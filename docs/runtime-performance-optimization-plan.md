# Runtime performance — measured profile & ranked optimization plan

**Status**: AUTHORED 2026-07-07 from a full profiling campaign of the live system.
**Progress**: H1 ✅ landed (2026-07-08). **Arc 2 (2026-07-08): F2 + S1 + S6a + S5 ✅ landed** —
full `fg gauntlet` green (build + dpr1/dpr2/webkit 196/196 each + apps + paint-truthfulness +
tiernaming/settle/capstone gates) **and** `fg homepage` native boot-smoke green; **zero reference
churn** (byte-identical, cross-engine). Remaining: S2, S3, S4, S6b, F1, F3. See §8 ledger + §7.
**⚠️ Verified-fact correction (2026-07-08):** S1's headline "−33% busy / −8.3% wall" is an artifact
of the **unminified profiling build only** — the shipped build strips the log via minification and
never pays it. See the S1 section in §5 and the methodology note below. This does NOT affect any
other item: §4.3's log-stripped profile is exactly the shipped build's cost profile, so S2–S6/F1/F2
remain ranked against the correct baseline.
**Scope**: Fizzygum runtime + vendored SWCanvas + SystemTest harness.
**Provenance of every number**: measured on this workspace on 2026-07-07 — build of 12:25
(framework `6f6c834e` + the then-uncommitted WorldWdgt edit; SWCanvas repo HEAD `f463993`,
vendored pin in `vendor/swcanvas.pin`), full 190-test SystemTest suite headless
(Puppeteer Chrome, 1100×800 viewport, `?sw=1&speed=fastest&intro=0`, ONE browser per run,
runs strictly serial for profile purity). **Every instrumented, profiled, and A/B run passed
190/190** — the measurement stack is pixel-transparent, and test verdicts are raw-pixel
SHA-256 matches, so a passing A/B is also a byte-identical-pixels proof.

**Reproduction**: the complete harness lives in [`docs/profiling/`](profiling/README.md)
(counter instrumentation, CPU profiler driver, aggregators, shadow-build assembler). One
command sequence per measurement is in that README.

**Companion doc**: `'/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas/plans/clipping-optimization.md'`
— the SWCanvas-repo clipping plan. Its §8 asked for exactly the workload instrumentation
performed here, and §8.5 there now records these results. Item S3 below is "execute that plan".

---

## 1. Executive summary

At dpr1 the suite burns **128.0s of CPU over 374s wall** (34% busy; the rest is vsync idle —
the harness runs at ~57fps and dpr1 wall time is *frame-count*-bound). At dpr2 it burns
**292.3s over 479s wall** (61% busy; **17.4ms average CPU per painted frame exceeds the
16.7ms frame budget**, so at dpr2 — and on any slower machine, and in real interactive use —
CPU cuts convert ~1:1 into wall/latency wins).

Where busy CPU goes (self time; "busy" = idle/program excluded):

| Consumer | dpr1 %busy | dpr2 %busy |
|---|---|---|
| SWCanvas total | 71.4% | 63.6% |
| — drawImage pipeline | 38.4% | 24.0% |
| — — of which the per-call debug `console.log` | ≈33% | ≈12% |
| — polygon-fill + span machinery | 11.6% | 13.9% |
| — clip-mask reads (`_getBit`) | 6.4% | 10.3% |
| — blend + Color object churn | 8.3% | 8.8% |
| — clip-mask build | 2.6% | 2.8% |
| Harness SHA-256 screenshot hashing | 6.9% | **24.7%** |
| Fizzygum framework proper | ≈12% | ≈5% |
| GC | 6.2% | 4.8% |

### The ranked list

| # | Item | Repo | Measured basis | Expected win (busy CPU) | Effort | Risk |
|---|---|---|---|---|---|---|
| **S1** ✅ | Delete the per-call debug `console.log` in `Context2D.drawImage` | SWCanvas | A/B −33% busy @dpr1 **on the UNMINIFIED build only** — shipped build minifies the log away (see §2 caveat) | **shipped: ~0** (hygiene + honest profiles) | trivial | none |
| **H1** | SHA-256 screenshot hashing → `crypto.subtle.digest` (same digest) | Fizzygum-tests | 6.9% dpr1 / 24.7% dpr2 busy; impl also makes 2 full-buffer copies per hash | most of that back | medium | low |
| **S2** | drawImage fast path: hoist per-call invariants; axis-aligned 1:1 source-over row loop; kill per-pixel allocations | SWCanvas | `_drawImageInternal` 12.4% busy post-S1; 662,474 calls/suite, avg 1,163px, all unclipped | ~8–11% | medium | medium (byte-identical gate) |
| **S3** | Tier-0 rectangular clipping — execute the SWCanvas clipping plan §9 | SWCanvas | clip build 2.6–2.8% + reads 6.4–10.3% + span detours; **76,675 clips/suite, 100.000% axis-aligned integer rects** | ~10–18% | large | medium |
| **S4** | `blendPixel`: composite-op specialization, no per-pixel result object | SWCanvas | blendPixel 5.8% busy post-S1 + feeds 4.8–7.2% GC | ~4–6% (+GC) | small-med | medium (byte-identical gate) |
| **F2** ✅ | Cache `WorldWdgt.getCanvasPosition` (forced reflow per synthesized mouse event) | Fizzygum | **5.8% busy post-S1** (single method!) — landed 2026-07-08, gauntlet+homepage green | ~5% (mostly suite CPU) | small | low |
| **S5** ✅ | Hoist `_evaluatePaintSource` out of per-pixel span loops for solid colors | SWCanvas | 4.3% busy post-S1 — landed 2026-07-08 (span-level memoize; byte-identical, gauntlet green) | ~3–5% | small | low |
| **F1** | Boot the test harness from a pre-compiled image | Fizzygum | boot = 3.5–3.7s/page in-browser compile; `js/pre-compiled.js` in normal builds is a 257-byte stub | ~2.5–3s × every page × every shard × every gauntlet leg | medium | medium |
| **S6a** ✅ | `_requiresCanvasWideCompositing` allocated a fresh array + `.includes` per op → module-const `Set` | SWCanvas | landed 2026-07-08 (byte-identical, gauntlet green) | ~1% | small | low |
| **S6b/c** | `withGlobalAlpha` identity fast-path (⚠ premultiplied-rounding risk — deferred); investigate 0.7–1.3% `_performCanvasWideCompositing` (likely profiler misattribution — Fizzygum never sets a canvas-wide op) | SWCanvas | ~1% combined | small | med (S6b) |
| **F3** | Dirty-rect DOM present in `blitRenderCanvasToDOM` | Fizzygum | measured only 0.3% busy headless — **deprioritized by measurement** | headless ~0; real browsers unknown | small | low |

