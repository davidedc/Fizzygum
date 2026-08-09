> **ARCHIVED — EXECUTED IN FULL (2026-07-27).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Cross-branch duplication refactors (inverse-audit findings 4–6): paint→Appearance delegation, the code-runner base class, three small helper extractions

> **Status: EXECUTED 2026-07-27** (authored 2026-07-26/27; the sibling
> `mixin-application-tidyups-plan.md` ran first, same day). As-built record:
>
> - **R1 — DONE, all nine** painters converted to per-class Appearance delegation
>   (HandleAppearance, PenAppearance, LabelButtonAppearance, LayoutChromeAppearance,
>   CellAppearance, SheetHeaderCellAppearance, AnalogClockAppearance,
>   GraphsPlotsChartsAppearance, Example3DPlotAppearance), each gated green
>   individually (build + probe + presuite). The `opaqueCoveredRect` comment updated.
>   Two deviations, both principled: (a) subclass-polymorphic drawing TAILS stay on
>   the widgets as PUBLIC protocol methods — the existing `drawLayoutChrome` precedent
>   — so the plot family's private `_renderingHelper` was renamed `drawPlot` (3 concrete
>   plots + Example3D; a cross-object private call from the appearance would bump the
>   call-separation ratchet); (b) the clock keeps its 4 public `draw*Hand` methods +
>   `_drawHand` + all state widget-side (the inspect-edit demo edits `drawSecondsHand`;
>   the appearance computes into `@widget` fields). ONE churn class, verified benign
>   via fg diffpage: the clock's inspector member list lost 6 rows (5 moved `_` helpers
>   + the paint override) → gated recapture of `SystemTest_macroAnalogClockInspectEdit`
>   and `SystemTest_macroNakedInspectorRendersResizesAndEdits`, COMPLETE at dpr 1+2.
>   Every other conversion was zero-churn.
> - **R2 — DONE as `CodeAreaWdgt`**, but the plan's "shared `_reLayout`" claim was
>   FALSIFIED by the verbatim diff (the four bodies differ in button fields, 2-vs-3
>   button geometry, row heights and `_fullChanged` presence) — the base carries only
>   the byte-identical members: the shared fields (+padding comments), the
>   `_buildAndConnectChildren` settle-wrapper, the TWO code-area builder variants
>   (`_buildEditableCodeAreaNoSettle` — Script/CodePrompt; `_buildMonoCodeAreaNoSettle`
>   — Console/ErrorsLog) and `notifyTargetAndClose`; the four `_reLayout`s stay
>   per-class (their identical prologue is the bounds-first-gate shape and stays in
>   place). `SimpleLinkWdgt` left out as anticipated (its tempPromptEntryField is a
>   bare StringWdgt, a different animal).
> - **R3 — 1 and 2 DONE** (`Rectangle.largestCenteredSquare()` consumed by
>   GenericShortcutIconWdgt + FanoutWdgt; `PreferencesAndSettings.normalizedWheelDeltas`
>   consumed by ScrollPanelWdgt + SimpleSpreadsheetWdgt). **3 = the sanctioned LEAVE
>   outcome**: the pair's "pixel-alpha read" characterisation below is WRONG (falsified
>   at execution — both bodies are verbatim copies of
>   `RectangularAppearance.isTransparentAt` on two `BackBufferMixin`-painting
>   `CanvasWdgt` subclasses); unifying via an assigned RectangularAppearance would leak
>   its shape-specific menu entries, so both keep the copy with cross-reference
>   comments naming the twin.
> - Close gate: full gauntlet green (see archive INDEX). Original plan text kept
>   verbatim below.

**Mandate.** Each tier fully eliminates its duplication family by moving the behaviour
to its RIGHT home — the Appearance seam (R1), a shared base class (R2), plain
helpers (R3). Explicitly NOT mixins: the 2026-07-26 inverse mixin audit examined every
family below against the mixin doctrine and rejected it (rationale embedded per tier);
do not re-litigate that here.

## §0 Orientation

