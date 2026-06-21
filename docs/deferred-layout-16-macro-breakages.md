# The 16 macro breakages under the deferred geometry API — catalogue & root-cause map

> **STATUS: HISTORICAL.** These 16 construction macros broke when the public geometry API first became deferred and
> were RESOLVED by the self-settling API (`817c2ce4` + tests `a256ccfe6`) — they are now a green regression guard, not
> an open issue. The aim, the current model + mechanism, and what's next are in
> [`deferred-layout-OVERVIEW.md`](deferred-layout-OVERVIEW.md) (the self-contained entry point). Kept as the
> breakage-class catalogue + root-cause map.

**Companion to `softwrap-deferred-layout-conversion-plan.md` and `deferred-layout-path-a-design.md`.**
Written 2026-06-19.

## RESOLUTION — the self-settling public geometry API (2026-06-19)

All 16 are FIXED — but **not** by either option weighed in this doc (macro-discipline settles vs
pending-aware framework readers). A cleaner third approach shipped: the public geometry setters now
**self-settle**. `setExtent` / `fullMoveTo` / `setBounds` / `setWidth` / `setHeight` record their
desired change and then run `recalculateLayouts()` before returning (`Widget.mutateGeometryThenSettle`),
so a top-level caller (macro, app, event handler) always sees a consistent world — no manual
"settle"/yield — and the read-backs that caused M1–M4 can no longer observe stale geometry.

**Flow-soundness layering it rests on:** the public setters are the *only* thing that flushes; INTERNAL
layout (`doLayout` / `reLayout` / `desktopReLayout` / `raw*` / `silent*` / `adjustContentsBounds`) must
use the **raw** setters, never the public ones (else a setter reached during a flush re-enters
`recalculateLayouts`). Enforced two ways:
- **runtime (hard throw):** `mutateGeometryThenSettle` throws if a public setter is reached while a flush
  or layout pass is in progress (`world._inLayoutMutation` / `_recalculatingLayouts`).
- **build-time (static lint):** `buildSystem/check-layering.js` (wired into `build_it_please.sh`) fails
  the build on a low-level method (`raw*`/`silent*`/`__*`/`*Core`/`*Layout`/`adjustContents*`/
  `adjustScrollBars`) calling a public setter or `recalculateLayouts`, on `recalculateLayouts` called
  outside `doOneCycle`/the flush, or on public→public.

**Internal→public sites converted to raw to satisfy this (byte-safe — freefloating targets, matching
the adjacent `fullRawMoveTo`):** 5 `doLayout` (`AxisWdgt`, `FanoutWdgt`, `GenericObjectIconWdgt`,
`GenericShortcutIconWdgt`, `WidgetHolderWithCaptionWdgt`), 5 `reLayout` (`StretchableEditableWdgt`,
`PatchProgrammingWdgt`, `DashboardsWdgt`, `SimpleSlideWdgt`, `ReconfigurablePaintWdgt`), 2
`desktopReLayout` (`WorldWdgt`).

**Verified:** lint 0 violations; suite 165/165 (dpr1); all 12 desktop apps launch clean **under the
hard-throw build** via the new `Fizzygum-tests/scripts/smoke-apps-headless.js`. The 16 acceptance macros
below are now on the deferred API and pass.

**Known residual:** the hard throw can still fire on an untested *interaction* (a drag/menu inside an
app) that reaches a private→public in a method the lint doesn't recognize by name — convert-as-found.

**Step 1 — DONE (2026-06-19, Fizzygum-tests).** Macros no longer call ANY scroll-panel re-fit method
(`adjustContentsBounds` / `adjustScrollBars` / `refitContentsAndScrollBars`). It turned out **no
framework change was needed**: the self-settling deferred API already re-fits an enclosing scroll panel
when a freefloating child's `setExtent`/`fullMoveTo` settles — `doLayout` applies the change via
`fullRawMoveTo` (→ `fullRawMoveBy`) and `rawSetExtent`, both of which carry the auto-refit hook
`if @amIDirectlyInsideNonTextWrappingScrollPanelWdgt() then @parent.parent.adjustContentsBounds();
@parent.parent.adjustScrollBars()` — so the explicit macro calls were simply redundant. 7 macros,
test-only (+3/−22), byte-identical at dpr1 / dpr2 / WebKit. **Caveat (pre-existing):** that hook is
GATED to a widget *directly* inside a *non-text-wrapping* scroll panel (see the `Widget.coffee:1160`
comment — "this whole mechanism should go away with proper layouts"); a deeper-nested child would not
auto-refit. The 7 macros all use direct children, so they're covered; closing the gap generally is part
of the full deferred-layout migration.

