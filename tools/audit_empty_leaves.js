#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const mapPath = path.join(root, 'texts', 'verse_hierarchy_map.json');
const mappingPath = path.join(root, 'texts', 'verse_commentary_mapping.txt');
const reportJsonPath = path.join(root, 'texts', 'empty_leaf_audit.json');
const reportMdPath = path.join(root, 'texts', 'empty_leaf_audit.md');

function normalize(s) {
  return s
    .toLowerCase()
    .replace(/[\u2018\u2019]/g, "'")
    .replace(/\[[^\]]*\]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/[:\.,;]+$/g, '')
    .trim();
}

function stripNumberPrefix(s) {
  return s.replace(/^\d+(?:\.\d+)*\.\s*/, '').trim();
}

function isSectionHeading(line) {
  return /^\d+(?:\.\d+)*\.\s+.+/.test(line.trim());
}

function extractHeading(line) {
  const t = line.trim();
  const colon = t.indexOf(':');
  return colon > 0 ? t.slice(0, colon).trim() : t;
}

function extractVerseRefs(line) {
  const refs = [];
  const re = /\[(\d+\.\d+)([a-d]*)(?:-(\d+\.\d+)[a-d]*)?\]/g;
  let m;
  while ((m = re.exec(line)) !== null) {
    const start = m[1];
    const suffix = m[2] || '';
    const end = m[3];
    if (end) {
      const [sc, sv] = start.split('.').map((x) => parseInt(x, 10));
      const [ec, ev] = end.split('.').map((x) => parseInt(x, 10));
      if (Number.isFinite(sc) && Number.isFinite(sv) && Number.isFinite(ec) && Number.isFinite(ev)) {
        for (let c = sc; c <= ec; c++) {
          const vStart = c === sc ? sv : 1;
          const vEnd = c === ec ? ev : 999;
          for (let v = vStart; v <= vEnd; v++) refs.push(`${c}.${v}`);
        }
      } else {
        refs.push(start + suffix);
      }
    } else {
      refs.push(start + suffix);
    }
  }
  return refs;
}

function parseMapping(mappingContent) {
  const lines = mappingContent.split(/\r?\n/);
  const verseToHeading = new Map();
  const verseToContext = new Map();
  let currentHeading = null;

  function previousNonEmptyLine(idx) {
    for (let j = idx - 1; j >= 0; j--) {
      if (lines[j].trim() !== '') return lines[j];
    }
    return null;
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (isSectionHeading(line)) currentHeading = extractHeading(line);

    const refs = extractVerseRefs(line);
    if (refs.length === 0) continue;

    let targetHeading = null;
    if (isSectionHeading(line)) {
      targetHeading = extractHeading(line);
    } else {
      const nextIdx = i + 1;
      const nextIsHeading = nextIdx < lines.length && isSectionHeading(lines[nextIdx]);
      const prev = previousNonEmptyLine(i);
      const prevIsHeading = prev != null && isSectionHeading(prev);

      if (nextIsHeading && prevIsHeading) {
        targetHeading = extractHeading(lines[nextIdx]);
      } else {
        targetHeading = currentHeading;
      }

      if (!targetHeading) {
        for (let j = i - 1; j >= 0; j--) {
          if (isSectionHeading(lines[j])) {
            targetHeading = extractHeading(lines[j]);
            break;
          }
        }
      }
    }

    if (!targetHeading) continue;

    const context = [];
    for (let j = i - 1; j >= 0 && j >= i - 25; j--) {
      if (isSectionHeading(lines[j])) context.push(extractHeading(lines[j]));
    }

    for (const ref of refs) {
      verseToHeading.set(ref, targetHeading);
      verseToContext.set(ref, context);
    }
  }

  return { verseToHeading, verseToContext };
}

function collectLeaves(sections) {
  const leaves = [];
  function walk(node, chain) {
    if (!node || typeof node !== 'object') return;
    const title = String(node.title || '');
    const path = String(node.path || '');
    const verses = Array.isArray(node.verses) ? node.verses.slice() : [];
    const children = Array.isArray(node.children) ? node.children : [];
    const nextChain = [...chain, { path, title }];
    if (children.length === 0) {
      if (!path || !title) return;
      leaves.push({
        path,
        title,
        titleNorm: normalize(stripNumberPrefix(title)),
        verses,
        chain: nextChain,
      });
      return;
    }
    for (const child of children) walk(child, nextChain);
  }
  for (const s of sections) walk(s, []);
  return leaves;
}

function buildRefCurrentPath(verseToPath) {
  const out = new Map();
  for (const [ref, breadcrumb] of Object.entries(verseToPath)) {
    if (!Array.isArray(breadcrumb) || breadcrumb.length === 0) continue;
    const last = breadcrumb[breadcrumb.length - 1];
    const path = String((last && (last.section || last.path)) || '');
    out.set(ref, path);
  }
  return out;
}

function headingCouldTargetLeaf(headingNorm, leafNorm) {
  if (!headingNorm || !leafNorm) return false;
  if (headingNorm === leafNorm) return true;
  if (headingNorm.startsWith(leafNorm + ',')) return true;
  if (headingNorm.startsWith(leafNorm + ' i.e')) return true;
  return false;
}

