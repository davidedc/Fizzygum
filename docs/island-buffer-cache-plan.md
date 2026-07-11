# Island buffer cache — completing §4.4 so "transform animation never re-rasterizes content" is true

**STATUS: ✅ LANDED 2026-07-11 (design LOCKED + executed; results in §6). Phase-5 item 0 (⭐ top
follow-up) of the affine-transforms arc — see `docs/affine-transforms-plan.md` §7 item 15 for the menu
pointer, §4.4/§4.5 for the original design this completes, §9/§10.9/§10.10 (now flipped to TRUE
as-built, measured 1.40×). The design claim "transform animation never re-rasterizes content" is now
TRUE. COMMITTED + PUSHED to origin/master (owner-approved 2026-07-11) — Fizzygum `17803fc0`, tests
`50b240814`. §1-§5 below are the original executed plan, preserved.**

Self-contained and cold-executable. Line numbers verified 2026-07-11 and WILL drift — every anchor
has a symbol; grep the symbol, scoped to `src/` (never the workspace root).

---

## §1 Goal and non-goals

**Goal:** keep each island's content buffer ACROSS composites so that (a) a transform-only change
(rotation/scale step, drag of the island) re-warps the cached buffer with ZERO content
re-rasterization, and (b) a content change re-rasterizes ONLY the dirty sub-rect of the buffer.
This must be **pixel-invisible**: a sound cache produces byte-identical output to the rebuild-
every-time path — that property is this unit's central gate, proven by an on/off A/B, not assumed
(the perf ledger's C1 lesson: a cached back buffer once differed from direct draw via FP
non-associativity — verify, don't argue).

**Non-goals (all banked elsewhere — do not let them creep in):**
- §7.1 dynamic layer-policy engine (cost models, vector-replay mode) — NOT this. In particular the
  "identity blit == replay" and "tiling content stays raster-under-warp" guards belong to §7.1/§7.2
  vector-replay, NOT here: this unit never adds a replay mode, and at identity the island bypasses
  the buffer entirely (stock panel blit), so neither guard applies.
- §7.4 rasterization-scale/density folding (owner-downgraded; if it ever lands, the cache key
  gains a density component — note in code comment, do not build).
- §4.2's warp-sub-rect composite optimization (still banked; composite continues to warp the whole
  buffer under the damage clip).
- Memory budget/eviction policy (v1 lifecycle in §3.6 is enough; LRU budgets are §7.1 territory).

## §2 As-built facts this unit changes (verified 2026-07-11; grep symbols)

- `TransformFrameWdgt._compositeIslandBuffer` (`src/TransformFrameWdgt.coffee`, symbol) calls
  `_refreshIslandBuffer()` on EVERY composite; `_refreshIslandBuffer` allocates a FRESH canvas
  (`HTMLCanvasElement.createOfPhysicalDimensions`), translates by `-slotOrigin×ceilPixelRatio`,
  sets `world.paintingIntoIslandBuffer` (save/restore for nesting — PRESERVE this), and repaints
  the whole content subtree. The buffer is a LOCAL — no instance field exists today (⇒ §3.1's new
  fields introduce a serialization hazard that does not exist yet).
- Each damaged frame composites the island TWICE — the unified shadow pass first
  (`fullPaintIntoAreaOrBlitFromBackBufferJustShadow` → `…ContentPotentiallyAsShadow` →
  `_compositeIslandBuffer`), then the normal content pass — so today every damaged frame pays TWO
  full subtree rasterizations + allocations. ⇒ the refresh must run at the FIRST composite of the
  frame (the SHADOW pass) and be reused by the second — wire it refresh-if-dirty at composite
  time and this falls out automatically; do not special-case "content pass refreshes".
- Composite dispatch: identity → super (stock blit, NO buffer); pure scale →
  `_compositeScaleOnly`; rotation → `_compositeTransformed` (clip + transform + drawImage).
- §4.5 damage invariant (already true, keep true): **buffer content depends ONLY on virtual
  content; the matrix affects only compositing** — a spec (rotation/scale) change damages the
  SCREEN (old∪new footprint) and must NOT dirty the buffer.
- The §4.5 damage hook: `Widget::mapRectToScreen` walks the crossed islands for every inner
  damage rect at flesh-out (both lanes, source + destination) — this walk is the natural DEPOSIT
  point for buffer-dirty rects (§3.2).
- Slot re-fits: `TrackingTransformFrameWdgt._reLayoutChildren` re-fits the slot to content bounds
  (R3; includes the Bug-D anchor-stability code — leave it untouched); `wrapContent` and
  `_materializeSugarIslandNoSettle` set slots directly. Slot EXTENT changes are a realloc.
