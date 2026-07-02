#!/usr/bin/env node
'use strict';
/*
 * check-layering.js — build-time flow-soundness gate for the self-settling public
 * geometry API (docs/deferred-layout-16-macro-breakages.md / the self-settling-API design).
 *
 * THE CONSTRAINTS (program-flow soundness, not state invariants)
 *   A) A LOW-LEVEL method (name starting raw / _ / __ , ending NoSettle, or one of
 *      _reLayout / _positionAndResizeChildren / _reLayoutScrollbars) must NOT call a public
 *      geometry setter, a SINGLE-settling text setter (setText / setFontSize / setFontName /
 *      toggleShowBlanks / toggleWeight / toggleItalic / toggleIsPassword), or recalculateLayouts.
 *      Low-level code mutates immediately (raw pixels / the _ and __ private tiers) and must never reach UP into the
 *      public, self-flushing layer. (The text setters self-settle via the single _settleLayoutsAfter,
 *      so reaching one from a layout pass throws the flow-violation — AxisWdgt._reLayout once called
 *      setText for its tick labels; it now uses the non-settling _setTextNoSettle core.)
 *   B) recalculateLayouts() may be called ONLY from doOneCycle (the frame) and the settle tier
 *      _settleLayoutsAfter (the public-setter flush). Nowhere else.
 *   C) A public geometry setter must NOT call another public geometry setter (that would
 *      flush more than once per logical mutation).
 *   G) A LOW-LEVEL method must NOT directly call a STRUCTURAL self-settling wrapper -- add's siblings
 *      destroy / close / fullDestroy / createReference / grab / drop / slideBackTo / setLabel /
 *      _buildAndConnectChildren / ... : every method that self-settles via _settleLayoutsAfter. It must
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
 * keys off the leading `@`/`.` and the LOWERCASE public name, so `@setExtent`/`.moveTo`
 * match while the low-level `@_applyExtent`/`@_applyMoveTo`/`@_commitBounds` do NOT.
 *
 * Exit codes: 0 = clean, 1 = layering violation(s), 2 = operational error.
 * Run from the Fizzygum/ repo root (build_it_please.sh does this):
 *   node ./buildSystem/check-layering.js
 */

const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, '..', 'src');

const PUBLIC_SETTERS = ['setExtent', 'moveTo', 'setBounds', 'setWidth', 'setHeight'];
// NB moveWithin (ex-fullMoveWithin, public) is deliberately NOT here: it is a public CONVENIENCE that delegates
// to the one-settle moveTo, so listing it would false-trip [C] (public-setter calls public-setter) on its
// moveWithin -> moveTo call. Like fullMoveWithin pre-rename, it stays untracked (it self-settles via moveTo).
// a call to a public setter: leading @ or . then the lowercase public name (the _-prefixed low-level mutators
// — _applyExtent / __commitExtent / etc. — don't match: the leading underscore sits between the @/. and the verb).
const PUB_CALL = new RegExp('[@.]\\s*(' + PUBLIC_SETTERS.join('|') + ')\\b');
// R2 carve-out: the public mover moveTo shares its name with the HTML5 canvas context.moveTo (~560 draw
// call-sites + @moveTo in the canvas extensions). PUB_CALL is receiver-blind, so a moveTo match is IGNORED
// (in checkFile) when it is a canvas call -- a canvas receiver, or one of the boot canvas-extension files.
const CANVAS_MOVETO = /\b(context|pctx|backBufferContext|aContext|ctx)\s*\.\s*moveTo\b/;
const CANVAS_EXT_FILE = /boot[\/\\]extensions[\/\\].*[Cc]anvas/;
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
const RECALC_WHITELIST = new Set(['doOneCycle', '_settleLayoutsAfter']);

const isLowLevel = (name) =>
  /^raw[A-Z]/.test(name) ||  // raw* is now ONLY the pixel accessors (rawPixelInfo/rawPixelHash/rawRGBA).
                            // (the structural silent* setters were renamed to __hide/__addShadow/__add LEAVES in §3d/B13,
                            //  caught by /^_/ below — the old /^silent/ arm was retired with them. The old /^fullRaw/ arm
                            //  was likewise REMOVED with the §6-1/§6-5 move+mutator renames: every fullRaw* mover is now an
                            //  _apply* corner or a _move* convenience — both leading-underscore, so caught by /^_/
                            //  below; the low-level classification is unchanged.)
  /^_/.test(name) ||        // leading-underscore = private (incl. __ and the re-layout machinery
                            // _positionAndResizeChildren / _reLayoutScrollbars / _reLayoutChildrenAndScrollbars /
                            // _reLayoutChildren / _reLayoutSelf / _reLayoutDesktop /
                            // _announceLayoutPropertyChangeToContainer / _amIDirectlyInside*)
  /NoSettle$/.test(name);    // the _xxxNoSettle cores (do the mutation, no settle)
