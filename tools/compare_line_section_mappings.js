#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const hierarchyPath = path.join(root, 'texts', 'verse_hierarchy_map.json');
const commentaryPath = path.join(root, 'texts', 'verse_commentary_mapping.txt');

const outJsonLineMapPath = path.join(root, 'texts', 'line_section_map_from_json.json');
const outCommentaryLineMapPath = path.join(
  root,
  'texts',
  'line_section_map_from_commentary.json'
);
const outMismatchJsonPath = path.join(root, 'texts', 'line_section_mismatches.json');
const outMismatchMdPath = path.join(root, 'texts', 'line_section_mismatches.md');

function normalizeTitle(s) {
  return String(s || '')
    .replace(/^\d+(?:\.\d+)*\.\s*/u, '')
    .replace(/\[[^\]]+\]/gu, ' ')
    .toLowerCase()
    .replace(/[\u2018\u2019]/gu, "'")
    .replace(/\b(?:the|that|this|these|those)\b/gu, ' ')
    .replace(/[^a-z0-9'\s]/gu, ' ')
    .replace(/\s+/gu, ' ')
    .trim();
}

function isSectionHeading(line) {
  return /^\d+(?:\.\d+)*\.\s+.+/.test(String(line || '').trim());
}

function extractHeading(line) {
  const t = String(line || '').trim();
  const colon = t.indexOf(':');
  return (colon > 0 ? t.slice(0, colon) : t).trim();
}

function formatRef(ch, verse, suffix) {
  return `${Number(ch)}.${Number(verse)}${suffix || ''}`;
}

function expandLineSuffixRange(startSuffix, endSuffix) {
  const all = ['a', 'b', 'c', 'd'];
  const start = startSuffix && startSuffix.length ? startSuffix[0] : 'a';
  const end =
    endSuffix && endSuffix.length ? endSuffix[endSuffix.length - 1] : 'd';
  const i = all.indexOf(start);
  const j = all.indexOf(end);
  if (i < 0 || j < 0 || i > j) return [];
  return all.slice(i, j + 1);
}

function extractVerseRefs(line) {
  const refs = [];
  const seen = new Set();
  const text = String(line || '');

  function add(ref) {
    if (!seen.has(ref)) {
      seen.add(ref);
      refs.push(ref);
    }
  }

  // Bracket refs: [9.101], [9.101ab], [9.101ab-9.101cd], [9.95-9.97]
  const bracketRe = /\[(\d+)\.(\d+)([a-d]*)(?:-(\d+)\.(\d+)([a-d]*))?\]/gi;
  let m;
  while ((m = bracketRe.exec(text)) !== null) {
    const c1 = Number(m[1]);
    const v1 = Number(m[2]);
    const s1 = m[3] || '';
    const hasRange = m[4] != null;
    if (!hasRange) {
      add(formatRef(c1, v1, s1));
      continue;
    }
    const c2 = Number(m[4]);
    const v2 = Number(m[5]);
    const s2 = m[6] || '';
    if (c1 === c2 && v1 === v2 && (s1 || s2)) {
      for (const l of expandLineSuffixRange(s1, s2)) {
        add(formatRef(c1, v1, l));
      }
      continue;
    }
    if (Number.isFinite(c1) && Number.isFinite(v1) && Number.isFinite(c2) && Number.isFinite(v2)) {
      for (let c = c1; c <= c2; c++) {
        const vs = c === c1 ? v1 : 1;
        const ve = c === c2 ? v2 : 999;
        for (let v = vs; v <= ve; v++) {
          add(formatRef(c, v, ''));
        }
      }
    }
  }

  // Bare ref line: 9.101 / 9.101ab / 9.101ab-9.101cd / 9.95-9.97
  const bareRe =
    /^(\d+)\.(\d+)([a-d]*)(?:-(\d+)\.(\d+)([a-d]*))?$/i;
  const t = text.trim();
  const b = bareRe.exec(t);
  if (b) {
    const c1 = Number(b[1]);
    const v1 = Number(b[2]);
    const s1 = b[3] || '';
    const hasRange = b[4] != null;
    if (!hasRange) {
      add(formatRef(c1, v1, s1));
    } else {
      const c2 = Number(b[4]);
      const v2 = Number(b[5]);
      const s2 = b[6] || '';
      if (c1 === c2 && v1 === v2 && (s1 || s2)) {
        for (const l of expandLineSuffixRange(s1, s2)) {
          add(formatRef(c1, v1, l));
        }
      } else {
        for (let c = c1; c <= c2; c++) {
          const vs = c === c1 ? v1 : 1;
          const ve = c === c2 ? v2 : 999;
          for (let v = vs; v <= ve; v++) {
            add(formatRef(c, v, ''));
          }
        }
      }
    }
  }

  return refs;
}

function parseRef(ref) {
  const m = /^(\d+)\.(\d+)([a-d]*)$/i.exec(ref);
  if (!m) return null;
  return { chapter: Number(m[1]), verse: Number(m[2]), suffix: (m[3] || '').toLowerCase() };
}

function expandRefToLines(ref) {
  const parsed = parseRef(ref);
  if (!parsed) return [];
  const letters = parsed.suffix
    ? [...new Set(parsed.suffix.split('').filter((c) => ['a', 'b', 'c', 'd'].includes(c)))]
    : ['a', 'b', 'c', 'd'];
  return letters.map((l) => `${parsed.chapter}.${parsed.verse}${l}`);
}

function lineSortKey(lineId) {
  const m = /^(\d+)\.(\d+)([a-d])$/i.exec(lineId);
  if (!m) return [Infinity, Infinity, Infinity];
  const lineOrder = { a: 1, b: 2, c: 3, d: 4 };
  return [Number(m[1]), Number(m[2]), lineOrder[m[3].toLowerCase()] || 9];
}

function sortLineIds(ids) {
  return ids.slice().sort((x, y) => {
    const a = lineSortKey(x);
    const b = lineSortKey(y);
    if (a[0] !== b[0]) return a[0] - b[0];
    if (a[1] !== b[1]) return a[1] - b[1];
    return a[2] - b[2];
  });
}

function compactLineLetters(letters) {
  const set = new Set(letters);
  const ordered = ['a', 'b', 'c', 'd'].filter((x) => set.has(x));
  if (ordered.length === 4) return '';
  return ordered.join('');
}

function lineToVerse(lineId) {
  const m = /^(\d+)\.(\d+)([a-d])$/i.exec(lineId);
  if (!m) return { verse: lineId, line: '' };
  return { verse: `${Number(m[1])}.${Number(m[2])}`, line: m[3].toLowerCase() };
}

function buildJsonLineMap(hierarchy) {
  const verseToPath = hierarchy.verseToPath || {};
  const refRows = [];
  for (const [ref, breadcrumb] of Object.entries(verseToPath)) {
    if (!Array.isArray(breadcrumb) || breadcrumb.length === 0) continue;
    const last = breadcrumb[breadcrumb.length - 1] || {};
    const sectionPath = String(last.section || last.path || '');
    const sectionTitle = String(last.title || '');
    const lines = expandRefToLines(ref);
    if (lines.length === 0) continue;
    refRows.push({
      ref,
      lines,
      lineCount: lines.length,
      sectionPath,
      sectionTitle,
    });
  }

  // More specific refs (fewer lines) win over broad refs.
  refRows.sort((a, b) => {
    if (a.lineCount !== b.lineCount) return a.lineCount - b.lineCount;
    return a.ref.localeCompare(b.ref, undefined, { numeric: true });
  });

  const lineMap = new Map();
  for (const row of refRows) {
    for (const line of row.lines) {
      if (!lineMap.has(line)) {
        lineMap.set(line, {
          line,
          verse: lineToVerse(line).verse,
          lineLetter: lineToVerse(line).line,
          sectionPath: row.sectionPath,
          sectionTitle: row.sectionTitle,
          sourceRef: row.ref,
          sourceSpecificity: row.lineCount,
        });
      }
    }
  }
  return lineMap;
}

function buildCommentaryLineMap(mappingText) {
  const lines = mappingText.split(/\r?\n/);
  let currentHeading = null;
  const lineMap = new Map(); // line -> Map(heading -> count)

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (isSectionHeading(line)) {
      currentHeading = extractHeading(line);
    }
    const refs = extractVerseRefs(line);
    if (!currentHeading || refs.length === 0) continue;

    for (const ref of refs) {
      for (const verseLine of expandRefToLines(ref)) {
        if (!lineMap.has(verseLine)) lineMap.set(verseLine, new Map());
        const headingCount = lineMap.get(verseLine);
        headingCount.set(
          currentHeading,
          (headingCount.get(currentHeading) || 0) + 1
        );
      }
    }
  }

  return lineMap;
}