function classifyLeaf(leaf, refsForLeaf, verseToContext, refCurrentPath) {
  if (refsForLeaf.length === 0) {
    return {
      classification: 'expected_empty',
      reason: 'No direct mapping heading found for this leaf title',
    };
  }

  const ancestorNorms = leaf.chain
    .slice(0, -1)
    .map((c) => normalize(stripNumberPrefix(c.title)))
    .filter(Boolean);

  const directAssignments = refsForLeaf.filter((r) => refCurrentPath.get(r.ref) === leaf.path);
  if (directAssignments.length > 0) {
    return {
      classification: 'index_inconsistency',
      reason: 'verseToPath points here but leaf verses array is empty',
      sampleRefs: directAssignments.slice(0, 5).map((x) => x.ref),
    };
  }

  let matchedByContext = 0;
  const conflicts = [];

  for (const row of refsForLeaf) {
    const context = verseToContext.get(row.ref) || [];
    const contextNorms = new Set(context.map((h) => normalize(stripNumberPrefix(h))).filter(Boolean));
    const contextHit = ancestorNorms.some((a) => contextNorms.has(a));
    if (contextHit) {
      matchedByContext += 1;
      conflicts.push({ ref: row.ref, currentPath: refCurrentPath.get(row.ref) || null, heading: row.heading });
    }
  }

  if (matchedByContext > 0) {
    return {
      classification: 'suspicious_misassigned',
      reason: 'Mapping refs for this heading exist with matching ancestor context, but are assigned to other leaves',
      sampleRefs: conflicts.slice(0, 8),
      matchCount: matchedByContext,
    };
  }

  return {
    classification: 'ambiguous_empty',
    reason: 'Matching heading exists but context did not reliably match this leaf',
    sampleRefs: refsForLeaf.slice(0, 5).map((x) => ({ ref: x.ref, currentPath: refCurrentPath.get(x.ref) || null })),
  };
}

function main() {
  const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'));
  const mappingContent = fs.readFileSync(mappingPath, 'utf8');

  const sections = map.sections || [];
  const verseToPath = map.verseToPath || {};

  const { verseToHeading, verseToContext } = parseMapping(mappingContent);
  const leaves = collectLeaves(sections);
  const emptyLeaves = leaves.filter((l) => l.verses.length === 0);
  const refCurrentPath = buildRefCurrentPath(verseToPath);

  const refsByHeadingNorm = new Map();
  for (const [ref, heading] of verseToHeading.entries()) {
    const norm = normalize(stripNumberPrefix(heading));
    if (!refsByHeadingNorm.has(norm)) refsByHeadingNorm.set(norm, []);
    refsByHeadingNorm.get(norm).push({ ref, heading });
  }

  const results = [];
  for (const leaf of emptyLeaves) {
    const candidateRefs = [];
    for (const [headingNorm, rows] of refsByHeadingNorm.entries()) {
      if (!headingCouldTargetLeaf(headingNorm, leaf.titleNorm)) continue;
      candidateRefs.push(...rows);
    }

    const classification = classifyLeaf(leaf, candidateRefs, verseToContext, refCurrentPath);
    results.push({
      path: leaf.path,
      title: leaf.title,
      chain: leaf.chain,
      ...classification,
    });
  }

  results.sort((a, b) => a.path.localeCompare(b.path, undefined, { numeric: true }));

  const counts = {
    total_leaves: leaves.length,
    empty_leaves: emptyLeaves.length,
    suspicious_misassigned: results.filter((r) => r.classification === 'suspicious_misassigned').length,
    ambiguous_empty: results.filter((r) => r.classification === 'ambiguous_empty').length,
    expected_empty: results.filter((r) => r.classification === 'expected_empty').length,
    index_inconsistency: results.filter((r) => r.classification === 'index_inconsistency').length,
  };

  const report = {
    generated_at_utc: new Date().toISOString(),
    counts,
    results,
  };

  fs.writeFileSync(reportJsonPath, JSON.stringify(report, null, 2));

  const lines = [];
  lines.push('# Empty Leaf Audit');
  lines.push('');
  lines.push(`Generated: ${report.generated_at_utc}`);
  lines.push('');
  lines.push('## Summary');
  lines.push('');
  lines.push(`- Total leaves: ${counts.total_leaves}`);
  lines.push(`- Empty leaves: ${counts.empty_leaves}`);
  lines.push(`- Suspicious misassigned: ${counts.suspicious_misassigned}`);
  lines.push(`- Ambiguous: ${counts.ambiguous_empty}`);
  lines.push(`- Expected empty: ${counts.expected_empty}`);
  lines.push(`- Index inconsistencies: ${counts.index_inconsistency}`);
  lines.push('');

  function emitSection(title, key) {
    const rows = results.filter((r) => r.classification === key);
    lines.push(`## ${title} (${rows.length})`);
    lines.push('');
    if (rows.length === 0) {
      lines.push('None.');
      lines.push('');
      return;
    }
    for (const r of rows) {
      lines.push(`- ${r.path} | ${r.title}`);
      lines.push(`  - Reason: ${r.reason}`);
      if (r.sampleRefs && r.sampleRefs.length > 0) {
        const refBits = r.sampleRefs.map((s) => {
          if (typeof s === 'string') return s;
          const cur = s.currentPath ? ` -> ${s.currentPath}` : '';
          return `${s.ref}${cur}`;
        });
        lines.push(`  - Sample refs: ${refBits.join(', ')}`);
      }
    }
    lines.push('');
  }

  emitSection('Suspicious Misassigned', 'suspicious_misassigned');
  emitSection('Ambiguous Empty', 'ambiguous_empty');
  emitSection('Expected Empty', 'expected_empty');
  emitSection('Index Inconsistency', 'index_inconsistency');

  fs.writeFileSync(reportMdPath, lines.join('\n'));

  console.log(JSON.stringify(counts));
  console.log(`Wrote ${reportJsonPath}`);
  console.log(`Wrote ${reportMdPath}`);
}

main();