**Privates-hygiene backlog (owner-requested 2026-06-19).** The notification + auto-refit hooks grew
organically and want a consistent treatment — to be sequenced into the migration:
1. **Reorg + privatize the hooks.** `childGeometryChanged`, `reactToDropOf` / `reactToGrabOf`,
   `reLayOutAfterContainedPanelChange`, `refreshScrollPanelWdgtOrVerticalStackIfIamInIt`,
   `childAdded` / `childRemoved` / `grandChild*`, `amIDirectlyInside*` follow different conventions and
   invocation paths — unify them onto one standard and make them all private.
2. **`refitContentsAndScrollBars` + `adjustContentsBounds` + `adjustScrollBars` are private too.**
3. **Register all of the above in the layering lint** (`buildSystem/check-layering.js`) as private/low-level.
4. **Extend the lint to scan the macro test sources** (`Fizzygum-tests/tests/**/*_automationCommands.js`)
   so a macro can no longer call a private method (this gate would have caught the original 16-macro mess).
5. **Adopt a consistent private-naming scheme** (leading `_`) and apply it during the reorg — this
   subsumes the standalone `_`-rename weighed earlier (deferred *into* this arc, not done alone).

**Step 2 (pending):** deliberately decide the public-mutator surface (`add` / `hide` / `show`); run the
full dpr2/WebKit/torture gauntlet before further commits.

---

*(Original analysis below — the per-test breakage map stays accurate; its "recommended approach" /
"which mechanism" framing is superseded by the resolution above.)*

## What this is

When the SystemTest macros are converted from the immediate (`rawSetExtent` / `fullRawMoveTo` /
`rawSetWidth`) geometry API to the **deferred** API (`setExtent` / `fullMoveTo` / `setWidth`), **16
macros break** (every other macro converts byte-identically). This document catalogues those 16: what
each test is about, a link to its `visualisation.html`, the exact snippet where the conversion bites,
and why it fails.

It is the concrete, evidence-backed version of the audit the Path-A design doc calls for. Use it to
decide the per-case fix.

### How it was produced (so the evidence is reproducible)

1. Framework left at HEAD (the Path-A `effective*` experiment reverted — it regressed the inspector
   canaries and is *not* the right primary tool; see "Why not just convert the framework readers" below).
2. All 21 still-raw macros converted to the deferred API. **5 convert cleanly and pass byte-identical**
   (`macroClockInWindowKeepsSquareOnResize`, `macroConstrainingStackForcesDroppedWidgetsToFullWidth`,
   `macroDuplicateComplexWidgetRidesHand`, `macroShiftClickExtendsSelection`,
   `macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved` — they were simply missed by the
   original conversion pass and have no read-back). The remaining **16 fail** — they are this catalogue.
3. Per-image pass/fail captured with `node scripts/run-macro-test-headless.js SystemTest_<name>`
   (and `--dump-failures` to inspect the divergent pixels). Failure here is **deterministic** (SWCanvas +
   the event queue are byte-exact), so each red image pinpoints a real read-back, not a flake.

## The headline finding

**Every one of the 16 fails for the same underlying reason, in four shapes.** The macro builds a parent
widget with the **deferred** API, then does something that *depends on that geometry already being
applied* — **before the settle** (`recalculateLayouts → doLayout`, which runs once per cycle just before
paint). With the old raw API the geometry applied *immediately*, so the dependent step saw the final
value; with the deferred API it sees the **stale, pre-settle** value.

The four shapes (mechanisms **M1–M4**):

