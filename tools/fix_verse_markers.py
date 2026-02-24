#!/usr/bin/env python3
"""Fix >>> markers in verse_commentary_mapping.txt so they indicate ONLY root text.
Uses root_text.txt (or bcv-root) as canonical text and, when available,
bcv_parsed.json for verse-aware add-marker matching."""

import json
import re
import argparse
from difflib import SequenceMatcher
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROOT_TEXT = ROOT / "texts" / "root_text.txt"
BCV_ROOT = ROOT / "texts" / "bcv-root"
PARSED = ROOT / "texts" / "bcv_parsed.json"
MAPPING = ROOT / "texts" / "verse_commentary_mapping.txt"

VERSE_NUM_RE = re.compile(r"^\s*(\d+)\.(\d+)\s*$")
VERSE_TAG_RE = re.compile(r"^\[\d+\.\d+")
SPLIT_TAG_RE = re.compile(r"^\[(\d+)\.(\d+)(ab|cd)\]\s*$")
SECTION_HDR_RE = re.compile(r"^\d+(\.\d+)*\.\s+")
TOKEN_RE = re.compile(r"[A-Za-z0-9āīūṛṅñṭḍṇśṣ]+")


def get_root_source() -> Path:
    """Use root_text.txt if present; else fallback to bcv-root."""
    if ROOT_TEXT.exists():
        return ROOT_TEXT
    return BCV_ROOT


def normalize(line: str) -> str:
    """Normalize for matching: trim/collapse whitespace, strip trailing refs."""
    s = line.strip().replace("\t", " ")
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"\s*\[\d+(?:\.\d+)?\]\s*$", "", s)
    return s.strip()


