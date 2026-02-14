#!/usr/bin/env python3
"""
Enforce that each section's verses form a consecutive block in document order.
When a section has non-consecutive verses, reassign outliers to the preceding verse's section.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPPING_PATH = ROOT / "texts" / "verse_commentary_mapping.txt"
JSON_PATH = ROOT / "texts" / "verse_hierarchy_map.json"


def verse_sort_key(v):
    m = re.match(r"^(\d+)\.(\d+)([a-d]*)$", v)
    if not m:
        return (0, 0, 0)
    c, vn = int(m.group(1)), int(m.group(2))
    suf = {"": 0, "ab": 1, "cd": 2}.get(m.group(3), 0)
    return (c, vn, suf)


def extract_verse_refs(line):
    refs = []
    for m in re.finditer(r"\[(\d+\.\d+)([a-d]*)(?:-(\d+\.\d+)[a-d]*)?\]", line):
        start, suffix, end = m.group(1), m.group(2) or "", m.group(3)
        if end:
            c1, v1 = map(int, start.split("."))
            c2, v2 = map(int, end.split("."))
            for c in range(c1, c2 + 1):
                vs = v1 if c == c1 else 1
                ve = v2 if c == c2 else 999
                for v in range(vs, ve + 1):
                    refs.append(f"{c}.{v}")
        else:
            refs.append(start + suffix)
    return refs


def main():
    # Build document order of all verses
    lines = MAPPING_PATH.read_text(encoding="utf-8").split("\n")
    all_refs = set()
    for line in lines:
        all_refs.update(extract_verse_refs(line))
    doc_order = sorted(all_refs, key=verse_sort_key)
    verse_to_idx = {v: i for i, v in enumerate(doc_order)}

    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    path_to_node = {}

    def walk(nodes):
        for n in nodes:
            p = n.get("path", "")
            if p:
                path_to_node[p] = n
            walk(n.get("children", []))

    walk(data["sections"])

    # Build verse -> section (from verseToPath)
    verse_to_section = {}
    for v, bc in data["verseToPath"].items():
        if bc and isinstance(bc, list):
            verse_to_section[v] = bc[-1]["section"]

    # Find sections with non-consecutive verses
    def get_verses_for_section(path):
        return [v for v, s in verse_to_section.items() if s == path]

    changed = True
    iterations = 0
    max_iter = 50

    while changed and iterations < max_iter:
        changed = False
        iterations += 1

        for path, node in path_to_node.items():
            verses = get_verses_for_section(path)
            if len(verses) < 2:
                continue

            sorted_verses = sorted(verses, key=verse_sort_key)
            idxs = [verse_to_idx.get(v) for v in sorted_verses if v in verse_to_idx]
            if None in idxs or len(idxs) < 2:
                continue

            # Find gaps: verses in other sections between our first and last
            first_idx, last_idx = min(idxs), max(idxs)
            our_set = set(verses)

            for i in range(first_idx, last_idx + 1):
                v = doc_order[i]
                if v in our_set:
                    continue
                # v is between our verses but in another section - we have a gap
                # Either add v to us (if it's unmapped or we can steal it) or split
                # Consecutiveness: we cannot have gaps. So we must either:
                # (a) add v to our section, or (b) remove verses from our section to create a consecutive block
                # Option (b): keep only one consecutive run. Reassign verses that create gaps.
                break
            else:
                continue

            # Has gap - keep largest consecutive run, reassign the rest
            runs = []
            current_run = [sorted_verses[0]]
            for i in range(1, len(sorted_verses)):
                prev_idx = verse_to_idx[sorted_verses[i - 1]]
                curr_idx = verse_to_idx[sorted_verses[i]]
                if curr_idx == prev_idx + 1:
                    current_run.append(sorted_verses[i])
                else:
                    runs.append(current_run)
                    current_run = [sorted_verses[i]]
            runs.append(current_run)

            # Keep largest run in this section, reassign others to preceding verse's section
            best_run = max(runs, key=len)
            to_reassign = [v for run in runs if run != best_run for v in run]

            for v in to_reassign:
                idx = verse_to_idx[v]
                # Assign to preceding verse's section
                if idx > 0:
                    prev_v = doc_order[idx - 1]
                    prev_sec = verse_to_section.get(prev_v)
                    if prev_sec and prev_sec != path:
                        verse_to_section[v] = prev_sec
                        changed = True

    # Rebuild verseToPath from verse_to_section and path_to_node
    def get_breadcrumb(path):
        if not path:
            return []
        parts = path.split(".")
        bc = []
        for i in range(1, len(parts) + 1):
            p = ".".join(parts[:i])
            n = path_to_node.get(p)
            if n:
                bc.append({"section": p, "title": n.get("title", "")})
        return bc

    new_verse_to_path = {}
    for v, path in verse_to_section.items():
        bc = get_breadcrumb(path)
        if bc:
            new_verse_to_path[v] = bc

    # Rebuild section verses from verse_to_section (verses may have been moved)
    def clear_verses(nodes):
        for n in nodes:
            n["verses"] = []
            clear_verses(n.get("children", []))

    clear_verses(data["sections"])

    for v, path in verse_to_section.items():
        node = path_to_node.get(path)
        if node and "verses" in node:
            node["verses"].append(v)

    # Sort verses in each node
    def sort_nodes(nodes):
        for n in nodes:
            if "verses" in n:
                n["verses"] = sorted(n["verses"], key=verse_sort_key)
            sort_nodes(n.get("children", []))

    sort_nodes(data["sections"])

    # Rebuild sectionToFirstVerse
    def collect_all(node):
        v = set(node.get("verses", []))
        for c in node.get("children", []):
            v.update(collect_all(c))
        return v

    section_to_first = {}

    def build_first(nodes):
        for n in nodes:
            p = n.get("path", "")
            if p:
                all_v = list(collect_all(n))
                if all_v:
                    all_v.sort(key=verse_sort_key)
                    section_to_first[p] = all_v[0]
            build_first(n.get("children", []))

    build_first(data["sections"])
    data["sectionToFirstVerse"] = section_to_first
    data["verseToPath"] = new_verse_to_path

    JSON_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print("Enforced consecutiveness. Verses in verseToPath:", len(new_verse_to_path))


if __name__ == "__main__":
    main()
