# Plan — remove the GEOMETRY re-fit sub-seam (the last hard wall of the proper-layouts arc)

> **STATUS (2026-07-01) — ✅ ARC COMPLETE. The ENTIRE notify-by-mutation re-fit seam is DELETED (property + geometry),
> AND Stage 6 is DONE: the convergence cap is retired, the 3 phase flags assessed, the residual convergence pruned.**
> The PROPERTY sub-seam (`_announceLayoutPropertyChangeToContainer`) was DELETED (Fizzygum `c637ffb1`). The GEOMETRY
> sub-seam (`_announceGeometryChangeToContainer`) — which `docs/proper-layouts-4.4-ordered-downwalk-plan.md` §8
> declared *"effectively irreducible"* — is now ALSO fully DELETED: its OFF-pass half via the uniform dirty-tree
> (Stage 1, `65401c36`), and its IN-pass half via the settle loop's **ORDERED settle-time re-fit**
> (`_reFitMyTrackingContainerAfterSettle`, Stages 4–5 `c7d0a616` — re-fit a chain-top's tracking container AFTER it
> settles). The immediate mutators are now PURE geometry.
> **Stage 6 (2026-07-01, this session):** measurement FALSIFIED the "≤8 pure drain" premise — the loop is a drain of
> up to 428 DISTINCT widgets (0 re-visits) PLUS a small bounded size-negotiation (peak 10 re-visits). So (a) the
> silent convergence-suppression `recalcIterationsCap` is DELETED, replaced by a never-fire `layoutIterationsSanityLimit`
> loud-THROW assert (owner's choice; the loop is not provably acyclic); (b) the 3 phase flags all **STAY** — they are
> re-entrancy / batching guards, NOT convergence devices (the mandate's "all booleans go" theory conflated the two);
> (c) most residual re-visits were WASTED no-op re-fits → a **NO-OP EARLY RETURN** (skip the up-edge when the settled
> frame is unchanged) cut peak re-visits **10 → 2**, byte-exact. The last 2 = the inherent bidirectional negotiation;
> true single-pass = the known §4.2 pure-measure wall, NOT unlocked by the seam removal. See §5 Stage 6.
> **The §8 "irreducible" verdict was proven OVER-general THREE times (property, geom-off-pass, geom-in-pass).**
>
> **⚠ READ §0 BEFORE BELIEVING THAT VERDICT.** That §8 verdict was written when the two sub-seams were **fused**
> and studied as one. This session PROVED the fused "irreducible" framing wrong for half of it: with the right
> **decomposition + a small toolkit + persistence**, the property sub-seam — which §8 counted inside the same
> "irreducible" wall — fell completely (9 callers deleted, gauntlet + torture green). The geometry seam is genuinely
> harder, but it is **not** to be treated as closed. Work it in slices. Do **not** re-run the 8 already-falsified
> paths (§2) — start from the fresh angles (§4) with the proven techniques (§3).

---

## §0 — The spirit (READ FIRST): "deemed impossible" ≠ impossible

On 2026-06-29 a thorough feasibility session (`…-4.4-…-plan.md` §8) ran 8 distinct seam-deletion probes, all
falsified, and concluded the re-fit seam was an irreducible multi-widget dependency edge — STOP-and-bank. That
verdict was **correct about what it tested** and is worth deep respect: do not waste days re-deriving it.

But on 2026-07-01, prompted by the owner to "really try HARD … we are almost there … don't give up," a fresh
independent pass found the verdict had **over-generalised**:

1. **The seam is actually TWO sub-seams.** `_announceGeometryChangeToContainer` (fired by the *immediate geometry
   mutators*, IN-pass) and `_announceLayoutPropertyChangeToContainer` (fired by *layout-property setters*, OFF-pass).
   §8 studied them fused; the reverse-probe on the current tree breaks **21 tests** with both off, not §8's "10".
2. **The property half was fully removable.** Its 9 callers now route the freefloating-content→container dependency
   through the **uniform dirty-tree** (see §3.5 D1 + §3.6 bare-invalidate). The **last "irreducible" holdout**
   (a StringWdgt contained-text case that *stalled / did not converge*) was cracked by a one-line insight
   (bare-invalidate). What looked like a fundamental width↔height cycle was under-invalidation.
3. **The techniques generalise.** Reverse-probe → decompose → instrument-and-LOOK → forensic-classify → try the
   minimal principled change → byte-exact-gate. That loop, run with persistence, is what cracked it.

**Mandate for this plan:** the geometry seam is the harder half — but approach it the same way. Decompose it
further (§4.1), find the sub-slice that yields, ship byte-exact, repeat. "Stop if a stage can't be made
byte-exact" remains a *sanctioned resting point per stage* — but do **not** treat the whole seam as closed after
one or two failed stages. The property seam fell on roughly the third serious attempt of the session.

---

## §1 — What the geometry sub-seam IS (ground truth; grep the symbol, anchors vs `c637ffb1`)

**The seam method.** `Widget._announceGeometryChangeToContainer` (`src/basic-widgets/Widget.coffee:1662`):
```
_announceGeometryChangeToContainer: ->
  return if @isLayoutInert?()                                      # carets/handles excluded (isLayoutInert)
  @_reFitContainer @parent.parent if @_amIDirectlyInsideNonTextWrappingScrollPanelWdgt()   # :2848
  @_reFitContainer @parent
```
- **Fired by the NOTIFYING immediate geometry mutators:** `_commitExtentAndNotify` (`:1599`) and
  `_applyMoveByAndNotify` (`:1261`). (Contrast the *non-notifying* arrange twins `_applyExtent`/`_applyBounds`/
  `_applyMoveTo` built by §4.2 Stage 3 — a container arranging its own children uses those, so it does NOT fire the
  seam at itself. Only genuinely-external / self-applied-in-pass geometry fires it.)
- **Dispatch:** `_reFitContainer(container)` (`:1706`), gated on `container._reLayoutChildren?` (only Window / Stack /
  ScrollPanel react). Two states:
  - IN a pass (`world._recalculatingLayouts`): `container.__markForRelayout()` (`:3796` — bare push + mark invalid,
    **no climb**; legal mid-pass; this is the LIVE path for the immediate-mutator seam);
  - OFF a pass: `container._invalidateLayout()`.

**The load-bearing case (what makes it hard).** A freefloating content (a scroll panel's `@contents`, a window's
content) has its geometry **applied IN-PASS** — by its own `_reLayout`, reached as a *separate settle chain-top*
because the settle walk-up STOPS at a freefloating boundary (`WorldWdgt._recalculateLayoutsBody:937+`, the
`isFreeFloating() or parent.layoutIsValid` break). The size-tracking container must re-fit **after** that in-pass
application — which is exactly when the raw setter fires this seam. §8's instrumentation on
`SystemTest_macroNoSpuriousScrollbarsOnScrollPanelResize`: **341 in-pass seam fires vs 5 off-pass**; the content
box's position evolves over successive `_positionAndResizeChildren` calls, driven by `keepContentsInScrollPanelWdgt`
(`ScrollPanelWdgt.coffee:465`) moving the content, NOT by a one-shot `@desiredPosition`.

**The crux site — `ScrollPanelWdgt._positionAndResizeChildren` (`:345`):**
- content-SIZING panels (text-wrapping / `SimplePlainTextScrollPanelWdgt` / `SimpleVerticalStackScrollPanelWdgt`)
  measure the content frame from the §4.1 **pure** measure `subWidgetsMergedPreferredBounds` (`:399/:401`);
- free-positioned panels (folder / toolbar / menu) measure from the **applied** read-back
  `subWidgetsMergedFullBounds` (`:403`) merged with `@boundingBox()` (the `else` branch);
- the frame is then anchored at `@contents.left()`/`.top()` (`:431` — the "centered icon" line);
- `keepContentsInScrollPanelWdgt` (`:465`) clamps the content position AFTER the frame commit.
This creates a genuine **frame-size ↔ content-position** coupling that the settle loop iterates via the seam.

**Session-verified mechanism (LOOK, don't infer).** Instrumenting `_positionAndResizeChildren` (P2 trace) on
NoSpurious showed the transient wrong frame is driven by the content's child (a centered 50×40 box) being read at a
**stale absolute position** (box still at (0,0) while `@contents` had moved to (150,80)) → the frame computes to a
huge `(0,0 530×400)` → spurious H+V scrollbars; the next visit, after the box's position has caught up, re-fits to
the correct `(150,80 380×320)`. **The seam bridges a temporal inconsistency: the container reads child geometry
that a *different* settle visit is still applying.**

**The work-list.** §8: no-op'ing the (fused) seam broke exactly 10 tests = 7 scroll + 3 window/stack. §8's split of
those 10: **6 in-pass** (LockedScrollPanelScrolls, ScrollBarsTrackContentChange, ScrollPanelInWindowMovesWindow,
WindowWithAClock, WindowWithSimpleVerticalPanel, WindowsNestedCollapsing) + **4 off-pass**
(EditingStringInScrollablePanel, ScrollPanelCaretBroughtIntoView, NoSpuriousScrollbars,
ScrollPanelNotMovedViaNonFloatDrag). **RE-DERIVE this on the current tree first** (§3.1) — the property seam is now
gone, so the geometry-only break-list may have shifted.

---

## §2 — What is already FALSIFIED (do NOT re-tread these as-is)

From `…-4.4-…-plan.md` §8 (2026-06-29) + this session (2026-07-01). Each was a clean reverse-probe.

1. **Non-notifying conversion of the arrange** — DONE for the arrange (§4.2 Stage 3, capstone 18→0); the seam's
   remaining fires are genuinely-external / self-applied-in-pass, not arrange self-re-enqueues.
2. **Synchronous in-arrange fixpoint** (wrap `_positionAndResizeChildren` in a ≤16-iter loop) — NO-OP: the arrange
   is already idempotent (`C.out == C.in` at every settled state). There is no *single-container* convergence to
   iterate; the convergence is CROSS-widget.
3. **Analytic position↔frame decoupling** (owner-requested) — FALSIFIED as tested, *because its upper bound is #2*
   (a no-op). ⚠ BUT see §4.4: the probe wrapped the **existing** arrange; it never actually rewrote the `:431`
   `@contents.left()` anchor. The decoupling is not disproven as a *rewrite*, only as an *iteration*.
4. **Remove the `@contents.width()` measure read-back** (measure at the viewport width instead) — BYTE-EXACT but
   **marginal**: the seam-off reverse-probe still breaks all 10. Doesn't reduce the seam *alone*.
5. **Drop the `@boundingBox()` read-back** (unify free-positioned to the subBounds+viewport shape) — NOT byte-exact,
   **breaks 9** (folder/toolbar/menu/free-positioned content). It is LOAD-BEARING **because nothing replaced it**
   (see §4.2: build a pure positional measure as the replacement rather than dropping it).
6. **"The edge is the content's own `_reLayout`"** framing — WRONG; the load-bearing fire is the CONTAINER resizing
   its own content, `top=ScrollPanelWdgt`.
7. **Local off-pass freefloating-climb ("D1") to delete the geom seam** — the climb is byte-SAFE (165/165 with the
   seam intact — indeed this session made D1 PERMANENT for the property seam), but deleting the geom seam on top of
   it recovers **0 of the 10**: the off-pass climb fires at *scheduling* time, before the content's geometry is
   applied; the load-bearing notification is in-pass-**post-application**, and the FLOWRULE forbids in-pass
   `_invalidateLayout` (`Widget._invalidateLayout:3800` throws if `world._recalculatingLayouts`).
8. **Ordered-traversal content-first PRE-SETTLE proxy** (each container arrange post-order-settles its content's
   dirty descendants before measuring) — recovers **0**: the box position is driven by `keepContents` (a content
   MOVE), not a pending descendant `_reLayout`, so pre-settling descendants doesn't capture the size↔position
   fixpoint. ⚠ This is a **proxy** for §4.3, not §4.3 itself (see there).

**The through-line:** every falsified path either (a) tried to make a *single container's* arrange converge (it
already does), or (b) tried to deliver the notification *off-pass* (too early) or *by dropping* a read-back (nothing
replaces it). The seam delivers an **in-pass, post-application, cross-widget** signal. Beating it needs either the
signal delivered correctly in-order (§4.3/§4.4) or the read-back it stands in for made **pure** (§4.2).

---

## §3 — The proven toolkit (this is HOW the property seam fell — use all of it)

1. **Reverse-probe.** Gate the seam behind a runtime flag and no-op it, then run the suite; the break-list IS the
   work-list, and re-running it tells you if the tree changed. Pattern: add `return if window.SEAM_NOOP_GEOM` at the
   top of `_announceGeometryChangeToContainer`; build; run
   `AUDIT_PRELUDE=<prelude setting window.SEAM_NOOP_GEOM=true> node scripts/run-all-headless.js --shards=8 --dpr=1
   --speed=fastest`. (`run-all-headless.js` injects `AUDIT_PRELUDE` via `page.addInitScript`;
   `run-macro-test-headless.js` takes `PRELUDE_JS=<file>` + `LOG_FILE=<file>` for a single test.)
2. **Sub-seam / work-list decomposition.** Split the trigger set by timing (in-pass vs off-pass), by container class
   (scroll vs window vs stack), and by content kind (content-SIZING vs free-positioned). Attack the most tractable
   slice first and ship it; don't try to delete the whole seam in one move. (This is the single biggest lesson: the
   "irreducible" 10 are not one thing.)
3. **Instrument and LOOK — never trust the doc's reconstruction.** Wrap `_positionAndResizeChildren` (and/or
   `_reLayout`, `keepContentsInScrollPanelWdgt`) in a PRELUDE_JS to log per-call state (panel bounds, `@contents`
   bounds, `subWidgetsMergedFullBounds`, `@boundingBox()`, first-child abs pos, would-a-bar-show). The
   "idempotent vs 341-fires" contradiction in §8 was only resolved by seeing the *stale child position* in a trace.
   Classes are compiled in-browser, so install via a `requestAnimationFrame` poll until the prototype exists.
