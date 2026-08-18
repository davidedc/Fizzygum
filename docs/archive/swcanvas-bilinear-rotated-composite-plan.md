> **ARCHIVED — ✅ COMPLETE (2026-08-12).** SWCanvas's transformed `drawImage` now samples at the
> dest pixel center with texel centers at +0.5 (native semantics), fixing thin-feature dropout in
> rotated island composites; all gates green (gauntlet 14/14 incl. webkit, `fg homepage` OK).
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Thin-feature dropout in rotated island composites — bilinear sampling for SWCanvas's transformed drawImage

> **STATUS 2026-08-12: ✅ COMPLETE — executed the same day as authored, all gates green
> (gauntlet 14/14 incl. webkit, `fg homepage` OK), D1 owner YES in-session.** S0/S1/S2 ran as
> specified. S2's spike FALSIFIED §4.1(3)'s floor-convention spelling (fraction measured from
> the floor texel): it keeps the gaps — measured live — and shifts content −0.5px per resample
> (a compensating wrapper would drift a full pixel). The landed shape samples at the DEST
> PIXEL CENTER with texel centers at +0.5 (native semantics); its zero-fraction case is a
> texel-center landing, so an exact-90° `setTransform` with integer translation reproduces
> pure texels crisply (pinned by SWCanvas `tests/core/057-drawimage-rotated-bilinear-contract.js`).
> Corollary caught by that test: pixel INCLUSION and sampling must share a convention per
> path — corner containment + center sampling drops an edge column at 90°. SWCanvas `619dc1c`
> pushed on main BEFORE the pin rewrite. Both suites failed with the IDENTICAL 37-test
> rotated-only list pre-recapture (the pure-scale island test unchanged — the §4.1 gate held);
> `fg recapture --auto` both dprs, with ONE silent per-density capture miss (dpr1 refs not
> written for `macroTransformFrameSlotTracksContentResize`) caught by the completeness gate
> and re-captured. §4.3.3 sweep of all 148 changed refs: CLEAN — the single text-color flag
> (`205→37,37,37`, dpr2 OverlappingRotatedIslands) is rotated "A"/"BEE" glyphs REGAINING
> pixels NN dropped, verified visually: in this change class, one-way color pairs are the
> EXPECTED signature (staircase retreat / fringe appearance / dropped features returning), so
> the sweep's one-way heuristic flags broadly and the triage key is WHAT the pair is, not that
> it is one-way. T2 authored with a DESELECT step — the teal selection overlay sits exactly on
> the border ring and otherwise hides the stroke at both dprs (MACRO-PATTERNS, affine
> section). Perf: rotated composite ~2.4× (1.13→2.75 ms per 400×300 warp; rotation path only),
> axis-aligned unchanged — measured by `debug/bench-rotated-drawimage.js` because
> `benchmark-session.js` has NO drawImage case (blind by construction). S1 probe gotcha: a
> centerline walk must index device pixels by floor(p), not round(p) — round() masked the
> double-resample repro entirely. D2 (axis-aligned scale-path smoothing) stays open in
> `docs/BACKLOG.md` (affine §7.8); D3 resolved as silent-always-bilinear-on-rotation, no API.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-12 at Fizzygum `3e354133` / Fizzygum-tests `dae43ecd0` / SWCanvas checkout
`430cafa` (= the vendored pin). Every `file:line`/quote below was verified on those trees;
lines drift — the method name / quoted code is authoritative, re-grep before trusting a number.

**MANDATE.** Eliminate — not mitigate — the defect class colloquially known as "thin-stroke
dashing inside compensating wrappers": ANY thin feature (a 1–2 device-px border, the teal
selection overlay, potentially hairline content) visibly DISINTEGRATES into dashes when it
renders inside a rotated `TransformFrameWdgt` island on the SWCanvas backend. The fix is at
the ONE place the pixels are actually destroyed: SWCanvas's transformed `drawImage` samples
nearest-neighbor, and the composite drops source pixels. This plan makes that composite
gap-free (bilinear), then re-baselines the affected references and closes the ledger items.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework on a single canvas, with two rendering backends
chosen at build time per entry page: native HTML5 2D (`index.html`, production) and the
deterministic software rasterizer **SWCanvas** (`worldWithSystemTestHarness.html` — what the
269+ SystemTest screenshot suite drives byte-exactly at dpr 1 and 2). SWCanvas is a SEPARATE
repo, vendored by pin (§1.4).

