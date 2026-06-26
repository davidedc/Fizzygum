#!/usr/bin/env node
'use strict';
/*
 * check-layering.js — build-time flow-soundness gate for the self-settling public
 * geometry API (docs/deferred-layout-16-macro-breakages.md / the self-settling-API design).
 *
 * THE CONSTRAINTS (program-flow soundness, not state invariants)
 *   A) A LOW-LEVEL method (name starting raw / silent / __ , ending NoSettle, or one of
 *      _reLayout / _positionAndResizeChildren / _reLayoutScrollbars) must NOT call a public
 *      geometry setter, a SINGLE-settling text setter (setText / setFontSize / setFontName /
 *      toggleShowBlanks / toggleWeight / toggleItalic / toggleIsPassword), or recalculateLayouts.
 *      Low-level code mutates immediately (raw/silent) and must never reach UP into the
 *      public, self-flushing layer. (The text setters self-settle via the single _settleLayoutsAfter,
 *      so reaching one from a layout pass throws the flow-violation — AxisWdgt._reLayout once called
 *      setText for its tick labels; it now uses the non-settling _setTextNoSettle core.)
 *   B) recalculateLayouts() may be called ONLY from doOneCycle (the frame) and the settle tiers
 *      _settleLayoutsAfter / _settleLayoutsAfterBatch (the public-setter flush). Nowhere else.
 *   C) A public geometry setter must NOT call another public geometry setter (that would
 *      flush more than once per logical mutation).
 *   G) A LOW-LEVEL method must NOT directly call a STRUCTURAL self-settling wrapper -- add's siblings
 *      destroy / close / fullDestroy / createReference / grab / drop / slideBackTo / setLabel /
 *      buildAndConnectChildren / ... : every method that self-settles via _settleLayoutsAfter. It must
 *      reach the _<name>NoSettle CORE instead (the "cores call cores" discipline, made static). The
 *      wrapper set is DISCOVERED structurally (not hand-listed); `add` and collapse/unCollapse are
 *      deliberately excluded -- see the [G] block lower down for why. [G] is the structural-wrapper
 *      extension of [A] (which covers the geometry/text setters + recalc).
 *   H) (WARNING, non-fatal) A method that self-settles via @_settleLayoutsAfter should be a THIN public
 *      wrapper -- a GUARD return (`return` / `return if|unless …`) BEFORE the settle is an early-return that
 *      almost always belongs INSIDE the _<name>NoSettle core (so the wrapper is a pure settle and the
 *      "already in this state" skip is not split across wrapper + core). Surfaced as a WARNING (the build
 *      still passes); bless a deliberate pre-settle guard with `# early-return-sanctioned: <why>`.
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
// The SINGLE-settling text setters (StringWdgt): each self-settles via _settleLayoutsAfter, so being
// reached from a layout pass / another settle throws the flow-violation. Low-level code that must set
// text uses the NON-settling core (_setTextNoSettle) or a raw setter. NB sizeToTextAndDisableFitting is
// not in THIS list (it is not one of the 7 text setters) but it is NOT a free pass: it now self-settles
// via the SINGLE tier (_settleLayoutsAfter — it moved off the batch settler when the batch tier went to 0
// callers), so rule [G] discovers it as a structural wrapper and forbids low-level code from calling it
// (low-level code uses the core _sizeToTextAndDisableFittingNoSettle). The `[@.]\s*` anchor + `\b` make
// `@setText`/`.setText` match while `@_setTextNoSettle`/`._setTextNoSettle` (the cores, leading `_`) and
// `setTextLineWrapping` do NOT.
const TEXT_SETTERS = ['setText', 'setFontSize', 'setFontName', 'toggleShowBlanks', 'toggleWeight', 'toggleItalic', 'toggleIsPassword'];
const TEXT_SETTER_CALL = new RegExp('[@.]\\s*(' + TEXT_SETTERS.join('|') + ')\\b');
const RECALC_CALL = /[@.]\s*recalculateLayouts\b/;            // @recalculateLayouts / world.recalculateLayouts
const INVALIDATE_CALL = /[@.]\s*_invalidateLayout\b/;         // @_invalidateLayout / x._invalidateLayout
// [F] a CONTAINER-refit apply CALL (excludes _reLayoutSelf — see the [F] rule note by the check below). The
// trailing (?!\?) skips the `?._reLayoutChildren?` EXISTENCE-CHECK guards (e.g. `return unless @parent?._reLayoutChildren?`)
// — those test for the method, they don't apply it; a real apply is `()`-called or paren-less-arg-called, never `?`-tested.
// The SECOND lookahead skips a method-REFERENCE COMPARISON (`@_reLayout != Widget::_reLayout` — the
// implementsDeferredLayout idiom for "does the subclass override _reLayout"): a comparison / `is` / `isnt`
// right after the name means it is being compared AS A VALUE, not applied. (A real apply is never compared.)
const APPLY_CALL = /[@.]\s*(_reLayoutChildren|_positionAndResizeChildren|_reLayoutScrollbars|_reLayout)\b(?!\?)(?!\s*(?:[!=]=|[<>]=?|is\b|isnt\b))/;
const SANCTION_MARKER = 'layout-apply-sanctioned';        // the conscious-sign-off comment marker for [F]
const PUBLIC_SET = new Set(PUBLIC_SETTERS);
const RECALC_WHITELIST = new Set(['doOneCycle', '_settleLayoutsAfter', '_settleLayoutsAfterBatch']);

const isLowLevel = (name) =>
  /^raw[A-Z]/.test(name) || /^silent/.test(name) ||
  /^_/.test(name) ||        // leading-underscore = private (incl. __ and the re-layout machinery
                            // _positionAndResizeChildren / _reLayoutScrollbars / _reLayoutChildrenAndScrollbars /
                            // _reLayoutChildren / _reLayoutSelf / _reLayoutDesktop /
                            // _refreshScrollPanelWdgtOrVerticalStackIfIamInIt / _amIDirectlyInside*)
  /NoSettle$/.test(name);    // the _xxxNoSettle cores (do the mutation, no settle)
// NB the old `|| /Layout$/.test(name)` arm was REMOVED (lint-ratchet C4, 2026-06-25): after the
// layout-method-family rename every real layout pass is _reLayout*-prefixed (already caught by /^_/
// above), so /Layout$/ only ever matched NON-pass methods whose name ends in "Layout" -- the queries
// implementsDeferredLayout / countOfChildrenInHorizontalStackLayout and the menu actions
// newParentChoiceWithHorizLayout / attachWithHorizLayout -- mis-classifying them as low-level.
// (Widget.implementsDeferredLayout's `@_reLayout != Widget::_reLayout` is a reference comparison,
// handled by APPLY_CALL's comparison lookahead above, so it is not a false [F] off-settle-apply hit.)

// [E] the flow rule (task #17): an IMMEDIATE geometry mutator (raw*/silent*/fullRaw*) must only
// MUTATE geometry, never SCHEDULE a (re-)layout. Scheduling (_invalidateLayout) is the public
// self-settling tier's job; a raw setter that invalidates lets "applying a layout" re-trigger
// "scheduling a layout", re-dirtying a container DURING its own layout pass -> the recalculate-
// Layouts until-loop never converges (the Phase 3b Slice 2 freeze that hung 9/12 desktop apps).
// NB this is NARROWER than isLowLevel on purpose: a _private / *NoSettle / *Layout method legitimately
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
//
// NAME-COVERAGE re-census (lint-ratchet plan Phase 2, 2026-06-25): confirmed the immediate-mutator NAME
// set == exactly the methods that write geometry immediately, so [E] has no innocent-named blind spot.
// Every method that assigns @bounds or calls the raw-geometry seam (_reFitContainerAfterRawGeometryChange)
// / the move-cache break is raw*/silent*/fullRaw*-named (incl. the mixin-nested fullRawMoveBy). The only
// non-raw-named methods touching the cache-break are constructor (@bounds init, not a mutation),
// _destroyNoSettle and removeFromTree (teardown / structural-removal cache hygiene -- neither writes
// geometry; removeFromTree is a structural op that legitimately schedules). No escapee -> no rename needed.
const isImmediateMutator = (name) => /^(raw[A-Z]|silent|fullRaw)/.test(name);

