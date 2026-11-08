#!/usr/bin/env node
// check-scheduled-checks.js — build lint: a `# CHECK AFTER <date>` marker must not be OVERDUE.
// Ported from the retired SourceVault.allScheduledChecks console tool (P2-T3 follow-up). Scans src/
// only; mirrors check-thin-wraps.js / check-stinks.js (line scanner; exit 0 clean / 1 violation).
//
// PURPOSE: a "time-bomb reminder" — drop `# CHECK AFTER <date>` next to a workaround / deferred
// decision that should be re-evaluated once <date> passes. This gate FAILS the build the first time it
// is built on/after that date, so the reminder can't rot unnoticed (the original tool found two markers
// dated Jan 2021 still sitting in the tree in 2026). To resolve: act on it, then either delete the
// marker or push the date forward. <date> is anything Date.parse understands, e.g.
//   # CHECK AFTER 1 Jan 2027 00:00:00 GMT
// A marker whose date is unparseable is also flagged (it can never fire, defeating the purpose).
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-scheduled-checks.js
// [--src=DIR] — the rail checks another src tree (a copy carrying a plant). That both rules BITE is proven on every
// build by check-scheduled-checks-selftest.js.

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs, dirArg } = require('./lib/cli-args');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, ['--src='], 'scheduled-checks');
rejectPositionalArgs(ARGV, 'scheduled-checks', 'a src tree is named with --src=DIR');
const SRC = dirArg(ARGV, '--src=', path.resolve(__dirname, '../src'), 'scheduled-checks');
const MARKER = /#\s*CHECK AFTER\s+(.+?)\s*$/i;   // in a comment, capture the date to end-of-line
const { coffeeMask } = require('./lib/coffee-mask');   // each file's comments, as the lexer reads them
const NOW = Date.now();

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.coffee')) acc.push(p);
  }
  return acc;
}

const overdue = [], malformed = [];
let markers = 0;
for (const p of walk(SRC, [])) {
  coffeeMask(fs.readFileSync(p, 'utf8'), path.relative(SRC, p)).forEach((l, i) => {
    const m = MARKER.exec(l.comment || '');
    if (!m) return;
    markers++;
    const when = Date.parse(m[1]);
    const at = { file: path.relative(SRC, p), line: i + 1, date: m[1] };
    if (Number.isNaN(when)) malformed.push(at);
    else if (when < NOW) overdue.push(at);
  });
}

console.log(`[scheduled-checks] ${markers} CHECK-AFTER marker(s) scanned.`);
if (overdue.length || malformed.length) {
  if (overdue.length) {
    console.error(`\n[scheduled-checks] FAIL -- ${overdue.length} CHECK-AFTER marker(s) are OVERDUE:`);
    for (const v of overdue) console.error(rules.fired('OVERDUE', `  ${v.file}:${v.line}  (due: ${v.date})`));
  }
  if (malformed.length) {
    console.error(`\n[scheduled-checks] FAIL -- ${malformed.length} CHECK-AFTER marker(s) have an unparseable date:`);
    for (const v of malformed) console.error(rules.fired('UNPARSEABLE_DATE', `  ${v.file}:${v.line}  (date: "${v.date}")`));
  }
  console.error('\nRe-evaluate the flagged code, then delete the marker or push its date forward.');
  process.exit(1);
}
console.log('[scheduled-checks] OK -- no overdue CHECK-AFTER markers.');
process.exit(0);