// NB the old `|| /Layout$/.test(name)` arm was REMOVED (lint-ratchet C4, 2026-06-25): after the
// layout-method-family rename every real layout pass is _reLayout*-prefixed (already caught by /^_/
// above), so /Layout$/ only ever matched NON-pass methods whose name ends in "Layout" -- the queries
// implementsDeferredLayout / countOfChildrenInHorizontalStackLayout and the menu actions
// newParentChoiceWithHorizLayout / attachWithHorizLayout -- mis-classifying them as low-level.
// (Widget.implementsDeferredLayout's `@_reLayout != Widget::_reLayout` is a reference comparison,
// handled by APPLY_CALL's comparison lookahead above, so it is not a false [F] off-settle-apply hit.)

// [E] the flow rule (task #17): an IMMEDIATE geometry mutator (the apply-2x2 corners + convenience movers)
// must only MUTATE geometry, never SCHEDULE a (re-)layout. Scheduling (_invalidateLayout) is the public
// self-settling tier's job; an apply corner that invalidates lets "applying a layout" re-trigger
// "scheduling a layout", re-dirtying a container DURING its own layout pass -> the recalculate-
// Layouts until-loop never converges (the Phase 3b Slice 2 freeze that hung 9/12 desktop apps).
// NB this is NARROWER than isLowLevel on purpose: a _private / *NoSettle / *Layout method legitimately
// drives layout (and may invalidate other widgets), so it is NOT covered by rule E.
//
// COMPLETENESS (deferred-layout capstone, 2026-06-21): the immediate-mutator boundary is now fully
// closed, and this SCHEDULE rule is the whole of what needs LINTING. The other freeze vector -- an
// immediate mutator triggering a CLIMB (re-fitting its ancestors up the tree) -- was eliminated not by
// a lint but by deferring the re-fit seam (_announceGeometryChangeToContainer enqueues/invalidates
// the container; its synchronous childGeometryChanged climb arm was retired and that orphaned method
// deleted). What an immediate mutator legitimately MAY do is APPLY a re-fit synchronously IN PLACE -- a
// TERMINAL, single-container apply (TextWdgt._applyExtent->@_reLayoutSelf, StretchablePanelWdgt.
// _applyExtent->@_reLayout, ScrollPanelWdgt/SimpleVerticalStackPanelWdgt._applyExtent->@_reLayoutChildren). Those
// applies are SANCTIONED (see those overrides' comments) -- only the SCHEDULE below is forbidden.
// Forbidding the _reLayoutChildren apply by name was assessed and DECLINED as cosmetic: it does the
// identical work to the blessed _reLayoutSelf/_reLayout applies, so a name-based ban would just force a
// DRY-breaking inline. (deferred-layout-capstone-execution-plan.md, Part B.)
//
// NAME-COVERAGE invariant (lint-ratchet Phase 2, 2026-06-25; kept current through the §6-5 mutator sweep, 2026-06-29):
// every method that writes geometry immediately is recognizably LOW-LEVEL and named in the apply 2x2 family -- an
// _apply* (or its _apply*Base override-bypass twin) / _commit*AndNotify CORNER, or a _move* / _setWidthSizeHeightAccordingly /
// _setExtentToFractional* / _resizeToWithoutSpacing CONVENIENCE (all covered by [E], the SCHEDULE ban below), or a
// __commit* LEAF (covered by the STRONGER [I] no-orchestration ban, which subsumes the schedule ban). The
// structural silent* setters were renamed to the __hide/__addShadow/__add LEAVES (§3d/B13), now [I]-governed. None is
// innocent-named, so [E]/[I] have no blind spot. The only non-low-level methods touching the cache-break are
// constructor (@bounds init, not a mutation), _destroyNoSettle and removeFromTree (teardown / structural-removal
// cache hygiene -- neither writes geometry; removeFromTree is a structural op that legitimately schedules). No escapee.
const isImmediateMutator = (name) =>
  /^_apply(Extent|Bounds|Width|Height|MoveBy|MoveTo)$/.test(name) ||            // ✓/✓ corners — the polymorphic apply (ex *AndNotify; Tier B 2026-07-02). NB _apply*Base is the arrange-bypass twin, NOT matched here.
  /^_commit(Extent|Bounds)AndNotify$/.test(name) ||                             // notify-only corners (ex silentRawSet{Extent,Bounds})
  /^_move(LeftSideTo|RightSideTo|TopSideTo|BottomSideTo|ToSideOf|FullCenterTo|Within|InDesktopToFractionalPosition|InStretchablePanelToFractionalPosition)$/.test(name) ||  // convenience movers (ex fullRawMove*)
  /^_(setWidthSizeHeightAccordingly|setExtentToFractionalExtentInPaneUserHasSet|resizeToWithoutSpacing)$/.test(name);  // convenience setters/resizer (ex rawSet*/rawResize*). NB the ex-silent* structural setters are now __hide/__addShadow/__add LEAVES under [I], NOT immediate-mutators (like the __commit* leaves).
