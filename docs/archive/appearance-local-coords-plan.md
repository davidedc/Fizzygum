# Appearance local-logical-coordinates conversion (affine plan §7.7)

> **STATUS 2026-08-12: ✅ COMPLETE — Tiers 1–4 all LANDED. The COORDINATE CONVERSION (Tiers
> 1–3) is byte-identical everywhere (zero reference changes); Tier 4's deletion of the dead
> `Widget._drawHighlightOverlay` shortened the inspector's inherited-member list, which
> re-scrolled `macroDuplicatedInspectorDrivesCopiedTargetOnly`'s member-list window — the ONE
> recaptured test, under the standing owner grant for benign inspector member-list churn
> (memory `byte-identical-not-sacred-for-benign-inspector-recapture`; root-caused to the pixel
> via `fg diffpage` before recapturing).
> The close-gauntlet ALSO surfaced one REAL dpr2-only regression, root-caused via tier-bisect +
> draw-call instrumentation and FIXED with zero recaptures
> (`macroDropIntoRotatedStretchablePanelStretchesOnResize`): §5.1's C1 risk materialized in the
> ONE place plane geometry is legitimately FRACTIONAL — a rotated-container payload's figure —
> where (a) the scope's ADDED damage clip (the legacy Rectangular paint never clipped)
> quantizes its boundary differently from the fills under the buffer's fractional ambient
> translate, and (b) raw fractional fills quantize at the rasterizer instead of legacy
> `Math.round`. Fix: `opts.clip: false` for the self-bounding Rectangular body/stroke (the
> droplet hook re-clips itself), and `_fillLocalRectSnappedToDevicePixels` reproducing the
> `paintRectangle` device-grid quantization (identity for integer geometry). Law updated.**
> The §4.4 stroke decision landed as (A) — the device-hairline
> spelling, exact; option (B) remains an open TODO in `RectangularAppearance.paintStroke`.
> §4.4's Desktop probe verdict: the pattern-fill hook stays DEVICE-space by declaration
> (a CanvasPattern anchors to the coordinate space; scale/phase would shift under the scope's
> CTM), repositioned after the scope closes and verified byte-identical by a dedicated
> wallpaper A/B probe (patterns 2–7 × dpr 1/2, `Fizzygum-tests/.scratch/render-wallpaper-probe.js`).
> Durable residue: the convention law lives in
> `docs/architecture/appearance-paint-convention.md`; the ONE preamble is
> `Appearance._paintInLocalScope`. `_drawHighlightOverlay` (dead) deleted everywhere.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-12 at Fizzygum `46c046a3` / tests `36ac5c1f5` (both pushed, gauntlet 14/14 on
that tree). Every `file:line` below was verified on that tree; **lines drift — the method name /
quoted code is authoritative, re-grep before trusting a number.**

**MANDATE.** Eliminate the *absolute-device-coordinate* idiom from appearance paint bodies and
collapse the three coexisting paint-preamble spellings into one, so that every appearance body is
a widget-local, logical-pixel program drawn **through the ctx matrix** — the form a vector-replay
layer (affine plan §7.1/§7.2) can run under an arbitrary CTM. Where a body is *deliberately*
device-space (one family, documented below) the plan records the law it satisfies instead of
converting it. This is a transformation of the convention, not a burial: at the end there is ONE
written paint-convention law, dead machinery is deleted, and the absolute idiom survives only
where a stated invariant requires it.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on a single canvas (two backends: native
HTML5 and the deterministic SWCanvas — the suite screenshots SWCanvas byte-exactly). Pluggable
`*Appearance` objects do all widget drawing. The rendering loop is broken-rectangles repaint;
**compositing uses no ctx transforms** — device pixels have historically come from manual
`* ceilPixelRatio` multiplication (affine plan §3.2). The affine-transforms arc (CLOSED, phases
0–4) added `TransformFrameWdgt` islands that buffer a subtree un-transformed and composite the
buffer through one matrix — so appearance bodies today never see an island matrix.