| | Mechanism | Where it bites | Tests | Count |
|---|---|---|---|---|
| **M1** | **Macro reads back stale geometry** — the macro reads a just-deferred widget's geometry, or calls `adjustContentsBounds()`/`adjustScrollBars()` explicitly, *before* a `yield` settle. | the macro source | Attach, CompositeDrags, DocumentScrolls, NoSpuriousScrollbars, SimpleDocAddIndented | 5 |
| **M2** | **Nested children mis-placed under a pending parent** — children added to / positioned within a parent whose deferred *move* hasn't settled get the parent's settle-move applied **on top of** their own position (double-counted), so they land shifted by ~the parent's move delta. | framework (settle moves the subtree) + macro ordering | HideUnhide, HierarchyMenuHover, MenuFromFramedItem, PanelInPanel, EmbeddedDuplicate | 5 |
| **M3** | **Scroll-panel / document content sizing reads the container's pending extent** — `ScrollPanelWdgt.adjustContentsBounds` (auto-triggered by add / scroll) reads the panel's own stale `@width()/@height()` while its deferred `setExtent` is pending, so the contents are fit to the wrong size. | `ScrollPanelWdgt.adjustContentsBounds` | EditingString, NestedScrollPanels, ScrollPanelCaret, ScrollPanelCoalesces | 4 |
| **M4** | **Slider thumb positioned from the slider's stale position** — `SliderButtonWdgt.reLayout` places the thumb at `(posX,posY).add @parent.position()`; on `add` (`iHaveBeenAddedTo`) the slider's deferred move is still pending, so the thumb reads a stale parent origin, and a pure *move* never re-lays-out the thumb afterwards. | `SliderButtonWdgt.coffee:68` (`@parent.position()`) | CompositeShadow, Sliders | 2 |

Several tests carry a secondary mechanism too (noted per entry) — e.g. a ScrollPanel test that *also*
nests a composite.

### The universal, byte-identical fix (macro-authoring discipline)

All four shapes share one cure: **settle the widget before anything depends on its geometry** — i.e.
insert `yield "waitNoInputsOngoing"` after a parent's deferred `setExtent`/`fullMoveTo` and *before*
reading it back, adding/positioning children into it, or calling `adjustContentsBounds()`. This
reproduces the raw behaviour **byte-for-byte** (raw applied immediately; an early settle applies the
deferred value at the same logical point) and touches **only test code — zero framework risk**.
Where a read-back is a literal expression (`panel.right() - 30`), substituting the explicit constant is
equally valid (and avoids the extra cycle), but loses the macro's resilience to fixture edits.

### Why not just convert the framework readers (the design doc's §3/§4 Path A)?

Tried in this iteration: making `ScrollPanelWdgt.adjustContentsBounds` read pending-aware `effective*`
geometry. It **regressed two inspector canaries** (`macroDuplicatedInspectorDrivesCopiedTargetOnly`,
`macroSimpleDocumentHandlesOldInspector`) — leaking pending geometry into an applied-needer path — while
fixing only **1 of the 16** (`EditingString`). So the framework-reader route is both riskier and
narrower than the macro-discipline route. It remains the *only* option for any read-back that genuinely
can't be settled (none of these 16 is in that class — all are construction-time and settle-fixable), and
M3/M4 in particular would each need a careful, canary-checked, per-reader change if pursued.

---

## The catalogue (grouped by mechanism)

Visualisation links are relative to this file (`Fizzygum/docs/`).

### M1 — macro reads back stale geometry

#### 1. macroAttachTargetExcludesClippedWidget — *2/2 images fail*
- **About:** a child whose raw bounds stick out past a clipping panel's edge is *unreachable* as an
  "attach"/"set target" candidate where it's clipped away (clip gates the candidate walk).
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroAttachTargetExcludesClippedWidget/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroAttachTargetExcludesClippedWidget/visualisation.html)
- **Where it bit:** `rect.fullMoveTo new Point (panel.right() - 30), 165` (and `panel.right() + 20` /
  `panel.right() + 12` for the later probes), each right after deferred `panel.setExtent` + `panel.fullMoveTo`.
- **Why:** `panel.right()` reads the panel's **applied** bounds, but the panel's move/resize is still
  pending → returns the stale (default) right edge, so `rect`/probe land in the wrong place.

#### 2. macroCompositeDragsAsUnitIntoScrollPanel — *16/16 images fail*
- **About:** a composite (boxes parented under one box) drags as a single unit in and out of a scroll
  panel, grabbed by any of its members.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroCompositeDragsAsUnitIntoScrollPanel/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroCompositeDragsAsUnitIntoScrollPanel/visualisation.html)
