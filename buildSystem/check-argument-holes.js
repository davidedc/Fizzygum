#!/usr/bin/env node
// check-argument-holes.js — RATCHET on the hole test (R3 of
// docs/architecture/constructor-and-parameter-conventions.md):
//
//     if any call site must pass `undefined` to reach a later argument, the parameter list is wrong
//
// A hole is not a style blemish. It is PROOF that the skipped parameter is configuration rather
// than identity, and that no single positional order can serve every caller — the remedy is a
// trailing `opts = {}` (or, for a class exempt under §3, a reorder).
//
// ⚠⚠ WHY THIS EXISTS ALONGSIDE THE `positional-hole` STINK. That stink matches two `undefined`s
// ADJACENT ON ONE LINE. It is a fine instant alarm for the worst shape and it is HARD at 0 — but it
// is blind to the two commonest holes: a SINGLE `undefined` (`holder.add w, undefined, spec`) and
// one spread over a multi-line call. Reading its 0 as "the tree is clean" is exactly how the
// conformance arc came to be archived as complete and re-opened the same day with ~50 holes
// standing (docs/archive/constructor-parameter-conformance-plan.md §7c). This check is the honest
// count, and it shares ONE parser with `census-call-arity.js` so the gate and the advisory view can
// never disagree about what a hole is.
//
// SCOPE: `Fizzygum/src/**/*.coffee` only, deliberately.
//   - The sibling tests repo carries ~25 more holes, but its `SystemTest_*.js` metadata is PROSE in
//     string literals, which the tree-wide identifier sweep necessarily over-matches. A doc edit in
//     a test must never break the build. Sweep those with `census-call-arity.js --holes` by hand.
//   - `.call`/`.apply`/`.bind` are excluded by the shared `isHole`: there `undefined` is a foreign
//     API's THIS-arg, the ordinary idiom for "no receiver", not a skipped parameter.
//
// RATCHET, the check-stinks idiom: FAIL when the count EXCEEDS the baseline (a regression), and
// print a tighten-me note when it drops BELOW. Tighten the baseline in the SAME commit that drops
// it. The target is 0.

const path = require('path');
const census = require('./census-call-arity.js');

// Seeded at 20, tightened to 9 (P8), and to 2 at P9 — which is this check's FLOOR, not a way-point.
//
// ⚠⚠ THE REMAINING 2 ARE NOT HOLES, AND NO FUTURE SWEEP SHOULD "FIX" THEM. They are `undefined`
// used as a VALUE, which this regex cannot distinguish from a skipped parameter:
//   - RectangularAppearance.paintStroke      an absent appliedShadow MEANS "no shadow"
//   - Widget._setScaleFactorNoSettle         an absent rotation MEANS "leave it unchanged"
// Each is annotated at its call site. The test that separates the two cases, worked out by reading
// all nine of P8's survivors: a `undefined` is a HOLE when some OTHER caller of the same method
// OMITS that trailing tail — i.e. the parameter list gives this caller no shorter way to reach a
// later argument. When EVERY caller passes every argument (typically because the last one is a
// required block, as with _paintInLocalScope's bodyFn) or when no reordering can help (a symmetric
// two-slot partial-update record), the `undefined` is an operand with an absent value and the list
// is right. So: a rise here is a regression; reaching 0 is not a goal.
const BASELINE = 2;

const SRC = [path.join(census.ROOT, 'Fizzygum', 'src')];

const holes = census.collectHoles(SRC);

for (const r of holes) {
  console.log(`  ${r.file}:${r.line}  ${r.callee}  [ ${r.args.join(' | ')} ]`);
}

const n = holes.length;
if (n > BASELINE) {
  console.error(`\n[argument-holes] FAIL — ${n} site(s), baseline ${BASELINE}.`);
  console.error('A call punching `undefined` through to reach a later argument means the parameter');
  console.error('list is wrong (R3). Give the callee a trailing `opts = {}` and name the option, or');
  console.error('— for a class exempt under §3 of the convention doc — reorder so the commonly-passed');
  console.error('operand comes first. Law: docs/architecture/constructor-and-parameter-conventions.md');
  process.exit(1);
}
if (n < BASELINE) {
  console.log(`\n[argument-holes] ${n} site(s) (baseline ${BASELINE}) -- UNDER`);
  console.log(`NOTE: tighten the baseline to ${n} in buildSystem/check-argument-holes.js, in THIS commit.`);
} else {
  console.log(`\n[argument-holes] OK — ${n} site(s) (baseline ${BASELINE}).`);
}
