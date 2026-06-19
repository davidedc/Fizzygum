# Deferred-layout Path A — the per-reader design (why "pending-aware accessors" fails, what to do instead)

**Companion to `docs/softwrap-deferred-layout-conversion-plan.md`.** That doc establishes the model
(deferral is within-frame; accessors read applied `@bounds`; handler raw geometry is a *symptom* of the
half-built model) and names **Path A** as "make the geometry accessors pending-aware." This doc records
that the *blanket* form of that idea was implemented and **empirically diverges**, explains why, and
specifies the **per-reader** design that actually works. Written 2026-06-19 after the experiment.

---

## 1. What Path A must achieve

Let macros (and, eventually, framework handlers) set geometry through the **deferred** API
(`setExtent`/`fullMoveTo`/`setWidth`/`setBounds`) instead of the immediate `raw*` API, and still get
**byte-identical** results. The blocker is in-cycle **read-back**: code that reads a widget's geometry
*after a deferred set but before the `recalculateLayouts → doLayout` settle* sees the stale APPLIED
`@bounds`, not the just-requested value. The originating concrete target is the **16 SystemTest macros**
that still use raw because they read geometry back synchronously during scene construction (see §7).

After the settle, `@desired*` is cleared and applied == requested, so **the entire concern is the
intra-cycle in-flight window**; rendering (which runs after the settle) is never affected.

## 2. Why the blanket "pending-aware accessors" approach DIVERGES (empirical, 2026-06-19)

The experiment: add `effectiveBounds()` = (`@desiredPosition ? @bounds.origin`, `@desiredExtent ?
@bounds.extent()`), route **every** geometry accessor (`position`/`extent`/`left`/`top`/`right`/`bottom`/
`center`/`boundingBox`/…) through it, make `subWidgetsMergedFullBounds` + `fullBounds`/`SLOWfullBounds`
pending-aware, and invalidate the `fullBounds` cache from `invalidateLayout`. Then re-convert the 16 and
run the suite.

Result — **it did not converge**: failures went **16 → 17 → 18** as more read paths were made
pending-aware. Each step fixed some container-sizing cases but regressed others. Net WORSE, and three
*previously-passing* tests regressed (`macroSierpinskiInCanvas`, `macroDuplicatedInspectorDrivesCopiedTargetOnly`,
`macroScrollBarsTrackContentChange`).

**Root cause:** the geometry read surface has **conflicting** semantic needs. The *same* accessor
(`extent()`, `position()`, …) is called both by readers that want **where the widget is heading**
(pending) and by readers that want **where the widget actually is right now** (applied). A single
accessor cannot satisfy both; making it pending-aware fixes the first group and breaks the second. This
is why a blanket change is structurally unable to converge — it is not a matter of covering "more" read
paths.

## 3. The core distinction: pending-needers vs applied-needers

**PENDING-needers** (want `@desired*` when set) — all are *intra-cycle, pre-settle* reads whose job is
to compute a derived layout from where things are going:
- `Widget.adjustContentsBounds` (and the `PanelWdgt` / `ScrollPanelWdgt` / `SimpleVerticalStackPanelWdgt`
  overrides): container content-sizing reads `@contents` + each child's `width/height/left/top/boundingBox`.
- `Widget.subWidgetsMergedFullBounds`: reads `child.bounds` / `child.fullBounds()` to merge child extents.
- `Widget.add` → `rememberFractionalPositionInHoldingPanel` → `positionFractionalInWidget` /
  `positionPixelsInWidget`: reads the child's `@position()` at add-time.
- **Macro-side construction reads** (in test code, NOT framework): e.g.
  `box.fullMoveTo (panel.center()...)` — `panel.center()` must reflect the panel's just-requested extent.

**APPLIED-needers** (must keep reading `@bounds`, never pending) — reads that describe the *actual*
current pixels/buffer/region:
- **Dirty-rect repaint**: `changed()` / `fullChanged()` / `clippedThroughBounds()` /
  `SLOWfullClippedBounds` compute the on-screen region to invalidate. They MUST dirty where the widget
  actually is (old region), or moves leave stale pixels.