- **Where it bit:** `panel.adjustContentsBounds()` + `panel.adjustScrollBars()` called *explicitly* right
  after deferred `panel.setExtent new Point 350, 230` (before the first `yield`). Secondary **M2**: the
  red/green/blue composite is nested (`red.add green`, `red.add blue`) under a pending `red`.
- **Why:** `adjustScrollBars`/`adjustContentsBounds` read the panel's stale `@width()/@height()` → the
  scroll panel and its bars are mis-sized from image_1, so *every* subsequent drag shot is off.

#### 3. macroDocumentScrollsMixedTextAndClocks — *6/6 images fail*
- **About:** a SimpleDocument scroll panel flows/clips/scrolls mixed content (text paragraphs interleaved
  with analog clocks of different sizes; oversized clocks clamp to the column and clip).
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroDocumentScrollsMixedTextAndClocks/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroDocumentScrollsMixedTextAndClocks/visualisation.html)
- **Where it bit:** `doc.adjustContentsBounds()` + `doc.adjustScrollBars()` after deferred
  `doc.setExtent new Point 250, 300` (and again after the later `doc.setExtent new Point 900, 400`).
  Secondary **M3** (the clocks are sized inside the still-pending document).
- **Why:** the explicit content-sizing reads the document's stale extent → content laid out to the wrong
  column width/height.

#### 4. macroNoSpuriousScrollbarsOnScrollPanelResize — *1/3 images fail (image_1 only; 2 & 3 pass)*
- **About:** a scroll panel holding one always-fitting box must never show a spurious scrollbar as it is
  moved/resized.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroNoSpuriousScrollbarsOnScrollPanelResize/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroNoSpuriousScrollbarsOnScrollPanelResize/visualisation.html)
