# Axis-aligned SCALE-path smoothing for SWCanvas's drawImage (the bilinear arc's D2)

> **STATUS 2026-08-13: ✅ COMPLETE — executed the day after authoring, all gates green
> (recapture COMPLETE at both dprs; gauntlet 14/14 incl. webkit, settle leg green on the
> serial retry = the documented load-flake path; `fg homepage` OK), owner gates D2a/D2b/D2c
> answered in-session.**
> S0/S1/S2 ran as specified; S1's fail lists were IDENTICAL at both dprs and scaled-scenes-only
> (kill criteria passed — zero step-1/text churn, the exactness rule held by construction).
> ⭐ D2a came back AMENDED: the owner asked for INTEGER scales (and 90°-multiple grid transforms)
> to stay NN — landed as a FIZZYGUM-layer policy via the now-standard flag
> (`_compositeScaleOnly` sets `imageSmoothingEnabled = false` when `s == round(s)`), keeping the
> SWCanvas engine HTML5-conformant (default-smooth) while both backends render integer zooms
> crisp; that shrank the re-baseline from 7 tests to ONE (`macroSampleSlideEditViewToggle`'s
> edit-mode toolbar, a non-integer-downscaled icon caption). The 90° half of the ask is
> DEFERRED to BACKLOG behind quadrant-exact `TransformSpec._cosSin`: at 90-multiples the spec
> matrix carries ~1e-16 trig residues and NN's floor through a residue-skewed inverse picks
> wrong texels (the §9 snap-trick case law stands — do not snap at the composite).
> ⭐ S1 surfaced a REAL defect the plan's §1.2 table missed: `_compositeScaleOnly`'s per-strip
> src sub-rects gave each damage strip its own rounded mapping (half-texel phase shift +
> tap starvation at strip edges) — incremental composites visibly diverged from full ones
> under bilinear (`OversizedShadowChildInScaledIslandRepaintsBuffer`'s numeric A/B, 708/1420 px).
> Fixed by re-shaping the composite to the rotation path's proven form: the WHOLE buffer through
> ONE mapping under a rect damage clip (byte-identical strips BY CONSTRUCTION, same inner-loop
> cost via SWCanvas' Tier-0 clip; pinned SWCanvas-side by 058's seam test).
> ⭐ S2 falsified the §4.2 compounding worry empirically: a 4-resize StretchableCanvas sequence
> is byte-identical to one direct resize (it always re-blits the pristine original — no opt-out
> needed). Perf (isolated processes): step-1/rotated unchanged, scaled composites ~2.6×.
> `imageSmoothingEnabled` landed per HTML5 (default true, boolean-coerced, save/restore, BOTH
> API layers; false forces NN for every transform) — ⚠ `Rasterizer.beginOp` WHITELISTS op
> fields, so the flag had to be added there too (a silently-dropped param reads as default-true).
> ⚠⚠ TWO measurement traps burned this arc, both "prove the injection is live" lessons:
> (1) `npm run build` does NOT regenerate `dist/swcanvas.min.js` — and the Fizzygum boot bundle
> embeds the MIN bundle, so the first S1 suite ran the OLD sampler and returned an all-green
> phantom (caught because green contradicted the sampling math; `npm run minify` before every
> vendor). (2) the per-line FAIL grep of a parallel suite log is INTERLEAVED and lossy — read
> the `failed tests (N): [...]` summary line, never per-line greps.
> ⚠ `fg recapture --auto`'s classifier mis-filed the one genuinely pixel-stale test as
> "needs-a-fix (failureImages=0)" while a single run visibly dumped a failing image, and a
> parallel suite leg returned a phantom PASS for it (the zero-failed-screenshots-masks-an-error
> gotcha) — re-captured via the per-test `capture-macro-test-references.js` + re-gated; the
> classifier quirk is noted for a tooling follow-up. Sweep over the 2 changed refs: CLEAN.
> T-scale test `SystemTest_macroScaledStrokedRectSmooth` pins BOTH policy faces (1.5× smooth,
> then `setScale 2` crisp) — captured both dprs, stable ×6. SWCanvas commit pushed on main
> BEFORE the pin rewrite (dual suites 244/244 green, test counts re-synced).

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-12 at Fizzygum `2e8e3e10` / Fizzygum-tests `20877b2b9` / SWCanvas `619dc1c`
(= the vendored pin; all three pushed). Every `file:line`/quote below was verified on those
trees; lines drift — the method name / quoted code is authoritative, re-grep before trusting
a number.

**MANDATE.** Close the remaining half of the drawImage sampling divergence between SWCanvas
and native: axis-aligned SCALED composites still sample nearest-neighbor (chunky pixel
duplication on upscale, row/column dropping on downscale), while native smooths them
(`imageSmoothingEnabled` defaults true). Eliminate the divergence — smooth what actually
resamples, keep everything that does not resample byte-identical — and implement
`imageSmoothingEnabled` so opting out stays possible per HTML5 semantics. This is owner
decision D2 of the closed bilinear arc (`docs/archive/swcanvas-bilinear-rotated-composite-plan.md`
§10), commissioned 2026-08-12.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework on a single canvas, two build-time backends: native
HTML5 2D (`index.html`, production) and the deterministic software rasterizer **SWCanvas**
(`worldWithSystemTestHarness.html` — what the 292-test SystemTest suite screenshots
byte-exactly at dpr 1 and 2). SWCanvas is a separate repo vendored by pin
(`Fizzygum/vendor/swcanvas.pin`; local checkout
`/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas`, dev loop `npm run build && npm test`,
vendor via `Fizzygum/scripts/vendor-swcanvas.sh --source …` which rewrites the pin — the
SWCanvas commit MUST be pushed before the Fizzygum pin commit lands).

The predecessor arc (CLOSED + PUSHED 2026-08-12, SWCanvas `619dc1c` / Fizzygum `2e8e3e10` /
tests `20877b2b9`; archive + full case law:
`docs/archive/swcanvas-bilinear-rotated-composite-plan.md`, memory
`swcanvas-bilinear-rotated-composite-arc`) made SWCanvas's transformed `drawImage` sample
BILINEAR on **non-axis-aligned** transforms (`transform.b !== 0 || transform.c !== 0`):
premultiplied filtering, dest-pixel-CENTER sampling with texel centers at +0.5, a
zero-fraction pure-texel fast path, per-path containment/sampling coherence. That eliminated
thin-feature dashing in rotated islands and re-baselined 37 rotated-only tests. It
deliberately did NOT touch any axis-aligned path — which is why its re-baseline stayed small
and why THIS plan exists as a separate arc with its own gates.

**⭐ THE CRITICAL REFRAME (do not lose this): "axis-aligned scaled" is NOT "src/dst rects
differ", and it is NOT "the CTM has non-unit scale" — it is "the EFFECTIVE SAMPLE STEP ≠ 1".**
The rasterizer maps each device pixel through the inverse CTM into the dest rect, then into
the source via `xScale = sourceWidth / destWidth` (Rasterizer.js:790). The per-device-pixel
source step is therefore `invA * xScale` horizontally / `invD * yScale` vertically — the CTM
scale and the rect ratio COMPOSE. Fizzygum traffic proves both halves matter:

- `StretchableCanvasWdgt` re-blits its own back buffer under `ctx.scale w/oldW, h/oldH` with
  SAME-SIZE rects (`src/authoring/StretchableCanvasWdgt.coffee:61-63`) — CTM-scaled, rect-1:1.
  A gate keyed on rect ratio alone MISSES it.
- `TransformFrameWdgt._compositeScaleOnly` (`src/TransformFrameWdgt.coffee:592`) draws the
  island buffer with DIFFERING src/dst rects in device space — rect-scaled, CTM-identity-ish.
- Meanwhile most dpr-2 traffic is scale(2) CTM × a `1/ceilPixelRatio` compensation (e.g.
  `StretchableCanvasWdgt.coffee:160`, and the physical-pixel buffer discipline everywhere) —
  effective step EXACTLY 1 — and every dpr2 reference byte-pins that. Smoothing anything with
  step 1 would churn the entire dpr2 reference set including text. The step-1 set must stay
  bit-exact BY CONSTRUCTION, not by luck.

## §1 Current state (verified 2026-08-12 on the pushed trees)

### 1.1 SWCanvas sampling policy as landed (`src/core/Rasterizer.js`)

`_drawImageInternal`: bbox of the four transformed dest-rect corners → per device pixel:
corner-mapped inverse transform, then

- `const useBilinear = (transform.b !== 0 || transform.c !== 0);` (Rasterizer.js:802) —
  bilinear branch: dest-pixel-CENTER containment + sampling (`centerOffX/Y = (invA+invC)*0.5`
  etc.), texel centers at +0.5, premultiplied 4-tap accumulate in fixed order (00,10,01,11),
  taps outside the `tapMinX..tapMaxX × tapMinY..tapMaxY` sub-rect bounds contribute
  transparent black, `fx === 0 && fy === 0` pure-texel fast path (bit-exact NN of that point).
- NN branch (ALL axis-aligned transforms today): corner-mapped containment,
  `Math.floor(sourceXf)` sample, image-bounds check.
- `xScale = (destWidth === sourceWidth) ? 1 : sourceWidth / destWidth` with the long
  FP-stability comment (do NOT compute `(d/dW)*sW` per pixel — precomputed-ratio only). The
  1:1 same-size case reduces to bit-exact integer arithmetic. **Preserve that comment and
  that property.**
- `imageSmoothingEnabled` does NOT exist anywhere in SWCanvas `src/` (grep re-verified at
  `619dc1c`) — unimplemented, not defaulted. Contract tests for the landed rotation policy:
  `tests/core/057-drawimage-rotated-bilinear-contract.js` (5 tests; suite total 235).

### 1.2 Fizzygum's axis-aligned drawImage traffic (the blast-radius inventory)

Grep `drawImage` in `Fizzygum/src` — the callers that matter, characterized:

| Caller | Shape | Effective step | D2 effect |
|---|---|---|---|
| `TransformFrameWdgt._compositeScaleOnly` (:592) | rect-scaled device-space blit of the island buffer (src sub-rect clamped; dst edges rounded) | ≠ 1 when island scale s ≠ 1 | **smooths** — the primary target |
| `StretchableCanvasWdgt` :61-63 | CTM-scaled (`ctx.scale`) same-rect re-blit of its own back buffer on resize | ≠ 1 during/after stretch | **smooths** — and NOTE it self-compounds: each resize re-blits the previous blit's output |
| `BackBufferMixin` blit; `Appearance` shadow-scratch blit (:120 `drawImage scratch, 0,0,w,h, al,at, w,h`); BitmapText per-glyph + scratch-to-main | same-size rects, cpr-compensated CTM | **exactly 1** | MUST stay byte-identical (the bit-exactness rule §4.1.3) |
| `SimpleImageWdgt` :84 (`drawImage @img, 0,0, extent.x, extent.y`), `VideoPlayerCanvasWdgt` | rect-scaled image content | ≠ 1 | smooths — but `video-player` is a flag-gated part: NOT in any standard build, zero refs |
| `CanvasWdgt` :62, `Deserializer`, `Duplicator`, `HTMLCanvasElement-extensions` | same-size copies | 1 | unchanged |

Scaled-island SystemTests that pin the NN look today (none of them failed in the bilinear
arc — proof they sit on the axis-aligned path): `SystemTest_macroTransformFrameScaledRenders`,
`…ScaledCaretSlot`, `…ScaledClickThrough`, `…ScaledDragged`, `…ScaledTextEditRepaints`,
`…TransformFrameResizeInsideScaledIsland`, `…OversizedShadowChildInScaledIslandRepaintsBuffer`.
Expect these (plus any StretchableCanvas / stretched-app scenes) to be the re-baseline set —
**but the set is MEASURED by the S1 spike, never assumed**: the dpr-compensation dance means
step-1 traffic hides everywhere, and one unexpected test class in the fail list = STOP.

### 1.3 What the docs currently say

- `docs/architecture/transforms.md` §8 "Sampling contract (SWCanvas)": bilinear on rotation;
  §9 bullet "Sampling: bilinear on rotation, nearest-neighbor on scale" states scale-path
  smoothing is a deliberately separate decision and `imageSmoothingEnabled` unimplemented.
- `docs/BACKLOG.md` affine §7.8 line: rotation half DONE, scale half open behind D2.
- SWCanvas `README.md` "Image Rendering" section: describes the split as of `619dc1c`.

## §2 Why it is shaped this way

v1 SWCanvas sampled NN everywhere (determinism + simplicity). The bilinear arc scoped its fix
to non-axis-aligned transforms precisely so its re-baseline would be confined to rotated
scenes by construction. The scale path was left NN because (a) axis-aligned UPSCALE cannot
gap a thin feature (it only duplicates pixels — chunky, not broken), so there was no
correctness mandate, and (b) the axis-aligned path carries ALL the byte-pinned text/back-buffer
traffic, so touching it responsibly requires the effective-step analysis above plus its own
mass re-baseline. Native, meanwhile, smooths scaled draws by default — so scaled islands,
stretched canvases and scaled images are the one remaining place the two backends visibly
disagree.

## §3 The distilled argument

- The resampling seam is ONE function (`_drawImageInternal`), already carrying a correct,
  landed bilinear implementation (premultiplied, center-convention, fast-pathed). D2 is not
  new machinery — it is widening the gate from `b≠0||c≠0` to "the sample actually steps
  through the source at ≠ 1", reusing the same 4-tap code.
- The step-1 bit-exactness rule keeps every glyph blit, back-buffer blit and shadow-scratch
  blit byte-identical BY CONSTRUCTION — the same trick that kept the rotation arc's blast
  radius honest (there: axis-aligned untouched; here: step-1 untouched).
- `imageSmoothingEnabled` gives the escape hatch HTML5 users expect (pixel-art canvases,
  crisp intentional upscales). Implementing it now, with the default true, converges the API
  toward the standard instead of inventing a third state.
- The predecessor arc's tooling is all reusable as-is: the recapture completeness gate, the
  color-pair sweep (`Fizzygum-tests/.scratch/sweep-recapture-diffs.js`), `fg diffpage` for the
  look-gate, `debug/bench-rotated-drawimage.js` extendable for scale cases.

## §4 Fix shape

### 4.1 SWCanvas: smooth when the effective step ≠ 1 (the core change)

In `_drawImageInternal`:

1. **Gate.** Hoist, next to `useBilinear`: the axis-aligned smooth condition. The effective
   steps are `stepX = invA * xScale`, `stepY = invD * yScale` (invA/invD already hoisted;
   for axis-aligned transforms invB=invC=0 so these are exact). Smooth when
   `imageSmoothingEnabled && (b !== 0 || c !== 0 || stepX !== 1 || stepY !== 1 || <phase ≠ integer>)`
   — BUT do not literally restructure into one condition without care: the required behavior is
   - non-axis-aligned → bilinear branch (unchanged from `619dc1c`),
   - axis-aligned AND smoothing on AND (stepX ≠ 1 or stepY ≠ 1) → the SAME bilinear branch,
   - axis-aligned AND (smoothing off OR pure step-1 translation) → the historical NN branch
     **byte-for-byte**.
   ⚠ Phase subtlety: step-1 with a FRACTIONAL translation (a same-size blit at a fractional
   position) resamples too. Native smooths it; today's NN floor-snaps it. Decide with a
   measurement in S1 whether any Fizzygum traffic hits step-1-fractional-phase (integer
   placement law says it shouldn't on-plane; scratch blits are integer). If none: gate on
   step alone and let the zero-fraction fast path make integer-phase step-1 exact — the
   simplest spelling, and the fast path is then the ONLY thing keeping text byte-exact, which
   the S1 fail list verifies empirically. If S1 shows churn from this: tighten the gate to
   exclude step-1 entirely.
2. **Reuse the landed bilinear branch as-is** — same premultiplied 4-tap, same center
   convention, same tap bounds, same fast path. For axis-aligned smoothing the center
   convention matters just as much: a scaled blit under the corner convention would shift
   content half a texel (the predecessor arc falsified exactly that class of error for
   rotation — do not re-derive it, see §9).
3. **Bit-exactness where nothing resamples.** step-1 integer-phase axis-aligned draws must
   produce the historical NN bytes exactly, whichever branch they flow through. This is the
   §4.1(3) analog of the rotation arc's zero-fraction rule and it is what keeps ~all dpr2
   refs (text included) out of the re-baseline.
4. **`imageSmoothingEnabled`.** Implement per HTML5: default `true`; settable boolean;
   participates in save/restore state. Wire it in BOTH API layers (dual-API parity is a
   SWCanvas invariant): `src/core/Context2D.js` AND `src/compat/CanvasCompatibleContext2D.js`.
   Semantics: `false` forces the NN branch for ALL transforms — including rotation, matching
   the HTML5 property — ⚠ which makes it possible to re-introduce rotated dashing
   DELIBERATELY; Fizzygum never sets it false (grep to confirm at execution time), so no
   Fizzygum ref depends on the false path; SWCanvas-side tests cover it.
5. **Do NOT touch** the `(d/dW)*sW` FP case law, the 1:1 `xScale === 1` reduction, or the
   NN branch's corner-mapped containment.

### 4.2 Fizzygum-side policy decision (owner gate D2b, ask WITH the look-gate)

With smoothing default-true, all step≠1 Fizzygum sites smooth. The owner may want per-site
opt-outs (`ctx.imageSmoothingEnabled = false` around a specific blit):
- **Scaled islands** (`_compositeScaleOnly`): expected YES-smooth (native parity; this is the
  D2 point). Includes glyphs inside scaled islands going smooth — the most owner-visible
  change; render it in the A/B explicitly.
- **`StretchableCanvasWdgt`**: judgement call — it re-blits its OWN previous output on every
  resize, so smoothing COMPOUNDS blur across successive resizes. Present an A/B of a
  drag-resize sequence at the gate; if compounding blur is unacceptable, set
  `imageSmoothingEnabled = false` around that one blit (crisp NN, current behavior) or
  restructure to always re-blit from `@behindTheScenesBackBuffer` at cumulative scale
  (better; check whether that is already the shape before proposing it).
- **`SimpleImageWdgt`/video-player**: flag-gated part, zero refs — takes the default, no
  decision needed.

### 4.3 Tests (provisioned up front, per owner instruction)

1. **SWCanvas contract test** `tests/core/058-drawimage-scaled-smoothing-contract.js`
   (follow 057's shape; concat build auto-includes; core tests need no metadata):
   - non-integer upscale (e.g. 3→7px) of a hard-edge pattern: interior blend values present
     (not pure source colors) — smoothing engaged;
   - **step-1 integer-phase byte-equality**: a same-size blit and a cpr-style
     scale(2)×0.5-rect... (spell it as: `ctx.scale(2,2)` + `drawImage(img,0,0,w/2,h/2)`
     — wait, that is rect-scaled; the honest step-1 case is `ctx.scale(2,2)` +
     a HALF-size... no: step = invA·xScale = 0.5·1 — construct the true step-1 cases:
     identity same-size, and `ctx.scale(2)` with `drawImage(img,0,0)` of a
     physical-resolution source drawn at logical size via rect `w/2 × h/2` giving
     invA·xScale = 0.5·2 = 1) — assert byte-equality with the pre-change NN output
     (capture the expectation as literal pixels in the test, not by dual-running);
   - `imageSmoothingEnabled = false` → NN bytes on a scaled blit; property default true;
     survives save/restore; settable through BOTH API layers;
   - downscale (e.g. 8→3px): no crash, deterministic output, weights sane (sum of a
     solid-color region stays that color).
2. **Fizzygum SystemTest T-scale** (author AFTER the fix so refs carry the fixed look; use
   the tests repo's `/author-macro-test` skill): `SystemTest_macroScaledStrokedRectSmooth` —
   a black-stroked rect (strokeColor set before `world.add`, DESELECT after the drop — the
   teal selection overlay sits exactly on the border ring and hides the stroke,
   MACRO-PATTERNS affine section) inside a container scaled to a NON-INTEGER factor (pin the
   scale in the fixture, e.g. `setScale 1.5` / the TransformSpec spelling the Scaled* tests
   use — copy `macroTransformFrameScaledRenders`'s fixture idiom), screenshot; resize/rescale,
   screenshot. Pins smooth-scale continuity + the absence of NN chunking. Capture
   `--dprs=1,2`, visualisation page, stability ×3.
3. **Re-baseline** via `fg recapture --auto --dprs=1,2` (the completeness gate catches silent
   per-density misses — it fired once in the predecessor arc) + the **color-pair sweep**
   (`Fizzygum-tests/.scratch/sweep-recapture-diffs.js`) over every changed ref. Sweep triage
   law (predecessor case law): one-way pairs are the EXPECTED signature of a sampling change
   (hard edges→blends); triage by what/where visually, not by one-wayness; a text-blob pair
   in an UNSCALED region = corrupted capture, fix the capture never the ref.

### 4.4 Docs + ledger (provisioned up front, per owner instruction)

- SWCanvas repo: `README.md` Image Rendering section (smoothing model + the property);
  `ARCHITECTURE.md` if it gains a sampling paragraph; `tests` count re-sync
  (`npm run update-test-counts`); `Texture3D.js` header parenthetical re-check (currently
  says "only non-axis-aligned drawImage samples bilinear" — becomes "drawImage smooths
  whenever it resamples; Texture3D stays NN").
- Fizzygum: `docs/architecture/transforms.md` §8 sampling contract (rotation+scale unified:
  "smooths whenever the effective sample step ≠ 1; `imageSmoothingEnabled` implemented,
  default true, never set false by Fizzygum" — or the per-site policy D2b chose) and §9's
  scale bullet REWRITTEN (no longer "accepted NN"); `docs/BACKLOG.md` affine §7.8 line closed
  fully; `appearance-paint-convention.md` only if the stroke/overlay wording references
  scale (it does not today — verify with a grep for "scale" before touching).
- Close-arc: `git mv` this plan to `docs/archive/` + status stamp + `archive/INDEX.md` entry
  + memory note (`/close-arc` skill); update memory `swcanvas-bilinear-rotated-composite-arc`'s
  "Open: D2" line.

## §5 Spikes (run in order; each has a kill criterion)

- **S0 — native A/B (30 min, no code).** On the current build's `index.html` vs
  `index-sw.html`, build a scaled-island scene via the console (copy
  `macroTransformFrameScaledRenders`'s fixture; the lazy part dance:
  `world.parts.ensureLoaded('authoring')` first if the scene needs authoring classes).
  Confirm native smooths / SW is chunky, pinning the target look. If native is ALSO chunky
  on scaled islands → the divergence model is wrong — STOP, re-derive.
- **S1 — blast-radius measurement (the load-bearing spike, ~2 h).** Implement §4.1 with the
  simplest gate (smooth whenever step ≠ 1 or non-axis-aligned; no phase exclusion),
  `npm run build && npm test` in SWCanvas (⚠ some of the 153 visual tests DO scale images —
  expect a handful to change; unlike the rotation arc, a non-empty visual diff here is not
  automatically a scoping leak: eyeball each, they must all be scaled-content scenes), then
  vendor `--no-pin-update`, `fg build`, `fg suite` + `fg suite --dpr=2`. **The fail lists ARE
  the D2 re-baseline set.** Kill criteria: (a) any test with NO scaled content in the fail
  list → the step-1 exactness rule leaked — STOP and fix before anything else; (b) text-bearing
  UNSCALED scenes failing at dpr2 → the cpr-compensation traffic is not step-1 as assumed —
  STOP, re-derive the gate (likely the phase exclusion of §4.1.1). Deliverable: the measured
  fail list count + classification, quoted in the look-gate.
- **S2 — StretchableCanvasWdgt compounding probe (1 h).** Scripted resize sequence on a
  stretchable canvas (drag its resizer 3-4 times via a quick puppeteer probe in
  `Fizzygum-tests/.scratch/` — Node probes live THERE, `require()` resolves from the script's
  dir), screenshot after each. Measures whether smoothing visibly compounds. Feeds D2b.

## §6 Central risks

1. **The step-1 set is the whole game.** Everything byte-pinned (glyph traffic, back-buffer
   blits, shadow scratch) must flow bit-exact. Defense: §4.1(3) + S1's kill criterion (a)/(b)
   + SWCanvas 058's byte-equality case.
2. **Unknown re-baseline size.** Measured by S1 before any commitment; if it comes back
   absurd (hundreds of tests via some unforeseen step≠1 traffic), STOP at the look-gate and
   present the number — the owner may prefer per-site opt-in (`imageSmoothingEnabled=false`
   default at the Fizzygum layer + explicit true around `_compositeScaleOnly`) over a mass
   re-baseline. That inversion is a legitimate landing shape; keep it on the table.
3. **Compounding blur in StretchableCanvasWdgt** (S2/D2b).
4. **Downscale quality.** Bilinear is correct-but-aliasing-prone below ~0.5×; Fizzygum's
   island scales are user-driven and can go small. Accept for D2 (native's own bilinear tier
   aliases too); note box-filter/mipmaps as future work in the archive stamp, do NOT build
   them now.
5. **Determinism.** Same rules as the rotation arc: plain doubles, fixed order, no new
   transcendentals; the gauntlet's webkit leg is the cross-engine proof.
6. **Pin ordering.** SWCanvas commit pushed on `main` BEFORE Fizzygum's rewritten pin
   commits. The SWCanvas checkout may carry unrelated dirt (`DIRECT-RENDERING-SUMMARY.MD`
   modified, `plans/direct-dispatch-gaps-and-coverage.md` untracked at authoring time) —
   branch off `619dc1c`, leave the dirt out.
7. **Perf.** Scaled blits are hotter than rotated ones (every scaled-island composite, every
   stretchable-canvas resize). Extend `debug/bench-rotated-drawimage.js` with an axis-aligned
   scaled case, measure old-vs-new in ISOLATED processes (same-process A/B is polluted by JIT
   state — measured in the predecessor arc: +30% phantom), report the delta at the gate.
   `benchmark-session.js` has NO drawImage case — it is blind to this change by construction.

## §7 Cold-execution protocol

1. Read this doc fully; then the predecessor archive
   `docs/archive/swcanvas-bilinear-rotated-composite-plan.md` (status stamp + §9),
   `docs/architecture/transforms.md` §8-§9, SWCanvas `CLAUDE.md`, and the landed sampling code
   (`src/core/Rasterizer.js` — grep `useBilinear`).
2. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (expect clean repos at
   `2e8e3e10`/`20877b2b9` or later, build FRESH). Verify SWCanvas checkout vs
   `Fizzygum/vendor/swcanvas.pin` (`git -C "/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas"
   log --oneline -1` — expect `619dc1c` or a descendant matching the pin); if diverged, STOP
   and reconcile. Branch SWCanvas off the pin for the work.
3. Re-verify §1's quotes (grep `useBilinear`, `_compositeScaleOnly`, the StretchableCanvasWdgt
   `ctx.scale` re-blit, `imageSmoothingEnabled` absence, and that Fizzygum never sets
   `imageSmoothingEnabled`).
4. Spikes S0 → S1 → S2, honoring kill criteria. S1's fail list is the arc's central artifact.
5. **Owner look-gate D2a + policy gate D2b — HARD STOP until explicit YES in-session.**
   Render via `fg diffpage` over S1's fail list (at minimum: a scaled island with text, the
   stroked-rect scale scene, a StretchableCanvas resize sequence). Present: the fail-list
   count + classification, the perf delta, the compounding-blur probe, and the
   default-true-vs-per-site-opt-in shape. If declined: revert the vendor, keep the plan,
   record the decision.
6. SWCanvas: finalize §4.1 + 058 tests + docs; `npm run build && npm test` green; commit on
   the branch, merge to `main` (ff), PUSH.
7. Fizzygum: vendor `--source` (pin rewritten), `fg build`, suite fail lists re-confirmed
   rotated/scaled-only, `fg recapture --auto --dprs=1,2` to COMPLETE, color-pair sweep clean,
   T-scale test authored + captured + stable, `fg presuite`, full `fg gauntlet` + `fg homepage`.
8. Docs + ledger (§4.4), archive + INDEX + memory. Commits: SWCanvas first (pushed), then
   Fizzygum (pin + docs [+ any D2b opt-out src line]), then Fizzygum-tests (re-baseline +
   T-scale) — `git commit -F <file>`, push only on owner OK (standing rule).
9. House rules: `fg` wrapper for build/test; long ops launched ONCE in background, wait for
   the task notification; Edit tool only on `.coffee`; never edit a running op's inputs; Node
   probes in `Fizzygum-tests/.scratch/`; absolute paths everywhere (`/Users/davidedellacasa/
   code/Fizzygum-all/fg`, never `./fg`).

## §8 Verification protocol (the concrete gate list)

- SWCanvas: `npm run build && npm test` all green with 058 added; visual-test diffs (if any)
  each eyeballed as scaled-content; isolated-process perf A/B reported.
- Fizzygum: `fg build` → `fg suite` + `fg suite --dpr=2` fail lists = scaled/rotated scenes
  only → `fg recapture --auto --dprs=1,2` to COMPLETE → sweep clean → T-scale authored +
  captured + stable ×3 → `fg presuite` → `fg gauntlet` 14/14 (webkit leg = cross-engine
  proof) → `fg homepage` OK.
- DONE when: scaled islands render smooth (native-parity) on the SW page, the step-1 traffic
  is proven byte-identical (S1 criterion + 058), `imageSmoothingEnabled` is implemented and
  covered, and the ledger/docs say so.

## §9 Rejected alternatives — do NOT re-attempt

- **Gating smoothing on the src/dst RECT ratio alone.** Falsified by inspection at authoring
  time: `StretchableCanvasWdgt` scales via `ctx.scale` with same-size rects (§0) — the gate
  must be the effective sample step.
- **Floor-anchored (corner-convention) filtering for the new path.** Falsified empirically in
  the predecessor arc for rotation (kept the defect; drifts content −0.5px per resample) —
  the same math applies to scale. Center convention, per-path containment/sampling coherence.
- **Straight-alpha filtering.** Same predecessor case law: transparent texels carry arbitrary
  RGB; premultiplied only.
- **Building box-filter/mipmap minification now.** Out of scope; bilinear parity first, note
  the tier as future work.
- **Smoothing without implementing `imageSmoothingEnabled`.** Rotation could be silent
  (native gives no practical choice there); scale cannot — HTML5 users legitimately disable
  smoothing for pixel art, and Fizzygum may need per-site opt-outs (D2b). The property comes
  WITH this change (the predecessor plan's D3 said exactly this).
- **Inherited from the predecessor (§9 there, evidence attached): body-side spellings,
  snap tricks, whole-pipeline restructures.** Dead ends; read that section before proposing
  anything at the Fizzygum paint-body layer.

## §10 Owner decision points (ask in-session, at the marked gates)

- **D2a (look-gate):** accept the smoothed look on scaled islands / stretched canvases /
  scaled glyph content, given the measured fail-list size and perf delta. HARD gate before
  any recapture.
- **D2b (policy):** default-true smoothing everywhere step≠1, vs per-site opt-outs
  (StretchableCanvasWdgt compounding), vs the inversion (Fizzygum-layer default-false +
  explicit true at `_compositeScaleOnly`) if S1's radius is unacceptable.
- **D2c (SWCanvas API):** `imageSmoothingEnabled` boolean only (recommended), vs also
  `imageSmoothingQuality` (recommend NO — single quality tier, note as future work).

## §11 References

- Predecessor arc: `docs/archive/swcanvas-bilinear-rotated-composite-plan.md` (status stamp =
  the sampling-convention case law), `archive/INDEX.md` entry, memory
  `swcanvas-bilinear-rotated-composite-arc`.
- Island architecture: `docs/architecture/transforms.md` §8-§9.
- SWCanvas: `/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas` — `CLAUDE.md` (dual-API
  parity, build-before-test, benchmark discipline), `src/core/Rasterizer.js`,
  `tests/core/057-drawimage-rotated-bilinear-contract.js` (the shape 058 copies),
  `debug/probe-rotated-thinline-gaps.js`, `debug/bench-rotated-drawimage.js`.
- Vendoring: `Fizzygum/scripts/vendor-swcanvas.sh` header; `vendor/swcanvas.pin`.
- Tooling: `Fizzygum-tests/.scratch/sweep-recapture-diffs.js` (the sweep), `fg diffpage`,
  `fg recapture --auto`, the tests repo `/author-macro-test` skill.
- Memory: `ask-before-commit-push`, `no-conclusions-before-evidence`,
  `dont-let-recapture-churn-dictate-design`, `long-op-eta-and-status-updates`.
