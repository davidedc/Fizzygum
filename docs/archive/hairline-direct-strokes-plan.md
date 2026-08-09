> **ARCHIVED — COMPLETE (authored 2026-08-08, executed 2026-08-09).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Hairline strokes on the direct fast paths — the sub-pixel faint rule, uniformly

**STATUS: ✅ EXECUTED IN FULL AND CLOSED 2026-08-09 — H1+H2+H3.** Landed as
SWCanvas `d6e6765` (the hairline branch in all five direct stroke dispatchers,
core test 055, probe; plus two consistency fixes the rule surfaced in execution:
ArcOps' opaque 1px Bresenham walk canonicalized to the family spelling — a
partial arc no longer changes shape with its opacity — and the rotated-rect 1px
DDA dedups shared corner pixels), Fizzygum (pin bump + the rotate-handle ring
re-converted to `strokeCircle` + a dead lineCap removed from
UpperRightTriangleAppearance + integer-pixel doc §7), Fizzygum-tests (16-test
re-baseline, dpr 1+2: 9 ring tests — at dpr 2 the 0.5-logical ring is a TRUE
1px device stroke and sharpens from a 2-px half-opacity band to a crisp opaque
ring — plus 7 collapsed-window tests whose uncollapse icon strokes sub-1px at
dpr 1 only). Verification: 540-case sweeps byte-identical for lw ≥ 1; test 055's
oracles FAIL on the pre-change dist (non-vacuity); recapture COMPLETE both
densities; closing gauntlet 14/14 incl. WebKit on the new refs. Terminology
(owner): this is the HAIRLINE FAINTNESS RULE, not anti-aliasing — both backends
blend the faint stroke with what lies beneath (probe-measured on Chrome);
SWCanvas stays non-AA, one uniform level per stroke. Deviation from §4 H1.2:
the rotated rect/roundRect branches got the rule too (their 1px renderers take
the multiplied alpha through the existing globalAlpha argument), rather than
keep-current-behaviour-with-a-comment.**

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-08, immediately after the direct-shape fast-paths arc closed
(`docs/archive/direct-shape-fastpaths-followups-plan.md`). Nothing below has been
started. Every `file:line` was verified on authoring day but LINES DRIFT — the quoted
method names and code are authoritative; re-grep before trusting a number.

**Mandate:** eliminate the hairline (sub-1px-stroke) inconsistency across SWCanvas's
direct stroke dispatchers by replicating the generic pipeline's ONE sub-pixel rule —
*render at 1px geometry, at opacity proportional to the true width* — as a first-class
branch in every direct stroke entry, then re-convert the one Fizzygum consumer this
unlocks (the rotate-handle knob ring) back to `strokeCircle`. No burying: every
dispatcher either gets the rule or carries a written reason at its entry point.

---

## §0 Orientation

Three sibling repos plus one external:

- `~/code/Fizzygum-all/Fizzygum` — framework source. Read its `CLAUDE.md` first.
- `~/code/Fizzygum-all/Fizzygum-tests` — SystemTest suite + harness. `CLAUDE.md` + `DETERMINISM.md`.
- `~/code/Fizzygum-all/Fizzygum-builds` — generated; never edit.
- `~/code/Unified SW Canvas/SWCanvas` — the SWCanvas repo (path has SPACES — quote it).
  Fizzygum vendors its built `dist/` via `Fizzygum/scripts/vendor-swcanvas.sh` pinned by
  `Fizzygum/vendor/swcanvas.pin`. Non-negotiables from its `CLAUDE.md`: `npm run build`
  BEFORE every test run; dual-API parity (core + compat) for public-surface changes;
  Prettier + ESLint; `npm run update-test-counts` after adding tests.
  ⚠⚠ **The vendor script ships `dist/swcanvas.min.js`, which only `npm run build:prod`
  regenerates** — vendoring after a plain `npm run build` ships a STALE min (the entry
  pages LOAD the min; symptom: page-side `… is not a function` per repaint → main-thread
  wedge → the suite crawling at ~25 s/test with healthy-looking shards). This bit the
  prior arc; always `npm run build:prod` before vendoring.