- **Where it bit:** `box.fullMoveTo new Point (panel.center().x - 25), (panel.center().y - 20)` plus the
  explicit `panel. , all before the first `yield`.
- **Why:** `panel.center()` reads the stale (pre-settle) panel centre → the box is mis-centred in
  image_1. Images 2–3 pass because the subsequent real drag/resize re-place the box correctly — proof
  this is purely a construction-time read-back.

#### 5. macroSimpleDocumentCanAddIndentedParagraph — *3/4 images fail (image_1 PASSES; 2–4 fail)*
- **About:** narrowing a document paragraph's "base width" via its menu re-flows it; the shipped default
  paragraph is the target.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroSimpleDocumentCanAddIndentedParagraph/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroSimpleDocumentCanAddIndentedParagraph/visualisation.html)
- **Where it bit:** `target.layoutSpecDetails.rememberInitialDimensions target, doc.contents` (and
  `doc.contents.adjustContentsBounds()`) right after deferred `doc.setExtent new Point 360, 330`.
- **Why:** `rememberInitialDimensions` records the target's in-stack width from `doc.contents`'s **stale**
  width (the document's resize is pending) → the wrong "initial width" is banked, so the later
  proportional base-width calc is off. **image_1 (construction) passes** — the corruption only shows once
  the remembered dimension is *used* by the menu-driven base-width change (images 2–4).

### M2 — nested children mis-placed under a pending parent

> Confirmed visually (`macroHierarchyMenuHoverHighlightsExactSubtree` image_1): the top-level panel
> settles correctly, but the nested box + rectangle are shifted down-right by ~the panel's move delta.
> The settle moves the parent's whole subtree, and the child's own deferred position is applied too —
> double-counting the offset. (Differential proof: `macroHideUnhideWidgetChain` image_2, the parent box
> *alone*, passes; image_1 with the nested chain fails.) **Fix:** settle the parent before adding /
> positioning children.

#### 6. macroHideUnhideWidgetChain — *2/3 images fail (image_2 passes)*
- **About:** a 3-box re-parented chain (box1▷box2▷box3); hiding the middle box hides its whole subtree;
  show() restores it (image_1 ≡ image_3).
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroHideUnhideWidgetChain/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroHideUnhideWidgetChain/visualisation.html)
- **Where it bit:** `box1.fullMoveTo(110,90)` deferred; then `box1.add box2` / `box2.add box3` with
  `box2.fullMoveTo(190,150)` / `box3.fullMoveTo(270,210)`.
- **Why:** box2/box3 land shifted by box1's pending-move delta. image_2 (box1 alone, subtree hidden)
  passes → the parent itself is fine; only the nested children are wrong.

#### 7. macroHierarchyMenuHoverHighlightsExactSubtree — *5/5 images fail*
- **About:** right-clicking the deepest of a panel▷box▷rect nest opens the ancestor hierarchy menu;
  hovering an item highlights exactly that widget's subtree.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroHierarchyMenuHoverHighlightsExactSubtree/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroHierarchyMenuHoverHighlightsExactSubtree/visualisation.html)
- **Where it bit:** `panel.fullMoveTo(40,30)` deferred; then `panel.add box` (`box.fullMoveTo(70,55)`),
  `box.add rect` (`rect.fullMoveTo(95,75)`).
- **Why:** box + rect shifted by the panel's move delta (confirmed visually). Every shot includes the
  mis-placed nest, so all 5 fail.

#### 8. macroMenuFromFramedItemNotClipped — *2/2 images fail*
- **About:** a context menu popped from an item inside a clipping frame is a world-level popup, so it is
  *not* clipped by the frame.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroMenuFromFramedItemNotClipped/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroMenuFromFramedItemNotClipped/visualisation.html)
- **Where it bit:** `frame.fullMoveTo(170,90)` deferred; then `frame.add clippedChild` /
  `frame.add innerItem` with their `fullMoveTo`s.
- **Why:** the clipped child + inner item land shifted by the frame's move delta → the clip geometry and
  the items render in the wrong place.

#### 9. macroPanelInPanelTransparencyAndStroke — *2/2 images fail*
- **About:** a panel crops its children to its bounds and re-paints its stroke on top; a child panel +
  box straddle the outer edge (cropped); making the outer translucent does not cascade alpha to children.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroPanelInPanelTransparencyAndStroke/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroPanelInPanelTransparencyAndStroke/visualisation.html)
- **Where it bit:** `outer.fullMoveTo(95,80)` deferred; then `outer.add inner` / `outer.add box` with
  their `fullMoveTo`s.
- **Why:** inner panel + box shifted by the outer's move delta → the crop-at-edge geometry is wrong.

#### 10. macroEmbeddedDuplicateButtonReduplicates — *4/4 images fail*
- **About:** a panel's context-menu "duplicate" item is dropped *into* the panel as an embedded,
  self-replicating duplicate button.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroEmbeddedDuplicateButtonReduplicates/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroEmbeddedDuplicateButtonReduplicates/visualisation.html)
- **Where it bit:** `panel.fullMoveTo(40,40)` deferred; then `panel.add heart` followed by
  `heart.fullMoveTo(150,95)`.
- **Why:** the heart icon lands shifted by the panel's move delta in the fixture shot, and the
  subsequent duplicate-into-panel positions inherit the error.

### M3 — scroll-panel / document content sizing reads the container's pending extent

> The one mechanism the reverted `effective*` experiment *did* fix (it made
> `ScrollPanelWdgt.adjustContentsBounds` read the container's pending extent) — at the cost of regressing
> the inspector canaries. A settle after the panel's `setExtent` is the byte-identical alternative.

#### 11. macroEditingStringInScrollablePanelCaretAlwaysVisible — *4/4 images fail*
- **About:** editing a wide string inside a scroll panel keeps the caret in view, auto-scrolling
  horizontally as it walks past the right edge.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroEditingStringInScrollablePanelCaretAlwaysVisible/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroEditingStringInScrollablePanelCaretAlwaysVisible/visualisation.html)
- **Where it bit:** `panel.setExtent new Point 300, 140` deferred; `adjustContentsBounds` (auto-triggered
  by `panel.add str` / scrolling) then reads the panel's stale `@width()/@height()`.
- **Why:** contents fit to the stale viewport size → the scrollable extent and caret-follow geometry are
  wrong. (Confirmed: making `adjustContentsBounds` pending-aware fixed exactly this test.)

#### 12. macroNestedScrollPanelsRouteWheel — *3/3 images fail*
- **About:** nested scroll panels route the wheel to the innermost scrollable, escalating to the outer
  once the inner is at its limit.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroNestedScrollPanelsRouteWheel/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroNestedScrollPanelsRouteWheel/visualisation.html)
- **Where it bit:** `outer.setExtent new Point 300, 300` deferred; the inner `ListWdgt` + paragraphs are
  flowed into the still-pending outer (content sizing reads the stale extent).
- **Why:** the document's content/overflow geometry (and thus both scrollbars' travel) is computed from
  the stale outer size.

#### 13. macroScrollPanelCaretBroughtIntoViewWhenMoved — *4/4 images fail*
- **About:** the vertical companion to #11 — moving the caret scrolls the panel back up to reveal a caret
  that had scrolled out of view.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroScrollPanelCaretBroughtIntoViewWhenMoved/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroScrollPanelCaretBroughtIntoViewWhenMoved/visualisation.html)
- **Where it bit:** `panel.setExtent new Point 360, 180` deferred; `str` + tall `rect` added → content
  sizing reads the stale extent. Secondary **M2** (str/rect under the pending panel).
- **Why:** the scrollable extent / vertical scrollbar is sized from the stale viewport.

#### 14. macroScrollPanelCoalescesChildMenu — *2/2 images fail*
- **About:** a SimplePlainText scroll panel coalesces its child's context menu into the panel's own menu
  (vs a plain panel, which builds a hierarchy menu).
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroScrollPanelCoalescesChildMenu/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroScrollPanelCoalescesChildMenu/visualisation.html)
- **Where it bit:** `panel.setExtent new Point 300, 150` deferred; the auto-built inner text blurb is
  sized against the stale panel extent. Secondary **M2** (the contrast `plainPanel`'s rect).
- **Why:** the coalescing panel's text/content geometry is laid out to the stale size.

### M4 — slider thumb positioned from the slider's stale position

> `SliderButtonWdgt.reLayout` (`SliderButtonWdgt.coffee:68`) does
> `@silentFullRawMoveTo new Point(posX, posY).add @parent.position()`. On `add`/`iHaveBeenAddedTo` the
> slider's deferred move is pending, so `@parent.position()` is stale; a pure *move* (no extent change)
> never re-triggers the thumb's `reLayout`, so the thumb stays at the stale origin. **Fix:** settle the
> slider before adding it (so its origin is applied before the thumb lays out), or a targeted framework
> change (thumb reads `@parent.effectivePosition()`, or a move re-lays-out the thumb).

#### 15. macroCompositeWidgetsHaveCorrectShadow — *2/2 images fail*
- **About:** a composite (rectangle/box + attached slider) casts ONE drop-shadow shaped like the whole
  subtree silhouette; re-parenting the slider removes its own shadow.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroCompositeWidgetsHaveCorrectShadow/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroCompositeWidgetsHaveCorrectShadow/visualisation.html)
- **Where it bit:** `sliderA.fullMoveTo(155,125)` then `rect.add sliderA` (and `sliderB` / `box.add
  sliderB`) — the slider is deferred-moved, then added.
- **Why:** the slider thumb lays out against the slider's stale origin → the thumb (and hence the
  composite silhouette and its shadow) is in the wrong place.

#### 16. macroSlidersControlTextWidget — *3/3 images fail*
- **About:** three sliders wired to a text widget's font-size / alpha / content drive it live; the panel
  is then duplicated.
- **Visualisation:** [`../../Fizzygum-tests/tests/SystemTest_macroSlidersControlTextWidget/visualisation.html`](../../Fizzygum-tests/tests/SystemTest_macroSlidersControlTextWidget/visualisation.html)
- **Where it bit:** `fontSlider.fullMoveTo(92,104)` / `alphaSlider.fullMoveTo(150,104)` /
  `textSlider.fullMoveTo(185,104)`, each followed by `leftPanel.add <slider>`. (Note: the macro itself
  uses only absolute coords — no macro-side read-back; the read-back is entirely framework-internal.)
- **Why:** each slider's thumb lays out against the slider's stale origin while its deferred move is
  pending → all three thumbs render mis-placed.

---

## Cross-reference

- The 5 cleanly-converted "bonus" macros are listed under "How it was produced" above — they are pure
  cleanup wins (no read-back) and can be banked independent of the 16.
- `deferred-layout-path-a-design.md` §7 lists these same 16 as the Path-A acceptance set, and the
  canaries (`macroSierpinskiInCanvas`, `macroDuplicatedInspectorDrivesCopiedTargetOnly`,
  `macroScrollBarsTrackContentChange`) that must not regress. This catalogue refines that doc's
  assumption: the dominant fix is **macro-authoring discipline (M1/M2/M3/M4 all settle-fixable)**, not the
  framework-reader conversion the design doc led with.
