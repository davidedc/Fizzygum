#!/usr/bin/env node
// check-thin-wraps.js — build lint: every public self-settling method must be the ONE canonical
// MECHANICAL THIN WRAP around its private *NoSettle twin. Mirrors check-dead-methods.js / check-stinks.js
// (line scanner; exit 0 clean / 1 violation).
//
// CANONICAL FORM: for a private `_<name>NoSettle`, the public `<name>` in the SAME class must, after
// comments/blank lines, be:
//     [ zero or more  `return if <cond>` / `return unless <cond>` idempotency guards ]
//     @mutateGeometryThenSettle => @_<name>NoSettle <args?>
// i.e. it does NO work of its own -- it guards, then hands the mutation to the core via the
// single-mutation settle tier. (mutateGeometryThenSettle anchors on `@`: a teardown that orphans `@`
// is still safe -- the orphan guard is checked at entry while `@` is attached and the flush is global,
// so `@` and the older `(@parent ? @)` anchor are provably equivalent; `@` is the standard.)
//
// EXEMPTION: a method that legitimately cannot be the canonical wrap carries a `# thin-wrap-exempt:
// <reason>` marker in the comment block directly above it (same in-code idiom as the layering lint's
// `# layout-apply-sanctioned`). The lint accepts the canonical wrap OR a marked method (reason
// required). There is NO central name-allowlist -- the justification lives at the method.
//
// One class per file (filename == class name). A `_<name>NoSettle` with no same-class `<name>` (e.g.
// BasementWdgt._addLostWidgetNoSettle, reached only internally) is skipped -- there is no public twin to
// constrain. (This is the wrap-SHAPE check the self-settling API relies on; check-layering.js enforces
// the complementary call-graph rule that the CORE reaches no public setter.)

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');

const HEADER = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;   // 2-space-indent class method header
const GUARD  = /^return\s+(if|unless)\b/;               // idempotency guard clause
const EXEMPT = /#\s*thin-wrap-exempt:\s*\S/;            // marker WITH a non-empty reason

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

const violations = [];
let checked = 0, exempt = 0;
for (const p of walk(SRC, [])) {
  const cls = path.basename(p, '.coffee');
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  const heads = [];
  lines.forEach((l, i) => { const m = HEADER.exec(l); if (m) heads.push({ name: m[1], i }); });
  const byName = new Map(heads.map((h, k) => [h.name, k]));
  for (let k = 0; k < heads.length; k++) {
    const m = /^_(.+)NoSettle$/.exec(heads[k].name);
    if (!m) continue;                                   // not a *NoSettle method
    const base = m[1];                                  // _fullDestroyNoSettle -> fullDestroy
    if (!byName.has(base)) continue;                    // no same-class public twin -> nothing to constrain
    const head = heads[byName.get(base)];
    // EXEMPTION: scan upward through the contiguous comment block directly above the public header.
    let marked = false;
    for (let j = head.i - 1; j >= 0 && /^\s*#/.test(lines[j]); j--) {
      if (EXEMPT.test(lines[j])) { marked = true; break; }
    }
    if (marked) { exempt++; continue; }
    // the public method's code lines (comments + blanks removed)
    const end = byName.get(base) + 1 < heads.length ? heads[byName.get(base) + 1].i : lines.length;
    const body = [];
    for (let j = head.i + 1; j < end; j++) { const c = stripComment(lines[j]).trim(); if (c) body.push(c); }
    // strip leading idempotency guards, then require exactly the canonical wrap
    let rest = body.slice();
    while (rest.length && GUARD.test(rest[0])) rest.shift();
    const canonical = new RegExp('^@mutateGeometryThenSettle\\s*=>\\s*@_' + base + 'NoSettle\\b');
    if (rest.length === 1 && canonical.test(rest[0])) checked++;
    else violations.push({ key: cls + '.' + base, file: path.relative(SRC, p), line: head.i + 1, body });
  }
}

console.log(`[thin-wraps] ${checked} canonical wrapper(s) + ${exempt} marked-exempt checked.`);
if (violations.length) {
  console.error(`\n[thin-wraps] FAIL -- ${violations.length} public method(s) own a _<name>NoSettle twin but are neither the canonical wrap nor marked exempt:`);
  for (const v of violations) {
    console.error(`  ${v.key}  (${v.file}:${v.line})`);
    console.error(`    body: ${JSON.stringify(v.body)}`);
  }
  console.error('\nCanonical: [return if/unless guards] then  @mutateGeometryThenSettle => @_<name>NoSettle <args>.');
  console.error('Or add a  # thin-wrap-exempt: <reason>  comment directly above the method (see the 3 in WorldWdgt).');
  process.exit(1);
}
console.log('[thin-wraps] OK -- every public/NoSettle pair is the canonical wrap or marked exempt.');
process.exit(0);