// (the __commit* leaves are deliberately NOT matched here -- rule [I] governs them more strictly. The —/✓ arrange
//  corners _applyExtentBase/_applyMoveByBase/_applyMoveToBase (+ the silent _commitBounds commit) react synchronously and were never [E]-covered;
//  they stay out, exactly as their pre-sweep raw-less _arrangeApply* form was.)

// [D] macro hygiene: a SystemTest macro must drive the world through the PUBLIC widget API ONLY -- never
// the framework's private (_) surface, nor the immediate-mutator geometry API (the _apply*/_commit*/__commit*
// corners + leaves [incl. the ex-silent* __hide/__addShadow/__add structural leaves], the _move*/_set*/_resize* movers).
// HARD ban, no sanctioned escape. Two reasons: (1) the low-level geometry setters bypass the layout settle,
// so a macro poking one on an ATTACHED widget leaks an off-settle container re-fit onto the per-frame
// end-of-cycle flush (the end-of-cycle drawdown); (2) a macro reaching past the public API is testing
// through a back door instead of the surface a user actually drives. This is also the gate that catches the
// original 16-macro private-call mess.
//
// The one historical carve-out -- the construction "measure-and-size" read-back (size a soft-wrapping text
// to its wrapped HEIGHT at a chosen WIDTH: __commitWidth W -> measure -> __commitHeight) -- is now
// CLOSED. The fix is to ATTACH the widget FIRST (to its end destination, or the desktop) and use the PUBLIC
// setters: an attached setWidth SELF-SETTLES, so the text wraps in place and its height is then readable,
// then setHeight (or just let the container fit it). The orphan-before-add trick existed only to avoid a
// settle during construction; attaching first makes the settle legitimate. (If some public geometry method
// genuinely cannot work on an orphan, it should THROW on an orphan rather than invite a raw workaround.)
//
// Scope: BOTH the test macros (tests/*/*_automationCommands.js, scanned whole-file -- they are ~all macro
// source) AND the shared macro VERBS in src/macros/MacroToolkit.coffee -- but for the latter only the
// `Macro.fromString """..."""` heredoc bodies (the L1/L2 toolkit METHODS around them are framework code that
// legitimately uses the low-level API).
const MACROS_DIR = path.join(__dirname, '..', '..', 'Fizzygum-tests', 'tests');
const MACRO_VERBS_FILE = path.join(SRC, 'macros', 'MacroToolkit.coffee');
const MACRO_FORBIDDEN_CALL = /[@.]\s*(_[A-Za-z]\w*|raw[A-Z]\w*)\b/;  // renamed geometry mutators + the ex-silent* structural leaves (__hide/__addShadow/__add) are now _-prefixed (caught by _[A-Za-z]); raw* = the pixel API, still macro-forbidden. (the dead fullRaw\w* and silent\w* arms were dropped with the §6-5 / §3d renames.)

