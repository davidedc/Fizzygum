#!/usr/bin/env node
// check-relayout-repaints.js — TOMBSTONE for the retired paired damage-suppression verbs
// (repaint-as-one-unit arc, 2026-08-11; formerly the [INV-1] covering-repaint lint).
//
// [INV-1] — "a `_reLayoutSelf` that suppresses change-tracking MUST issue a covering
// `_fullChanged()` after its last re-enable" (born from the 2026-07 D2 edit/view-toggle
// ghosts, docs/archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md §2) — is now
// STRUCTURAL: bulk child positioning coalesces through `Widget._repaintAsOneUnit fn`, whose
// `finally` both restores `world._damageSuppressionDepth` and issues the owner's covering
// repaint, so neither half can be forgotten or lost to an exception. The runtime twin
// (the paint-truthfulness audit, Fizzygum-tests scripts/run-paint-audit.js) is unchanged.
//
// What is left to lint is only that nobody resurrects the retired imperative spelling:
// `disableTrackChanges` / `maybeEnableTrackChanges` (world verbs, paired by caller
// discipline) must not reappear anywhere in shipping src or the harness src — a caller
// wanting a suppression window wants `@_repaintAsOneUnit =>` instead. Mirrors the other
// retired-mechanism tombstones (check-region-markers.js, check-whole-file-markers.js):
// the gate slot stays occupied so the retirement cannot silently un-happen.
//
// Exit 0 clean / 1 violation.

const fs = require('fs');
const path = require('path');

const ROOTS = [
  path.resolve(__dirname, '../src'),
  // the harness compiles into the same world — a resurrection there is just as live
  path.resolve(__dirname, '../../Fizzygum-tests/Automator-and-test-harness-src'),
];

const RETIRED = /\b(disableTrackChanges|maybeEnableTrackChanges)\b/;

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}

const violations = [];
let scanned = 0;
for (const root of ROOTS) {
  for (const p of walk(root, [])) {
    scanned++;
    const lines = fs.readFileSync(p, 'utf8').split('\n');
    lines.forEach((l, i) => {
      if (RETIRED.test(l)) violations.push({ file: p, line: i + 1, text: l.trim() });
    });
  }
}

if (violations.length) {
  console.error(`\n[relayout-repaints] FAIL -- ${violations.length} occurrence(s) of the RETIRED paired suppression verbs (deleted 2026-08-11, repaint-as-one-unit arc):`);
  for (const v of violations) {
    console.error(`  ${v.file}:${v.line}  ${v.text}`);
  }
  console.error('\nThe imperative disable/enable pair is retired: pairing and the covering repaint were caller');
  console.error('obligations, and both failure modes (a leaked frame, a forgotten cover) shipped real bugs.');
  console.error('Wrap the bulk child-positioning pass in the self-balancing, self-covering block instead:');
  console.error('       @_repaintAsOneUnit =>');
  console.error('         <position children via _apply*/_reLayout tiers>');
  console.error('(Widget._repaintAsOneUnit — suppression depth and covering @_fullChanged both restored in `finally`.)');
  process.exit(1);
}
console.log(`[relayout-repaints] OK -- ${scanned} file(s): the retired disableTrackChanges/maybeEnableTrackChanges spelling is extinct ([INV-1] is structural in Widget._repaintAsOneUnit).`);
process.exit(0);
