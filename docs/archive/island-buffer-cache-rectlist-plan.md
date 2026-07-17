> **ARCHIVED — COMPLETE (2026-07-17 restructure).** LANDED + PUSHED 2026-07-11 (Fizzygum d845a79f).
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Island buffer cache — §4.4 rect-list dirty refinement (v1 → v2)

**STATUS: ✅ LANDED + PUSHED 2026-07-11 (owner-approved) — Fizzygum `d845a79f`, tests `88b2c7d4e` (design
LOCKED + executed; results in §6). Phase-5 follow-on to the landed island buffer cache
(`docs/archive/island-buffer-cache-plan.md`, Fizzygum `17803fc0`). Owner picked this next 2026-07-11.
Self-contained + cold-executable. Line numbers verified 2026-07-11 and WILL drift — every anchor has a
symbol; grep the symbol, scoped to `src/` (never the workspace root).**

This is a small, contained data-structure upgrade to the shipped cache: the invalidation state goes from
ONE merged bounding rect to a small **rect-list**, so a frame that edits two (or more) far-apart regions
rebuilds only the touched sub-rects instead of the whole bounding box that spans them. Nothing else about
the cache changes.

---

## §1 Goal and non-goals

**Goal:** when multiple disjoint content regions are damaged in one frame, the island's partial rebuild
touches only those regions, not their bounding box. Concretely, `_islandBufferDirtyRect` becomes a list of
(coalesced, disjoint) rects instead of a single merged rect; `_refreshIslandBuffer` clears+repaints each.

**This must stay pixel-invisible AND never cost more than v1.** Byte-identity to the rebuild-every-composite
path remains THE gate (the existing on/off A/B macro, extended with a multi-region case). A hard cost ceiling
(§3.4 degrade guards) guarantees the worst case collapses back to v1's single-bbox behaviour.

**Non-goals (do not creep):**
- §4.2 warp-sub-rect composite optimisation (composite still warps the whole buffer under the damage clip).
- §7.1 layer-policy / vector-replay, §7.2 leaf self-warp, §7.3 quad damage — separate items.
- Per-rect **dirty tracking across frames** / retained damage history — the list is rebuilt from deposits
  each frame and cleared at refresh, exactly as v1's single rect is. No persistence.
- Memory budgets / eviction — unchanged from v1 §3.6.
- A rect-list on the COMPOSITE side (the shadow/normal passes still consume one buffer canvas as today).

## §2 As-built facts this refinement changes (verified 2026-07-11; grep the symbols)

All anchors are in `src/TransformFrameWdgt.coffee` unless noted.

- **The field** `_islandBufferDirtyRect` (declared ~L58) is today `nil` (clean) | `Rectangle` (ONE merged
  bounding rect, VIRTUAL coords) | the sentinel `"all"`. It is listed in `@serializationTransients` (~L76)
  and nil'd by `_dropIslandBuffer` (~L202) and (via that) `_reactToBeingCopied` (~L214). **It is a transient
  render-derived field — changing its runtime TYPE from Rectangle to Array is internal only; nothing
  serialises it and nothing else reads it.**