// [G] the STRUCTURAL self-settling-wrapper rule (the deferred-layout "cores call cores" discipline,
// made static). [A] above forbids a low-level method from DIRECTLY calling the 5 geometry setters /
// the single-settling text setters / recalculateLayouts -- a closed, hand-listed set. The SAME
// re-entrancy hazard exists for the STRUCTURAL self-settling wrappers (destroy / close / fullDestroy /
// createReference / grab / drop / slideBackTo / setLabel / _buildAndConnectChildren / ...): each routes
// through the single-mutation settle tier _settleLayoutsAfter, so reaching one from inside a layout pass
// / a *NoSettle core / a raw setter re-enters the flush and hits the runtime throw (Widget.coffee, in
// _settleLayoutsAfter). Low-level code must call the matching _<name>NoSettle CORE, never the wrapper.
//
// The wrapper set is DISCOVERED structurally (discoverSettlingWrappers: every method whose body calls
// @_settleLayoutsAfter), never hand-listed -- so a NEW single-settling wrapper is auto-covered. Only the
// SINGLE-mutation tier counts: SETTLE_CALL matches _settleLayoutsAfter only, the sole settle wrapper. Two
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
// hits, because `constructor` (-> _buildAndConnectChildren -> add) is a hub reached by `new @constructor`
// and `@constructor.name` everywhere, and the raw setters / *NoSettle cores themselves land in the set --
// so it flags the very "cores call cores" pattern it exists to bless. Name-based reachability cannot model
// the orphan guard (a receiver's attached-ness is dynamic), so this DIRECT rule is the maximal SOUND static
// check; the runtime throw stays the backstop for the transitive/dynamic cases (and for `add`).
const SETTLE_CALL = /[@.]\s*_settleLayoutsAfter\b/;          // SINGLE-mutation tier only (Batch absorbs nested settles)
const CALLBACK_HOOK = /^_(reactTo|before)[A-Z]/;            // [J] a notification hook -- settle-neutral by convention (layering/naming convention §3)
// [I] the orchestration verbs a __ LEAF must not @-self-call: the re-fit seam (_reFitContainer* valve + _announce* announce-up), a
// react step (_reLayout\w* = _reLayoutSelf/_reLayoutChildren*/_reLayoutScrollbars/_reLayout; changed/fullChanged),
// a schedule/settle (_invalidateLayout/recalculateLayouts/_settleLayoutsAfter*), or a public setter. Scoped to
// @-self (a .-receiver can't be typed -- like SELF_ADD_CALL); the runtime audit covers dynamic dispatch.
const LEAF_FORBIDDEN = /@\s*(_reFitContainer\w*|_announce\w*|_reLayout\w*|_invalidateLayout|recalculateLayouts|_settleLayoutsAfter\w*|fullChanged|changed|setExtent|setBounds|setWidth|setHeight|moveTo)\b/;  // _reFitContainer* = the phase valve; _announce* = the announce-up seam (§9.4, ex _reFitContainerAfterRawGeometryChange / _refreshScrollPanelWdgtOrVerticalStackIfIamInIt). public setters mirror PUBLIC_SETTERS (moveTo, not the retired fullMoveTo — §6-1)

// [K] the 2x2 apply-family NAME-CONSISTENCY corners (layering/naming convention §2/§4). Since the *AndNotify rename
// (Tier B, 2026-07-02) the axis is REACT × DISPATCH: the polymorphic _apply<Geom> (ex *AndNotify) is the override
// DISPATCH POINT, and its _apply<Geom>Base twin is the override-BYPASS primitive the top-down arrange uses for leaf
// children. We enforce the STATICALLY-SOUND negative that survives post-seam-deletion (in checkFile below): a _apply*Base
// bypass twin reacts only -- it must NOT fire the container re-fit seam (_reFitContainer* valve; the _announce* announce-up
// half is dead, deleted 2026-07-01 -- rule [N]) NOR DISPATCH to its polymorphic _apply* sibling (routing an arrange apply
// back through the very override the twin exists to bypass -- e.g. ClippingAtRectangularBoundsMixin._applyMoveBy, the
// override _applyMoveByBase must skip). The old "*AndNotify REACHES the seam" POSITIVE is retired with the seam (it was
// the RUNTIME auditTierAndApplyNaming's job; the settle-time up-edge replaced the seam). The _commit*AndNotify "must not
// react" half is vacuous (those corners collapsed into the __commit* leaves / _commitBounds 2026-07-01) -- kept as a
// defensive arm. Scoped to the 2x2 CORNERS only: the convenience movers/setters (_move*/_set*/_resize*) delegate to a
// polymorphic _apply* corner freely, so they are NOT subjects.
const APPLY_CORNER = /^_apply(Extent|Bounds|Width|Height|MoveBy|MoveTo)$|^_apply(Extent|MoveBy|MoveTo)Base$|^_commit(Extent|Bounds)AndNotify$/;  // clean poly form | the 3 override-bypass *Base twins | the (collapsed) notify-only commit corners
const K_SEAM_CALL  = /@\s*(_reFitContainer\w*|_announce\w*)\b/;   // the up-notify seam (the DISPATCH-axis negative): _reFitContainer* valve + the _announce* announce-up (dead, deleted 2026-07-01)
const K_REACT_CALL = /@\s*(changed|fullChanged|_reLayout\w*|_positionAndResizeChildren)\b/;           // repaint / self- or child-relayout (the REACT axis)
const K_POLY_APPLY = /[@.]\s*_apply(Extent|Bounds|Width|Height|MoveBy|MoveTo)(?![A-Za-z])/;           // a call to a polymorphic apply corner (the clean _apply*, NOT the _apply*Base twin) — routing an arrange apply back through the override it bypasses
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