Affine transform "islands" (`TransformFrameWdgt`) give a subtree rotation/scale. The stroke
flip arc (`docs/archive/stroke-flip-and-fracplane-coverage-plan.md`, closed 2026-08-12, the
predecessor of this plan) flipped the rectangular border to 1 logical px and authored
`SystemTest_macroDropStrokedRectIntoRotatedPanel` (P3), which immediately exposed this
defect: the new test's references pin a black border rendered as sparse dashes, under a teal
selection overlay rendered as sparse dashes, on a payload dropped into a rotated container.
The BACKLOG item this plan discharges is in `docs/BACKLOG.md` under
`archive/stroke-flip-and-fracplane-coverage-plan.md` ("every THIN STROKE inside a
compensating wrapper rasterizes DASHED…").

**⭐ THE CRITICAL REFRAME (do not lose this):** the dashes are NOT a stroke-rasterization
problem and NOT a paint-body problem. Fizzygum islands render **straight-then-warp**
(`docs/architecture/transforms.md` §8): the island's content is rasterized UN-TRANSFORMED
into a buffer — where the stroke is perfectly SOLID — and the buffer is then composited
through the island matrix with `drawImage`. SWCanvas's transformed `drawImage` iterates
destination pixels, inverse-maps each into the source buffer, and picks the
nearest-neighbor texel (`Math.floor`). Along a 1–2-px-wide source feature under rotation,
the quantized sample point periodically lands on the background texel BESIDE the feature —
those destination pixels get background — the feature acquires GAPS. A **compensating
wrapper** (`TrackingTransformFrameWdgt`, the reparent-transparency sugar island that keeps a
payload screen-upright inside a rotated container, rotation ≈ −θ against the container's +θ)
suffers this TWICE: its own composite into the container's buffer (resample #1, at −θ), then
the container's composite to screen (resample #2, at +θ). Net rotation ≈ 0 on screen, but NN
resampling does not cancel — each pass drops pixels independently. A PLAINLY rotated island
(no wrapper) suffers it once and also dashes thin features, just less densely.

The stroke-flip arc FALSIFIED the body-side fix space empirically (§9), which is why this
plan goes straight to the compositor.

## §1 Current state (verified 2026-08-12)

### 1.1 The composite path (Fizzygum, `src/TransformFrameWdgt.coffee`)

`_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` picks: identity → stock
invisible-panel blit; pure scale → `_compositeScaleOnly` (axis-aligned src/dst-rect
`drawImage`, no `setTransform`); rotation → `_compositeTransformed` (verified at
`TransformFrameWdgt.coffee:576` call site / `:653` definition): composes
`(device × island matrix)` onto the CTM and `drawImage`s the whole buffer under a mandatory
path clip. `cachesBuffer: true` (`TransformFrameWdgt.coffee:45`) — the buffer is kept across
composites (island buffer cache, `transforms.md` §8.1); `TrackingTransformFrameWdgt` inherits
all of this. Nested case: when the container island RE-rasterizes its own buffer, the wrapper
inside paints like any widget — i.e. runs ITS `_compositeTransformed` against the container's
buffer context. That is resample #1.

### 1.2 The sampling site (SWCanvas, `src/core/Rasterizer.js`)

`drawImage` (`Rasterizer.js:647`) → `_drawImageInternal` (`:669`). For a transformed
destination: bounding box of the four transformed corners, then per device pixel:

```js
// Transform device pixel back to destination space …
const destPointX = invA * deviceX + invC * deviceY + invE;
const destPointY = invB * deviceX + invD * deviceY + invF;
…
const sourceXf = sourceX + (destPointX - destX) * xScale;
const sourceYf = sourceY + (destPointY - destY) * yScale;

// Nearest-neighbor sampling
const sourcePX = Math.floor(sourceXf);
const sourcePY = Math.floor(sourceYf);
```

then straight-alpha source-over compositing (inlined fast path for `source-over`). The
header comment in the shipped bundle states the design: "Sampling is nearest-neighbor
(consistent with the rest of SWCanvas — Pattern and drawImage are nearest-neighbor too)"
(`Fizzygum/vendor/swcanvas/swcanvas.js:1852`). There is NO `imageSmoothingEnabled` anywhere
in SWCanvas `src/` (grep verified — the property is unimplemented, not defaulted).

Note the existing FP-stability case law in that function: the same-size 1:1 blit keeps
`xScale === 1` and reduces to bit-exact integer arithmetic, with a long comment explaining
why the mapping must NOT be computed as `(d/dW)*sW`. Preserve that path and that reasoning.

### 1.3 The pinned evidence (Fizzygum-tests, committed at `dae43ecd0`)

- `SystemTest_macroDropStrokedRectIntoRotatedPanel` (both dprs): black 1-logical-px border +
  teal overlay on the wrapped payload rendered as sparse dashes. Color inventory of the
  border band at dpr1: only `70,130,210` (fill), `255,250,245` (panel), `38,166,154`
  (overlay dashes) — ZERO black pixels in a 12-row strip across the top edge.
- `SystemTest_macroDropIntoRotatedStretchablePanelStretchesOnResize`: the unstroked payload
  shows the same dashed teal overlay ring (proves the class predates the stroke flip).
- The retired 1-DEVICE-px border dashed the same way (never covered by any ref).

### 1.4 The vendoring flow (Fizzygum ⇄ SWCanvas)

- SWCanvas checkout: **`/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas`** (origin
  `davidedc/swcanvas.js`, HEAD `430cafa` = the pin). ⚠ That checkout has UNRELATED dirt (a
  modified `DIRECT-RENDERING-SUMMARY.MD`, an untracked `plans/direct-dispatch-gaps-and-coverage.md`)
  — leave it untouched; do not commit it with this arc's changes.
- SWCanvas dev loop: `npm run build && npm test` (46 core + 153 visual tests;
  `tests/run-tests.js`; perf: `node tests/direct-rendering/scripts/benchmark-session.js`).
- Vendor into Fizzygum: `Fizzygum/scripts/vendor-swcanvas.sh --source "/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas"`
  (vendors the locally-built `dist/` AND rewrites `vendor/swcanvas.pin` to that HEAD SHA).
  ⚠⚠ The from-pin mode downloads the tarball from GitHub by SHA — so the SWCanvas commit
  MUST be pushed before the Fizzygum pin commit lands, or any fresh clone breaks.
  (`vendor/swcanvas-release.pin` is only the font-assets release tag — untouched here.)
- After vendoring: full Fizzygum rebuild required (the SW bundle is baked into the boot JS).

## §2 Why it is shaped this way

NN sampling is deliberate v1 design, chosen for determinism and simplicity when the island
architecture landed ("render-straight-then-warp… v1 warps the whole buffer under the clip
(correctness-first)", `transforms.md` §8). The upgrade was ALREADY BANKED as affine plan
§7.8: "SWCanvas bilinear drawImage (separate repo; v1 uses nearest-neighbor)"
(`docs/BACKLOG.md`, affine section). Meanwhile the NATIVE backend rotates through the
browser's `drawImage`, which smooths (default `imageSmoothingEnabled = true`) — so today the
two backends genuinely diverge on rotated composites, and the SW look is the broken-seeming
one. This plan is that §7.8 item, scoped to where it eliminates the defect class.

## §3 The distilled argument

- The pixels are destroyed in exactly one function (`_drawImageInternal`'s NN sample under a
  non-axis-aligned transform). Fixing there fixes EVERY island composite — compensating
  wrappers (double resample), plain rotated islands (single), and every thin feature, not
  just strokes — with zero changes to Fizzygum paint bodies.
- Bilinear sampling cannot produce a pure-background gap along a continuous source feature:
  every dest pixel near the feature blends it in. Gaps (the defect) become impossible;
  softness (AA-like edges) is the accepted trade — and it CONVERGES SW toward what native
  already renders.
- Body-side alternatives are already falsified with byte-level evidence (§9) — the
  predecessor arc implemented the "snap to device grid" variant, captured BYTE-IDENTICAL
  references, and reverted it. There is no spelling fix; do not look for one.
- Scoping bilinear to NON-AXIS-ALIGNED transforms only (`b ≠ 0 || c ≠ 0`) keeps every
  existing non-rotated reference byte-identical BY CONSTRUCTION — the axis-aligned and 1:1
  paths are not even touched. The re-baseline is therefore confined to rotated-island scenes.

## §4 Fix shape

### 4.1 SWCanvas: bilinear on the non-axis-aligned path (the core change)

In `_drawImageInternal`, where the transform is non-axis-aligned (detect once, before the
loop: `transform.b !== 0 || transform.c !== 0` — use the actual field names of SWCanvas's
transform object, grep `transformPoint` in `src/core/`), replace the NN sample with
bilinear over the 4 neighboring texels. Non-negotiable requirements:

1. **Premultiplied filtering.** Source texels are STRAIGHT (non-premultiplied) RGBA, and
   island buffers have fully transparent backgrounds whose RGB is arbitrary. Naive straight-
   alpha lerp bleeds that arbitrary RGB into edges (dark fringes). Weight each texel's RGB by
   its alpha, lerp premultiplied, un-premultiply at the end (guard the a=0 case).
2. **Edge policy: clamp-to-edge inside the source rect,** treating texels outside the
   `sx/sy/sw/sh` sub-rect as transparent black (premultiplied zero) — NOT clamped content —
   so a blit does not smear pixels that were never part of the source rect. (The existing
   out-of-bounds `continue` becomes a per-tap transparent contribution.)
3. **Bit-exactness where the fraction is zero.** When both sample fractions are 0 the
   result must equal the NN result exactly (weights 1/0/0/0 — add the explicit fast path).
   This is belt-and-braces: the axis-aligned/1:1 paths are already untouched by the gate in
   the enclosing `if`, but the zero-fraction fast path protects any rotated-by-90°-style
   composite that still lands on integer coordinates.
4. **Determinism.** Plain double arithmetic, fixed operation order, no `Math.fround` — must
   be byte-identical on V8 and JSC (the suite's webkit leg re-verifies the SAME refs).
5. **Do NOT touch** the axis-aligned scale path, the 1:1 fast path, or the `(d/dW)*sW`
   FP case law (§1.2). Scale-path smoothing is explicitly OUT OF SCOPE (§10 D2).

Add a SWCanvas-side regression test (their `tests/core/` shape — copy an existing test's
harness idiom): a 2-px line in a source bitmap, `drawImage`d under a 30° rotation, assert
ZERO interior gaps — walk the dest centerline, max background run ≤ 1 px — plus an
alpha-edge case (line over transparent background, assert no dark fringe: no dest pixel
darker than the line color) and a zero-fraction case asserting byte-equality with NN.
Update `DIRECT-RENDERING-SUMMARY.MD` / `ARCHITECTURE.md` where they state NN sampling
(⚠ that summary file is locally dirty with unrelated WIP — coordinate, don't clobber).

### 4.2 Owner look-gate BEFORE any re-baseline (hard gate, like the stroke flip's)

Bilinear visibly changes EVERY rotated island's look on the SW page (softened edges, solid
thin features). Render an A/B (current vendored build vs locally-vendored spike build) of at
least: the P3 scene, the template drop scene, and one tilted-window scene
(`fg diffpage` after a spike vendor, or side-by-side crops like the predecessor arc's
`.scratch/rectprobe-*` flow). **Get an explicit owner YES on the new look before recapturing
anything.** If the owner declines: STOP, revert the vendor, keep the plan for a future
sampling policy (do not invent a middle-ground filter unilaterally).

### 4.3 Fizzygum: re-baseline + coverage

1. Vendor (`--source`), rebuild, then `fg suite` + `fg suite --dpr=2`: the fail list IS the
   re-baseline candidate set. Expect ONLY rotated-composite scenes (Tilted*, Rotate*,
   TransformFrame* rotated family, DropIntoRotated*, DropStrokedRect*, SaveAsPromptAboveTilted*,
   DropKeepsHandOrientation, hierarchy/overlap rotated tests, …). **Any NON-rotated test in
   the fail list = the §4.1 scoping leaked — STOP and root-cause before recapturing.**
2. `fg recapture --auto` to COMPLETE (both dprs in one pass — unlike the stroke flip, BOTH
   densities legitimately change here).
3. **Color-pair sweep of every changed ref** (the predecessor arc's
   `Fizzygum-tests/.scratch/sweep-recapture-diffs.js` pattern — pair old git-HEAD vs new by
   image key, inventory differing color pairs): expect edge-blend colors appearing and dash
   gaps disappearing, all confined to rotated regions. It exists to catch another
   atlas-race-corrupted capture (that trap fired once already — see the archive stamp of the
   predecessor plan) and any unexpected diff class. ⚠ A text-blob color pair
   (`240,240,240 → 37,37,37`-style) = a corrupted capture: fix the capture, never keep it.
4. Acceptance pin, P3: crop the new `SystemTest_macroDropStrokedRectIntoRotatedPanel` refs —
   the black border and teal overlay must be CONTINUOUS (walk the ring: no background run
   > 1 px). Same check on the template test's overlay.
5. New test T2 (author AFTER the fix so refs carry the fixed look — the predecessor arc's
   ordering lesson): `SystemTest_macroRotatedStrokedRectSingleComposite` — the SINGLE-
   composite pin. Scene: stroked rect dropped into the stretchable container BEFORE rotation
   (a plain child, like the template's w1 but with `strokeColor = Color.BLACK` set before
   `world.add`), rotate 30°, screenshot, resize 300→420, screenshot. Author per the tests
   repo's `/author-macro-test` skill; capture `--dprs=1,2`; visualisation page.
6. Close gates: full `fg gauntlet` (its webkit leg re-verifies the re-baselined refs
   cross-engine — this is the JSC-determinism proof for the new arithmetic) + `fg homepage`.

### 4.4 Docs + ledger (Fizzygum)

- `docs/architecture/transforms.md` §8: the rotation composite is now bilinear-sampled
  (state the premultiplied + non-axis-aligned-only + zero-fraction-exact contract, and WHY:
  NN drops thin features; keep "v1 was NN" as one historical clause, no dates).
- `docs/architecture/appearance-paint-convention.md`, the `paintStroke` bullet: delete the
  "rasterization-class limit / dashes" caveat sentence block, replace with one line: thin
  strokes render continuously under rotated composites since the bilinear sampling change
  (pointer to transforms.md §8).
- `src/basic-widgets/RectangularAppearance.coffee` `paintStroke` comment: same trim (the
  "rasterizes dashed … ledgered in docs/BACKLOG.md" clause goes; the "snapping is provably
  the identity" clause STAYS — it is standing case law against a re-attempt).
- `docs/BACKLOG.md`: check off the thin-stroke item under the stroke-flip archive section
  (annotate: fixed at the compositor, plan name); update the affine section's §7.8 line
  (rotation path DONE; scale-path smoothing still open if the owner wants it).
- Close-arc flow: `git mv` this plan to `docs/archive/` + status stamp + `archive/INDEX.md`
  entry + memory note (per the umbrella `/close-arc` skill if available).

## §5 Spikes (run in order; each has a kill criterion)

- **S0 — native A/B (30 min, no code changes).** Open `Fizzygum-builds/latest/index.html`
  (native, current build) and build the scene via the console:
  `world.evaluateString "c = new StretchableWidgetContainerWdgt; world.add c; c.moveTo new Point 70,40; r = new RectangleWdgt (new Point 90,55), Color.create 70,130,210; r.strokeColor = Color.BLACK; c.contents.add r; r.moveTo new Point 120,90; c.setRotationDegrees 30"`
  (adjust: the essential thing is a stroked rect INSIDE the rotated container). Expected:
  native shows a continuous (anti-aliased) border. Confirms the defect is SW-only and pins
  the target look. If native ALSO dashes → the mechanism model is wrong — STOP, re-derive.
- **S1 — SWCanvas minimal repro (1 h).** In the SWCanvas checkout, a standalone script:
  32×32 surface, 2-px line bitmap, `drawImage` under `rotate(30°)`, count centerline gaps.
  Expected: gaps > 0 under NN. This becomes the §4.1 regression test's fixture. If NO gaps
  reproduce at the SWCanvas layer → the dropout lives in Fizzygum's composite geometry
  instead — STOP, re-derive against `_compositeTransformed`.
- **S2 — bilinear prototype (0.5 day).** Implement §4.1 behind nothing (just the branch),
  `npm run build && npm test` — expect the 153 visual tests to expose any accidental
  axis-aligned change (they must ALL pass unchanged if the scoping is right; SWCanvas's own
  suite is the byte-compat oracle at that layer). Then S1 asserts zero gaps. Then vendor
  `--no-pin-update` into Fizzygum for the §4.2 A/B.

## §6 Central risks

1. **Blast-radius leak** — bilinear accidentally engaging on axis-aligned blits (back
   buffers, text scratch blits, BitmapText glyph traffic) would churn EVERY reference and
   break text byte-exactness. Defense: the `b/c ≠ 0` gate + SWCanvas's own 153 visual tests
   + §4.3.1's "only rotated scenes may fail" STOP rule.
2. **Alpha fringes** from straight-alpha lerp (§4.1.1) — the island-buffer background is
   transparent, so this WILL show if done naively; the S1 alpha case pins it.
3. **Cross-engine determinism** — new float arithmetic must match on V8/JSC; plain doubles
   with fixed order do (existing precedent: DetTrig exists because trig did NOT — do not
   introduce transcendental functions here). The gauntlet webkit leg is the proof.
4. **Perf** — bilinear = 4 taps + lerps, rotation path only (already the slow path; spins
   during drags). Run SWCanvas's `benchmark-session.js` before/after; flag > ~10% regression
   on rotated-composite-heavy cases to the owner rather than silently accepting.
5. **Corrupted captures during the mass recapture** — the atlas-race trap (predecessor arc
   found a hand-carried window freezing placeholder text into a ref). The §4.3.3 sweep is
   the required detector; the dpr1-invariance oracle does NOT exist this time (both dprs
   change), so the sweep is the ONLY line of defense — do not skip it.
6. **Pin ordering** — push the SWCanvas commit BEFORE committing Fizzygum's rewritten
   `vendor/swcanvas.pin` (§1.4). A pin naming an unpushed SHA breaks every fresh clone.
7. **The SWCanvas checkout's unrelated dirt** (§1.4) — branch from `430cafa` for this work;
   leave the dirty files out of the commit.

## §7 Cold-execution protocol

1. Read this doc fully. Then: `Fizzygum/docs/architecture/transforms.md` §8–8.2, the
   predecessor archive `docs/archive/stroke-flip-and-fracplane-coverage-plan.md` (status
   stamp + §6), and SWCanvas's `CLAUDE.md` + `ARCHITECTURE.md` (rasterizer section).
2. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (expect clean repos at
   `3e354133`/`dae43ecd0` or later, build FRESH; this plan file may be the only Fizzygum
   dirt). Verify the SWCanvas checkout still sits at the pin:
   `git -C "/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas" log --oneline -1` vs
   `cat Fizzygum/vendor/swcanvas.pin` — if they diverge, STOP and reconcile first.
3. Re-verify §1's quotes (grep `_compositeTransformed`, the "Nearest-neighbor sampling"
   comment in `Rasterizer.js`, `cachesBuffer`).
4. Spikes S0 → S1 → S2, honoring their kill criteria.
5. Owner look-gate §4.2 — HARD STOP until an explicit YES in-session.
6. SWCanvas: finalize §4.1 + regression tests + SWCanvas docs; commit on a branch off the
   pin; `npm run build && npm test` green; PUSH (merge per that repo's habit).
7. Fizzygum: vendor `--source` (pin rewritten), `fg build`, §4.3 steps 1–4 in order with
   their STOP rules, then T2 (§4.3.5), then `fg presuite` (the `fracplane` rider now guards
   the wrapper scene at dpr2 in the inner loop), then full `fg gauntlet` + `fg homepage`.
8. Docs + ledger (§4.4). Commits: SWCanvas repo first, then Fizzygum (src-less: vendor pin +
   docs), then Fizzygum-tests (re-baseline + T2) — `git commit -F <file>`, push only on
   owner OK (standing rule: ask before commit/push).
9. House rules: `fg` wrapper for build/test; long ops launched ONCE in background, wait for
   the task notification; Edit tool only on `.coffee`; never edit a running op's inputs;
   `Fizzygum-tests/.scratch/` for Node probes (never the session scratchpad — `require()`
   resolves from the script's directory).

## §8 Verification protocol (the concrete gate list)

- SWCanvas layer: `npm run build && npm test` (all green, zero visual-test drift), new
  gap/fringe/zero-fraction tests green, `benchmark-session.js` delta reported.
- Fizzygum layer: `fg build` → targeted `fg suite` + `fg suite --dpr=2` (fail list =
  rotated-only, else STOP) → `fg recapture --auto` to COMPLETE → color-pair sweep clean →
  P3 + template continuity crops eyeballed → T2 authored + captured + green → `fg presuite`
  → `fg gauntlet` 14/14 → `fg homepage` OK.
- The defect is DEAD when: P3's refs show continuous border + overlay at both dprs, T2's
  refs show a continuous border on the single-composite scene, and the SWCanvas regression
  test locks the compositor.

## §9 Rejected alternatives — do NOT re-attempt (falsification evidence attached)

- **Device-grid snapping in `paintStroke` (or any body spelling).** Implemented and
  falsified 2026-08-12: captures came back BYTE-IDENTICAL to the raw spelling — a widget's
  own plane position is integer by the placement law (`Math.round` is dead code there), and
  the fractional figure origin + rotation live in the CTM, which the appearance law forbids
  a body from reading. Case law in the predecessor archive + `paintStroke`'s comment.
- **AA/coverage-tolerant stroke rasterization in SWCanvas.** Wrong layer: the stroke is
  already SOLID in the island buffer (render-straight-then-warp). Verified via the composite
  architecture (§1.1) — the dropout happens at `drawImage` time.
- **Thicker strokes / minimum-width hacks in paint bodies.** Leaks compositing knowledge
  into bodies, changes the owner-approved 1-logical-px look everywhere, and still dashes at
  sufficient rotation angles.
- **Flattening nested island composites** (compose matrices, composite the deepest buffer
  once to screen). Does not eliminate the class — a SINGLE NN resample already dashes thin
  features (the plainly-rotated case) — and it is an invasive z-order/damage architecture
  change for at best a partial win. Revisit only as a perf idea after bilinear lands.
- **Wontfix / "the SW page is dev-only".** The suite pins SW pixels as the product's
  behavioral record, the owner runs the SW page (memory: fizzygum-runtime-backend-swcanvas),
  and native ALREADY smooths — the parity argument runs toward the fix, not away from it.

## §10 Owner decision points (ask in-session, at the marked gates)

- **D1 (the §4.2 look-gate):** accept the bilinear look on rotated islands (softened edges
  everywhere, continuous thin features). The whole plan is gated on this YES.
- **D2 (scope):** Phase 1 deliberately leaves the axis-aligned SCALE path NN (byte-compat;
  `imageSmoothingEnabled` stays unimplemented). If the owner wants HTML5-faithful smoothing
  on scaled blits too, that is a SEPARATE follow-up with its own (much larger) re-baseline.
- **D3 (SWCanvas API shape):** silent always-bilinear-on-rotation (recommended, zero API) vs
  implementing `imageSmoothingEnabled` now. Recommend D3-silent; the flag can come with D2.

## §11 References

- Predecessor arc + evidence: `docs/archive/stroke-flip-and-fracplane-coverage-plan.md`
  (status stamp), `archive/INDEX.md` entry, memory `stroke-flip-and-fracplane-arc`.
- Island architecture: `docs/architecture/transforms.md` §8–8.2;
  `docs/archive/island-buffer-cache-plan.md`.
- Banked upgrade: affine plan §7.8 (`docs/BACKLOG.md`, affine section).
- SWCanvas: `/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas` — `CLAUDE.md`,
  `ARCHITECTURE.md`, `src/core/Rasterizer.js`, `DIRECT-RENDERING-SUMMARY.MD` (locally dirty).
- Vendoring: `Fizzygum/scripts/vendor-swcanvas.sh` header; `vendor/swcanvas.pin`.
- Memory: `dont-let-recapture-churn-dictate-design`, `no-conclusions-before-evidence`,
  `stop-iterating-fix-shapes-after-two-falsifications`, `ask-before-commit-push`.
