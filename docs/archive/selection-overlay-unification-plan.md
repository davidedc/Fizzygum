> **ARCHIVED — ✅ COMPLETE + LANDED (2026-07-21).** Implemented and gauntlet-green; commits Fizzygum `9a673549` + Fizzygum-tests `0b6acc769` (master). The world-attached HighlighterWdgt editor-focus indicator is REPLACED by a per-widget paint-time selection overlay (`Widget._drawSelectionOverlay`, drawn after the subtree, clipped to the widget's visible footprint); §5.D D-3/D21 world-child indicator superseded. The hover hook `paintHighlight` was renamed `_drawHighlightOverlay`. Chrome is excluded via `excludedFromEditorFocusTracking`; the spreadsheet cell keeps its own inline ring.
> Historical record + case law; do not execute — the body below still reads "no code written" as authored. Index: `docs/archive/INDEX.md`.

# Selection-overlay unification — draw the editor-focus selection as a per-widget PAINT-TIME overlay

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
No code has been written for this plan. It reworks code that is already committed (the §5.D D-3 /
D21 editor-focus indicator). Read this whole doc before touching anything; grep every cited symbol
fresh (line numbers drift — the method name / quoted code is authoritative).

**Mandate: complete transformation, not a patch.** ELIMINATE the world-attached selection-indicator
widget entirely and replace it with a per-widget paint-time overlay, folding the spreadsheet's bespoke
cell-selection ring into the SAME mechanism. This is not "make the overlay stay on top" — it is "the
selection is a thing a widget draws on top of its own content, and there is ONE such mechanism."

---

## §0 Orientation

**Framework.** Fizzygum is a CoffeeScript single-`<canvas>` GUI framework (Morphic descendant). `nil` =
`undefined`. One class per file (filename == class). No module system — load order is regex-discovered
from literal `new X` / `extends X` / `@augmentWith X`, so a dynamic `new someVar` produces NO dependency
edge and crashes boot. Rendering is a broken-rectangles (dirty-region) repaint; widgets opting into
`BackBufferMixin` cache their own image to an offscreen buffer that is BLITTED each paint. Tests are
screenshot-diff **SystemTests** (macros); verify with the umbrella `fg` wrapper (`fg build`,
`fg presuite`, `fg gauntlet`). Never commit/push without owner approval.

**Immediately-prior arc + result.** The Frame-model flagship arc (`docs/plans/onion-widget-composition-plan.md`)
landed §5.D **D-3** (a visible editor-focus indicator, commit `6f1514b4`) and, uncommitted at the time
this plan was written, **D21** (also frame a widget selected inside an editable container). Both were
built as a **reconciled, world-attached `HighlighterWdgt` overlay**: `WorldWdgt.addEditorFocusIndicatorWidget`
runs each cycle, computes the selected widget via `_widgetBeingEdited()`, and creates/moves/destroys ONE
`HighlighterWdgt` (a teal outline) parented into the target's island-or-world.

**Why this plan exists now (three owner-reported defects, all rooted in "the indicator is a separate
world widget"):**
1. **Bug 1 — the teal frame vanishes on mousedown, before any op.** ROOT CAUSE (confirmed by probe):
   the indicator is a plain WORLD child. On mousedown inside a window, `Widget.mouseDownLeft →
   bringToForeground` moves that window to the front (last world child), so the window's opaque content
   paints OVER the indicator. The caret does NOT suffer this because it is parented INSIDE the edited
   widget's subtree (`WorldWdgt.edit` → `addCaret target.parent, caret`), so it rides the window forward.
   The indicator (parented to the world) does not.
2. **Correction 1 — chrome gets framed.** The frame-bar chrome buttons (`EditIconButtonWdgt` /
   collapse / uncollapse — all `extends IconButtonWdgt extends ButtonWdgt`) are NOT
   `excludedFromEditorFocusTracking`, so clicking the eye/pencil sets `editorFocusWdgt` = that button and
   D21 frames it. A pre-existing gap, invisible before D-3/D21.
3. **Correction 2 — two selection mechanisms.** A spreadsheet cell showed BOTH its native blue ring AND
   the D21 teal frame. The owner wants ONE selection mechanism where widgets override how selection LOOKS.

**⚡ CRITICAL REFRAME (owner, verbatim intent):** *"I don't think this should be a widget… it should be
just a drawing thing that the widget itself overlays on top of its own drawing. If the widget has a
buffer, the selection should not be part of the buffer, should be on top of it."* → The selection is a
per-widget **paint-time decoration drawn on top of the widget's own content (after the back-buffer
blit)**, NOT a separate widget. This single change fixes all three defects: (1) z-order is free — a
widget's own drawing is always on top of its content and rides its z-order; (2) chrome simply doesn't opt
in; (3) the spreadsheet cell already draws its ring this way (see §2), so the two mechanisms become one.

---

## §1 The hook already exists — `paintHighlight`

The framework ALREADY has the exact "draw on top of my own content, after the buffer" hook the owner
describes, and it is currently a no-op stub waiting for a consumer:

- **`Widget.paintHighlight: (aContext, al, at, w, h) -> @appearance?.paintHighlight …`** (`basic-widgets/
  Widget.coffee`, ~:434).
- **`RectangularAppearance.paintHighlight`** (`basic-widgets/RectangularAppearance.coffee`, ~:26) is
  literally `return` (no-op), with commented-out example code that draws an outline via `paintRectangle`
  in ACTUAL pixels, and this comment (authoritative): *"useful for example when hovering over references
  to widgets. Can only modify the rendering of a widget, so any highlighting is only visible in the
  measure that the widget is visible (as opposed to `HighlighterWdgt` being used to highlight a widget)."*
  — i.e. it was designed to be the on-top-of-content alternative to the `HighlighterWdgt` widget.
- **It is called AFTER the content paint / buffer blit, in screen pixels**, in every paint path:
  `BackBufferMixin.paintIntoAreaOrBlitFromBackBuffer` calls `@paintHighlight aContext, al, at, w, h`
  (`mixins/BackBufferMixin.coffee` ~:137) right after `aContext.drawImage @backBuffer …` + `restore()`;
  and the non-buffered path calls it from each appearance (`RectangularAppearance` ~:110,
  `BoxyAppearance` ~:85, `CircleBoxyAppearance` ~:95, `AnalogClockWdgt` ~:117, `GraphsPlotsChartsWdgt`
  ~:77, `Example3DPlotWdgt` ~:215, `UpperRightTriangleAppearance` ~:31, `HandleWdgt` ~:153, `PenWdgt`
  ~:97, `LayoutChromeWdgt` ~:62, `LabelButtonWdgt` ~:167). `al, at, w, h` are the widget's actual
  on-screen pixel rect (post-dpr), so a stroke there lands exactly on the widget's screen footprint.

**Consequence:** the selection overlay belongs in `paintHighlight` (or a sibling hook called from the
same site). No new paint plumbing is needed; the recursion + clipping + shadow handling already runs it.

---

## §2 The spreadsheet is the PRECEDENT — this migration already happened once

The spreadsheet ALREADY moved its selection from "the sheet paints the ring" to "each cell draws its own
ring on top of itself", for the identical reason (a container-drawn overlay gets overdrawn by the
widgets on top of it). This is the proof the owner's architecture works in-tree.