// [L] the notification-callback NAME convention (layering/naming convention §3/§4), checked at the method DEF.
// A callback uses the fully-derivable (perspective × phase) scheme _(reactTo|before)(Being|Child|HolderWindow)<Event>
// (SELF = Being, CONTAINER = Child, third-party = HolderWindow; <Event> a PascalCase verb, optionally qualified
// e.g. _reactToChildAddedInScrollPanel / _reactToBeingDroppedIntoFolder). Two static name checks:
//   * any _reactTo*/_before* def MUST match CALLBACK_SHAPE and must NOT carry NoSettle -- a callback is a
//     settle-neutral core by definition (the dispatcher owns the one settle, rule [J]); the NoSettle suffix is
//     reserved for the public-setter cores of §3d-settle, never a callback;
//   * the legacy callback fragments (childX / justBeen / iHaveBeen / aboutTo / prepareTo) are banned outright --
//     the ⚑ rename batches (§9.7-2/3/4) retired them; the (now empty) ban keeps them retired.
// The old _reactToDropOf / _reactToGrabOf "…Of" shape is caught by CALLBACK_SHAPE itself (DropOf/GrabOf is not a
// Being/Child/HolderWindow event), so it needs no separate fragment. The gates (wantsToBe<Event>ed /
// wants<Event>OfChild) are PUBLIC positive bools, not _reactTo*/_before* hooks, so they are outside this rule.
const CALLBACK_PREFIX = /^_(reactTo|before)/;
const CALLBACK_SHAPE = /^_(reactTo|before)(Being|Child|HolderWindow)[A-Z]\w*$/;
const LEGACY_CALLBACK_FRAGMENT = /^(child[A-Z]|justBeen|iHaveBeen|aboutTo|prepareTo)/;

// [M] terminology fragment-ban (layering/naming convention §4): the retired GEOMETRY/STRUCTURAL prefixes must not
// reappear as method names. The geometry raw* setters/movers (rawSet*/fullRawMove*) were eliminated in §6, and the
// structural silent* setters (silentHide/silentAdd/silentAddShadow) in §3d -- this locks them out for good. A small
// allowlist holds the legit raw-PIXEL accessors (raw = raw pixel DATA, not raw geometry). NB `full[A-Z]` is
// DELIBERATELY NOT banned: the geometry full* (fullMoveTo/fullRawMove*) are gone, but full* remains a legitimate
// SUBTREE-AWARE vocabulary (fullChanged / fullCopy / fullDestroy / fullBounds / fullPaintInto / fullImage* -- ~25
// live defs), out of scope for this campaign. Only the specific retired `fullRaw` mover prefix is caught.
const FRAGMENT_BANNED = /^(silent[A-Z]|raw[A-Z]|fullRaw)/;
const FRAGMENT_ALLOWLIST = new Set(['rawPixelInfo', 'rawPixelHash', 'rawRGBA']);  // raw-PIXEL accessors keep "raw" (raw pixel data, not raw geometry)
const APPLY_ANDNOTIFY_BANNED = /^_apply\w*AndNotify$/;  // [M] the retired _apply*AndNotify polymorphic-apply suffix (Tier B, 2026-07-02): the corners dropped it to the bare _apply* once the notify seam was deleted (2026-07-01). NB _commit*AndNotify is a DIFFERENT (collapsed) corner, deliberately not caught here.

// [N] the retired notify-by-mutation CONTAINER SEAM must not be re-defined (Opt-4 hygiene guard, 2026-07-01). The two
// announce-verbs (_announceGeometryChangeToContainer / _announceLayoutPropertyChangeToContainer) were the mutation-time
// re-fit seam a widget fired to nudge its size-tracking container; BOTH were DELETED 2026-07-01 and replaced by the
// settle-time up-edge (_reFitMyTrackingContainerAfterSettle re-fits the container AFTER its content settles, reading
// FINAL geometry, from the settle loop -- assessment §4.1 + §6 rulebook rule 2). Re-introducing a mutation-driven
// container notification re-opens the convergence the arc closed, so lock out the exact removed shape by name. Precise
// (matches only the announce-a-change-TO-a-container seam, not any "announce"), sound TODAY (no _announce* method is
// defined -- verified). Caveat (accepted, per the Opt-4 decision): name-based, so a revival under a NEW name is not
// caught here -- but the CALL side of any such seam already is, by rule [I] (a __ leaf must not @-call _announce*) and
// rule [K] (a _apply*Base bypass twin must not fire _announce*). This closes the DEF side those two never covered.
const SEAM_VERB_BANNED = /^_announce\w*ToContainer$/;   // the deleted notify-by-mutation container-seam shape

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