// [D] macro hygiene: a SystemTest macro must not reach into the framework's PRIVATE surface.
// Forbid calls to _private methods (the re-layout machinery -- _positionAndResizeChildren / _reLayoutScrollbars /
// _reLayoutChildren / _refreshScrollPanelWdgtOrVerticalStackIfIamInIt / _amIDirectlyInside* -- and any
// future _-method). This is the gate that would have caught the original 16-macro mess.
// NOT (yet) forbidden: the immediate raw/silent geometry API (rawSet*/fullRaw*/silent*, used for
// legitimate construction-time measure-and-size read-back). Per owner: these are "needed now"; at the
// END of the deferred-layout plan they get public self-settling alternatives and this rule tightens to
// forbid them too (raw|silent|fullRaw).
//   TIGHTENING ASSESSED — NOT YET RIPE (lint-ratchet plan Phase 3, 2026-06-25): a full macro audit found
//   the ONLY remaining raw/silent macro uses are 6 silentRawSetWidth/silentRawSetHeight calls, all the
//   SAME measure-and-size read-back on an ORPHAN, in 3 macros: macroTextRelayoutsCorrectlyOnResize,
//   macroBareTextWidgetDropShadowRestAndDrag, macroBoxTransparencyAndColorChanging. Each does
//   silentRawSetWidth W -> breakTextIntoLines (measure the wrapped height AT W) -> silentRawSetHeight
//   wrappedHeight, before world.add. No behaviour-preserving public alternative exists: setExtent needs
//   both dims up front, but the height is DERIVED from the width just set (chicken-and-egg), and the
//   widget is an orphan (the public setters' settle would no-op anyway via the orphan guard, but they
//   are not byte-identical to silent). Tightening now would force these into a worse pattern -> DECLINED.
//   Re-ripens only once a public "size to wrapped text at width W" construction helper exists.
// The former reLayout() carve-out is now CLOSED: this arc renamed reLayout -> _reLayoutSelf (private) and
// removed the macro calls, so the _-check below already forbids it (the planned tightening, achieved here).
const MACROS_DIR = path.join(__dirname, '..', '..', 'Fizzygum-tests', 'tests');
const MACRO_FORBIDDEN_CALL = /[@.]\s*(_[A-Za-z]\w*)\b/;