- `SimpleSpreadsheetWdgt` owns the selection STATE: `@selectedCol` / `@selectedRow` (document state,
  serialized), `@selectionColor = Color.create 40, 110, 210` (`spreadsheet/SimpleSpreadsheetWdgt.coffee`
  ~:115/116/128), navigated by CLICK and by ARROW KEYS (~:604-613), with public
  `isSelectedAddress(address)` (~:456-458). ⚠ This selection is MODEL-based (col/row) + keyboard-navigable
  + viewport-recycled — it is NOT `editorFocusWdgt`-based, and the generic click-based mechanism does NOT
  subsume it (established feasibility finding). Unification is at the DRAWING layer, not the state layer.
- Each `CellWdgt` DRAWS its own ring in its paint (`spreadsheet/CellWdgt.coffee` ~:120-123):
  ```coffee
  if sheetWidget.isSelectedAddress @address
    aContext.strokeStyle = sheetWidget.selectionColor.toString()
    aContext.lineWidth = 2
    aContext.strokeRect 2, 2, @width() - 4, @height() - 4
  ```
- **Why it moved (F5 receipt B, from `src/spreadsheet/CLAUDE.md`):** *"once cells stroke their own edges
  AFTER the sheet's paint, a sheet-drawn ring's antialiased bands get overdrawn — 91/348 px flip at
  dpr1/dpr2 — so sheet-drawn selection cannot survive the widgetisation."* Exactly the z-order lesson of
  Bug 1, learned earlier for the sheet.