- **`CanvasWdgt` pixel-buffer sizing** (the `macroSierpinskiInCanvas` regression): the backing bitmap is
  allocated/drawn at the APPLIED extent; a pending extent mis-sizes the buffer.
- **The inspector** (the `macroDuplicatedInspectorDrivesCopiedTargetOnly` regression): duplication /
  geometry snapshotting reads the actual current bounds.
- **Scrollbar tracking** (the `macroScrollBarsTrackContentChange` regression).
- **Hit-testing / spatial queries during a drag**: today drags use `raw*`, so `@desired*` is nil and the
  distinction is moot — but any future deferred drag (the Path-A *transport* case) must be designed so
  hit-testing reads the right thing (its own sub-problem; keep it out of this first pass).

Note the base accessors are read in *thousands* of places; the applied-needers are the silent majority.
That is why **APPLIED must stay the default** and PENDING must be opt-in per audited reader.

## 4. The design

**Keep the base accessors APPLIED-only** (`position`/`extent`/`left`/`top`/`right`/`bottom`/`center`/
`width`/`height`/`boundingBox`/`fullBounds` continue to read `@bounds`, exactly as today). Do NOT make
them pending-aware.

**Add explicit pending-aware reads** and call them ONLY from audited pending-needers:
- `effectivePosition()` → `@desiredPosition ? @bounds.origin`
- `effectiveExtent()` → `@desiredExtent ? @bounds.extent()`
- `effectiveBoundingBox()` → a `Rectangle` from the two above (the helper from the experiment; see §10)
- a pending-aware merged-bounds for containers (a variant of `subWidgetsMergedFullBounds` that merges
  children's `effectiveBoundingBox()` / pending `fullBounds`).

Then **convert each pending-needer** (§3 list) to read the `effective*` forms. Because these are opt-in,
the applied-needers are untouched and cannot regress.

**`fullBounds` caching:** if a container pending-needer needs a child's *pending full extent* (subtree
included), it needs a pending-aware fullBounds. Provide an **uncached** `effectiveFullBounds()` rather
than making the cached `fullBounds` pending-aware — the cache is invalidated by `breakNumberOf...Caches`
on raw changes but NOT by deferred sets, and making the cached path pending-aware forces cache-busting in
`invalidateLayout` (hot path) plus keeping `SLOWfullBounds` in lock-step for the `doubleCheck`. An
uncached `effectiveFullBounds()` used only intra-cycle by the audited readers sidesteps all of that.

## 5. The reader audit (the unit of work)

This is the bulk of Path A and must be exhaustive:
1. Enumerate every geometry read on the in-flight path. Grep the accessor names **and** direct `.bounds`
   field reads across `src/` (not just the accessor definitions — many readers bypass accessors, e.g.
   `subWidgetsMergedFullBounds` does `child.bounds`).
2. For each, decide: is it ever reached **between a deferred set and the settle**, and does it want
   PENDING (where it's heading) or APPLIED (where it is)? Default to APPLIED unless it is provably a
   layout-derivation reader.
3. Convert only the PENDING-needers to `effective*`. Leave everything else.
4. Re-run the acceptance + canary suite (§7) after each small batch — the failure mode is deterministic
   (§8), so a wrong classification turns a test red immediately and pinpoints the reader.

Start with the **container path** (`adjustContentsBounds`, `subWidgetsMergedFullBounds`, `add`'s
fractional read) — that is what the 16 acceptance macros exercise. Defer the **hand/grab transport**
case (deferred drags) to a later pass with the `torture-headless` soak.

## 6. Macro-authoring discipline (the in-construction reads)

Some of the 16 read geometry **in the macro itself** mid-construction (e.g.
`box.fullMoveTo (panel.center()...)`, then `panel.adjustContentsBounds()` before any `yield`). These are
test code, not framework, so the framework `effective*` reads don't cover them. Two acceptable fixes,
per macro:
- **Use explicit coordinates** instead of reading a sibling's just-set geometry (the macro already knows
  the numbers it requested), or
- **Insert a settle** (`yield "waitNoInputsOngoing"`) between the construction and the read, so the
  geometry is applied before it is read.