// [G] the STRUCTURAL self-settling-wrapper rule (the deferred-layout "cores call cores" discipline,
// made static). [A] above forbids a low-level method from DIRECTLY calling the 5 geometry setters /
// the single-settling text setters / recalculateLayouts -- a closed, hand-listed set. The SAME
// re-entrancy hazard exists for the STRUCTURAL self-settling wrappers (destroy / close / fullDestroy /
// createReference / grab / drop / slideBackTo / setLabel / buildAndConnectChildren / ...): each routes
// through the single-mutation settle tier _settleLayoutsAfter, so reaching one from inside a layout pass
// / a *NoSettle core / a raw setter re-enters the flush and hits the runtime throw (Widget.coffee, in
// _settleLayoutsAfter). Low-level code must call the matching _<name>NoSettle CORE, never the wrapper.
//
// The wrapper set is DISCOVERED structurally (discoverSettlingWrappers: every method whose body calls
// @_settleLayoutsAfter), never hand-listed -- so a NEW single-settling wrapper is auto-covered. Only the
// SINGLE-mutation tier counts: a future _settleLayoutsAfterBatch wrapper ABSORBS nested settles, so it is
// safe from low-level code and is NOT a [G] subject (SETTLE_CALL matches _settleLayoutsAfter only). Two
// name groups are excluded (a name line-scanner cannot cover them -- documented so they are a reasoned
// boundary, not a silent gap):
//   * the geometry/text setters -- [A] already reports them, with a sharper message.
//   * `add` -- only its MEMBER form `.add` is excluded: it shares a name with Point#add / Rectangle#add
//     (vector arithmetic, ubiquitous in layout math: `@topLeft().add pt`), and a name scanner cannot tell
//     a Widget structural add from a Point add on an expression without type inference (29 of 35 census
//     hits were Point#add). But the SELF form `@add` IS covered (SELF_ADD_CALL below): inside a Widget
//     method `@` is unambiguously a Widget, so `@add child` is always Widget.add -- the one add shape a
//     scanner CAN attribute, and the most important hole to close (a future *NoSettle core doing @add).
//     (The orphan guard + runtime throw remain the backstop for the `.add` member form and for
//     construction-time add() on an orphan.)
// (collapse / unCollapse USED to be excluded here -- they appeared in layout passes
// [WindowWdgt._positionAndResizeChildren's editButton / internalExternalSwitchButton;
// HorizontalMenuPanelWdgt._reLayoutSelf]. The end-of-cycle-flush drawdown convert (2026-06-25) routed those
// layout-pass call-sites to the idempotent _collapseNoSettle / _unCollapseNoSettle cores, so [G] now COVERS
// collapse / unCollapse like any other wrapper -- the discrete-handler callers [Un/CollapseIconButtonWdgt,
// BasementOpenerWdgt] are non-low-level and correctly keep the public self-settling form.)
//
// The TRANSITIVE closure of [G] (forbid low-level code from REACHING a wrapper by ANY call path) was
// prototyped and REJECTED: a name-based backward-reachability fixpoint balloons to ~720-870 names / ~500-710
// hits, because `constructor` (-> buildAndConnectChildren -> add) is a hub reached by `new @constructor`
// and `@constructor.name` everywhere, and the raw setters / *NoSettle cores themselves land in the set --
// so it flags the very "cores call cores" pattern it exists to bless. Name-based reachability cannot model
// the orphan guard (a receiver's attached-ness is dynamic), so this DIRECT rule is the maximal SOUND static
// check; the runtime throw stays the backstop for the transitive/dynamic cases (and for `add`).
const SETTLE_CALL = /[@.]\s*_settleLayoutsAfter\b/;          // SINGLE-mutation tier only (Batch absorbs nested settles)
const WRAPPER_EXCLUDED = new Set(['add']);   // see the [G] block above (collapse/unCollapse folded in once the layout passes routed to their cores)
const SELF_ADD_CALL = /@\s*add\b/;        // [G] the unambiguous structural add: @add (self == Widget.add inside a Widget
                                          // method). \b excludes @addMany / @addInPseudoRandomPosition; the leading @ (not .)
                                          // excludes the Point#add-ambiguous member form @expr().add / pt.add / @_addNoSettle.