S1's A/B (suite wall 374s→343s at frame-bound dpr1, busy CPU 128.0s→86.1s) was measured on the
**unminified** build; the shipped build already sits at that 86.1s post-S1 state (minification
strips the log), so S1 lands as source hygiene, not a shipped speedup (§2 caveat, S1 in §5).
Stacking H1+S2+S4+S5+F2 (+the landed S6a) addresses ≈60% of dpr1 busy and ≈70% of dpr2 busy
**before** the larger S3 clipping work. Detailed items in §5; measured evidence in §3–4;
verification protocol in §6; sequencing in §7.

---

## 2. How the measurements were made (short form)

- **Workload counters**: page-side wrappers (installed pre-boot, counting only, arguments
  untouched) on both the native `CanvasRenderingContext2D` prototype and SWCanvas's compat
  context prototype. Classify every `clip()` (axis-aligned-integer-rect? rotated CTM? nested?
  clip-bbox/surface ratio) and partition every draw call by the *effective* clip kind
  (none / rect-only / mask). Full suite, real (minified) build.
- **CPU profiles**: CDP `Profiler` sampling (300µs dpr1 / 500µs dpr2), started AFTER boot,
  over the full suite in one page, on an unminified **shadow build**
  (`docs/profiling/mk-shadow-build.sh`) so SWCanvas frames carry real names; eval'd
  meta-compiled classes are attributed via `Debugger.getScriptSource` (one eval per class)
  down to `Class.method` granularity.
- **A/B**: identical shadow builds ± one change, full suite, no profiler, wall-clock compared;
  190/190 green on both sides doubles as the pixels-unchanged proof.
- Boot measured separately with `--profile-boot` (profiling from navigation to world-ready).

Known instrument caveat: the counter harness's transform tracker misses `canvas.width=`
transform resets, so cumulative 'areas' sums drift at dpr2 (a resize-heavy run) — all
point-classified stats (clip kinds, call counts, per-call areas at dpr1) are unaffected.

**Minification caveat (added 2026-07-08, important for S1):** the CPU profiles run on the
**unminified** shadow build (`mk-shadow-build.sh` appends `vendor/swcanvas/swcanvas.js`) so
SWCanvas frames carry real names. The **shipped** build concatenates `swcanvas.min.js`, produced
by SWCanvas `minify.sh` with terser `--compress drop_console=true,…,pure_funcs=['console.log',…]`.
That is an *entirely different code path for anything terser removes*: the drawImage debug
`console.log` (S1) is **deleted outright by minification**, so it costs nothing in the shipped
build, the real `?sw=1` runtime, or `fg gauntlet` — its measured cost lives only in the profiled
unminified build. This is unique to code minification *removes*; ordinary hot-loop functions are
renamed/inlined, not deleted, so their profiled costs remain a faithful proxy. Net consequence:
treat §4.1/§4.2's raw drawImage self-time as inflated by the log, and use **§4.3 (log-stripped) as
the shipped-cost baseline** — which is exactly how every non-S1 item is already ranked.

---

## 3. Measured workload (full suite, sw=1, dpr1; dpr2 in parentheses where it differs)

The world under `?sw=1` renders entirely into one SWCanvas surface (1100×800 phys @dpr1),
presented to the DOM canvas once per changed frame via `putImageData` (6,498 presents).

**Clipping — the numbers the SWCanvas plan §8 asked for:**
- `clip()` calls: **76,675 (62,344 @dpr2) — 100.000% axis-aligned INTEGER rectangles.**
  Zero non-rect paths, zero clips under a rotated CTM, zero nested clips.
- Clip size: 71% of clips cover ≤1% of the surface; 82% ≤5%; mean 3.4%.
- `save()`: 382,794 total; **12,494 with a live clip mask** — each of those deep-clones a
  full-surface BitBuffer today (110KB @dpr1 / 440KB @dpr2).