- Precedents to imitate: `occlusionCullingEnabled` (`src/WorldWdgt.coffee`, the global-flag
  pattern); `@serializationTransients` static-array extension (`TransformFrameWdgt` already adds
  `_lastClaimedExtent`); the world's broken-rect partial repaint (clear + repaint clipped) is the
  model for partial buffer rebuilds.
- Lessons that bite here (memory + plan §8): deepCopy of derived state — `@serializationTransients`
  alone is NOT sufficient for copy-coherence (fizzytiles `rebuildDerivedValue` lesson) — §3.1
  handles it by dirty-all-on-copy; measure perf MINIFIED under `?sw=1`
  (`docs/profiling/prof-interactive.js`); pixel diffs in the EMPTY harness world only.

## §3 Design (LOCKED — owner discussion 2026-07-11)

### 3.1 New instance state on `TransformFrameWdgt` (+ serialization/copy safety)

`_islandBuffer` (canvas), `_islandBufferSlotExtent` (Point, the realloc key),
`_islandBufferDirtyRect` (nil | Rectangle in VIRTUAL coords | the sentinel "all"), and the two
flags in §3.5. ALL buffer fields go into the class's `@serializationTransients` array (extend the
existing one). deepCopy: after copy the fields must be nil/dirty-all — verify what DeepCopierMixin
does with transient-listed fields and, if they are copied anyway, nil them in the copy hook the
way other caches do (grep `rebuildDerivedValue` for the pattern); a copied island silently SHARING
a buffer canvas with its original is the failure mode to rule out (assert distinct-or-nil in the
byte-identity macro, §4 step 5).

### 3.2 Invalidation — event-driven damage-lane deposit (NOT content hashing)

- **Content damage:** in the §4.5 mapping walk (`mapRectToScreen`), when crossing a non-identity
  island, DEPOSIT the pre-mapping virtual rect: `island._islandBufferDirtyRect =
  merge(existing, rect)` (v1 = ONE merged bounding rect — conservative, simple; the rect-list
  refinement ✅ LANDED 2026-07-11, `docs/island-buffer-cache-rectlist-plan.md`). Both flesh-out lanes and both source/destination rects flow through this
  walk already, so old-position erase and new-position paint both land in the union. Zero dormant
  cost (the walk early-returns off-island).
- **Structural changes** (add/remove child) already `fullChanged()` through the same lane. ✓
- **Slot EXTENT change** (tracking re-fit / wrapContent / materialize): realloc — compare against
  `_islandBufferSlotExtent`, on mismatch discard buffer + dirty-all. Slot MOVES (origin-only
  change) keep the buffer (content is painted relative to slot origin via the ctx translate —
  verify: the translate uses the CURRENT origin at refresh time, and a pure move re-fits nothing
  inside the buffer… CAUTION: children's absolute virtual coords move WITH the island on a move
  (`moveBy` recurses), and the buffer's translate is recomputed per refresh — so a moved island's
  cached buffer content is still valid ONLY because content and origin moved together; assert
  this with the drag case in the A/B macro).
- **Transform (spec) changes: deposit NOTHING** (§2 invariant). The existing
  `_transformChangedNoSettle` already only does screen damage — leave it; add a code comment
  pinning the invariant.
- **DO NOT hash content** (no O2-style keys) — invalidation here is event-driven; hashing is a
  different mechanism for a different problem.

### 3.3 Refresh-if-dirty (replaces rebuild-always)

At `_compositeIslandBuffer` entry: if cache disabled (§3.5) → current behavior (fresh local
buffer). Else: no buffer OR extent mismatch → full rebuild into a NEW canvas; else if
`_islandBufferDirtyRect?` → partial rebuild: `clearRect` the dirty rect (physical coords — the
island background is TRANSPARENT, so without the clear old pixels ghost under alpha), then repaint
the content subtree with clip = the dirty VIRTUAL rect (children's normal
`fullPaintIntoAreaOrBlitFromBackBuffer(bufferCtx, dirtyRect)` — the same clear+clipped-repaint
contract the world's broken-rect repaint uses); else → reuse as-is (the transform-animation fast
path: zero rasterization). Clear the dirty state after refresh. Preserve
`world.paintingIntoIslandBuffer` save/restore semantics in all branches (nested islands).

### 3.4 Composite unchanged

`_compositeScaleOnly` / `_compositeTransformed` consume the buffer exactly as today (incl. the
mandatory damage clip and the OOB source clamp). The shadow pass reuses the just-refreshed buffer
(automatic per §2 bullet 2).

### 3.5 Optionality (built from day one — it IS the correctness instrument)