4. **Pixel forensics to classify a mismatch.** `scratch/forensics.py <obtained.png> <ref.png> [strip.png]` reports
   diff-pixel count, bbox, top channel deltas, and a symmetric-shift heuristic. Signatures: symmetric ± gray buckets
   = spatial SHIFT (layout/text moved); uniform positive gray overlay = colour-state; an EXTRA thin region = a
   scrollbar/border appearing. Dump the live divergent image with `run-macro-test-headless.js … --dump-failures`
   (writes to `.scratch/<test>/dpr<N>/`), then crop+`Read` the diff region to SEE it.
5. **Benign inspector-recapture recognition.** Inspector tests render Widget **method source** and **member lists**.
   Editing a method's body shifts the rendered source; deleting a method shifts the member list. Both are BENIGN —
   recapture (`node scripts/capture-macro-test-references.js <macroName> --dprs=1,2`, PRE-AUTHORISED), do not chase.
   In this session `InspectorResizingOKEvenWhenTakenApart` (source) and `DuplicatedInspectorDrivesCopiedTargetOnly`
   (member list) were both benign — verified by cropping the diff and seeing it was code text.
6. **The bare-vs-trigger `_invalidateLayout` distinction (KEY, the crack for the property holdout).**
   `@parent._invalidateLayout(@)` passes the child as `triggeringChild`, so the freefloating-skip
   (`Widget._invalidateLayout:3800`, `return if triggeringChild?.isFreeFloating() … unless @_reLayoutChildren? and
   not world._recalculatingLayouts`) can DROP it at a non-tracking intermediate parent → stale → non-converge.
   `@parent._invalidateLayout()` (BARE, no trigger) invalidates the container unconditionally, then climbs. When you
   want the container re-fit, prefer the bare form.