This plan is affine plan §7.7 (`docs/plans/affine-transforms-plan.md:1900-1907`): *"Appearance
conversion to local-logical-coordinate drawing (through the ctx matrix, legacy integer path kept
as the identity fast path) — the prerequisite for widespread vector-replay"*. The immediately
prior related arcs: the 2026-07-27 Appearance-delegation arc
(`docs/archive/cross-branch-duplication-refactors-plan.md` §1) moved the nine custom widget
painters onto appearance objects **verbatim** (byte-identity outranked helper reuse — prologue
unification was explicitly deferred as its "optional polish step 4", never executed); the
direct-shape/hairline/roundRect arcs (2026-08) gave both backends one crisp drawing vocabulary.

**⚡ CRITICAL REFRAME — §7.7's wording is STALE; the territory is smaller and different than it
says.** A full inventory (2026-08-12, 112 `*Appearance` classes) found:

- **93 of 112 are ALREADY local-logical** — including the whole icon family (91 classes), which
  draws `paintFunction` art in a 200×200 *spec space* under a translate+scale CTM
  (`IconAppearance.paintIntoAreaOrBlitFromBackBuffer` ~:74: `useLogicalPixelsUntilRestore` →
  `translate` → two `scale` calls). Icons are vector-replay-shaped TODAY.
- **5 are MIXED** (device-space clip + background, then local-logical content):
  LayoutChromeAppearance, GraphsPlotsChartsAppearance, Example3DPlotAppearance,
  AnalogClockAppearance, SimpleDropletAppearance.
- **13 are ABSOLUTE-ACTUAL**, and they split in two:
  - the real conversion targets: **RectangularAppearance** (the workhorse — every plain
    rectangular widget, window panel, menu box), **DesktopAppearance** (2 wallpaper hooks over
    Rectangular), **LabelButtonAppearance** (one `paintRectangle` call);
  - the **SizeAwareIconAppearance family (base + 9)** — absolute-DEVICE by *documented deliberate
    design* (`src/icons/SizeAwareIconAppearance.coffee:65-73`: "deliberately NO
    useLogicalPixelsUntilRestore(): subclasses draw in integer DEVICE pixels" — dpr-specific
    pixel-exact icon art, the typewriter-size-aware arc). **EXCLUDED from conversion** (§6).
- The "legacy integer path kept as the identity fast path" clause is MOOT as originally feared:
  SWCanvas's fast paths gate on `isAxisAligned`/`isUniformScale`, **not** `isIdentity` (§1.3), so
  drawing through a translate/scale CTM disengages nothing. There is no second path to keep.