- Global kill-switch `WorldWdgt.islandBufferCacheEnabled` (default true; `occlusionCullingEnabled`
  precedent). Runtime-flippable; flipping must be pixel-invisible (a flip may simply drop caches).
- Per-island `cachesBuffer` (default true, plain boolean, serialized like `_materializedBySugar`
  is — or transient; owner has no preference, pick serialized-for-simplicity and say so).
- Cache active ⇔ `world.islandBufferCacheEnabled and @cachesBuffer`. The off path is the current
  code — keep it intact, do not fork logic beyond the one entry check.

### 3.6 Lifecycle (v1 — no budgets)

Buffer dropped: on island destroy/dematerialize (fields die with the widget — but nil them in the
teardown anyway if a teardown hook exists, to release the canvas eagerly); on spec returning to
IDENTITY (the identity composite path bypasses the buffer, so nil it in `_transformChangedNoSettle`
when `isIdentity()` — cheap hygiene, avoids a window-sized canvas lingering on a de-tilted-but-
explicit island); on extent realloc (replaced).

## §4 Execution steps (ordered; ONE unit, gate-green, then commit)

0. **Pre-flight:** re-verify §2 facts (grep symbols); confirm suite baseline green (`fg build` +
   quick dpr1 suite); check whether `docs/profiling/prof-interactive.js` has any rotated-island
   scenario (`grep -n "rotat\|island\|setRotation" docs/profiling/prof-interactive.js`) — it
   predates rotation, expect NO (then step 6 uses the standalone micro-probe).
1. §3.1 state + transients + copy-coherence.
2. §3.2 deposit + §3.6 lifecycle + §3.5 flags.
3. §3.3 refresh-if-dirty.
4. `fg build` green (layering/dead-methods/thin-wraps).
5. **The A/B byte-identity macro** `SystemTest_macroIslandBufferCacheByteIdentity` (value-assert
   ONLY, no screenshots ⇒ no reference dance): build a 25° island with text+box content in the
   empty harness world; hash the canvas (`dataHash` idiom); `world.islandBufferCacheEnabled =
   false`; `fullChanged()`; settle; hash — ASSERT EQUAL. Re-enable; EDIT the text (partial-rebuild
   path); hash; disable; `fullChanged()`; settle; hash — ASSERT EQUAL (the core soundness assert:
   cached partial rebuild == full rebuild). Drag the island (slot move with cached buffer) and
   repeat the flip-compare. Rotate a few steps and repeat. deepCopy the island and assert the
   copy renders correctly and shares no buffer (behaviourally: mutate copy's content, original's
   pixels unchanged). NOTE the flag names must be macro-readable (no `_` prefix on the public
   flags — `islandBufferCacheEnabled`/`cachesBuffer` as specced are fine).
6. **Perf measurement (minified, `?sw=1`):** micro-probe (scratchpad, puppeteer — reuse the
   probe-bug1 skeleton incl. the (0,25) page-offset + empty-world gotchas from memory): a 460×400
   window with text content, 90 × 1° `setRotation` steps; wall-clock per step, cache ON vs OFF.
   Expected: ON ≈ warp-only per step (large win — today each step re-rasterizes the subtree
   twice); record the numbers in §6 of THIS doc and flip the affine plan's §9/§10.9/§10.10
   annotations from "requires §4.4 (banked)" to "TRUE as-built, measured YYYY-MM-DD: <numbers>".
7. **Gates:** `fg gauntlet` (dpr1/dpr2/webkit + apps/paint/tiernaming/settle/capstone) +
   `fg homepage`. **Expected reference deltas: ZERO** (236/236 + the new value-assert macro ⇒ 237;
   a sound cache is pixel-invisible — ANY existing-reference change means the invalidation is
   unsound: FIX, never recapture). The paint-truthfulness leg with the cache ON is itself a
   suite-wide staleness check of the invalidation — treat a paint-leg offender as a §3.2 gap.
8. Commit (source + macro + this doc's results + the affine-plan annotation flips) under the
   grant; update the memory topic (`affine-transforms-plan-authored.md`) with the landing +
   measured numbers. Do NOT push.

**Done-criteria:** gauntlet green ×3 + homepage; zero recaptures; byte-identity macro green at
dpr1+dpr2+webkit; measured speedup recorded; §9/§10.9/§10.10 flipped to as-built+measured;
`grep -n "_refreshIslandBuffer" src/` shows the refresh-if-dirty shape (no unconditional rebuild
on the cache-enabled path).

## §5 Risks / sharp edges

- **Partial-rebuild ghosting** (forgot the `clearRect` → old pixels under alpha) — caught by the
  byte-identity macro's edit case and the paint leg.
- **Deposit misses a lane** (a content mutation whose damage never crosses `mapRectToScreen`) —
  the paint-audit leg is the suite-wide net; if it fires, find the lane, don't widen dirty-all.
- **Copy/serialization of the new fields** — §3.1; the failure mode is a SHARED canvas between
  copies (assert behaviourally, step 5).
- **Nested islands** — inner island's composite runs while painting the outer buffer
  (`paintingIntoIslandBuffer` nesting); the inner island's OWN cache works identically (its
  dirty deposits come from the same walk). Include one nested case in the macro if cheap;
  otherwise note it as covered by existing nested macros + the flip-compare.