7. **The D1 climb-through (now PERMANENT, shipped).** `Widget._invalidateLayout` climbs THROUGH a freefloating
   boundary OFF-PASS when the parent is a size-tracking container (`@_reLayoutChildren?`). This is the uniform-dirty-
   tree channel that replaced the property seam. It is byte-safe and available to build on.
8. **Loop-dump / `RECALC_CAP` probe.** `WorldWdgt._recalculateLayoutsBody` cap is `recalcIterationsCap` (`:934`).
   To snapshot a non-convergence: temporarily gate it low (a `window.RECALC_CAP` hook), ring-buffer the chain-tops
   re-laid each iteration, and dump on bail. (Watch out: `console.error` may be dropped by the single-test log
   capture — write to `window.__X` and print it from a prelude rAF poll, or prefix `LAYOUTAUDIT` for AUDIT_DIR.)
9. **Byte-exact gating every step + the RIGHT verifier (§6).** The determinism-sensitive verifier is the **torture**
   (`RECALC_NONCONVERGENCE` must stay ABSENT) — any change to `_invalidateLayout` / the settle loop / an arrange is a
   convergence change and MUST be torture-checked, not just gauntlet-checked.

---

## §4 — Fresh angles / hypotheses (ordered by tractability; NONE of these is the falsified list in §2)

