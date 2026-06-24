#!/usr/bin/env node
// check-stinks.js — build gate for "STINKS": code smells we are driving to zero, each RATCHETED at
// a baseline count (mirrors buildSystem/check-dead-methods.js, which ratchets dead code via an
// allowlist; and check-layering.js, which fails on any violation).
//
// Each stink carries a `baseline` — the max occurrences currently tolerated. The build FAILS when a
// stink EXCEEDS its baseline (a regression). When a stink drops BELOW its baseline you have driven
// it down: tighten the baseline in THIS file to lock the gain in (the check prints a reminder). A
// stink at baseline 0 is a HARD rule — any occurrence fails the build. There is no separate
// allowlist file: the baseline lives inline next to the rule, since a smell is a count, not a set of
// named methods.
//
// Stink: settle-batch-with-core  --  `<anchor>.settleLayoutsOnceAfter => @_xxxCore()`
//   Using the BATCHING settler (settleLayoutsOnceAfter) with a single *Core thunk. A pure core is a
//   single mutation that does NOT re-enter the settle tier, so it wants the SINGLE-mutation settler
//   (mutateGeometryThenSettle). Reaching for the batch means the core still calls a NESTED public
//   setter, and the batch is masking that. Fix: make the core pure, then switch the wrapper to
//   mutateGeometryThenSettle. Baseline driven to 0 (2026-06-24): the 5 teardown/build wrappers
//   (fullDestroy/close/collapse/unCollapse/buildAndConnectChildren) were all flipped to
//   mutateGeometryThenSettle via "cores call cores" — now a hard rule, no new occurrence may land.

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');

const STINKS = [
  {
    id: 'settle-batch-with-core',
    baseline: 0,
    why: 'settleLayoutsOnceAfter (batch settler) wrapping a single *Core thunk -- a pure core wants the single-mutation mutateGeometryThenSettle; the batch masks a core that still reaches a nested public setter',
    re: /settleLayoutsOnceAfter\s*=>\s*@_\w+Core\b/,
  },
];

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}
function stripComment(line) { const i = line.indexOf('#'); return i < 0 ? line : line.slice(0, i); }

const files = walk(SRC, []);
let over = 0;        // total occurrences ABOVE baseline (a build failure)
let ratchetable = 0; // stinks now BELOW baseline (a chance to tighten)
for (const stink of STINKS) {
  const baseline = stink.baseline || 0;
  const hits = [];
  for (const p of files) {
    fs.readFileSync(p, 'utf8').split('\n').forEach((line, i) => {
      if (stink.re.test(stripComment(line))) hits.push(`${path.relative(SRC, p)}:${i + 1}: ${line.trim()}`);
    });
  }
  const n = hits.length;
  const tag = n > baseline ? 'FAIL' : n < baseline ? 'UNDER' : 'OK';
  console.log(`[stinks] ${stink.id}: ${n} site(s) (baseline ${baseline}) -- ${tag}`);
  if (n > baseline) {
    over += n - baseline;
    console.error(`    ${stink.why}`);
    for (const h of hits) console.error(`    ${h}`);
  } else if (n < baseline) {
    ratchetable++;
  }
}

if (ratchetable) {
  console.log(`[stinks] NOTE -- ${ratchetable} stink(s) now BELOW baseline; tighten its baseline in buildSystem/check-stinks.js to lock the gain in.`);
}

if (over) {
  console.error(`\n[stinks] FAIL -- ${over} occurrence(s) over baseline. Either fix the smell (preferred) or, if genuinely intentional, raise that stink's baseline in buildSystem/check-stinks.js with a one-line reason.`);
  process.exit(1);
}

console.log(`[stinks] OK -- all stinks within baseline.`);
process.exit(0);