Fizzygum (CoffeeScript canvas GUI framework; no modules, all globals, source-as-text,
one class per file named after the class) draws every widget through a pluggable
**Appearance** object: `Widget::paintIntoAreaOrBlitFromBackBuffer` is a one-liner
delegating to `@appearance?.paintIntoAreaOrBlitFromBackBuffer` (`basic-widgets/
Widget.coffee` ~:481), and the `Appearance` base (`src/Appearance.coffee`) already
provides the factored paint-prologue helpers `_calculateKeyValuesOrNil` /
`_beginLogicalPixelsBox` that appearance subclasses (BoxyAppearance etc.) use.

The 2026-07-26 inverse mixin audit (`./find_duplicated_code.sh` +
`./find_similar_code.sh` → gitignored `duplication-report/`, `.ai.txt` files are the
LLM handoffs; plus `node buildSystem/census-hierarchy-duplication.js` and
`census-property-placement.js`) found the three families below. They are the largest
REAL duplication in `src/` (the whole tree is only ~1.4% duplicated). The mixin-shaped
findings went to the sibling plan; these three are delegation/base-class/helper shaped.

Line numbers were verified 2026-07-26 and DRIFT — the method names and quoted code are
authoritative; re-grep before trusting any `file:line`.

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — expect clean repos.
2. Read this plan fully; skim `docs/architecture/mixins.md` §2 only if you need the
   boot/meta background; R1 needs the rendering notes in root `Fizzygum/CLAUDE.md`
   (broken-rects loop, Appearance objects) and `../Fizzygum-tests/DETERMINISM.md`
   before touching paint code.
3. Every move is a VERBATIM move gated by a diff: fold only what is byte-identical
   (modulo comments/whitespace); a real delta stays in the subclass/class as an
   override. This is the fold-arc discipline that kept 2026-07's conversions
   pixel-clean.
4. Expected pixel churn: ZERO in all three tiers. Any suite failure →
   `fg diffpage <names>` and diagnose as a DEFECT first; the gated
   `fg recapture <names>` only for a verified-benign diff (none is expected).
5. Per tier: `fg build` → `fg presuite` (background + verdict file, never
   foreground-poll). Arc close: full `fg gauntlet` (13 legs). Ratchet gates
   (`instanceof-type-test`, `undefined-literal`, call-separation) stay at baseline —
   factor deeper, never bump. Do not commit/push without the owner's explicit word.

## §1 R1 — convert the nine custom painters to Appearance delegation

### Current state (verified 2026-07-26)

Nine widget classes override `paintIntoAreaOrBlitFromBackBuffer` to draw arbitrary
pixels instead of routing through an Appearance. The codebase itself enumerates them —
`Widget.opaqueCoveredRect`'s comment (~:2795): *"nine widget classes override it to
draw arbitrary pixels (HandleWdgt, LayoutChromeWdgt, LabelButtonWdgt, PenWdgt,
CellWdgt, SheetHeaderCellWdgt, AnalogClockWdgt, Example3DPlotWdgt,
GraphsPlotsChartsWdgt)"* — and its prototype-identity check
(`return nil if @paintIntoAreaOrBlitFromBackBuffer isnt Widget::paintIntoAreaOrBlitFromBackBuffer`)
excludes them all from occlusion-culling coverage claims.