Prefer explicit coordinates (no extra cycle, no behavioural shift). Document this as a macro-authoring
rule in `src/macros/MACRO-PATTERNS.md`: *do not read a widget's geometry between a deferred set and the
next settle.*

## 7. Acceptance tests & canaries

**Acceptance (must go GREEN once converted to deferred):** the 16 macros that today keep raw —
`macroAttachTargetExcludesClippedWidget`, `macroCompositeDragsAsUnitIntoScrollPanel`,
`macroCompositeWidgetsHaveCorrectShadow`, `macroDocumentScrollsMixedTextAndClocks`,
`macroEditingStringInScrollablePanelCaretAlwaysVisible`, `macroEmbeddedDuplicateButtonReduplicates`,
`macroHideUnhideWidgetChain`, `macroHierarchyMenuHoverHighlightsExactSubtree`,
`macroMenuFromFramedItemNotClipped`, `macroNestedScrollPanelsRouteWheel`,
`macroNoSpuriousScrollbarsOnScrollPanelResize`, `macroPanelInPanelTransparencyAndStroke`,
`macroScrollPanelCaretBroughtIntoViewWhenMoved`, `macroScrollPanelCoalescesChildMenu`,
`macroSimpleDocumentCanAddIndentedParagraph`, `macroSlidersControlTextWidget`.

**Canaries (must NOT regress — the applied-needers):** `macroSierpinskiInCanvas` (canvas buffer),
`macroDuplicatedInspectorDrivesCopiedTargetOnly` (inspector), `macroScrollBarsTrackContentChange`
(scrollbar). In the blanket experiment these three broke first — treat them as the early-warning that a
pending read leaked into an applied-needer.

## 8. Verification protocol

Each repo in a SEPARATE `cd` (chaining build+test across repos → MODULE_NOT_FOUND). Failure is
**deterministic** here (a mis-classified reader returns stale/early geometry and fails every run), so the
suite is a reliable oracle — no soak needed for the container path:
1. `cd Fizzygum && ./build_it_please.sh` (full build, recopies the converted tests).
2. `cd Fizzygum-tests && node scripts/run-all-headless.js --shards=5` (dpr1), then `--dpr=2 --shards=5`,
   then `--browser=webkit --shards=5`. Expect 165/165 with ZERO reference recaptures.
3. The **hand/grab transport** sub-pass (later) additionally needs `scripts/torture-headless.js` at dpr2
   over the drag/scroll tests (its risk IS cadence-sensitive, unlike the container path).

## 9. Sequencing

1. Add the `effective*` reads (§4) — additive, no behavioural change on their own.
2. Convert the **container path** pending-needers (`adjustContentsBounds`, `subWidgetsMergedFullBounds`/
   `effectiveFullBounds`, `add`'s fractional read).
3. Apply the **macro-authoring discipline** (§6) to the in-construction reads of the 16, then convert
   those 16 macros to the deferred API. Re-run §8.
4. Iterate the audit (§5) on any remaining red test until the 16 are green and the canaries hold.
5. (Separate, later) the deferred **hand/grab transport** case — its own design + torture soak.

## 10. Reference: the experiment's reusable helper

The pending-aware bounds helper from the experiment is correct and reusable as the basis for the
`effective*` reads (just don't route the *base* accessors through it):

```coffee
# pending-aware bounds: the desired (not-yet-applied) geometry if a deferred change is pending,
# else the applied @bounds. For use ONLY by audited intra-cycle pending-needers (§3), never by the
# base accessors or any applied-needer (rendering, buffers, dirty-rects).
effectiveBounds: ->
  if !@desiredPosition? and !@desiredExtent?
    return @bounds
  origin = @desiredPosition ? @bounds.origin
  ext    = @desiredExtent   ? @bounds.extent()
  new Rectangle origin.x, origin.y, origin.x + ext.x, origin.y + ext.y
```

The deferred clamp primitive **`fullMoveWithin`** (shipped 2026-06-19, `Widget.coffee`) is the deferred
twin of `fullRawMoveWithin` and is the clamp that the grab/spawn sites will use once their read-backs are
resolved (it already does its own pending-aware check, so it is correct independent of this design).
