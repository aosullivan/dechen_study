#!/usr/bin/env python3
"""
Rebuild verseToPath and sectionToFirstVerse from the 'sections' tree (source of truth).
Reads verse_hierarchy_map.json and overwrites the two indices.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = ROOT / "texts" / "verse_hierarchy_map.json"


def collect_path_chain(node, parent_chain):
    """Build chain of {section, title} from root to this node."""
    chain = parent_chain + [{"section": node["path"], "title": node["title"]}]
    return chain


def build_section_to_first_verse(node):
    """
    For each section (path), compute the first verse in that section.
    If section has verses, first verse = verses[0].
    Else first verse = first verse from first descendant that has any (depth-first).
    Returns dict path -> verse (only for paths that have or contain verses).
    """
    out = {}

    def walk(n):
        if not isinstance(n, dict):
            return None
        first = None
        if n.get("verses"):
            first = n["verses"][0]
        for child in n.get("children", []):
            if not isinstance(child, dict):
                continue
            child_first = walk(child)
            if child_first is not None and first is None:
                first = child_first
        if first is not None:
            out[n["path"]] = first
        return first

    walk(node)
    return out


def build_verse_to_path(sections):
    """
    For each verse, set verseToPath[verse] = breadcrumb chain to the section
    that contains it. When a verse appears in multiple sections, use the
    deepest (last in depth-first order) so we get the most specific section.
    """
    verse_to_path = {}

    def walk(node, parent_chain):
        if not isinstance(node, dict):
            return
        chain = collect_path_chain(node, parent_chain)
        for v in node.get("verses", []):
            verse_to_path[v] = chain
        for child in node.get("children", []):
            if isinstance(child, dict):
                walk(child, chain)

    for top in sections:
        walk(top, [])

    return verse_to_path


def main():
    with open(JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    sections = data["sections"]

    # sectionToFirstVerse: merge from each root
    section_to_first_verse = {}
    for root in sections:
        section_to_first_verse.update(build_section_to_first_verse(root))

    # verseToPath: merge from each root (later/deeper overwrites)
    verse_to_path = {}
    for root in sections:
        sub = build_verse_to_path([root])
        for k, v in sub.items():
            verse_to_path[k] = v

    def path_key(s):
        return tuple(int(p) for p in s.split("."))

    data["sectionToFirstVerse"] = dict(
        sorted(section_to_first_verse.items(), key=lambda x: path_key(x[0]))
    )
    data["verseToPath"] = dict(sorted(verse_to_path.items()))

    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print("Updated verseToPath entries:", len(data["verseToPath"]))
    print("Updated sectionToFirstVerse entries:", len(data["sectionToFirstVerse"]))


if __name__ == "__main__":
    main()
