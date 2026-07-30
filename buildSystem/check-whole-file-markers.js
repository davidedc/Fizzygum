#!/usr/bin/env node
'use strict';
// check-whole-file-markers.js — build gate TOMBSTONING the per-FILE exclusion markers.
// Sibling of check-region-markers.js (which buried the per-REGION mechanism in arc 3): same idiom,
// an inline baseline per kind that may only fall, at 0 = a hard rule.
//
// WHAT A WHOLE-FILE MARKER WAS. A comment on (usually) a source file's first line:
//   # this file is excluded from the fizzygum homepage build     -> dropped from --homepage
//   # this file is only needed for Macros                        -> dropped from --homepage
//   # this file is only needed for VideoPlayer                   -> dropped from --homepage
// build.py matched all three with regexes and skipped the file. It was the LAST survivor of the
// "exclude code by pattern-matching comments in source text" family.
//
// WHY IT IS RETIRED (arc 4 phase 1, docs/plans/build-arc-4-dynamic-parts-plan.md §5.2).
// Not because it was broken -- it worked -- but because it could not answer the question the
// system had grown into. A marker states a file's fate INVISIBLY, one file at a time: to learn the
// shape of a production build you had to open 499 files. It cannot express which files belong
// TOGETHER, so it cannot express a PART, so it cannot support loading a slice on demand. And the
// census that preceded this arc found the predictable rot: 43 files carried the homepage marker,
// 2 carried the macros one, and the VideoPlayer regex had ZERO carriers -- a live exclusion rule
// in the build matching nothing at all, for who knows how long, invisible precisely because
// nothing gathered these facts in one place.
//
// WHAT REPLACED IT. buildSystem/parts.json: named parts, each owning directories, each declaring
// `inHomepage`. One file, whole partition visible at once. A part's absence is absorbed at call
// sites by the class-existence guard idiom (`if DemoMenus?`), which check-part-edges.js enforces.
//
// ⛔ DO NOT introduce a replacement marker syntax. Arc 3 learned this the hard way with regions and
// the lesson generalises: invisible text-level exclusion is the wrong tool, not a tool with the
// wrong spelling. If a file should not ship somewhere, put it in a part that does not ship there.
//
// Scope: src/**/*.coffee. Runs for every build flavour — the rule is a property of the source, not
// of what is being built. Documentation that DESCRIBES the retired mechanism (this file, parts.json,
// build.py, the plan docs, src/macros/CLAUDE.md) is outside that scope by construction.

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');
const REPO = path.resolve(__dirname, '..');

// Baselines MEASURED by this gate at the moment the mechanism died: 43 homepage + 2 macros +
// 0 video-player = 45 marker lines across 45 files, all removed in arc 4 phase 1. Every kind is
// therefore a HARD RULE at zero from the start -- there was no intermediate state to ratchet down
// through, because the plan's completion doctrine requires a retirement to finish inside its arc.
const KINDS = [
  {
    id: 'homepage',
    marker: '# this file is excluded from the fizzygum homepage build',
    baseline: 0,
    was: 43
  },
  {
    id: 'macros',
    marker: '# this file is only needed for Macros',
    baseline: 0,
    was: 2
  },
  {
    id: 'video-player',
    marker: '# this file is only needed for VideoPlayer',
    baseline: 0,
    was: 0
  }
];

function walk(dir, out) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isSymbolicLink()) continue;
    if (entry.isDirectory()) walk(p, out);
    else if (entry.isFile() && entry.name.endsWith('.coffee')) out.push(p);
  }
  return out;
}

const found = Object.create(null);
for (const k of KINDS) found[k.id] = [];

for (const file of walk(SRC, [])) {
  const rel = path.relative(REPO, file);
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    for (const k of KINDS) {
      if (trimmed === k.marker) found[k.id].push(`${rel}:${i + 1}`);
    }
  }
}

const total = KINDS.reduce((n, k) => n + found[k.id].length, 0);
console.log(`[whole-file-markers] scan done — ${total} marker(s): ` +
  KINDS.map(k => `${k.id}=${found[k.id].length}/${k.baseline}`).join(' '));

let failed = false;
for (const k of KINDS) {
  const n = found[k.id].length;
  if (n > k.baseline) {
    console.error(`\n[whole-file-markers] FAIL -- '${k.id}': ${n} > baseline ${k.baseline}.`);
    console.error(`  marker: ${k.marker}`);
    console.error(`  This mechanism is RETIRED (arc 4): a flavour excludes named PARTS, not files,`);
    console.error(`  and the partition lives in buildSystem/parts.json. Put the file in a part whose`);
    console.error(`  'inHomepage' (or requiresFlag) already says what you are trying to say, and make`);
    console.error(`  sure its call sites cope with the part's absence via 'if TheClass?'.`);
    console.error(`  ⛔ Do NOT invent a replacement marker syntax.`);
    for (const f of found[k.id]) console.error(`    ${f}`);
    failed = true;
  }
}

if (failed) process.exit(1);
console.log('[whole-file-markers] OK -- no whole-file exclusion marker; exclusion is by part.');
process.exit(0);