const NOSETTLE_MARKER = 'nosettle-sanctioned';              // the [G] per-method conscious sign-off (mirrors [F])
const EARLY_RETURN_MARKER = 'early-return-sanctioned';      // the [H] per-method conscious sign-off (mirrors [F]/[G])
// [H] a GUARD return: a bare `return`, or a postfix `return if … / return unless …`. NOT `return <value>`
// (that is a legit return-the-result, e.g. `return @_settleLayoutsAfter => …` — what follows `return` is an
// expression, not if/unless/end-of-line). This is the early-return guard that should live INSIDE the
// _<name>NoSettle core, not before a public wrapper's _settleLayoutsAfter.
const GUARD_RETURN = /\breturn\b\s*(if\b|unless\b|$)/;

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

// [G] pre-pass: the set of public methods that self-settle via the SINGLE-mutation tier (their body
// calls @_settleLayoutsAfter) -- the structural wrappers a low-level method must NOT call (it must reach
// the _<name>NoSettle core instead). Computed from source so it tracks the codebase as wrappers are
// added/removed. The 2-space-method grouping mirrors checkFile's exactly. Returns the FORBIDDEN set:
// the discovered wrappers minus the geometry/text setters ([A] covers those) and minus WRAPPER_EXCLUDED.
function discoverSettlingWrappers(files) {
  const wrappers = new Set();
  for (const file of files) {
    const lines = fs.readFileSync(file, 'utf8').split('\n');
    let method = null, strState = null;
    for (let n = 0; n < lines.length; n++) {
      const { code, state } = stripLine(lines[n], strState);
      strState = state;
      if (strState === null) {
        const m = lines[n].match(METHOD_HEADER);
        if (m) { method = m[1]; continue; }
        if (/^  [A-Za-z_]\w*:/.test(lines[n]) || /^[^\s]/.test(lines[n])) method = null;
      }
      if (method && SETTLE_CALL.test(code)) wrappers.add(method);
    }
  }
  for (const n of [...PUBLIC_SETTERS, ...TEXT_SETTERS, ...WRAPPER_EXCLUDED]) wrappers.delete(n);
  return wrappers;
}