function toCommentaryLineRows(lineMap) {
  const rows = [];
  for (const [line, headingCounts] of lineMap.entries()) {
    const headings = [...headingCounts.entries()]
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .map(([heading, count]) => ({ heading, count }));
    rows.push({
      line,
      verse: lineToVerse(line).verse,
      lineLetter: lineToVerse(line).line,
      closestHeading: headings.length ? headings[0].heading : null,
      headings,
    });
  }
  rows.sort((a, b) => {
    const ak = lineSortKey(a.line);
    const bk = lineSortKey(b.line);
    if (ak[0] !== bk[0]) return ak[0] - bk[0];
    if (ak[1] !== bk[1]) return ak[1] - bk[1];
    return ak[2] - bk[2];
  });
  return rows;
}

function buildMismatchReport(jsonLineMap, commentaryLineMap) {
  const allLines = new Set([...jsonLineMap.keys(), ...commentaryLineMap.keys()]);
  const mismatches = [];

  for (const line of sortLineIds([...allLines])) {
    const jsonRow = jsonLineMap.get(line) || null;
    const commentaryHeadingsMap = commentaryLineMap.get(line) || null;
    const commentaryHeadings = commentaryHeadingsMap
      ? [...commentaryHeadingsMap.entries()]
          .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
          .map(([heading]) => heading)
      : [];

    let type = null;
    if (!jsonRow && commentaryHeadings.length) {
      type = 'missing_in_json';
    } else if (jsonRow && commentaryHeadings.length === 0) {
      type = 'missing_in_commentary';
    } else if (jsonRow && commentaryHeadings.length) {
      const jsonNorm = normalizeTitle(jsonRow.sectionTitle);
      const hasMatch = commentaryHeadings.some((h) => normalizeTitle(h) === jsonNorm);
      if (!hasMatch) type = 'section_mismatch';
    }
    if (!type) continue;

    mismatches.push({
      line,
      verse: lineToVerse(line).verse,
      lineLetter: lineToVerse(line).line,
      type,
      jsonSectionPath: jsonRow ? jsonRow.sectionPath : null,
      jsonSectionTitle: jsonRow ? jsonRow.sectionTitle : null,
      jsonSourceRef: jsonRow ? jsonRow.sourceRef : null,
      commentaryHeadings,
    });
  }

  // Compact by verse + mismatch signature.
  const grouped = new Map();
  for (const m of mismatches) {
    const sig = [
      m.verse,
      m.type,
      m.jsonSectionPath || '',
      m.jsonSectionTitle || '',
      m.commentaryHeadings.map(normalizeTitle).sort().join(' || '),
    ].join(' | ');
    if (!grouped.has(sig)) {
      grouped.set(sig, {
        verse: m.verse,
        type: m.type,
        jsonSectionPath: m.jsonSectionPath,
        jsonSectionTitle: m.jsonSectionTitle,
        jsonSourceRef: m.jsonSourceRef,
        commentaryHeadings: m.commentaryHeadings,
        lines: [],
      });
    }
    grouped.get(sig).lines.push(m.lineLetter);
  }

  const compact = [];
  for (const g of grouped.values()) {
    const compactSuffix = compactLineLetters(g.lines);
    compact.push({
      ref: `${g.verse}${compactSuffix}`,
      verse: g.verse,
      lines: [...new Set(g.lines)].sort(),
      type: g.type,
      jsonSectionPath: g.jsonSectionPath,
      jsonSectionTitle: g.jsonSectionTitle,
      jsonSourceRef: g.jsonSourceRef,
      commentaryHeadings: g.commentaryHeadings,
    });
  }
  compact.sort((a, b) => {
    const [ac, av] = a.verse.split('.').map(Number);
    const [bc, bv] = b.verse.split('.').map(Number);
    if (ac !== bc) return ac - bc;
    if (av !== bv) return av - bv;
    return a.ref.localeCompare(b.ref);
  });

  return { detailed: mismatches, compact };
}