def normalize_loose(line: str) -> str:
    """Loose normalize: punctuation-insensitive and case-insensitive."""
    s = normalize(line)
    s = s.replace("’", "'").replace("‘", "'")
    s = s.lower()
    s = re.sub(r"[^a-z0-9āīūṛṅñṭḍṇśṣ']+", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def tokenize(line: str) -> list[str]:
    return TOKEN_RE.findall(normalize_loose(line))


def has_marker(line: str) -> bool:
    return line.startswith(">>>")


def strip_marker(line: str) -> str:
    if line.startswith(">>> "):
        return line[4:]
    if line.startswith(">>>"):
        return line[3:].lstrip()
    return line


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


def _tokens_contiguous_subseq(shorter: list[str], longer: list[str]) -> bool:
    """True if `shorter` appears contiguously inside `longer`."""
    if not shorter:
        return False
    if len(shorter) > len(longer):
        return False
    n = len(shorter)
    for i in range(len(longer) - n + 1):
        if longer[i:i + n] == shorter:
            return True
    return False


def build_root_line_index(path: Path) -> tuple[set[str], set[str], dict[str, list[list[str]]]]:
    """Extract root lines and multiple indexes used for tolerant matching."""
    root_lines: set[str] = set()
    root_loose: set[str] = set()
    token_index: dict[str, list[list[str]]] = {}

    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if re.match(r"^\[\d+\.\d+\]$", stripped):
            continue
        norm = normalize(stripped)
        if not norm:
            continue
        root_lines.add(norm)
        loose = normalize_loose(norm)
        if loose:
            root_loose.add(loose)
            toks = tokenize(loose)
            if toks:
                token_index.setdefault(toks[0], []).append(toks)
    return root_lines, root_loose, token_index


def _root_match_kind(
    norm: str,
    root_lines: set[str],
    root_loose: set[str],
    token_index: dict[str, list[list[str]]],
) -> str | None:
    """Return match kind for root text lookup: exact/loose/fuzzy, or None."""
    if norm in root_lines:
        return "exact"

    loose = normalize_loose(norm)
    if loose in root_loose:
        return "loose"

    toks = tokenize(loose)
    if toks:
        for cand in token_index.get(toks[0], []):
            if (
                len(toks) >= 2
                and _tokens_contiguous_subseq(toks, cand)
                and len(cand) <= len(toks) + 6
            ) or (
                len(cand) >= 2
                and _tokens_contiguous_subseq(cand, toks)
                and len(toks) <= len(cand) + 6
            ):
                return "loose"

    if len(norm) < 100:
        for r in root_lines:
            if abs(len(r) - len(norm)) <= 2 and _levenshtein(norm, r) <= 2:
                return "fuzzy"
    return None


def load_parsed_verse_map(path: Path) -> dict[str, list[str]]:
    """Load canonical verse line-splits from bcv_parsed.json if available."""
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    refs = data.get("refs")
    verses = data.get("verses")
    if not isinstance(refs, list) or not isinstance(verses, list) or len(refs) != len(verses):
        return {}
    out: dict[str, list[str]] = {}
    for ref, verse in zip(refs, verses):
        if not isinstance(ref, str) or not isinstance(verse, str):
            continue
        lines = [ln.strip() for ln in verse.split("\n") if ln.strip()]
        if lines and ref not in out:
            out[ref] = lines
    return out


def is_boundary_line(stripped: str) -> bool:
    """True if stripped line marks boundary between verse text and other content."""
    return bool(
        VERSE_TAG_RE.match(stripped)
        or VERSE_NUM_RE.match(stripped)
        or SECTION_HDR_RE.match(stripped)
        or stripped.startswith("[ Image:")
    )


def line_matches_canonical(candidate: str, canonical: str) -> bool:
    """Tolerant match for a mapping line (or merged lines) against canonical verse line."""
    if candidate.strip().endswith(":") and not canonical.strip().endswith(":"):
        return False

    a = normalize_loose(candidate)
    b = normalize_loose(canonical)
    if not a or not b:
        return False
    if a == b:
        return True

    ta = tokenize(a)
    tb = tokenize(b)
    if not ta or not tb:
        return False
    if ta == tb:
        return True

    if (
        len(ta) >= 2
        and _tokens_contiguous_subseq(ta, tb)
        and len(tb) <= len(ta) + 6
    ) or (
        len(tb) >= 2
        and _tokens_contiguous_subseq(tb, ta)
        and len(ta) <= len(tb) + 6
    ):
        return True

    sim = SequenceMatcher(None, a, b).ratio()
    if sim >= 0.86:
        return True
    if len(ta) >= 3 and len(tb) >= 3 and ta[:3] == tb[:3] and sim >= 0.72:
        return True

    overlap = len(set(ta) & set(tb)) / max(1, min(len(set(ta)), len(set(tb))))
    return overlap >= 0.82 and abs(len(ta) - len(tb)) <= 4


def add_missing_markers_by_split_tags(lines: list[str], verse_map: dict[str, list[str]]) -> int:
    """Add >>> markers in [C.Vab]/[C.Vcd] split sections without C.V number line."""
    added = 0
    for i, line in enumerate(lines):
        m = SPLIT_TAG_RE.match(line.strip())
        if not m:
            continue
        ref = f"{int(m.group(1))}.{int(m.group(2))}"
        part = m.group(3)
        canonical = verse_map.get(ref)
        if not canonical:
            continue

        if part == "ab":
            targets = canonical[:2]
        else:
            targets = canonical[2:] if len(canonical) > 2 else canonical[-2:]
        if not targets:
            continue

        j = i + 1
        t_idx = 0
        scanned = 0
        max_scanned = len(targets) * 6 + 8
        while t_idx < len(targets) and j < len(lines) and scanned <= max_scanned:
            stripped = lines[j].strip()
            if not stripped:
                j += 1
                continue
            if VERSE_TAG_RE.match(stripped) or VERSE_NUM_RE.match(stripped):
                break
            if SECTION_HDR_RE.match(stripped) or stripped.startswith("[ Image:"):
                j += 1
                continue

            scanned += 1
            raw = strip_marker(lines[j]).strip()
            if len(raw) > 120:
                j += 1
                continue
            if line_matches_canonical(raw, targets[t_idx]):
                if not has_marker(lines[j]):
                    lines[j] = ">>> " + lines[j]
                    added += 1
                t_idx += 1
                j += 1
                continue

            # Two-line merge fallback for split/merged line variants.
            if j + 1 < len(lines) and not raw.endswith(":"):
                next_stripped = lines[j + 1].strip()
                if next_stripped and not (
                    VERSE_TAG_RE.match(next_stripped)
                    or VERSE_NUM_RE.match(next_stripped)
                    or SECTION_HDR_RE.match(next_stripped)
                    or next_stripped.startswith("[ Image:")
                ):
                    merged = f"{raw} {strip_marker(lines[j + 1]).strip()}".strip()
                    if line_matches_canonical(merged, targets[t_idx]):
                        for idx in (j, j + 1):
                            if not has_marker(lines[idx]):
                                lines[idx] = ">>> " + lines[idx]
                                added += 1
                        t_idx += 1
                        j += 2
                        continue
            j += 1
    return added


def add_missing_markers_by_verse(lines: list[str], verse_map: dict[str, list[str]]) -> int:
    """Add >>> markers by aligning each C.V block with canonical verse lines."""
    added = 0
    for i, line in enumerate(lines):
        m = VERSE_NUM_RE.match(line.strip())
        if not m:
            continue
        ref = f"{int(m.group(1))}.{int(m.group(2))}"
        canonical = verse_map.get(ref)
        if not canonical:
            continue

        j = i + 1
        cidx = 0
        matched_any = False
        scanned = 0
        max_scanned = len(canonical) * 3 + 2

        while cidx < len(canonical) and j < len(lines) and scanned <= max_scanned:
            while j < len(lines) and not lines[j].strip():
                j += 1
            if j >= len(lines):
                break

            stripped = lines[j].strip()
            if is_boundary_line(stripped):
                break

            scanned += 1
            raw = strip_marker(lines[j]).strip()
            if len(raw) > 120:
                break
            canon_line = canonical[cidx]
            to_mark = None

            if line_matches_canonical(raw, canon_line):
                to_mark = [j]
            elif j + 1 < len(lines) and not raw.endswith(":"):
                next_stripped = lines[j + 1].strip()
                if next_stripped and not is_boundary_line(next_stripped):
                    merged = f"{raw} {strip_marker(lines[j + 1]).strip()}".strip()
                    if line_matches_canonical(merged, canon_line):
                        to_mark = [j, j + 1]

            if to_mark is None:
                if matched_any:
                    break
                break

            for idx in to_mark:
                if lines[idx].strip() and not has_marker(lines[idx]):
                    lines[idx] = ">>> " + lines[idx]
                    added += 1

            matched_any = True
            cidx += 1
            j = to_mark[-1] + 1

    added += add_missing_markers_by_split_tags(lines, verse_map)
    return added


def add_missing_markers_fallback(lines: list[str], root_lines: set[str]) -> int:
    """Fallback add mode when parsed verse map is unavailable."""
    added = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or has_marker(line) or stripped.startswith("["):
            continue
        if SECTION_HDR_RE.match(stripped) or stripped.startswith("[ Image:"):
            continue
        if len(stripped) >= 100:
            continue
        if normalize(stripped) in root_lines:
            lines[i] = ">>> " + line
            added += 1
    return added


def fix_mapping(
    root_lines: set[str],
    root_loose: set[str],
    token_index: dict[str, list[list[str]]],
    verse_map: dict[str, list[str]],
    mapping_path: Path,
    write_changes: bool = True,
) -> tuple[int, int, int, int]:
    """Remove >>> from non-root lines; add >>> to root lines missing it."""
    content = mapping_path.read_text(encoding="utf-8")
    had_trailing_newline = content.endswith("\n")
    lines = content.splitlines()

    total_marked = 0
    removed = 0
    fuzzy_kept = 0

    for i, line in enumerate(lines):
        if not has_marker(line):
            continue
        total_marked += 1
        norm = normalize(strip_marker(line))
        kind = _root_match_kind(norm, root_lines, root_loose, token_index)
        if kind is None:
            lines[i] = strip_marker(line)
            removed += 1
        elif kind != "exact":
            fuzzy_kept += 1

    if verse_map:
        added = add_missing_markers_by_verse(lines, verse_map)
    else:
        added = add_missing_markers_fallback(lines, root_lines)

    out = "\n".join(lines)
    if had_trailing_newline:
        out += "\n"
    if write_changes:
        mapping_path.write_text(out, encoding="utf-8")
    return total_marked, removed, fuzzy_kept, added


def main():
    parser = argparse.ArgumentParser(description="Fix >>> markers in verse commentary mapping.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Compute and print proposed marker changes without writing the mapping file.",
    )
    args = parser.parse_args()

    src = get_root_source()
    print(f"Using root text from: {src}")
    root_lines, root_loose, token_index = build_root_line_index(src)
    print(f"Root text lines: {len(root_lines)}")
    verse_map = load_parsed_verse_map(PARSED)
    if verse_map:
        print(f"Verse map loaded from {PARSED}: {len(verse_map)} refs")
    else:
        print("Verse map unavailable; using fallback add-marker mode.")
    total, removed, fuzzy_kept, added = fix_mapping(
        root_lines,
        root_loose,
        token_index,
        verse_map,
        MAPPING,
        write_changes=not args.dry_run,
    )
    print(f">>> lines checked: {total}")
    print(f">>> removed (commentary mis-marked as verse): {removed}")
    print(f">>> kept via tolerant match: {fuzzy_kept}")
    print(f">>> added to root lines missing it: {added}")
    if args.dry_run:
        print(f"Dry run only; no changes written to {MAPPING}")
    else:
        print(f"Wrote {MAPPING}")


if __name__ == "__main__":
    main()
