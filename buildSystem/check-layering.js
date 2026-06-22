#!/usr/bin/env node
'use strict';
/*
 * check-layering.js — build-time flow-soundness gate for the self-settling public
 * geometry API (docs/deferred-layout-16-macro-breakages.md / the self-settling-API design).
 *
 * THE CONSTRAINTS (program-flow soundness, not state invariants)
 *   A) A LOW-LEVEL method (name starting raw / silent / __ , ending Core, or one of
 *      _reLayout / _positionAndResizeChildren / _reLayoutScrollbars) must NOT call a public
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
const INVALIDATE_CALL = /[@.]\s*invalidateLayout\b/;         // @invalidateLayout / x.invalidateLayout
// [F] a CONTAINER-refit apply CALL (excludes _reLayoutSelf — see the [F] rule note by the check below). The
// trailing (?!\?) skips the `?._reLayoutChildren?` EXISTENCE-CHECK guards (e.g. `return unless @parent?._reLayoutChildren?`)
// — those test for the method, they don't apply it; a real apply is `()`-called or paren-less-arg-called, never `?`-tested.
const APPLY_CALL = /[@.]\s*(_reLayoutChildren|_positionAndResizeChildren|_reLayoutScrollbars|_reLayout)\b(?!\?)/;
const SANCTION_MARKER = 'layout-apply-sanctioned';        // the conscious-sign-off comment marker for [F]
const PUBLIC_SET = new Set(PUBLIC_SETTERS);
const RECALC_WHITELIST = new Set(['doOneCycle', 'mutateGeometryThenSettle', 'settleLayoutsOnceAfter']);

const isLowLevel = (name) =>
  /^raw[A-Z]/.test(name) || /^silent/.test(name) ||
  /^_/.test(name) ||        // leading-underscore = private (incl. __ and the re-layout machinery
                            // _positionAndResizeChildren / _reLayoutScrollbars / _reLayoutChildrenAndScrollbars /
                            // _reLayoutChildren / _reLayoutSelf / _reLayoutDesktop /
                            // _refreshScrollPanelWdgtOrVerticalStackIfIamInIt / _amIDirectlyInside*)
  /Core$/.test(name) ||
  /Layout$/.test(name);     // _reLayout — the main layout pass (and any future *Layout)

// [E] the flow rule (task #17): an IMMEDIATE geometry mutator (raw*/silent*/fullRaw*) must only
// MUTATE geometry, never SCHEDULE a (re-)layout. Scheduling (invalidateLayout) is the public
// self-settling tier's job; a raw setter that invalidates lets "applying a layout" re-trigger
// "scheduling a layout", re-dirtying a container DURING its own layout pass -> the recalculate-
// Layouts until-loop never converges (the Phase 3b Slice 2 freeze that hung 9/12 desktop apps).
// NB this is NARROWER than isLowLevel on purpose: a _private / *Core / *Layout method legitimately
// drives layout (and may invalidate other widgets), so it is NOT covered by rule E.
//
// COMPLETENESS (deferred-layout capstone, 2026-06-21): the immediate-mutator boundary is now fully
// closed, and this SCHEDULE rule is the whole of what needs LINTING. The other freeze vector -- an
// immediate mutator triggering a CLIMB (re-fitting its ancestors up the tree) -- was eliminated not by
// a lint but by deferring the re-fit seam (_reFitContainerAfterRawGeometryChange enqueues/invalidates
// the container; its synchronous childGeometryChanged climb arm was retired and that orphaned method
// deleted). What an immediate mutator legitimately MAY do is APPLY a re-fit synchronously IN PLACE -- a
// TERMINAL, single-container apply (TextWdgt.rawSetExtent->@_reLayoutSelf, StretchablePanelWdgt.rawSetExtent
// ->@_reLayout, ScrollPanelWdgt/SimpleVerticalStackPanelWdgt.rawSetExtent->@_reLayoutChildren). Those
// applies are SANCTIONED (see those overrides' comments) -- only the SCHEDULE below is forbidden.
// Forbidding the _reLayoutChildren apply by name was assessed and DECLINED as cosmetic: it does the
// identical work to the blessed _reLayoutSelf/_reLayout applies, so a name-based ban would just force a
// DRY-breaking inline. (deferred-layout-capstone-execution-plan.md, Part B.)
const isImmediateMutator = (name) => /^(raw[A-Z]|silent|fullRaw)/.test(name);

