#!/usr/bin/env python3
"""Map unmapped verses to the preceding verse's section (maintains consecutiveness)."""
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
    lines = MAPPING_PATH.read_text(encoding="utf-8").split("\n")
    all_refs = set()
    for line in lines:
        all_refs.update(extract_verse_refs(line))
    verses_ordered = sorted(all_refs, key=verse_sort_key)

    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    verse_to_path = data["verseToPath"]
    path_to_node = {}

    def walk(nodes):
        for n in nodes:
            p = n.get("path", "")
            if p:
                path_to_node[p] = n
            walk(n.get("children", []))

    walk(data["sections"])

    def get_breadcrumb(path):
        if not path:
            return []
        parts = path.split(".")
        bc = []
        for i in range(1, len(parts) + 1):
            p = ".".join(parts[:i])
            node = path_to_node.get(p)
            if node:
                bc.append({"section": p, "title": node.get("title", "")})
        return bc

    additions = {}
    for i, v in enumerate(verses_ordered):
        if v in verse_to_path:
            continue
        for j in range(i - 1, -1, -1):
            if verses_ordered[j] in verse_to_path:
                bc = verse_to_path[verses_ordered[j]]
                if bc and isinstance(bc, list):
                    prev_sec = bc[-1]["section"]
                    additions[v] = prev_sec
                break
        else:
            for j in range(i + 1, len(verses_ordered)):
                if verses_ordered[j] in verse_to_path:
                    bc = verse_to_path[verses_ordered[j]]
                    if bc and isinstance(bc, list):
                        additions[v] = bc[-1]["section"]
                    break

    for v, path in additions.items():
        node = path_to_node.get(path)
        if node:
            if "verses" not in node:
                node["verses"] = []
            node["verses"].append(v)
        bc = get_breadcrumb(path)
        if bc:
            verse_to_path[v] = bc

    def sort_verses(nodes):
        for n in nodes:
            if "verses" in n and n["verses"]:
                n["verses"] = sorted(n["verses"], key=verse_sort_key)
            sort_verses(n.get("children", []))

    sort_verses(data["sections"])

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

    JSON_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Mapped {len(additions)} previously unmapped verses. Total: {len(verse_to_path)}")


if __name__ == "__main__":
    main()
