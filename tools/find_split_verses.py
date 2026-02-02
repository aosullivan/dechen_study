#!/usr/bin/env python3
"""Find verses in verse_commentary_mapping.txt that are split (ab in one section, cd in next).

Pattern: We have [C.V] then:
- A subsection header (N. Title)
- Line "C.V" (verse number only)
- Exactly 2 lines of verse-like text (not a tag, not subsection, not Image)
- Then 0+ lines (blank, [ Image ], subsection outline like "1.\tMethod...")
- Then ANOTHER subsection header (M. Title) 
- Then 2 lines of verse-like text
- Before the next [C.V+1] or [Z.W] tag

So the verse is quoted as ab (2 lines) then later cd (2 lines) in a different subsection.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPPING = ROOT / "texts" / "verse_commentary_mapping.txt"
BCV_ROOT = ROOT / "texts" / "bcv-root"


def is_verse_tag(s):
    """Line is a mapping tag like [1.6] or [1.6ab] or [7.46]."""
    s = s.strip()
    if not s.startswith("[") or not s.endswith("]"):
        return False
    return bool(re.match(r"^\[\d+\.\d+", s))


def is_whole_verse_tag(s):
    """Line is exactly [C.V] with no ab/cd suffix."""
    s = s.strip()
    return bool(re.match(r"^\[(\d+)\.(\d+)\]$", s))


def is_verse_number_line(s, c, v):
    """Line is just 'C.V' or 'c.v'."""
    s = s.strip()
    m = re.match(r"^\s*(\d+)\.(\d+)\s*$", s)
    if not m:
        return False
    return int(m.group(1)) == c and int(m.group(2)) == v


def is_subsection_header(s):
    """Line is '1. Title' or '2. Method...' (digit, dot, space/tab, then text)."""
    s = s.strip()
    return bool(re.match(r"^\d+\.\s+[A-Za-z]", s))


def is_verse_like_line(s):
    """Line looks like verse text (not a tag, not subsection, not Image, not blank)."""
    s = s.strip()
    if not s:
        return False
    if s.startswith("[") and "]" in s:
        return False
    if re.match(r"^\d+\.\s+", s):
        return False
    if s.startswith("[ Image"):
        return False
    return True


def load_root_verses():
    """Parse bcv-root: return dict (c, v) -> (line1, line2, line3, line4)."""
    text = BCV_ROOT.read_text(encoding="utf-8")
    verses = {}
    ref_re = re.compile(r"\[(\d+)\.(\d+)\]")
    lines = text.split("\n")
    for i, line in enumerate(lines):
        m = ref_re.search(line)
        if m:
            c, v = int(m.group(1)), int(m.group(2))
            block = []
            j = i - 1
            while j >= 0 and len(block) < 4:
                stripped = lines[j].strip()
                if stripped and not stripped.startswith("Chapter "):
                    if ref_re.search(stripped):
                        part = ref_re.split(stripped)[0].strip()
                        if part:
                            block.insert(0, part)
                    else:
                        block.insert(0, stripped)
                j -= 1
            if len(block) >= 4:
                verses[(c, v)] = tuple(block[-4:])
            elif len(block) > 0:
                pad = [""] * (4 - len(block))
                verses[(c, v)] = tuple(pad + block)
    return verses


def norm(s):
    """Normalize for fuzzy match: strip, lower, first 60 chars."""
    return s.strip().lower().replace("'", "'")[:60]


def cd_matches(root_verses, c, v, line1, line2):
    """Check if line1, line2 match lines 3-4 of verse (c,v) from bcv-root (relaxed: first 25 chars)."""
    if (c, v) not in root_verses:
        return False
    cd = root_verses[(c, v)][2:4]
    n1, n2 = norm(line1)[:40], norm(line2)[:40]
    nc1, nc2 = norm(cd[0])[:40], norm(cd[1])[:40]
    # Require substantial overlap (first ~25 chars or substring)
    def overlap(a, b):
        return len(a) >= 15 and (a in b or b in a or a[:25] == b[:25])
    return overlap(n1, nc1) and overlap(n2, nc2)


def main(validate_with_root=True):
    lines = MAPPING.read_text(encoding="utf-8").split("\n")
    root_verses = load_root_verses() if validate_with_root else {}
    splits = []

    i = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"^\[(\d+)\.(\d+)\]$", line.strip())
        if m:
            c, v = int(m.group(1)), int(m.group(2))
            j = i + 1
            found_verse_num = False
            found_two_after_num = False
            subsection_line = None
            cd_line1 = cd_line2 = None

            while j < min(i + 45, len(lines)):
                l = lines[j]
                if is_verse_number_line(l, c, v):
                    found_verse_num = True
                    k = j + 1
                    count = 0
                    while k < len(lines) and count < 2:
                        if is_verse_like_line(lines[k]):
                            count += 1
                        k += 1
                    if count == 2:
                        found_two_after_num = True
                    j = k
                    continue
                if found_verse_num and found_two_after_num:
                    if is_subsection_header(l):
                        subsection_line = j
                        k = j + 1
                        count = 0
                        cand = []
                        while k < len(lines) and count < 2:
                            if is_verse_like_line(lines[k]):
                                count += 1
                                cand.append(lines[k].strip())
                            elif is_verse_tag(lines[k]):
                                break
                            k += 1
                        if count == 2:
                            cd_line1, cd_line2 = cand[0], cand[1]
                            if not validate_with_root or cd_matches(root_verses, c, v, cd_line1, cd_line2):
                                splits.append((c, v, i + 1, subsection_line + 1))
                            break
                    if is_verse_tag(l) and not is_verse_number_line(l, c, v):
                        break
                j += 1
        i += 1
    # Dedupe by (c,v), keep first occurrence (tag_ln, sub_ln)
    seen = {}
    for (c, v, tag_ln, sub_ln) in splits:
        if (c, v) not in seen:
            seen[(c, v)] = (tag_ln, sub_ln)
    for (c, v), (tag_ln, sub_ln) in sorted(seen.items()):
        print(f"{c}.{v}  tag line {tag_ln}, cd subsection line {sub_ln}")
    print(f"\nTotal: {len(seen)} split verses")
    return seen


def already_split(lines, c, v):
    """Check if verse c.v already has ab/cd tags."""
    ab_tag = f"[{c}.{v}ab]"
    cd_tag = f"[{c}.{v}cd]"
    for line in lines:
        if ab_tag in line or cd_tag in line:
            return True
    return False


def apply_splits(splits_dict):
    """Replace [C.V] with [C.Vab] and insert [C.Vcd] before cd subsection for each verse."""
    lines = MAPPING.read_text(encoding="utf-8").split("\n")
    # Filter out already-split
    to_apply = {
        (c, v): (tag_ln, sub_ln)
        for (c, v), (tag_ln, sub_ln) in splits_dict.items()
        if not already_split(lines, c, v)
    }
    # Build insert and replace maps (0-based indices)
    insert_before = {}  # line_idx -> list of tags to insert
    replace_at = {}     # line_idx -> new tag
    for (c, v), (tag_ln, sub_ln) in to_apply.items():
        tag_idx = tag_ln - 1
        sub_idx = sub_ln - 1
        replace_at[tag_idx] = f"[{c}.{v}ab]"
        insert_before.setdefault(sub_idx, []).append(f"[{c}.{v}cd]")
    # Build new lines
    new_lines = []
    for i, line in enumerate(lines):
        if i in insert_before:
            for tag in insert_before[i]:
                new_lines.append(tag)
        if i in replace_at:
            new_lines.append(replace_at[i])
        else:
            new_lines.append(line)
    MAPPING.write_text("\n".join(new_lines), encoding="utf-8")
    print(f"Applied {len(to_apply)} splits (skipped {len(splits_dict) - len(to_apply)} already split)")
    return to_apply


if __name__ == "__main__":
    import sys
    validate = "--no-validate" not in sys.argv
    splits_dict = main(validate_with_root=validate)
    if "--apply" in sys.argv:
        apply_splits(splits_dict)
