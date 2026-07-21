# Vector-icon crispness audit — why some icons render crisp and others mushy

**Status**: MEASUREMENT + ANALYSIS snapshot, 2026-07-19. Owner-requested investigation (the
"better vector icons" venue — deliberately SEPARATE from `plans/pixel-icons-plan.md`, but its
§7 findings are an input to that plan's §5 disposition re-judging). Filed under
`measurements/` per the docs README: a dated audit, superseded — never edited — by a newer
snapshot if re-run. Method: full code audit of the 91 `*IconAppearance.coffee` files + a
headless per-icon rendering measurement on BOTH backends (probe + regeneration commands in
§8). Line-number cites verified 2026-07-19; grep the symbol before trusting a line number.

## §1 The question, and the answer in brief

**Owner's observation** (2026-07-19): some icons look great — the eye, the thick arrows, the
close/collapse buttons; some look bad — the typewriter, the super-toolbar (`Toolbars*`).
**Owner's hypothesis**: the good ones carefully draw 1-px lines that start/end on clean
pixels regardless of icon size; the bad ones don't attend to stroke fit.

**The hypothesis is REFUTED by the code.** None of the named-good icons is pixel-aligned —
alignment is not the mechanism, and under Fizzygum's icon pipeline it *cannot* be (§2):

- `EyeIconAppearance` is bezier curves in a 200-unit space, fills only, fractional control
  points (`bezierCurveTo 38, 34, 162, 34, 192, 100`).
- The arrows are polygon fills with fractional vertices (`moveTo 1.5, 50.94`; `lineTo 20.65,
  70.08`).
- `PencilIconAppearance` is a fill drawn under a **13.16° rotation** — pixel alignment is
  impossible there by construction, and it still reads great.
- The close/collapse family shares a bezier ring (`IconAppearance._paintButtonRing`, 200-unit
  space) whose band is ~12.6 units ≈ **1.0 px** at its actual 16-px display size.

**What actually distinguishes them** (evidence in §3–§5): the good icons are **fill-only,
single-silhouette glyphs with generous feature widths** (arrow stem 26% of design space,
collapse bar 10.5%, eye band 11%) or ultra-simple ring glyphs; the bad icons are
**stroke-built line art** with feature widths of 1–2.5% of design space, fractional stroke
widths (`lineWidth = 2.5`), half-integer-offset *fills* (a stroke idiom misapplied), and
dense parallel details. At small sizes the thin features have literally no solid pixel
(fringe = 100% of ink), rendering as gray soup on native and as ragged, uneven, or dropped
strokes on SWCanvas.

**A discovery that reframes the pixel-icons discussion**: at the title-bar buttons' real
size (16 logical px; 32 device px at dpr 2), SWCanvas's no-AA thresholding turns the eye and
close glyphs into **coherent 1–2 px pixel art** — connected ring, clean X, classic-Mac look
(§4.4). The icons the owner loves under the daily `?sw=1` backend are *already de-facto
bitmap icons*, manufactured accidentally by thresholding a simple thick shape. The bad icons
fail precisely because thresholding thin/dense features yields raggedness instead.

## §2 The pipeline arithmetic — why "align to pixels" cannot be a vector-icon rule here

`IconAppearance.paintIntoAreaOrBlitFromBackBuffer` (`src/icons/IconAppearance.coffee`)
renders every icon as: clip → `useLogicalPixelsUntilRestore()` (scale by `ceilPixelRatio`) →
translate to `calculateRectangleOfIcon()` (the `preferredSize` box **aspect-fit and centered**
in the widget bounds, `.round()`ed) → scale by `fit/preferredSize` → scale by
`preferredSize/specificationSize` → `paintFunction` in design space.

Net effect: design-space coordinates are multiplied by `displaySize/specificationSize` — an
**arbitrary fractional scale** decided by whatever size the widget happens to have. A
coordinate that lands on a pixel boundary at one size lands mid-pixel at the next. Only when
an icon is displayed at exactly `specificationSize` (or an integer multiple/divisor) does
coordinate discipline survive. Measured display sizes of the named icons:

| Icon(s) | Design space | Real display size | Effective scale | 1 design unit = |
|---|---|---|---|---|
| Close/Collapse/Uncollapse/Eye/Pencil (window chrome) | 200 (base default, no override) | **16 logical px** (`WindowWdgt.CLOSE_ICON_SIZE: 16`, `WindowWdgt.coffee:52`; 32 device px at dpr 2) | 0.08 | 0.08 px |
| Arrows N/S/E/W/NE/NW/SE/SW | 100 | menu-created, free-floating (varies) | varies | varies |
| Typewriter (doc-shortcut glyph) | 100 | inside the 95×95 `GenericShortcutIconWdgt` composite | ~0.7–0.95 | ~0.7–0.95 px |
| Toolbars ("super-toolbar" app icon, `ToolbarsApp.buildIcon`) | 100 | same ~95 px composite family | ~0.95 | ~0.95 px |

So the close ring's 12.6-unit band = 1.0 px at 16 px; the typewriter's 2-unit document lines
= ~1.9 px at 95 px; the Toolbars `lineWidth = 1` details = **sub-pixel** at every real size.
Spec-size distribution fleet-wide: 69 files declare 100×100, 3 declare 400×400, 1 declares
200×200, 17 subclasses inherit the base's 200×200.

## §3 Code audit — what the good and bad files actually do

### 3.1 The named-good icons

| Icon | Construction | Thinnest salient feature |
|---|---|---|
| Eye | 2 bezier contours (opposite winding) + pupil circle, **one fill** | almond band ~11% of space |
| Pencil | 2 polygon subpaths, **one fill**, rotated 13.16° | body ~24% |
| Arrows ×8 | outline polygon fill + inset body polygon fill (2 fills) | stem 26% |
| Close | ring (2 opposite-winding circle contours, fill) + X as a **filled** shape | ring 6.3%, X arm ~4.5% |
| Collapse | same ring + `rect 65, 107, 65, 21` fill | bar 10.5% |
| Uncollapse | ring + rect fill + one `rect` stroke `lineWidth 10` (5% of space) | 5% |
| CollapsedState/UncollapsedState | one 3-point polyline stroke, `lineWidth 30` of 400-space | 7.5% |

Common: **fill-first construction** (every named-good except the two State glyphs and
Uncollapse's frame is fill-only), **one or two features total**, **feature widths ≥ ~5% of
design space** (≥ 1 px at their smallest real display size), **no dense detail clusters**.

### 3.2 The named-bad icons

- `TypewriterIconAppearance` (221 lines): six document-line `rect`s of **height 2** (2% of
  space) at **half-integer offsets** (`rect 29.5, 16.5, 30, 2`), eleven key-circle strokes at
  **`lineWidth = 2.5`** (fractional AND thin). The `.5` offset is the PaintCode export idiom
  for aligning 1-px *strokes* at scale 1; applied to *fills* it guarantees a 2-row gray
  fringe even at natural size, and means nothing at any other scale.
- `ToolbarsIconAppearance` (207 lines): thirteen **`lineWidth = 1`** strokes (1% of space —
  sub-pixel at every real display size), plus a big outline both filled and stroked at width
  7. The strongman's arm outlines and the drawer details go lumpy/ragged under SWCanvas at
  95 px (visually confirmed, §4.4).

### 3.3 Fleet-wide stats (all 91 files, counted 2026-07-19)

- **48 files are fill-only** (never call `stroke()`) — including every named-good icon.
- **20 files have thin strokes** (`lineWidth` ≤ 2.5 in a 100-space): CalculatingNode,
  DegreesConverter (+CF variant via inheritance), Destroy, ElasticWindow, EmptyWindow,
  FizzygumLogo, FizzygumLogoWithText, FloppyDisk, GenericPanel, Heart, Information,
  PatchProgrammingComponents, Save, Script, SimpleSlide, SliderNode, SlidesToolbar,
  Templates, Toolbars, Typewriter.
- **24 files use fractional `lineWidth`** (2.5, 1.5, 4.5, 3.5, 8.5 …; histogram: 46× `2`,
  40× `2.5`, 37× `1`, 22× `1.5` …).
- **56 files use half-integer coordinates** (the PaintCode stroke-alignment idiom, applied
  indiscriminately to fills and strokes alike).

## §4 Measurements

### 4.1 Method

Headless Chrome; the built world booted once per backend (`worldWithSystemTestHarness.html`,
native and `?sw=1`); every `*IconAppearance` class instantiated with a stub widget
(color BLACK) and rendered through the §2 transform chain (replicated verbatim minus
clip/alpha) onto offscreen surfaces from `HTMLCanvasElement.createOfPhysicalDimensions` (the
SW-aware factory) at logical sizes {16, 24, 32, 48, 64, 95, 128} × dpr {1, 2}. Per render,
from the alpha channel: `ink` (α>0), `solid` (α≥250), `fringe` = ink−solid, `interior` (ink
whose 8-neighborhood is all ink), `coverage` (Σα/255). 90 concrete classes measured (the
abstract base errors on the stub — expected). Derived columns:

- **fr16 / fr32 / fr95** = fringe share of ink at 16/32/95 px, dpr 1, native. Measures how
  much geometry misses the pixel grid (AA gray on native = threshold jag/dropout on SW).
- **thin95** = 1 − interior/ink at 95 px native: share of ink in features thinner than ~3 px
  — the "line-art-ness" of the icon at desktop-shortcut size.
- **swEdge95** = edge share of SW ink at 95 px: exposure to threshold raggedness.
- **covR16 / covR95** = SW coverage ÷ native coverage: <100% = SW *drops* ink (features miss
  pixel centers), >100% = SW *fattens* thin features to full pixels.

### 4.2 The named icons, measured

| Icon | fr16 | fr32 | fr95 | thin95 | swEdge95 | covR16 |
|---|---|---|---|---|---|---|
| ArrowNE | 27 | 15 | 5 | 8 | 9 | 101 |
| ArrowN | 23 | 18 | 5 | 11 | 11 | 94 |
| Pencil | 40 | 20 | 7 | 14 | 14 | 107 |
| Eye | 65 | 36 | 14 | 26 | 28 | 93 |
| Uncollapse | 93 | 54 | 21 | 35 | 38 | 96 |
| Collapse | 87 | 56 | 22 | 36 | 40 | 82 |
| Close | 85 | 56 | 21 | 39 | 44 | 85 |
| CollapsedState | 79 | 48 | 19 | 38 | 41 | 119 |
| UncollapsedState | 84 | 49 | 19 | 38 | 41 | 125 |
| **Typewriter** | 22 | 11 | 5 | **5** | 6 | 99 |
| **Toolbars** | 28 | 17 | 6 | **10** | 11 | 101 |

Two lessons the table teaches *against* naive metric-reading:

1. **Global averages dilute localized mush.** Typewriter scores among the fleet's BEST on
   every global metric — its big solid body dominates the statistics — yet the owner
   correctly judges it bad, because the salient details (document lines, key rings) are
   exactly the thin 5% . Same for Toolbars (thin arms on big solid cape/cabinet). Perceived
   quality tracks the WORST salient feature, not the average. The metrics locate line-art
   icons reliably; for solid-body-with-thin-details icons the code audit (§3.2) is the
   reliable detector.
2. **Thin-ish + simple can still read fine.** The close/collapse family measures mid-pack
   (fr16 85–93!) yet looks great at 16 px — because it is ONE closed simple shape, and
   SWCanvas thresholding lands it as connected 1-px pixel art (§4.4). Structural simplicity
   buys tolerance that dense detail does not get.

### 4.3 Fleet ranking — the line-art offenders (worst 20 by thin95)

Brush **85**, Flora 83, Templates 82, ScratchArea 76, UnderCarpet 74, LittleUSA 69,
Plot3D 69, LittleWorld 60, TextToolbar 59, Heart 57, Toothpaste 57, ScatterPlot 54,
SliderNode 54, ElasticWindow 53, EmptyWindow 53, CalculatingNode 51, Pencil2 51,
PatchProgrammingComponents 50, WindowsToolbar 48, Scooter 47.

Every one of these has **fr16 ≥ 90** — at 16 px they contain essentially *no solid pixel*
(many exactly 100): pure gray soup on native, pure threshold noise on SW. (Brush at #1
independently confirms the owner's old observation that the brush's highlight squiggle can't
survive small sizes.) Best-15 (thin95 ≤ 6): VideoPlay, VaporwaveBackground, Save,
VaporwaveSun, Typewriter†, ShortcutArrow, Script, RasterPic, Object, Folder, FloppyDisk,
Trashcan, SimpleSlide, PatchProgramming, PaintBucket — † = §4.2 lesson 1 applies: a
best-15 *global* score does not clear an icon whose thin details sit on a big solid body.

**SWCanvas 16-px coverage anomalies** (threshold distortion of thin features):
ScratchArea **165%** (SW fattens its hatching to +65% ink), UncollapsedState 125%,
WindowsToolbar 127%, ElasticWindow 122%, Templates 121%, CollapsedState 119%, FunctionPlot
119% — versus Flora **60%**, PatchProgrammingComponents 68%, Heart 77%, AngledArrowUpLeft
81%, Collapse 82% (SW *drops* up to 40% of the glyph). Both directions are the same disease:
features near 1 px land on or off pixel centers essentially at random.

### 4.4 Visual findings (6× nearest-neighbor dumps; regenerate per §8)

- **Eye & Close, 16 px, SWCanvas**: coherent connected pixel art — unbroken 1-px ring, clean
  4-px-arm X, solid pupil in a connected almond. At dpr 2 (32 device px) even better: clean
  2-px bands. *These are exactly the glyphs a pixel-icon author would draw by hand.*
- **Eye & Close, 16 px, native**: legible but soft — the same geometry as AA gray.
- **Typewriter, 95 px, SWCanvas**: legible body, but the key circles are lumpy/uneven (the
  2.5-unit strokes alternate 2-px and 3-px) and the document lines sit unevenly — the
  "doesn't attend to stroke fit" look the owner named.
- **Toolbars, 95 px, SWCanvas**: the `lineWidth = 1` arm outlines render as ragged wobbling
  1-px runs; the white header line nearly vanishes.
- **ArrowN, 32 px, SWCanvas**: clean chunky silhouette, minor edge steps, fully legible.

## §5 What the good icons have in common (the actual answer)

1. **Fills, not strokes.** All named-good are fill-built. A fill's edge raggedness is
   bounded by its perimeter; a stroke's *width* is itself sub-pixel-fragile under scaling.
2. **Generous feature width**: thinnest salient feature ≥ ~5% of design space, hence ≥ ~1 px
   at the smallest real display size — and the icons that read best (arrows, pencil) carry
   10–26%.
3. **Structural simplicity**: one silhouette or ring + at most ~2 inner features. Simple
   closed shapes survive thresholding as *connected* runs; the eye forgives a soft or jagged
   edge on ONE shape, not on twelve parallel ones.
4. **Feature separation**: no parallel thin details 1–3 px apart (typewriter doc lines, the
   drawer hatching) whose AA fringes merge into gray or whose thresholded runs collide.
5. **Luck, at the chrome size**: the ring glyphs' specific geometry happens to threshold
   into connected 1-px circles at 16 px under SW. This is real but *unengineered* — nothing
   guarantees it survives a redesign, a size change, or a different dpr.

## §6 The crispness rules — and what "make the bad ones follow them" really means

Rules a vector icon must follow to render crisp in THIS pipeline (arbitrary aspect-fit
scaling, native AA + SW threshold backends):

- **R1 — build from fills.** Convert every stroked feature to a filled band/outline shape
  (the arrows' two-polygon pattern is the house style to copy).
- **R2 — minimum feature width**: ≥ 2 px at the smallest display size of the icon's usage
  cohort (chrome 16 px ⇒ ≥ 12.5% of a 100-space; shortcut 95 px ⇒ ≥ 2.1%). Features that
  can't be that thick must be dropped or merged at that cohort size.
- **R3 — minimum feature separation**: ≥ 2 px at cohort size; no parallel thin clusters.
- **R4 — complexity budget**: what must read at 16 px is one silhouette + ≤ 2 inner
  features; save the rest for large-only variants.
- **R5 — kill the misapplied `.5` idiom**: half-integer offsets only ever helped 1-px
  strokes at scale 1.0; on fills they are pure fringe. Integer `lineWidth` only, if strokes
  survive R1 at all (56 files use `.5` coords today; 24 use fractional widths).
- **R6 — design at cohort size**: pick `specificationSize` = the size the cohort actually
  displays (16/32 chrome; ~95 shortcuts) so scale ≈ 1 and coordinate discipline means
  something; displaying at other sizes reintroduces arbitrary scaling (R2's margins are what
  keep that acceptable).

**The honest scope limit**: R1/R5 are mechanical-ish per-file edits, but R2–R4 are
**redraw-level decisions** — thickening the typewriter's document lines, simplifying the
strongman, redrawing hatching as bands changes the artwork, not the numbers. There is no
mechanical transform from a bad icon to a rule-following one; "follow the rules" =
re-authoring each bad icon *at its cohort size with pixel-budget thinking* — which is
substantially the same design work the pixel-icons plan's grids require, minus the grid.

## §7 Disposition input — the three tiers (feeds `plans/pixel-icons-plan.md` §5 re-judging)

- **Tier A — already crisp, leave as vector (owner's instinct confirmed)**: the fill-only
  chunky set — the 8 arrows, Pencil, Eye, VideoPlay + the best-15 list's genuinely-simple
  members (Object, Folder, ShortcutArrow, PaintBucket, SimpleSlide, PatchProgramming,
  Trashcan …). Nothing to fix; converting them to bitmaps is optional aesthetics, not need.
  The chrome ring family (Close/Collapse/Uncollapse/States) ALSO belongs here today — but
  note §5.5: its 16-px quality is lucky thresholding; if any redesign touches it, either
  re-verify at 16 px/SW or pin it deliberately as a pixel icon.
- **Tier B — solid base, localized thin details; fixable by targeted redraw (R2/R3 on the
  details only)**: Typewriter (document lines → 3-unit bands, keys → filled dots),
  Toolbars (arms/details thickened or dropped), and the §3.3 thin-stroke list's
  solid-body members (Save, FloppyDisk, Script, GenericPanel, SlidesToolbar,
  Templates-frame …). Vector redraw and bitmap conversion are comparable effort here;
  per-icon owner taste decides.
- **Tier C — wholesale line art; vector fix = full re-authoring**: the §4.3 worst-20
  (Brush, Flora, ScratchArea, UnderCarpet, Heart, Toothpaste, ElasticWindow, EmptyWindow,
  CalculatingNode, SliderNode, plot icons, LittleUSA/LittleWorld …). These have no solid
  pixel at 16 px and ragged SW at every size. The realistic choices are: redraw as chunky
  fills (Tier-A style, losing the fine-line character), convert to pixel grids (which is the
  same redesign with an honest medium), or accept them as large-size-only icons. These are
  the strongest bitmap candidates in the fleet.

## §8 Regeneration + limitations

- Probe (gitignored): `Fizzygum-tests/.scratch/icon-crispness/probe.js`. Run from its own
  directory (Node resolves `puppeteer`/`scripts/lib` upward from the script):
  `node probe.js --out=metrics-native.json --pngdir=pngs` and
  `node probe.js --sw --out=metrics-sw.json --pngdir=pngs`. Needs a fresh FULL build. ~60 s
  per backend, one browser each. PNGs are 6× nearest-neighbor upscales on white.
- Limitations: (a) global metrics dilute localized defects (§4.2 lesson 1 — Typewriter/
  Toolbars must be caught by code audit, not thresholds); (b) stub-widget render replicates
  the transform chain verbatim but skips clip/shadow (irrelevant to crispness); (c) fringe
  measures grid-miss, which is *necessary but not sufficient* for perceived mush — structure
  (§5.3) modulates perception; the PNG dumps were the arbiter for every named judgment here;
  (d) icon color was BLACK on transparent; hue interactions (e.g. the outline-vs-body
  two-tone) don't change geometry findings.

## References

- `plans/pixel-icons-plan.md` — the bitmap venue; its §5 disposition takes §7 above as input.
- `architecture/integer-pixel-placement-and-sizing.md` — Layer C ("content rendering is not
  integer, and that is correct") is the standing policy this audit's pipeline arithmetic
  (§2) rests on.
- `src/icons/IconAppearance.coffee` (pipeline), `WindowWdgt.coffee:52` (`CLOSE_ICON_SIZE`),
  `GenericShortcutIconWdgt.coffee` (95×95 composite).
- Memory: `swcanvas-reproduces-what-native-hides`, `fizzygum-runtime-backend-swcanvas`.