// --- mixin-DSL awareness: ATTRIBUTE methods defined inside a mixin instead of lumping them into
// onceAddedClassProperties. A mixin (src/mixins/*) declares its methods INSIDE a 2-space
// `onceAddedClassProperties: (fromClass) -> @addInstanceProperties fromClass, { … }` block; the method
// keys sit one nesting level deeper -- 4-space (e.g. KeepsRatioWhenInVerticalStackMixin) or 6-space
// (most others). methodBoundary() locks the hash indent from the FIRST sub-method and treats siblings
// at that indent as headers (deeper lines = their bodies). For a NON-mixin file (no onceAddedClass
// Properties) mixinHashIndent stays null and methodBoundary is byte-for-byte the old 2-space logic.
const MIXIN_CONTAINER = 'onceAddedClassProperties';
const MIXIN_METHOD_HEADER = /^( {4,})([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;

// What a fully-closed line does to the current method grouping:
//   { method, mixinHashIndent, kind:'header'|'end' }  -- the line STARTS or ENDS a method
//   null                                              -- the line is inside the current method's body
// mixinHashIndent: null = not in a mixin block; -1 = in onceAddedClassProperties, awaiting the first
// sub-method to lock the indent; >0 = the locked sub-method indent.
function methodBoundary(raw, mixinHashIndent) {
  const m = raw.match(METHOD_HEADER);                          // a 2-space class / mixin-container method
  if (m) return { method: m[1], mixinHashIndent: m[1] === MIXIN_CONTAINER ? -1 : null, kind: 'header' };
  if (mixinHashIndent !== null) {                              // inside a mixin's onceAddedClassProperties
    const sm = raw.match(MIXIN_METHOD_HEADER);
    if (sm) {
      const indent = sm[1].length;
      const lock = mixinHashIndent === -1 ? indent : mixinHashIndent;   // first sub-method locks the indent
      if (indent === lock) return { method: sm[2], mixinHashIndent: lock, kind: 'header' };
      return null;                                             // deeper: a nested def inside a sub-method body
    }
  }
  if (/^  [A-Za-z_]\w*:/.test(raw) || /^[^\s]/.test(raw)) return { method: null, mixinHashIndent: null, kind: 'end' };
  return null;                                                 // ordinary body line
}

// [G] pre-pass: the set of public methods that self-settle via the SINGLE-mutation tier (their body
// calls @_settleLayoutsAfter) -- the structural wrappers a low-level method must NOT call (it must reach
// the _<name>NoSettle core instead). Computed from source so it tracks the codebase as wrappers are
// added/removed. The 2-space-method grouping mirrors checkFile's exactly. Returns the FORBIDDEN set:
// the discovered wrappers minus the geometry/text setters ([A] covers those) and minus WRAPPER_EXCLUDED.
function discoverSettlingWrappers(files) {
  const wrappers = new Set();
  for (const file of files) {
    const lines = fs.readFileSync(file, 'utf8').split('\n');
    let method = null, mixinHashIndent = null, strState = null;
    for (let n = 0; n < lines.length; n++) {
      const { code, state } = stripLine(lines[n], strState);
      strState = state;
      if (strState === null) {
        const b = methodBoundary(lines[n], mixinHashIndent);
        if (b) { method = b.method; mixinHashIndent = b.mixinHashIndent; if (b.kind === 'header') continue; }
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
  let mixinHashIndent = null; // mixin-DSL grouping state (see methodBoundary): null = not in a mixin block
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
    if (strState === null) {                       // header detection only on fully-closed lines (mixin-aware)
      const b = methodBoundary(raw, mixinHashIndent);
      if (b) {
        method = b.method; mixinHashIndent = b.mixinHashIndent;
        methodMarked = false; methodNoSettleMarked = false; methodGuardReturnLine = -1; methodHWarned = false; methodEarlyReturnMarked = false;
        if (b.kind === 'header') {
          // [L] callback NAME convention (checked once, at the def): derivable shape + legacy-fragment ban (see consts above).
          if (b.method) {
            if (CALLBACK_PREFIX.test(b.method)) {
              if (/NoSettle$/.test(b.method)) violations.push(`[L] callback ${b.method}() carries NoSettle — a notification callback is a settle-neutral core; the dispatcher owns the one settle, so drop the suffix (layering/naming convention §3)  — ${rel}:${n + 1}`);
              else if (!CALLBACK_SHAPE.test(b.method)) violations.push(`[L] malformed callback ${b.method}() — must match _(reactTo|before)(Being|Child|HolderWindow)<Event> (layering/naming convention §3)  — ${rel}:${n + 1}`);
            }
            if (LEGACY_CALLBACK_FRAGMENT.test(b.method)) violations.push(`[L] legacy callback fragment ${b.method}() — use the _(reactTo|before)(Being|Child|HolderWindow)<Event> scheme (layering/naming convention §3/§4)  — ${rel}:${n + 1}`);
            // [M] retired geometry/structural naming fragments (raw* / silent* / fullRaw — see consts above; raw-pixel accessors allowlisted).
            if (FRAGMENT_BANNED.test(b.method) && !FRAGMENT_ALLOWLIST.has(b.method)) violations.push(`[M] retired naming fragment ${b.method}() — the raw*/silent*/fullRaw geometry+structural prefixes were eliminated (§6/§3d); use the _apply*/_commit*/__ tier names (raw PIXEL data uses the rawPixel*/rawRGBA accessors). (layering/naming convention §4)  — ${rel}:${n + 1}`);
            if (APPLY_ANDNOTIFY_BANNED.test(b.method)) violations.push(`[M] retired apply-notify suffix ${b.method}() — the _apply*AndNotify corners were renamed to the bare polymorphic _apply* (Tier B, 2026-07-02, docs/layout-optimizations-and-oo-cleanup-plan.md §3); "AndNotify" asserted a notify seam deleted 2026-07-01. Use _apply* (polymorphic) or _apply*Base (override-bypass twin). (layering/naming convention §4)  — ${rel}:${n + 1}`);
            // [N] retired notify-by-mutation container seam (see the SEAM_VERB_BANNED const above): the deleted _announce*ToContainer verbs must not return as a def.
            if (SEAM_VERB_BANNED.test(b.method)) violations.push(`[N] retired container-seam verb ${b.method}() — the notify-by-mutation re-fit seam (_announce*ToContainer) was deleted 2026-07-01 and replaced by the settle-time up-edge _reFitMyTrackingContainerAfterSettle; do NOT re-introduce a mutation-driven container notification (assessment §4.1 / §6 rulebook rule 2)  — ${rel}:${n + 1}`);
          }
          continue;           // the header line itself carries no call to check
        }
      }
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
    let pub = code.match(PUB_CALL);
    // R2: ignore the HTML5-canvas moveTo (context.moveTo / @moveTo in the canvas extensions), not Widget.moveTo.
    if (pub && pub[1] === 'moveTo' && (CANVAS_EXT_FILE.test(rel) || CANVAS_MOVETO.test(code))) pub = null;
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
      violations.push(`[E] immediate mutator ${method}() calls _invalidateLayout() — an apply/commit corner or convenience mover must only MUTATE geometry, never SCHEDULE layout (task #17)  — ${at}`);
    }
    // [J] settle-neutral callbacks (layering/naming convention §3/§4): a notification HOOK (_reactTo* / _before*)
    // must NOT open a settle -- the gesture/structural DISPATCHER owns the single _settleLayoutsAfter; the hook is
    // a settle-neutral core. (recalculateLayouts inside a hook is already [A]/[B] -- hooks are _-prefixed = low-level.)
    if (CALLBACK_HOOK.test(method) && SETTLE_CALL.test(code)) {
      violations.push(`[J] notification hook ${method}() calls _settleLayoutsAfter — a callback is a settle-neutral core; the dispatcher owns the one settle (layering/naming convention §3)  — ${at}`);
    }
    // [I] the __ LEAF (HARD-FAIL, layering/naming convention §1/§4): a __ method is a true bottom -- via @-self it must
    // trigger NO orchestration (re-fit seam / react step / schedule-settle / public setter). Scoped to @-self (a
    // .-receiver can't be typed; the runtime audit -- a later batch -- covers dynamic dispatch and __-getter purity).
    // recalc/_invalidateLayout overlap [A]/[E] harmlessly.
    if (/^__/.test(method)) {
      const leaf = code.match(LEAF_FORBIDDEN);
      if (leaf) violations.push(`[I] __ leaf ${method}() @-calls ${leaf[1]}() — a __ leaf must trigger no orchestration (seam/react/schedule/settle/public setter); keep it a pure bottom (layering/naming convention §1)  — ${at}`);
    }
    // [K] 2x2 apply-family name-consistency (the two statically-sound negatives; positive reaches-seam is the runtime audit's job, see the defs).
    if (APPLY_CORNER.test(method)) {
      if (/Base$/.test(method)) {
        // override-BYPASS twin (_apply*Base) reacts only — must NOT fire the container re-fit seam nor DISPATCH to its polymorphic _apply* sibling (the corner it exists to bypass)
        if (K_SEAM_CALL.test(code)) violations.push(`[K] bypass twin ${method}() fires the re-fit seam — a _apply*Base primitive reacts only; the polymorphic dispatch point is the bare _apply* corner (layering/naming convention §2)  — ${at}`);
        else { const kc = code.match(K_POLY_APPLY); if (kc) violations.push(`[K] bypass twin ${method}() dispatches to polymorphic ${kc[0].replace(/^[@.]\s*/, '')}() — a _apply*Base must bypass the override, not route the arrange apply back through it (layering/naming convention §2)  — ${at}`); }
      } else if (/^_commit/.test(method) && K_REACT_CALL.test(code)) {
        // notify-only corner (_commit*AndNotify) commits + notifies — must NOT react  [vacuous: these corners collapsed into the __commit* leaves / _commitBounds 2026-07-01]
        violations.push(`[K] notify-only corner ${method}() reacts via ${code.match(K_REACT_CALL)[1]}() — _commit*AndNotify only commits; the reacting polymorphic mutator is _apply* (layering/naming convention §2)  — ${at}`);
      }
      // the clean polymorphic _apply* (ex *AndNotify) reacts + IS the override dispatch point — no static negative:
      // its "reaches the container re-fit" is now the settle-time up-edge's job, not a corner-name invariant.
    }
    if (recalc && !RECALC_WHITELIST.has(method)) {
      violations.push(`[B] recalculateLayouts() called from ${method}() (only doOneCycle / _settleLayoutsAfter may)  — ${at}`);
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
// narrative comments (which legitimately mention e.g. adjustContentsBounds / @_moveWithin).
// heredocOnly: scan only the `Macro.fromString """..."""` bodies (for MacroToolkit.coffee, whose
// surrounding L1/L2 toolkit methods are framework code). When false, scan the whole file (the test
// automationCommands.js are ~all macro source).
function checkMacroFile(file, violations, heredocOnly) {
  const rel = path.relative(path.join(__dirname, '..', '..'), file);
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  let inHeredoc = false;
  for (let n = 0; n < lines.length; n++) {
    const raw = lines[n];
    if (heredocOnly) {
      if (!inHeredoc) {
        if (/Macro\.fromString\s+"""/.test(raw)) inHeredoc = true;  // opener; its own line has no body call
        continue;
      }
      if (/^\s*"""\s*$/.test(raw)) { inHeredoc = false; continue; }  // lone closing """
    }
    const hash = raw.indexOf('#');
    const code = hash >= 0 ? raw.slice(0, hash) : raw;
    const m = code.match(MACRO_FORBIDDEN_CALL);
    if (m) violations.push(`[D] macro calls private/low-level .${m[1]}() — ${rel}:${n + 1} `
      + `(use the PUBLIC API; for measure-and-size, attach the widget first then setExtent/setWidth/moveTo)`);
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
  // matches a CALL to one. Empty-set guard keeps the regex well-formed (a few dozen names in practice;
  // now mixin-aware -- see methodBoundary -- so a settling wrapper defined inside a mixin is attributed too).
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
    // also scan the SHARED macro verbs in MacroToolkit.coffee (heredoc bodies only)
    if (fs.existsSync(MACRO_VERBS_FILE)) {
      try { checkMacroFile(MACRO_VERBS_FILE, violations, true); macroCount++; }
      catch (e) { console.error(`check-layering: operational error in ${MACRO_VERBS_FILE}:`, e.message); process.exit(2); }
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
    console.error('E: immediate geometry mutators (apply/commit corners + convenience movers) must not call _invalidateLayout) and docs/deferred-layout-16-macro-breakages.md (A/B/C).');
    console.error('F: a non-mutator handler must DEFER a container apply (_invalidateLayout) or mark it `# layout-apply-sanctioned: <why>` — see docs/deferred-layout-OVERVIEW.md §11.');
    console.error('G: low-level code must reach the _<name>NoSettle core, not the public self-settling wrapper (destroy/close/fullDestroy/createReference/...) — or mark `# nosettle-sanctioned: <why>`.');
    console.error('I: a __ leaf must trigger no orchestration (re-fit seam / react / schedule-settle / public setter) — keep it a pure bottom (layering/naming convention §1).');
    console.error('J: a notification hook (_reactTo*/_before*) must not open a settle — the gesture/structural dispatcher owns the one _settleLayoutsAfter (layering/naming convention §3).');
    console.error('K: a 2x2 apply corner must match its name — a _apply*Base bypass twin must not fire the container re-fit seam nor dispatch to its polymorphic _apply* sibling; a _commit*AndNotify must not react (layering/naming convention §2).');
    console.error('L: a notification callback must be named _(reactTo|before)(Being|Child|HolderWindow)<Event> with no NoSettle; the legacy fragments (childX/justBeen/iHaveBeen/aboutTo/prepareTo) are retired (layering/naming convention §3/§4).');
    console.error('M: the retired raw*/silent*/fullRaw fragments and the _apply*AndNotify suffix must not reappear as method names (use _apply*/_apply*Base/_commit*/__ tiers; raw PIXEL data uses rawPixel*/rawRGBA) (layering/naming convention §4).');
    console.error('N: the retired notify-by-mutation container seam (_announce*ToContainer) must not be re-defined — the settle-time up-edge _reFitMyTrackingContainerAfterSettle replaced it (assessment §4.1 / §6 rulebook rule 2).');
    process.exit(1);
  }
  console.log(`layering gate: ${files.length} source(s) + ${macroCount} macro(s) — 0 violations (A/B/C/D/E/F/G/I/J/K/L/M/N; ${FORBIDDEN_WRAPPERS.size} settling wrappers guarded)${warnings.length ? `; ${warnings.length} [H] warning(s)` : ''}`);
  process.exit(0);
}

main();
