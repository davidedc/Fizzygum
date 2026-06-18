# Plan: convert SimplePlainTextWdgt soft-wrap from IMMEDIATE (raw) to DEFERRED (invalidateLayout) layout

**Status: ASSESSED 2026-06-18 — DEFERRED FOR NOW (revisit-able). NOT a closed "LEAVE".**
The deferred-layout pattern remains the *ideal target*; this session verified the current code,
**corrected a wrong premise in the original plan**, and concluded the full conversion is not worth
doing *yet* because there is no clean determinism-safe seam today. We recorded exactly *why* it is
blocked and *what a future conversion would have to solve* (see §0 and §6), and made two tiny safe
cleanups (see §13), so a later session can pick this up without re-deriving anything.

This file is intended to be executable *cold* (no prior conversation context). Read it top to bottom.

---

## 0. Assessment outcome (2026-06-18) — read this first

**Decision: deferred for now, revisit-able.** The toggle stays IMMEDIATE; we keep the door open.

**The original plan's "Blocker #1" was FACTUALLY WRONG and is corrected here.** It claimed the
high-level `setExtent` can't be used on the scroll panel's content because the content panel is
"layout-managed, not freefloating." In fact the content `PanelWdgt` **is**
`LayoutSpec.ATTACHEDAS_FREEFLOATING` (verified: `ScrollPanelWdgt` ctor `@addRaw @contents` →
`Widget.addRaw` defaults `layoutSpec = ATTACHEDAS_FREEFLOATING`; the class default agrees; no override
anywhere). So `setExtent`'s freefloating gate would *pass*. `setExtent` being unusable is **not** why
the code uses raw geometry.

**The REAL obstacle (decisive, verified):** *the deferred cycle never reaches the wrap geometry.*
1. The content panel + the text are both `ATTACHEDAS_FREEFLOATING`. `invalidateLayout` only propagates
   **up** the tree when `@layoutSpec != ATTACHEDAS_FREEFLOATING` (`Widget.coffee` ~`:3575`). So
   `invalidateLayout()` on the text/content marks **only itself** dirty — it does **not** climb to the
   `ScrollPanelWdgt`.
2. The wrap geometry (content sized to viewport, each `FIT_BOX_TO_TEXT` child constrained to content
   width) lives in `ScrollPanelWdgt.adjustContentsBounds`, which is **not on the
   `recalculateLayouts → doLayout` path**: `ScrollPanelWdgt` defines no `doLayout`, and no `doLayout`
   in the codebase calls `adjustContentsBounds`. Even forcing the scroll panel dirty doesn't help — its
   `rawSetExtent` (the only place `doLayout` would reach `adjustContentsBounds`, inline) is guarded
   `unless aPoint.equals @extent()`, and a wrap toggle does **not** change the viewport extent, so that
   block is skipped.
3. So a deferred toggle would re-`reLayout` the **text alone** (via
   `doLayout → rawSetBounds → TextWdgt::rawSetExtent → reLayout`) and never run the panel-level wrap
   recompute. To fix that you must wire `adjustContentsBounds` into the cycle — which trips the two
   hazards below.

**Why wiring it in is hazardous (the "tricky" part):**
- **Global ripple.** `implementsDeferredLayout()` is literally `@doLayout != Widget::doLayout`
  (`Widget.coffee` ~`:3756`). Giving `ScrollPanelWdgt` a `doLayout` flips this predicate `false → true`
  for **every** scroll panel + `ListWdgt` + the `Simple*ScrollPanelWdgt` family. It's consulted in
  `subWidgetsMergedFullBounds` (`Widget.coffee` ~`:990`, called from inside `adjustContentsBounds`):
  a child that `implementsDeferredLayout()` contributes `child.bounds` instead of `child.fullBounds()`
  to the merge — so **nested** scroll panels would silently change merged-bounds → geometry shifts in
  cases far from soft-wrap. Large, hard-to-bound blast radius.
- **Determinism (`[DET]`).** `adjustContentsBounds` hard-writes `widget.softWrap = true` in its
  wrapping branch (~`:289`). A deferred text `reLayout` reads the text's *current* `@softWrap`; routed
  through the cycle, the final wrapped width then depends on the **order** the dirty queue happens to
  interleave the text's `doLayout` and the panel's `adjustContentsBounds`. That is precisely the
  "render must not depend on an intermediate layout pass" rule in `Fizzygum-tests/DETERMINISM.md`, and
  it's the class of bug that surfaces at **dpr2 under parallel load**.

