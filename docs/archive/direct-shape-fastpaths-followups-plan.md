> **ARCHIVED — COMPLETE (authored 2026-08-07, executed 2026-08-08; P6 added in execution).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Direct-shape fast paths — follow-ups to the Boxy roundRect conversion

**STATUS: ✅ EXECUTED IN FULL AND CLOSED 2026-08-08 — all phases P1–P6 (P6 added
in execution: the uniform-scale gate). Landed as SWCanvas `277e8e3`+`af9af84`+`7414c35`,
Fizzygum `4d1876bc`+`2682fb5e` (pin), Fizzygum-tests `d402421bb` (133-test re-baseline,
dpr 1+2). Verification: recapture COMPLETE at both densities; closing gauntlet 14/14
legs incl. WebKit on the new references. Deviations from the authored text: the
stadium primitive is a dedicated `StadiumOps` (the RoundedRectOpsAA-at-degenerate-radius
delegation was measured and REJECTED — edge-sampled corner extents lose a horizontal
stadium's apex columns); the P3 conversion additionally swept mechanically-safe icon
path-rects/circles to direct calls (owner-directed); the rotate-handle hairline ring
was converted, found to vanish in scaled islands (sub-pixel width below every direct
threshold), and REVERTED with a written reason — the four-swirlies glyph redesign is
the real fix (BACKLOG). Case law: memory note `direct-shape-fastpaths-arc.md`.**

Authored 2026-08-07, immediately after the Boxy→roundRect arc closed. Every `file:line` was verified on authoring day but LINES DRIFT — the quoted
method names and code are authoritative; re-grep before trusting a number.

**Mandate:** finish what the Boxy arc started — eliminate the remaining path-drawn,
compactly-parametrisable chrome shapes (circles, the stadium, the title-bar annulus) by
routing them through SWCanvas's direct fast paths, and close the tier-0 clip gap for the
WHOLE direct-call family rather than the two ops patched so far. No burying: a shape
either gets a real primitive with the full verification battery, or it stays on the
generic path with a written reason (as BubblyAppearance did).

---

## §0 Orientation

Three sibling repos plus one external:

- `~/code/Fizzygum-all/Fizzygum` — framework source. Read its `CLAUDE.md` first.
- `~/code/Fizzygum-all/Fizzygum-tests` — SystemTest suite + harness. `CLAUDE.md` + `DETERMINISM.md`.
- `~/code/Fizzygum-all/Fizzygum-builds` — generated; never edit.
- `~/code/Unified SW Canvas/SWCanvas` — the SWCanvas repo (path has SPACES — quote it).
  Fizzygum vendors its built `dist/` via `Fizzygum/scripts/vendor-swcanvas.sh` pinned by
  `Fizzygum/vendor/swcanvas.pin`. Its `CLAUDE.md` lists the non-negotiables:
  `npm run build` BEFORE every test run (inline-marker preprocessor), dual-API parity
  (`src/core/Context2D.js` + `src/compat/CanvasCompatibleContext2D.js`), Prettier +
  ESLint (new bare-const globals must be registered in TWO spots in `.eslintrc.js`),
  `npm run update-test-counts` after adding tests.

**The immediately-prior arc (CLOSED + PUSHED 2026-08-07)** converted `BoxyAppearance`
(menus, buttons, window bodies/title bars — the hottest chrome) from a four-`arc()` path
to SWCanvas's non-standard direct calls. Landed state this plan builds on:

- SWCanvas `main` @ `6b20dcc`: 1px-stroke corners share the edges' snapped pixel frame +
  `QUADRANT_TRIG_EPSILON` (commit `131aaac`, core tests 046–048); tier-0 rect-clip wiring
  for `fillRoundRect`/`strokeRoundRect` + two clip-drop bug fixes (commit `6b20dcc`,
  core test 049). Byte-identity methodology: `debug/sweep-stroke1px-roundrect-hashes.js`.
- Fizzygum `master` @ `80a76187`: `fillRoundRect`/`strokeRoundRect` polyfills on the
  NATIVE `CanvasRenderingContext2D` (over standard `roundRect()`) in
  `src/boot/extensions/CanvasRenderingContext2D-extensions.coffee`;
  `BoxyAppearance.fillOutline`/`strokeOutline` seam (BubblyAppearance overrides both and
  stays on the generic path). **The ONE crisp spelling, valid on both backends at every
  ceilPixelRatio:** fill `0, 0, w, h, r` · 1-logical-px stroke `0.5, 0.5, w-1, h-1, r`.
- Fizzygum-tests `master` @ `0b8f823e3`: 134 tests re-baselined at dpr 1+2, and
  `AutomatorPlayer.FULL_FAILURE_IMAGE_BUDGET = 24` — the harness used to retain
  gigabytes of failure artifacts on a mass-fail dpr2 run and OOM the shard pages
  ("Page crashed"); mass-churn comparison runs now survive. Closing gauntlet was green
  on all 14 legs including WebKit on the new references.
- Session case law: memory note `roundrect-fastpath-conversion-audit.md`
  (`~/.claude/projects/-Users-davidedellacasa-code-Fizzygum-all/memory/`).

**⚡ CRITICAL REFRAME (the audit's premise was WRONG — do not re-import it).** The
original follow-up idea was "relax CircleOps from identity-transform to axis-aligned
uniform scale". That premise came from a STALE table in SWCanvas's
`DIRECT-RENDERING-SUMMARY.MD` (§3, the row `Circle | Transform: noTransform =
this._transform.isIdentity`). The CODE disagrees: `Context2D.fillCircle` (~:2369) and
`strokeCircle` (~:2392) transform the center via `transformPoint` and scale the radius
by `this._transform.uniformScale` UNCONDITIONALLY, then `_fillCircleDirect` (~:2742) /
`_strokeCircleDirect` (~:2777) go direct for any solid colour + source-over. Circles
already fast-path under Fizzygum's translate+uniform-scale contexts today. What is
ACTUALLY missing upstream for circles is the same pair the roundRect arc fixed:

1. **No tier-0**: `_fillCircleDirect`/`_strokeCircleDirect` call `_ensureClipBuffer()`
   unconditionally — under Fizzygum's save→`clipToRectangle`(damage)→paint→restore
   pattern (a FRESH clip state per widget paint) every circle paint would materialise a
   full-surface bitmask. `grep -c clipRect src/renderers/CircleOps.js` → **0** (same for
   `ArcOps.js`, `LineOps.js`).
2. **No verified crisp contract**: nobody has probed what CircleOps does at half-integer
   centers / the crisp idioms, nor whether its quadrant pixels carry the same
   trig-noise flooring the 1px roundRect corners had (fixed via `QUADRANT_TRIG_EPSILON`
   — grep it in `src/renderers/RoundedRectOpsAA.js` for the pattern).
3. One real hazard: under a NON-uniform transform, `uniformScale` (a geometric mean)
   silently draws a wrong-radius circle where an ellipse belongs — roundRect falls back
   to the generic path instead. Fizzygum's converted call sites must be proven
   uniform-scale (they are — see §1.2) and the doc table must be trued up.

---

## §1 Current state (verified 2026-08-07 — re-grep everything before edits)

### 1.1 SWCanvas direct-call family and tier-0 coverage

| Op family | Direct entry points | tier-0 clipRect? |
|---|---|---|
| Rect | `fillRect`/`strokeRect`/`fillStrokeRect` | ✅ (pre-existing) |
| RoundedRect | `fillRoundRect`/`strokeRoundRect` | ✅ (`6b20dcc`); `fillStrokeRoundRect` deliberately NOT (comment at its `_ensureClipBuffer()` call) |
| Circle | `fillCircle`/`strokeCircle`/`fillStrokeCircle` | ❌ |
| Arc | `fillArc`/`outerStrokeArc`/`fillOuterStrokeArc` | ❌ |
| Line | `strokeLine` | ❌ |

The tier-0 convention to mirror (all in `6b20dcc`): entry point computes
`const tier0ClipRect = this._tier0ClipRect(); const clip = tier0ClipRect ? null :
this._ensureClipBuffer();` and passes both down; the renderer takes
`(…, clipBuffer = null, clipRect = null)`, derives `cx0/cy0/cx1/cy1` (defaults = surface
bounds, so unclipped output is byte-identical by construction), clamps every row/span/
pixel. ⚠ `SpanOps` does NOT clamp — callers must keep spans inside the surface. The
byte-identical contract lives at `Context2D._tier0ClipRect`'s doc comment.

### 1.2 Fizzygum's remaining path-drawn compact shapes (the conversion targets)

- **Stadium (sliders — HOT)**: `src/basic-widgets/CircleBoxyAppearance.coffee`
  `paintIntoAreaOrBlitFromBackBuffer` (~:60–90): ONE path = two full `arc()` circles +
  a `moveTo/lineTo` rectangle, single fill. Centers come `.round()`ed from
  `calculateKeyPoints` (~:12–27), the rect `.floor()`ed. Handles BOTH orientations
  (vertical/horizontal sliders). Consumers: `CircleBoxWdgt` → `SliderWdgt`,
  `SliderButtonWdgt`. Painted inside `_beginLogicalPixelsBox` (uniform
  `ceilPixelRatio` scale + integer translate).
- **Annulus (every window title bar — HOT)**: `src/icons/IconAppearance.coffee`
  `_paintButtonRing` (~:287): two bezier-approximated circles as opposite-winding
  subpaths, one fill. Geometry in the icon's ~200×200 specification space: center
  (100.5, 99.5), outer r≈97 (3.5→197.5), inner r≈84.4 (15.1→184.9) → ring thickness
  ≈12.6, mid-radius ≈90.75. Consumers: `CloseIconAppearance`, `CollapseIconAppearance`,
  `UncollapseIconAppearance`. It draws under `_paintColoredIcon`'s DOUBLE scale
  (~:100–117: widget/preferred × preferred/specification) — uniform ONLY when the icon
  widget is square. Title-bar buttons are square; a probe must CONFIRM (hazard §0.3).
  The default `IconAppearance.paintFunction` (~:23) is the same ring shape — optional
  same treatment.
- Cold sites deliberately left alone (audit verdicts, do not re-litigate without new
  evidence): icons generally (non-uniform per-shape `oval` scaling + cached), speech
  bubble (single family, generic path), `DragChargingRing` (dwell-only), clock (cached),
  stars/regular polygons (zero call sites in `src/`).

---

## §2 Why it is shaped this way

The path-drawn shapes are Morphic inheritance: 10+ years ago canvas had no rounded-rect
command and no direct-shape API at all, so everything was `arc()`+`lineTo` paths. The
Boxy arc established the replacement pattern end to end — vocabulary (SWCanvas's direct
names, polyfilled on native), crisp spelling, probe-first pixel forensics, byte-identity
sweeps, recapture gates. This plan is that pattern applied to the shapes the audit ranked
next, plus the debt the arc knowingly left (`fillStroke_AA_Any` tier-0, docs-sync).

## §3 The distilled argument

Sliders and title-bar buttons are painted constantly; both draw circles through the
generic polygon pipeline (bezier tessellation → scanline fill) although SWCanvas has
Bresenham circle renderers sitting one call away that ALREADY accept Fizzygum's
transforms. The blockers are small and known-shaped: tier-0 (a mechanical mirror of
`6b20dcc`), crisp-contract probes (the roundRect arc's playbook, tools already in
`debug/`), and for the stadium one new primitive whose absence cannot be composed around
(§6b). Doing this now, while the arc's case law and tooling are fresh, is materially
cheaper than rediscovering it later.

---

## §4 Phases

Run in order; each phase lands (owner-gated) before the next starts. P4 and P5 are
independent of P2/P3 and may be reordered if convenient.

### P1 — upstream: circle-path hardening (tier-0 + crisp probes + doc truth-up)

1. **Probe first, change nothing** (the arc's doctrine): in the SWCanvas repo, write
   `debug/probe-circle-crisp.js` after the pattern of
   `debug/probe-halfinteger-roundrect-full.js` — ASCII-dump `fillCircle`/`strokeCircle`
   (1px and thick) at integer vs half-integer (`*.5`) centers, integer vs `.5` radii,
   identity vs scale(2) vs translate+scale, vs the generic-path (`arc()`+fill/stroke)
   rendering of the same geometry. Questions: is the output single-width and symmetric?
   do quadrant pixels show the trig-noise flooring (`floor(c + r·cos θ)` at θ = 90°
   multiples with the true term exactly 0 — the `QUADRANT_TRIG_EPSILON` class)? what is
   the crisp idiom (which spelling puts a ring exactly inside a box)? CircleOps uses
   Bresenham (not per-degree trig) per its header — the noise class may not apply; the
   probe DECIDES, not this paragraph.
2. **Tier-0 for CircleOps**: mirror `6b20dcc` exactly — entry points
   `_fillCircleDirect`/`_strokeCircleDirect` (and `fillStrokeCircle`'s path) gain the
   `_tier0ClipRect()` split; every `CircleOps.*` writer gains `clipRect = null` +
   `cx0/cy0/cx1/cy1` clamps with surface-bounds defaults. `ArcOps`/`LineOps`: same
   treatment IF the diff stays mechanical; otherwise leave with the
   `fillStrokeRoundRect`-style "deliberately NOT wired" comment. Any half-integer/
   junction defect the probes surfaced gets fixed HERE with the frame-snap approach
   (falsified alternative §6e), plus non-vacuity proof against the pinned dist.
3. **Verification (all required)**: a `debug/sweep-*` hash sweep over a circle parameter
   grid — no-clip cases MUST be byte-identical pre/post; a clipped tier0≡bitmask probe
   (two-identical-rects clip defeats the rect detector — see test 049's technique); new
   core tests `050+` in `tests/core/` (numbering: 001–045 2D, 300s text, 400s 3D; 046–049
   are the roundRect contract tests — follow their style: `test('name', fn)`, Core API,
   exact-pixel assertions, closed-ring ≥2-neighbors check, mirror symmetry, `savePNG`);
   `npm run build && npm test && npm run test:direct-rendering`; `npx eslint`/
   `prettier --check` on touched files; `npm run update-test-counts`.
4. **True up `DIRECT-RENDERING-SUMMARY.MD`**: the §3 conditions table's Circle row
   (stale `isIdentity` claim) and the tier-0 coverage story (§6.5.2 documents the
   roundRect pattern — extend, don't duplicate).
5. **Owner gate**: present commit; after approval push, then bump the Fizzygum pin
   (`./scripts/vendor-swcanvas.sh --source "<SWCanvas path>"` — pushes SWCanvas FIRST or
   the from-pin fetch 404s), `fg build`, `fg presuite` (expect zero churn — nothing in
   Fizzygum calls circles directly yet), owner-gated pin-bump commit.

### P2 — upstream: stadium/capsule primitive

1. API: `fillStadium(x, y, w, h)` (+ `strokeStadium`, `fillStrokeStadium` if the probe
   shows Fizzygum needs them — `CircleBoxyAppearance` today only FILLS; check
   `strokeColor` usage on `CircleBoxWdgt` before building stroke variants nobody calls —
   the dead-method gate: capability lands WITH callers). Cap radius = `min(w,h)/2`,
   orientation implied by the longer axis — covers vertical AND horizontal sliders with
   one signature. Dual-API parity (core + compat), tier-0 from birth, `_Opaq`/`_Alpha`
   variants, the established fallback shape (non-eligible → un-baked `SWPath2D` under
   the CTM — copy `fillRoundRect`'s fallback comment/structure).
2. Renderer: a `StadiumOps` (or a RoundedRectOpsAA delegation — a stadium IS a rounded
   rect with r = min(w,h)/2; MEASURE whether `fill_AA_*` already produces the right
   pixels for that degenerate radius before writing any new rasteriser — if yes the
   "primitive" is a thin Context2D entry point over RoundedRectOpsAA and the whole
   phase shrinks).
3. Same verification battery as P1 (probes, sweep, core test, suites, lint, counts,
   doc section, owner-gated commit/push/pin-bump).

### P3 — Fizzygum: convert the circle chrome (MASS-VISUAL — owner gates throughout)

1. `CircleBoxyAppearance`: replace the two-arcs+rect path with the stadium call,
   preserving `calculateKeyPoints`' rounding so the geometry fed in is unchanged.
   Keep `isTransparentAt` (hit test) untouched. ⚠ The shadow pass fills at
   `globalAlpha < 1` — which is WHY this needs P2's primitive and not a
   circle+rect+circle composition (§6b).
2. `IconAppearance._paintButtonRing`: replace the bezier annulus with
   `strokeCircle 100.5, 99.5, 90.75` at `lineWidth ≈ 12.6` in specification space —
   AFTER a probe confirms (a) the three button icons paint under uniform scale (square
   widgets) and (b) the ring pixels are acceptable vs the bezier original on the diff
   page. If the icons can be non-square anywhere, guard or skip — a non-uniform scale
   makes `fillCircle` silently draw the wrong circle (§0.3). Optionally the default
   `IconAppearance.paintFunction` ring, same conditions.
3. Verify with the Boxy arc's exact flow: `fg build` → `fg suite` (dpr1) + rerun at
   `--dpr=2` → union the failing lists → `fg diffpage --tests-file=… --dprs=1,2` →
   **owner eyeballs** → `fg recapture --auto --dprs=1,2` (COMPLETE verdict required) →
   `fg gauntlet` (all 14 legs; WebKit reuses the new refs) → owner-gated commits
   (Fizzygum src; Fizzygum-tests refs) and pushes. Slider + title-bar pixels appear in
   a large fraction of the 283 tests — expect a three-digit recapture; the harness
   budget (`FULL_FAILURE_IMAGE_BUDGET`) makes the dpr2 mass-fail comparison run safe.

### P4 — upstream: `fillStroke_AA_Any` tier-0 (small, independent)

`RoundedRectOpsAA.fillStroke_AA_Any` (used by `fillStrokeRoundRect`; span-based via
`_getXExtent` + `renderFillSpan`/`renderStrokeSpan`) gains `clipRect` clamps like its
siblings; `Context2D.fillStrokeRoundRect` drops the "deliberately NOT wired" comment for
the real split. Fizzygum never calls it (Boxy fills and strokes DIFFERENT rects), so
this is upstream hygiene: sweep + a 049-style clipped-equivalence case + suites, then
owner-gated commit/push (pin bump can ride the next natural vendor bump).

### P6 — upstream: uniform-scale gate for the circle/arc direct paths (ADDED IN EXECUTION, owner-directed 2026-08-08)

Grown out of P3's polyfill ⚠-comments: rather than documenting that the direct
circle/arc paths draw a wrong-radius CIRCLE under a non-uniform transform, gate
them. All six entries (`fillCircle`/`strokeCircle`/`fillStrokeCircle`,
`fillArc`/`outerStrokeArc`/`fillOuterStrokeArc`) check `isUniformScale` and
route ineligible calls through an un-baked user-space `SWPath2D` under the CTM
(the `fillRoundRect`/`fillStadium` fallback pattern) — correct ellipse, slower,
never wrong; cross-backend shape agreement restored (the native polyfills were
always correct). `strokeLine` deliberately ungated, reason at its entry. Pinned
by core test 054 (ellipse bbox, six-way byte-equivalence with external-path
renders, rotation+uniform stays direct); 300-case uniform sweep byte-identical
(zero churn for eligible callers).

### P5 — docs-sync of the landed Boxy conversion (Fizzygum)

Weave — never bolt on (see the `docs-sync` skill if available; else follow
`docs/README.md` filing rules):

- `docs/architecture/integer-pixel-placement-and-sizing.md`: a section on the ONE crisp
  rounded-rect spelling (fill `0,0,w,h,r` / stroke `0.5,0.5,w-1,h-1,r`), why it is
  backend/dpr-invariant (the SWCanvas frame-snap), and that direct-call names
  (`fillRoundRect` etc.) are the shared vocabulary — native polyfills in
  `CanvasRenderingContext2D-extensions.coffee`.
- `Fizzygum-tests`: note `FULL_FAILURE_IMAGE_BUDGET` in `CLAUDE.md`'s gotchas (the
  mass-fail-dpr2 OOM class) if not already there.
- `docs/BACKLOG.md`: tick this plan's line as phases land; on full completion `git mv`
  this plan to `docs/archive/` + stamp + INDEX line (the standing loop).

---

## §0.5 Cold-execution protocol

1. `~/code/Fizzygum-all/fg status` — orient; verify all three repos clean and the shas
   in §0 are ancestors of the current heads. If heads moved, re-verify §1's claims
   before trusting anything here.
2. Read: `Fizzygum/CLAUDE.md` → `Fizzygum-tests/CLAUDE.md` (at least the headless-runner
   + determinism sections) → SWCanvas `CLAUDE.md` → the memory note
   `roundrect-fastpath-conversion-audit.md` → this plan fully.
3. Execute phases in order. Probe BEFORE changing rasterisers, always; never conclude
   pixels from reading code (this arc falsified two crash theories that way — evidence
   first).
4. **Owner gates (never autonomous)**: every commit and push; the P3 diff-page eyeball;
   the P3 mass recapture. Long ops (`fg suite`/`gauntlet`/recapture) run via Bash
   `run_in_background`, never foreground pollers; `fg killz` before dpr2 suite runs.
5. ⛔ Never `git stash` in ANY of these repos (Fizzygum + tests: documented data-loss
   case law; SWCanvas: tracked `dist/` regenerates on build and blocks the pop —
   recovery: `git checkout -- dist/` then pop).
6. Node scratch probes for the tests repo go in `Fizzygum-tests/.scratch/` (require()
   resolution); SWCanvas probes in its `debug/` (tracked, per its README convention).

## §5 Verification quick-reference

- SWCanvas: `npm run build` (ALWAYS before tests) · `npm test` (223+) ·
  `npm run test:direct-rendering` · `npm run build:prod` (before perf) · lint/format ·
  `npm run update-test-counts` · byte-identity sweep pre/post (capture the BEFORE from
  `git show HEAD:dist/swcanvas.js` into /tmp — do not stash).
- Fizzygum: `fg build` · `fg presuite` (inner loop) · `fg suite --dpr=2` ·
  `fg diffpage --tests-file=F --dprs=1,2` · `fg recapture --auto --dprs=1,2` ·
  `fg gauntlet` (phase close) — invoke as `/Users/davidedellacasa/code/Fizzygum-all/fg`.
- A leg that fails only in a parallel wave and passes the serial retry is the
  boot-storm infra flake, not a code bug.

## §6 Rejected alternatives — do NOT re-attempt

- **(a) "Relax CircleOps' transform condition"** — the follow-up as originally worded.
  FALSE PREMISE: the identity requirement exists only in a stale doc table; the code
  already transforms and goes direct (§0 reframe). The doc gets fixed, not the code.
- **(b) Stadium as `fillCircle + fillRect + fillCircle` composition** — double-blends
  the overlap regions whenever `effectiveAlpha < 1`, and Fizzygum's SHADOW pass always
  paints at reduced alpha, so shadows would darken at the seams vs today's single-path
  fill. An opaque-only composition + alpha fallback was considered and rejected as a
  two-mode maintenance trap. Hence P2's primitive.
- **(c) Per-backend / per-dpr crisp stroke spellings in widget code** — superseded by
  the upstream frame-snap (`131aaac`); one spelling everywhere is the contract now.
- **(d) Corner-formula epsilon tweaks without the frame rebase** — changes
  integer-input pixels and churns everything; the landed pattern is: snap the frame
  once, derive edges AND corners from it, snap quadrant trig to exact zero.
- **(e) Trusting `failed: 0` / crash-free-looking partial runs** — a dpr2 shard that
  dies mid-run still prints a failing-list; check `shards complete: N/8` and CRASHED
  counts before believing any suite number.

## §7 References

- Memory: `roundrect-fastpath-conversion-audit.md` (the full arc case law, blast-radius
  numbers, falsification history).
- SWCanvas: commits `131aaac`, `6b20dcc`; `DIRECT-RENDERING-SUMMARY.MD` §6.5.2;
  `tests/core/046–049`; `debug/probe-halfinteger-*` + `debug/sweep-stroke1px-*`.
- Fizzygum: commit `80a76187`; `src/basic-widgets/BoxyAppearance.coffee` (the seam
  pattern); `src/boot/extensions/CanvasRenderingContext2D-extensions.coffee` (polyfill
  home + the crisp-spelling comment).
- Fizzygum-tests: commits `7c5d21c73` (harness budget), `0b8f823e3` (re-baseline);
  `DETERMINISM.md`.