### §4.1 — Decompose the 10 and pick off the yielding slices FIRST (do this before anything ambitious)
The property seam fell because it was separated from the geom seam. Do the analogous split *within* the geom 10:
- **Re-derive the geom-only break-list** (§3.1) now that the property seam is gone.
- **Classify each broken test** by: (a) in-pass vs off-pass (§8 said 6/4 — re-confirm); (b) content-SIZING (uses the
  pure `subWidgetsMergedPreferredBounds`) vs free-positioned (uses applied `subWidgetsMergedFullBounds` +
  `@boundingBox()`); (c) container class (scroll / window / stack).
- **Hypothesis:** the 4 OFF-pass cases may be D1-climbable *exactly like the property seam was* — they fire off-pass,
  where the FLOWRULE (the §2#7 blocker) does not apply. Try routing just those through D1 + bare-invalidate and
  deleting only their trigger path. Even a 4/10 reduction is real progress and shrinks the wall.
- **Hypothesis:** the content-SIZING scroll panels already have a pure measure; their remaining seam dependence is
  the `:431` anchor + keepContents (§4.4), a *narrower* problem than the free-positioned `@boundingBox()` case.

### §4.2 — Build the PURE POSITIONAL measure that replaces `@boundingBox()` (attacks §2#5 at the root)
§2#5 failed only because dropping `@boundingBox()` left nothing behind. The container needs the content's children's
**merged bounds** (their union) to size the frame. For free-positioned content those positions are (mostly) fixed
and independent of the frame → a pure function. For layout-derived content (centered/stacked) the positions are a
pure function of the frame width (`subWidgetsMergedPreferredBounds` already re-derives stack positions this way,
`:1119`; verify it's byte-identical to the applied bounds at the fixpoint — §4.1 already proved this for stacks).
Extend it to a **`subWidgetsMergedPreferredFullBounds`** that predicts the APPLIED union for *every* content kind
(honouring elasticity/fill/min-extent exactly as the arrange applies it). If the frame is computed entirely from a
pure measure, it never reads applied child geometry → the in-pass post-application dependency dissolves → the seam's
fire has nothing to deliver. **Risk:** exactly predicting applied positions for arbitrary free-positioned content is
hard; but you only need it for the content kinds in the geom-10 work-list, not universally.

### §4.3 — The REAL ordered down-walk / two-flag (NOT the falsified pre-settle proxy)
§2#8 falsified a *proxy* (pre-settle descendants). The real thing (`…-4.4-…-plan.md` §4 Stages B/C, never
implemented) is:
- **Two-flag dirtiness:** add `hasDirtyDescendant` alongside `layoutIsValid` (`Widget.coffee:234`);
  `_invalidateLayout` flips `hasDirtyDescendant` up the chain (O(depth) mark, O(1) enqueue of dirty ROOTS only); the
  settle loop walks DOWN from roots. Byte-IDENTICAL as a pure bookkeeping change (same widgets re-laid, verify the
  work-list order matches) — land it standalone as scaffolding.
- **Encode the content→container SIZE edge as an ORDERING constraint:** when the loop would visit a size-tracking
  container, ensure its freefloating content's geometry is applied FIRST *in the same ordered traversal* (not as a
  separate chain-top). Then the container reads `@boundingBox()` when it is already valid → no deferred re-fit → the
  seam is unnecessary. The pre-settle proxy failed because it settled descendants but left the keepContents position
  loop; the real version must fold keepContents into the ordered visit too (see §4.4).
This is the assessment's "biggest + riskiest change." It is the endgame. Do §4.1/§4.2 first to shrink what it must
cover; the property-seam win says the "proxy failed ⇒ real thing impossible" inference is invalid — build the real
thing.