**The unification target:** the cell's ring becomes an OVERRIDE of the shared selection hook —
`showsSelectionOverlay()` = `sheetWidget.isSelectedAddress @address`, `drawSelectionOverlay` = the blue
`strokeRect`. The generic default (teal outline, gated by `editorFocusWdgt`) and the cell's blue ring are
then two skins of ONE mechanism.

---

## §3 Current state to REMOVE / KEEP (grep every symbol fresh)

**REMOVE (the world-attached overlay-widget machinery), all in `src/WorldWdgt.coffee`:**
- `editorFocusIndicatorWdgt: nil` (field decl, ~:282 area).
- `addEditorFocusIndicatorWidget: ->` (the reconciler, ~:1639) AND its call in `doOneCycle`
  (`@addEditorFocusIndicatorWidget()`, right after `@addHighlightingWidgets()`, ~:1762).
- The reset nil-out in `_resetWorldNoSettle` (`@editorFocusIndicatorWdgt = nil`).
- `HighlighterWdgt.editorFocusOutlineStyle: ->` (`src/HighlighterWdgt.coffee`).
- The allowlist line `addEditorFocusIndicatorWidget` in `buildSystem/public-api-allowlist.txt`.

**KEEP (the selection LOGIC — this is correct and hard-won):**
- `editorFocusWdgt` (the sticky focus pointer) + its two set sites in `ActivePointerWdgt` (~:498 drop,
  ~:795 click, both ancestry-excluded via `_excludedFromEditorFocusTrackingByAncestry`) + its clears
  (`_softResetWorld`, and the D2b destroy-time clear in `Widget._destroyNoSettle`).
- `WorldWdgt._widgetBeingEdited()` — the predicate (world-guard `return nil if focus is @`; TEXT branch
  `@caret? and @caret.target is focus`; CITIZEN branch `focus.providesAmenitiesForEditing and
  focus.dragsDropsAndEditingEnabled`; **D21** SELECTED-ITEM branch: walk `focus.parent` up, `true` ⇒
  frame if edit-mode, explicit `false` ⇒ stop (spreadsheet-grid opt-out), else keep walking). This
  predicate MOVES from "what the reconciler frames" to "what `showsSelectionOverlay` asks". Rename to a
  query name that reads as a predicate over an ARGUMENT (e.g. `_isTheEditorSelectedWidget(w)` or a cached
  `_editorSelectedWidget()`), see §4.

