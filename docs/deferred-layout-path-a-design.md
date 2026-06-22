# Deferred-layout Path A — the per-reader design (why "pending-aware accessors" fails, what to do instead)

> **STATUS: HISTORICAL — Path A is FALSIFIED, do NOT revive.** Path A ("pending-aware accessors": add `effective*`
> reads that return where geometry is HEADING) is incorrect for the container path — `_positionAndResizeChildren` bakes
> via the non-invalidating `silentRawSetBounds`, so a pending read bakes a mid-settle transient (§11 has the
> instrumented proof: scroll content over-sized 43px). The deferred-layout effort instead uses the **deferred
> re-queue** + **Path-B de-read-back** (see [`deferred-layout-OVERVIEW.md`](deferred-layout-OVERVIEW.md) §3/§6, the
> self-contained entry point). Kept for the why-it-fails record (§11) and the pending-vs-applied reader taxonomy.

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
*after a deferred set but before the `recalculateLayouts → _reLayout` settle* sees the stale APPLIED
`@bounds`, not the just-requested value. The originating concrete target is the **16 SystemTest macros**
that still use raw because they read geometry back synchronously during scene construction (see §7).

After the settle, `@desired*` is cleared and applied == requested, so **the entire concern is the
intra-cycle in-flight window**; rendering (which runs after the settle) is never affected.

> **RECONCILED 2026-06-20 — the 16 macros are already GREEN (this changes Path A's framing, not its
> design).** When this doc was written the 16 still used raw. They were subsequently converted to the
> deferred API and made green by the **self-settling public geometry API** (Fizzygum `817c2ce4` / tests
> `a256ccfe6`) — each public setter self-flushes, so a *top-level* (macro) caller sees the applied value
> on the next line. So Path A no longer needs to flip the 16 red→green; they are its **green regression
> guard**. Path A's *remaining* value is the harder case the self-settling API does NOT cover: an
> **in-pass** reader (a container re-fitting during one settle, a batched builder, or a future framework
> handler that mutates-then-reads in a single synchronous pass) still sees stale `@bounds`. Making the
> audited container-sizing path read PENDING in-pass is the prerequisite for removing the synchronous
> re-fit seam (C2/C3). Today that conversion is **byte-identical groundwork** (the convergence loop
> already reaches the same final pixels); its load-bearing verification arrives with the seam removal.

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
to compute a derived layout from where things are going. (The names below are the post-Phase-2
privatized `_positionAndResizeChildren`; **AUDIT-REFINED 2026-06-20** — the original "all overrides" claim was
too broad, the per-override reality is annotated:)
- `_positionAndResizeChildren` overrides — **only the SCROLL PANEL reads pending.** `ScrollPanelWdgt._positionAndResizeChildren`
  (`:317`) sizes itself to `@contents.subWidgetsMergedFullBounds()` (it REACTS to content extent) → pending.
  `WindowWdgt._positionAndResizeChildren` reads `@contents.width()` (`:442`) as a freshly-added content's
  preferred width (one pending candidate); its `@contents.height()` reads are *after* a raw width re-fit →
  applied. `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` **DRIVES** its children (sizes via raw
  `rawSetWidthSizeHeightAccordingly`, positions via raw `fullRawMoveTo`, reads `widget.height()` only
  *after* the raw size) → its child reads are already applied → **NOT a pending-needer.**
- `Widget.subWidgetsMergedFullBounds` (`:1067`): reads `child.bounds` / `child.fullBounds()` to merge child
  extents → the core pending-needer (used by the scroll panel above). Convert via an **opt-in pending
  variant** (`effectiveSubWidgetsMergedFullBounds`), not by mutating the base method (it has an
  applied-needer caller, `ContainerMixin.adjustBounds`).
- `Widget.add` → `rememberFractionalPositionInHoldingPanel` → `positionFractionalInWidget` /
  `positionPixelsInWidget`: reads the child's `@position()` at add-time (the `@ == world` arm only).
  Convert via an **opt-in** add-time effective read; do NOT change the shared
  `positionFractionalInWidget`/`positionPixelsInWidget` (general-purpose, applied-needers).
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

**Acceptance — now a GREEN REGRESSION GUARD (already converted, tests `a256ccfe6`; must STAY green):**
the 16 macros (formerly "keep raw", now on the deferred API) —
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