So the actual work = convert the absolute trio, normalize the five MIXED preambles, unify the
three preamble spellings, delete dead machinery, and write the law. Plus one owner decision
(§4.4: the Rectangular stroke's device-hairline vs logical-hairline).

---

## §1 Current architecture (verified 2026-08-12)

### 1.1 The paint call chain and key values

Recursive paint is back-to-front; leaf paint calls
`appearance.paintIntoAreaOrBlitFromBackBuffer(aContext, clippingRectangle, appliedShadow)`.
`Widget.calculateKeyValues` (`src/basic-widgets/Widget.coffee:2571-2586`) returns
`[area, sl, st, al, at, w, h]`: `area` = the *logical*-px `clippingRectangle ∩ @bounds`
(`.round()`ed); `al/at` = its top-left **in device px** (`* ceilPixelRatio`); `w/h` = device-px
size clamped to the widget; `sl/st` = the same corner relative to the widget (device px — the
back-buffer source offset). `BackBufferMixin` overrides it (`mixins/BackBufferMixin.coffee:66`).

`useLogicalPixelsUntilRestore` is a pure CTM scale, defined twice:
`boot/extensions/CanvasRenderingContext2D-extensions.coffee:5-6` (native:
`@scale ceilPixelRatio, ceilPixelRatio`) and `boot/extensions/SWCanvasElement-extensions.coffee:252-254`
(SWCanvas: same, plus `@textPixelDensity = ceilPixelRatio` so text keeps its atlas direct-blit
fast path; `textPixelDensity` is save/restore-snapshotted).

### 1.2 The three preamble spellings (the duplication this plan dissolves)

All three produce the same scope: save → clip to the damage box → set alpha → logical pixels →
translate to the widget position.

1. **`Appearance._beginLogicalPixelsBox`** (`src/Appearance.coffee:47-58`) — the factored helper;
   used ONLY by Boxy/CircleBoxy/UpperRightTriangle. Leaves the ctx SAVED (caller restores).
2. **Re-inlined copies** in HandleAppearance (:16-26), PenAppearance (:15-25), CellAppearance
   (:24-28), SheetHeaderCellAppearance (:30-34), DragChargingRingAppearance (:17-22) — with
   drift: Cell/SheetHeaderCell omit `globalAlpha` entirely; DragChargingRing uses plain
   `@widget.alpha` instead of the shadow-aware product.
3. **The MIXED five**: device-space `clipToRectangle al,at,w,h` + device-space background
   `paintRectangle al,at,…` first, THEN `useLogicalPixelsUntilRestore` + `translate` for content
   (canonical: `GraphsPlotsChartsAppearance.coffee:10-41`).

The fine-tail dedup sweep (2026-08-12, `duplication-report/triage-report.md` "SRC FINE-TAIL
SWEEP") measured this family as the largest un-harvestable duplication in src — un-harvestable
*by text-level extraction*; this plan is the design-level fix.

### 1.3 SWCanvas CTM facts (vendored `vendor/swcanvas.js`, pin `430cafa9`; verified in code)

- `Transform2D` precomputes `isAxisAligned`/`isUniformScale`/`scaleX/Y`/`scaledLineWidthFactor`
  at construction (`swcanvas.js:1135-1157`). For a pure translation ALL derived properties equal
  identity's — only `isIdentity` differs.
- **No direct-shape fast path gates on `isIdentity`** (grep: 8 `isIdentity` hits in 29.5k lines;
  the 4 dispatch hits — roundRect ×3 + stadium — are argument-plumbing shortcuts into the SAME
  renderer, numerically equal at `scaleX === 1`). The full dispatch conditions are richer than
  the CTM alone — twice owner-corrected 2026-08-12; the COMPLETE per-entry audit now lives in
  the SWCanvas repo's `DIRECT-RENDERING-SUMMARY.MD` §3 (per-entry dispatch table) — cite THAT,
  not this summary, for anything beyond this plan's needs. What this plan relies on:

  | entry | CTM condition for direct | non-CTM conditions for direct |
  |---|---|---|
  | `fillRect`/`strokeRect`/`fillStrokeRect` | `isAxisAligned` (0/90/180/270, ANY scale incl. non-uniform, flips) → `RectOpsAA`; else `isUniformScale` (tilted) → `RectOpsRot`; generic ONLY at `!isAxisAligned && !isUniformScale` (non-90° rotation + non-uniform, shear, mirror-with-rotation) | Color paint, `a>0`, source-over, `_noShadow` |
  | `fill/strokeRoundRect`, `fillStadium` | `isUniformScale` required, ladder identity→axis-aligned→rotated (⚠ stricter than plain rects: axis-aligned `scale(2,1)` goes generic here) | same as rects |
  | `fill/strokeCircle`, arcs | `isUniformScale` (any rotation); non-uniform ⇒ correct ellipse via a pre-gated external-path fallback (P6) | Color, source-over; arcs additionally `lineCap === 'butt'`; ⚠ NO shadow gate (ctx shadows silently dropped — SWCanvas gap, recorded there) |
  | `strokeLine` | none (ANY CTM incl. shear; width via geometric-mean scale) | Color, source-over, `lineCap === 'butt'` |

  Fizzygum appearance painters satisfy the non-CTM columns today (Color fills, source-over, no
  ctx shadows — widget shadows are the Fizzygum-level appliedShadow pass; the two direct-stroke
  users know the lineCap rule — `UpperRightTriangleAppearance` documents it). Hairline
  classification uses `scaledLineWidth` (= `lineWidth × scaledLineWidthFactor`), unchanged under
  translation. Tier-0 rect clipping (`clipToRectangle` under a translate CTM) still detected.
  **A translate or dpr-scale CTM disengages NOTHING; even tilted/uniform-scaled replay (the
  future §7.1/§7.2) keeps fast paths for most shape content.**
- Path fills bake the CTM into device coords at path-BUILD time (`:25553-25571`); rasterizer
  entry rounding is `floor`/`ceil`/`ceil(v−0.5)` of values that shift by an exact integer under
  integer translation ⇒ **byte-identity is provable for integer/dyadic geometry**.
- **The one FP hazard (the C1 class):** expressions like `fillRect`'s
  `(x + w/2 + e) − w/2` recovery and `_findPolygonIntersections`' `p1.x + t·dx` re-round; IEEE-754
  addition is not associative, so NON-dyadic painter arithmetic (`/3`, `sqrt`, trig, fit-scales)
  can shift ≤1px when moved between coordinate spaces — exactly
  `docs/architecture/integer-pixel-placement-and-sizing.md:111-131`. Mitigation: preserve each
  expression's association order when converting; treat fractional vector art as recapture-risk.
- **Text: conversion is a strict WIN.** `TextRenderer._isDirectBlitEligible(t,dpr)` requires
  `t.a === dpr` + integer translation (`swcanvas.js:24028-24031`). Absolute-device text on the
  world context at dpr 2 has `t.a = 1 ≠ dpr = 2` ⇒ slow intermediate-buffer path TODAY; logical
  coords under the `useLogicalPixelsUntilRestore` CTM hit the fast path.
- Precedent for absolute-coords-under-integer-translate: the shadow silhouette helper
  (`Appearance._paintDamagedAreaAsBlackSilhouette`, `src/Appearance.coffee:73-82`) runs painters
  under `sctx.translate -al, -at` today.

### 1.4 Debris (verified)

- **`_drawHighlightOverlay` is dead everywhere**: base stub empty (`Appearance.coffee:29`), the
  sole override is `return` + commented body (`RectangularAppearance.coffee:26-40`), yet it is
  still called at the tail of ~8 paint methods and documented as "actual px" in ~6 places.
- **`paintRectangle` fillStyle leak**: `Widget.paintRectangle` (`Widget.coffee:2633-2657`)
  without `pushAndPopContext` leaves `fillStyle` (and sometimes `globalAlpha`) set; four callers
  tolerate/rely on it (LayoutChrome :37, GraphsPlotsCharts :35, Example3DPlot :38, AnalogClock
  :55). Same hazard class as the P3 "black dash via the fillStyle side-effect" defect
  (`docs/BACKLOG.md`, direct-shape-fastpaths P3). `RectangularAppearance.coffee:66` sets a
  `fillStyle` that is immediately overwritten — a stale leftover.
- `UpperRightTriangleAppearance._renderingHelper` sets `lineWidth` *before* its own `save()`
  (`:43-45`) — leaks into the outer scope (currently harmless).

### 1.5 RectangularAppearance exactly (the core target — quoted, `src/basic-widgets/RectangularAppearance.coffee`)

Body (:49-110): prelim check → `_setUpBackgroundPattern?` hook → keyValues → save → shadow-aware
`globalAlpha` → **background = fill the whole DAMAGE box** `al,at,w,h` (the padding halo beyond
the tight box) → **main fill = damage ∩ `boundingBoxTight().scaleBy ceilPixelRatio`** → droplet
hook → `paintStroke` (skipped in shadow pass) → `_paintBackgroundPatternFill?` hook → restore →
dead `_drawHighlightOverlay`. All in device px via `@widget.paintRectangle`.

`paintStroke` (:112-161): re-derives keyValues (`_calculateKeyValuesOrNil`), clips to the rounded
damage∩tight box, then `lineWidth = 1` — **1 DEVICE px regardless of dpr** (comment :125: "stroke
width is baked to 1, regardless of the ceilPixelRatio", with an open TODO "might look better if
* ceilPixelRatio") — `strokeRect (round(left*cpr)+0.5, round(top*cpr)+0.5, round(w*cpr)−1,
round(h*cpr)−1)`. So at dpr 2 every rectangular border is a device hairline (visually half the
logical thickness), unlike BoxyAppearance's logical spelling (`strokeRoundRect 0.5, 0.5, w−1,
h−1` in logical px = 2 device px at dpr 2).

---

## §2 Why it is shaped this way

Morphic.js descent: the original engine composited by manual pixel arithmetic (no ctx
transforms), so every painter was written in device space. `useLogicalPixelsUntilRestore` arrived
with HiDPI; newer appearances adopted translate+logical piecemeal, old ones (Rectangular, the
delegation-arc verbatim moves) kept their coordinates. The delegation arc *deliberately* did not
unify prologues (byte-identity outranked reuse — its §1 step 4 "optional polish" is this plan).
The SizeAware family went the OTHER way on purpose: dpr-conditional pixel art wants integer
device coordinates (its header says so). Nobody ever wrote the convention down, so three
spellings coexist and every new appearance picks one by imitation.

## §3 The distilled argument

1. **Vector-replay (affine §7.1/§7.2) needs bodies that draw through the CTM.** The island
   architecture buffers because bodies can't be replayed under a matrix. Icons already can; after
   this arc everything except the documented device-space family can. This is the enabling step,
   deliberately shippable long before any replay engine exists.
2. **The conversion is now KNOWN cheap and safe where it matters**: the 2026-08-12 SWCanvas audit
   (§1.3) proved translate/scale CTMs disengage no fast path and that integer/dyadic geometry is
   byte-identical by construction. The feared "legacy fast path to keep" doesn't exist. Prior
   sessions could not have known this — the stale `DIRECT-RENDERING-SUMMARY.MD` table claiming
   circles need identity was only falsified 2026-08-08 (direct-shape follow-ups P1).
3. **Text perf at dpr 2 improves as a side effect** (§1.3 text fact) — absolute-device text
   painters currently miss the atlas direct-blit path on the world context.
4. **The duplication is otherwise un-fixable**: the fine-tail sweep proved the preamble family
   can't be folded textually while three conventions coexist. One convention + one template =
   the whole family dissolves.
5. **The safety nets exist**: byte-exact suite (290 tests ×3 engines), the paint-truthfulness
   gate, `fg diffpage` for eyeballing, and the census/settle gates — the same nets that carried
   the delegation arc and the direct-shape recapture.

## §4 Fix shape

### 4.1 The law (write into `docs/architecture/` at close — new file or a section of
`integer-pixel-placement-and-sizing.md`)

> **The appearance paint convention.** An appearance body draws its widget's OWN pixels in
> widget-local LOGICAL coordinates, through the ctx matrix, inside the standard scope
> (save → damage clip → alpha → `useLogicalPixelsUntilRestore` → translate to widget position).
> Damage clipping, the shadow-silhouette fallback, and back-buffer blitting are the PREAMBLE's
> device-space business — a body never touches `al/at/sl/st`. The body receives the damage box
> as a LOCAL rect for partial-repaint fills. Exception, by declaration only: a body may draw in
> integer DEVICE pixels anchored at the widget origin when its art is dpr-conditional pixel work
> (the SizeAware family) — such a body documents it and never reads `al/at`.
> Ctx state set by a body is contained by the preamble's save/restore; leaving state as a
> contract for a callee within one body is allowed, across bodies it is not.

### 4.2 The template (Tier 1 — mechanism, zero body changes)

On `Appearance`, one preamble entry replacing spellings 1–3 (parameterized where the five MIXED
differ: alpha source, background-fill policy, shadow-pass policy):

```coffee
# the ONE paint scope: nil (nothing to draw) or runs bodyFn ctx, localArea, appliedShadow
# inside save→clip(damage)→alpha→logical-pixels→translate(position), then restores.
_paintInLocalScope: (aContext, clippingRectangle, appliedShadow, opts, bodyFn) ->
```

`localArea` = `area.translateBy @widget.position().neg()` — logical, integer (both operands
rounded/integer). Existing `_beginLogicalPixelsBox` folds into it; the five re-inlined copies
(§1.2 spelling 2) convert mechanically (their bodies are already local-logical — this tier only
swaps the scaffold). Byte-identity expectation: exact (same ops, same order, same values —
Cell/SheetHeaderCell's omitted `globalAlpha` becomes an explicit opts choice reproducing today's
values).

### 4.3 Tier 2 — the MIXED five

Move each device-space background fill inside the scope as `fillRect localArea…` (logical). Fix
the four `paintRectangle`-fillStyle-leak sites by having each body set its own state (same
values ⇒ same pixels). AnalogClock's cached-face `drawImage` stays a device-space blit in the
preamble position (blits are preamble business — same as BackBufferMixin); only its hands/live
content ride the scope (they already do). SimpleDroplet's "logical but untranslated" body
(§ explorer note — parent-plane absolute coords) becomes widget-local by subtracting position
(integers; exact).

### 4.4 Tier 3 — the absolute trio, and THE OWNER DECISION

- **LabelButtonAppearance**: one fill → `localArea` fill in-scope. Trivial.
- **RectangularAppearance body**: background = fill `localArea`; main fill = fill
  `localArea ∩ boundingBoxTight-local`. All integer ⇒ byte-identical (§1.3).
- **RectangularAppearance `paintStroke` — decision point.** Two options:
  - **(A) Byte-identical conversion (DEFAULT, no ask needed):** keep the device-hairline visual
    by spelling it honestly in logical coords: `inset = 0.5 / ceilPixelRatio`,
    `lineWidth = 1 / ceilPixelRatio` (dyadic for dpr ∈ {1,2} ⇒ exact; `scaledLineWidth` = 1
    device px, same hairline classification). Comment states "this stroke is one DEVICE pixel by
    design". Zero recapture.
  - **(B) Convention flip to the Boxy logical spelling** (`0.5, 0.5, w−1, h−1`, `lineWidth 1`
    logical): visually THICKER borders at dpr 2 on essentially every rectangular widget ⇒ a
    near-total dpr-2 recapture. This also closes the file's own TODO (:151). **OWNER-GATED —
    present the A/B diff (one window screenshot at dpr 2) and ask.** Do NOT let the recapture
    cost decide silently (owner rule: churn must not dictate design; but a mass recapture always
    needs an explicit OK).
- **DesktopAppearance**: its two hooks fill with a canvas `pattern`. ⚠ Pattern fills anchor to
  the coordinate space — a translate CTM SHIFTS pattern phase. The desktop sits at the origin
  (translate(0,0) ⇒ no shift) but this is exactly the zero-coverage path (item-7 record:
  wallpaper has NO test). Convert LAST with a dedicated wallpaper A/B probe, or — acceptable
  fallback under the law — leave both hooks device-space *with the declaration* (they are
  isolated hooks, not duplicated preamble). Executor's call after probing; do not skip the probe.

### 4.5 Tier 4 — debris deletion + law

Delete `_drawHighlightOverlay` (stub, disabled override, all ~8 call sites, all ~6 comment
blocks). Remove `RectangularAppearance.coffee:66`'s overwritten `fillStyle`. Move
`UpperRightTriangleAppearance._renderingHelper`'s `lineWidth` inside its save. Write the §4.1 law
into `docs/architecture/`; update `Appearance.coffee`'s header; flip affine plan §7.7 to LANDED
with a pointer; INDEX line; BACKLOG line closes.

### 4.6 Explicitly OUT of scope

- SizeAwareIconAppearance family (base + 9): stays device-space BY LAW (§4.1 exception). Its
  header already carries the declaration.
- Icon family (91): already conformant (spec-space through the CTM). No edits.
- BackBufferMixin blitting, `calculateKeyValues` itself, the island compositor: preamble/device
  business, untouched.
- Any actual vector-replay engine (§7.1/§7.2): a later arc.

## §5 Central risks

1. **C1 FP non-associativity** (§1.3): any body whose art computes non-dyadic intermediates may
   shift ≤1px when its origin moves into the CTM. The MIXED five's content already lives in the
   scope (no change); the risk concentrates in Rectangular/LabelButton/Desktop — whose geometry
   is all integer. Residual risk ≈ zero, but the gate is empirical: presuite per tier, `fg
   diffpage` on ANY mismatch, STOP and root-cause (never recapture to make a tier pass —
   recapture only for a consciously-approved §4.4(B)).
2. **Pattern phase under translate** (Desktop, §4.4) — probed, not assumed.
3. **Side-effect contracts** (§1.4): converting a caller that today INHERITS a leaked
   `fillStyle` must set its own — verify each of the four sites' values match what leaked.
4. **Shadow pass**: bodies run twice (normal + `appliedShadow`); the scope's alpha policy must
   reproduce each class's current shadow-alpha product exactly (spelling-2 drift means
   per-class opts, not one guess).
5. **Suite blind spots**: wallpaper and some info-doc surfaces have zero coverage — use the
   render-probe pattern (`Fizzygum-tests/.scratch/render-doc-windows.js`, fresh SW world +
   window-box clip + `cmp`) for any zero-coverage surface a tier touches.

## §0.5 Cold-execution protocol

1. Read this doc fully. Re-verify §1.5's two quoted methods and §1.2's five inlined-preamble
   sites against current source (grep the method names; ignore stale line numbers).
2. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (expect clean repos; if this doc
   is uncommitted, that is expected — plans commit with their arc).
3. **Phase 0 probe (½ h, no product code):** on a built tree, an SW headless probe that renders
   one plain rectangular window (a) as-built and (b) with a scratch-patched RectangularAppearance
   drawing body+stroke in the §4.4(A) local spelling — `cmp` the clipped PNGs at dpr 1 AND dpr 2.
   Byte-equal ⇒ proceed; diff ⇒ STOP, root-cause against §1.3's math before any tier lands.
   Also capture the §4.4(B) dpr-2 screenshot pair for the owner ask. Probe home:
   `Fizzygum-tests/.scratch/` (gitignored; puppeteer resolves there).
4. Execute tiers 1→4 in order; after EACH tier: `fg build` + `fg presuite`; any pixel mismatch =
   STOP per §5.1. Tier boundaries are commit points (present summary, owner OK — house rule).
5. Close: full `fg gauntlet` + `fg homepage`; docs per §4.5; archive this plan via the close-arc
   flow; memory note.

## §0-R Phase-0 probe results (2026-08-12, same session as authoring)

- **§4.4(A) byte-identity: PASS.** `RectangularAppearance` body + `paintStroke` scratch-converted
  to the local spelling (probe diff kept the association orders of §1.5's derivation); welcome +
  templates windows rendered on fresh SW worlds, window-box-clipped, at dpr 1 AND dpr 2
  (viewport `deviceScaleFactor` mirrors `?dpr` so the PNGs carry real device pixels):
  **all four pairs BYTE-IDENTICAL** (`Fizzygum-tests/.scratch/render-rect-probe.js`,
  outputs `rectprobe-A/` vs `rectprobe-B/`). The derivation §1.3 relies on (integer/dyadic ⇒
  exact) held empirically: `1/cpr` lineWidth and `0.5/cpr` insets reproduce the device-hairline
  stroke bit-for-bit.
- Suite-level evidence: see the session record — the probe tree also ran the dpr1 suite + paint
  audit (fg presuite) before reverting.
- The probe left the tree REVERTED; Tier 3 re-lands the conversion deliberately (with the hook
  repositioning done properly — the probe parked `_paintBackgroundPatternFill` on a recomputed
  device rect and left the droplet hook on device args, fine for probe subjects which have
  neither, NOT fine to land).

## §6 Rejected alternatives — do NOT re-attempt

- **Converting the SizeAware family to logical coords**: falsified by design — its art is
  dpr-conditional integer-device pixel work (its header documents why; the two-line-icon and
  hairline arcs baked cross-dpr crispness into device coordinates). The law's exception clause
  IS the fix.
- **Keeping a parallel "legacy absolute path" per appearance as an identity fast path**: dead
  premise — SWCanvas fast paths don't key on identity (§1.3); a second path would be pure
  duplication.
- **Text-level extraction of the preamble family without the convention change**: falsified by
  the fine-tail sweep (2026-08-12) — the three spellings differ semantically (alpha policies,
  clip nesting), which is why jscpd's clones there were declared un-harvestable.
- **Doing this arc as part of a vector-replay engine**: scope explosion; the conversion is
  independently gateable (byte-identity) and §7.1/§7.2 remain banked.

## §7 References

- `docs/plans/affine-transforms-plan.md` §3.2/§4.2/§7 items 1/2/7 (this is §7.7).
- `docs/archive/cross-branch-duplication-refactors-plan.md` §1 (the delegation arc; step-4 polish
  = this plan's Tier 1).
- `docs/architecture/integer-pixel-placement-and-sizing.md` :111-131 (C1 non-associativity case
  law) and §7 (crisp-spelling contract).
- `docs/archive/direct-shape-fastpaths-followups-plan.md` (P1 falsified the identity-gate myth;
  P3's fillStyle black-dash case law).
- Memory notes: `duplicated-code-refactor-arc` (fine-tail LEAVE reasons this plan dissolves),
  `typewriter-size-aware-experiment` (why SizeAware stays device-space), `affine-transforms-plan-authored`.
- ⚠ STALE, do not cite: `roundrect-fastpath-conversion-audit.md:31`'s "Circle fast path requires
  IDENTITY transform" (superseded 2026-08-08).