**ROI / framing.** Soft-wrap is a discrete, rare user action — no batching benefit. The only win is
*consistency* with the framework's layout pattern + removing a raw mutation from a click handler; it
ships nothing user-facing. This sits in the same DET-core territory as Phase-6 **Tier 4** (the
layout/scroll capstone, assessed = LEAVE). Given the global ripple + the determinism hazard + ~41
SystemTests exposed (§10), the risk/reward is negative **today**. Hence: *deferred for now, not never.*

---

## 1. Orientation — read these first (cold start)

- **`Fizzygum-tests/DETERMINISM.md`** — the byte-exact screenshot contract. MANDATORY before
  touching render/layout/input code. The one-line rule: *render must be a pure function of the
  event stream + final geometry, never of wall-clock time, frame/cycle count, or an
  intermediate layout pass.*
- **`Fizzygum/CLAUDE.md`** + **`Fizzygum-tests/CLAUDE.md`** — build/run/test mechanics.
- This conversion came out of the OO-smell campaign **Phase 7** (coupling cleanups). The
  campaign tracker is **`Fizzygum/docs/oo-smells-refactoring-backlog.md`**; the God-class arc
  (Phase 6, COMPLETE) is **`Fizzygum/docs/god-class-decomposition-plan.md`**. Phase-6 **Tier 4**
  (the layout/scroll DET capstone) was assessed **= LEAVE** (no clean determinism-safe seam) —
  this soft-wrap conversion sits in the **same DET-core territory**, so that verdict is the precedent.

### What Fizzygum is (one paragraph)
A CoffeeScript GUI framework ("web OS") rendered on a single HTML5 `<canvas>`, descended from
Morphic.js. No module system — every class is a global compiled in-browser; reference a class
by naming it. `nil` means `undefined`. Widgets form a tree (`TreeNode → Widget → PanelWdgt → …
→ WorldWdgt` = the global `window.world`), painted recursively via a broken-rectangles repaint
loop. Behaviour is verified by **SystemTests**: macros drive the live world and compare canvas
screenshots by **raw-pixel SHA-256** against committed references (SWCanvas software backend,
deterministic). So any layout change that shifts pixels forces a deliberate reference recapture.

### What "soft wrap" is
A `SimplePlainTextWdgt` (an editable plain-text widget that fits its box to its text) placed
inside a scroll panel can be toggled between two layout modes via a right-click menu item:
- **soft wrap ON** — the text wraps to the viewport width; no horizontal scrolling.
- **soft wrap OFF ("code view")** — the text keeps its natural un-wrapped width and the panel
  scrolls horizontally.
The toggle is `softWrapOn`/`softWrapOff` on `SimplePlainTextWdgt` (menu items in its
`addWidgetSpecificMenuEntries`, shown only when `@amIDirectlyInsideScrollPanelWdgt()`).

---

## 2. The current code (verbatim — line numbers approximate; the tree shifts)

