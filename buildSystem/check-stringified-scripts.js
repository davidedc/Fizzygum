#!/usr/bin/env node
// check-stringified-scripts.js — build lint: no stringified-code ScriptWdgt literals in core source.
// Ported from the retired SourceVault.allSourcesContainingStringifiedCodeForScript console tool (P2-T3
// follow-up). Scans src/ only; mirrors check-thin-wraps.js / check-stinks.js (line scanner; exit 0
// clean / 1 violation).
//
// POLICY: stringified code (`scriptWdgt = new ScriptWdgt """..."""`) should be rare — it belongs in
// USER code, not the core framework, and even there is ideally temporary and eventually migrated into a
// real class. Core is at 0 today; this gate keeps it there. A genuine exception carries a
// `# stringified-script-sanctioned: <reason>` marker on the line or in the comment block directly above.
// Any string handed to the constructor on its own line counts — a `"""` or `'''` block, a one-line string, with or
// without parentheses; a block string opened on the NEXT line is not seen.
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-stringified-scripts.js
// [--src=DIR] — the rail checks another src tree (a copy carrying a plant). That the rule BITES, and that both
// sanction placements excuse it, is proven on every build by check-stringified-scripts-selftest.js.

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs, dirArg } = require('./lib/cli-args');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, ['--src='], 'stringified-scripts');
rejectPositionalArgs(ARGV, 'stringified-scripts', 'a src tree is named with --src=DIR');
const SRC = dirArg(ARGV, '--src=', path.resolve(__dirname, '../src'), 'stringified-scripts');
const HIT = /new ScriptWdgt\b\s*\(?\s*["']/;               // a string handed to the constructor: stringified code
const SANCTION = /#\s*stringified-script-sanctioned:\s*\S/; // marker WITH a non-empty reason
// each file is read through lib/coffee-mask.js: a hit is matched on bare code (comments and literal contents blanked,
// a literal's opening quote kept — the string handed to the constructor is the signal), the marker read from a comment
const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');

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
let sanctioned = 0;
for (const p of walk(SRC, [])) {
  const masked = coffeeMask(fs.readFileSync(p, 'utf8'), path.relative(SRC, p));
  masked.forEach((l, i) => {
    if (!HIT.test(l.bare)) return;
    // sanction: on the line itself, or in the contiguous comment block directly above
    let ok = SANCTION.test(l.comment || '');
    for (let j = i - 1; !ok && j >= 0 && isCommentOnly(masked[j]); j--) {
      if (SANCTION.test(masked[j].comment)) ok = true;
    }
    if (ok) sanctioned++;
    else violations.push({ file: path.relative(SRC, p), line: i + 1 });
  });
}

console.log(`[stringified-scripts] scan done (${sanctioned} sanctioned).`);
if (violations.length) {
  console.error(`\n[stringified-scripts] FAIL -- ${violations.length} stringified ScriptWdgt literal(s) in core:`);
  for (const v of violations) console.error(rules.fired('STRINGIFIED_SCRIPT', `  ${v.file}:${v.line}`));
  console.error('\nMove the script into user code / a real class, or add a');
  console.error('`# stringified-script-sanctioned: <reason>` marker on/above the line.');
  process.exit(1);
}
console.log('[stringified-scripts] OK -- no stringified ScriptWdgt literals in core.');
process.exit(0);
