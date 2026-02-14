#!/usr/bin/env python3
"""Fix >>> markers in verse_commentary_mapping.txt so they indicate ONLY root text.
Uses root_text.txt (or bcv-root) as the canonical source of root text lines.
Any line with >>> whose content is NOT in root text will have >>> removed."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROOT_TEXT = ROOT / "texts" / "root_text.txt"
BCV_ROOT = ROOT / "texts" / "bcv-root"
MAPPING = ROOT / "texts" / "verse_commentary_mapping.txt"

# Use root_text.txt if it exists and has content; else bcv-root
def get_root_source():
    if ROOT_TEXT.exists():
        return ROOT_TEXT
    return BCV_ROOT

def normalize(line: str) -> str:
    """Normalize for matching: trim, collapse whitespace, strip footnote/verse refs."""
    s = line.strip().replace("\t", " ")
    s = re.sub(r"\s+", " ", s)
    # Strip trailing [368] or [1.5] style refs
    s = re.sub(r"\s*\[\d+(?:\.\d+)?\]\s*$", "", s)
    return s.strip()

def build_root_line_set(path: Path) -> set[str]:
    """Extract all verse/chapter lines from root text. Exclude ref-only lines."""
    content = path.read_text(encoding="utf-8")
    lines = content.splitlines()
    root_lines = set()
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        # Skip lines that are just a verse ref (e.g. [1.1])
        if re.match(r"^\[\d+\.\d+\]$", stripped):
            continue
        # Include all other lines (verses and chapter titles)
        norm = normalize(stripped)
        if norm:
            root_lines.add(norm)
    return root_lines

def _levenshtein(a: str, b: str) -> int:
    """Edit distance between two strings."""
    if len(a) < len(b):
        return _levenshtein(b, a)
    if len(b) == 0:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a):
        curr = [i + 1]
        for j, cb in enumerate(b):
            curr.append(min(
                prev[j + 1] + 1,
                curr[j] + 1,
                prev[j] + (0 if ca == cb else 1),
            ))
        prev = curr
    return prev[-1]

def _is_root_text(norm: str, root_lines: set[str]) -> bool:
    """True if norm exactly or fuzzy-matches a root line (allows minor typos)."""
    if norm in root_lines:
        return True
    # Fuzzy: allow edit distance <= 2 for lines under 100 chars (handles Sempitneral vs Sempiternal)
    if len(norm) < 100:
        for r in root_lines:
            if abs(len(r) - len(norm)) <= 2 and _levenshtein(norm, r) <= 2:
                return True
    return False

def fix_mapping(root_lines: set[str], mapping_path: Path) -> tuple[int, int, int, int]:
    """Remove >>> from non-root lines; add >>> to root lines missing it. Returns (checked, removed, fuzzy_kept, added)."""
    content = mapping_path.read_text(encoding="utf-8")
    lines = content.splitlines(keepends=True)
    total_marked = 0
    removed = 0
    fuzzy_kept = 0
    added = 0
    out = []
    for i, line in enumerate(lines):
        if line.startswith(">>> "):
            total_marked += 1
            content_part = line[4:].rstrip("\n\r")
            # Normalize for comparison - strip footnote refs like [368]
            norm = normalize(content_part)
            if _is_root_text(norm, root_lines):
                if norm not in root_lines:
                    fuzzy_kept += 1
                out.append(line)
            else:
                # This is commentary, not root text - remove >>>
                new_line = line[4:]  # Keep the rest as-is (including newline from keepends)
                out.append(new_line)
                removed += 1
        else:
            # Add >>> to root text lines that lack it (exact match, short lines only to avoid commentary)
            stripped = line.rstrip("\n\r")
            if stripped and len(stripped) < 90 and not stripped.startswith(">>> ") and not stripped.startswith("["):
                norm = normalize(stripped)
                if norm in root_lines:
                    # Skip section headings (N. Title), image placeholders, and lines with tab/list prefix
                    if not re.match(r"^\d+(\.\d+)*\.\s+", stripped) and "[ Image:" not in stripped and not stripped.startswith("\t"):
                        out.append(">>> " + line)
                        added += 1
                        continue
            out.append(line)
    mapping_path.write_text("".join(out), encoding="utf-8")
    return total_marked, removed, fuzzy_kept, added

def main():
    src = get_root_source()
    print(f"Using root text from: {src}")
    root_lines = build_root_line_set(src)
    print(f"Root text lines: {len(root_lines)}")
    total, removed, fuzzy_kept, added = fix_mapping(root_lines, MAPPING)
    print(f">>> lines checked: {total}")
    print(f">>> removed (commentary mis-marked as verse): {removed}")
    print(f">>> kept via fuzzy match (typos): {fuzzy_kept}")
    print(f">>> added to root lines missing it: {added}")
    print(f"Wrote {MAPPING}")

if __name__ == "__main__":
    main()