### `SimplePlainTextWdgt.coffee` (the toggle)
```coffee
  softWrapOn:  -> @setSoftWrap true        # ~:108
  softWrapOff: -> @setSoftWrap false       # ~:109

  setSoftWrap: (wrap) ->                    # ~:117 (now preceded by a WHY-immediate comment, §13)
    return if @parent.parent.isTextLineWrapping == wrap   # idempotence guard
    @softWrap = wrap
    @parent.parent.setTextLineWrapping wrap
    @reLayout() unless wrap
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()
```
Topology when these run: `ScrollPanelWdgt` (`@parent.parent`, owns `isTextLineWrapping`) →
content `PanelWdgt` (`@parent`, == the scroll panel's `@contents`) → the `SimplePlainTextWdgt`
(`@`). Guaranteed by `@amIDirectlyInsideScrollPanelWdgt()`.

### `ScrollPanelWdgt.coffee` (the panel's wrap setter — added in Phase-7 "7c")
```coffee
  setTextLineWrapping: (wraps) ->          # ~:714 (now preceded by a WHY-immediate comment, §13)
    @isTextLineWrapping = wraps
    if wraps
      @contents.fullRawMoveTo @position()  # <-- the load-bearing IMMEDIATE bit:
      @contents.rawSetExtent @extent()     #     force the content to the viewport size
```
`isTextLineWrapping` default + field: `ScrollPanelWdgt.coffee:6` (`isTextLineWrapping: false`);
also set in ctors of `SimplePlainTextScrollPanelWdgt:28`, `SimplePlainTextPanelWdgt:23`,
`SimpleVerticalStackScrollPanelWdgt:3`. (The unused `toggleTextLineWrapping` was DELETED — §13.)

### `Widget.coffee` (the shared tail both directions call)
```coffee
  refreshScrollPanelWdgtOrVerticalStackIfIamInIt: ->   # ~:1483
    if @amIDirectlyInsideScrollPanelWdgt()
      @parent.parent.adjustContentsBounds()
      @parent.parent.adjustScrollBars()
    @parent?.childGeometryChanged?()
```

### `TextWdgt.coffee` (why the two directions differ — the width source)
```coffee
  reLayout: ->                             # ~:394  (only acts when @fittingSpec == FIT_BOX_TO_TEXT)
    if @softWrap
      … = @breakTextIntoLines @text, @originallySetFontSize, @extent()   # wrap to CURRENT extent
      width = @width()                                                    # keep current width
    else
      veryWideExtent = new Point 10000000, 10000000
      … = @breakTextIntoLines @text, @originallySetFontSize, veryWideExtent  # DON'T wrap
      width = @widthOfPossiblyCroppedText                                 # grow to NATURAL width
    height = @wrappedLines.length * Math.ceil @fontHeight @originallySetFontSize
    @silentRawSetExtent new Point width, height
    @changed()
```
Note `TextWdgt` also overrides `rawSetExtent` (~`:426`): `super; if FIT_BOX_TO_TEXT then @reLayout()`.
This is the hook by which the deferred cycle (`doLayout → rawSetBounds → rawSetExtent`) would re-wrap
a dirty text widget — see §0 point 3.

---

## 3. The framework's two-tier geometry API + the deferred cycle (the mechanism we want to use)

Fizzygum already encodes the deferred pattern as **two tiers of geometry API** on `Widget`:

- **IMMEDIATE / low-level** — `rawSetExtent` (`Widget.coffee:1397`), `fullRawMoveTo`,
  `silentRawSetExtent`, `rawSetWidth/Height`. Change geometry *right now*. The code's own
  comment (`:1398`): *"in theory the low-level APIs should only be in the 'recalculateLayouts'
  phase."* `rawSetExtent` ends by calling `@changed()` + `@reLayout()` synchronously.
- **DEFERRED / high-level** — `setExtent` (`Widget.coffee:1420`), `fullMoveTo`, etc. Body: sets
  `@desiredExtent` + calls `@invalidateLayout()`. **Guard (`:1423`): returns early unless
  `@layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING`.** NOTE (corrected): the scroll panel's content
  panel IS freefloating, so this guard would NOT block it — see §0.

- **`invalidateLayout`** (`Widget.coffee:3571`):
  ```coffee
  invalidateLayout: ->
    if @layoutIsValid
      world.widgetsThatMaybeChangedLayout.push @     # enqueue in the world's dirty list
    @layoutIsValid = false                            # mark dirty
    if @layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING and @parent?
      @parent.invalidateLayout()                      # propagate up — BUT NOT past a freefloating widget
  ```
- **The cycle** — `WorldWdgt.recalculateLayouts` (`WorldWdgt.coffee:841`) tail-drains the dirty
  widgets (`layoutIsValid == false`), climbs to the topmost-still-invalid ancestor, and calls
  `doLayout()` on it. It runs **once per `doOneCycle`** (`WorldWdgt.coffee:1221-1223`,
  method `doOneCycle` `:1198`), wrapped by `window.recalculatingLayouts = true/false`.
- `Widget.layoutIsValid` default `true` (`:234`). Base `Widget.reLayout` is a NO-OP (`:2273`);
  subclasses override (`TextWdgt:394`, etc.).

So the intended deferred flow is: a state change calls `invalidateLayout()` → the next
`doOneCycle` runs `recalculateLayouts` → `doLayout()` re-derives geometry from the final state,
**once**. The catch for soft-wrap is that this flow never reaches `adjustContentsBounds` (§0).

---

## 4. Why soft-wrap is a smell

`setSoftWrap` runs in a **menu-click handler** (outside the `recalculatingLayouts` phase) and
does **immediate** layout work: `rawSetExtent`/`fullRawMoveTo` on the content + an explicit
`reLayout` + `adjustContentsBounds`/`adjustScrollBars`. That contradicts the framework's stated
intent ("low-level APIs should only be in the recalculate phase") and bypasses the deferred
cycle. The "ideal" shape would be: set the `isTextLineWrapping` flag, `invalidateLayout()`, and
let the cycle's `doLayout` produce the geometry. (Why that's blocked today: §0.)

