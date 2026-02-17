#!/usr/bin/env python3
"""
Find all nodes in verse_hierarchy_map.json that have BOTH non-empty children
AND non-empty verses arrays.

Filter: only nodes whose path starts with "4." (chapter 4 of the outline).

Note: The "verses" field references text chapter.verse (e.g. "9.4cd"),
while the "path" field is the outline position (e.g. "4.6.2.1.1.3.3").
No verse values themselves start with "4.", so the filter is applied
to the path field instead.
"""

import json
import sys


def find_dual_nodes(node, results):
    """Recursively find nodes with both non-empty children and non-empty verses."""
    if not isinstance(node, dict):
        return

    verses = node.get("verses", [])
    children = node.get("children", [])

    if verses and children:
        path = node.get("path", "")
        # Filter to chapter 4 outline nodes
        if path.startswith("4."):
            children_titles = [
                c["title"] if isinstance(c, dict) else str(c)
                for c in children
            ]
            results.append({
                "path": path,
                "title": node.get("title", ""),
                "verses": verses,
                "children_titles": children_titles,
            })

    for child in children:
        find_dual_nodes(child, results)


def main():
    filepath = "/Users/adrianosullivan/projects/dechen_study/texts/verse_hierarchy_map.json"
    with open(filepath) as f:
        data = json.load(f)

    results = []
    for section in data["sections"]:
        find_dual_nodes(section, results)

    if not results:
        print("No matching nodes found.")
        sys.exit(0)

    print(f"Found {len(results)} node(s) in chapter 4 with both children AND verses:\n")
    for i, r in enumerate(results, 1):
        print(f"--- Node {i} ---")
        print(f"  Path:             {r['path']}")
        print(f"  Title:            {r['title']}")
        print(f"  Verses:           {r['verses']}")
        print(f"  Children titles:")
        for ct in r["children_titles"]:
            print(f"    - {ct}")
        print()


if __name__ == "__main__":
    main()
