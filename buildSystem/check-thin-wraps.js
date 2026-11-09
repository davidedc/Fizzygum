#!/usr/bin/env node
// check-thin-wraps.js — build lint: every public self-settling method must be the ONE canonical
// MECHANICAL THIN WRAP around its private *NoSettle twin. Mirrors check-dead-methods.js / check-stinks.js
// (line scanner; exit 0 clean / 1 violation).
//
// CANONICAL FORM: for a private `_<name>NoSettle`, its settling twin in the SAME class -- the public
// `<name>` (e.g. setLabel) OR the private `_<name>` (e.g. the construction wrapper _buildAndConnectChildren)
// -- must, after comments/blank lines, be:
//     [ zero or more  `return if <cond>` / `return unless <cond>` idempotency guards ]
//     @_settleLayoutsAfter => @_<name>NoSettle <args?>
// i.e. it does NO work of its own -- it guards, then hands the mutation to the core via the
// single-mutation settle tier. (_settleLayoutsAfter anchors on `@`: a teardown that orphans `@`
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

// A `# thin-wrap-exempt:` marker that excuses nothing — not directly above a public/private method that owns a same-class
// `_<name>NoSettle` twin, so this gate never reads it — FAILS as stale: it states an exemption from a check that is not
// made there, and a later reader trusts it. Explanatory text worth keeping stays a plain comment.
//
// It reads the compiled sources (lib/source-files.js compiledFiles: src/ and the tests repo's harness).
//
// Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-thin-wraps.js [--src=DIR]
// [--tests-repo=DIR] — the rails check another src tree or tests repo (a copy carrying a plant). That both rules BITE,
// and that every accepted shape passes, is proven on every build by check-thin-wraps-selftest.js.

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'thin-wraps');
rejectPositionalArgs(ARGV, 'thin-wraps', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'thin-wraps');

const { methodSpans } = require('./lib/coffee-method-header');   // class methods and mixin members, one span each
const GUARD  = /^return\s+(if|unless)\b/;               // idempotency guard clause
const EXEMPT = /#\s*thin-wrap-exempt:\s*\S/;            // marker WITH a non-empty reason

// each file is read through lib/coffee-mask.js: a body is its code lines (comments blanked), a marker sits in a comment
const { coffeeMask, isCommentOnly } = require('./lib/coffee-mask');

const violations = [];
const staleMarkers = [];
let checked = 0, exempt = 0;
for (const p of compiledFiles(ROOTS)) {
  const cls = path.basename(p, '.coffee');
  const text = fs.readFileSync(p, 'utf8');
  const lines = text.split('\n');
  const masked = coffeeMask(text, sourceName(p, ROOTS));
  const markedLine = (j) => isCommentOnly(masked[j]) && EXEMPT.test(masked[j].comment);
  const usedMarkers = new Set();   // the marker lines an exemption below consumed
  const heads = [];
  for (const sp of methodSpans(lines)) heads.push({ name: sp.name, i: sp.line, end: sp.end });
  const byName = new Map(heads.map((h, k) => [h.name, k]));
  for (let k = 0; k < heads.length; k++) {
    const m = /^_(.+)NoSettle$/.exec(heads[k].name);
    if (!m) continue;                                   // not a *NoSettle method
    const base = m[1];                                  // _fullDestroyNoSettle -> fullDestroy
    // The settling twin is either the PUBLIC <base> (e.g. setLabel) or a PRIVATE _<base> (e.g. the
    // construction wrapper _buildAndConnectChildren): a core can be wrapped by a public self-settling API
    // OR a private self-settling internal step -- same canonical body either way.
    const twinName = byName.has(base) ? base : (byName.has('_' + base) ? '_' + base : null);
    if (!twinName) continue;                            // no same-class twin -> nothing to constrain
    const twinIdx = byName.get(twinName);
    const head = heads[twinIdx];
    // EXEMPTION: scan upward through the contiguous comment block directly above the public header.
    let marked = false;
    for (let j = head.i - 1; j >= 0 && isCommentOnly(masked[j]); j--) {
      if (markedLine(j)) { marked = true; usedMarkers.add(j); break; }
    }
    if (marked) { exempt++; continue; }
    // the public method's code lines (comments + blanks removed)
    const end = head.end;
    const body = [];
    for (let j = head.i + 1; j < end; j++) { const c = masked[j].code.trim(); if (c) body.push(c); }
    // strip leading idempotency guards, then require exactly the canonical wrap
    let rest = body.slice();
    while (rest.length && GUARD.test(rest[0])) rest.shift();
    const canonical = new RegExp('^@_settleLayoutsAfter\\s*=>\\s*@_' + base + 'NoSettle\\b');
    if (rest.length === 1 && canonical.test(rest[0])) checked++;
    else violations.push({ key: cls + '.' + twinName, file: sourceName(p, ROOTS), line: head.i + 1, body });
  }
  lines.forEach((l, j) => {
    if (markedLine(j) && !usedMarkers.has(j)) staleMarkers.push({ file: sourceName(p, ROOTS), line: j + 1 });
  });
}

console.log(`[thin-wraps] ${checked} canonical wrapper(s) + ${exempt} marked-exempt checked.`);
if (violations.length) {
  console.error(`\n[thin-wraps] FAIL -- ${violations.length} public method(s) own a _<name>NoSettle twin but are neither the canonical wrap nor marked exempt:`);
  for (const v of violations) {
    console.error(rules.fired('NOT_CANONICAL', `  ${v.key}  (${v.file}:${v.line})`));
    console.error(`    body: ${JSON.stringify(v.body)}`);
  }
  console.error('\nCanonical: [return if/unless guards] then  @_settleLayoutsAfter => @_<name>NoSettle <args>.');
  console.error('Or add a  # thin-wrap-exempt: <reason>  comment directly above the method.');
}
if (staleMarkers.length) {
  console.error(`\n[thin-wraps] FAIL -- ${staleMarkers.length} # thin-wrap-exempt: marker(s) excuse nothing (no method owning a _<name>NoSettle twin directly below):`);
  for (const s of staleMarkers) console.error(rules.fired('STALE_EXEMPT_MARKER', `  STALE_ALLOWLIST_ENTRY ${s.file}:${s.line}`));
  console.error('Delete the marker; keep any explanation as a plain comment.');
}
if (violations.length || staleMarkers.length) process.exit(1);
console.log('[thin-wraps] OK -- every public/NoSettle pair is the canonical wrap or marked exempt.');
process.exit(0);