function main() {
  const hierarchy = JSON.parse(fs.readFileSync(hierarchyPath, 'utf8'));
  const mappingText = fs.readFileSync(commentaryPath, 'utf8');

  const jsonLineMap = buildJsonLineMap(hierarchy);
  const commentaryLineMap = buildCommentaryLineMap(mappingText);
  const commentaryRows = toCommentaryLineRows(commentaryLineMap);
  const mismatchReport = buildMismatchReport(jsonLineMap, commentaryLineMap);

  const jsonRows = sortLineIds([...jsonLineMap.keys()]).map((line) => jsonLineMap.get(line));

  fs.writeFileSync(outJsonLineMapPath, JSON.stringify({
    generated_at_utc: new Date().toISOString(),
    source: 'texts/verse_hierarchy_map.json',
    total_lines: jsonRows.length,
    rows: jsonRows,
  }, null, 2));

  fs.writeFileSync(outCommentaryLineMapPath, JSON.stringify({
    generated_at_utc: new Date().toISOString(),
    source: 'texts/verse_commentary_mapping.txt',
    rule: 'closest section heading above verse reference',
    total_lines: commentaryRows.length,
    rows: commentaryRows,
  }, null, 2));

  fs.writeFileSync(outMismatchJsonPath, JSON.stringify({
    generated_at_utc: new Date().toISOString(),
    compared_lines: new Set([...jsonLineMap.keys(), ...commentaryLineMap.keys()]).size,
    mismatched_lines: mismatchReport.detailed.length,
    compact_count: mismatchReport.compact.length,
    compact: mismatchReport.compact,
    detailed: mismatchReport.detailed,
  }, null, 2));

  const md = [];
  md.push('# Line-Level Section Mismatch Report');
  md.push('');
  md.push(`Generated: ${new Date().toISOString()}`);
  md.push('');
  md.push(`- JSON line assignments: ${jsonRows.length}`);
  md.push(`- Commentary line assignments: ${commentaryRows.length}`);
  md.push(`- Mismatched lines: ${mismatchReport.detailed.length}`);
  md.push(`- Compact mismatches: ${mismatchReport.compact.length}`);
  md.push('');
  md.push('## Compact Mismatch List');
  md.push('');
  if (mismatchReport.compact.length === 0) {
    md.push('None.');
  } else {
    for (const row of mismatchReport.compact) {
      const jsonLabel = row.jsonSectionPath
        ? `${row.jsonSectionPath} | ${row.jsonSectionTitle}`
        : '(missing in JSON)';
      const commentaryLabel = row.commentaryHeadings.length
        ? row.commentaryHeadings.slice(0, 3).join(' || ')
        : '(missing in commentary)';
      md.push(`- ${row.ref}`);
      md.push(`  - Type: ${row.type}`);
      md.push(`  - JSON: ${jsonLabel}`);
      md.push(`  - Commentary: ${commentaryLabel}`);
    }
  }
  md.push('');

  fs.writeFileSync(outMismatchMdPath, md.join('\n'));

  console.log(
    JSON.stringify(
      {
        json_lines: jsonRows.length,
        commentary_lines: commentaryRows.length,
        mismatched_lines: mismatchReport.detailed.length,
        compact_mismatches: mismatchReport.compact.length,
      },
      null,
      2
    )
  );
  console.log(`Wrote ${outJsonLineMapPath}`);
  console.log(`Wrote ${outCommentaryLineMapPath}`);
  console.log(`Wrote ${outMismatchJsonPath}`);
  console.log(`Wrote ${outMismatchMdPath}`);
}

main();