- Draw calls under an active clip: `stroke` 124,543 · `fill` 54,163 · `fillText` 23,507 ·
  `strokeRect` 19,907 · `fillRect` 5,080 — **all of them under rect-only clips; ZERO under a
  genuine (non-rect) mask.**
- Derived: ≈2.27 **billion** `setPixel` calls per suite run just writing clip masks
  (Σ clip-bbox pixels), plus a full-surface AND per nested intersect (none occur) and a
  full-surface clone per save-under-clip.

**Draw volumes (whole suite):** `fillRect` 1,381,877 (avg 1,358 px) · `drawImage` 662,474
(avg 1,163 px — small back-buffer blits; **every one currently fires the debug console.log**)
· `stroke` 124,949 · `fillText` 61,973 · `clearRect` 56,000 · `fill` 54,163 ·
`measureText` 35,398 · back-buffer canvases created 19,397 (323M px).

**Frames:** 19,412 painted cycles (56.9/s — vsync-paced), 24,743 broken-rect repaint walks,
896M px cumulative broken area (avg ≈36k px per broken rect).

**Boot:** 3.5–3.7s per page = in-browser CoffeeScript compilation of ~470 classes + harness
(the shipped `js/pre-compiled.js` is a 257-byte stub in non-homepage builds; nothing is
pre-compiled for the test harness). Every suite shard pays it; `fg gauntlet` pays it
~9 shards × 4 legs ≈ 36 times.

---

## 4. Measured CPU profiles

### 4.1 Full suite, sw=1 dpr1, WITH the drawImage log (the shipped state)

Wall 374s; busy 128.0s (34.2%). Buckets (% of busy): SWCanvas 71.4 · framework-proper ≈12 ·
SHA-256 6.9 · gc 6.2 · harness-UI/other ≈2 · compiler 0.5.

SWCanvas subsystems (% of busy): drawImage pipeline **38.4** (compat/core `drawImage` SELF
30.2 — the log; `_drawImageInternal` 8.1) · polygon-fill+span 11.6 (`_fillPixelSpan` 5.9,
`_fillPolygonsDirect` 2.8, `fill_AA_Alpha`, `_fillScanline`, `_evaluatePaintSource`) ·
blend+color 8.3 (`blendPixel` 3.9 + SWCanvas `Color` ctor/getters ≈3) · clip-mask read
(`_getBit`) 6.4 · clip-mask build 2.6 (`fillPolygonsToClipMask`, per-pixel `setPixel`,
`BitBuffer` ctor) · canvas-wide compositing 0.7.

### 4.2 Full suite, sw=1 dpr2 (500µs sampling)

