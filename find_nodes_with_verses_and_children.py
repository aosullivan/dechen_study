#!/usr/bin/env python3
"""
Find all nodes in verse_hierarchy_map.json that have BOTH non-empty children
AND non-empty verses arrays, filtered to verses starting with "4." (chapter 4).
"""

import json

def find_dual_nodes(node, results):
    """Recursively find nodes with both non-empty children and non-empty verses."""
    verses = node.get("verses", [])
    children = node.get("children", [])

    if verses and children:
        # Filter: at least one verse must start with "4."
        ch4_verses = [v for v in verses if v.startswith("4.")]
        if ch4_verses:
            results.append({
                "path": node["path"],
                "title": node["title"],
                "verses": verses,
                "children_titles": [c["title"] for c in children],
            })

    for child in children:
        find_dual_nodes(child, results)


def main():
    with open("/Users/adrianosullivan/projects/dechen_study/texts/verse_hierarchy_map.json") as f:
        data = json.load(f)

    results = []
    for section in data["sections"]:
        find_dual_nodes(section, results)

    if not results:
        print("No nodes found with both children and chapter-4 verses.")
        return

    print(f"Found {len(results)} node(s) with both children AND verses starting with '4.':\n")
    for i, r in enumerate(results, 1):
        print(f"--- Node {i} ---")
        print(f"  Path:            {r['path']}")
        print(f"  Title:           {r['title']}")
        print(f"  Verses:          {r['verses']}")
        print(f"  Children titles: {r['children_titles']}")
        print()


if __name__ == "__main__":
    main()
