#!/usr/bin/env node
// check-trailing-whitespace.js — build lint: no trailing whitespace on a line that has CONTENT.
// Ported from the retired SourceVault.allTrailingWhiteSpaces console tool (P2-T3 follow-up). Scans
// src/ only; mirrors check-thin-wraps.js / check-stinks.js (line scanner; exit 0 clean / 1 violation).
//
// SCOPE: flags a line matching /\S[ \t]+$/ — i.e. a non-blank line ending in spaces/tabs. Lines that are
// ENTIRELY whitespace (blank-with-indent) are intentionally NOT flagged: they are invisible, harmless, and
// number in the hundreds; gating them would be pure churn for no readability gain. This matches the
// original tool's `[^\s#]...$` intent (trailing ws after real content).

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');
const TRAILING = /\S[ \t]+$/;   // non-blank line ending in whitespace

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
for (const p of walk(SRC, [])) {
  scanned++;
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  lines.forEach((l, i) => {
    if (TRAILING.test(l)) violations.push({ file: path.relative(SRC, p), line: i + 1 });
  });
}

console.log(`[trailing-whitespace] ${scanned} source(s) scanned.`);
if (violations.length) {
  console.error(`\n[trailing-whitespace] FAIL -- ${violations.length} line(s) have trailing whitespace after content:`);
  for (const v of violations) console.error(`  ${v.file}:${v.line}`);
  console.error('\nStrip the trailing spaces/tabs (an anchored `s/(\\S)[ \\t]+$/$1/` preserves indentation).');
  process.exit(1);
}
console.log('[trailing-whitespace] OK -- no trailing whitespace after content.');
process.exit(0);