- **Deposit** `_depositIslandBufferDirtyRect: (aRect)` (~L318): guards (inactive / `"all"` / empty) → grows
  `dirty = aRect.expandBy(1).growBy world.maxShadowSize` (the SAME grow the screen flesh-out lane uses:
  covers the changed child's own drop-shadow + 1px AA fringe — KEEP IT) → `merge`s it into the single field.
  Called from exactly THREE sites, each passing ONE rect: `Widget.coffee:1288`
  (`mapRectToScreen` destination deposit, gated by `depositBufferDirty`) and `WorldWdgt.coffee:923` + `:982`
  (the two flesh-out **source** lanes). ⇒ ALL list-building is self-contained inside the deposit method;
  the callers are untouched.
- **Refresh** `_refreshIslandBuffer` (~L342): the full-rebuild path (no buffer / slot-extent realloc / stale
  `_islandBufferGeneration` epoch — the async-atlas invalidation, LEAVE IT) is unchanged. The dirty branch
  (~L363) today computes ONE `clip = ("all" ? slot : dirtyRect.intersect slot)` and calls
  `_rasterizeIslandContent slot, physExtent, clip` once, then nils the field.
- **Per-rect rasterise** `_rasterizeIslandContent: (slot, physExtent, clip)` (~L378): `clip?` ⇒ PARTIAL —
  into the kept `@_islandBuffer`: `bctx.save` → translate `-slotOrigin×ceilPixelRatio` → **`clearRect`** the
  clip (device px) → **HARD `bctx.clipToRectangle`** the clip (load-bearing: `clippingRectangle` is only a
  culling hint, so a child shadow/over-hang escapes it and doubles over un-cleared pixels — the v1 bug-1 fix)
  → walk `@children` painting clipped → `restore`. `clip` nil ⇒ FULL into a FRESH canvas. **This method
  already does exactly one correct, byte-identical-to-full clear+clip+repaint of ONE rect.** The refinement
  reuses it verbatim, once per rect — no change to this method.
- **The flags** precedent: `WorldWdgt.islandBufferCacheEnabled` (class prop, `WorldWdgt.coffee:227`) is the
  global on/off; `TransformFrameWdgt::cachesBuffer` the per-island opt-out; `_islandBufferCacheActive`
  (~L310) = both. The refinement adds ONE more class-prop A/B flag alongside (§3.5).
- **`Rectangle` API** (`src/basic-data-structures/Rectangle.coffee`): `merge(r)` = bounding union
  (handles EMPTY operands); `intersect(r)` = intersection (or EMPTY); `isIntersecting(r)` = boolean, **edge-
  inclusive** (`>=`/`<=`, so touching rects count as intersecting — good, adjacency coalesces); `area()`;
  `containsRectangle(r)`; `isEmpty()`/`isNotEmpty()`.

## §3 Design (LOCKED — 2026-07-11)

### 3.0 The one correctness invariant (why this is cost-only, not correctness-risky)

**Coverage invariant:** at all times `union(_islandBufferDirtyRect) ⊇ union(every grown damage rect
deposited since the last refresh)`. Every list mutation below only ENLARGES coverage (append a rect; replace
a subset by their bounding union; collapse the whole list to its bounding box; promote to `"all"`), so the
invariant holds after each. Because each grown damage rect already ⊇ (its child's bounds + shadow + AA
fringe) — v1's unchanged deposit contract — and the refresh clears+HARD-clips+repaints exactly the covered
region, the partial rebuild is byte-identical to a full rebuild **for any policy that respects the
invariant**. The rect-list only chooses WHICH superset of the damage to rebuild, never whether it is covered.
This is the backbone; the byte-identity macro (§4) is its executable proof.

### 3.1 Field type

`_islandBufferDirtyRect`: `nil` (clean) | `Array<Rectangle>` (1+ coalesced DISJOINT rects, VIRTUAL coords) |
`"all"` (sentinel, unchanged). Update the declaration comment (~L58) and the `@serializationTransients`
comment block (~L68) to say "rect-list". No serialization or copy change — it is transient and nil'd on drop.

### 3.2 Deposit → coalesce into a disjoint list

Rewrite `_depositIslandBufferDirtyRect`:
- Guards + grow: **unchanged** (inactive / `"all"` / empty → return; `dirty = aRect.expandBy(1).growBy
  world.maxShadowSize`).
- `!@_islandBufferDirtyRect?` (clean) → `@_islandBufferDirtyRect = [dirty]`; return.
- Else (array): **merge `dirty` with every rect it `isIntersecting`, to a fixpoint** (a merge grows `dirty`
  and may make it touch previously-untouched rects), keeping the non-touching rects; push the fully-grown
  `dirty`. The result is a DISJOINT set (no two rects touch). Then pass it through `_coalesceDirtyList`
  (§3.4) and store.

```coffee
_depositIslandBufferDirtyRect: (aRect) ->
  return if !@_islandBufferCacheActive()
  return if @_islandBufferDirtyRect == "all"
  return if !aRect? or aRect.isEmpty()
  dirty = aRect.expandBy(1).growBy world.maxShadowSize
  if !@_islandBufferDirtyRect?
    @_islandBufferDirtyRect = [dirty]
    return
  remainder = @_islandBufferDirtyRect
  loop                                   # fold every touching rect into `dirty`; repeat until none touch
    touching = (r for r in remainder when dirty.isIntersecting r)
    break if touching.length == 0
    remainder = (r for r in remainder when not dirty.isIntersecting r)
    dirty = touching.reduce ((acc, r) -> acc.merge r), dirty
  remainder.push dirty
  @_islandBufferDirtyRect = @_coalesceDirtyList remainder
```

Zero dormant cost: the walk still early-returns off-island; a clean island never enters here.

### 3.3 Refresh → clear+repaint each rect

In `_refreshIslandBuffer`, replace the single-clip dirty branch with a loop; the `"all"` sentinel keeps its
whole-slot rebuild; each rect reuses `_rasterizeIslandContent` verbatim (its per-rect clear+HARD-clip+repaint
is already the proven byte-identical path):

```coffee
  else if @_islandBufferDirtyRect?
    if @_islandBufferDirtyRect == "all"
      @_rasterizeIslandContent slot, physExtent, slot
    else
      for dirtyRect in @_islandBufferDirtyRect
        clip = dirtyRect.intersect slot
        @_rasterizeIslandContent slot, physExtent, clip if clip.isNotEmpty()
  @_islandBufferDirtyRect = nil
```

`_rasterizeIslandContent` and both composite paths are **unchanged**. N rects = N clipped subtree walks
(each culls non-intersecting children); §3.4 caps N so this never regresses.

### 3.4 Coalesce / degrade guards (the cost ceiling)

`_coalesceDirtyList(list)` (list already disjoint, ≥1) returns the list to store. It NEVER shrinks coverage
(§3.0), only trades separate rects for their bounding box:

```coffee
_coalesceDirtyList: (list) ->
  # A/B instrument (§3.5): force v1's single-bbox policy when the rect-list is disabled.
  return [@_boundingBoxOfRects list] if !WorldWdgt.dirtyRectListEnabled
  bbox = @_boundingBoxOfRects list
  # Primary ceiling: too many rects ⇒ N clipped walks cost more than one bbox walk.
  return [bbox] if list.length > TransformFrameWdgt.ISLAND_DIRTY_MAX_RECTS
  # Secondary: the rects already cover most of their bounding box ⇒ one bbox walk is as cheap.
  totalArea = list.reduce ((a, r) -> a + r.area()), 0
  return [bbox] if totalArea >= TransformFrameWdgt.ISLAND_DIRTY_AREA_FRACTION * bbox.area()
  list

_boundingBoxOfRects: (list) ->
  list.reduce ((acc, r) -> acc.merge r), list[0]
```

Constants (TransformFrameWdgt class props, documented + tunable):
- `@ISLAND_DIRTY_MAX_RECTS: 8` — max separate rects before collapsing to the bounding box.
- `@ISLAND_DIRTY_AREA_FRACTION: 0.75` — collapse when the union area reaches this fraction of the bbox area.

Rationale: with `dirtyRectListEnabled = false` the field always holds exactly `[oneBbox]` — byte-for-byte
v1's single-rect behaviour and a clean A/B baseline. Both guards keep v2's worst case ≤ v1 (one bbox walk).

### 3.5 A/B flag (built from day one — the correctness + perf instrument)

`WorldWdgt.dirtyRectListEnabled` (class prop, default `true`; sits beside `@islandBufferCacheEnabled`).
When `false`, `_coalesceDirtyList` collapses to one bbox (= v1 policy). Purpose: (a) the byte-identity macro
asserts the rect-list policy and the bbox policy produce IDENTICAL pixels on the same multi-region fixture
(a strong soundness check independent of the cache-off baseline); (b) the perf probe flips it to measure the
multi-region win. Runtime-flippable; a flip is pixel-invisible (both policies respect §3.0).

### 3.6 Serialization / copy / lifecycle — UNCHANGED

No new instance fields (the field is reused; the two constants + the flag are class props). `_dropIslandBuffer`
already nils the field (nil is a valid Array-typed clean value). deepCopy still drops via `_reactToBeingCopied`.
**⇒ the inspector member list does NOT change ⇒ expected reference recaptures: ZERO** (contrast v1, whose two
new `_islandBufferSource*` Widget fields forced the one benign inspector recapture).

## §4 Execution steps (ordered; ONE unit, gate-green, then commit under the grant — do NOT push)

0. **Pre-flight:** re-grep the §2 symbols to confirm line drift; confirm the suite baseline is green (it is —
   just landed). Reuse `scratchpad/prof-island-cache.js` as the perf-probe skeleton.
1. **Source** — `TransformFrameWdgt.coffee`: field-type comment (§3.1); the two class constants (§3.4);
   rewrite `_depositIslandBufferDirtyRect` (§3.2); add `_coalesceDirtyList` + `_boundingBoxOfRects` (§3.4);
   rewrite the refresh dirty branch (§3.3). `WorldWdgt.coffee`: add `@dirtyRectListEnabled: true` + comment
   beside `@islandBufferCacheEnabled` (§3.5).
2. **Build** — `fg build` green (layering / dead-methods / thin-wraps / syntax).
3. **Extend the macro** `SystemTest_macroIslandBufferCacheByteIdentity` (keep all 7 existing cases; the box
   fixture already has two far-apart boxes — after the `.growBy maxShadowSize` grow they are DISJOINT, so a
   single-step two-colour edit yields a 2-rect list):
   - **CASE 8 — MULTI-REGION EDIT (the rect-list path):** recolour BOTH boxes in one macro step (no `yield`
     between) ⇒ two deposits ⇒ 2 disjoint dirty rects ⇒ a 2-rect partial rebuild. `world.fullChanged()`;
     capture cache-ON; flip `islandBufferCacheEnabled=false`; `fullChanged()`; capture; assert `pixelDiff==0`.
   - **CASE 9 — POLICY A/B (rect-list == bbox):** recolour both boxes again; capture with
     `dirtyRectListEnabled=true` (rect-list); capture with `=false` (bbox); assert `pixelDiff==0` (both also
     equal the cache-off baseline transitively). Restore the flag to `true` at the end.
   - Macro rules: value-assert only (no screenshots — a forced full repaint would mask the partial rebuild);
     read `world.worldCanvasContext.getImageData` directly (the existing idiom); the flags are public
     (`islandBufferCacheEnabled` / `dirtyRectListEnabled` / `cachesBuffer`) so macro-readable — do NOT read
     the `_`-prefixed `_islandBufferDirtyRect`.
4. **Run the macro** headless dpr1 (`fg test SystemTest_macroIslandBufferCacheByteIdentity --dpr=1`) then
   dpr2 — all 9 cases green.
5. **Perf probe** (`scratchpad/prof-island-rectlist.js`, minified `?sw=1`): a LARGE island (~600×500)
   holding a grid of small boxes (e.g. 6×6); per frame recolour the top-left and bottom-right box; measure
   composite wall-clock per frame with `dirtyRectListEnabled` ON vs OFF (in-page synchronous `doOneCycle`
   loop so rAF can't dilute — the prof-island-cache pattern). Expected: ON rebuilds 2 small rects, OFF the
   spanning bbox (≈ the whole grid) ⇒ a win scaling with (bbox area / union area). Record numbers in §6.
6. **Gates** — `fg gauntlet` (dpr1/dpr2/webkit + apps/paint/tiernaming/settle/capstone) + `fg homepage`,
   run in the BACKGROUND with no concurrent browser commands. **Expected reference deltas: ZERO** (suite
   237 → 237; a sound cache is pixel-invisible AND no new inspector fields ⇒ no recapture — ANY reference
   change means an unsound coalesce: FIX, never recapture). The paint-truthfulness leg with the cache ON is
   the suite-wide staleness net for the new deposit path.
7. **Docs** — fill §6 here; flip the "rect-list … banked" notes in `docs/archive/island-buffer-cache-plan.md` (§3.2
   ~L88 + the code-comment note) and the affine-plan §7/§4.4 pointer to "LANDED (see
   island-buffer-cache-rectlist-plan.md)". Update the memory topic.
8. **Commit** (source + macro + this doc + the pointer flips) under the standing grant. **Do NOT push**
   (needs owner approval).

**Done-criteria:** `fg gauntlet` green ×3 + homepage; ZERO recaptures; the extended byte-identity macro
green at dpr1+dpr2 (9 cases); the multi-region win recorded in §6; `grep -n "_coalesceDirtyList"
src/TransformFrameWdgt.coffee` shows the degrade guards; `_islandBufferDirtyRect` is an Array on the dirty
path.

## §5 Risks / sharp edges

- **A missed coalesce that shrinks coverage** would break byte-identity — but every operation here only
  merges/collapses (enlarges), and the macro's CASE 8 (two disjoint rects rebuilt, region between them left
  intact) + the suite's paint leg are the net. If CASE 8 fails, the coalesce dropped coverage — fix the set
  logic, do NOT widen to dirty-all silently.