// [D] macro hygiene: a SystemTest macro must not reach into the framework's PRIVATE surface.
// Forbid calls to _private methods (the re-layout machinery -- _positionAndResizeChildren / _reLayoutScrollbars /
// _reLayoutChildren / _refreshScrollPanelWdgtOrVerticalStackIfIamInIt / _amIDirectlyInside* -- and any
// future _-method). This is the gate that would have caught the original 16-macro mess.
// NOT (yet) forbidden: the immediate raw/silent geometry API (rawSet*/fullRaw*/silent*, used for
// legitimate construction-time measure-and-size read-back). Per owner: these are "needed now"; at the
// END of the deferred-layout plan they get public self-settling alternatives and this rule tightens to
// forbid them too (raw|silent|fullRaw).
// The former reLayout() carve-out is now CLOSED: this arc renamed reLayout -> _reLayoutSelf (private) and
// removed the macro calls, so the _-check below already forbids it (the planned tightening, achieved here).
const MACROS_DIR = path.join(__dirname, '..', '..', 'Fizzygum-tests', 'tests');
const MACRO_FORBIDDEN_CALL = /[@.]\s*(_[A-Za-z]\w*)\b/;

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
  let methodMarked = false;   // [F]: has a `# layout-apply-sanctioned` sign-off appeared in the current method?
  let strState = null;
  for (let n = 0; n < lines.length; n++) {
    const raw = lines[n];
    const { code, state } = stripLine(raw, strState);
    strState = state;
    if (strState === null) {                       // header detection only on fully-closed lines
      const m = raw.match(METHOD_HEADER);
      if (m) { method = m[1]; methodMarked = false; continue; }
      // a new 2-space property/non-method, or a dedent to class level, ends the method
      if (/^  [A-Za-z_]\w*:/.test(raw) || /^[^\s]/.test(raw)) { method = null; methodMarked = false; }
    }
    if (!method) continue;
    if (raw.includes(SANCTION_MARKER)) methodMarked = true;  // [F] per-method conscious sign-off (any body line)
    const at = `${rel}:${n + 1}`;
    const pub = code.match(PUB_CALL);
    const recalc = RECALC_CALL.test(code);
    const invalidate = INVALIDATE_CALL.test(code);
    if (isLowLevel(method)) {
      if (pub) violations.push(`[A] low-level ${method}() calls public setter .${pub[1]}()  — ${at}`);
      if (recalc) violations.push(`[A] low-level ${method}() calls recalculateLayouts()  — ${at}`);
    }
    if (isImmediateMutator(method) && invalidate) {
      violations.push(`[E] immediate mutator ${method}() calls invalidateLayout() — raw/silent/fullRaw setters must only MUTATE, never SCHEDULE layout (task #17)  — ${at}`);
    }
    if (recalc && !RECALC_WHITELIST.has(method)) {
      violations.push(`[B] recalculateLayouts() called from ${method}() (only doOneCycle / mutateGeometryThenSettle may)  — ${at}`);
    }
    if (PUBLIC_SET.has(method) && pub && pub[1] !== method) {
      violations.push(`[C] public setter ${method}() calls another public setter .${pub[1]}()  — ${at}`);
    }
    // [F] the SCHEDULE/APPLY boundary, made auditable (deferred-layout-OVERVIEW.md §11). A method that is NEITHER
    // low-level NOR an immediate mutator -- i.e. a handler / property setter / menu action / gesture / constructor --
    // must NOT call a CONTAINER-refit apply (_reLayoutChildren / _positionAndResizeChildren / _reLayoutScrollbars / _reLayout)
    // synchronously OFF-SETTLE. It must DEFER (record intent via invalidateLayout; let the cycle / a flush apply it),
    // OR, if the apply is genuinely AT a settle point (a deferred-seam in-pass arm, run under _recalculatingLayouts) or
    // a documented determinism-exempt family (scroll-input / collapse / construction), CONSCIOUSLY mark the METHOD --
    // any one line in its body `# layout-apply-sanctioned: <why>` exempts that whole handler. The apply BODIES, the
    // cycle, and the raw-tier terminal applies are already
    // isLowLevel / isImmediateMutator and exit above -- so this rule's whole surface is the off-settle non-mutator
    // caller. SCOPE: _reLayoutSelf is DELIBERATELY excluded -- it is a SELF-apply (own text re-wrap / own slider thumb / own
    // button label; residuals-audit families 5/6/7 are "compliant in substance"), not the freefloating-child->container
    // regression class [F] guards; including it would mark ~30 benign self-applies for little risk coverage.
    if (!isLowLevel(method) && !isImmediateMutator(method)) {
      const apply = code.match(APPLY_CALL);
      if (apply && !methodMarked) {
        violations.push(`[F] off-settle synchronous layout apply .${apply[1]}() in ${method}() — DEFER it (invalidateLayout), or if it is at a settle point / a documented determinism-exempt family mark the method  # ${SANCTION_MARKER}: <why>  — ${at}`);
      }
    }
  }
}