function checkFile(file, violations, wrapperCall, warnings) {
  const rel = path.relative(path.join(__dirname, '..'), file);
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  let method = null;          // current method name (null = not inside a 2-space method)
  let methodMarked = false;   // [F]: has a `# layout-apply-sanctioned` sign-off appeared in the current method?
  let methodNoSettleMarked = false;   // [G]: has a `# nosettle-sanctioned` sign-off appeared in the current method?
  let methodGuardReturnLine = -1;     // [H]: line of a GUARD return seen before any _settleLayoutsAfter in this method
  let methodHWarned = false;          // [H]: already emitted the early-return-before-settle warning for this method
  let methodEarlyReturnMarked = false;// [H]: has a `# early-return-sanctioned` sign-off appeared in the current method?
  let strState = null;
  for (let n = 0; n < lines.length; n++) {
    const raw = lines[n];
    const { code, state } = stripLine(raw, strState);
    strState = state;
    if (strState === null) {                       // header detection only on fully-closed lines
      const m = raw.match(METHOD_HEADER);
      if (m) { method = m[1]; methodMarked = false; methodNoSettleMarked = false; methodGuardReturnLine = -1; methodHWarned = false; methodEarlyReturnMarked = false; continue; }
      // a new 2-space property/non-method, or a dedent to class level, ends the method
      if (/^  [A-Za-z_]\w*:/.test(raw) || /^[^\s]/.test(raw)) { method = null; methodMarked = false; methodNoSettleMarked = false; methodGuardReturnLine = -1; methodHWarned = false; methodEarlyReturnMarked = false; }
    }
    if (!method) continue;
    if (raw.includes(SANCTION_MARKER)) methodMarked = true;  // [F] per-method conscious sign-off (any body line)
    if (raw.includes(NOSETTLE_MARKER)) methodNoSettleMarked = true;  // [G] per-method conscious sign-off (any body line)
    if (raw.includes(EARLY_RETURN_MARKER)) methodEarlyReturnMarked = true;  // [H] per-method conscious sign-off
    // [H] EARLY-RETURN-BEFORE-SETTLE (a WARNING, not a hard failure): a method that self-settles via
    // @_settleLayoutsAfter should be a THIN public wrapper. A GUARD return BEFORE that settle is an early-return
    // that almost always belongs INSIDE the _<name>NoSettle core -- otherwise the wrapper hides a guard, and the
    // "already in this state" skip is split across the wrapper (skip the settle) and the core (skip the work).
    // Record the first guard return; flag once when a _settleLayoutsAfter appears after it. The settle tiers
    // themselves are exempt (RECALC_WHITELIST). Bless a deliberate pre-settle guard with `# early-return-sanctioned`.
    if (!RECALC_WHITELIST.has(method) && !methodHWarned) {
      if (methodGuardReturnLine < 0 && GUARD_RETURN.test(code)) methodGuardReturnLine = n + 1;
      if (SETTLE_CALL.test(code) && methodGuardReturnLine >= 0 && !methodEarlyReturnMarked) {
        warnings.push(`[H] ${method}() has a guard return at ${rel}:${methodGuardReturnLine} BEFORE its _settleLayoutsAfter (${rel}:${n + 1}) — move that early-return into the _<name>NoSettle core so the public wrapper stays a thin settle (or mark # ${EARLY_RETURN_MARKER}: <why>)`);
        methodHWarned = true;
      }
    }
    const at = `${rel}:${n + 1}`;
    const pub = code.match(PUB_CALL);
    const txt = code.match(TEXT_SETTER_CALL);
    const recalc = RECALC_CALL.test(code);
    const invalidate = INVALIDATE_CALL.test(code);
    if (isLowLevel(method)) {
      if (pub) violations.push(`[A] low-level ${method}() calls public setter .${pub[1]}()  — ${at}`);
      if (txt) violations.push(`[A] low-level ${method}() calls self-settling text setter .${txt[1]}() — set text from a layout pass via the non-settling _setTextNoSettle core (or a raw setter), never the single-settling public setter  — ${at}`);
      // recalc is OK from a whitelisted flush driver (the settle tiers are now _-prefixed, hence
      // low-level by name, but they ARE the flush — rule [B] below governs who may call recalc).
      if (recalc && !RECALC_WHITELIST.has(method)) violations.push(`[A] low-level ${method}() calls recalculateLayouts()  — ${at}`);
      // [G] structural self-settling wrapper (discovered from _settleLayoutsAfter callers): low-level code
      // must reach the _<name>NoSettle core, never the public wrapper (it re-enters the single-mutation
      // flush). The settle tiers themselves (RECALC_WHITELIST) ARE the flush, so they are not [G] subjects.
      if (!RECALC_WHITELIST.has(method) && !methodNoSettleMarked) {
        const wrap = wrapperCall && code.match(wrapperCall);
        if (wrap) violations.push(`[G] low-level ${method}() calls self-settling wrapper .${wrap[1]}() — reach the non-settling core (e.g. _${wrap[1]}NoSettle), not the public self-settling wrapper (or mark # ${NOSETTLE_MARKER}: <why>)  — ${at}`);
        // the unambiguous self-add @add (Widget.add) — the one add shape a name scanner can attribute (`.add` member
        // stays excluded as Point#add-ambiguous). Low-level code must use @_addNoSettle, not the self-settling add().
        if (SELF_ADD_CALL.test(code)) violations.push(`[G] low-level ${method}() calls @add (self == Widget.add) — reach @_addNoSettle, not the self-settling add() (or mark # ${NOSETTLE_MARKER}: <why>)  — ${at}`);
      }
    }
    if (isImmediateMutator(method) && invalidate) {
      violations.push(`[E] immediate mutator ${method}() calls _invalidateLayout() — raw/silent/fullRaw setters must only MUTATE, never SCHEDULE layout (task #17)  — ${at}`);
    }
    if (recalc && !RECALC_WHITELIST.has(method)) {
      violations.push(`[B] recalculateLayouts() called from ${method}() (only doOneCycle / _settleLayoutsAfter / _settleLayoutsAfterBatch may)  — ${at}`);
    }
    if (PUBLIC_SET.has(method) && pub && pub[1] !== method) {
      violations.push(`[C] public setter ${method}() calls another public setter .${pub[1]}()  — ${at}`);
    }
    // [F] the SCHEDULE/APPLY boundary, made auditable (deferred-layout-OVERVIEW.md §11). A method that is NEITHER
    // low-level NOR an immediate mutator -- i.e. a handler / property setter / menu action / gesture / constructor --
    // must NOT call a CONTAINER-refit apply (_reLayoutChildren / _positionAndResizeChildren / _reLayoutScrollbars / _reLayout)
    // synchronously OFF-SETTLE. It must DEFER (record intent via _invalidateLayout; let the cycle / a flush apply it),
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
        violations.push(`[F] off-settle synchronous layout apply .${apply[1]}() in ${method}() — DEFER it (_invalidateLayout), or if it is at a settle point / a documented determinism-exempt family mark the method  # ${SANCTION_MARKER}: <why>  — ${at}`);
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
  // [G] pre-pass: discover the structural self-settling wrappers (single-tier), then a regex that
  // matches a CALL to one. Empty-set guard keeps the regex well-formed (it is ~12 names in practice).
  const FORBIDDEN_WRAPPERS = discoverSettlingWrappers(files);
  const WRAPPER_CALL = FORBIDDEN_WRAPPERS.size
    ? new RegExp('[@.]\\s*(' + [...FORBIDDEN_WRAPPERS].join('|') + ')\\b') : null;
  const violations = [];
  const warnings = [];
  for (const f of files) {
    try { checkFile(f, violations, WRAPPER_CALL, warnings); }
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
  if (warnings.length) {
    console.warn(`\n⚠ layering gate — ${warnings.length} [H] early-return-before-settle warning(s) (non-fatal):`);
    for (const w of warnings) console.warn('  ' + w);
    console.warn('  [H] a public settle-wrapper should be THIN — push its early-return guard(s) into the _<name>NoSettle core, or mark `# early-return-sanctioned: <why>`.');
  }
  if (violations.length) {
    console.error(`\n!!! layering gate FAILED — ${violations.length} violation(s):\n`);
    for (const v of violations) console.error('  ' + v);
    console.error('\nSee docs/deferred-layout-refit-and-add-design.md (D: macros must not call private/low-level methods;');
    console.error('E: raw/silent/fullRaw mutators must not call _invalidateLayout) and docs/deferred-layout-16-macro-breakages.md (A/B/C).');
    console.error('F: a non-mutator handler must DEFER a container apply (_invalidateLayout) or mark it `# layout-apply-sanctioned: <why>` — see docs/deferred-layout-OVERVIEW.md §11.');
    console.error('G: low-level code must reach the _<name>NoSettle core, not the public self-settling wrapper (destroy/close/fullDestroy/createReference/...) — or mark `# nosettle-sanctioned: <why>`.');
    process.exit(1);
  }
  console.log(`layering gate: ${files.length} source(s) + ${macroCount} macro(s) — 0 violations (A/B/C/D/E/F/G; ${FORBIDDEN_WRAPPERS.size} settling wrappers guarded)${warnings.length ? `; ${warnings.length} [H] warning(s)` : ''}`);
  process.exit(0);
}

main();
