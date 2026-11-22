#!/usr/bin/env node
// check-scheduled-checks.js — build lint: a `# CHECK AFTER <date>` marker must not be OVERDUE.
// Ported from the retired SourceVault.allScheduledChecks console tool (P2-T3 follow-up). Reads the
// compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness); mirrors
// check-thin-wraps.js / check-stinks.js (line scanner; exit 0 clean / 1 violation).
//
// PURPOSE: a "time-bomb reminder" — drop `# CHECK AFTER <date>` next to a workaround / deferred
// decision that should be re-evaluated once <date> passes. This gate FAILS the build the first time it
// is built on/after that date, so the reminder can't rot unnoticed (the original tool found two markers
// dated Jan 2021 still sitting in the tree in 2026). To resolve: act on it, then delete the marker; a later
// date is right only when the decision waits on something the comment names, and a failing run prints that
// advice (lib/gate-advice.js). <date> is anything Date.parse understands, e.g.
//   # CHECK AFTER 1 Jan 2027 00:00:00 GMT
// A marker whose date is unparseable is also flagged (it can never fire, defeating the purpose).
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-scheduled-checks.js
// [--src=DIR] [--tests-repo=DIR] — the rails check another src tree or tests repo (a copy carrying a plant). That
// both rules BITE is proven on every build by check-scheduled-checks-selftest.js.

const fs = require('fs');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);
const { adviceLines, advisedAmong } = require('./lib/gate-advice');

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'scheduled-checks');
rejectPositionalArgs(ARGV, 'scheduled-checks', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'scheduled-checks');
const MARKER = /#\s*CHECK AFTER\s+(.+?)\s*$/i;   // in a comment, capture the date to end-of-line
const { coffeeMask } = require('./lib/coffee-mask');   // each file's comments, as the lexer reads them
const NOW = Date.now();

const overdue = [], malformed = [];
let markers = 0;
for (const p of compiledFiles(ROOTS)) {
  coffeeMask(fs.readFileSync(p, 'utf8'), sourceName(p, ROOTS)).forEach((l, i) => {
    const m = MARKER.exec(l.comment || '');
    if (!m) return;
    markers++;
    const when = Date.parse(m[1]);
    const at = { file: sourceName(p, ROOTS), line: i + 1, date: m[1] };
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
    console.error('A marker whose date Date.parse cannot read never fires: write one it reads (`# CHECK AFTER 1 Jan 2027 00:00:00 GMT`).');
  }
  // after the whole report: what an overdue reminder asks, its quiet fix and the right answer (lib/gate-advice.js)
  const advised = advisedAmong(rules.gate, rules.firedIds);
  if (advised.length) { console.error(''); for (const l of adviceLines(rules.gate, advised)) console.error(l); }
  process.exit(1);
}
console.log('[scheduled-checks] OK -- no overdue CHECK-AFTER markers.');
process.exit(0);
