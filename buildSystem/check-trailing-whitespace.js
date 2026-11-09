#!/usr/bin/env node
// check-trailing-whitespace.js — build lint: no trailing whitespace on a line that has CONTENT.
// Ported from the retired SourceVault.allTrailingWhiteSpaces console tool (P2-T3 follow-up). Reads the
// compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness); mirrors
// check-thin-wraps.js / check-stinks.js (line scanner; exit 0 clean / 1 violation).
//
// SCOPE: flags a line matching /\S[ \t]+$/ — i.e. a non-blank line ending in spaces/tabs. Lines that are
// ENTIRELY whitespace (blank-with-indent) are intentionally NOT flagged: they are invisible, harmless, and
// number in the hundreds; gating them would be pure churn for no readability gain. This matches the
// original tool's `[^\s#]...$` intent (trailing ws after real content). A CRLF line counts the same: the `\r` is
// the line ending, not content, so whitespace before it is trailing.
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-trailing-whitespace.js
// [--src=DIR] [--tests-repo=DIR] — the rails check another src tree or tests repo (a copy carrying a plant). That the
// rule BITES is proven on every build by check-trailing-whitespace-selftest.js.

const fs = require('fs');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'trailing-whitespace');
rejectPositionalArgs(ARGV, 'trailing-whitespace', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'trailing-whitespace');
const TRAILING = /\S[ \t]+\r?$/;   // non-blank line ending in whitespace (before a CRLF's \r too)

const violations = [];
let scanned = 0;
for (const p of compiledFiles(ROOTS)) {
  scanned++;
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  lines.forEach((l, i) => {
    if (TRAILING.test(l)) violations.push({ file: sourceName(p, ROOTS), line: i + 1 });
  });
}

console.log(`[trailing-whitespace] ${scanned} source(s) scanned.`);
if (violations.length) {
  console.error(`\n[trailing-whitespace] FAIL -- ${violations.length} line(s) have trailing whitespace after content:`);
  for (const v of violations) console.error(rules.fired('TRAILING_WHITESPACE', `  ${v.file}:${v.line}`));
  console.error('\nStrip the trailing spaces/tabs (an anchored `s/(\\S)[ \\t]+$/$1/` preserves indentation).');
  process.exit(1);
}
console.log('[trailing-whitespace] OK -- no trailing whitespace after content.');
process.exit(0);
