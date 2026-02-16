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
    Then fill any missing paths (sections with no verses and no verses in descendants)
    by inheriting from parent so every path has an entry.
    Returns dict path -> verse for every path in the tree.
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


def collect_all_paths(node):
    """Collect every section path in the tree (dict path -> None)."""
    out = {}

    def walk(n):
        if not isinstance(n, dict):
            return
        out[n["path"]] = None
        for child in n.get("children", []):
            if isinstance(child, dict):
                walk(child)

    walk(node)
    return out


def fill_section_to_first_verse(section_to_first_verse, sections):
    """
    For every path that appears in the tree but is missing from sectionToFirstVerse,
    set it to the nearest ancestor's first verse (walk up until we find one).
    """
    all_paths = {}
    for root in sections:
        all_paths.update(collect_all_paths(root))
    for path in all_paths:
        if path in section_to_first_verse:
            continue
        # Walk up to find an ancestor that has a first verse
        parts = path.split(".")
        for i in range(len(parts) - 1, 0, -1):
            ancestor = ".".join(parts[:i])
            if ancestor in section_to_first_verse:
                section_to_first_verse[path] = section_to_first_verse[ancestor]
                break


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

    # sectionToFirstVerse: merge from each root, then fill missing paths from parent
    section_to_first_verse = {}
    for root in sections:
        section_to_first_verse.update(build_section_to_first_verse(root))
    fill_section_to_first_verse(section_to_first_verse, sections)

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