Each override repeats the same prologue/epilogue skeleton around a per-class pixel
body (jscpd: HandleWdgt~PenWdgt, AnalogClock~GraphsPlotsCharts, Pen~GraphsPlotsCharts,
LayoutChrome~GraphsPlotsCharts, CellWdgt~SheetHeaderCellWdgt; jsinspect: a 10-way
structural match incl. the Widget base). The canonical shape
(GraphsPlotsChartsWdgt's, ~:31–66):
`preliminaryCheckNothingToDraw` → `calculateKeyValues` → `save` →
`clipToRectangle` → set `globalAlpha` → (some: paint background rect) →
`useLogicalPixelsUntilRestore` → `translate` to `@position()` → **the per-class pixel
body** (`_renderingHelper` / `handleWidgetRenderingHelper` / hands+face drawing / …) →
`restore` → (some: highlight overlay). The prologue PARAMETERS differ per class
(`@backgroundTransparency` vs `@alpha`; with/without background fill; state-dependent
colour choices) — the skeleton is the clone, the parameters are per-class truth.

### Why delegation (and not a mixin or base template-method)

The Appearance object IS this framework's paint-delegation seam — "Pluggable
*Appearance objects do the drawing" (root CLAUDE.md); the base `Appearance` already
carries the factored prologue helpers. A mixin would be a third copy of machinery
`Widget` + `Appearance` already own; a Widget-side template-method would bypass the
appearance system these classes should have used from the start. Bonus: after
conversion the prototype-identity check in `opaqueCoveredRect` passes for these
classes and the decision moves to the appearance-class switch where it belongs (the
outcome stays `nil` for these odd-shaped/translucent painters — no culling behaviour
change — but the seam is honest again).

### Fix shape (per class — nine small, independent, identically-shaped steps)

For each class C in the enumerated nine:
1. Create `src/<same dir as C>/CAppearance.coffee`-style class (house naming:
   `HandleAppearance`, `AnalogClockAppearance`, … check `src/icons/IconAppearance.coffee`
   and `DragChargingRingAppearance.coffee` for the ctor idiom — appearances hold
   `@widget` and are constructed as `new XAppearance @` where the widget sets
   `@appearance` in its constructor/build).
2. Move C's `paintIntoAreaOrBlitFromBackBuffer` body VERBATIM into the new appearance's
   `paintIntoAreaOrBlitFromBackBuffer`, mechanically rewriting `@foo` widget accesses
   to `@widget.foo` (fields, `position()`, the per-class rendering helpers — which
   move too if they are paint-only; verbatim-diff gate on every moved member). Do NOT
   force the base `_calculateKeyValuesOrNil`/`_beginLogicalPixelsBox` helpers where
   the class's prologue parameters differ — byte-identical pixels outrank helper
   reuse in this tier (helper consolidation is the optional polish step 4).
3. Delete C's override; set `@appearance = new CAppearance @` at C's construction
   (mirroring how e.g. BoxWdgt gets its BoxyAppearance). `fg build` + probe one test
   touching C, then `fg presuite`.
4. OPTIONAL POLISH (only after all nine are green): collapse now-identical
   appearance-side prologues into the base helpers where the diff is exact.
5. Update the `opaqueCoveredRect` comment (the nine-class enumeration disappears;
   BackBufferMixin's blit exclusion remains — reword to match reality).

### Risks / gotchas

- **Pixel identity is the whole game.** SWCanvas + the suite compare byte-exact; the
  verbatim-move discipline plus per-class presuite keeps each step bisectable.
- `calculateKeyValues` today comes from Widget (and BackBufferMixin overrides it for
  its consumers) — when a moved body calls it, `@widget.calculateKeyValues` keeps the
  exact same dispatch. Do not "simplify" to appearance-side helpers in tier 1.
- Some of the nine have state-coupled paint (HandleWdgt's `@state` colours,
  LabelButtonWdgt's flat fill); the appearance reads them via `@widget.state` — fine.
- CellWdgt/SheetHeaderCellWdgt sit in the spreadsheet hot path — after those two, run
  the serialization gauntlet leg's rigs implicitly via the full gauntlet at close.
- The `fg census`/arrange-idempotence and paint-audit legs both run in the gauntlet —
  they are the designed safety net for exactly this refactor.

## §2 R2 — a shared base class for the code-runner widgets

### Current state (verified 2026-07-26)

Four (plus one marginal) classes, ALL `extends Widget` directly, hand-roll the same
"code/text area + bottom action buttons" widget: `meta/ConsoleWdgt` ("dev → console",
run-selection/run-all → `doAll` with `@` = target), `ScriptWdgt` (a script on the
desktop; `doAll` → `world.evaluateString @textWidget.text`), `CodePromptWdgt` (the
code-entry popup; `@target[@callback]` commit), `ErrorsLogViewerWdgt` (the error log;
same ctor signature as CodePromptWdgt `(@msg, @target, @callback, @defaultContents)`).
`SimpleLinkWdgt` shares one small fragment (jsinspect 5×, ~3 lines) — check it, likely
leave it out.

Verified clone set (jscpd/jsinspect): the code-area build block (repeated verbatim in
at least three — `@textWidget = @tempPromptEntryField.textWdgt;
@textWidget.backgroundColor = Color.TRANSPARENT;
@textWidget._setFontNameNoSettle nil, nil, @textWidget.monoFontStack;
@textWidget.isEditable = true; @textWidget.enableSelecting()`), the `_reLayout`
(ConsoleWdgt ~:77–102 ≡ ScriptWdgt ~:138–163: apply-own-bounds-first comment block,
`world.disableTrackChanges()`, text-area + button-row geometry), the
CodePromptWdgt~ErrorsLogViewerWdgt constructor pair, and the commit plumbing
(`@target[@callback].call @target, nil, @textWidget`).

### Why a base class (not a mixin, not a collaborator)

They are the same KIND of widget — same fields (`textWidget`,
`tempPromptEntryField`), same layout, same lifecycle — differing only in what "run"
does and what chrome surrounds it. Same-kind + same-branch (`extends Widget`) is
BASE-CLASS territory (the fold arc's `IconicDesktopSystemPanelWdgt` precedent);
a mixin is for unrelated branches, a collaborator for delegable responsibility —
neither fits a widget's own build/layout/fields.

### Fix shape

1. New `src/CodeAreaWdgt.coffee` (name is a suggestion — owner may rename at review)
   `extends Widget`, carrying ONLY the byte-identical members after a verbatim diff
   across all four: the field declarations, the code-area build block (as a private
   `_buildCodeArea`-style NoSettle helper if the surrounding ctors differ), the shared
   `_reLayout`, and the commit plumbing where identical. Anything that differs stays
   in the subclass (e.g. ScriptWdgt's `@savedScript` serialization dance,
   ConsoleWdgt's target binding).
2. Re-parent the four classes to it; delete the folded members from each.
3. Gates: the tiernaming/settle legs care about `_reLayout` shape — the moved
   `_reLayout` keeps its apply-own-bounds-first structure verbatim (it encodes the
   inspector-doLayout-lag case law; the comment moves with it).
4. Serialization: class renames are NOT happening (no `*Wdgt` name changes) and the
   new base adds no instance state — snapshot compatibility is a non-concern (standing
   owner policy: none owed anyway).
5. Inspector churn: a new base class shifts the four classes' member lists from own to
   inherited — the inspector HIDES inherited by default; no SystemTest drives these
   classes' inspectors (re-verify with a grep over `../Fizzygum-tests/tests/` before
   trusting this).

## §3 R3 — three small helper extractions

Small, independent; do them in one sitting. For each: move the computation to the
named home, point both former copies at it, verbatim-preserving behaviour.

1. **Largest-centered-square geometry** — `icons/GenericShortcutIconWdgt.coffee`
   ~:34–57 ≡ `patch-programming/FanoutWdgt.coffee` ~:77–100 (compute the biggest
   square centred in my bounds, `_applyBounds` a child icon into it, under
   `world.disableTrackChanges()`). Home: the geometry part
   (`min(w,h)` square centred in a rectangle) belongs on `Rectangle`
   (`src/basic-data-structures/Rectangle.coffee`) as a pure query — e.g.
   `largestCenteredSquare()` returning a Rectangle; each class's layout keeps its own
   2-line apply. Pure function, no widget knowledge — NOT a Widget method (Widget is
   being shrunk by standing doctrine).
2. **Wheel-delta normalization** — `basic-widgets/ScrollPanelWdgt.coffee` ~:793–806 ≡
   `spreadsheet/SimpleSpreadsheetWdgt.coffee` ~:515–523 (dominant-axis squelch + the
   `WorldWdgt.preferencesAndSettings.invertWheelX/Y` flips). Home: a method ON the
   preferences object (it reads its own fields) — e.g.
   `PreferencesAndSettings.normalizedWheelDeltas(x, y)` returning the adjusted pair;
   both wheel handlers call it. (Find the class file via
   `grep -rn "class PreferencesAndSettings" src`.)
3. **Pixel-alpha hit test** — `basic-widgets/SimpleImageWdgt.coffee`
   `isTransparentAt` ≡ `video-player/VideoPlayerCanvasWdgt.coffee` `isTransparentAt`
   (jsinspect exact pair: map the point to local raster coords, read a 1×1 pixel,
   answer by alpha). Two consumers, ~15 lines: extract the shared body into a small
   helper both call with their raster source — OR, if the diff shows a real source-
   type asymmetry that makes the helper awkward, LEAVE both with a cross-reference
   comment naming the twin (an accepted outcome for this item; record which way it
   went in the close-out).

## §4 Documents to update

- R1: the `Widget.opaqueCoveredRect` comment (§1 step 5); root `Fizzygum/CLAUDE.md`
  needs no change (the Appearance statement becomes MORE true); if
  `docs/architecture/` has a rendering doc section naming the nine custom painters,
  grep for `paintIntoAreaOrBlitFromBackBuffer` under `docs/` and update what names
  them.
- R2: none beyond in-file comments (the new base gets a header comment stating the
  family contract).
- R3: in-file comments at the new helper homes.
- At arc close (per tier or all together): `git mv` this plan → `docs/archive/` with
  the EXECUTED stamp + `docs/archive/INDEX.md` line (⚖ any falsifications met on the
  way); memory topic + MEMORY.md index.

## §5 Verification protocol

Same as §0.5: per step `fg build` + `fg presuite` (backgrounded, verdict files);
`fg gauntlet` at each tier's close; zero churn expected everywhere; `fg diffpage`
before believing any diff benign; `fg recapture <names>` only for verified-benign.
R1 additionally leans on the gauntlet's paint-audit + census legs. If any moved-paint
step fails pixel-identity and the diff is not an obvious transcription slip, STOP that
class (revert, mark it in the plan) rather than chasing — per-class independence means
one stubborn class doesn't block the other eight.

## §6 Rejected alternatives (do not re-attempt)

- **A "CustomPainterMixin"** for R1 — third copy of machinery Widget + Appearance
  already own; rejected at the 2026-07-26 audit.
- **A Widget-side template-method** (`paintIntoAreaOrBlitFromBackBuffer` calling an
  overridable `_paintSelf`) — bypasses the Appearance seam the framework standardized
  on; rejected same audit.
- **Forcing base-helper reuse during the R1 verbatim moves** — the per-class prologue
  parameters genuinely differ; helper consolidation is the explicitly-optional polish
  AFTER pixel-green, never during the move.
- **A mixin for R2** — same-kind widgets on the same branch; base class per the fold
  precedent.
- **Putting R3's geometry/wheel helpers on Widget** — Widget is under a standing
  shrink mandate; the computations have non-Widget homes (Rectangle, the prefs
  object).

## §7 References

- Sibling plan: `docs/archive/mixin-application-tidyups-plan.md` (findings 1–3; run it
  first — it touches StretchableWidgetContainerWdgt and the mixins doc too).
- `duplication-report/*.ai.txt` (regenerate with `./find_duplicated_code.sh`,
  `./find_similar_code.sh`) — the raw clone evidence.
- `../Fizzygum-tests/DETERMINISM.md` — mandatory reading before R1.
- `docs/archive/mixin-fold-*`/`docs/archive/mixin-editing-v2-plan.md` INDEX entries —
  the verbatim-fold discipline this plan reuses.
- Root `CLAUDE.md` — `fg` wrapper, long-op discipline, cwd traps.