### §4.4 — Kill the frame-size ↔ content-position coupling by rewriting the `:431` anchor + keepContents
§2#3 (analytic decoupling) was falsified only as an *iteration* of the existing arrange; it never actually rewrote
the coupling. The coupling: frame anchored at `@contents.left()` (`:431`, to keep a centered icon centered) +
`keepContents` clamping `@contents.left()` after the commit (`:465`). Rewrite so **frame SIZE** = a pure function of
the content measure + viewport (no `@contents.left()` read), and **frame POSITION** = the preserved scroll offset,
clamped — with centering derived from the final frame width by the CONTENT's own arrange, not from the frame's
anchor. If the frame stops depending on the applied content position, keepContents moving the content no longer
feeds back → the loop is a true single pass → the seam's in-pass re-fit is unnecessary. **The centered-icon and
legitimately-scrolled cases are the byte-exactness hazards** — instrument and diff them specifically.

### §4.5 — Convert in-pass immediate mutation to desired-then-container-applies (make geom look like property)
The property seam fires off-pass because property changes go through the deferred `@desired*` + `_invalidateLayout`
tier. The geom seam fires in-pass because the content SELF-APPLIES its geometry immediately during its chain-top
`_reLayout`. If the content instead recorded a *desired* geometry and let its size-tracking container APPLY it
during the container's own visit (the §4.3 model), the notification becomes off-pass → D1-climbable → deletable by
the exact mechanism that killed the property seam. This is §4.3 viewed from the mutator side; the two meet in the
middle.

---

## §5 — Staging (each byte-exact, independently shippable, soak-gated; STOP-per-stage is fine, STOP-forever is not)

- **Stage 0 — ✅ DONE 2026-07-01.** Geom-only reverse-probe (dpr1) → break-list = **13 = 10 IN-pass ⊎ 3 OFF-pass**
  (disjoint; a per-arm split-probe — gating the in-pass vs off-pass fire separately inside the seam method —
  classified each empirically). IN-pass 10 = §8's original set (7 scroll + 3 window/stack). OFF-pass 3 =
  `SimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrapping` (STALLED = non-convergence), `WrappingTextFieldResizesOK`,
  `ScrollPanelUpdatesCorrectlyOnCollapsing…ClosingWindow`. **KEY:** the 4 tests §8 called "off-pass" now break on the
  **IN-pass** arm — the property-seam deletion already routed their off-pass dependence through D1; the geom seam's
  residual off-pass load is only these 3 text-wrap/collapse cases (much smaller/cleaner than §8 implied).