---

## 5. Investigation (verified facts — start here, do not re-derive)

### 5a. The ON/OFF asymmetry is intentional, and *why*
From `TextWdgt::reLayout` (§2): with `@softWrap` it wraps to the box's **current extent**;
without, it measures the **natural un-wrapped width**. Therefore:
- **wrap OFF** is self-contained: `@reLayout()` alone grows the box to its natural width (panel
  then scrolls horizontally).
- **wrap ON** can't just `@reLayout()` — that would wrap to the *current* (possibly wide) width and
  change nothing visible. The box must first be **re-constrained to the viewport width**; that's the
  `@contents.rawSetExtent @extent()` in `setTextLineWrapping(true)`.

### 5b. `adjustContentsBounds` ALREADY derives most of the wrap geometry — but not all
`ScrollPanelWdgt.adjustContentsBounds` (`:266`) contains, when
`@isTextLineWrapping and @contents instanceof PanelWdgt`, for each `FIT_BOX_TO_TEXT` child:
```coffee
  widget.softWrap = true
  widget.rawSetWidth @contents.width() - totalPadding   # constrain text width to the CONTENT width
  @contents.rawSetHeight (Math.max widget.height(), @height()) - totalPadding
```
So it already: (1) reasserts `softWrap=true`, (2) constrains the text width to `@contents.width()`,
(3) sets the content height. **What it does NOT do:** set `@contents.width()` to the *scroll-panel*
(viewport) width (it only READS `@contents.width()` here, and grows `@contents` to `@width()` only as
a minimum FLOOR via `growBy`). That single missing step — "content width := viewport width when
wrapping" — is exactly what `setTextLineWrapping(true)` does explicitly via `@contents.rawSetExtent`.
The re-entrancy guard `_adjustingContentsBounds` (`:268`/reset `:349`) brackets the method.

### 5c. ~~Blocker #1 — `setExtent` is FREEFLOATING-only~~ — CORRECTED: NOT a blocker
The original plan said you couldn't swap `@contents.rawSetExtent` → `@contents.setExtent` because
`setExtent` is freefloating-only and the content panel is layout-managed. **This is wrong.** The
content `PanelWdgt` IS `ATTACHEDAS_FREEFLOATING` (verified — §0). The freefloating gate would pass.
The real reason the code uses the raw API is that `setExtent` is **deferred**: the toggle wants the
geometry applied *synchronously* so its immediate `adjustContentsBounds` wraps correctly in the same
turn. (And, because the content is freefloating, a deferred `invalidateLayout` wouldn't reach the
panel at all — 5d/§0.)

### 5d. Blocker #2 (CONFIRMED, and the real one) — the wrap geometry is NOT on the cycle
`ScrollPanelWdgt` defines no `doLayout`. No `doLayout` in the codebase calls `adjustContentsBounds`.
The content/text are freefloating, so `invalidateLayout` on them does not climb to the panel
(`Widget:3575`). Even a forced-dirty panel skips the inline `adjustContentsBounds` because
`ScrollPanelWdgt.rawSetExtent` is guarded `unless aPoint.equals @extent()` and a toggle doesn't change
the viewport. **So merely calling `invalidateLayout()` re-lays-out the text alone and never re-derives
the panel's wrap geometry.** Connecting the two is a real layout-engine change with the §0 hazards.

---

## 6. What a FUTURE deferred conversion must solve (the revisit checklist)

