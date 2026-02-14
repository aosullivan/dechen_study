#!/usr/bin/env python3
"""Verify each section's verses form a consecutive block."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPPING_PATH = ROOT / "texts" / "verse_commentary_mapping.txt"
JSON_PATH = ROOT / "texts" / "verse_hierarchy_map.json"


def verse_key(v):
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
                vs, ve = (v1, v2) if c == c1 == c2 else ((v1, 999) if c == c1 else (1, v2) if c == c2 else (1, 999))
                for v in range(vs, ve + 1):
                    refs.append(f"{c}.{v}")
        else:
            refs.append(start + suffix)
    return refs


def main():
    lines = MAPPING_PATH.read_text(encoding="utf-8").split("\n")
    all_refs = set()
    for line in lines:
        all_refs.update(extract_verse_refs(line))
    doc_order = sorted(all_refs, key=verse_key)
    verse_to_idx = {v: i for i, v in enumerate(doc_order)}

    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    verse_to_section = {}
    for v, bc in data["verseToPath"].items():
        if bc and isinstance(bc, list):
            verse_to_section[v] = bc[-1]["section"]

    violations = 0

    def check_node(node):
        nonlocal violations
        verses = [v for v, s in verse_to_section.items() if s == node.get("path", "")]
        if len(verses) < 2:
            return
        sorted_v = sorted(verses, key=verse_key)
        idxs = [verse_to_idx.get(v) for v in sorted_v if v in verse_to_idx]
        if None in idxs:
            return
        for i in range(len(idxs) - 1):
            for j in range(idxs[i] + 1, idxs[i + 1]):
                other = doc_order[j]
                other_sec = verse_to_section.get(other)
                if other_sec and other_sec != node.get("path", ""):
                    violations += 1
                    if violations <= 5:
                        print(f"GAP: {node.get('path')} has {sorted_v[i]} then {sorted_v[i+1]}, but {other} (in {other_sec}) between")
        for c in node.get("children", []):
            check_node(c)

    for s in data["sections"]:
        check_node(s)

    print(f"Violations: {violations}")
    if violations == 0:
        print("All sections have consecutive verses.")


if __name__ == "__main__":
    main()