function collectMacros(dir, out) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) collectMacros(p, out);
    else if (e.name.endsWith('_automationCommands.js')) out.push(p);
  }
  return out;
}

// Scan a macro test source for forbidden private/low-level calls (rule D). The macro CoffeeScript
// lives in a backtick string inside this .js; a per-line `#`-comment strip is enough to avoid the
// narrative comments (which legitimately mention e.g. adjustContentsBounds / @fullRawMoveWithin).
function checkMacroFile(file, violations) {
  const rel = path.relative(path.join(__dirname, '..', '..'), file);
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  for (let n = 0; n < lines.length; n++) {
    const hash = lines[n].indexOf('#');
    const code = hash >= 0 ? lines[n].slice(0, hash) : lines[n];
    const m = code.match(MACRO_FORBIDDEN_CALL);
    if (m) violations.push(`[D] macro calls private/low-level .${m[1]}()  — ${rel}:${n + 1}`);
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
  let macroCount = 0;
  if (fs.existsSync(MACROS_DIR)) {           // absent in a --homepage/--notests build — skip [D] then
    let macros;
    try { macros = collectMacros(MACROS_DIR, []); }
    catch (e) { console.error('check-layering: operational error collecting macros:', e.message); process.exit(2); }
    macroCount = macros.length;
    for (const f of macros) {
      try { checkMacroFile(f, violations); }
      catch (e) { console.error(`check-layering: operational error in ${f}:`, e.message); process.exit(2); }
    }
  }
  if (violations.length) {
    console.error(`\n!!! layering gate FAILED — ${violations.length} violation(s):\n`);
    for (const v of violations) console.error('  ' + v);
    console.error('\nSee docs/deferred-layout-refit-and-add-design.md (D: macros must not call private/low-level methods;');
    console.error('E: raw/silent/fullRaw mutators must not call invalidateLayout) and docs/deferred-layout-16-macro-breakages.md (A/B/C).');
    console.error('F: a non-mutator handler must DEFER a container apply (invalidateLayout) or mark it `# layout-apply-sanctioned: <why>` — see docs/deferred-layout-OVERVIEW.md §11.');
    process.exit(1);
  }
  console.log(`layering gate: ${files.length} source(s) + ${macroCount} macro(s) — 0 violations (A/B/C/D/E/F)`);
  process.exit(0);
}

main();
