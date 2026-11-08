#!/usr/bin/env node
// check-constructors-build.js — build lint: a constructor MUST NOT build its own children inline.
// Child-building called on `this` (@add / @addMany / @addNoSettle / @_addNoSettle / @_addManyNoSettle / …)
// belongs in the _buildAndConnectChildrenNoSettle core, reached from the constructor via the settling
// wrapper @_buildAndConnectChildren() (or, for the ViewportWdgt base, @_buildViewportChrome()). That is
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

// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-constructors-build.js
// [--src=DIR] — the rail checks another src tree (a copy carrying a plant). That the rule BITES — a one-line
// constructor too — and that both marker placements excuse it, is proven on every build by
// check-constructors-build-selftest.js.

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs, dirArg } = require('./lib/cli-args');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, ['--src='], 'ctor-build');
rejectPositionalArgs(ARGV, 'ctor-build', 'a src tree is named with --src=DIR');
const SRC = dirArg(ARGV, '--src=', path.resolve(__dirname, '../src'), 'ctor-build');

const METHOD = /^  (@?[A-Za-z_]\w*)\s*:/;           // 2-space-indent class member header, class-side (`@name:`) too
const BUILD  = /@_{0,2}add(Many)?(NoSettle)?[ (]/;  // @add / @addMany / @addNoSettle / @_addNoSettle / @__add / … on `this`
                                                    // (the __add structural LEAF counts too — a ctor building through it
                                                    // is still inline child-building, one tier deeper; the menu/slider
                                                    // family that used it was converted 2026-07-12, see
                                                    // docs/archive/menu-slider-ctor-conversion-plan.md)
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
// each file is read through lib/coffee-mask.js: a build call is matched on bare code, the marker read from a comment
const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');

const violations = [];
let exemptCount = 0;
for (const p of walk(SRC, [])) {
  const cls = path.basename(p, '.coffee');
  const text = fs.readFileSync(p, 'utf8');
  const lines = text.split('\n');
  const masked = coffeeMask(text, path.relative(SRC, p));
  const marked = (j) => EXEMPT.test(masked[j].comment || '');

  // Gather each constructor's body lines via the inctor state machine (a class can only have one, but
  // we stay general). A 2-space class header that is NOT `constructor` ends the current constructor.
  const ctors = [];
  let cur = null;
  for (let i = 0; i < lines.length; i++) {
    const m = METHOD.exec(lines[i]);
    if (m) {
      if (cur) { ctors.push(cur); cur = null; }
      if (m[1] === 'constructor') {
        cur = { start: i, body: [] };
        // a ONE-LINE constructor carries its body after the arrow: read it like a body line
        const arrow = masked[i].bare.search(/[-=]>/);
        if (arrow >= 0 && masked[i].bare.slice(arrow + 2).trim()) cur.body.push({ i, text: lines[i].slice(arrow + 2), code: ' '.repeat(arrow + 2) + masked[i].bare.slice(arrow + 2) });
      }
      continue;
    }
    if (cur) cur.body.push({ i, text: lines[i], code: masked[i].bare });
  }
  if (cur) ctors.push(cur);

  for (const ctor of ctors) {
    const hits = ctor.body.filter(L => BUILD.test(L.code));
    if (!hits.length) continue;
    // exemption: marker in the body OR the contiguous comment block directly above the header
    let exempt = ctor.body.some(L => marked(L.i));
    for (let j = ctor.start - 1; j >= 0 && isCommentOnly(masked[j]); j--) {
      if (marked(j)) { exempt = true; break; }
    }
    if (exempt) { exemptCount++; continue; }
    for (const h of hits) violations.push({ cls, file: path.relative(SRC, p), line: h.i + 1, text: h.text.trim() });
  }
}

console.log(`[ctor-build] ${exemptCount} marked-exempt constructor(s) checked.`);
if (violations.length) {
  console.error(`\n[ctor-build] FAIL — ${violations.length} constructor build-call(s): a constructor must not build its own children inline.`);
  for (const v of violations) {
    console.error(rules.fired('CTOR_BUILDS_CHILDREN', `  ${v.cls}  (${v.file}:${v.line})`));
    console.error(`    ${v.text}`);
  }
  console.error('\nMove the child-building into  _buildAndConnectChildrenNoSettle  and have the constructor call the');
  console.error('settling wrapper  @_buildAndConnectChildren()  (orphan-settledness: `new X()` returns settled).');
  console.error('Or add a  # constructor-build-exempt: <reason>  comment in/above the constructor.');
  process.exit(1);
}
console.log('[ctor-build] OK — no constructor builds its own children inline.');
process.exit(0);