- **Overlapping rects double-repaint** — the disjoint-merge invariant prevents it; even if a bug left an
  overlap, the result is still CORRECT (each clipped repaint is a full correct repaint of its region), only
  wasteful. So an overlap is a perf smell, never a correctness bug.
- **Cost regression on scattered damage** — the count-cap + area-fraction guards collapse to v1's single
  bbox, so worst case ≤ v1. The perf probe's ON-vs-OFF confirms no regression on the dense/scatter case
  (they should converge to equal when the guards fire).
- **A child straddling two disjoint rects** paints (clipped) in both — correct (each paint is full+clipped),
  bounded. Not a concern.
- **`world.fullChanged()` in the macro** does not force a full ISLAND rebuild (it sets the world repaint
  scope, not `_islandBufferDirtyRect`); CASE 2 already relies on this to exercise the partial path. The perf
  probe is the definitive proof the 2-rect path is actually taken (it measures the eliminated work).

## §6 Results (EXECUTED 2026-07-11)

- **Byte-identity macro** `SystemTest_macroIslandBufferCacheByteIdentity` — extended to 11 assertions (the
  7 v1 cache paths + CASE 8 MULTI-REGION EDIT + CASE 9 COLLAPSE POLICY). ALL PASS at dpr1 AND dpr2:
  `MULTI-REGION EDIT: two disjoint dirty rects rebuilt == cache-off full rebuild` = 0 diff;
  `COLLAPSE POLICY (dirtyRectListEnabled=off): single-bbox partial rebuild == full rebuild` = 0 diff. ⇒ the
  rect-list rebuild AND the collapsed-bbox path are both byte-identical to the full rebuild (the coverage
  invariant §3.0 holds as-built).
- **Perf micro-probe** (`scratchpad/prof-island-rectlist.js`, sw=1, 90 frames; recolour the top-left +
  bottom-right box of a 6×6 grid in a 25° 600×500 island; in-page synchronous doOneCycle timing):
  **rect-list ON median 0.80ms / OFF (bbox) median 2.20ms ⇒ 2.75× per frame** (mean 2.68×). The win is the
  eliminated re-rasterisation of the ~34 boxes between the two edited corners (the bbox policy rebuilds the
  whole grid; the rect-list rebuilds only the 2 dirty boxes). Scales with (bbox area / union area).
- **Gauntlet**: `GAUNTLET OK — dpr1:PASS dpr2:PASS webkit:PASS apps:PASS paint:PASS tiernaming:PASS
  settle:PASS capstone:PASS` (suite 237, 0 failed on every leg) + `fg homepage` BOOT OK.

**No new instance fields ⇒ reference recaptures ZERO** (confirmed: 0 failed tests on every gauntlet leg;
contrast v1's benign inspector recapture). The paint-truthfulness leg with the cache ON is the suite-wide
staleness net for the new multi-rect deposit path — it passed clean.