- **Stage 1 — ✅ DONE 2026-07-01 (OFF-PASS arm DELETED; seam now IN-PASS ONLY).** The off-pass 3 routed through the
  uniform dirty-tree via bare-invalidate at the semantic points: `SimplePlainTextWdgt` soft-wrap (`:154`, changed
  from the trigger-form `@parent._invalidateLayout(@)` — dropped at the non-tracking @contents PanelWdgt — to a BARE
  `@parent.parent._invalidateLayout()` reaching the scroll-panel grandparent; this ONE line fixed BOTH the soft-wrap
  case AND the 403-fire resize case) + `WindowWdgt` collapse/uncollapse (`:350`/`:363`, added
  `@parent.parent._invalidateLayout() if inside a scroll panel`). Off-pass reverse-probe: **3 → 0** (dropping the
  off-pass arm is byte-exact suite-wide). `_announceGeometryChangeToContainer` is now `return unless
  world?._recalculatingLayouts`; `_reFitContainer`'s off-pass arm is reached only by gesture/menu/attach callers.
  Byte-exact: **gauntlet dpr1/dpr2/webkit 165/165 + apps/tier/settle, 0 recaptures**; **20-min torture (dprs 1,2 ×
  fast,fastest × shards 1,2,4,8) RECALC_NONCONVERGENCE ABSENT, no nondeterminism**. **LESSON:** §4.1's optimism was
  RIGHT and the reconnaissance analysis ("resize has no semantic hook, can't be D1-cracked") was WRONG — the bare
  crack fixed the generic-resize case too. The §0 mandate (try the minimal change, don't conclude from analysis)
  earned its keep here. Possible future elegance (deferred, NOT needed for the win): fold the 3 per-site
  grandparent-reaches into a D1 generalization that climbs THROUGH a freefloating non-tracking intermediate
  (@contents PanelWdgt) to the tracking scroll-panel ancestor — riskier (broad climb change), so per-site shipped.
- **Stage 2 — the pure positional measure (§4.2), landed incrementally.** Build `subWidgetsMergedPreferredFullBounds`
  for the content kinds in the work-list; switch `_positionAndResizeChildren` to it for those; prove byte-exact with
  the seam ON, then check how many break-list tests it lets the seam-off probe recover.
  - **SESSION FINDINGS 2026-07-01 (classification + §4.4 probe done; IN-PASS CORE = CHARACTERIZED WALL, not yet cracked):**
    Instrumented the in-pass seam + ran the 10. They split **6 scroll ⊎ 4 window** by re-fit target:
    (scroll) LockedScrollPanelScrolls, ScrollBarsTrackContentChange, ScrollPanelNotMovedViaNonFloatDrag,
    NoSpuriousScrollbars (**92 in-pass re-fits in one run** = the content-frame↔scroll-position convergence),
    EditingStringInScrollablePanel, ScrollPanelCaretBroughtIntoView — dominant edge `@contents PanelWdgt → ScrollPanelWdgt`;
    (window) ScrollPanelInWindowMovesWindow, WindowWithAClock (**1212+748+… fires**), WindowWithSimpleVerticalPanel,
    WindowsNestedCollapsing — re-fit target `WindowWdgt._reLayoutChildren` (a **SEPARATE mechanism** from the ScrollPanel crux).
    ROOT of the scroll staleness: base `subWidgetsMergedPreferredBounds` (Widget.coffee:1130) uses **pure sizes but APPLIED
    child positions** `child.left()/top()`; a **centered free-positioned icon does NOT re-center on `_reLayoutSelf`** (a bare
    PanelWdgt has no centering layout), so its absolute position goes stale when the frame changes → the seam re-fits.
    **§4.4 line-431 probe (empirical, throwaway, reverted):** commenting out the `@contents.left()/top()` anchor is
    **byte-exact with the seam ON (165/165)** — it is redundant WITH the seam — but the in-pass reverse-probe with it
    removed **still breaks the same 10** (recovers 0). ⇒ **§4.4's `:431` anchor is NOT the crux; decoupling it alone does
    not reduce the in-pass seam dependence.** Two things a real crack needs, neither a quick change: (a) make content-sizing
    child POSITIONS pure for EVERY content kind (extend the stack's `subWidgetsMergedPreferredBounds` override to the
    bare-panel / centered-icon cases — i.e. give them a real centering layout so positions are re-derived, a behaviour-risky
    change), AND/OR (b) the §4.3 ordered down-walk so the container is VISITED after its content settles WITHOUT the seam
    (the in-pass channel; `_invalidateLayout` throws in-pass, so only `__markForRelayout` is legal — no D1 shortcut like the
    off-pass half had). PLUS the window group (4) is a wholly separate `WindowWdgt` re-fit path. This is the genuine §8 wall;
    §4.2/§4.3 are each a multi-hour structural build. **`_applyMoveBy` DOES translate children rigidly (Widget:1274-1276)** —
    so the staleness is the non-re-centering free-positioned child, NOT a lagging keepContents move (rules out that fix).
- **Stage 3 — the `:431`/keepContents decoupling (§4.4).** Rewrite frame-size/position separation; instrument the
  centered-icon + scrolled cases; byte-exact gate. ⚠ 2026-07-01: line-431 removal proven byte-safe-with-seam but
  seam-reduction-neutral (see Stage 2 findings) — §4.4 must be paired with pure content positions (§4.2) + the §4.3
  visit channel to matter; it is not a standalone lever.
- **Stage 4 — ✅ DONE 2026-07-01 (the ordered settle-time re-fit — a simpler realization of §4.3 than the planned
  two-flag).** No two-flag/down-walk scaffolding was needed. Instead: the settle loop already walks up each broken
  chain to a chain-top and `_reLayout`s it; adding **one call right after that `_reLayout`** — re-fit the chain-top's
  size-tracking container (`_reFitMyTrackingContainerAfterSettle`) — delivers the content→container edge at
  SETTLE-completion instead of mutation-time. The container then reads FINAL (not half-applied) content geometry →
  correct in one visit → bounded O(depth) up-walk, no fixpoint iteration. KEY: the up-edge must **NOT** be gated on
  freefloating (a non-freefloating tracked child — a nested `WindowWdgt` — also re-fits its parent; a chain-top trace
  found this). Reverse-probe seam-OFF + up-edge: 3 (scroll-only) → 7 → **0** as the guard broadened; final 165/165.
- **Stage 5 — ✅ DONE 2026-07-01. DELETED `_announceGeometryChangeToContainer` + its 2 firing sites**
  (`_commitExtentAndNotify` / `_applyMoveByAndNotify` — now pure geometry mutators). The method was repurposed/renamed
  to `_reFitMyTrackingContainerAfterSettle`, called by the settle loop (Stage 4). Byte-exact: **gauntlet
  dpr1/dpr2/webkit 165/165 + apps/tier/settle, 0 recaptures** (the rename netted zero method-count change → no
  inspector shift); convergence via repeated danger-config runs, RECALC_NONCONVERGENCE ABSENT. **The entire
  notify-by-mutation re-fit seam (property + geometry) is now GONE.** ⏭ NEXT = Stage 6 (retire the booleans): the
  bounded up-walk should let `recalcIterationsCap` demote to a never-fire assert.
- **Stage 6 — ✅ DONE 2026-07-01 (the convergence cap retired; phase flags assessed; residual convergence pruned).**
  KEY CORRECTION to the pre-work premise: the settle loop is **NOT** the "≤8 pure O(depth) drain" this plan assumed.
  Instrumenting the FULL suite (dpr1 + dpr2, `window.__fizzyMaxRecalc`/re-visit counters) measured **peak 428
  iterations in ONE flush — but with ZERO re-visits (427 DISTINCT widgets: a big tree settled at once, a pure
  drain)**, AND a separate **peak of 10 re-visits** of a 5-widget `Window → VerticalStack → ScrollPanel` chain
  (`macroWindowCellsInConstrainedScrollStackReflow`). So the loop still has a small **bounded size-negotiation
  convergence** (it converges fast + bounded, it does NOT strictly drain). `RECALC_NONCONVERGENCE` never fires.
  - **`recalcIterationsCap` → `layoutIterationsSanityLimit` (DONE).** The SILENT convergence-suppression (log +
    `@widgetsThatMaybeChangedLayout = []` + `return`, i.e. abandon the work-list and ship a broken layout) is
    **DELETED**. What remains is a pure **never-fire assertion** at a generous-but-finite bound (100000, ~230× the
    empirical peak 428): on the impossible non-termination it `console.error`s the `RECALC_NONCONVERGENCE` token
    (kept for the torture grep) **then THROWs** — a loud bug tripwire, not a tolerated budget. (Owner's explicit
    choice 2026-07-01: loud-throw over full-delete, because the loop is NOT provably acyclic — residual convergence
    is real — so a production non-termination should surface as an error, not a frozen tab. The per-`_reLayout`
    ERROR path is separately handled by the catch block; the cap only ever backstopped non-*erroring* non-convergence,
    which the bounded up-walk makes vanishingly unlikely.) Byte-exact (the branch never executes): gauntlet
    dpr1/dpr2/webkit 165/165.
  - **The 3 phase flags — VERDICT: all STAY; none is a convergence device (honest per the mandate).** The original
    "remove the seam ⇒ all these booleans have nothing to do" theory (`proper-layouts-elimination-goal`) **conflated
    convergence devices with re-entrancy/batching guards.** Grepped + read every use:
    - `_recalculatingLayouts` — the FLOWRULE **re-entrancy guard** (throws at `recalculateLayouts` if a public setter
      re-enters a pass) AND the **in-pass/off-pass dispatch** (`if world._recalculatingLayouts then __markForRelayout()
      else _invalidateLayout()` at `Widget.coffee:2122/2150`, `_reFitContainer:1716`, the D1 climb guard `:3824`,
      `TextWdgt:423`, `StringWdgt:1228`) — it picks the *legal* enqueue primitive mid-pass (`_invalidateLayout` throws
      in-pass). Independent of convergence. **STAYS.**
    - `_inLayoutMutation` — the **re-entrancy guard** for "a public geometry setter reached during a flush" (`Widget.coffee:800`
      → throw unless orphan) + the debug end-of-cycle audit. Independent of convergence. **STAYS.**
    - `_batchingLayoutSettling` — the **batch/coalesce** perf primitive (`_settleLayoutsAfterBatch`, currently 0 callers,
      retained-by-design + allowlisted). Not convergence. **STAYS** (its dead-code status is a separate question, not this arc's).
  - **Residual convergence (owner-requested "investigate the cycle now") — CHARACTERIZED + PARTLY PRUNED.** The
    residual re-visits are the **inherent bidirectional layout dependency**: the settle loop is deliberately
    **parent-first / top-down** (its own comment at the walk-up: a freefloating child must be sized by its parent
    first), so a size-tracking container SIZES its content's width top-down, then must FIT to the content's resulting
    height bottom-up — a bounded **2-visit** pattern (top-down size, then the settle-time up-edge as the bottom-up
    fit). Suite-wide it is dominated by **text-wrapping resize** (`macroWrappingTextFieldResizesOK` etc. — the classic
    width→height) and the **caret scroll-follow** (`CaretWdgt._reLayout`, an intentional partway-convergence). A trace
    showed **most re-visits were WASTED no-op re-fits** (a chain-top re-enqueued only to be re-laid to the SAME box,
    e.g. a scroll panel `362x204 → 362x204`). ⇒ **NO-OP EARLY RETURN shipped:** the settle loop now only calls
    `_reFitMyTrackingContainerAfterSettle` if the just-settled chain-top's FRAME actually changed (position or extent);
    an unchanged frame means the container's fit is unchanged (sound whether the widget is fit-to-content or
    fixed-size). **Suite-wide peak re-visits 10 → 2**, byte-exact dpr1/dpr2/webkit + danger torture. The residual **2**
    is the genuine one-round negotiation. **True single-pass (eliminating the last 2) = the known §4.2 pure-measure
    wall** (measure content height at the target width WITHOUT applying, then arrange once) — NOT unlocked by the seam
    removal; left as the genuine remaining proper-layouts wall (a multi-hour structural build, uncertain byte-exact).
  - **Per-axis DAG lint — N/A.** It presupposed the convergence is a proven DAG up-walk; the measurement FALSIFIED that
    (bidirectional size negotiation ⇒ not a DAG). No lint added.
  Verified: `./fg gauntlet` dpr1/dpr2/webkit 165/165 + apps + tiernaming + settle; danger-config torture (manual loop —
  `torture-headless.js` deadlocks in-session) RECALC-absent, no nondeterminism.

Any single stage that cannot be made byte-exact is a **sanctioned stopping point for that stage** — bank the
reductions already shipped and leave the rest. That is NOT the same as declaring the seam irreducible.

---

## §6 — Verification protocol (every stage touching the loop / an arrange / the seam / `_invalidateLayout`)
- `./fg build` (0 violations) · `./fg suite` (dpr1 165/165; dump+LOOK on any pixel fail) · `./fg gauntlet`
  (dpr1/dpr2/WebKit 165/165 + apps + tier-naming + settle gates).
- **`./fg gauntlet` alone is NOT enough for a convergence change.** Run the **torture**:
  `node scripts/torture-headless.js --minutes=20 --dprs=1,2 --speeds=fast,fastest --shards=1,2,4,8`.
  `RECALC_NONCONVERGENCE` must be **ABSENT** and no test may flip (only stale-ref benign inspectors allowed, and only
  until recaptured). Ideally add a dpr2-fastest-s8 pass (the classic determinism-danger config).
- The **reverse-probe** is the seam-specific gate for Stages 1–5: with the seam no-op'd, the target break-list must
  CONVERGE and byte-match the seam-ON pixels.
- Benign inspector member-list/source recaptures are PRE-AUTHORISED; anything else must be byte-exact.
- Kill orphan `Chrome for Testing` before each run; write gate output to a file then read it (do not pipe the build
  into a filter — the `fizzygum-cmd-guard` hook blocks wrong-cwd/piped-build commands; use `./fg` from the umbrella
  root, which is cwd-correct).

---

## §7 — References (read these; they are the accumulated hard-won context)
- **`docs/proper-layouts-4.4-ordered-downwalk-plan.md`** — §8 is the binding FALSIFICATION record (the 8 paths, the
  341-vs-5 instrumentation, the geomcap idempotence finding). §2/§3/§4 are the (never-implemented) ordered-down-walk
  design this plan's §4.3 revives.
- **`docs/proper-layouts-4.1-pure-measure-campaign-plan.md`** — the pure-measure protocol (`preferredExtentForWidth`,
  `subWidgetsMergedPreferredBounds`) this plan's §4.2 extends.
- **`docs/proper-layouts-4.2-structural-arrange-plan.md`** — the non-notifying arrange twins (`_applyExtent` /
  `_applyBounds` / `_applyMoveTo`) that already removed the arrange's self-fires (capstone 18→0).
- **`docs/proper-layouts-eliminate-suppression-booleans-plan.md`** — the phases A–F elimination roadmap + the goal
  (delete the booleans, don't relocate them).
- **`docs/layout-system-architecture-assessment.md`** §2.4/§2.5/§4.1/§4.2/§4.4/§4.5 — the owner's authoritative
  analysis (READ, never edit).
- **Memories:** `[[proper-layouts-elimination-goal]]` (the standing mandate), `[[fizzygum-structural-arrange-arc]]`
  (§4.2 + the §8 verdict), `[[fizzygum-convergence-arc-feasibility]]`, `[[fizzygum-pure-measure-campaign-progress]]`,
  `[[fizzygum-next-work-backlog]]` (the property-seam-deletion result + the D1/bare-invalidate technique — the direct
  precedent for this plan).
- **Anchors (vs `c637ffb1`, grep the symbol — line numbers drift):** seam `_announceGeometryChangeToContainer`
  Widget.coffee:1662; firers `_commitExtentAndNotify`:1599 / `_applyMoveByAndNotify`:1261; dispatch
  `_reFitContainer`:1706; `_invalidateLayout` (+ freefloating-skip + D1):3800; `__markForRelayout`:3796;
  `markLayoutAsFixed`:4119; `layoutIsValid`:234; `widgetsThatMaybeChangedLayout` WorldWdgt:302; settle loop
  `_recalculateLayoutsBody` WorldWdgt:928 (cap :934); measures `preferredExtentForWidth`:741 /
  `subWidgetsMergedFullBounds`:1088 / `subWidgetsMergedPreferredBounds`:1119; scroll crux
  `ScrollPanelWdgt._positionAndResizeChildren`:345 (pure :399/401, applied :403, anchor :431), `keepContentsInScrollPanelWdgt`:465,
  `_applyExtentAndNotify` override :266, `_reLayout` :315, `_reLayoutScrollbars`:129; `_amIDirectlyInsideNonTextWrappingScrollPanelWdgt`:2848;
  `isFreeFloating`:620.

---

## §8 — Honest risk + the persistence mandate
This is the genuinely hard half. §8 of the 4.4 plan is right that a *single container's* arrange has no internal
convergence to remove, and that an *off-pass* climb cannot deliver an *in-pass post-application* signal. So the real
paths (§4.2 pure-positional-measure, §4.3 ordered down-walk, §4.4 decoupling) are structural and non-trivial, and
any one of them may not reach byte-exactness. That is an acceptable per-stage outcome.

What is **not** acceptable is repeating 2026-06-29's over-generalisation: concluding from one or two failed stages
that the whole seam is irreducible. The property sub-seam — counted inside the same "irreducible" verdict — fell to
decomposition + the bare-invalidate insight + persistence, after the paths that "should" have worked (self-mark
invalidate, trigger-form climb) each failed first. Expect the geometry seam to take several honest attempts, expect
the yielding slice to be non-obvious, and expect the win (if it comes) to reduce the seam incrementally rather than
delete it in one move. Bank every byte-exact reduction; keep the seam only for what genuinely resists; and only the
GOAL (§5 Stage 6 — the booleans gone) counts as done.