Wall 479s; busy 292.3s (61.0% — **CPU-bound**). SWCanvas 63.6% busy; **SHA-256 24.7% busy
(72.3s — the single hottest function**: every screenshot hashes 14.08MB of raw pixels).
drawImage pipeline 24.0 (log-self 12.4 + inner loop 11.6 — the loop scales ×4 with pixels,
the log doesn't) · polygon-fill+span 13.9 · clip-mask read 10.3 · blend+color 8.8 ·
clip-mask build 2.8 · compositing-wide 1.3.

### 4.3 Full suite on the log-stripped build (= the post-S1 world), dpr1, method-level

Busy **86.1s** (vs 128.0s ⇒ the log was ≈42s ≈ 33% of busy). Top self (% of busy):
`_drawImageInternal` 12.4 · `SHA256.hashBytes` 10.3 · `_getBit` 9.6 · `_fillPixelSpan` 7.3 ·
gc 7.2 · `blendPixel` 5.8 · **`WorldWdgt.getCanvasPosition` 5.8** · `_evaluatePaintSource` 4.3 ·
`_fillPolygonsDirect` 4.3 · `fillPolygonsToClipMask` 3.2 · `ActivePointerWdgt.processMouseMove`
1.7 · `WorldWdgt._resetWorldNoSettle` 1.7 (per-test resets) ·
`SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole` 0.9 ·
`TextWdgt.breakTextIntoLines` 0.5. Totals: `doOneCycle` 79.3s, of which `updateBroken`
(the paint pass) 51.2s — painting dominates the cycle; layout/dataflow/events are minor.

### 4.4 Boot profile (single page)

Boot wall 3.7s; ≈1.0–1.5s CoffeeScript compiler CPU (parse/compileNode/compileToFragments)
plus class eval + regex dependency scan; the rest is script loading/eval pacing. (The
compiler also appears mid-suite in small amounts: each macro test compiles its
`mainMacroSource` at test start.)

### 4.5 A/B: S1 log removal (no profiler, full suite each side, both 190/190)

dpr1: 374s → 343s wall (−8.3% at a frame-bound density). dpr2: 478s → 442s wall (−7.5%;
−36s, matching the profile's prediction — the log is ≈12% of dpr2's 292s busy ≈ 35s).

---

## 5. The ranked items, in detail

### S1 — Delete the debug `console.log` in `Context2D.drawImage` 【SWCanvas; trivial; LANDED as hygiene】

**✅ LANDED 2026-07-08.** Deleted the block from `Context2D.drawImage` in the SWCanvas repo,
rebuilt dist, re-vendored, `fg gauntlet` + `fg homepage` green.

**⚠️ Reclassified — NOT a shipped-runtime win.** The vendored bundle that ships is
`swcanvas.min.js`, and SWCanvas `minify.sh` runs terser with
`drop_console=true,…,pure_funcs=['console.log',…]`, which **removes the drawImage log (and its
argument-object construction) outright** — verified: 0 occurrences of `Core drawImage called with`
in `swcanvas.min.js`, and `build_it_please.sh:553` cats the `.min.js`. So the shipped build, the
real `?sw=1` runtime, and `fg gauntlet` **never executed this log**; its measured −33%/−8.3% (§4.5)
lives only in the *unminified* profiling shadow build (`mk-shadow-build.sh:46` appends
`swcanvas.js`). Deleting it from source is still worth it: it removes genuinely dead debug from a
hot path AND makes the profiling harness honest — with the log present, every drawImage sample in
the §6.4 re-profile loop was inflated. Because terser dropped it either way, the shipped
`.min.js` is byte-identical w.r.t. S1 alone (the vendored `.min.js` changed here only because S6a+S5
rode along in the same re-vendor).

**Where**: SWCanvas repo `src/core/Context2D.js:1852` (the vendored `.min.js` never contained it —
terser strips it; the unminified `swcanvas.js`/shadow build did).

```js
// Debug logging for browser troubleshooting
if (typeof console !== 'undefined' && console.log) {
    console.log('Core drawImage called with:', { imageType: ..., hasWidth: ..., ... });
}
```

**Why it's #1**: it runs on EVERY `drawImage` — 662,474 times per suite run — allocating the
argument object and emitting a CDP `consoleAPICalled` event each time (headless runners and
DevTools sessions pay protocol traffic; every browser pays the object build + console
machinery). Measured by direct A/B (§4.5): **busy CPU −33%, wall −8.3% at dpr1, verdicts
unchanged 190/190** (= byte-identical pixels).

**Change**: delete the block (or gate it behind a debug flag that defaults off — but plain
deletion matches the codebase's stated preference for no dead debug in hot paths).
**Flow**: fix in the SWCanvas repo → run its own test suite (`npm test`, 218 green) → rebuild
dist → re-vendor into Fizzygum (`./scripts/vendor-swcanvas.sh`, updates `vendor/swcanvas.pin`)
→ `fg gauntlet`. Pixels can't change; references untouched.

### H1 — SHA-256 screenshot hashing via `crypto.subtle.digest` 【Fizzygum-tests; medium】

**✅ LANDED 2026-07-08 (the preferred async path).** Added `SHA256.hashRawPixelsAsync` (native
`crypto.subtle`); `compareScreenshots` snapshots the surface synchronously then hashes off-thread and
records the match when it resolves; a new `"waitForScreenshotHash"` Macro pump gate holds the macro (and
test completion) until each digest settles (so `assertScreenshotsIdentical` still sees fingerprints). Cold
paths (the `SystemTestsReferenceImage` ctor + the paint-truthfulness fingerprint) keep the sync JS impl —
same digest by spec. **Verified:** full `fg gauntlet` green (dpr1/dpr2/webkit/apps + paint/tiernaming/
settle/capstone, 194 tests, 0 failed) → **zero reference churn, cross-engine**; and a direct A/B on a real
dpr2 frame (1920×880, 6.45 MB) measured **80.95 ms → 2.92 ms per hash = 27.7×**, digests identical. See §8.

**Where**: `Fizzygum-tests/Automator-and-test-harness-src/SHA256.coffee` (`hashBytes`,
`hashRawPixels`, `hashRawPixelsAsync`), consumed by `AutomatorPlayer.compareScreenshots`
(`AutomatorPlayer.coffee:248`) and `SystemTestsReferenceImage.coffee:28`.

**Why**: 6.9% of busy at dpr1 and **24.7% at dpr2** (72.3s — the hottest single function;
each dpr2 screenshot hashes 2200×1600×4 = 14.08MB). On top of the JS compression loop,
`hashRawPixels` copies the frame into a fresh `Uint8Array(8+len)` and `hashBytes` copies it
AGAIN into the padded block buffer — two full-frame allocations+copies per screenshot.

**Change (preferred)**: `crypto.subtle.digest('SHA-256', buf)` — the **same algorithm**, so
`dataHash` values and every committed reference filename stay valid (the digest-parity
constraint with `scripts/recompress-swcanvas-references.js` is preserved by construction).
Native digest is typically 5–10× the JS loop and runs off the JS main loop. WebCrypto
`digest()` is **one-shot** (no streaming `.update()`), so it still needs `[header][RGBA]` in
ONE contiguous buffer = one copy (removes the second, padded-block copy, not the first).
`crypto.subtle` availability over `file://` was ✅ PROBED on both engines (2026-07-08): Chrome
AND WebKit both report `isSecureContext:true` and compute `digest('SHA-256','abc')` = the
correct vector over `file://` — so the preferred path is viable on both legs (no `http://`
fallback needed). The `SHA256.coffee:11-12` comment ("unavailable over `file://`") is stale —
correct it. (Evidence table in the invisible-pixel plan §2.7.) ⚠ **Zero-churn
holds only in isolation:** if the invisible-pixel canonicalisation (Option A in
`docs/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §2.7) is adopted, every reference
is re-hashed anyway — fold this crypto.subtle switch into THAT backfill rather than shipping
two reference-set disruptions.
Plumbing: `compareScreenshots` (`:248`) and its callers must await the digest (the Automator
command sequence already advances via per-frame polling — insert the await at the
screenshot-command completion gate; the world keeps cycling while the hash resolves). Two more
sync callers exist: `liveCanvasFingerprintNow` (`:62`, paint audit) — await it too — and the
`SystemTestsReferenceImage` **constructor** (`SystemTestsReferenceImage.coffee:28`), which
cannot `await`; it is capture/failure-only (cold), so leave it on the sync JS `SHA256` (same
digest by spec). Net: crypto.subtle for the hot path, retained sync JS for the cold path.
**Fallback (half the win, zero plumbing)**: keep it synchronous but hash the frame in place —
process the width/height prefix and the tail block without concatenating (drop both copies),
and inline `rotr`.
**Verify**: self-test vector already in SHA256.coffee; suite dpr1+dpr2+webkit; digests of a
few committed references recomputed and compared before/after.

### S2 — drawImage fast paths 【SWCanvas; medium; byte-identical gate】

**Where**: `src/core/Rasterizer.js:555-725` (`_drawImageInternal`).

**Why**: post-S1 it is the top SWCanvas function (12.4% busy dpr1, ~11.6% dpr2 for the loop).
The inner loop, per device pixel: allocates `inverseTransform.transformPoint({x,y})` (object),
does 4 dest-rect float compares, floors to source coords with bounds check, then calls
`CompositeOperations.blendPixel(...)` which string-switches on the op and **returns a fresh
{r,g,b,a} object**. Fizzygum's blit traffic is the friendliest possible: 662,474 calls,
avg 1,163px, **all axis-aligned 1:1** (integer back-buffer blits at identity or integer
translation), all source-over, none clipped (counters: drawImage under clip = 0).

**Change** (tiers, each keeping the general loop as fallback):
1. Hoist per-call invariants out of the loop: the inverse transform application (for an
   affine transform, march `destPoint` incrementally: +invA per x-step, +invB/invD per
   y-step — zero per-pixel objects), `globalAlpha`, composite-op dispatch (resolve ONCE per
   call to a specialized blend function), source stride bases.
2. Axis-aligned integer 1:1 case (`b===0&&c===0&&a===1&&d===1`, integer e/f, no clip,
   source-over): compute the overlapped [x0,x1)×[y0,y1) analytically, then per row walk
   source/dest offsets directly. Per pixel: if `srcA===255 && globalAlpha===1` write the 4
   bytes (or detect opaque RUNS and `dst.set(src.subarray(...))` per run); if `srcA===0` skip;
   else exact source-over integer blend inline.
3. (optional) same-size scaled-by-integer case — probably unnecessary here.

**Byte-identical constraint**: the fast path must reproduce `blendPixel`'s exact integer
rounding for the alpha case (copy the arithmetic verbatim), and the same pixel-selection
semantics as the sampling loop (the same-size case already uses the FP-stable
`sourceX + (destX-...)` form — the analytic rect must select identical pixels; derive it
from the existing bounds math, not fresh geometry). Gate: SWCanvas visual suite (218), then
Fizzygum `fg gauntlet` — any reference mismatch = the arithmetic differs somewhere.

### S3 — Tier-0 rectangular clipping 【SWCanvas; large; the companion plan】

**What**: execute `plans/clipping-optimization.md` §9 Stages 1–3 (+4 if profiles then still
show 1px-stroke bit-tests): detect axis-aligned integer rect clips post-flatten, keep
`_clipRect` + `_clipIsRect` state, clamp draw extents analytically and pass
`clipBuffer=null` to the renderers' existing unclipped paths, track clip bbox for the
residual mask case, snapshot/restore without bitmap cloning for tier-0.

**Why (now measured, was predicted)**: every §8.3 trigger threshold is exceeded at the
maximum possible value — **100.000% of 76,675 clips are axis-aligned integer rects**; ~227k
draw calls/suite run under rect-only clips and would take the tier-0 path; today they cost:
mask build 2.6–2.8% busy (≈2.27G `setPixel`s + 76,675 full-surface BitBuffer allocations),
mask reads (`_getBit`) 6.4–10.3% busy, plus the structural detours — clipped `fillRect`
reroutes through the whole path-filling machinery (`Rasterizer.js:170-177`), clipped spans
pay per-pixel bit tests inside `_fillPixelSpan`/`_fillPolygonsDirect` (part of the 11.6–13.9%
span bucket), and 12,494 saves clone a full-surface mask. Realistic recovery ≈10–18% of busy.

**Fizzygum-side facts that simplify it**: clips come from exactly two shapes of code —
`clipToRectangle` (`src/boot/extensions/CanvasRenderingContext2D-extensions.coffee`, a
moveTo+4×lineTo+closePath integer rect; 14 appearance call sites) and
`RectangularAppearance.paintStroke` (`beginPath/rect/clip`); both integer, both in a
save/restore pair, never nested (measured 0), never rotated (measured 0). The
"recover-to-rect promotion" and non-rect bbox refinements in the companion plan's skip list
can stay skipped.

**Byte-identical constraint**: the analytic rect must reproduce `_fillClipMaskSpans`'s
pixel-center sampling semantics exactly (a clip rect [5,25) exposes columns 5..24 — see the
comment block at `PolygonFiller.js:767+`). Derive the tier-0 rect from the SAME rounding.

### S4 — `blendPixel` de-allocation & specialization 【SWCanvas; small-medium】

**Where**: `src/utils/CompositeOperations.js` (`blendPixel`), callers:
`Rasterizer._drawImageInternal:708`, `PolygonFiller._blendPixel:468→476`, shadow pipeline.

**Why**: 5.8% busy post-S1 (dpr1) + a large share of the 4.8–7.2% GC bucket: a string
`switch` and a fresh `{r,g,b,a}` object **per blended pixel**.

**Change**: resolve the composite op ONCE per draw op to a specialized function (source-over
first — it's ~100% of Fizzygum's traffic); have it write into the surface array directly
(pass surface+offset) or return via out-params/packed int, preserving the exact integer
arithmetic. S2's fast path subsumes the drawImage caller; this item covers the span/polygon
callers. Same byte-identical gate as S2.

### F2 — Cache `WorldWdgt.getCanvasPosition` 【Fizzygum; small; LANDED】

**✅ LANDED 2026-07-08.** `getCanvasPosition` now memoises into `_cachedCanvasPosition` and returns
a **fresh copy per call** (a caller — `stretchWorldToFillEntirePage` — mutates the returned object,
so handing back the cached object would corrupt it). Invalidated via `invalidateCanvasPositionCache`
at the two canvas-geometry mutation sites (`sizeCanvasToTestScreenResolution`,
`stretchWorldToFillEntirePage`) and eagerly in `resizeBrowserEventListener`; the per-test reset
paths (`softResetWorld`/`_resetWorldNoSettle`) don't touch canvas geometry, so the cache stays valid
across resets. `fg gauntlet` (every macro drives synthesised input through this) + `fg homepage`
green. Note: the 5.8% is largely a *test-harness* effect (the control panel dirties the DOM, forcing
a reflow on each read) — in production the fixed full-page canvas rarely moves — so this is mostly a
suite-CPU win, plus a correct memoisation for production.

**Where**: `src/WorldWdgt.coffee` `getCanvasPosition` (walks `offsetLeft/offsetTop/offsetParent` up the DOM);
called per synthesized mouse event from `MousemoveInputEvent`'s constructor
(`src/events-input/MousemoveInputEvent.coffee:13`) and from
`ActivePointerWdgt.coffee:915/929`.

**Why**: **5.8% of busy CPU** post-S1 — reading `offsetLeft` forces a synchronous style+layout
pass whenever the DOM is dirty, and the SystemTests control panel writes to the DOM
constantly, so macro-driven event streams re-lay-out the page per event. In production the
world canvas is fixed at 0,0 filling the page; the value almost never changes.

**Change**: cache the computed position; invalidate on `resize`/`scroll` (listeners already
exist — `stretchWorldToFillEntirePage`, `initEventListeners`) and on
`syncRenderCanvasToWorldCanvas`. Straight memoization, no behavior change. (Independently
worthwhile: `addMessageToSystemTestsConsole` at 0.9% — consider batching its DOM appends —
but the cache alone removes the interaction.)

**Verify**: `fg gauntlet` (input positions feed every macro; a wrong offset shifts every
synthesized click — failures would be loud and immediate).

### S5 — Hoist `_evaluatePaintSource` for solid colors 【SWCanvas; small; LANDED】

**✅ LANDED 2026-07-08.** In `PolygonFiller._fillPixelSpan`, when `paintSource instanceof Color`
(Fizzygum: always, bar ~11 gradient uses/suite) the paint is now evaluated **once per span** and the
resulting immutable `Color` reused for every pixel; gradients/patterns keep the per-pixel path.
**Byte-identical by construction**: for a solid `Color`, `_evaluatePaintSource` ignores x/y and
`globalAlpha`/`subPixelOpacity` are span-level scalars, so the hoisted call is the *same pure call
with the same arguments*, just memoised — and `_blendPixel` only reads the color via getters (never
mutates it). Verified: SWCanvas's own 218 tests + `fg gauntlet` (dpr1/dpr2/webkit) green, zero ref
churn. (The other `_evaluatePaintSource` caller, `Rasterizer._performCanvasWideCompositing:345`, is a
path Fizzygum never triggers — left as-is.)

**Where**: `src/renderers/PolygonFiller.js` `_evaluatePaintSource` / `_fillPixelSpan`, plus
`Color.withGlobalAlpha` (`src/core/Color.js`).

**Why**: 4.3% busy post-S1: per PIXEL it runs a 5-way `instanceof` chain, then
`withGlobalAlpha` (a new Color unless alpha is 1 — and it showed 0.8% self), plus r/g/b/a
getter calls (≈2% combined).

**Change**: at span/op entry, if the paint source is a solid `Color` (Fizzygum: always,
except 11 gradient uses per suite run), evaluate ONCE to four ints and run the span loop on
those; keep the per-pixel path for gradients/patterns only.

### F1 — Pre-compiled boot for the test harness 【Fizzygum; medium】

**Where**: `build_it_please.sh` (ships the stub `js/pre-compiled.js`), boot logic in
`src/boot/globalFunctions.coffee:276-324` (already loads and prefers `window.preCompiled`),
generation via `?generatePreCompiled` (downloads a zip today, homepage-build flow).

**Why**: every harness page spends 3.5–3.7s compiling ~470 classes before the first test
(≈1.0–1.5s pure compiler CPU + eval + dependency scan). The parallel suite pays it per shard
(8×), `fg gauntlet` ≈36×; watching/iterating single tests pays it per run.

**Change sketch**: teach the build to generate the pre-compiled image headlessly for
non-homepage builds too (boot the freshly built world once under Puppeteer with
`?generatePreCompiled`, capture the image, place it as `js/pre-compiled.js`, rebuild the
bundle stamp — the smoke-boot harness in `Fizzygum-tests/scripts/` already knows how to boot
the build headless). Boot must keep compiling CLASS SOURCES lazily for the live-editing
tests (sources still ship; the meta system already handles the pre-compiled+sources split —
`JSSourcesContainer.content` is populated either way).
**Risks/opens**: (a) build time grows by one headless boot (~5s) — acceptable next to the
test-copy step; (b) verify the handful of tests that live-edit classes still pass (they
compile from source at edit time regardless); (c) the `--homepage` generation flow must not
fork — reuse one code path.
**Payoff**: ≈2.5–3s off EVERY headless page boot — suite wall −~5% per shard, single-test
inner loop noticeably snappier, browser-watched runs boot near-instantly.

### S6 — SWCanvas micro batch 【SWCanvas; small】

- **S6a ✅ LANDED 2026-07-08**: `Rasterizer._requiresCanvasWideCompositing` allocated a fresh
  `globalOps` array + `.includes` on EVERY draw op (called from `beginOp` + fill/stroke paths).
  Hoisted to a module-const `CANVAS_WIDE_COMPOSITE_OPS = new Set([...])` before the class (the build
  wraps every file in one IIFE, so a module-scoped const is safe — precedent: `SWCanvasConstants.js`)
  and switched to `.has(...)`. Pure de-allocation, byte-identical; `fg gauntlet` green.
- **S6b (DEFERRED — ⚠ not byte-identical-trivial)**: `Color.withGlobalAlpha` returning `this` when
  `globalAlpha === 1` looked free, but `withGlobalAlpha` currently returns a **new** Color with
  `premultiplied=false`, whereas `this` may be premultiplied. Downstream, `_evaluatePaintSource`'s
  `subPixelOpacity < 1` branch reads `resultColor.premultiplied` and reconstructs via the r/g/b
  getters, which round differently for premultiplied vs non-premultiplied storage — a possible ±1
  drift. Excluded from the safe batch; revisit with the S2/S4 blend work under the byte-identical gate.
- **Investigate (DEFERRED)**: `_performCanvasWideCompositing` showed 0.7% (dpr1) / 1.3% (dpr2) busy,
  yet Fizzygum never sets a canvas-wide op (`grep globalCompositeOperation src/` empty; confirmed
  2026-07-08) and `_requiresCanvasWideCompositing('source-over')` is false so the gated call at
  `Rasterizer.js:415/431` never fires for Fizzygum — so this is **most likely profiler
  self-time misattribution** (inlining), not a real Fizzygum path. Confirm before spending effort.

### F3 — Dirty-rect DOM present 【Fizzygum; small; DEPRIORITIZED】

**Where**: `src/WorldWdgt.coffee:1172-1178` `blitRenderCanvasToDOM` — full-surface
`putImageData` per changed frame; the in-code comment already names per-broken-rect blits
as a future optimization.
**Measured**: only ~0.3% of busy CPU at dpr1 in headless Chrome (the raster/compositing cost
largely lives off the sampled thread), invisible at dpr2. Keep it on the list only for
real-display browsers (memory bandwidth: 14MB/frame at dpr2), measure there before doing it.
The change itself is easy (world already has per-frame broken rects; use the
`putImageData(img, dx, dy, dirtyX, dirtyY, dirtyW, dirtyH)` overload per rect).

---

## 6. Verification protocol (applies to every item)

1. **SWCanvas changes (S1–S6)**: run the SWCanvas repo's own visual suite first (218 tests,
   `npm test` there), then re-vendor (`Fizzygum/scripts/vendor-swcanvas.sh` — updates
   `vendor/swcanvas.pin`), rebuild, and run **`fg gauntlet`** (build + suite dpr1 + dpr2 +
   webkit + apps). The SystemTest suite compares raw-pixel SHA-256 against committed
   references, so ANY arithmetic deviation fails loudly — this is the byte-identical gate.
   No reference may be recaptured for S-items: a mismatch means the change is wrong.
2. **Fizzygum changes (F1–F3)**: `./build_and_test.sh` for the inner loop; full `fg gauntlet`
   before declaring done. F2 additionally exercises every macro (all input synthesis flows
   through the cached position).
3. **H1**: recompute `dataHash` for a sample of committed references with the new path and
   diff against filenames; suite at dpr1+dpr2 AND `--browser=webkit` (secure-context/subtle
   availability differs by engine over `file://`).
4. **Performance regression check**: re-run the two headline measurements from
   `docs/profiling/README.md` (counter run + dpr1 profile) after each landed item and append
   the busy-time delta to this doc's §8 ledger.

## 7. Suggested sequencing

**Done:** ✅ H1 (2026-07-08) · ✅ **S1 + F2 + S6a + S5** (2026-07-08, arc 2). Remaining below.

1. ~~S1~~ ✅ (landed as hygiene — see §5; unblocks honest profiles: the log distorted every
   unminified-build drawImage measurement).
2. ~~F2~~ ✅ and ~~S6a~~ ✅ — small, independent, low-risk.
3. ~~H1~~ ✅ — dominant *suite-speed* item at dpr2.
4. ~~S5~~ ✅ (landed early — it re-vendored cleanly alongside S1/S6a and is byte-identical).
   **Next real rendering wins:** **S2** (drawImage fast path, 2–3 days) then **S4** (1 day, shares
   the blend-specialization machinery). These are the genuine *production* rendering wins (SWCanvas
   raster) as opposed to the suite-speed items above; both are byte-identical-gated.
5. **S3** (the companion plan's §9 Stages 1–3; ~1 week) — after S2/S4 so its win is measured
   against the already-cleaned span/blend baseline. Largest single production win (`_getBit`
   clip-mask reads 9.6% + mask build + span detours).
6. **F1** (1–2 days) — orthogonal; any time. Suite/dev-loop boot speed.
7. **S6b** (with the S4 blend work, under the byte-identical gate) + the
   `_performCanvasWideCompositing` investigation.
8. Re-profile (§6.4 loop — not yet re-run after arc 2); decide on S3 Stage 4
   (Cohen-Sutherland / 1px strokes) and F3 with fresh data.

## 8. Post-landing measurement ledger

| Date | Item landed | dpr1 busy (was 128.0s / 86.1s post-S1) | dpr2 busy (was 292.3s) | Suite wall dpr1/dpr2 | Notes |
|---|---|---|---|---|---|
| — | — | — | — | — | baseline rows above |
| 2026-07-08 | **H1** (crypto.subtle) | — (not re-profiled) | — (not re-profiled) | 1.49 / 1.91 min (parallel, 5 shards) | Per-hash A/B: 80.95→2.92 ms = **27.7×** on a 6.45 MB dpr2 frame, digests identical. Full-suite busy-CPU delta not yet measured with the profiling harness (was 6.9% dpr1 / 24.7% dpr2 of busy; expect ~all recovered). Gauntlet green, zero ref churn. |
| 2026-07-08 | **F2 + S1 + S6a + S5** (arc 2) | — (not re-profiled) | — (not re-profiled) | dpr1 2.50 / dpr2 1.99 min (parallel, 5 shards) | Full `fg gauntlet` green (dpr1/dpr2/webkit 196/196 + apps + paint + tiernaming/settle/capstone) **and** `fg homepage` boot-smoke green; **zero reference churn**, cross-engine. dpr2 first-pass showed a **flaky parallel-boot stall** (shards 0/3/4: `ReferenceError: CoffeeScript is not defined` at boot → "did not start within 90s"; 0 pixel failures); clean re-run 5/5. Targeted busy-CPU deltas (F2 5.8%, S5 4.3%, S6a ~1%; S1 shipped ~0) not yet re-profiled — run the §6.4 loop next. |

## 9. Explicitly considered and rejected / deferred

- **CSS-color parse caching** — already done on both sides (SWCanvas `ColorParser` has a
  Map cache; Fizzygum `Color.toString` memoizes `_derived_String`). No item.
- **Native-backend headless suite** as a comparison baseline — the native leg does not run
  headless (first test never completes; reference/settle gates are SWCanvas-oriented).
  Framework share was instead derived by bucketing the sw=1 profile. (If a native headless
  leg is ever wanted, that hang is the blocker to investigate — infra note, not a perf item.)
- **Changing the reference-hash algorithm** (xxHash etc.) for H1 — would re-key every
  committed reference filename; `crypto.subtle` gets the win with zero churn.
- **Skip-hash when pixels unchanged** between screenshots — determinism-sensitive machinery
  for a case H1 already makes cheap; rejected.
- **Y-X banded regions / per-row span extents / subregion masks / AA clips** — the SWCanvas
  companion plan's §7 skip list; the measured workload (0 non-rect clips) confirms all of it.

## Appendix A — reproduction

Everything needed to re-run the measurements ships in [`docs/profiling/`](profiling/README.md):

- **One command reproduces the whole campaign**: `bash docs/profiling/run-campaign.sh`
  (phases A–F + aggregation, ~55 min; prereqs: a FULL fresh `./build_it_please.sh` and
  `cd ../Fizzygum-tests && npm i` once). Individual measurements by hand: see the README's
  "Typical session" + flag reference.
- **The raw baseline to diff against** is preserved in
  [`docs/profiling/results-2026-07-07/`](profiling/results-2026-07-07/INDEX.md): the counter
  JSONs, every profile digest (`*.report.txt`, `*.groups.txt`), all per-run `meta.json`s
  (wall clocks, per-test timestamps, exact URLs/flags), the environment (M4 Max 16-core,
  Puppeteer 22.15.0 / Chrome-for-Testing 127, build `6f6c834e` @ 2026-07-07 12:25), and the
  A/B wall-clock ledger. Only the multi-MB `.cpuprofile` files are not kept — regenerable,
  and their digests are the reports (load a regenerated one into Chrome DevTools →
  Performance → "Load profile" to explore interactively).
- §6 item 4 defines the post-landing measurement loop: re-run the campaign (or just the
  counter run + dpr1 profile), diff against `results-2026-07-07/`, and append the delta to
  the §8 ledger.

## Document history

- 2026-07-07 — Authored from the first full profiling campaign (counters ×3 configs,
  CPU profiles ×3, boot profile, S1 A/B ×2 densities, method-level framework profile).
