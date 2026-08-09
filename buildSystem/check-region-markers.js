#!/usr/bin/env node
// check-region-markers.js — build gate RATCHETING the in-file region-exclusion mechanism (`»>>`)
// down to zero. Mirrors the check-stinks.js idiom: an inline per-kind baseline that may only FALL.
//
// WHAT A REGION IS. build.py carries three region regexes (HOMEPAGE_EXCLUSION_PARTS,
// MACROS_INCLUSION_PARTS, VIDEOPLAYER_INCLUSION_PARTS). Each strips the text between a
// `# »>> this part is …` opener comment and the next comment ending in `«`, so a marked region
// simply does not exist in the flavour that strips it.
//
// WHY IT IS BEING RETIRED (arc 3, docs/archive/build-arc-3-world-harmonization-plan.md). The
// mechanism was the only tool available when the OLD test system recognised widgets by string/ID
// and so froze the UI; it then accreted for eight+ years without an audit. The 2026-07-28 census
// found ~14 of 58 homepage sites are not dev/test code at all but PRODUCT code — core sizing and
// `_reLayout` machinery, class constants that become `nil` when stripped, public API — i.e. the
// homepage was shipping a silently truncated layout engine. A mechanism that can do that invisibly
// is the wrong mechanism: code is RE-HOMED (promoted, moved to the tests repo, or extracted into a
// collaborator class) so no marker is needed. Deliberately there is NO replacement marker syntax.
//
// THE RATCHET. Each kind carries the count of OPENERS currently tolerated in src/. The build FAILS
// when a kind EXCEEDS its baseline (someone added a region). When a count drops BELOW its baseline
// you have re-homed something: tighten the number here to lock the gain in — the gate prints the
// reminder. At baseline 0 the kind is a HARD rule and the corresponding regex is deleted from
// build.py (arc 3 Phase 6 does that for all three).
//
// It also checks PAIRING: an opener whose region never closes would silently swallow the rest of
// the file in the stripped flavour. That is a hard failure at any baseline.
//
// Scope: src/**/*.coffee only. Runs for every build flavour (the count is a property of the source,
// not of what is being built).

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');

// Baselines MEASURED by this engine. Arc 3 started at 58 homepage + 3 macros + 2 video-player = 63
// openers, all paired; each phase that re-homes sites tightens the number here to lock the gain in.
// Homepage: 58 (Phase 1) -> 37 (Phase 2 PROMOTE) -> 25 (Phase 3 DELETE) -> 12 (Phase 4 TESTS-REPO) -> 10 (Phase 5a folds) -> 5 (Phase 5b pinouts) -> 3 (Phase 5c demo split) -> 1 (Phase 5d world-menu split).
// ALL THREE ARE NOW ZERO, so every baseline is a HARD RULE: any occurrence fails the build, and
// build.py no longer carries a single region regex. The last site to go was BoxyAppearance's
// "pick inset..." row — its action method had ceased to exist (clicking it threw) but the row still
// RENDERED, so it was menu topology and waited for the phase that closes with a recapture wave.
const KINDS = [
  { id: 'homepage', baseline: 0,
    why: 'homepage-stripped regions — the census found product code among them; every site is re-homed by arc 3',
    open: /^[ \t]*#\s*»>>\s*this part is excluded from the fizzygum homepage build/ },
  { id: 'macros', baseline: 0,
    why: 'macro-only regions; they fold into the whole-file-marked src/macros/ family (which is arc 4 territory, not this gate)',
    open: /^[ \t]*#\s*»>>\s*this part is only needed for Macros/ },
  { id: 'videoplayer', baseline: 0,
    why: 'video-player-only regions; they fold into the whole-file-marked video-player family',
    open: /^[ \t]*#\s*»>>\s*this part is only needed for VideoPlayer/ },
];

// Any `»>>` line that matches no kind above is a marker the build does not understand — it strips
// nothing, so it is a lie in the source. Prose ABOUT the mechanism (this arc's own explanatory
// comments) is exempted with the marker below.
const PROSE = /#.*»>>.*\bmarkers?\b/;

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}

const counts = Object.fromEntries(KINDS.map(k => [k.id, 0]));
const unpaired = [];
const unknown = [];

for (const p of walk(SRC, [])) {
  const rel = path.relative(SRC, p);
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    if (!l.includes('»>>')) continue;
    const kind = KINDS.find(k => k.open.test(l));
    if (!kind) {
      if (!PROSE.test(l)) unknown.push(`${rel}:${i + 1}`);
      continue;
    }
    counts[kind.id]++;
    // pair it: the region ends at the next line carrying the closer character
    let j = i + 1;
    while (j < lines.length && !lines[j].includes('«')) j++;
    if (j >= lines.length) unpaired.push(`${rel}:${i + 1} (${kind.id})`);
  }
}

const total = KINDS.reduce((n, k) => n + counts[k.id], 0);
console.log(`[region-markers] scan done — ${total} region opener(s): ` +
  KINDS.map(k => `${k.id}=${counts[k.id]}/${k.baseline}`).join(' '));

let failed = false;

if (unknown.length) {
  console.error(`\n[region-markers] FAIL -- ${unknown.length} »>> marker(s) build.py does not recognise (they strip NOTHING):`);
  for (const u of unknown) console.error(`  ${u}`);
  failed = true;
}

if (unpaired.length) {
  console.error(`\n[region-markers] FAIL -- ${unpaired.length} region opener(s) with no closing « :`);
  for (const u of unpaired) console.error(`  ${u}`);
  console.error('An unclosed region swallows the rest of the file in the flavour that strips it.');
  failed = true;
}

for (const k of KINDS) {
  const n = counts[k.id];
  if (n > k.baseline) {
    console.error(`\n[region-markers] FAIL -- '${k.id}' regions: ${n} > baseline ${k.baseline}.`);
    console.error(`  ${k.why}`);
    console.error('  The region mechanism is being RETIRED: do not add a region, and do not invent a');
    console.error('  replacement marker syntax. RE-HOME the code instead — promote it (it is product),');
    console.error('  move it to ../Fizzygum-tests/Automator-and-test-harness-src/ (it is test machinery),');
    console.error('  or extract it into its own collaborator class.');
    failed = true;
  } else if (n < k.baseline) {
    console.log(`[region-markers] '${k.id}' is DOWN to ${n} (baseline ${k.baseline}) -- tighten the baseline in ${path.basename(__filename)} to lock the gain in.`);
  }
}

if (failed) process.exit(1);
console.log('[region-markers] OK -- no region added.');
process.exit(0);