**One sanctioned-benign exception to "canaries must not regress":** `macroDuplicatedInspectorDrivesCopiedTargetOnly`
inspects a `RectangleWdgt` with inherited methods shown, so ADDING the `effective*` methods to `Widget`
(step 1, define-only) grows its member list → a scrollbar-thumb-proportion shift in `image_2`/`image_3`
(member *text* byte-identical). This is the exact mechanism + precedent of the C0 seam recapture (tests
`544166856`) and is recaptured as a benign member-list growth — NOT a semantic regression (a define-only
method cannot leak a pending value into the inspector's applied read). Distinguish the two by pixel-diff:
benign = only the thumb region differs; a real leak would change the inspected geometry/visualisation.

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
3. ~~Apply the macro-authoring discipline (§6) … convert those 16 macros~~ — **DONE** (tests `a256ccfe6`,
   via the self-settling API, not Path A). The §6 discipline + the macro list remain as reference for any
   *future* macro that reads geometry mid-construction.
4. After steps 1–2, re-run §8: the 16 (now green) + the canaries must HOLD; the only expected pixel change
   is the §7 sanctioned-benign inspector recapture. A mis-classified reader fails deterministically and
   pinpoints itself.
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

## 11. RESULT 2026-06-20 — the container content-sizing conversion (step 2) is NOT byte-safe (REVERTED)

The `effective*` reads (§4/§10) were added to `Widget` (`effectivePosition`/`effectiveExtent`/
`effectiveBoundingBox`/`effectiveFullBounds`/`effectiveSubWidgetsMergedFullBounds`) and verified additive
(suite green; the only delta was the §7 sanctioned inspector recapture — see the note below). Then the
**container content-sizing conversion was attempted and REVERTED** because it is **not byte-safe**:

- Routing `ScrollPanelWdgt._positionAndResizeChildren`'s `@contents.subWidgetsMergedFullBounds()` →
  `effectiveSubWidgetsMergedFullBounds()` (and `WindowWdgt._positionAndResizeChildren`'s `@contents.width()`
  → `effectiveExtent().x`) changed the **settled scrollbar thumb** in **2 tests** —
  `macroNestedScrollPanelsRouteWheel` (all 3 images) and `macroSimpleDocumentHandlesOldInspector`
  (image_2/3). The outer thumb became **shorter** (content sized **larger**) though the *visible* content
  was pixel-identical — i.e. only the panel's internal content-size bookkeeping diverged.
- Refining the merge to keep the original's **applied-viewport** semantic for *deferred-layout* children
  (the nested-scroll case — the `child.bounds` branch + ScrollPanelWdgt's `implementsDeferredLayout:false`
  pin) fixed one image, but the **non-deferred** branch (`effectiveFullBounds`) still diverged → reverted.

**Root cause / the load-bearing insight.** `_positionAndResizeChildren` **BAKES** its computed content size via
`@contents.silentRawSetBounds` (a *non-invalidating raw* set). The applied read is correct because the
**synchronous re-fit is RE-TRIGGERED** as each child applies its `@desired*` (the inline
`_reFitContainerAfterRawGeometryChange` seam fires on a child's raw geometry change), so a *later* re-fit
re-reads the children's **final applied** geometry and bakes the converged size. A **pending** read bakes
where children are *heading*, but a child's pending extent is frequently **further adjusted during its own
settle** (a deferred-layout child's viewport is driven by *this* container; a soft-wrapping text child's
height changes on reflow), so **pending ≠ final-applied**, and the baked transient persists (the silent
set doesn't re-invalidate). **Therefore the synchronous re-fit + convergence loop is LOAD-BEARING
precisely because it re-reads APPLIED geometry after children settle.** Path A's premise — *pending-aware
reads let a container converge in one deferred pass, making the seam (C2/C3) removable* — **does not hold
for the scroll-panel content path**: the convergence is doing real fixed-point work that one pending read
does not replicate, so the seam cannot be removed merely by making the container read pending.

**The correctness verdict (instrumented 2026-06-20 — the pending read is WRONG, not merely different).**
A probe hooked `compareScreenshots` to log, per screenshot, the outer `SimpleDocumentScrollPanelWdgt`'s
baked `@contents.height()` vs the true settled `@contents.subWidgetsMergedFullBounds().height()` vs the
viewport, with `correctH = max(trueMerged + 2·padding, viewport)`:

| build | baked `contentsH` | `trueMergedH` | `correctH` | **slack** |
|---|---|---|---|---|
| reference (applied read) | 325 | 315 | 325 | **0 ✓** |
| pending-read conversion | 368 → 333 (after scroll) | 315 | 325 | **+43 → +8 ✗** |

The reference sizes the content **exactly** to its true bounds (slack 0). The pending read **over-sizes
by 43px** — it bakes a mid-construction transient (the content's pending extent *before* its own settle
shrank it) into `@contents` via the non-invalidating `silentRawSetBounds`, leaving phantom empty scroll
space that the synchronous convergence loop (which re-reads APPLIED geometry after children settle) would
otherwise correct. So the conversion is not just non-byte-safe, it is **incorrect**; reverting (not
recapturing) was right. This is hard confirmation that the synchronous re-fit/convergence is load-bearing,
and that a future seam removal must converge the re-fit on a *fixed point* of pending geometry, never bake
a single pending read into a silent set. NEXT-STEP implication: a real seam removal (C2/C3) must make the container re-fit
**converge on pending without baking a non-final transient** (e.g. re-fit on the cycle reading pending
*and* re-running until the pending-derived size is a fixed point), or keep the applied-read convergence —
not a single pending read into a silent set. This reframes the C2 wall.

> **[RESOLVED 2026-06-21 — this paragraph called it right.** The seam was NOT removed and NOT made to read pending; it
> was **converted to DEFER via the `recalculateLayouts` re-queue** — it enqueues the container into the until-loop,
> which re-fits it on the **applied-read convergence loop** (exactly the "keep the applied-read convergence" option
> argued here). C2 is therefore NOT a wall — only the *naive no-op* removal was. Shipped `5fc152c7`/`7303fc5d`/
> `1caea690`/`1e5d3745`; see `deferred-layout-OVERVIEW.md` §3 + `deferred-layout-c2-execution-plan.md`.]**

**Inspector recapture footnote (the §7 benign case turned out non-vacuous).** Adding the `effective*`
methods grew `macroDuplicatedInspectorDrivesCopiedTargetOnly`'s inherited-method list and shifted its
`editInspectorAlpha` scroll-to-row math — which revealed the committed reference was **vacuously passing**
(neither inspector's alpha edit applied; both rects stayed opaque, contradicting the test's own "left
faded" comment). The longer list happens to land the 'alpha' row in the clickable pane, so the edits now
apply and the rects fade as intended. Per owner decision (2026-06-20) the references were **recaptured to
the corrected state** (not the test hardened — its scroll-into-view stays fragile to list-length changes;
hardening deferred). This recapture's fate is tied to whether the `effective*` methods are kept (see the
landing decision).
