#!/usr/bin/env node
// check-stinks.js — reports "STINKS": code smells we want to DRIVE TO ZERO over time.
//
// A stink is NOT a build failure (contrast check-layering.js / check-dead-methods.js, which FAIL).
// It is reported on every build so the count stays visible and trends to zero. ALWAYS exits 0.
//
// Stink: settle-batch-with-core  --  `<anchor>.settleLayoutsOnceAfter => @_xxxCore()`
//   Using the BATCHING settler (settleLayoutsOnceAfter) with a single *Core thunk. A pure core is a
//   single mutation that does NOT re-enter the settle tier, so it wants the SINGLE-mutation settler
//   (mutateGeometryThenSettle). Reaching for the batch means the core still calls a NESTED public
//   setter, and the batch is masking that. Fix: make the core pure, then switch the wrapper to
//   mutateGeometryThenSettle.

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');

const STINKS = [
  {
    id: 'settle-batch-with-core',
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
let total = 0;
for (const stink of STINKS) {
  const hits = [];
  for (const p of files) {
    fs.readFileSync(p, 'utf8').split('\n').forEach((line, i) => {
      if (stink.re.test(stripComment(line))) hits.push(`${path.relative(SRC, p)}:${i + 1}: ${line.trim()}`);
    });
  }
  total += hits.length;
  console.log(`[stinks] ${stink.id}: ${hits.length} site(s) -- ${stink.why}`);
  for (const h of hits) console.log(`    ${h}`);
}
console.log(`[stinks] TOTAL: ${total} stink(s) to drive to zero (non-blocking).`);
process.exit(0);
