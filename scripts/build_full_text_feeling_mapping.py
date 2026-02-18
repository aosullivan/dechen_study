#!/usr/bin/env python3
"""
Build full-text feeling advice mapping from section_emotion_mappings.json.
Reads existing emotion mappings, maps each emotion to feeling category ids,
outputs full_text_feeling_advice_mapping.json (does not overwrite chapter 7 file).
"""
import json
from pathlib import Path

# Emotion (from section_emotion_mappings) -> list of feeling category ids (for buttons)
EMOTION_TO_FEELINGS = {
    "Joy / Happiness / Enjoyment / Laughter": ["need_motivation"],
    "Feeling Treated with Respect": ["doubting_myself"],
    "Well-Rested / Energized": ["take_care_of_myself"],
    "Worry / Anxiety": ["anxious"],
    "Stress": ["overwhelmed", "need_to_keep_going"],
    "Love / Affection / Connectedness": ["need_motivation", "need_perspective"],
    "Contentment / Satisfaction / Calm": ["need_perspective", "take_care_of_myself"],
    "Physical Pain / Discomfort": ["take_care_of_myself"],
    "Sadness": ["hopeless"],
    "Anger / Frustration / Irritation": ["need_perspective", "distracted"],
    "Tiredness / Fatigue": ["tired"],
    "Disgust / Annoyance / Contempt": ["need_perspective"],
    "Boredom": ["lazy", "procrastinating"],
    "Loneliness": ["hopeless", "need_motivation"],
    "Fear / Apprehension": ["anxious"],
    "Guilt / Regret": ["guilty"],
    "Embarrassment / Shame": ["guilty", "doubting_myself"],
    "Hopelessness / Discouragement": ["hopeless"],
    "Overwhelmed": ["overwhelmed"],
    "Gratitude / Hope / Pride": ["need_motivation", "doubting_myself", "need_to_keep_going"],
}

FEELING_CATEGORIES = [
    {"id": "lazy", "label": "Lazy / Can't get started", "hint": "Readings to help you begin"},
    {"id": "procrastinating", "label": "Procrastinating", "hint": "Why wait? Use your time well"},
    {"id": "hopeless", "label": "Hopeless / Discouraged", "hint": "Hope and encouragement"},
    {"id": "anxious", "label": "Anxious / Fearful", "hint": "Facing fear with clarity"},
    {"id": "guilty", "label": "Guilty / Regretful", "hint": "Turn regret into change"},
    {"id": "tired", "label": "Tired / Burned out", "hint": "Rest and sustainable effort"},
    {"id": "distracted", "label": "Distracted / Restless", "hint": "Steady focus and vigilance"},
    {"id": "doubting_myself", "label": "Doubting myself", "hint": "Belief in your capacity"},
    {"id": "need_motivation", "label": "Need motivation", "hint": "Spark and purpose"},
    {"id": "need_to_keep_going", "label": "Need to keep going", "hint": "Persistence and commitment"},
    {"id": "overwhelmed", "label": "Overwhelmed", "hint": "Simplify and reframe"},
    {"id": "need_perspective", "label": "Need perspective", "hint": "See what matters"},
    {"id": "take_care_of_myself", "label": "Want to take care of myself", "hint": "Rest, pacing, self-care"},
]


def collect_leaf_sections(node, out):
    """Recursively collect leaf sections (path, title, emotion)."""
    path = node.get("path")
    title = node.get("title")
    emotion = node.get("emotion")
    children = node.get("children") or []
    if not children:
        if path and title and emotion:
            out.append({"path": path, "title": title, "emotion": emotion})
        return
    for c in children:
        collect_leaf_sections(c, out)


def main():
    base = Path(__file__).resolve().parent.parent
    path_in = base / "texts" / "section_emotion_mappings.json"
    path_out = base / "texts" / "full_text_feeling_advice_mapping.json"

    with open(path_in, "r", encoding="utf-8") as f:
        data = json.load(f)

    leaves = []
    for section in data.get("sections", []):
        collect_leaf_sections(section, leaves)

    # Build feeling -> list of { path, title } (no duplicates per feeling, preserve order)
    feeling_to_sections = {fc["id"]: [] for fc in FEELING_CATEGORIES}
    seen = {fc["id"]: set() for fc in FEELING_CATEGORIES}

    for item in leaves:
        path, title, emotion = item["path"], item["title"], item["emotion"]
        feeling_ids = EMOTION_TO_FEELINGS.get(emotion, [])
        for fid in feeling_ids:
            if path not in seen[fid]:
                seen[fid].add(path)
                feeling_to_sections[fid].append({"path": path, "title": title})

    out = {
        "description": "Full-text 'how I'm feeling' mapping. User taps a feeling → app shows relevant therapeutic sections from the whole Bodhicaryavatara.",
        "feelingCategories": FEELING_CATEGORIES,
        "feelingToSections": feeling_to_sections,
    }
    with open(path_out, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2, ensure_ascii=False)

    print(f"Wrote {path_out}")
    print(f"Leaf sections: {len(leaves)}")
    for fid, arr in feeling_to_sections.items():
        print(f"  {fid}: {len(arr)} sections")


if __name__ == "__main__":
    main()
