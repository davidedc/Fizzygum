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
// standing (docs/plans/constructor-parameter-conformance-plan.md §7c). This check is the honest
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

// Seeded 2026-08-16 at 20 and tightened to 9 the same day as P8 items 1b and 3 landed (the sweep
// started at 25). Every REMAINING site is a one-off; the two families are gone —
// `Appearance._paintInLocalScope` shed 8 when its two knobs became class-level declarations, and
// the demo buttons shed 3 when SimpleRectangularButtonWdgt took an options head.
// ⚠ Some survivors are `undefined` used as a MEANING rather than a skip (`_insertAddersSuchThat`'s
// axis is documented as "undefined is MEANINGFUL: content mode"; RectangularAppearance.paintStroke
// passes an absent appliedShadow because it is normal-pass-only). This regex cannot tell those from
// real holes — read the site before converting, and if it is genuinely a value, say so at the site.
const BASELINE = 9;

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
