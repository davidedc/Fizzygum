# Stroke flip to logical thickness (§4.4(B)) + fractional-plane dpr2 coverage

> **STATUS 2026-08-12: ✅ CLOSED — P1+P2+P3 all LANDED, same day as authored.** P1 landed as
> written (raw Boxy spelling; 139-test dpr2-only recapture, COMPLETE in one loop; dpr1
> byte-invariance verified). P3 landed and immediately EXPOSED that §1's "±ulp caveat" was
> hiding a real pre-existing class: EVERY thin stroke inside a compensating wrapper (old
> device-hairline border included, teal selection overlay included) rasterizes DASHED on
> thresholded SWCanvas — the fractional figure origin + rotation live in the CTM, unreadable
> by a law-compliant body, and a widget's own plane position is integer by the placement law,
> so the §3-P1 "snap" alternative is provably the identity (implemented, captured
> byte-identical, reverted). Ledgered in `docs/BACKLOG.md` (owner-gated, rasterization-class).
> P2 landed with a dpr2-only plant proof (dpr1:PASS + fracplane:FAIL). The P1 recapture also
> surfaced a SECOND pre-existing defect (BACKLOG'd): a hand-carried window's pixels are not
> refreshed when a pending glyph atlas arrives mid-drag — it corrupted one capture
> (`macroDragEmbedWindowTransitNeverArms` image_0, both densities, deterministic solo);
> repaired via a pre-carry `waitForScreenshotReady` in that macro + clean recapture. The
> planned diffpage spot-check was superseded by a FULL color-pair sweep of all 454 changed
> refs (one corruption found, zero others). Law updates:
> `architecture/appearance-paint-convention.md` stroke + overlay bullets.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-12 at Fizzygum `87e5c1c9` / tests `c65764bf4` (both pushed; gauntlet 14/14 +
`fg homepage` OK on that tree). Every `file:line`/quote below was verified on that tree; lines
drift — the method name / quoted code is authoritative, re-grep before trusting a number.

**MANDATE.** Close the three residuals of the appearance local-coords arc
(`docs/archive/appearance-local-coords-plan.md`) by elimination, not mitigation: (P1) the
rectangular border's dpr-inconsistent thickness is REMOVED by flipping it to 1 LOGICAL pixel
(the §4.4(B) decision, closing the file's TODO), (P2) the dpr1 blindness to fractional-plane
pixel regressions is REMOVED from the inner loop by a presuite rider leg, and (P3) the
zero-coverage of strokes on fractional-plane widgets is REMOVED by a new SystemTest.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework on a single canvas (native + deterministic SWCanvas;
the 290-test SystemTest suite screenshots SWCanvas byte-exactly at dpr 1 and 2). The
appearance local-coords arc (CLOSED + PUSHED 2026-08-12, Fizzygum `87e5c1c9`) converted every
appearance paint body to widget-local logical coordinates through the ctx matrix, inside the
ONE preamble `Appearance._paintInLocalScope`. Its law: `docs/architecture/appearance-paint-convention.md`.
Read that doc first — this plan modifies its stroke paragraph (P1) and leans on its
fractional-plane findings (P2/P3).

Three facts from that arc drive this plan:

1. **The rectangular border is ONE DEVICE pixel by design** (`RectangularAppearance.paintStroke`)
   — visually a hairline at dpr 2, HALF the logical thickness of BoxyAppearance's 1-logical-px
   stroke. The §4.4 decision landed as (A) byte-identical; option (B) — flip to the Boxy
   logical spelling — was deferred as an open TODO at the site. The OWNER has now commissioned (B).
2. **Plane geometry is legitimately FRACTIONAL in one place**: a payload dropped into a rotated
   container lands at the inverse-mapped screen point inside its reparent-transparency figure
   (`TrackingTransformFrameWdgt`) — integer size, fractional position, and the
   `NON_INTEGER_GEOMETRY` gate does not flag it (deliberate; two-vocabulary law). All pixel
   divergence this class can cause rounds identically at cpr 1 ⇒ **the dpr1 suite (= `fg
   presuite`) is BLIND to it; only the gauntlet's dpr2 leg sees it.** The arc's one real
   regression (an added clip shaving an edge column) shipped through THREE green presuites and
   was caught only by the close gauntlet.
3. **No reference exercises a strokeColor'd widget at a fractional plane position.** The
   current snapped stroke spelling reproduces legacy `Math.round` with a documented ±ulp FP
   caveat that nothing pins.

## §1 Current state (verified at `87e5c1c9`)

### 1.1 The stroke (`src/basic-widgets/RectangularAppearance.coffee`, `paintStroke`)

Runs inside `_paintInLocalScope` with `{ clip: false }`; gates on `@widget.strokeColor?`;
clips to damage∩tight; then:

```coffee
ctx.lineWidth = 1 / ceilPixelRatio # TODO might look better as 1 logical px (the Boxy spelling) — a dpr-2 recapture
widgetPosition = @widget.position()
sx = (Math.round(widgetPosition.x * ceilPixelRatio) + 0.5) / ceilPixelRatio - widgetPosition.x
sy = (Math.round(widgetPosition.y * ceilPixelRatio) + 0.5) / ceilPixelRatio - widgetPosition.y
sw = (Math.round(@widget.width() * ceilPixelRatio) - 1) / ceilPixelRatio
sh = (Math.round(@widget.height() * ceilPixelRatio) - 1) / ceilPixelRatio
ctx.strokeRect sx, sy, sw, sh
```

The Boxy twin this flips TO (`src/basic-widgets/BoxyAppearance.coffee`, `strokeOutline`):
`context.strokeRoundRect 0.5, 0.5, @widget.width() - 1, @widget.height() - 1, @getCornerRadius()`
at `lineWidth = 1` (logical). Boxy's own `lineWidth = 1 # TODO might look better if * ceilPixelRatio`
comment is a stale device-era thought — retire it in P1 (comment-only).

**Who has a strokeColor** (⇒ the dpr2 recapture blast radius): `FrameWdgt` (every window
border, 125,125,125), `PanelWdgt` (defaultPanelsStrokeColor — most panels), `SimpleButtonWdgt`
/ `SimpleRectangularButtonWdgt` / `CodeInjectingSimpleRectangularButtonWdgt`, `ToolTipWdgt`,
`GlassBoxBottomWdgt`, `FrameBarWdgt` titlebar backgrounds, `SpeechBubbleWdgt` (Boxy — already
logical, unchanged), `MenuRowsPanelWdgt`, `HighlighterWdgt` (sets `@strokeColor` per style —
its outline flips thickness too, accepted as part of (B)). Expect a LARGE dpr2-only recapture
(most dpr2 refs show a window or panel). **dpr1 refs are unchanged by construction**
(1 logical = 1 device at cpr 1; for integer positions the current spelling already equals the
Boxy form there).

**ALSO flipped (owner-decided 2026-08-12, after a probe-rendered A/B)**:
`Widget._drawSelectionOverlay` (the teal editor-selection outline,
`src/basic-widgets/Widget.coffee` — its own device-space draw, NOT an appearance body). It
flips to 1 LOGICAL px in the SAME device-space spelling, probe-validated verbatim:
`lineWidth = ceilPixelRatio` and
`strokeRect (Math.round(@left()*ceilPixelRatio) + 0.5*ceilPixelRatio), (…top…), (Math.round(@width()*ceilPixelRatio) - ceilPixelRatio), (…height…)`.
It stays device-space (it is screen chrome, not a body — the law is untouched); only the
thickness goes logical. Its pixels ride the same dpr2 recapture wave (any ref showing an
editor-selected widget).

### 1.2 The fg presuite (umbrella-local `fg` script, NOT in any repo)

`run_leg` (fg `:111`) is a case table; `presuite` (fg `:452-ish`) runs
`legs_pending presuite dpr1 paint` + `run_wave dpr1 paint` and tallies. A leg is: an entry in
`run_leg`, a name in `legs_pending`, a name in `run_wave`, and (for the peek line) a pattern
in `leg_headline`'s grep alternation. The wave bottleneck is `paint` (~90s), so a ~40s rider
leg is free. The named-subset runner exists:
`Fizzygum-tests/scripts/run-sequence-headless.js [--dpr=N] SystemTest_A …` — one browser, in
order, exit 0 iff all pass.

### 1.3 The template test for P3

`tests/SystemTest_macroDropIntoRotatedStretchablePanelStretchesOnResize/` — its macro builds a
`StretchableWidgetContainerWdgt`, drops `w1` (plain rect) BEFORE rotation, rotates 30°, drops
`w2 = new RectangleWdgt (new Point 90, 55), Color.create 70, 130, 210` AFTER rotation via a
genuine hand carry (`pickUp` → `syntheticEventsMouseMove_InputEvents` →
`syntheticEventsMouseClick_InputEvents`), asserts `w2.parent` is `TrackingTransformFrameWdgt`,
screenshots, resizes the container 300→420, asserts both children stretched, screenshots
again. `w2` lands at a FRACTIONAL position inside the figure — the exact scene P3 needs, plus
a stroke. There is NO `setStrokeColor` setter — the macro idiom is a direct field write
(`w.strokeColor = Color.BLACK`) BEFORE `world.add w` (first paint carries it; tests may reach
internals directly, per the tests repo's CLAUDE.md).

## §2 The distilled argument

- P1 is a pure design-debt payoff the owner has commissioned: one spelling for every
  rectangular-family border at every dpr, the paintStroke TODO closed, the snapped sx/sy/sw/sh
  complexity DELETED (the flip needs no legacy quantization — it is a new look, drawn raw in
  local coords like Boxy always was). The cost is a mass dpr2 recapture, which `fg recapture
  --auto` makes safe (completeness-gated).
- P2 exists because the arc PROVED the inner loop's blindness: three green presuites carried a
  real dpr2 regression. One ~40s rider leg closes the gap for the ONE known fractional scene
  class at inner-loop cadence, without waiting for the 5-min gauntlet.
- P3 pins the last uncovered corner (stroke × fractional position) with a real reference, so
  the ±ulp caveat in the law doc becomes an empirically pinned behavior instead of a hope.
- Ordering is forced: **P1 BEFORE P3's capture** (else P3's references are captured against
  the hairline look and immediately recaptured by the flip), and P3 BEFORE finalizing P2's
  test list (the new test joins the rider).

## §3 Fix shape

### P1 — the §4.4(B) flip (Fizzygum repo + tests recapture)

0. **Owner look-gate: ✅ PRE-CLEARED 2026-08-12, BOTH pieces** — the owner reviewed
   probe-rendered A/B composites for (a) the rectangular border ("the change is OK and also
   logically it makes more sense to keep the logical pixels as we do EVERYWHERE else") and
   (b) the teal editor-selection overlay (explicit "yes" to flipping it too). Do not re-ask;
   proceed straight to step 1. (A/B assets: `Fizzygum-tests/.scratch/rectprobe-A/` vs
   `rectprobe-Bstroke/` for the border; `selovl-A/` vs `selovl-B/` for the overlay —
   `selovl-B` was rendered from a scratch patch since REVERTED.)
1. In `paintStroke`: replace the whole snapped block (§1.1 quote) with the Boxy spelling —
   `ctx.lineWidth = 1` then `ctx.strokeRect 0.5, 0.5, @widget.width() - 1, @widget.height() - 1`.
   Delete the TODO; rewrite the method's comment block: the border is ONE LOGICAL pixel at
   every dpr (2 device px at dpr 2), matching BoxyAppearance; keep notes (1)/(2) about the
   half-pixel inset and inside-drawing; drop the arbitrary-width TODOs only if implementing
   them; else keep as TODO 3/4 verbatim. Retire Boxy's stale `* ceilPixelRatio` TODO comment.
   AND flip `Widget._drawSelectionOverlay` to the probe-validated spelling quoted in §1.1
   (lineWidth `ceilPixelRatio`, insets `0.5*ceilPixelRatio`, sizes `- ceilPixelRatio`),
   updating its comment (1 LOGICAL px, owner-decided with the border flip; still deliberately
   device-space — screen chrome, not an appearance body).
2. Sync `docs/architecture/appearance-paint-convention.md`'s "Related spellings" stroke
   paragraph (it currently documents the ONE-DEVICE-pixel design and its snapped spelling).
3. `fg build` + `fg presuite` (expect dpr1 green — the flip is invisible at cpr 1; if ANY dpr1
   ref fails, STOP and root-cause: that falsifies the invisibility argument).
4. `fg recapture --auto` (GATED: discovers the dpr2-stale set, recaptures, re-runs the full
   suite at both densities, prints COMPLETE/INCOMPLETE — loop until COMPLETE). Expect a large
   dpr2-only set. Spot-check 3–4 recaptured refs visually (`fg diffpage <names> --dprs=2`)
   for the expected border-thickness-only change before moving on.
5. Full `fg gauntlet` (webkit leg re-verifies the recaptured refs cross-engine) + `fg homepage`.

### P2 — the `fracplane` presuite rider (umbrella `fg` only — no repo commit)

1. Add to `run_leg`'s case table (model: the `apps` leg):
   `fracplane) ( cd "$FT" && to 300 node scripts/run-sequence-headless.js --dpr=2 SystemTest_macroDropIntoRotatedStretchablePanelStretchesOnResize SystemTest_<P3-name> ) >"$lg" 2>&1; rc=$? ;;`
   with a comment: fractional-plane scenes are dpr1-invisible (appearance local-coords arc) —
   this is the inner loop's only dpr2 eye; the gauntlet's full dpr2 leg subsumes it, so it is
   presuite-only.
2. Wire: `legs_pending presuite dpr1 paint fracplane`, `run_wave dpr1 paint fracplane`, and
   add `run-sequence:|played ` (whatever run-sequence's summary line is — check its output) to
   `leg_headline`'s alternation so the peek shows pass/fail.
3. Update fg's usage text (`fg presuite` description) + the umbrella `CLAUDE.md`'s presuite
   blurb (local file, not in a git repo).
4. Prove the leg FAILS on a plant: temporarily corrupt one of the two tests' expectations (or
   run with a deliberately stale build), see `fracplane:FAIL`, revert. A gate that has never
   failed is not a gate.

### P3 — the stroked-fractional SystemTest (tests repo)

1. Author per the tests repo's `/author-macro-test` skill. Suggested name:
   `SystemTest_macroDropStrokedRectIntoRotatedPanel`. Macro = the §1.3 template reduced to ONE
   drop: build container, rotate 30°, create `w = new RectangleWdgt (new Point 90, 55),
   Color.create 70, 130, 210` **with `w.strokeColor = Color.BLACK` set before `world.add`**,
   hand-carry drop into the rotated panel, assert `w.parent.constructor.name ==
   "TrackingTransformFrameWdgt"`, `yield "waitForScreenshotReady"`, screenshot (image_1);
   then `container.setExtent new Point 420, 420`, settle, screenshot (image_2 — the stroke
   under the figure's stretch). Keep the four mandatory metadata fields honest (`intent`:
   pin the stroke rendering at a FRACTIONAL plane position — the appearance-local-coords ±ulp
   caveat's only coverage).
2. Capture refs at BOTH dprs (`node scripts/capture-macro-test-references.js <name> --dprs=1,2`),
   then `fg suite` + `fg suite --dpr=2` green, then add the test's name to P2's `fracplane` leg.
3. Full `fg gauntlet` at close.

## §4 Central risks

1. **P1 recapture churn masking a real diff**: mitigated by the recapture gate's
   needs-recapture vs needs-a-fix classification + the diffpage spot-check in P1.4. A
   recaptured ref whose diff is NOT border-thickness-only ⇒ STOP, root-cause.
2. **dpr1 non-invariance of the flip** (P1.3's STOP): for integer positions the spellings are
   provably equal at cpr 1; a dpr1 failure means a fractional-position stroke ref existed
   after all — root-cause before recapturing anything.
3. **P3 flakiness**: the drop scene is macro-driven and already deterministic in the template
   test; keep `yield "waitForScreenshotReady"` before every screenshot (the atlas-settle law).
4. **P2 leg lifetime**: run-sequence boots one browser; under a loaded wave it can hit the
   boot-storm flake — fg's collect_and_retry already serially retries a failed wave leg once,
   which absorbs it (loud "load-flake" warning = infra, not product).

## §5 Cold-execution protocol

1. Read this doc fully, then `docs/architecture/appearance-paint-convention.md`, then the
   archived parent plan's status stamp (`docs/archive/appearance-local-coords-plan.md`).
2. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (expect clean repos at
   `87e5c1c9`/`c65764bf4` or later; this plan file + a BACKLOG line may be the only dirt).
3. Re-verify §1.1's quoted `paintStroke` block and §1.3's template macro against the current
   tree (grep the method/test names; ignore stale line refs).
4. Execute P1 → P3 → P2-finalize (P2 steps 1–3 can be drafted any time, but its test list is
   final only after P3). House rules: `fg` wrapper for build/test; long ops launched ONCE in
   background, wait for the task notification; Edit tool only on `.coffee`; STOP on any
   UNEXPECTED pixel change (the P1 recapture is the expected one); commits via
   `git commit -F <file>` at the phase boundaries with ONE end-of-arc review
   (owner-workflow-long-arcs), push only on owner OK.
5. Close: full `fg gauntlet` + `fg homepage`; archive this plan + INDEX line + memory note;
   BACKLOG line closes.

## §6 Rejected alternatives — do NOT re-attempt

- **Byte-preserving tricks for the flip**: dead premise — (B) is a deliberate visual change;
  the recapture IS the mechanism. Do not contort the spelling to reduce churn
  (memory: dont-let-recapture-churn-dictate-design).
- **Extending `NON_INTEGER_GEOMETRY` to flag figure payloads**: the fractional landing is the
  reparent-transparency CONTRACT ("what you see while dragging is what you get"), sanctioned
  by the two-vocabulary law. Flagging it would fail the suite on legitimate state.
- **A `fracplane` gauntlet leg**: the gauntlet's full dpr2 suite leg already subsumes it —
  presuite-only, or it is pure duplication.
- **Quantizing the figure landing to integers instead of P2/P3**: a design change to the drop
  contract with user-visible snapping; out of scope, owner-gated, and it would NOT remove the
  need for dpr2 coverage of the class (other fractional producers may appear).

## §7 References

- `docs/archive/appearance-local-coords-plan.md` (the parent arc; §4.4 = the A/B decision).
- `docs/architecture/appearance-paint-convention.md` (the law this plan amends at P1.2).
- Memory: `appearance-local-coords-arc` (the clip/snap case law + dpr1-blindness),
  `byte-identical-not-sacred-for-benign-inspector-recapture`, `dont-let-recapture-churn-dictate-design`.
- `Fizzygum-tests/.scratch/rectprobe-stroke-decision.png` + `rectprobe-Bstroke/` (the P1.0 A/B pair).
- `Fizzygum-tests/scripts/run-sequence-headless.js` (P2's runner), `scripts/recapture.js` (P1.4).