**The immediately-prior arc (CLOSED + PUSHED 2026-08-08)** — SWCanvas `7414c35`,
Fizzygum `1b431b39`, tests `d402421bb` — put sliders on `fillStadium`, title-bar rings
on `strokeCircle`, icon rects on direct calls, wired tier-0 clipping across the
rect/roundRect/circle families, and gated all six circle/arc entries on
`isUniformScale`. **One conversion was REVERTED during it:** the rotate-handle knob
ring (`HandleAppearance`, `lineWidth 0.5`) — converted to `strokeCircle`, it VANISHED
inside a scaled island, and was restored to its `arc()` path with a ⚠ comment. Case
law: memory note `direct-shape-fastpaths-arc.md`.

**⚡ THE KEY INSIGHT (owner-supplied, probe-confirmed).** SWCanvas already has the
right answer for sub-pixel strokes, but only in the GENERIC pipeline:
`Rasterizer._strokeInternal` (src/core/Rasterizer.js ~:587) renders any
`lineWidth < 1.0` at **width 1.0 with `subPixelOpacity = lineWidth`** — an alpha
multiplier threaded through `PolygonFiller`. One rule: *1px geometry, proportional
faintness*. The direct stroke dispatchers never got it — each does something
different below 1px (see §1.1) — and THAT inconsistency, not hairlines per se, is why
the handle-ring conversion failed. Replicating the rule as a direct-path branch makes
hairline strokes fast, deterministic, transform-robust, and visually consistent with
the generic pipeline.

Authoring-day probe (44×44, white ring r=15 on the handle-face blue; pixel counts of
touched pixels):

| Case | Painted px |
|---|---|
| (a) `strokeCircle` lw=0.5, identity — current internal fallback | 92 |
| (b) generic `arc()`+stroke lw=0.5 — the subPixelOpacity rule | 92 |
| (c) **proposed**: 1px Bresenham ring at `globalAlpha × 0.5` | 84 — full, closed, crisp |
| (d) `strokeCircle` lw=0.5 under `scale(1.4)` — current | **62 — broken ring** |
| (e) generic `arc()`+stroke lw=0.5 under `scale(1.4)` | 126 — full ring |

(a)≡(b): at identity the circle fallback inherits the faint rule. (d)≠(e): under a
transform the fallback re-strokes in DEVICE space and loses coverage — the vanish
mechanism. (c) is immune at any transform: the device lineWidth is already
uniform-scale-multiplied before the dispatch, so the faintness scales correctly too.

---

## §1 Current state (verified 2026-08-08 — re-grep everything before edits)

### 1.1 What each direct stroke dispatcher does for `0 < scaledLineWidth < 1` TODAY

All in `src/core/Context2D.js`. `STROKE_1PX_TOLERANCE = 0.001`
(`src/SWCanvasConstants.js:56`), so `is1pxStroke` means *exactly ≈1*, and sub-1px
widths never qualify.

| Entry | Dispatch today | Sub-1px behaviour today |
|---|---|---|
| `strokeRect` (~:768) | `is1pxStroke` → 1px; `scaledLineWidth > 1` → thick; **else falls through** | generic path pipeline → **correct faint** (slow) |
| `strokeRoundRect` (~:1100) | `is1pxStroke` → 1px; **else → `strokeThick_AA_*`** (no `>1` guard) | thick renderer at lw<1 → **FULL-opacity** thin ring (wrong weight) |
| `strokeCircle` → `_strokeCircleDirect` (~:2470) | `is1pxStroke` → Bresenham; `lineWidth > 1` → thick; **else → internal fallback** (device-space `arc` re-stroke at identity) | faint at identity, but **coverage-broken under transforms** (probe d) |
| `outerStrokeArc` (~:2600) | `is1pxStroke` → 1px; **else → `strokeOuter_*`** (no `>1` guard) | thick renderer at lw<1 → **FULL-opacity** (wrong weight) |
| `strokeLine` → `LineOps.stroke_Any` | `lineWidth <= THIN_LINE_THRESHOLD` (1.5) → Bresenham | **FULL-opacity** 1px line (no faint rule at all) |

Five entries, four different sub-1px behaviours, none matching the generic rule.
(The fused `fillStrokeRoundRect`/`fillStrokeCircle`/`fillOuterStrokeArc` stroke halves
have the same gaps — deliberately OUT of scope here, see §6e.)

### 1.2 The renderers already have everything the rule needs