**FIX (correction 1 — chrome exclusion), independent of the overlay rework:**
- The frame-bar chrome buttons are not editor-focus-excluded. Add `excludedFromEditorFocusTracking: ->
  true`. Decide the level: `EditIconButtonWdgt` (`buttons/EditIconButtonWdgt.coffee`) + the collapse pair
  (`CollapseIconButtonWdgt` / `UncollapseIconButtonWdgt`) individually, OR their shared base
  `IconButtonWdgt` (`buttons/IconButtonWdgt.coffee`), OR `ButtonWdgt` (broadest — "a button is an action
  trigger, never editor content"). ⚠ Adding a METHOD to `ButtonWdgt`/`IconButtonWdgt` is inspector-safe
  (the inherited-members inspector test inspects a `Rectangle`, which descends from neither) — but the
  DEAD-METHODS gate and the paint change are separate; verify at execution. Recommended: exclude at
  `ButtonWdgt` (most principled + subsumes the ad-hoc per-button declarations that already exist), unless
  a concrete button is found that legitimately needs to be `editorFocusWdgt` (none known).

---

## §4 Fix shape (the design)

**A. One "who is selected" query, computed cheaply.** `paintHighlight` runs for EVERY painted widget
every cycle, so do NOT recompute `_widgetBeingEdited()` (which walks the parent chain) per widget.
Compute the generic selected widget ONCE per cycle and cache it (e.g. `@_editorSelectedWidgetThisCycle`,
set at the top of the paint pass or lazily-once-per-`frameCount`), and have widgets compare by identity.
Concretely a Widget-level query:
```coffee
# Widget
showsSelectionOverlay: ->        # overridable; default = "I am the generic editor-selected widget"
  world._isEditorSelected @
drawSelectionOverlay: (aContext, al, at, w, h) ->   # overridable appearance; default teal outline
  @paintRectangle aContext, al, at, w, h, <teal 38,166,154>, 1, true, true   # stroke-only, actual px
```
`WorldWdgt._isEditorSelected(w)` returns `w is @_editorSelectedWidgetThisCycle` where the cached value is
`@_widgetBeingEdited()` computed once per cycle. (Name/shape is a design choice — the INVARIANT is:
per-widget, cheap identity check, single source of truth for "which widget is generically selected".)

**B. Wire the hook + RENAME it (owner, 2026-07-20).** The hook now paints BOTH the hover-highlight AND
the selection, so rename `paintHighlight` to reflect that — proposed **`paintSelectionOrHighlight`** (or
`paintHighlights`). This is a whole-tree identifier sweep: the two DEFINITIONS (`Widget.coffee` ~:434;
`RectangularAppearance.coffee` ~:26 + the base `Appearance.coffee` ~:31) and every CALL site
(`BackBufferMixin.coffee` ~:137; the appearance paint paths `RectangularAppearance` ~:110, `BoxyAppearance`
~:85, `CircleBoxyAppearance` ~:95, `AnalogClockWdgt` ~:117, `GraphsPlotsChartsWdgt` ~:77,
`Example3DPlotWdgt` ~:215, `UpperRightTriangleAppearance` ~:31; and the widgets that call it directly —
`HandleWdgt` ~:153, `PenWdgt` ~:97, `LayoutChromeWdgt` ~:62, `LabelButtonWdgt` ~:167; plus the commented
`IconAppearance` ~:120) — grep `paintHighlight` fresh for the complete set (~15 sites + defs) and rename
ALL in one commit. Then, after the existing hover-highlight no-op body, call the selection draw:
```coffee
paintSelectionOrHighlight: (aContext, al, at, w, h) ->
  # (existing hover-highlight stub stays)
  if @showsSelectionOverlay() then @drawSelectionOverlay aContext, al, at, w, h
```
Placed on `Widget` (or threaded through the appearance's renamed method to keep the appearance the draw
authority — match the existing pattern; the appearance already receives `al,at,w,h`). Draw with a
transparent fill + coloured stroke (an OUTLINE), in ACTUAL pixels, matching today's teal look. ⚠ Pure
rename ⇒ pixel-IDENTICAL: land the rename FIRST as its own byte-identical commit (no behaviour), THEN add
the selection draw — so a diff in the recapture step is unambiguously the new overlay, not the rename.

**C. Fold in the spreadsheet.** `CellWdgt` overrides `showsSelectionOverlay -> sheetWidget.isSelectedAddress
@address` and `drawSelectionOverlay` = its `strokeRect 2,2,w-4,h-4` blue ring; REMOVE the inline ring at
`CellWdgt.coffee` ~:120-123 (it becomes the override). ⚠ The cell ring is currently drawn in LOGICAL
pixels inside `useLogicalPixelsUntilRestore()` + a translate (its paint at ~:110-128); `paintHighlight`
hands ACTUAL pixels — so either keep the cell's ring where it is but route it through the shared
`showsSelectionOverlay` predicate, OR re-express it in actual pixels in the hook. Prefer the smallest
change that UNIFIES the predicate; pixel-identity is the gate (F5 recaptured the whole `macroSpreadsheet*`
family for this ring once already — a second move must be pixel-audited, §6).

**D. Correction 1.** Add `excludedFromEditorFocusTracking -> true` per §3 FIX.

**E. Delete the overlay-widget machinery** per §3 REMOVE, and delete the now-obsolete parts of the plan
`onion-widget-composition-plan.md` §5.D D-3/D21 that describe the widget-overlay (weave in a pointer to
THIS plan; keep the decisions D18-D21 as the surviving selection SEMANTICS).

---

## §5 Central risks (and how each is handled)

1. **Invalidation on selection CHANGE (the #1 risk).** The reconciler used to invalidate via the
   `HighlighterWdgt`'s own `changed()`/`fullDestroy()`. With a paint-time overlay, when the selected
   widget changes (A→B, or on/off), BOTH the old and new widgets must be `changed()` so their
   `paintHighlight` re-runs and the broken-rect repaint covers them — else A keeps a stale teal frame or
   B never gets one. **Handling:** at the `editorFocusWdgt` mutation sites (and the caret/edit-mode
   transitions the predicate reads), mark the OLD and NEW selected widgets `changed()`. The spreadsheet
   PRECEDENT does exactly this on cell-nav (mark old+new cells changed). ⚠ Also the D21/citizen predicate
   can change WITHOUT `editorFocusWdgt` changing (e.g. pencil toggled): a per-cycle diff of
   `_editorSelectedWidgetThisCycle` vs last cycle's value, invalidating both on change, is the robust
   general form — implement that (compute once per cycle, if changed since last cycle `changed()` old +
   new). This keeps it a pure function of state and needs no wiring at every predicate input.
2. **Cost.** `paintHighlight` runs per painted widget. The identity check must be O(1) (cached selected
   widget, §4-A). Do NOT call `_widgetBeingEdited()` (parent walk) per widget.
3. **Determinism.** The overlay is drawn on top each paint as a pure function of the (settled) selection
   state + geometry — never into the cached buffer (so buffer caching is untouched, per the owner's
   requirement) and never timer/frame-count dependent. `revisits`/`census` must stay zero (no layout
   effect — this is pure paint). The per-cycle "invalidate on change" must be a pure function of the
   event-driven selection state (it is). Read `Fizzygum-tests/DETERMINISM.md` §5 before touching paint.
4. **Clipping.** A widget's own `paintHighlight` is clipped to the widget's paint area (unlike the
   world-child overlay, which could draw outside a scroll clip). The teal frame at the widget's own
   bounds is inside its own footprint, so a `strokeRect` on `al,at,w,h` lands on the widget edge — fine.
   But a 2px stroke centred on the edge draws 1px OUTSIDE the clip → may be cropped. Match the cell's
   proven inset form (`strokeRect 2,2,w-4,h-4` draws fully INSIDE) if edge-cropping shows in diffpages.
5. **Affine islands.** The old reconciler re-parented the overlay into `target._enclosingNonIdentityIsland()`
   for R2 (warps + clips with the target under rotation). A paint-time overlay drawn by the widget itself
   is ALREADY in the widget's plane (its paint runs under the island transform) — so islands are handled
   for free and MORE correctly. Verify with the `macroTransformFrame*` tests (they were in the D-3
   recapture set).
6. **Recapture churn.** Every test currently showing the teal frame (the D-3 44 + the D21 set) will
   re-render; the pixels should be ~identical (same teal outline) but the drawing path changed, so treat
   ALL as conscious recaptures — diffpage + owner eyeball BEFORE recapturing (owner rule). The spreadsheet
   family may recapture again (the ring move).

---

## §5.5 Spikes (do FIRST, before the full rework)

- **S1 — paint-hook proof.** In a `.scratch` probe (reuse `Fizzygum-tests/scripts/lib/headless-boot`),
  after the rework of a SINGLE widget type, confirm: (a) a selected text widget draws the teal frame on
  top of its own content; (b) clicking a chrome button that `bringToForeground`s the window does NOT bury
  it (the whole point — reproduce Bug 1's setup: Doc Maker paragraph selected + `world.hand`-synthesised
  Bold click, screenshot, assert the teal is still painted). The Bug-1 repro probes already exist in
  `.scratch` (docmaker-*.js) — adapt them.
- **S2 — invalidation.** Confirm A→B selection change repaints both (no stale frame on A). Drive
  `editorFocusWdgt` A then B across cycles, screenshot each, assert.
- **S3 — spreadsheet parity.** After folding the cell ring into the hook, confirm `isSelectedAddress`
  still drives the blue ring pixel-identically (diffpage the `macroSpreadsheet*` set).

---

## §0.5 Cold-execution protocol (run in THIS order)

1. **Orient.** Read this whole doc. Read `onion-widget-composition-plan.md` §5.D D-3/D21 (the semantics
   you keep). Read `src/spreadsheet/CLAUDE.md` "F2/F5" (the precedent) + `Fizzygum-tests/DETERMINISM.md`
   §5. Grep fresh: `paintHighlight`, `addEditorFocusIndicatorWidget`, `_widgetBeingEdited`,
   `editorFocusWdgt`, `excludedFromEditorFocusTracking`, `isSelectedAddress`.
2. **Verify state.** `fg status`. Expect the D-3 machinery present in `WorldWdgt`/`HighlighterWdgt`/
   allowlist. If D21 is still uncommitted, that is fine — this plan supersedes its overlay parts.
3. **Spikes S1-S3** (§5.5) — do NOT proceed to the full rework until S1 (z-order fixed) + S2
   (invalidation) pass in a probe.
4. **Implement** §4 A-E, smallest coherent commits. Build after each (`fg build`).
5. **Verify + land** per §6. diffpage + OWNER EYEBALL before ANY recapture (standing rule). Recapture,
   `fg gauntlet` (revisits/census MUST be zero), author/keep the guard test, present the commit(s) for
   approval.

---

## §6 Verification protocol

- `fg build` after each change (0 violations / `done!!!`; watch the call-separation + dead-methods +
  layering gates — removing `addEditorFocusIndicatorWidget` also removes its allowlist line, and the
  chrome-exclusion add must not trip dead-methods).
- `fg presuite` to MEASURE the recapture footprint. `fg diffpage <names…>` on a representative sample
  (one text case, one citizen, one spreadsheet, one `TransformFrame*`) → OWNER EYEBALL before recapturing.
- Recapture consciously; `fg gauntlet` (all 11 legs; **revisits + census MUST stay zero** — this is pure
  paint, no layout effect).
- **Guard test:** the existing `SystemTest_macroEditorFocusIndicatorTracksEditedWidget` should still pass
  (recaptured). ADD or extend a guard that reproduces Bug 1: enter edit mode on a text widget INSIDE a
  window, click a toolbar button that `bringToForeground`s the window, screenshot — the selection overlay
  MUST still be visible (this is the regression the whole plan fixes).

---

## §7 Rejected alternatives (do-not-re-attempt)

- **Keep the world-attached `HighlighterWdgt` overlay and just re-assert its z-order each cycle
  (bring-it-to-front in the reconciler).** REJECTED by the owner: *"I don't think this should be a
  widget."* It also fights `bringToForeground` every cycle (churn) and does not unify with the
  spreadsheet. The paint-time overlay is strictly better (z-order free, unifies, no widget).
- **Full architectural unification of the spreadsheet's STATE into `editorFocusWdgt`** (make the sheet
  push `editorFocusWdgt` on every cell nav, drop `@selectedCol/Row`). REJECTED as out of scope: the
  spreadsheet selection is model-based / keyboard-navigable / viewport-recycled and does not fit the
  click-based `editorFocusWdgt` pointer. Unify the DRAWING (one `paintHighlight` hook), not the state.
- **Draw the selection INTO the widget's back-buffer.** REJECTED by the owner (verbatim): the selection
  must be *"on top of"* the buffer, not part of it — so it can toggle without invalidating the cached
  buffer and always sits above the content.

---

## §8 References

- `docs/plans/onion-widget-composition-plan.md` §5.D D-3/D21 — the selection SEMANTICS being kept
  (decisions D18-D21) and the overlay-widget approach being superseded.
- `src/spreadsheet/CLAUDE.md` (F2/F5 "the sheet paints the STATE, the cell renders it"; F5 receipt B) —
  the in-tree precedent this plan generalises.
- `Fizzygum-tests/DETERMINISM.md` §5 — paint determinism + the broken-rect staleness bug class.
- Memory: `onion-widget-composition-arc` (D-3/D21 case law), `broken-rect-staleness-invisible-to-screenshots`,
  `swcanvas-reproduces-what-native-hides`.
- Bug-1 evidence: `.scratch/docmaker-*.js` probes (confirmed `paintedAfterIndicator: ["DocumentWdgt"]` —
  `bringToForeground` buries the world-child indicator).
