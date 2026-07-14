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

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');
const HIT = /new ScriptWdgt\s+"""/;                       // start of a stringified-script literal
const SANCTION = /#\s*stringified-script-sanctioned:\s*\S/; // marker WITH a non-empty reason

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
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  lines.forEach((l, i) => {
    if (!HIT.test(l)) return;
    // sanction: on the line itself, or in the contiguous comment block directly above
    let ok = SANCTION.test(l);
    for (let j = i - 1; !ok && j >= 0 && /^\s*#/.test(lines[j]); j--) {
      if (SANCTION.test(lines[j])) ok = true;
    }
    if (ok) sanctioned++;
    else violations.push({ file: path.relative(SRC, p), line: i + 1 });
  });
}

console.log(`[stringified-scripts] scan done (${sanctioned} sanctioned).`);
if (violations.length) {
  console.error(`\n[stringified-scripts] FAIL -- ${violations.length} stringified ScriptWdgt literal(s) in core:`);
  for (const v of violations) console.error(`  ${v.file}:${v.line}`);
  console.error('\nMove the script into user code / a real class, or add a');
  console.error('`# stringified-script-sanctioned: <reason>` marker on/above the line.');
  process.exit(1);
}
console.log('[stringified-scripts] OK -- no stringified ScriptWdgt literals in core.');
process.exit(0);