The ideal end state is unchanged: `softWrapOn/Off` set `isTextLineWrapping` (+ the text's `@softWrap`)
and call `invalidateLayout()`; the layout cycle re-derives everything. To get there, ALL of these must
be solved *together* (solving any subset leaves it broken or non-deterministic):

1. **Move `content.width := viewport.width` into the layout pipeline** (out of
   `setTextLineWrapping(true)`'s `@contents.rawSetExtent @extent()`), e.g. into
   `adjustContentsBounds` gated on `@isTextLineWrapping`, BEFORE the per-child `rawSetWidth`. (Locally
   plausible; but `adjustContentsBounds` runs from ~42 sites, so prove byte-exactness across the whole
   reflow family, not just soft-wrap.)
2. **Make the cycle reach `adjustContentsBounds` for a wrap toggle WITHOUT flipping
   `implementsDeferredLayout` globally.** A naive `ScrollPanelWdgt.doLayout` trips the
   `Widget:990` nested-scroll merged-bounds change (§0). Needs a seam that connects the panel's wrap
   recompute to the dirty-drain without changing `@doLayout != Widget::doLayout` for all scroll panels
   — or a deliberate, separately-verified acceptance of that ripple.
3. **Reproduce the OFF / natural-width path in the cycle.** Today OFF works via the synchronous
   `@reLayout()` while `@softWrap == false`. Deferred, it must come from
   `doLayout → rawSetBounds → TextWdgt::rawSetExtent → reLayout` reading the final `@softWrap`.
4. **Eliminate the `softWrap`-overwrite ordering hazard** (`adjustContentsBounds:289` writes
   `widget.softWrap = true`). The final `@softWrap` + wrapped width must be a pure function of the
   toggle regardless of dirty-queue interleaving: a *single authority* computes wrap geometry once per
   cycle with fixed child ordering, and `TextWdgt.doLayout` must not independently re-wrap a wrapping
   scroll-panel child. This is the determinism-critical piece (DETERMINISM.md), and the reason this
   amounts to redrawing the wrap-ownership seam between `TextWdgt`, the content `PanelWdgt`, and
   `ScrollPanelWdgt` — i.e. the Phase-6 Tier-4 territory.

If a future session finds a seam that satisfies all four without the global ripple, the payoff is the
consistency win in §0; until then, the immediate shape is correct and intentional.

---

## 7. Open questions — now RESOLVED

1. **Content panel `layoutSpec`?** → `LayoutSpec.ATTACHEDAS_FREEFLOATING` (verified). Corrects 5c.
2. **Does `recalculateLayouts → doLayout` reach `adjustContentsBounds` for a scroll panel?** → **NO**
   (verified: no `doLayout` calls it; scroll panel has none; the inline edge in `rawSetExtent` is
   skipped for an unchanged viewport). This is the real blocker (5d/§0).
3. **Where does OFF sizing happen in the cycle if `setSoftWrap` didn't call `@reLayout()`?** →
   `doLayout → rawSetBounds → TextWdgt::rawSetExtent → reLayout` (the `TextWdgt` override ~`:426`),
   but with the ordering hazard of §6.4.
4. **Re-entrancy** — `adjustContentsBounds` guards with `_adjustingContentsBounds` (`:268`); routing it
   through the cycle creates a `doLayout ↔ adjustContentsBounds ↔ rawSet*` cluster whose guard
   interaction must be proven not to skip the first (correctness-bearing) pass.
5. **`childGeometryChanged` + `adjustScrollBars`** — the refresh tail also calls these; a deferred path
   must still update the scrollbars and notify the parent stack.
6. **Other `isTextLineWrapping` writers** — the three ctors set it at construction (before the first
   cycle); confirmed they still produce correct initial geometry.

---

## 8. Touch-list (file:line — verify lines, the tree shifts; lines drifted slightly after §13 edits)

- `Fizzygum/src/SimplePlainTextWdgt.coffee` — `softWrapOn/Off`, `setSoftWrap`.
- `Fizzygum/src/basic-widgets/ScrollPanelWdgt.coffee` — `setTextLineWrapping`, `adjustContentsBounds`
  (`:266`), `isTextLineWrapping` field (`:6`), `rawSetExtent` (`:221`, the viewport-guard).
- `Fizzygum/src/basic-widgets/Widget.coffee` — `refreshScrollPanelWdgtOrVerticalStackIfIamInIt`,
  `rawSetExtent` (`:1397`), `setExtent` + guard (`:1420`/`:1423`), `invalidateLayout` (`:3571`, upward
  gate `:3575`), `implementsDeferredLayout` (~`:3756`), `subWidgetsMergedFullBounds` (~`:990`),
  `layoutIsValid` (`:234`), `amIDirectlyInsideScrollPanelWdgt`, base `reLayout` (`:2273`),
  `addRaw` default freefloating (~`:2227`).
- `Fizzygum/src/basic-widgets/TextWdgt.coffee` — `reLayout` (`:394`), `rawSetExtent` override (~`:426`).
- `Fizzygum/src/WorldWdgt.coffee` — `recalculateLayouts` (`:841`), cycle invocation (`:1221-1223`,
  `doOneCycle` `:1198`), `widgetsThatMaybeChangedLayout` (declared `:255`).

---

## 9. Risk, ROI, and the honest framing

- **Risk: MEDIUM–HIGH, `[DET]`.** Render/layout code photographed by ~41 wrap-touching SystemTests
  (§10). Going immediate→deferred changes *when* layout computes and can shift pixels or, at
  dpr2-under-load, expose the §6.4 ordering bug. dpr2 + WebKit are MANDATORY; re-read DETERMINISM.md.
- **ROI: marginal.** Soft-wrap is a discrete, rare user action — no batching benefit. The win is
  *consistency* + removing a raw mutation from a click handler. It ships nothing user-facing.
- **Overlaps Phase-6 Tier 4 (= LEAVE).** Same DET-core area, no clean determinism-safe seam.
- **Verdict 2026-06-18: deferred for now (not never).** Do not force a risky re-architecture for a
  marginal consistency gain. Revisit if/when a seam satisfying all of §6 appears (e.g. during a
  broader layout-engine pass that already touches `doLayout`/`adjustContentsBounds`).

---

## 10. Test classification (soft-wrap / wrapping-scroll-panel exposure)

~41 SystemTests touch wrap-related terms (12 directly mention `SoftWrap`). Directly about the toggle /
wrap-mode reflow (watch these closest): `macroSoftWrapping`, `macroSoftWrapTogglesTextReflow`,
`macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent`,
`macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved`,
`macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo`,
`macroNonWrappingTextResizesToContent`, `macroFreeWidthScrollStackShowsHorizontalScrollbar`,
`macroWrappingTextFieldResizesOK`, `macroTextRelayoutsCorrectlyOnResize`. Broader (same pipeline): the
`macroSimpleDocument*` family, `macroWindowWithPlainWrappingTextResizingFollowsContentSize`,
`macroBareTextWdgt*Reflows*`, `macroVerticalStackPanelGrowsWithContent`,
`macroResizingScrollFrameThenImmediatelyScrollingTheHandlesDontStickToScrollPanelContent`.

---

## 11. Verification recipe + definition of done (if/when this is revisited)

Per-change verification (from the campaign):
1. `cd Fizzygum && ./build_it_please.sh` (the build runs the CoffeeScript syntax gate).
2. **Separate cd** → `cd Fizzygum-tests && node scripts/run-all-headless.js --shards=5` (dpr1),
   then `--dpr=2 --shards=5`, then `--browser=webkit --shards=5`. Expect 165/165.
3. The `--homepage` 3-step, as THREE separate `cd` commands (chaining build+smoke across the two repos
   → MODULE_NOT_FOUND): (a) `cd Fizzygum && ./build_it_please.sh --homepage`;
   (b) `cd Fizzygum-tests && node scripts/smoke-boot-headless.js --native-only`;
   (c) `cd Fizzygum && ./build_it_please.sh` (restore).
4. If pixels legitimately shift, recapture deliberately and CONFIRM the new references are correct:
   `cd Fizzygum-tests && node scripts/capture-macro-test-references.js SystemTest_<name> --clean --dprs=1,2`.

**Done (for the eventual conversion) when:** soft-wrap marks via `invalidateLayout()` and the cycle
derives the geometry, with §6.1–§6.4 all solved; 165/165 across dpr1 + dpr2 + WebKit + `--homepage`
boot (recaptures justified as faithful); and a `scripts/torture-headless.js` pass over the soft-wrap
tests shows no dpr2-under-load nondeterminism.

---

## 12. Context: what shipped before this (so the toggle code makes sense)

Phase-7 item **7c** (Fizzygum commit `9d3e1234`): moved the grandparent write +
content-resize into `ScrollPanelWdgt.setTextLineWrapping` (encapsulation); unified `softWrapOn/Off`
into `setSoftWrap(wrap)` (ON/OFF asymmetry made explicit); added the `setSoftWrap` idempotence guard.
All byte-identical / behaviour-preserving. THIS plan was the *next* step (immediate→deferred), assessed
2026-06-18 as deferred-for-now (§0).

---

## 13. What this assessment session changed (2026-06-18) — byte-exact cleanups

While assessing, two tiny safe wins were taken (provably pixel-free — no recapture):
1. **Deleted the dead `ScrollPanelWdgt.toggleTextLineWrapping`** (zero call sites; already inside the
   homepage-exclusion markers; not serialized geometry). It was a misleading second "wrapping" entry
   point that — unlike `setTextLineWrapping` — did NOT do the viewport resize.
2. **Upgraded the WHY comments** on `ScrollPanelWdgt.setTextLineWrapping` and
   `SimplePlainTextWdgt.setSoftWrap` to record that the immediate shape is deliberate FOR NOW and to
   point here for the obstacle map.

No behavioural change; the architecture decision is "deferred for now, revisit-able" per §0.
