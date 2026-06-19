#!/usr/bin/env node
'use strict';
/*
 * check-layering.js — build-time flow-soundness gate for the self-settling public
 * geometry API (docs/deferred-layout-16-macro-breakages.md / the self-settling-API design).
 *
 * THE CONSTRAINTS (program-flow soundness, not state invariants)
 *   A) A LOW-LEVEL method (name starting raw / silent / __ , ending Core, or one of
 *      doLayout / adjustContentsBounds / adjustScrollBars) must NOT call a public
 *      geometry setter or recalculateLayouts.
 *      Low-level code mutates immediately (raw/silent) and must never reach UP into the
 *      public, self-flushing layer.
 *   B) recalculateLayouts() may be called ONLY from doOneCycle (the frame) and
 *      mutateGeometryThenSettle (the public-setter flush). Nowhere else.
 *   C) A public geometry setter must NOT call another public geometry setter (that would
 *      flush more than once per logical mutation).
 *
 * WHY A LINT (not only the runtime guards): the runtime re-entrancy guards
 * (_inLayoutMutation, _recalculatingLayouts) throw on the DANGEROUS dynamic cases
 * (nesting / re-entrant flush), but only on paths the tests exercise. This gate is the
 * EXHAUSTIVE, preventive check across ALL shipped source — and, unlike a runtime token,
 * it cannot be spoofed.
 *
 * HOW: a heuristic line scanner. It strips `#` comments and string literals (', ", ''',
 * """, `) so the call-detecting regexes never match a method name that merely appears in a
 * throw message or a comment; it groups lines into 2-space-indent methods. Call detection
 * keys off the leading `@`/`.` and the LOWERCASE public name, so `@setExtent`/`.fullMoveTo`
 * match while the low-level `@rawSetExtent`/`@fullRawMoveTo`/`@silentRawSetBounds` do NOT.
 *
 * Exit codes: 0 = clean, 1 = layering violation(s), 2 = operational error.
 * Run from the Fizzygum/ repo root (build_it_please.sh does this):
 *   node ./buildSystem/check-layering.js
 */

const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, '..', 'src');

const PUBLIC_SETTERS = ['setExtent', 'fullMoveTo', 'setBounds', 'setWidth', 'setHeight'];
// a call to a public setter: leading @ or . then the lowercase name (excludes raw*/silent* —
// those have `raw`/`silent` between the @/. and the capitalised `Set*`/`*MoveTo`).
const PUB_CALL = new RegExp('[@.]\\s*(' + PUBLIC_SETTERS.join('|') + ')\\b');
const RECALC_CALL = /[@.]\s*recalculateLayouts\b/;            // @recalculateLayouts / world.recalculateLayouts
const PUBLIC_SET = new Set(PUBLIC_SETTERS);
const RECALC_WHITELIST = new Set(['doOneCycle', 'mutateGeometryThenSettle']);

const isLowLevel = (name) =>
  /^raw[A-Z]/.test(name) || /^silent/.test(name) || /^__/.test(name) || /Core$/.test(name) ||
  /Layout$/.test(name) ||   // doLayout, reLayout, desktopReLayout, __calculate…Layout — internal layout passes
  name === 'adjustContentsBounds' || name === 'adjustScrollBars';

// Strip string literals and trailing `#` comments from one line, carrying multi-line
// string state across lines. Returns { code, state }.
function stripLine(line, state) {
  if (state) {                                   // currently inside a multi-line string
    const end = line.indexOf(state);
    if (end < 0) return { code: '', state };     // whole line is still inside it
    line = line.slice(end + state.length);
    state = null;
  }
  let out = '';
  let i = 0;
  while (i < line.length) {
    const three = line.substr(i, 3);
    if (three === '"""' || three === "'''") {
      const close = line.indexOf(three, i + 3);
      if (close < 0) { state = three; break; }
      i = close + 3; continue;
    }
    const c = line[i];
    if (c === '`') {
      const close = line.indexOf('`', i + 1);
      if (close < 0) { state = '`'; break; }
      i = close + 1; continue;
    }
    if (c === '"' || c === "'") {                // single-line quoted string
      let j = i + 1;
      while (j < line.length) {
        if (line[j] === '\\') { j += 2; continue; }
        if (line[j] === c) break;
        j++;
      }
      i = j + 1; continue;
    }
    if (c === '#') break;                         // comment to end of line
    out += c; i++;
  }
  return { code: out, state };
}

function collectCoffee(dir, out) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) collectCoffee(p, out);
    else if (e.name.endsWith('.coffee')) out.push(p);
  }
  return out;
}

const METHOD_HEADER = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;   // a class-level (2-space) method def

function checkFile(file, violations) {
  const rel = path.relative(path.join(__dirname, '..'), file);
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  let method = null;          // current method name (null = not inside a 2-space method)
  let strState = null;
  for (let n = 0; n < lines.length; n++) {
    const raw = lines[n];
    const { code, state } = stripLine(raw, strState);
    strState = state;
    if (strState === null) {                       // header detection only on fully-closed lines
      const m = raw.match(METHOD_HEADER);
      if (m) { method = m[1]; continue; }
      // a new 2-space property/non-method, or a dedent to class level, ends the method
      if (/^  [A-Za-z_]\w*:/.test(raw) || /^[^\s]/.test(raw)) method = null;
    }
    if (!method) continue;
    const at = `${rel}:${n + 1}`;
    const pub = code.match(PUB_CALL);
    const recalc = RECALC_CALL.test(code);
    if (isLowLevel(method)) {
      if (pub) violations.push(`[A] low-level ${method}() calls public setter .${pub[1]}()  — ${at}`);
      if (recalc) violations.push(`[A] low-level ${method}() calls recalculateLayouts()  — ${at}`);
    }
    if (recalc && !RECALC_WHITELIST.has(method)) {
      violations.push(`[B] recalculateLayouts() called from ${method}() (only doOneCycle / mutateGeometryThenSettle may)  — ${at}`);
    }
    if (PUBLIC_SET.has(method) && pub && pub[1] !== method) {
      violations.push(`[C] public setter ${method}() calls another public setter .${pub[1]}()  — ${at}`);
    }
  }
}

function main() {
  let files;
  try {
    files = collectCoffee(SRC, []);
  } catch (e) {
    console.error('check-layering: operational error collecting sources:', e.message);
    process.exit(2);
  }
  const violations = [];
  for (const f of files) {
    try { checkFile(f, violations); }
    catch (e) { console.error(`check-layering: operational error in ${f}:`, e.message); process.exit(2); }
  }
  if (violations.length) {
    console.error(`\n!!! layering gate FAILED — ${violations.length} violation(s):\n`);
    for (const v of violations) console.error('  ' + v);
    console.error('\nSee docs/deferred-layout-16-macro-breakages.md for the layering rules (A/B/C).');
    process.exit(1);
  }
  console.log(`layering gate: ${files.length} source(s) — 0 violations (A/B/C)`);
  process.exit(0);
}

main();
