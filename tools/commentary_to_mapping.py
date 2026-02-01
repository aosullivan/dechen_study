#!/usr/bin/env python3
"""Parse commentary.txt and insert [c.v] verse tags before each section heading.

The transformation adds verse number tags (in square brackets) immediately before 
each section heading to indicate which verses are discussed in that section.

For example:
  Before: "2. Fear of experiencing this"
  After:  "[2.40] [2.41] [2.42]\n2. Fear of experiencing this"
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COMMENTARY = ROOT / "texts" / "commentary.txt"
OUTPUT = ROOT / "texts" / "verse_commentary_mapping.txt"

# Line that is only a verse ref (e.g. "1.1", "2.1 ")
REF_LINE = re.compile(r"^\s*(\d+\.\d+)\s*$")
# Section heading: starts with number(s), dot, space, then text (e.g. "2. Fear of experiencing...")
SECTION_HEADING = re.compile(r"^(\d+\.)\s+[A-Z]")


def main():
    text = COMMENTARY.read_text(encoding="utf-8")
    lines = text.split("\n")

    # Find all verse ref positions and section heading positions
    ref_positions = []  # (line_index, ref)
    heading_positions = []  # (line_index, heading_text)

    for i, line in enumerate(lines):
        m = REF_LINE.match(line)
        if m:
            ref_positions.append((i, m.group(1)))
        elif SECTION_HEADING.match(line):
            heading_positions.append((i, line))

    # For each section heading, find the verses that appear between this heading
    # and the next heading (or end of file)
    # Then insert the verse tags before the heading

    # Build a list of (heading_line_index, [refs_in_section])
    heading_refs = []
    for h_idx, (h_line, h_text) in enumerate(heading_positions):
        # End is the next heading or end of file
        if h_idx + 1 < len(heading_positions):
            end_line = heading_positions[h_idx + 1][0]
        else:
            end_line = len(lines)
        
        # Find refs between h_line and end_line
        refs_in_section = []
        for r_line, ref in ref_positions:
            if h_line < r_line < end_line:
                refs_in_section.append(ref)
        
        heading_refs.append((h_line, refs_in_section))

    # Build the output by inserting verse tags before each heading
    output_lines = []
    heading_dict = {h_line: refs for h_line, refs in heading_refs}
    
    for i, line in enumerate(lines):
        if i in heading_dict:
            refs = heading_dict[i]
            if refs:
                # Insert verse tags on a line before the heading
                tags = " ".join(f"[{r}]" for r in refs)
                output_lines.append(tags)
        output_lines.append(line)

    OUTPUT.write_text("\n".join(output_lines), encoding="utf-8")
    
    # Count how many headings got tags
    tagged = sum(1 for _, refs in heading_refs if refs)
    print(f"Added verse tags to {tagged} section headings")
    print(f"Output written to {OUTPUT}")


if __name__ == "__main__":
    main()