The faint branch is pure dispatch — **no rasterizer changes**. Every family has a
1px-stroke renderer with a `globalAlpha` parameter and tier-0 `clipRect` support
(except the arc family's, which is deliberately un-tiered — see its entry comment):

- `RectOpsAA.stroke1px_AA_Alpha(surface, x, y, w, h, color, globalAlpha, clipBuffer, clipRect)` (:110)
- `RoundedRectOpsAA.stroke1px_AA_Alpha(…, radii, color, globalAlpha, clipBuffer, clipRect)` (~:237)
- `CircleOps.stroke1px_Alpha(surface, cx, cy, radius, color, globalAlpha, clipBuffer, clipRect)`
- `ArcOps.stroke1px_Alpha(surface, cx, cy, radius, start, end, color, globalAlpha, clipBuffer)`
- `LineOps.stroke_Any(…)` thin-alpha branch (takes `effectiveAlpha` via its
  `isSemiTransparentColor` path — see §4 H1.5 for the wiring detail)

The composition rule to replicate exactly (from `Rasterizer._strokeInternal`):
`effective opacity = globalAlpha × lineWidth` (then × colour alpha inside the
renderer, which is what the `_Alpha` variants already do). Since `lineWidth < 1`, the
product is < 1, so the `_Alpha` variant is ALWAYS the target — the `_Opaq` twin can
never apply on this branch.

### 1.3 The Fizzygum consumer this unlocks

`Fizzygum/src/HandleAppearance.coffee` — the rotate-handle knob ring, currently:

```coffee
    # ⚠ Deliberately NOT a strokeCircle direct call: this ring strokes at the hairline
    # lineWidth 0.5 set by handleWidgetRenderingHelper, below every direct-path
    # threshold (STROKE_1PX_TOLERANCE), so strokeCircle would re-route it through a
    # DEVICE-space path fallback that loses the sub-pixel ring entirely inside a
    # scaled island. ...
    if @widget.type is "rotateHandle"
      cx = @widget.width() / 2
      cy = @widget.height() / 2
      r  = Math.min(@widget.width(), @widget.height()) / 2 - 1
      context.beginPath()
      context.arc cx, cy, r, 0, 2 * Math.PI
      context.stroke()
```

`handleWidgetRenderingHelper` sets `lineWidth = 0.5` and draws the handle THREE times
(shadow twice, translated, then the colour pass) — all through `drawHandle`, so one
edit covers all three. The tests that show this ring (all byte-identical to the
committed refs today): `macroTransformFrameResizeInsideScaledIsland`,
`macroHandleWdgtIsItselfResizable`, `macroWidgetRotateViaHaloHandle`,
`macroTransformFrameRotateViaHandle`, `macroTransformFrameRotateSnap`.

### 1.4 Fizzygum sites that hit the changed dispatchers with lw < 1 today

- **Shrunk (scale < 1) transform islands**: any window/menu chrome inside them
  strokes Boxy borders at 1 *logical* px → device lw < 1 → today the
  `strokeRoundRect` path renders them FULL-opacity via `strokeThick_AA_*`; after H1
  they render as faint 1px — a deliberate weight CORRECTION whose blast radius is
  suite-discovered (expect few or zero tests; the dpr1+dpr2 suite runs in H2 decide).
- `RectangularAppearance.paintStroke` / `Widget._drawSelectionOverlay` stroke at
  device lw ≥ 1 — unaffected at identity; inside shrunk islands the former follows
  the same correction class.
- Nothing calls `strokeLine`/arcs with sub-1px widths today (grep to confirm).

---

## §2 Why it is shaped this way

The direct dispatchers accreted per-shape: rect got the fall-through-to-generic
(accidentally correct), roundRect and arc got a thick-catch-all (wrong weight below
1px), circle got a private device-space fallback (transform-fragile), and LineOps
predates the faint rule entirely. The generic pipeline's `subPixelOpacity` was added
once, centrally, where all PATH strokes funnel — the direct entries bypass that
funnel by design, and nobody re-stated the rule at their level. This plan re-states
it once per dispatcher, at the dispatch layer where the width is already in device
units, reusing the `_Alpha` renderers unchanged.

## §3 The distilled argument

One rule exists, is owner-blessed, and is already load-bearing for every path-drawn
hairline in the product; the direct paths just never learned it. Adding it is pure
dispatch (~6 small branches), provably zero-churn for every `lw ≥ 1` caller (the new
branch sits strictly below the existing thresholds), and it converts today's THREE
distinct sub-1px wrongnesses (full-opacity weight, transform-broken coverage,
slow-path inconsistency) into one correct fast behaviour. It also un-blocks the
rotate-handle ring — the one conversion the prior arc had to revert — with a crisper
result than the generic pipeline produces (probe c vs b). Doing it now, with the
prior arc's probes, sweeps and recapture flow still fresh, is materially cheaper than
rediscovering the context later.

---

## §4 Phases

Run in order; each phase lands (owner-gated) before the next starts.

### H1 — upstream: the faint-hairline branch in every direct stroke dispatcher

1. **Probe first, change nothing** (the standing doctrine): extend
   `debug/probe-circle-crisp.js`'s pattern into a new `debug/probe-hairline-strokes.js`
   that renders, for EACH of the five entries, the sub-1px stroke today vs the generic
   path vs the proposed faint-1px call (emulated via `globalAlpha × lw` at `lineWidth 1`),
   at identity and under `scale(1.4)` and `scale(0.7)` — reproducing §0's table per
   shape. The probe DECIDES the per-shape baseline notes below, not this paragraph.
2. **The branch, uniformly.** In each dispatcher, immediately after `is1pxStroke` is
   computed, add (adapting names per entry):
   ```js
   // Sub-pixel stroke: the generic pipeline's rule (Rasterizer._strokeInternal)
   // — render at 1px geometry, at opacity proportional to the true width.
   // lineWidth is already in device units (uniform-scale-multiplied), so the
   // faintness scales with the transform. Always the _Alpha renderer: the
   // opacity product is < 1 by construction.
   const isHairlineStroke = scaledLineWidth > 0 && scaledLineWidth < 1 && !is1pxStroke;
   ```
   and route it to the family's `stroke1px_*Alpha` with
   `this.globalAlpha * scaledLineWidth` in the `globalAlpha` slot, forwarding
   `clip`/`tier0ClipRect` exactly as the existing 1px branch does. Entries and their
   targets:
   - `strokeRect` (both the axis-aligned and — check whether it exists — the rotated
     branch; if the rotated branch has no 1px renderer, leave it on its current path
     with a one-line comment) → `RectOpsAA.stroke1px_AA_Alpha`.
   - `strokeRoundRect`, both the `isIdentity` and `isAxisAligned` sub-branches →
     `RoundedRectOpsAA.stroke1px_AA_Alpha`. The rotated branch keeps current
     behaviour (comment).
   - `_strokeCircleDirect` → `CircleOps.stroke1px_Alpha`. Place the branch BEFORE
     the existing `is1pxStroke` block's `paintSource.a > 0` guard family; keep the
     device-space fallback for what remains (gradients/patterns at any width).
   - `outerStrokeArc` → `ArcOps.stroke1px_Alpha` (still `isButtCap`-gated like the
     rest of its direct family).
   - `_strokeLineDirect` / `LineOps.stroke_Any` → route hairlines through the
     existing thin-ALPHA Bresenham branch with the multiplied alpha. Mechanically:
     in `_strokeLineDirect`, when `0 < scaledLineWidth < 1`, force
     `isOpaqueColor = false`, set `isSemiTransparentColor` per its current predicate,
     and pass `this.globalAlpha * scaledLineWidth` as the `globalAlpha` argument,
     with `lineWidth = 1`. (LineOps computes `effectiveAlpha` from
     `paintSource.a / 255 * globalAlpha` — the multiplication composes correctly.)
     ⚠ If the wiring in `stroke_Any` turns out non-mechanical (its dispatch reads
     `lineWidth` in several branches), gate the hairline at the `_strokeLineDirect`
     level only and leave `stroke_Any` untouched.
3. **Docs truth-up**: `DIRECT-RENDERING-SUMMARY.MD` — add the sub-pixel rule to §3's
   universal conditions area (one statement: hairline strokes render 1px ×
   proportional opacity on ALL direct stroke entries, mirroring
   `Rasterizer._strokeInternal`) and delete/adjust any per-shape row the probe shows
   stale. Add the new probe to `debug/README.md`'s listing.
4. **Verification (all required)**:
   - **Zero-churn proof for lw ≥ 1**: re-run BOTH existing sweeps
     (`debug/sweep-stroke1px-roundrect-hashes.js`, `debug/sweep-circle-hashes.js`)
     against the pre-change dist (capture `git show HEAD:dist/swcanvas.js` into the
     session scratchpad — ⛔ never `git stash` in this repo) — every case must be
     byte-identical (all their grids use lw ≥ 1).
   - **New core test `055-hairline-stroke-subpixel-rule.js`** (follow 046–054 style:
     `test('name', fn)`, Core API, exact-pixel asserts, `savePNG`): for each of the
     five entries — (i) hairline output byte-equals the explicit
     `lineWidth 1 + globalAlpha × w` call (the rule stated as an identity); (ii) ring/
     outline closure under `scale(1.4)` (every stroke pixel ≥ 2 of 8 neighbours —
     the transform-robustness the old circle fallback lacked); (iii) faintness
     monotonicity (w=0.25 strictly lighter than w=0.75 at a sampled pixel);
     (iv) `lw ≥ 1` dispatch unchanged (structural: `resetPathBasedFlag`/
     `wasPathBasedUsed` where applicable).
   - `npm run build && npm test && npm run test:direct-rendering` (the three
     `*subpixel*` visual tests exercise gradients/dash — path pipeline, must stay
     green untouched); `npx eslint`/`prettier --check` on touched files;
     `npm run update-test-counts`; **`npm run build:prod`** (the min — §0's trap).
5. **Owner gate**: present commit; after approval push.

### H2 — Fizzygum: re-convert the rotate-handle knob ring (+ pin bump)

1. **Pin bump**: `cd Fizzygum && ./scripts/vendor-swcanvas.sh --source "<SWCanvas path>"`
   (SWCanvas must be PUSHED first — the from-pin fetch 404s otherwise), `fg build`,
   `fg presuite`. Expect **zero churn ONLY IF no suite test strokes sub-1px through
   the changed dispatchers today** — §1.4 says shrunk-island chrome MAY: a presuite
   failure here is the weight-correction class, not a bug; carry those tests into
   step 3's diffpage/recapture set rather than reverting.
2. **The ring**: in `HandleAppearance`, replace the `beginPath`/`arc`/`stroke` block
   with `context.strokeCircle cx, cy, r` and REWRITE the ⚠ comment — the new truth:
   hairline widths now render on the direct path as a faint 1px Bresenham ring
   (`Rasterizer`'s sub-pixel rule), full closure at any uniform transform, no trig
   (cross-engine byte-identical without the fdlibm shim); the native page still
   rasterises through the arc polyfill and matches no reference. Keep the pointer to
   the four-swirlies redesign (BACKLOG) which replaces this paint wholesale.
3. **Verify with the standing mass-visual flow**: `fg build` → `fg suite` (dpr1) +
   `fg suite --dpr=2` (fg killz between) → union failing lists →
   `fg diffpage --tests-file=… --dprs=1,2` → **owner eyeballs** (expected: the five
   handle tests' rings as crisp faint Bresenham; possibly a few shrunk-island chrome
   tests with correctly-fainter borders; run the color-transition-histogram
   forensics from the prior arc — a one-sided gain/loss balance is the
   something-stopped-rendering detector) → `fg recapture --auto --dprs=1,2`
   (COMPLETE verdict required; budget ≥ 40 min/density of single-process
   re-verification if the set exceeds a handful) → `fg gauntlet` (14 legs).
4. **Owner-gated commits + pushes**: Fizzygum (ring re-conversion + docs), the pin
   commit, Fizzygum-tests (re-baseline).

### H3 — docs-sync + close

- `docs/architecture/integer-pixel-placement-and-sizing.md` §7: add the hairline
  rule to the direct-shape section (one spelling: stroke at the true sub-1px width;
  the engine renders 1px × proportional opacity on both pipelines — and note the
  native backend just AA-renders the true width, so cross-backend the WEIGHT
  matches even though pixels differ).
- `docs/BACKLOG.md`: tick this plan's line; on completion `git mv` this plan to
  `docs/archive/` + stamp + INDEX line + memory-note update (the standing loop —
  fold into `direct-shape-fastpaths-arc.md` or a small successor note).

---

## §0.5 Cold-execution protocol

1. `~/code/Fizzygum-all/fg status` — orient; verify Fizzygum ≥ `1b431b39`,
   Fizzygum-tests ≥ `d402421bb`, SWCanvas `main` ≥ `7414c35` and CLEAN. If heads
   moved, re-verify §1's dispatch tables before trusting anything here.
2. Read: `Fizzygum/CLAUDE.md` → `Fizzygum-tests/CLAUDE.md` (headless-runner +
   determinism sections) → SWCanvas `CLAUDE.md` → memory note
   `direct-shape-fastpaths-arc.md` → this plan fully.
3. Execute H1 → H2 → H3 in order. Probe BEFORE changing dispatch; never conclude
   pixels from reading code.
4. **Owner gates (never autonomous)**: every commit and push; the H2 diff-page
   eyeball; the H2 mass recapture.
5. Long ops (`fg suite`/`gauntlet`/`recapture`) via Bash `run_in_background` +
   task notifications; `fg killz` before dpr2 runs; peek cadence ≥ 5 min.
6. ⛔ Never `git stash` in ANY of these repos. Node scratch probes for the tests
   repo go in `Fizzygum-tests/.scratch/`; SWCanvas probes in its `debug/` (tracked).

## §5 Verification quick-reference

- SWCanvas: `npm run build` (before EVERY test run) · `npm test` ·
  `npm run test:direct-rendering` · both existing sweeps vs the pinned dist
  (byte-identical) · new test 055 · lint/format · `npm run update-test-counts` ·
  **`npm run build:prod` before vendoring**.
- Fizzygum: `fg build` · `fg presuite` · `fg suite` + `--dpr=2` ·
  `fg diffpage --tests-file=F --dprs=1,2` · `fg recapture --auto --dprs=1,2` ·
  `fg gauntlet` — invoke as `/Users/davidedellacasa/code/Fizzygum-all/fg`.
- Forensics on any surprising diff: color-transition histograms (±1-on-one-channel =
  the known blend-rounding class; anything else = look) and gain/loss balance
  (one-sided loss = something stopped rendering). Both scripted in the prior arc's
  session; trivially re-written from the descriptions in `archive/INDEX.md`'s entry.

## §6 Rejected alternatives — do NOT re-attempt

- **(a) Full-opacity 1px for hairlines** (what `strokeRoundRect`/`outerStrokeArc`/
  `LineOps` accidentally do today) — wrong stroke WEIGHT: a 0.5px stroke must read
  lighter than a 1px one; the generic pipeline and the native (AA) backend both
  honour that. The faint rule is the contract, not a nicety.
- **(b) Fixing `_strokeCircleDirect`'s device-space fallback coverage instead**
  (stroke in user space under the CTM) — treats one symptom in one shape; hairlines
  would stay on the slow path and the weight inconsistency in the other dispatchers
  would remain. The fallback stays for gradient/pattern strokes; its transform
  behaviour for THOSE is a pre-existing known-limit (no callers), noted, not fixed here.
- **(c) Coverage/AA-based hairline rendering** — SWCanvas is deliberately non-AA;
  uniform-alpha faintness is the engine's established idiom (`Rasterizer` precedent,
  owner-designed). Do not introduce per-pixel coverage math.
- **(d) Redesigning the rotate glyph in this arc** — the four-swirlies square is a
  separate owner-gated design task (BACKLOG, reference screenshots attached there);
  this plan only restores fast-path rendering of the CURRENT ring.
- **(e) Wiring the fused fillStroke paths' stroke halves** — no hairline fused
  callers exist; adding untested branches there is speculative surface. Leave with
  their current behaviour; revisit when a caller appears (the dead-method gate).
- **(f) A hairline branch keyed on LOGICAL width** — the dispatch must key on the
  DEVICE width (`scaledLineWidth`, already uniform-scale-multiplied): a 0.5-logical
  stroke at dpr2 is a true 1px stroke and must stay on the exact-1px path.

## §7 References

- Memory: `direct-shape-fastpaths-arc.md` (prior arc + case law), MEMORY.md index.
- SWCanvas: `Rasterizer._strokeInternal` (~:579–594, the rule); `Context2D` dispatch
  sites per §1.1; `tests/core/046–054` (style); `debug/probe-circle-crisp.js` +
  `debug/sweep-*` (patterns); `DIRECT-RENDERING-SUMMARY.MD` §3/§5.
- Fizzygum: `src/HandleAppearance.coffee` (`drawHandle` rotate branch +
  `handleWidgetRenderingHelper` lineWidth 0.5); commit `1b431b39` (arc close);
  `docs/archive/direct-shape-fastpaths-followups-plan.md` (the revert story);
  `docs/archive/INDEX.md` entry (forensic methods).
- Fizzygum-tests: `d402421bb` (current baseline); the five handle tests named in §1.3.

---

## Start prompt for a fresh session

> Run the hairline direct-strokes plan. Orient with
> `/Users/davidedellacasa/code/Fizzygum-all/fg status`, then read
> `Fizzygum/docs/archive/hairline-direct-strokes-plan.md` IN FULL and follow its §0.5
> cold-execution protocol (it tells you what else to read and in what order). Verify
> the §0.5 shas are ancestors of the current heads before trusting §1; re-grep every
> cited symbol before editing. Start with H1. All commits, pushes, the H2 diff-page
> eyeball and the H2 recapture are owner gates — present and wait.