## §6 Results (EXECUTED 2026-07-11)

**LANDED. The design claim ("transform animation never re-rasterizes content") is now TRUE as-built.**

- **Perf micro-probe** (`scratchpad/prof-island-cache.js`, sw=1, a 460×400 text window, 90 × 1° setRotation,
  in-page synchronous doOneCycle timing so rAF can't dilute): **cache ON median 6.0ms / cache OFF median
  8.4ms ⇒ 1.40× per step** (mean 1.42×). The win is the eliminated re-rasterisation; the SW warp itself
  dominates the per-step cost (§10.10 cost ladder), so the speedup is bounded by the raster fraction (~30%
  here) — larger for heavier content subtrees. The design claim is now TRUE regardless of magnitude.
- **Byte-identity A/B macro** `SystemTest_macroIslandBufferCacheByteIdentity` (deterministic box fixture):
  all 7 cache paths byte-identical (reuse, in-place partial rebuild, move-within-island source-erase,
  island-drag slot move, rotation warp, deepCopy no-shared-buffer, per-island opt-out) at dpr1 + dpr2.
- **Gauntlet**: `GAUNTLET OK — dpr1:PASS dpr2:PASS webkit:PASS apps:PASS paint:PASS tiernaming:PASS settle:PASS capstone:PASS` + `fg homepage` BOOT OK (suite 236→237, +1 macro);
  only reference delta = the pre-authorized benign inspector recapture (`macroDuplicatedInspectorDrivesCopiedTargetOnly`,
  image_1 byte-identical) — the 2 new `_islandBufferSource*` Widget fields shift the inspector Properties list.

**Two bugs the byte-identity A/B / gauntlet caught (both FIXED):**
1. **Doubled shadow / over-hang under partial rebuild** — a child's shadow (painted via a ctx translate)
   escaped the `clippingRectangle` *hint* and repainted over the un-cleared old pixels. FIX: a HARD ctx clip
   (`clipToRectangle`) to the cleared dirty rect in `_rasterizeIslandContent` — nothing can paint outside it.
2. **⚠ ASYNC GLYPH-ATLAS FREEZE (the important one; owner-flagged)** — SWCanvas loads glyph atlases
   asynchronously; text rasterises as solid BLOCKS into cached text back buffers until the atlas arrives,
   and the render silently changes (block → glyphs) with NO `changed()`/deposit event (a resource load, not
   a widget mutation), so an event-driven cache can't see it. The island buffer is a cache DOWNSTREAM of
   those text back buffers, so it froze the pre-atlas black-block render — visible as a black blob replacing
   rotated "PLOT". FIX: when an atlas warms, SWCanvas already resets the immutable text-back-buffer cache
   (`swCanvasScheduleTextRefresh` → `resetImmutableBackBuffersCache` + `fullChanged`; the macro screenshot
   gate does the same); that reset now ALSO bumps `WorldWdgt.immutableBackBufferGeneration`, and a
   TransformFrameWdgt full-rebuilds when its stored epoch is stale → it rebuilds from the now-warm text.
   Native never loads an atlas ⇒ epoch never bumps ⇒ zero effect. ⚠ **A first attempt gated on
   `world.anyTextDirty()` instead — it fixed Chrome but FLIPPED WebKit to failing** (the dirty→clean flag
   transition and the text-back-buffer re-render are not co-timed across engines; the epoch tied to the
   actual cache RESET is co-timed with the warm render, so it is engine-consistent — verified Chrome+WebKit).
   **Lesson banked: an island-cached render that changes across composites without a changed() (async
   resource load) must invalidate off the SAME signal that reloads the upstream cache, not off a
   liveness flag whose transition races the re-render.**
- Commit hashes: Fizzygum `17803fc0` (7 files +519/-43), tests `50b240814` (18 files +189/-4);
  **PUSHED to origin/master** (owner-approved 2026-07-11). ⚠ the Fizzygum commit also carries a
  PRE-EXISTING §7.4 "quantized density" refinement hunk in `affine-transforms-plan.md` (authored in a
  prior session) — owner decided 2026-07-11 to KEEP it folded (it is affine-plan doc content).
