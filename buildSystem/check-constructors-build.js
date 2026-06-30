#!/usr/bin/env node
// check-constructors-build.js — build lint: a constructor MUST NOT build its own children inline.
// Child-building called on `this` (@add / @addMany / @addNoSettle / @_addNoSettle / @_addManyNoSettle / …)
// belongs in the _buildAndConnectChildrenNoSettle core, reached from the constructor via the settling
// wrapper @_buildAndConnectChildren() (or, for the ScrollPanelWdgt base, @_buildScrollFrame()). That is
// what makes EVERY constructor settle uniformly: the settle-tier FLUSHES a top-level `new X()` and
// AUTO-DEFERS one built in-flush, i.e. inside a callback (Widget._settleLayoutsAfter:
// `return coreThunk() if @isOrphan()`). This locks in the "all constructors settle" end-state
// (Topic 4 part 2): no constructor may re-introduce the old inline
//     @_addNoSettle <child> … ; @_invalidateLayout()
// defer-to-attach hack.
//
// Mirrors check-thin-wraps.js / check-dead-methods.js (line scanner; exit 0 clean / 1 violation).
//
// SCOPE: matches add* called on `this` (`@add`, `@_addNoSettle`, …). Building INTO a sub-child
// (`@contents._addNoSettle …`) is not matched — that `.`-qualified form is not `@`-prefixed — and is a
// rarer shape handled in the relevant core, not the constructor. The state machine mirrors the FNR audit
// awk (an `inctor` flag set on `constructor:` and cleared by the next 2-space class header), so it scans
// multi-line constructor headers correctly.
//
// EXEMPTION: a constructor that legitimately must build inline carries a
//     # constructor-build-exempt: <reason>
// marker in its body or the contiguous comment block directly above its header (reason required). Same
// in-code idiom as the layering lint's `# layout-apply-sanctioned`. There is NO central allowlist — the
// justification lives at the constructor.

const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '../src');

const METHOD = /^  ([A-Za-z_]\w*)\s*:/;             // 2-space-indent class method/field header
const BUILD  = /@_?add(Many)?(NoSettle)?[ (]/;      // @add / @addMany / @addNoSettle / @_addNoSettle / … on `this`
const EXEMPT = /#\s*constructor-build-exempt:\s*\S/; // marker WITH a non-empty reason

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
let exemptCount = 0;
for (const p of walk(SRC, [])) {
  const cls = path.basename(p, '.coffee');
  const lines = fs.readFileSync(p, 'utf8').split('\n');

  // Gather each constructor's body lines via the inctor state machine (a class can only have one, but
  // we stay general). A 2-space class header that is NOT `constructor` ends the current constructor.
  const ctors = [];
  let cur = null;
  for (let i = 0; i < lines.length; i++) {
    const m = METHOD.exec(lines[i]);
    if (m) {
      if (cur) { ctors.push(cur); cur = null; }
      if (m[1] === 'constructor') cur = { start: i, body: [] };
      continue;
    }
    if (cur) cur.body.push({ i, text: lines[i] });
  }
  if (cur) ctors.push(cur);

  for (const ctor of ctors) {
    const hits = ctor.body.filter(L => BUILD.test(stripComment(L.text)));
    if (!hits.length) continue;
    // exemption: marker in the body OR the contiguous comment block directly above the header
    let marked = ctor.body.some(L => EXEMPT.test(L.text));
    for (let j = ctor.start - 1; j >= 0 && /^\s*#/.test(lines[j]); j--) {
      if (EXEMPT.test(lines[j])) { marked = true; break; }
    }
    if (marked) { exemptCount++; continue; }
    for (const h of hits) violations.push({ cls, file: path.relative(SRC, p), line: h.i + 1, text: h.text.trim() });
  }
}

console.log(`[ctor-build] ${exemptCount} marked-exempt constructor(s) checked.`);
if (violations.length) {
  console.error(`\n[ctor-build] FAIL — ${violations.length} constructor build-call(s): a constructor must not build its own children inline.`);
  for (const v of violations) {
    console.error(`  ${v.cls}  (${v.file}:${v.line})`);
    console.error(`    ${v.text}`);
  }
  console.error('\nMove the child-building into  _buildAndConnectChildrenNoSettle  and have the constructor call the');
  console.error('settling wrapper  @_buildAndConnectChildren()  (orphan-settledness: `new X()` returns settled).');
  console.error('Or add a  # constructor-build-exempt: <reason>  comment in/above the constructor.');
  process.exit(1);
}
console.log('[ctor-build] OK — no constructor builds its own children inline.');
process.exit(0);
