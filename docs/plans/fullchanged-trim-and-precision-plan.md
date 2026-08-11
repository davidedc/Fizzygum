# `_fullChanged` trim & precision: six findings, executed — the invalidation machinery never needs a hammer

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Status: AUTHORED 2026-08-11, not started. Owner-directed follow-up to the `_fullChanged` usage audit (same day, memory note `fullchanged-usage-audit`), which the owner commissioned right after the arbitrary-direction-shadows arc (Fizzygum `4e8ec996`, tests `ea9a1e320`) with the standing mandate this plan inherits:

**Mandate (owner's words, load-bearing):** invalidation "should be trim and precise so as NOT to need such a hammer" — a sweeping repaint is never the designed answer; where one exists it is either (a) genuinely irreducible (prove it), (b) a batching device whose scope IS the change (prove it), or (c) a stand-in for information the system throws away — in which case the fix is to make the system KEEP the information, not to enumerate guesses. Each phase below either eliminates a hammer, proves a site minimal, or closes a finding as measured-not-worth-it with the measurement on record. Nothing is "made easier to live with".

---

## §0 Orientation

Fizzygum (CoffeeScript GUI framework, one `<canvas>`, broken-rects incremental repaint — root `CLAUDE.md` + `Fizzygum/CLAUDE.md` for build/test) invalidates via two PRIVATE verbs on `src/basic-widgets/Widget.coffee`: `_changed()` (own paint bounds) and `_fullChanged()` (own SUBTREE footprint — a dedup-flagged mark; the flesh-out lanes in `src/WorldWdgt.coffee` union the widget's last-painted rect with its current one, both shadow-inclusive via `shadowExtendedRect`). Cross-object calls are structurally banned by `buildSystem/check-invalidation-receivers.js` except sites annotated `# cross-invalidation-sanctioned:` (9 today, all dispatcher/orchestration shapes).

**Critical reframe (the audit's core result — do not re-derive it wrong):** `Widget._fullChanged()` is NOT a world repaint; it is subtree-scoped. The true hammer — `world._fullChanged()`, repaint everything — appears in exactly FOUR shipping sites, and only ONE of them is a stand-in for discarded information (F6). The audit bucketed all 56 src call sites; this plan executes its six findings in dependency/priority order. The audit's inventory is summarized in §1 per finding; the memory note `fullchanged-usage-audit` and the conversation that produced it are NOT needed — this doc is self-contained.

**The six findings, named as their phases run (execution order):**

| Phase | Finding | One-liner | Kind |
|---|---|---|---|
| P0 | — | Probe/measure ALL hypotheses first (F1 repro, F2 redundancy, F3+F4 frequency) | probing |
| P1 | F1 | `toggleVisibility`/`removeFromTree` use bare `_fullChanged` where the shadow-owner walk is needed — possibly TOO NARROW (a correctness hole, the inverse of the mandate) | fix + test |
| P2 | F2 | Two redundant trailing `@_fullChanged()` (PopUpWdgt.popUp, ToolTipWdgt.openAt) — dead weight | deletion |
| P3 | F4 | `bringToForeground` runs on EVERY left-click press with no already-frontmost guard → a full focus-root repaint per click | fix |
| P4 | F5 | Test-side `world._fullChanged()` oracles swappable to the PUBLIC cache-reset verb where lane-diagnosis isn't the point | tests |
| P5 | F6 | The atlas-warm whole-world repaint replaced by paint-time cold-glyph attribution — the one real hammer-elimination | design + fix |
| P6 | F3 | The `disableTrackChanges` window DISCARDS per-child rects; collect-union variant — execute ONLY if P0's numbers justify it | gated |

**Why this order:** correctness first (F1 is the only candidate BUG); free deletions ride next (F2's redundancy proof comes out of P0); the biggest measured cost with the smallest fix follows (F4's guard is three lines); tests-side purity next (F5, independent, tests-repo only); then the one genuine design change (F6, cross-repo spike, the owner's driving question); F3 last because its payoff is least certain and its blast radius (~20 leaf `_reLayout`s) largest — its go/no-go DECISION is made at P0, only its execution is deferred.

## §1 Exact current state (grep every symbol fresh; line numbers are advisory, quoted code is authoritative)

Baseline: Fizzygum `4e8ec996` / tests `ea9a1e320` (suite 289, gauntlet 14/14). All refs below re-verified at authoring time.

### Core semantics
- `Widget._fullChanged` (`src/basic-widgets/Widget.coffee` ~:3232): under `world.trackChanges` top-of-stack, push onto `world.widgetsWithMaybeChangedFullPaintBounds` once (`fullPaintBoundsMaybeChanged` dedup flag — cleared per `_updateBroken`, so repeated same-cycle calls are free).
- `Widget._fullChangedIncludingShadowOwner` (~:3244): if `firstParentOwningMyShadow()` exists, invalidate THAT ancestor (a child of a shadow-casting composite contributes to the ancestor's silhouette; breaking only the child's rect leaves the ancestor's stale shadow band on screen), else self. **Its own comment admits the drift: "many other bare @_fullChanged sites could arguably use this too."**
- Flesh-out lanes (`src/WorldWdgt.coffee` `_fleshOutBroken` ~:867 / `_fleshOutFullBroken` ~:930): every damage rect gets `.expandBy(1).growBy @maxShadowSize` (=6, corner-ward: +7px bottom-right, +1 top-left slack — the margin that masked the shadows arc's D1 for (12,4)).

### F1 — shadow-owner-variant drift (P1)
- USES the shadow-owner walk: `hide` (~:2923), `show` (~:2934), destroy path (~:661), the add/re-home dispatcher (~:3344).
- USES bare `_fullChanged`: **`toggleVisibility` (~:2941)** — `@isVisible = not @isVisible; WorldWdgt.noteVisibilityOrCollapseChange(); @_fullChanged()` — the toggle twin of hide/show that MISSES the walk; **`removeFromTree` (~:3032)** — `@parent.removeChild @; @_fullChanged()` — the structural removal that misses it.
- Also bare, needing classification (not obviously shadow-relevant, decide in P1 with the criterion below): `_collapseNoSettle` (~:2962), `_expandNoSettle` (~:2988), `addShadow`/`removeShadow` (~:3161/:3172 — self IS the shadow owner, bare is correct), `_applyMoveByBase` (~:1976 — a move's erase uses the recorded shadow-inclusive footprint, bare is correct), `_moveInFrontOfSiblings` (~:3805) / `bringToForeground` (~:3810) — z-order does not change the composite silhouette (opacity union is order-independent), bare is correct.
- **Classification criterion:** a bare site needs the walk iff the operation changes what the subtree CONTRIBUTES to an ancestor-owned shadow silhouette (appear/disappear/shape-change) — not merely where it paints (moves erase via the recorded footprint) or its stacking order.

### F2 — redundant trailing calls (P2)
- `src/PopUpWdgt.coffee` `popUp` (~:184-201): `__commitMoveTo` → `widgetToAttachTo.add @` (invalidates via the add dispatcher) → `_moveWithin world` → `@addShadow()` (→ `Widget.addShadow` → `@_fullChanged()`, unconditional on every branch of `PopUpWdgt.addShadow`) → **`@_fullChanged()` ← redundant**.
- `src/ToolTipWdgt.coffee` `openAt` (~:52-58): `_applyMoveTo` (pre-add, nothing painted) → `world.add @` → `@addShadow()` → **`@_fullChanged()` ← redundant**.
- Both are runtime-free (dedup flag already set in the same JS turn) — the cost is clarity; the deletion must be PROVEN no-op (P0c) not assumed.

### F4 — unguarded z-order raise (P3)
- `Widget.mouseDownLeft` (~:3826): `@bringToForeground(); @escalateEvent "mouseDownLeft", pos` — **every left-click press on every widget**.
- `bringToForeground` (~:3810): `@rootForFocus()?.moveAsLastChild(); @rootForFocus()?._fullChanged()` — **no guard**. `moveAsLastChild` (`src/basic-data-structures/TreeNode.coffee` ~:90) early-returns when already last, so the structural half is a no-op for an already-frontmost root — but the `_fullChanged` still fires: a full repaint of the clicked window/subtree per click, pure cost, invisible to the suite (repaint is byte-idempotent — the paint-audit leg proves exactly that). `isInForeground` (~:3807, `@rootForFocus()?.isLastChild()`) sits directly above, currently consumed elsewhere.
- Other callers of `bringToForeground` (grep at execution time; at authoring: `_createReferenceAndCloseNoSettle` ~:3082 `# public-call-sanctioned`, macros/user code): the guard must live INSIDE `bringToForeground` so every caller benefits.
- ⚠ One known behavioural dependency to respect: the serializer's snapshot-transient note (Widget.coffee ~:65-71) records that "the triggering click's bringToForeground marks the menu dirty right before the save runs" — that path had a real bug from a RESTORED dedup flag, fixed by listing the flags as serialization transients. The guard changes when the mark happens (not on already-frontmost clicks); P0d checks this scenario.

### F5 — test-side oracles (P4)
All in `Fizzygum-tests/tests/`, each `world._fullChanged()` annotated `# macro-private-call-sanctioned:`. The public alternative `world.resetImmutableBackBuffersCache()` (`src/WorldWdgt.coffee` ~:232: cache reset + island-buffer epoch bump + intrinsic self `_fullChanged`) is already the oracle of `SystemTest_macroShadowAnyDirectionRendersAndErases` (swap done in the shadows arc, preference recorded in `src/macros/MACRO-PATTERNS.md` "Staleness diff-oracles").
- **Swappable (classify + swap in P4):** `macroClosingRotatedIslandChildClearsFootprint` (:69) — screen-lane erase check; the rebuild oracle is a strict superset (also catches buffer staleness), an upgrade. `macroOversizedShadowRemovalLeavesNoGhost` — island-free desktop scene. `macroTiltedFigureShadowAsDarkAsStraight` (:46) and `macroColoredCastersShadowNeutralBlack` (:50) — A/B shadow isolation via full repaints; verify at execution that neither compares across the swap in a way the text-cache re-render could perturb (SWCanvas is deterministic; expected fine).
- **⛔ MUST NOT swap: `macroIslandBufferCacheByteIdentity`** (~19 calls) — the KEPT island buffer is the SUBJECT under test; `resetImmutableBackBuffersCache` epoch-bumps every buffer, destroying the very state the test measures. Its `_fullChanged` calls are correct and stay.
- The harness paint audit (`Automator-and-test-harness-src/AutomatorPlayer.coffee` ~:117) IS `world._fullChanged()+_updateBroken()` — the ground-truth instrument; definitional, out of scope.

### F6 — the atlas-warm hammer (P5)
- Trigger chain (`src/boot/extensions/SWCanvasElement-extensions.coffee`): `swCanvasEnsureAtlasForFont` (~:115) requests missing glyph atlases; on a load resolving warm, `swCanvasScheduleTextRefresh` (~:88) batches one rAF-deferred `window.world?.resetImmutableBackBuffersCache?()` (~:96) per frame of arrivals.
- `WorldWdgt.resetImmutableBackBuffersCache` (~:232): `@cacheForImmutableBackBuffers?.reset?()` (drops the ENTIRE content-keyed LRU — `new LRUCache 1000` at ~:510) + `WorldWdgt.immutableBackBufferGeneration++` (every island buffer rebuilds) + `@_fullChanged()` (whole world).
- Cache consumers (all keyed by CONTENT, no back-pointer to widgets; entries are shared across widgets by design): `StringWdgt` (~:776/:845), `TextWdgt` (~:423/:483), `PaletteWdgt` (~:41/:52), `AnalogClockAppearance` (~:164/:172 — the clock FACE, whose numerals are glyphs: any "mark the text widgets" class-inventory misses it — the proof the predicate approach rots).
- Cold-glyph substitution happens INSIDE vendored SWCanvas (`BitmapText`; Fizzygum sees only `hasAtlas`/`loadFont` via `SWCanvas.fonts._raw`) — the surgical design needs a per-draw seam there (Spike S1). Precedent for upstream SWCanvas changes + `vendor/swcanvas.pin` bump: the icon drawing-commands arc (2026-08-09).
- The determinism fence: `world.anyTextDirty()` → `swCanvasAnyTextDirty` (~:153) = `swCanvasAtlasPending > 0 or swCanvasRefreshScheduled` — TWO flags covering both the in-flight and the landed-but-unpainted windows (DETERMINISM.md §2c flake B is the case law for why both). Every test-side pixel read waits on it. **Any F6 design must keep this window airtight.**
- Scope note: the production `--profile homepage` build is NATIVE-only (no SWCanvas bundle, no atlases) — this hammer never swings in production; it swings a handful of times, front-loaded, on the harness/`index-sw.html` pages.

### F3 — the coalescing window (P6)
- The idiom (≈20 sites, e.g. `meta-tools/InspectorWdgt.coffee` ~:597, `ScriptWdgt.coffee` ~:151, `authoring/Stretchable*`, `video-player/*`, `graphs-plots-charts/*`, `icons/Generic*`, `patch-programming*/*`, `app-kit/*`, `ColorPickerWdgt`, `CodePromptWdgt`, `ConsoleWdgt`, `WidgetHolderWithCaptionWdgt`, `GlassBoxBottomWdgt`, `basic-widgets/SliderWdgt` ~:251): `world.disableTrackChanges()` → position children via non-notifying `_apply*`/`_reLayout` tiers → `world.maybeEnableTrackChanges()` → `@_fullChanged()`. Purpose: ONE subtree rect instead of N child rects. Precision loss: a re-lay that moved one child still repaints the whole box. Counter-argument: most re-lays follow a real granted-bounds change where the whole box changed anyway. **This is why F3 is measurement-gated, not assumed.**

## §2 The distilled argument

- **F1 is the only suspected CORRECTNESS defect and it points the opposite way from the audit's premise** — two sites may be too narrow. It runs first, plant/probe first (a hypothesis that does not reproduce gets root-caused, not "fixed" — standing rule).
- **F2/F4 are pure subtraction** — a deletion and a guard; both provably behavior-preserving via P0 evidence + the suite's byte-identity.
- **F6 is the mandate's centerpiece:** the world-repaint stands in for information the system throws away at paint time (WHICH widgets drew placeholder glyphs, WHICH cache entries are poisoned). The fix records at the event — not by class inventory, which is an open set that rots silently (the clock face disproves "mark the text widgets"). Correct-by-construction beats enumerate-and-hope.
- **F3/F4-deep are measurement-gated:** the mandate says trim, not ornate — machinery added to save repaints must pay for itself in measured repaints saved. P0 produces the numbers; a below-threshold finding is CLOSED with the numbers on record, which is elimination of the QUESTION, not burial.
- **F5 is hygiene with one hard exclusion** — and the exclusion (`macroIslandBufferCacheByteIdentity`) is itself the documentation of when the sanctioned private oracle is genuinely required.

## §3 Phases (execution order; each = probe → fix → test → docs; gates named per phase)

### P0 — Probe & measure EVERYTHING first (no src behavior changes; ~half a day)
Probes live in `Fizzygum-tests/.scratch/` (Node resolves `require` from the script's dir — never the session scratchpad). Model on `.scratch/probe-shadow-direction.js` (A/B/C reads; drop nothing — it is current) and `.scratch/probe-shadow-instrument.js` (monkey-patch logging). Build must be FRESH (`fg status`).
1. **P0a (F1 repro):** fixture — desktop composite `parent` (RectangleWdgt) with child, `world.add parent` (parent owns a (4,4) default shadow; give it (12,12)/0.35 for a visible band), settle. Mutations, each on a fresh fixture: (i) `child.toggleVisibility()`; (ii) `child.removeFromTree()` (child stays owner-less — also try re-`world.add` after, separately). After settle: A/B diff (`world.fullRenderCanvasAsItAppearsOnScreen()` incremental vs after `world.resetImmutableBackBuffersCache()` ground truth — the PUBLIC oracle; note a plain-desktop scene needs no lane distinction). **Prediction: stale ancestor-shadow band (the child's silhouette contribution lingers where only the walk-up would have erased it).** Sensitivity trap from the shadows arc: position the child so its contribution's band falls where the flesh-out's corner-ward `+7px` slack does NOT cover the delta — put the child at the parent's TOP-LEFT region so its vanished silhouette changes the shadow's up-left edge... the shadow paints down-right of the parent: the child's contribution is at (child position + offset); choose child straddling the parent's LEFT edge so the composite silhouette (and its shadow band's left edge) visibly changes. If CLEAN: root-cause before touching anything (candidate masks: the parent's own `_reactToChild*` re-layout re-invalidating; the removeChild path's separate invalidation; the flesh-out slack — reconstruct rects exactly as the shadows arc did).
2. **P0b (F3+F4 frequency), one instrumented suite run:** monkey-patch in-page before the run (a prelude script à la `scripts/audit-preludes/` — copy `revisit-prelude.js`'s wiring): (i) wrap `Widget.prototype.bringToForeground` to count calls vs calls-where-`isInForeground()`-already-true; (ii) wrap `disableTrackChanges`/`maybeEnableTrackChanges`/`_fullChanged` to log, per coalescing window, the widget's box area vs the union of child boxes ACTUALLY moved/resized inside the window (patch `_applyMoveByBase`/`_applyBounds`/`_applyExtent` to accumulate under a flag). Output: totals + ratios. **Decision thresholds (owner-adjustable): F4 guard = unconditional (any nonzero already-frontmost count justifies three lines); F3 = pursue only if >20% of coalescing windows change <50% of the box area across the suite** (else close as NOT PURSUED with the numbers).
3. **P0c (F2 redundancy proof):** in-page: wrap `_fullChanged` to record `fullPaintBoundsMaybeChanged` at entry; open a pop-up (right-click a widget) and a tooltip; assert the trailing sites' flag is ALREADY true on every path (i.e. the wrapped call observed `true`). Also grep-verify no path reaches the trailing call without `addShadow` (both methods, all branches).
4. **P0d (F4 behavior canary):** the snapshot-transient scenario — open a menu, click its header (pin), save a world snapshot, reload, move the restored menu — no repaint artifacts (this is the Widget.coffee ~:65 case-law scenario; it must stay green under the P3 guard).

### P1 — F1: unify the shadow-owner walk (only if P0a reproduces; else record falsification and skip to P2)
1. Fix: `toggleVisibility` and `removeFromTree` → `@_fullChangedIncludingShadowOwner()`. Sweep the remaining bare sites against the §1 classification criterion; expected outcome at authoring: NO other site flips (moves/z-order/self-shadow are correct bare) — verify, don't assume. Update `_fullChangedIncludingShadowOwner`'s comment: the "many other bare sites could arguably…" sentence dies — replace with the criterion.
2. `fg build`; P0a probe flips to clean (both mutations, exact-0).
3. Coverage (`/author-macro-test` skill): `SystemTest_macroHiddenShadowChildLeavesNoBand` — reference-free diff-oracle: composite with ancestor shadow, `child.hide()` is covered (existing walk) so the test drives **`child.toggleVisibility()`** twice (off → assert; on → assert) plus a **`removeFromTree`** leg, A-vs-ground-truth exact-0 each. Oracle: the PUBLIC `world.resetImmutableBackBuffersCache()` (owner preference; plain scene). Non-vacuity plant: revert the two sites to bare `_fullChanged` → test FAILS with the P0a pixel count; revert back. Never commit the plant.
4. Gate: `fg presuite`. Zero reference churn expected (adding invalidation on idempotent paint changes no pixels).
5. Docs: none beyond the comments (the walk is an internal); MACRO-PATTERNS entry only if the toggle-twice idiom is new (check the catalogue first).

### P2 — F2: delete the two redundant calls
1. Delete the trailing `@_fullChanged()` in `PopUpWdgt.popUp` and `ToolTipWdgt.openAt` (P0c is the proof they are dead). Keep each method's remaining comments intact.
2. `fg build && fg presuite`. Zero churn expected — a deleted no-op cannot move pixels; ANY churn = P0c was wrong, stop and root-cause.

### P3 — F4: guard the raise
1. Fix in `bringToForeground` (so all callers benefit):
   `return if @isInForeground()` before the move+invalidate pair. (`moveAsLastChild` already no-ops structurally; the guard kills the gratuitous `_fullChanged`.) Comment: state the cost this guard removes (a full focus-root repaint per left-click on the already-frontmost window) and why the guard is safe (raising the frontmost is a visual no-op; repaint idempotence held before, so suppressing it is pixel-identical).
2. `fg build`; re-run P0b's F4 counter — already-frontmost raises now invalidate zero.
3. Run P0d (the snapshot canary) again.
4. Gate: `fg presuite`, then **full `fg gauntlet`** (this touches every click in every test — the broadest-exposure change in the plan; the settle/capstone/revisits legs are the ones that would catch a missed dependency on the gratuitous repaint).
5. The DEEP variant (occlusion-aware damage for genuinely-raised overlapping windows) is **NOT PURSUED** — record in §5 with the P0b numbers; the guard captures the common case (clicks inside the active window) at zero complexity.
6. Docs: none (internal); the paint-audit leg's byte-identity is the standing proof.

### P4 — F5: swap the swappable oracles (tests repo only, no rebuild needed — tests are served via symlink)
1. Per-test classification (§1 list): swap `macroClosingRotatedIslandChildClearsFootprint`, `macroOversizedShadowRemovalLeavesNoGhost`, `macroTiltedFigureShadowAsDarkAsStraight`, `macroColoredCastersShadowNeutralBlack` to `world.resetImmutableBackBuffersCache()` + the two settle yields, dropping the `# macro-private-call-sanctioned` line; adjust each metadata `assertions`/`provenance` wording. **⛔ `macroIslandBufferCacheByteIdentity` keeps every `_fullChanged`** — add one sentence to ITS provenance stating why (the kept buffer is the subject; the reset would destroy it).
2. Verify each swapped test individually (`node scripts/run-macro-test-headless.js <name>` + `--dpr=2`), then re-prove ONE non-vacuity plant per swapped diff-oracle test still fails (the shadows-arc plants are the recipes: e.g. the closing-island test's original revert). A swapped oracle that stops failing under its plant = the swap weakened it → revert that test's swap and record why.
3. Gate: `fg suite` (both dprs if any reference-carrying test was touched — these four are reference-free/reference-stable; screenshots must NOT change since the oracle runs after the last capture in each — verify zero churn).
4. Docs: MACRO-PATTERNS "Staleness diff-oracles" — the sanctioned-`_fullChanged` sentence narrows to "only when the kept-buffer state is itself the subject (macroIslandBufferCacheByteIdentity) or lane diagnosis is the point".

### P5 — F6: surgical cold-glyph attribution (the hammer elimination; cross-repo; ~1-2 days)
**Spike S1 (gate for the whole phase): find the per-draw cold-glyph seam.** Read the vendored SWCanvas `BitmapText` draw path (the vendored bundle in `Fizzygum/vendor/` per `scripts/vendor-swcanvas.sh`; the SWCanvas repo checkout if present as a sibling — check `vendor/swcanvas.pin` for the SHA). Needed: a callback/flag Fizzygum can observe **synchronously during a fillText that substituted placeholder boxes** (atlas missing at draw time). If none exists, add upstream (`onColdGlyphDrawn(idString)` hook or a per-draw return flag), pin-bump per the icon-arc precedent. If the seam is impossible cleanly (e.g. draws are batched beyond attribution), STOP — record the falsification in §5 and keep the current hammer (it is then bucket (a): irreducible with acceptable cost).
2. **Design (adjust to S1's actual seam):**
   - At cold-glyph draw time: record `world.paintingWidget` (already maintained by `fullPaintIntoAreaOrBlitFromBackBuffer` ~:2831 for error attribution) into `world.pendingColdGlyphWidgets` (a Set), and the cache key being built (StringWdgt/TextWdgt/Palette/ClockFace writers) into `world.pendingPoisonedCacheKeys`. A cold draw OUTSIDE any widget paint (paintingWidget nil — shouldn't happen; assert-log) falls back to the world hammer for that batch.
   - On atlas warm (`swCanvasScheduleTextRefresh`'s rAF): instead of `resetImmutableBackBuffersCache` — evict exactly `pendingPoisonedCacheKeys` from the LRU; for each live recorded widget `w`: `w._fullChangedIncludingShadowOwner()` (cross-invalidation-sanctioned: atlas-warm orchestration — annotate for the gate); destroyed/orphaned widgets skip (their pixels were already erased). **No epoch bump**: a recorded widget inside an island deposits its own damage into the buffer via the (exact, since the shadow-reach arc) flesh-out lanes, so the buffer region re-renders with warm text — the whole-cache rebuild dissolves.
   - `swCanvasAnyTextDirty` semantics UNCHANGED: `swCanvasRefreshScheduled` stays true until the surgical pass has applied (same `finally` discipline, ~:97-102) — the fence window is identical.
   - `resetImmutableBackBuffersCache` itself STAYS (public; the test oracle + any future genuine full-reset need) — only the atlas-warm CALLER stops using it.
3. **Verification — this phase's gates are the strictest in the plan:**
   - Probe first (`.scratch/probe-atlas-surgical.js`): boot the SW harness page cold, fixture with text at several sizes + a clock + a palette + text INSIDE a 35° island; capture after full settle; assert byte-equality against the same scene on the pre-change build (the end state must be pixel-identical — only the WORK done differs); log the recorded-set sizes.
   - `fg presuite`, then full `fg gauntlet`, then **`fg fuzz` — MANDATORY here** (this phase changes atlas-arrival handling, the exact §3g/§3i read-timing bug class; the atlas-delay injector is the instrument built for it; remember INVALID=exit 2 is not a pass, and a fuzz failure means fix the READ, never recapture).
   - `fg homepage` (native production tree untouched — the SW-only machinery must not leak into the native bundle; the boot-smoke asserts no console errors).
4. **Docs:** `Fizzygum-tests/DETERMINISM.md` §2c/§3g (the refresh is now surgical; the two-flag fence unchanged — update the mechanism description, not the contract); comments at `swCanvasScheduleTextRefresh`, `WorldWdgt.resetImmutableBackBuffersCache` (drop "Caller: swCanvasScheduleTextRefresh"), `WorldWdgt.immutableBackBufferGeneration` (its atlas-warm role narrows to the test oracle); SWCanvas repo docs per its own conventions if S1 lands upstream.

### P6 — F3: collect-union (ONLY if P0b cleared the threshold)
1. Design sketch (refine at execution): `disableTrackChanges` today pushes `false` onto `world.trackChanges`; the variant pushes a COLLECTOR — `_fullChanged`/`_changed` under a collector append `@fullBounds()`/`@bounds` (own-plane→screen-mapped? NO — keep it simple: append the WIDGET, not a rect; on `maybeEnableTrackChanges` the collector's owner calls `_fullChanged` per recorded widget, deduped — the flesh-out already unions and clips). The idiom's trailing `@_fullChanged()` at each of the ~20 sites is then DELETED (the collector replaces it) — this is the subtraction that pays for the mechanism.
2. Risks to probe before landing: nested disable windows (the stack nests today — the collector must too); the hand's `_applyMoveBy` (~ActivePointerWdgt:921) uses the same disable — verify the float-drag fast path keeps its single-composite behavior; sites whose granted bounds changed (the common case) must not regress to N child rects when ONE rect was better — collector dedup: if the OWNER widget itself is recorded, collapse to owner-only.
3. Gates: `fg presuite` + full `fg gauntlet` + one P0b re-measurement showing the repaint-area reduction that justified the phase. Zero reference churn (repaint idempotence).
4. Docs: the layering/naming convention doc if the disable/enable API semantics change; comments at `disableTrackChanges`.
5. If P0b said NO: write the numbers into §5, flip this phase to NOT PURSUED, done — that closure is a deliverable, not a failure.

## §0.5 Cold-execution protocol

1. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (all three repos clean at/past Fizzygum `4e8ec996` / tests `ea9a1e320`; if dirty, stop and ask). Read this plan FULLY. Re-verify every §1 claim with fresh greps (names + quoted code authoritative; line numbers drift). Read `src/macros/MACRO-PATTERNS.md` "Staleness diff-oracles" and skim `docs/archive/arbitrary-direction-shadows-plan.md`'s status stamp (the probe idioms + the masked-by-margin trap this plan's P0a must dodge come from there).
2. Run P0 in full BEFORE any fix. Each prediction that fails to reproduce gets root-caused and recorded in this doc's phase ledger, not worked around.
3. Execute P1→P6 in order. Each phase: fix → probe flips → coverage/plant where specified → the named gate → docs → a one-paragraph ledger entry appended to the phase in THIS doc. Phases are independently landable; the owner may want per-phase commits (ask — present per-repo messages via `git commit -F`, wait for OK; NEVER push autonomously).
4. Churn discipline: EVERY phase expects zero reference churn (all changes are invalidation-timing or oracle-side; paint is idempotent). Any pixel shift anywhere = STOP and investigate; never recapture.
5. Long ops (`fg gauntlet`, `fg fuzz`, instrumented suite runs): background with `run_in_background`, wait for the notification; peek `/tmp/fg-<cmd>.verdict` at ≥5-min cadence only. A running op owns src/tests — no edits mid-run.
6. Close per the close-arc ritual: final full `fg gauntlet` (+ `fg fuzz` if P5 landed), BACKLOG line flip, this plan → `docs/archive/` + status stamp + `archive/INDEX.md` entry + memory note.

## §4 Verification protocol (summary table)

| Phase | Minimum gate | Extra |
|---|---|---|
| P0 | probes green/numbers recorded | — |
| P1 | `fg presuite` | plant-proven test; probe flip |
| P2 | `fg presuite` | zero churn is the proof |
| P3 | `fg presuite` + full `fg gauntlet` | P0b re-count; P0d canary |
| P4 | `fg suite` (+dpr2 spot) | per-test plant re-proof |
| P5 | `fg presuite` + `fg gauntlet` + **`fg fuzz`** + `fg homepage` | byte-equal probe vs pre-change build |
| P6 | `fg presuite` + full `fg gauntlet` | re-measurement showing the win |

## §5 Rejected alternatives / falsification ledger (append at execution)

- **F6 by class inventory ("mark the text widgets dirty") — REJECTED at design time:** the cache is content-keyed with no widget back-pointers, and glyph-drawers are an open set (the analog clock's FACE buffer carries numerals; any appearance may fillText) — a hand-maintained inventory rots silently into permanent placeholder boxes with no gate to catch it. The event-recording design is closed over the actual defect.
- **F5 blanket swap — REJECTED:** `macroIslandBufferCacheByteIdentity`'s oracle must NOT rebuild buffers (the kept buffer is the test subject). Swap by classification only.
- **F4 occlusion-aware damage as the primary fix — NOT PURSUED:** complexity out of proportion; the `isInForeground` guard removes the dominant cost (already-frontmost clicks) in three lines. Revisit only with new measurements.
- (Execution appends here: P0a non-repro root-causes, S1 seam verdict, P6 go/no-go numbers.)

## §6 References

- Memory notes: `fullchanged-usage-audit` (the audit this plan executes), `arbitrary-direction-shadows-arc` (probe idioms, masked-by-margin case law, the F5 precedent swap), `cross-invalidation-audit-and-gate` (invalidation privacy + the gate), `broken-rect-staleness-invisible-to-screenshots` (why repaint idempotence makes zero-churn the expectation), `atlas-delay-fuzz-tool-arc` (fg fuzz semantics for P5).
- Docs: `Fizzygum-tests/DETERMINISM.md` §2c (flake B — the two-flag fence P5 must preserve), §3g/§3i; `src/macros/MACRO-PATTERNS.md` "Staleness diff-oracles"; `docs/archive/arbitrary-direction-shadows-plan.md` (status stamp = probe recipes); `docs/archive/island-buffer-cache-plan.md` §4.4/§6 (epoch semantics P5 narrows).
- Commits: Fizzygum `4e8ec996`, tests `ea9a1e320` (baseline); SWCanvas pin `vendor/swcanvas.pin` (P5 spike).

---

### Ready-to-paste start prompt for a fresh session

> Run the `_fullChanged` trim & precision plan: `Fizzygum/docs/plans/fullchanged-trim-and-precision-plan.md` — read it fully and follow its §0.5 cold-execution protocol. Start with `fg status` (repos clean at/past Fizzygum `4e8ec996` / tests `ea9a1e320`), re-verify the plan's §1 claims with fresh greps (line numbers advisory; the quoted code is authoritative — the load-bearing ones: the bare `_fullChanged` in `toggleVisibility`/`removeFromTree`, the unguarded `bringToForeground` called from `mouseDownLeft`, the trailing redundant calls in `PopUpWdgt.popUp`/`ToolTipWdgt.openAt`, and the atlas-warm `resetImmutableBackBuffersCache` chain in `SWCanvasElement-extensions.coffee`). Phase 0 must run ALL probes/measurements before any fix — a prediction that does not reproduce gets root-caused, not "fixed"; P0a must dodge the corner-ward flesh-out-slack masking trap (see the arbitrary-direction-shadows archive stamp). Then P1→P6 in order, each with its named gate; zero reference churn expected everywhere — any pixel shift = stop and investigate. P5 (`fg fuzz` mandatory) and P6 are the big ones; P6 executes only if P0b's numbers clear the threshold, else it closes as NOT PURSUED with the numbers recorded. Present per-repo commits via `git commit -F` and WAIT for owner OK — never push autonomously.
