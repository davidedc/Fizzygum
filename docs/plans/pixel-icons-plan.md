# Pixel icons — replace vector IconAppearance files with ASCII index-mask bitmaps

**Status**: two tracks. The BITMAP (ASCII index-mask) track: PLAN ONLY — AUTHORED
2026-07-18, phases P0–P6 NOT STARTED, gated on the §5 owner re-judge. The SIZE-AWARE
vector track (§5b): **LIVE and rolling** — 7 icons landed (Typewriter, Folder,
ShortcutArrow, the hybrid Toolbars/super-toolbar, GenericPanel, PatchProgramming,
SimpleSlide) + the `SizeAwareIconAppearance` base (now incl. the reusable `_pxPanel`
rounded panel and the family `_pxSlideCard`); further conversions proceed one icon at a time via the local skill
`/convert-icon-size-aware` and append lessons to §5b without touching this plan's
phases. Written to be executed COLD by an LLM/engineer with ZERO prior context — everything needed is embedded here or one named-doc hop
away. Every `file:line` was verified against source on 2026-07-18; **line numbers drift — the
method name / quoted code is authoritative; grep it fresh before trusting a line number.**

**Mandate**: complete transformation of the icon subsystem's underlying problem, not mitigation.
The vector `paintFunction` icon files are eliminated for every icon that can carry the pixel
look; the few that legitimately cannot are explicitly enumerated and stay vector by decision,
not by inertia.

**Owner decisions already locked (2026-07-17/18 brainstorm session)** — do NOT re-litigate:
- **(a) Index-mask format**: pixel data stores palette *indices* (body / outline / literal),
  resolved to colors at paint time. Never baked RGBA.
- **(b) Mac-style resolution set — three supported sizes, per-icon subset (owner refined
  2026-07-18)**: the format and rasterizer treat 48×48, 32×32 and 16×16 uniformly; each icon
  **declares the subset its real usage needs** — shipping all three is NOT mandated (cohort
  guidance in §5). The rasterizer picks by the **coverage rule** in §4.3 — NOT naive
  largest-that-fits (see the ⚠ there: largest-fits would make icons *shrink* in 64–95 px
  boxes, including retina toolbars).
- **(c) In-system pixel-icon editor: OUT OF SCOPE** (banked for a later arc, see §6 P6).
- Icons that stay vector: at minimum the two big maps (`SimpleUSAMapIconAppearance`,
  `SimpleWorldMapIconAppearance`) — owner-mandated. Full disposition in §5.

---

## §0 Orientation

**Fizzygum** is a CoffeeScript GUI framework ("web operating system") rendered on a single
HTML5 `<canvas>`. No module system: every class is a global, one class per file, filename =
class name, load order auto-discovered by regex-scanning source text. The umbrella workspace
holds three sibling repos: `Fizzygum/` (source — the only place behavior is edited),
`Fizzygum-tests/` (196 screenshot-diff SystemTests + headless harness), `Fizzygum-builds/`
(generated output; never hand-edit). Root `CLAUDE.md` + each repo's `CLAUDE.md` are the
operating manual — read them before running anything. Build/test via the `fg` wrapper invoked
as `/Users/davidedellacasa/code/Fizzygum-all/fg …` (absolute path, never `./fg`).

**Why this plan exists.** Icons are one of the largest code masses in the framework: 91
`*IconAppearance.coffee` files, **10,200 lines** (counted 2026-07-18), each a `paintFunction`
that replays a long list of canvas vector commands (`moveTo`/`bezierCurveTo`/`fill`) exported
from a separate macOS drawing app. Three problems, stated by the owner:
1. **They are large** (the two maps alone are 3,154 lines; `TypewriterIconAppearance` 221, etc.).
2. **They are fundamentally hard to edit** — authoring requires the external Mac app; the
   coordinate soup is opaque to hand-editing.
3. **They render badly under SWCanvas** — the software backend has no anti-aliasing, so thin
   strokes and fine detail degrade. SWCanvas is the test-suite backend and the owner's
   day-to-day backend (`?sw=1` — see memory/architecture note "prod NATIVE, owner runs ?sw=1").

**The critical reframe** (don't bury this): the fix is not "bitmaps as a fallback for vector".
The **chunky-pixel look is the feature**. Icons become small integer grids of palette indices,
drawn as k×k integer device-pixel squares. Axis-aligned integer rects with no AA are exactly
what SWCanvas renders perfectly — the SWCanvas problem disappears *by construction*, not by
tuning. Editability is solved by the storage format (ASCII art in the source file). Size is
solved for the worst offenders (busy 100–300-line icons → ~60-line files).

**A second reframe that shapes the whole design**: today's icons are **tinted masks, not
pictures**. They fill from `@widget.color` / `ownColorInsteadOfWidgetColor` and a theme-level
outline color at paint time (verified: 32 button `createAppearance` sites pass
`WorldWdgt.preferencesAndSettings.iconDarkLineColor` as the appearance's second ctor arg; the
hover-"stain" mechanism described in `Appearance.coffee`'s `ownColorInsteadOfWidgetColor`
comment depends on this). Any format that bakes colors in breaks recoloring. Hence index-mask.

## §0.5 Cold-execution protocol

A fresh session executes this plan as follows:

1. Read root `CLAUDE.md` + `Fizzygum/CLAUDE.md` + `Fizzygum-tests/CLAUDE.md` (commands, shell
   discipline, long-op rules). Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` to
   orient (repo shas, build freshness, leftover browsers).
2. Re-verify §1's load-bearing facts against current source (grep the method names; if any
   have drifted materially, update this doc before executing — plans stay truthful).
3. Execute phases **P0 → P5 in order** (§6). Each phase ends with its named gate. Two gates
   are **OWNER gates** (marked ⛔): P0's aesthetic sign-off and P4's mass-recapture approval.
   Do not proceed past an owner gate without an explicit owner answer in the conversation.
4. Verification tiers: while iterating use targeted checks (boot-smoke, single tests, the
   contact sheet); the full suite is *expected red* mid-arc after conversions and only returns
   green after the P4 recapture. Close the arc with a full `fg gauntlet` (§9).
5. **Never** commit/push autonomously (owner preference, standing): at the end, present a
   summary + proposed commit message(s) and wait. One end-of-arc review, not per-batch reviews.
6. Long ops (`fg gauntlet`, suite runs, mass recapture): launch ONCE in background with output
   redirected to a log; wait for the task notification; peek only via
   `cat /tmp/fg-<cmd>.verdict` or `tail -5` the log. Never foreground-poll, never pipe the fg
   call through a filter. Never edit `src/` while a suite/capture run is in flight.
7. Ad-hoc Node probes (puppeteer/pngjs) go under `Fizzygum-tests/.scratch/` (gitignored) —
   Node resolves `require()` from the script's directory; a probe elsewhere dies with
   MODULE_NOT_FOUND.

**Ready-to-paste start prompt for a fresh session:**
> Read `Fizzygum/docs/plans/pixel-icons-plan.md` and execute it cold, starting at §0.5 step 1.
> Do the §0.5-step-2 fact re-verification, then run Phase P0 (spike + evidence) and stop at
> the ⛔ P0 owner gate with the contact sheet and byte-identity evidence ready for my review.

## §1 Current architecture and exact state (verified 2026-07-18)

### The class chain

- `Appearance` (`src/basic-widgets/Appearance.coffee`) — base of all appearances.
  `constructor: (@widget, @ownColorInsteadOfWidgetColor) ->`. Provides
  `_calculateKeyValuesOrNil(aContext, clippingRectangle)` → `[area,sl,st,al,at,w,h]` or `nil`
  (nothing to draw). Comment on `ownColorInsteadOfWidgetColor` explains the button-glass
  "stain" mechanism — icons on hover-tinted glass keep their own color.
- `IconAppearance` (`src/icons/IconAppearance.coffee`, 337 lines) — the vector icon engine:
  - `preferredSize` / `specificationSize` (class-level `Point`s, typically 200×200 or
    100×100): the design space the `paintFunction` draws in.
  - `calculateRectangleOfIcon()` — aspect-fits `preferredSize` into the widget's bounds
    (logical px), centers, `.round()`s. Used by paint AND by layout (below).
  - `paintIntoAreaOrBlitFromBackBuffer(aContext, clippingRectangle, appliedShadow)` — clips
    to the dirty rect, sets `globalAlpha` from shadow × `@widget.alpha`, calls
    `useLogicalPixelsUntilRestore()`, translates/scales design space → widget box, calls
    `@paintFunction aContext`.
  - `_iconColorString()` → `(@ownColorInsteadOfWidgetColor ? @widget.color).toString()`;
    `_outlineColorString()` → `WorldWdgt.preferencesAndSettings.outlineColorString`
    (`PreferencesAndSettings.coffee:41,136`).
  - Path helpers `oval`/`circle`/`arc` + shared frame primitives (`_paintSlideOutline`,
    `_paintSlideCard`, `_paintWindowTitleDots`, `_paintWindowFrame`,
    `_paintRoundedSquareBadge`, `_paintPlotAxes`, `_paintPaletteSwatch`, `_paintButtonRing`)
    — code-motion consolidation from a 2026-07 duplication arc. ⚠ **`_paintRoundedSquareBadge`
    is used by the FanoutPin appearance too — a NON-icon appearance** (per the comment on the
    method). Helper cleanup must check all users, not just `icons/`.
- 90 subclasses: 89 under `src/icons/` + 2 under `src/maps/` (91 files total including the
  base; 10,200 lines total).

### The widget side

- `IconWdgt` (`src/IconWdgt.coffee`) — `constructor: (@color = WorldWdgt.preferencesAndSettings.iconDarkLineColor)`;
  `createAppearance: -> new IconAppearance @` — **a method, not a class field, so the build's
  regex dependency-finder sees the `new <X>IconAppearance` edge and orders the appearance
  class before the icon class** (the comment in the file says exactly this — preserve the
  pattern). `widthWithoutSpacing()` and `_resizeToWithoutSpacing()` delegate to the
  appearance's `calculateRectangleOfIcon()` — **the appearance is part of the layout
  contract, not just painting.**
- Every concrete icon has a paired `<X>IconWdgt` whose `createAppearance` news up the
  appearance. Buttons do the same directly: **32 sites** under `src/buttons/` pass
  `WorldWdgt.preferencesAndSettings.iconDarkLineColor` as the second ctor arg
  (= `ownColorInsteadOfWidgetColor`); others pass nothing (tint from `@widget.color`).
- `EditIconButtonWdgt` **swaps appearance instances at runtime** (pencil ↔ eye), so
  appearances must stay cheaply constructible.

### Color usage across the 91 files (the palette requirements)

- All tintable icons fill from `_iconColorString()` (body role).
- **38 files** under `icons/` reference the outline color (outline role).
- **21 appearance files** use fixed colors (named `Color.X` constants or `rgb(...)` literals)
  — e.g. `FizzygumLogoIconAppearance` (RED/WHITE), `HeartIconAppearance`,
  `MapPinIconAppearance`, `CollapsedStateIconAppearance`. → palette must support **literal
  color entries** alongside the two dynamic roles.
- **4 files use gradients**: `ColorPalettePatchProgramming`, `GrayscalePalettePatchProgramming`,
  `VaporwaveSun`, `VaporwaveBackground` (+ the two maps use large filled regions). Gradients
  don't map to a small index palette → stay vector (§5).
- **1 file draws text**: `FizzygumLogoWithTextIconAppearance` (`fillText`) → stays vector.
- `CFDegreesConverterIconAppearance` is a 7-line subclass of `DegreesConverterIconAppearance`
  overriding one fill-style method — the pixel design must support "same grid, different
  palette" subclassing (it does: grids resolve through the prototype chain, §4).

### Device pixels, integer placement, backends

- `Widget.calculateKeyValues` (`src/basic-widgets/Widget.coffee:2551`) returns
  **integer device pixels**: rounds the visible area and multiplies by `ceilPixelRatio`
  (global; 1 or 2). `al,at,w,h` are the dirty-rect blit coords in device px.
- ⚠ **Partial-repaint trap**: `al,at` are the **dirty rect's** corner, NOT the widget's. The
  vector path centers via `calculateRectangleOfIcon()` (absolute widget coords); the pixel
  rasterizer must likewise anchor to the widget's own origin (§4), never to `al,at`.
- Integer-placement policy (`docs/architecture/integer-pixel-placement-and-sizing.md`): every
  widget's applied `@bounds` (position AND extent) are integers in logical px → integer
  device px at dpr 1 and 2. So `@widget.left() * ceilPixelRatio` etc. are exact integers —
  the pixel rasterizer builds on this guarantee. (That doc's Layer C says content rendering
  MAY be fractional; pixel icons deliberately choose integer content anyway.)
- `useLogicalPixelsUntilRestore()` = `@scale ceilPixelRatio, ceilPixelRatio` on both backends
  (`boot/extensions/CanvasRenderingContext2D-extensions.coffee:5`;
  SWCanvas variant ~`boot/extensions/SWCanvasElement-extensions.coffee:164` additionally pins
  the text-atlas density). **The pixel rasterizer does NOT use it** — it draws in raw device px.
- Backends: production/native HTML5 canvas (AA) and SWCanvas (`?sw=1`, no AA, byte-
  deterministic — the whole test suite's reference identity is built on that; see
  `Fizzygum-tests/CLAUDE.md` and `DETERMINISM.md` there).

### Build & tests facts that constrain the work

- Build: `fg build` → `Fizzygum-builds/latest/`. Non-boot classes ship as escaped source
  strings compiled in-browser; the build-time syntax gate fragment-compiles each file. New
  class files are auto-discovered (class-per-file, filename = class name).
- **Homepage exclusion markers**: 20 files under `icons/` (the 10 Wdgt+Appearance pairs:
  ChapterX, ChapterXX, ChapterXXX, FridgeMagnets, Information, RasterPic, Save, Script,
  Trashcan, UnderCarpet) carry the file-level marker comment
  `# this file is excluded from the fizzygum homepage build` (matched byte-verbatim by
  `buildSystem/build.py:54`). **Any rewrite of these files must preserve the marker
  byte-verbatim as its own line.**
- Tests: 196 SystemTests; references are per-backend (native: PNG-string hash; SWCanvas:
  raw-pixel SHA-256) and per-density (dpr 1 and 2); ~1,542 reference images; the WebKit
  gauntlet leg **reuses** the SWCanvas references (no separate baseline). Recapture:
  `fg recapture <name>` (runs the tests repo's `capture-macro-test-references.js <name>
  --clean --dprs=1,2` full flow). `fg diffpage <names...>` builds a ref|now|diff review page.
  `fg classify` output is a reading hint, never permission to recapture.
- Icon rendering changes are **REAL visible changes** → every test whose screenshots show a
  converted icon goes red until recaptured. Mass recapture requires owner approval
  (standing rule). The affected set is discovered empirically in P4, not guessed.

## §2 Why the current shape exists

The icons were authored in a macOS vector-drawing app that exports canvas-command code (the
`#// Oval Drawing`-style comments in many files are export artifacts), pasted into
`paintFunction`s. A normalized design space (`specificationSize`) let one drawing scale to any
widget size — the right call for an AA native canvas, and consistent with Morphic ancestry.
Two things changed since: SWCanvas became the deterministic test/dev backend (no AA → thin
vector detail degrades), and the files became a maintenance burden nobody can edit without the
external app. The duplication arc (2026-07) already consolidated shared fragments into the
base-class `_paint*` helpers — that squeezed the redundancy, but the fundamental format
problem (opaque, uneditable, AA-dependent) is untouched. This plan replaces the format.

## §3 The distilled argument for this fix

1. **One decision kills all three problems.** Integer-grid pixel icons are small (grids of
   chars), hand-editable (ASCII art in the diff), and render crisply on SWCanvas *by
   construction* (axis-aligned integer device rects need no AA).
2. **Index-mask is forced, not chosen.** The tint architecture (`@widget.color`,
   `ownColorInsteadOfWidgetColor` staining, theme outline color) is load-bearing at 32+ call
   sites and in the hover mechanism. Palette indices resolved at paint time preserve it
   exactly; baked RGBA would break it. The 21 fixed-color icons fit via literal palette
   entries.
3. **Cross-backend fidelity is expected to become *identical*, and is at worst unchanged.**
   Suite gating needs only SWCanvas determinism (already guaranteed). Byte-identical
   native≡SWCanvas icon pixels are the *expected* bonus for integer axis-aligned opaque
   fills — P0 must prove or refute this empirically before any claim is written down.
4. **Zero call-site churn.** Concrete appearance class names are kept; only each class's
   *parent* and *body* change. All 90+ `createAppearance` sites, the runtime pencil↔eye swap,
   and the build's load-order edges are untouched.
5. **Honest size accounting** (don't oversell): kept-vector files (§5) total ≈3,800 lines —
   dominated by the two maps (3,154) which stay by owner decision. With per-icon grid
   subsets (§5 cohorts: most icons 2 grids ≈60–70 lines; detailed desktop/app icons 3 grids
   ≈110; tiny-chrome icons 1 grid ≈30), the ~79 converted files land around ≈5,000–5,800
   lines vs ≈6,400 vector lines today — a real but modest net shrink; bytes shrink more
   (grid rows are short and low-entropy vs long float soup). Measure at P5, don't assume.
   Owner problem #1 is decisively solved per-worst-file (221-line opaque Typewriter →
   readable grids), modestly in aggregate; the *material* wins are editability, SWCanvas
   crispness, retina detail (§4.3 dpr note), and per-file simplicity. (A ship-all-three
   mandate was considered 2026-07-18 and dropped by the owner: +50% authoring and ≈+2,700
   lines bought consistency only in the two narrow bands where subsets diverge — the cohort
   guideline in §4.2/§5 captures that at a fraction of the cost.)

## §4 Design — the fix shape

### 4.1 New class: `PixelIconAppearance` (`src/icons/PixelIconAppearance.coffee`)

`class PixelIconAppearance extends IconAppearance`. Extending (rather than siblinging) keeps
the `IconWdgt` layout contract (`calculateRectangleOfIcon` / `widthWithoutSpacing` /
`_resizeToWithoutSpacing`) inherited and working; overrides `preferredSize: new Point 32, 32`
(the natural/layout size in logical px) and `paintIntoAreaOrBlitFromBackBuffer`. The inherited
vector machinery (`paintFunction`, path helpers) is simply never called for pixel subclasses;
pruning it is the banked P6 cleanup, gated on the FanoutPin caveat (§1).

### 4.2 Source format (the ASCII index-mask)

```coffee
class HeartIconAppearance extends PixelIconAppearance

  # optional — this is the base-class default; add chars for literals as needed
  palette:
    '#': 'body'                # (@ownColorInsteadOfWidgetColor ? @widget.color).toString()
    'o': 'outline'             # WorldWdgt.preferencesAndSettings.outlineColorString
    'r': 'rgb(255, 59, 48)'    # any other value = literal fillStyle string

  pixels32: '''
    ................................
    ......oooo........oooo..........
    ....oo####oo....oo####oo........
    <32 rows of exactly 32 chars>
    '''

  pixels16: '''
    <16 rows of exactly 16 chars>
    '''

  pixels48: '''
    <48 rows of exactly 48 chars>
    '''
```

Rules (enforced by a strict parser that **throws** on violation — a malformed icon must fail
loudly at first paint, and the boot-smoke gate will catch anything on the default desktop):
- `.` is transparent, reserved, never in `palette`.
- Every row exactly N chars for `pixelsN`; N ∈ {16, 32, 48} — all three sizes are
  first-class in the format and rasterizer, and an icon declares **any non-empty subset**
  (owner decision 2026-07-18: all three are NOT mandated). Each declared grid is a
  hand-finished redraw at its density — never an auto-resample of another (classic Mac
  practice; the P2 tool drafts all three, P3 keeps what each icon's usage cohort needs).
  `pixels32` is the expected anchor for any icon that appears in general contexts;
  tiny-chrome-only icons (title-bar buttons) may ship 16-only.
- **Cohort-consistency guideline**: icons that share a context (one toolbar, the title-bar
  chrome, the desktop shortcut set) declare the SAME subset. Mixed subsets render different
  footprints side by side, but only in specific bands — 48–63 and 144–159 device px (§4.3)
  — so consistency is enforced per cohort (§5 table), not globally.
- **Charset**: palette chars from `[A-Za-z0-9#*+=@%-]` only. NO space (editors strip trailing
  spaces → row-length corruption), NO backslash, NO backtick, NO `{` (CoffeeScript `'''`
  blocks interpolate `#{…}`; banning `{` makes the `#` body char safe by construction).
- Grids are CoffeeScript block strings: all rows at identical indentation (the common indent
  is stripped by the compiler).
- Subclass-with-different-palette (the CFDegreesConverter pattern): declare only `palette`;
  `pixelsN` resolves through the prototype chain.
- The homepage-exclusion marker line, where present (§1 list), stays byte-verbatim.

### 4.3 The rasterizer (paint-time algorithm)

```coffee
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return nil unless keyValues?
    [area,sl,st,al,at,w,h] = keyValues

    aContext.save()
    aContext.clipToRectangle al,at,w,h    # dirty-rect clip, as the vector path does
    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.alpha
    # deliberately NO useLogicalPixelsUntilRestore(): we draw in integer DEVICE pixels

    # anchor to the WIDGET box, not the dirty rect (partial-repaint trap, §1) —
    # bounds are integer logical px (integer-placement policy) so these are exact ints:
    wl = @widget.left()   * ceilPixelRatio
    wt = @widget.top()    * ceilPixelRatio
    wW = @widget.width()  * ceilPixelRatio
    wH = @widget.height() * ceilPixelRatio

    variant = @_pickVariant wW, wH        # COVERAGE rule — see below; NOT largest-that-fits
    k = Math.max 1, Math.floor(Math.min(wW, wH) / variant.size)
    side = k * variant.size
    ox = wl + Math.floor((wW - side) / 2) # may go negative in the crop case:
    oy = wt + Math.floor((wH - side) / 2) # centered CROP, edges eaten by the clip above

    for run in variant.runs               # precomputed horizontal runs of same-index cells
      aContext.fillStyle = @_resolvePaletteChar run.ch   # cache/skip when unchanged
      aContext.fillRect ox + run.x0 * k, oy + run.y * k, run.len * k, k

    aContext.restore()
    return nil
```

- **Variant selection (`_pickVariant`) — the coverage rule.** Among declared grids with
  `floor(min(wW,wH)/S) >= 1`: drop the 16 whenever the 32 is eligible (the coarsest grid
  exists for small boxes, never as an upscale competitor — otherwise 16@5× "wins" an 80 px
  box over both finer grids); then pick the variant maximizing the rendered side
  `floor(min/S)·S`; break ties toward the **larger S** (more detail at equal coverage). If
  no grid fits at k≥1: smallest declared grid at k=1, centered crop.
  ⚠ **Naive "largest grid that fits" is a trap with three sizes**: it would render 48@k1
  (48 px) in every 64–95 px box where 32@k2 fills 64 px — i.e. adding the 48 asset would
  make icons *shrink* across that whole band, which includes every 32-logical-px toolbar
  button at dpr 2 (a 64-device-px box). The resulting ladder (box = min side, device px):
  | box | picked | rendered side |
  |---|---|---|
  | <16 | 16 @ k1 | 16, centered crop |
  | 16–31 | 16 @ k1 | 16 |
  | 32–47 | 32 @ k1 | 32 |
  | 48–63 | 48 @ k1 | 48 |
  | 64–95 | 32 @ k2 | 64 |
  | 96–127 | 48 @ k2 | 96 (ties 32@k3 → 48 wins on detail) |
  | 128–143 | 32 @ k4 | 128 |
  | ≥144 | continues alternating by the same rule (144→48@k3, 160→32@k5, 192→48@k4 …) |
  The table assumes all three grids declared; the rule operates on whatever subset the icon
  declares (the drop-the-16 clause applies only when a 32 is declared AND fits; the crop
  fallback uses the smallest *declared* grid). Where subsets change the footprint: a 48-less
  icon renders 32 in the 48–63 band and 128 in 144–159 where a 48-bearing icon renders
  48 / 144 — all other bands coincide. That divergence is the concrete reason for §4.2's
  cohort guideline; note 48–63 device px is 24–31 *logical* px at dpr 2, i.e. small retina
  buttons — the most visible cohort.
- **Parsed-grid cache**: parse each `pixelsN` once per class on first paint into row-runs
  (`{y, x0, len, ch}`), stored on `@constructor` (guard with `hasOwnProperty` so a
  palette-only subclass re-parses the inherited string — trivial cost, correct semantics).
  Grids and cache live on prototypes/constructors, not instances → `deepCopy`/serialization
  behavior identical to today's `paintFunction` (no per-instance state added).
- **Leftover padding** after centering the `k·N` square stays transparent — same letterboxing
  the aspect-fit vector path produces today.
- **Crop orientation**: centered (glyph mass centers; owner left center-vs-topleft open in the
  brainstorm — center is chosen here, one line to change if the contact sheet disagrees).
- **dpr note (deliberate)**: `k` is computed in device px. Under the coverage rule dpr 1 and
  dpr 2 usually land on the SAME *logical* footprint (device min doubles ⇒ k doubles: a
  32-logical box picks 32@k1 / 32@k2; a 56-logical box picks 48@k1 / 48@k2). Where they
  diverge, dpr 2 gets the *richer grid*: a 24-logical box shows 16@k1 at dpr 1 but the full
  48@k1 at dpr 2 — retina small buttons get the fine grid. Maximal use of density; per-dpr
  references make it test-safe. Owner reviews this behavior on the P0 contact sheet.
- **Transforms**: under rotated/tilted contexts (TransformFrame islands) the fillRects go
  through the same buffer-transform path as all content; crispness and cross-backend identity
  are only claimed for the axis-aligned case — exactly today's situation for vector icons.
- **Hit-testing/highlight**: no icon overrides `isTransparentAt` today, and `paintHighlight`
  is commented out in the vector path — no pixel-side work needed.

### 4.4 What "settings" means (kept simple, per owner)

No settings object in v1. The only knobs are the per-class declarations (`palette`,
`pixelsN` variants). The brainstormed "spaced circles / dot-matrix at large sizes" is banked
as P6 (a `dotMode` rendering style drawing `(k−1)`-sized or circular marks per cell) — the run
data structure already supports it; do not build it now.

## §5 Disposition — what converts, what stays vector

> **Re-judging input (2026-07-19)**: the vector-icon crispness audit
> (`docs/measurements/vector-icon-crispness-audit-2026-07-19.md`) tiers the fleet by
> measured crispness: its Tier A (fill-only chunky icons — arrows, Pencil, Eye, chrome
> ring family, ~15 more) already renders crisp as vector and may stay so by owner choice;
> its Tier C (wholesale line art, ~20 icons with zero solid pixels at 16 px) are the
> strongest bitmap candidates. The owner intends to re-judge this section's convert list
> against those tiers before P3 — treat the table below as pre-audit.
> **Update 2026-07-21**: a THIRD disposition now exists and is LANDED for one icon —
> size-aware vector redraw (§5b, `TypewriterIconAppearance`). Each icon's re-judge picks
> among: keep-vector / pixel-grid (this plan) / size-aware redraw (§5b).

**Stays vector (11 files, ≈3,800 lines)** — each for a stated reason, finalized on the P4
contact sheet:
| File | Reason |
|---|---|
| `maps/SimpleUSAMapIconAppearance` (2316) | owner-mandated keep |
| `maps/SimpleWorldMapIconAppearance` (838) | owner-mandated keep |
| `icons/IconAppearance` (337) | stays as the vector base + `PixelIconAppearance`'s parent |
| 4 gradient icons (§1 list, ≈103 total) | gradients don't fit a small index palette |
| `icons/FizzygumLogoWithTextIconAppearance` (179) | `fillText` typography |
| `icons/FizzygumLogoIconAppearance` (166) | brand mark; owner decides on contact sheet (a 32×32 red/white/outline pixel logo may be charming — offer both) |
| `icons/LittleUSAIconAppearance` (51), `icons/LittleWorldIconAppearance` (79) | tiny map glyphs; owner decides on contact sheet |

**Converts: everything else — ~79 appearance files.** The paired `*IconWdgt` files are NOT
touched (class names and `createAppearance` bodies unchanged). Regenerate the worklist cold:
`ls src/icons/*IconAppearance.coffee src/maps/*IconAppearance.coffee` minus the table above.

**Grid-subset cohorts** (initial guidance; P3 finalizes a per-icon table with all drafts in
hand — same-context icons MUST share a subset, §4.2):
| Cohort | Declared grids |
|---|---|
| Title-bar / tiny chrome (Close, Collapse, Uncollapse, CollapsedState, UncollapsedState, …) | `pixels16` (+`pixels32` if also used large) |
| Toolbar & creator-button glyphs, format buttons (Bold/Italic/Align*/font-size), all arrows | `pixels32` + `pixels16` — no 48 (simple glyphs gain nothing at 48; these render small) |
| Desktop / app / document icons (Typewriter, Basement, Welcome, Folder, Trashcan, shortcut badges, …) | `pixels48` + `pixels32` (+`pixels16` where they also appear in small chrome) |

## §5b Size-aware vector icons — a PROVEN third path (typewriter, landed 2026-07-21)

`TypewriterIconAppearance` was converted from its 221-line fixed-100-space vector drawing
to a **size-aware icon**: it overrides `paintIntoAreaOrBlitFromBackBuffer`, skips
`useLogicalPixelsUntilRestore`, and computes integer DEVICE-pixel geometry from its actual
size (one line-unit `t = round(S/32)`; detail tiers computed from the budget). Owner-approved
through ~8 review iterations; the conversion process is packaged as the local skill
`/convert-icon-size-aware` (umbrella `.claude/skills/`, uncommitted workspace tooling — the
in-repo record is this section + the reference implementation itself).

**The objective, stated precisely (owner, 2026-07-21)**: make the NON-AA backend's render
look good at every size — no ragged/uneven strokes, no dropouts — by having the icon use
its space intelligently and align integer-width strokes to the grid per size; the same
discipline also makes the HTML5-canvas (AA) render neater. It is NOT about making the two
backends render identically, and NOT about "correcting" native AA — AA is not a defect,
just AA. Cross-backend byte-identity falls out as a side effect and is kept purely as a
cheap verification invariant.

**Lessons learned (each verified empirically on the typewriter):**

1. **Cross-backend byte-identity falls out for free** with integer axis-aligned fillRects
   (verified at {16,24,32,48,64,95,128}px × dpr{1,2} after every iteration) and makes an
   excellent cheap regression gate — a DIFFER means something non-integer was drawn. A
   side effect, not the objective (see the statement above). It also pre-validates this
   plan's P0 expectation (§3.3) — the P0 spike can cite it.
2. **Anchor to the widget origin, never the dirty rect** (`al/at` shift under partial
   repaints); widget bounds are integer logical px (placement policy) so
   `left()*ceilPixelRatio` is an exact device integer.
3. **The border idiom**: paint each region as a solid-ink silhouette, then repaint its
   interior in the light color inset by `t` — borders can never thin below `t`. On a
   staircase flank the interior must additionally **lag one band behind** the ink; on a
   column-stepped arc each dark run must **extend to its deeper neighbour's top** or steep
   sections dash.
4. **Curves are fine in pixel-land**: column-stepped ellipses (slot mouth), row-span discs
   (round keys), stadium = disc rows + straight middle. `Math.sqrt` is IEEE-exact →
   engine-independent; avoid other transcendentals in paint code.
5. **The halo envelope is per-region and must be SPLIT around foreground shapes.** Two of
   the three bugs the owner's eye caught were halo-layering: a full-width rim overpainting
   the page's dark edges ("floating page", only at the sizes taking one branch), and a
   region (the flare bands) shipping with NO halo pass at all. Every silhouette-shaped
   region needs its own explicit envelope, and rims crossing a foreground shape must split
   around it.
6. **Detail must adapt by rule, not by cap**: the document-line count comes from a
   clearance rule (`floor((avail − t − gap)/pitch) + 1`, min chassis clearance = inter-line
   gap, 0 when nothing fits) — whole-pitch division wasted up to a full line. Keys go
   disc-ring → dot on `k − 2t ≥ 2`; mouth/knob-hollow/flare gate on their own minima;
   crowding at small sizes is a taste rule (one fewer key below 48px).
7. **dpr 2 is free**: same-device-budget renders are byte-identical (16px@dpr2 ≡ 32px@dpr1),
   so retina automatically gets the richer detail tier.
8. **The probe must drive the REAL paint override**, not `paintFunction` (a stub widget +
   borrowed `Widget.prototype.calculateKeyValues` + `window.ceilPixelRatio` set per dpr) —
   an audit-style probe that replays the transform chain bypasses everything size-aware.
9. **The iterative loop is the actual method**: render a size ladder on both backends,
   6× nearest-neighbor PNG dumps, side-by-side old-vs-new HTML opened for the owner,
   byte-identity gate re-run after EVERY change, owner feedback per round. Metrics found
   the fleet's problems (audit); the owner's eye found every per-icon defect.
10. **Close with a golden-master refactor**: render before, restructure (named painters
    over a metrics object, proportions as named constants), render after, byte-compare all
    18 images. The typewriter's cleanup changed zero pixels.
11. **Never let a derived band be a remainder thinner than its stroke.** The base of the
    flare staircase was computed as `deckH − inset·stepH`; at sizes where that landed
    below the line unit, the band was too short for its interior repaint and rendered
    solid — the bottom edge's thickness flickered erratically with size (owner-caught).
    Reserve minima explicitly (clamp the step height so the base keeps ≥ 2 units) and
    verify with a **parameter sweep across EVERY size** (a 117-size bottom-edge scan),
    not just the ladder — size-dependent defects hide between ladder rungs.
12. **Visual hierarchy may need more than one line unit.** A single `t` made every element
    equally heavy; the owner iterated to: `t = round(S/32)` for paper/lines/chassis/knobs,
    lighter `tc = round(S/45)` for the KEYS only (a chassis-also-light variant was tried
    and reverted). Same idiom, two weights — and the weights are one-line taste knobs.
13. **Halo extensions must be clamped to what the neighbouring INK will cover.** The
    staircase halo's up-extension (lesson 5) was a fixed `o`; once the second line unit
    made flare steps shorter than `o`, the extension rose past the deck top and punched
    light through the CARRIAGE's side borders — carriage visibly disconnected from the
    base, but only at the sizes where `stepH < o` (owner-caught; confirmed by a
    connectivity sweep: 15 of 117 sizes failed a carriage→base ink flood-fill, 0 after
    clamping `upExt = min(o, heightOfBandAbove)`). Corollary of lessons 5 + 11: every
    derived overpaint amount needs an explicit bound, and sweeps should assert
    STRUCTURE (connectivity), not just measurements.

**Impact on this plan**: the audit's Tier B (solid base + thin details) now has a concrete
non-bitmap remedy with a landed reference implementation; the §5 re-judge is a three-way
choice per icon. The shared drawing vocabulary (`_pxBorder`, `_pxDiscRows`/`_pxDisc`/
`_pxStadium`, the metrics-object pattern) is a candidate to extract into a
`SizeAwareIconAppearance` base once a second icon converts — do the extraction THEN, not
speculatively.

**2nd + 3rd conversions LANDED (2026-07-21, same day)**: `FolderIconAppearance` (uniform
`t` borders — the old fractional line-work rounded differently per edge under non-AA —
swept: five measured lines = t at every size 14–130) and `ShortcutArrowIconAppearance`
(rounded-badge ring 2t + the alias swoosh: scanline head, angle-parameterized stamped tail
tapering to a 1px point; at ≤24px an exact 45° right-triangle head with a straight
perpendicular shaft joining the hypotenuse's midpoint, clearance-clamped off the ring).
The planned base-class extraction happened on schedule: **`SizeAwareIconAppearance`** now
owns the paint-entry boilerplate + the `_px*` vocabulary (incl. new `_pxRoundRect`
row-span round-rect); the typewriter was slimmed onto it, golden-master byte-verified.
New lessons: (14) **per-COLUMN sampling of a curve degenerates at small sizes** (few
columns → flat "curl" feet); parameterize by angle/arc-length and stamp instead. (15) At
small sizes prefer **axis-aligned and exact-45° geometry** — free angles read as messy
jaggies; equal-leg triangles step exactly 1px/row. (16) **Clearance is a spec, not an
accident**: clamp glyph extents to keep ≥1px of light from surrounding frames; touching
reads as a defect.

**The verification kit that closed the arc** (adaptable per icon; typewriter versions under
`Fizzygum-tests/.scratch/icon-crispness/`, templates in the `/convert-icon-size-aware`
skill): (a) ladder byte-identity native≡SWCanvas at 9 size/dpr configs after EVERY edit;
(b) a 14–130px bottom-edge-thickness sweep (measurement invariant); (c) a 14–130px
carriage→base ink flood-fill sweep (structural invariant). Final shipped constants:
`t = round(S/32)`, `tc(keys) = round(S/45)`, `CHASSIS_MARGIN 0.05`/side. References
recaptured via `scripts/recapture.js --auto --dprs=1,2` (2 tests:
`macroDesktopShortcutIcons`, `macroSavedDocumentShortcutIcon`).

**4th conversion LANDED (2026-07-21) — the first HYBRID**: `ToolbarsIconAppearance`
(the super-toolbar: flexing arms + cape + a stacked toolbar column). Owner-directed
split: the cape and arms KEEP the original fractional bezier artwork (big fills and
thick strokes render fine under non-AA), while the toolbar column — 1px-in-design-space
strokes that scale to ~half a device pixel at the real display sizes (launcher 60px,
info-doc 85px) and drop out or dash under SWCanvas — is redrawn in integer device
pixels: border `t`, dividers/rings/header-line on the lighter `tc`, gray header band
with white title line, the design's 5 compartments reduced by clearance rule, tool-box
squares tiering hollow-ring → dot → nothing. New lessons:

17. **Hybrid conversions are a legitimate shape.** When part of an icon is already
    non-AA-friendly (big fills, thick strokes), keep that part as fractional bezier
    artwork inside `_paintSizeAware` (translate + scale to the design space) and redraw
    ONLY the sub-pixel line work as integer pixels. Two rules make it sound: every KEPT
    stroke gets clamped to at least one device pixel
    (`ctx.lineWidth = Math.max designWidth, 1 / sc`), and the byte-identity gate scopes
    to the integer-painted region — the region's own halo fill overpaints any bezier
    spill, so the column rect `[xL−o, yT−o, Wc+2o, H+2o]` stays byte-identical
    native≡SW while the whole image diverges (by design, and that's fine: identity is
    the verification gate, not the objective).
18. **Dump the OLD ladder BEFORE the first build of the new class.** The probe renders
    the BUILD, not src — build first and the old renders are gone (recovery costs two
    extra builds: park the new file, `git checkout --` the old one, rebuild, dump,
    restore, rebuild).

**5th conversion LANDED (2026-07-21)**: `GenericPanelIconAppearance` — the rounded
slide-card panel + two floating mini toolbars. The panel ships as the base's reusable
**`_pxPanel`** (halo + ink + interior round-rects, corner radius tracking each inset →
all four corners identical by construction, fixing the old uneven bezier corners);
`ShortcutArrowIconAppearance`'s badge was refactored onto it, golden-master verified
(all 120 renders of the 4 prior icons byte-identical). The same primitive is the
landing zone for SimpleSlide / Dashboards / PatchProgramming (the
`_paintSlideOutline`/`_paintSlideCard` family). The mini toolbars are LOCAL (owner:
thinner/smaller than the super-toolbar's column, not worth sharing) and introduced a
third line unit `td = round(S/64)` for the tool-box rings. New lessons:

**6th conversion LANDED (2026-07-21)**: `PatchProgrammingIconAppearance` — the family
slide card + the patch motif (quantized ring node, border-idiom square node, a `t`
wire meeting each node's outer wall exactly; the old wire crossed INTO both nodes).
The card geometry hoisted into the base as **`_pxSlideCard`** (fractions + radius +
`_pxPanel`, returns the ink rect); GenericPanel refactored onto it, golden-master
verified (150 renders byte-identical). New lessons: (21) **a 1px-wall quantized ring
4-disconnects into arcs below k = 6** (and steps diagonally at every size) — hollow
circles gate on `k − 2t ≥ 2 AND k ≥ 6`, and structural flood-fill sweeps must be
**8-connected** for curved ink (the wire still meets nodes 4-connectedly; a real gap
still fails). (22) **Nodes/content need explicit clearance clamps against the card
ring** — rounding parks content ON the border at some sizes (the 17px circle), the
same bug class as the toolbar backings; the sweep guards it via a
border-contamination check on the flood.

**7th conversion LANDED (2026-07-21)**: `SimpleSlideIconAppearance` (SlidesMaker) —
the family slide card + slide content on `tc`: two text columns whose rows are
computed ONCE and dropped as a unit (min-pitch rule), keeping cross-column alignment;
and a rising 3-bar chart on one baseline. New lesson: (23) **degrade an identity
feature by dropping members, never by flattening** — the card-top clamp at tiny sizes
squeezed all three bars to equal heights (the sweep's own strictly-rising invariant
caught it); heights now derive right-to-left with strict decrease and a bar that
can't stay ≥1 tall and strictly shorter DROPS, survivors compacting left. Corollary
of lessons 19/20; the "rise" is to a chart what the 4-vs-3 asymmetry is to the
toolbars. Sweep = `scan-simpleslide.js` (rows exact-`tc` and aligned, bars rising on
one baseline, interior-clearance guard rows/cols, whole-image byte gate).

19. **Sibling elements need shared metrics and explicit separation.** The two toolbars
    read as one family only when they paint at ONE column width (a pre-pass takes the
    MIN of their shrink-fits — this also killed a hollow-vs-dot style mismatch), and
    at tiny sizes clamp cascades squeeze siblings into each other: thread each
    element's painted extent to the next one's clearance clamp (paint-order
    dependency), and prefer keeping the design's element COUNT by shrinking width
    before dropping members (the 4-vs-3 box asymmetry is design).
20. **Clamps come in hard and soft tiers, and every owner complaint becomes a
    standing sweep assertion.** Soft clearances (the extra `o` before a border, the
    2o visual gap) may give at degenerate sizes; hard ones (border ink, a sibling's
    ink, the corner-arc region `px + r` when punching an edge) never — drop the
    element instead of painting an overlap. Each review note this arc (right-border
    gap, equal widths, corner-arc clearance, white-title-line clearance) is now a
    sweep invariant, incl. a global "no pure-white pixel 4-adjacent to ink" check
    (valid because the light color is 244,243,244 — pure white exists only in title
    lines). The white-line clearance fix was back-ported to the already-landed
    Toolbars icon, which shared the flaw.

## §6 Phases

### P0 — Spike + evidence + ⛔ owner aesthetic gate (small, cheap, decisive)

1. Implement minimal `PixelIconAppearance` (§4.1–4.3) — INCLUDING the full coverage-rule
   variant selection (it is ~15 lines and the P0 probe exercises one size per ladder band;
   what may wait for P1: fillStyle-change elision, literal-palette polish).
2. Hand-convert **one** icon: `HeartIconAppearance` (54 lines, simple silhouette, uses a
   literal color → exercises body + literal palette entries). Author all three grids
   (`pixels48` / `pixels32` / `pixels16`) by eye.
3. Build (`fg build`), then evidence probes (puppeteer scripts under
   `Fizzygum-tests/.scratch/pixel-icon-spike/`):
   - **Byte-identity probe**: render a `HeartIconWdgt` at widget sizes
     {12, 16, 20, 32, 33, 48, 56, 64, 96, 128} logical px — one size per §4.3 ladder band,
     incl. crop (12) and tie (96) cases — native vs `?sw=1`, at `?dpr=1` and `?dpr=2`;
     compare `getImageData` bytes over the widget rect. Record equal/not-equal per cell.
     Byte-identity is *expected*; if refuted, document the divergence — the arc still stands
     on SWCanvas determinism alone (§3.3), but claims in docs must match the evidence.
   - **Contact sheet**: a generated static HTML showing vector-vs-pixel at those sizes/dprs,
     both tint colors (dark-on-light and a colored tint) — the owner's look-and-feel
     evidence.
4. ⛔ **OWNER GATE — aesthetic sign-off**: present contact sheet + identity results. Owner
   approves the pixel style direction (and the dpr-2 sizing behavior, §4.3) or the arc stops
   here. Revert the spike cleanly if rejected.

### P1 — Infrastructure hardening

Coverage-rule selection hardened over arbitrary declared subsets (including 16-only and
48-less icons), centered-crop fallback, literal palette entries, strict parser + per-class
run cache, fillStyle-change elision. Gate: `fg build` green
(syntax gate) + `./build_and_smoke.sh` (both backends boot clean; the default desktop paints
the spike icon) + `fg test <one icon-free test>` still green (harness sanity).

### P2 — Authoring tool (the migration force-multiplier)

`Fizzygum-tests/scripts/rasterize-vector-icons.js` (committed — it remains the icon-authoring
pipeline until the future in-system editor): puppeteer, loads the built world, and per target
class:
1. Instantiate the appearance with a stub widget whose `color` is sentinel red
   `rgb(255,0,0)`; monkey-patch the instance's `_outlineColorString` to sentinel green
   `rgb(0,255,0)`.
2. Render `paintFunction` onto an offscreen native canvas at 8× supersample
   (scale = `8·N / specificationSize.width`), for N = 48, 32 and 16.
3. Per N×N cell: coverage = mean alpha; cell "on" if ≥ 0.5 (CLI-tunable per icon); role =
   dominant classified color (red→body, green→outline, other→quantized literal bucket → extra
   palette char).
4. Emit a complete draft `.coffee` per icon into `Fizzygum-tests/.scratch/pixel-icon-drafts/`
   (never directly into `src/`), preserving the homepage marker where the original has it,
   plus a combined contact-sheet HTML (vector | 32 | 16, multiple display sizes).

Gate: drafts + contact sheet exist for all ~79 targets; spot-check 5 for parse validity.

### P3 — Mass conversion

Copy drafts into `src/icons/` replacing the vector bodies (class name, file name, marker
comments preserved; parent class → `PixelIconAppearance`). First fix each icon's declared
grid subset per the §5 cohort table (all three drafts exist; keep what the cohort needs —
record the final per-icon table in this doc when done). Hand-touch-up the worst
auto-conversions — expect the 48s and the arrows/simple glyphs to be near-perfect from the
tool, the 16s to need the most hand-tuning, and the busy icons (Typewriter, Basement,
UnderCarpet, Welcome) to need edits at every density. Work in review-sized batches (arrows → window/panel chrome → text/format
buttons → app icons → odd-palette ones) but do NOT stop for per-batch owner review — the
single owner review happens at P4 (owner's standing long-arc preference). Gate:
`fg build` + boot-smoke green on both backends; every converted icon eyeballed in the
running world (native + `?sw=1`, dpr1+2 spot checks); contact sheet regenerated from the live
classes.

### P4 — Suite reconciliation + ⛔ owner recapture gate + mass recapture

1. Full suite run against the new build (background, log-redirected) to *enumerate* the red
   set — the tests whose references show converted icons. (Expectation: substantial — many
   desktop tests show toolbar icons. Measure, don't guess.)
2. `fg diffpage` over the red set (batched if large) — confirm every diff is the icon change
   and nothing else. Any non-icon diff = a real regression to fix before proceeding.
3. ⛔ **OWNER GATE — mass-recapture approval**: present red-set size, diffpage, regenerated
   contact sheet. This is the arc's ONE end-review point (with §5's contact-sheet decisions:
   logo / little-maps keep-or-convert).
4. Recapture: check `capture-macro-test-references.js` for multi-name support; if
   single-name, drive it serially (never parallel — boot-storm flake) via a thin loop script
   in `.scratch/`, logging per-test verdicts; equivalent of `fg recapture <name>` (full flow,
   `--dprs=1,2`) per affected test. Budget: recapture-inspector does 15 tests in minutes;
   scale estimate accordingly and run in background.
5. If inspector-set tests red with pure member-list diffs (new `PixelIconAppearance` members
   surfacing in an inspected object's panel): `fg recapture-inspector`. (Unlikely — the churn
   set keys off Widget-side members — but check.)
6. Close gate: full **`fg gauntlet`** green (11 legs incl. dpr2, webkit reusing SWCanvas refs,
   apps, paint audit, refs, revisits, census) + `fg homepage` boot check (homepage build
   excludes 10 icon pairs — must still compile/boot with the remaining pixel icons).

### P5 — Docs, measurements, close

- New `docs/architecture/pixel-icons.md`: present-tense reference for the format (§4.2 rules),
  the rasterizer contract, and the palette roles; link from `docs/README.md`'s architecture
  list. Update any architecture docs that describe icons as vector-only
  (`integer-pixel-placement-and-sizing.md` §Layer-C mentions icon art as fractional-space —
  add the pixel-icon integer-content note).
- Before/after measurement (honesty ledger): `wc -l` of the icon set pre/post, build artifact
  size delta, boot-time spot check. Optional `docs/measurements/` snapshot.
- Update `docs/BACKLOG.md` (close this plan's entries; move plan to `archive/` per README
  rule 2 with status stamp + `archive/INDEX.md` line), memory notes, then **propose** commit
  message(s) and STOP for owner approval (never auto-commit). Use `git commit -F <file>`
  when the owner approves (backtick-in-message trap).

### P6 — Banked (do NOT build in this arc)

- Dot-mode / LED / spaced-circles rendering style at large k.
- In-system pixel-icon editor (owner: "for a later day").
- Prune now-dead vector helpers from `IconAppearance` — ⚠ only after checking users OUTSIDE
  `icons/` (FanoutPin uses `_paintRoundedSquareBadge`).
- Optional pixel conversion of the logo/little-maps if the owner converts them later.

## §7 Central risks

1. **Owner rejects the look** → P0 exists to fail fast at one icon's cost. Do not proceed to
   P2/P3 on an unapproved style.
2. **Detail loss on busy icons** → the 48 grid is the detail tier for the cohorts that carry
   it; hand-touch-ups in P3; worst case a specific icon returns to the keep-vector list
   (per-icon decisions, not arc failure).
2b. **Cohort drift** → an icon later reused in a context whose cohort declares a different
   subset renders a divergent footprint in the §4.3 divergence bands; the P5 architecture
   doc must state the cohort rule so future icon placements check it.
3. **Byte-identity claim fails** (some backend nuance in fillRect/composite) → the arc still
   stands (suite gates SWCanvas only, which is deterministic regardless); write down what was
   actually observed. No conclusions before evidence.
4. **Mass recapture scale/churn** → enumerated empirically, owner-gated, serial capture,
   gauntlet close. Sub-pixel-sensitive divider tests etc. are unaffected (icons don't move
   layout: `preferredSize` stays a square aspect-fit and widget bounds are untouched — but
   verify in P4 step 2 that diffs are paint-only).
5. **`'''` string traps** (interpolation, trailing-space stripping, backslash) → charset rules
   in §4.2 make these impossible by construction; the strict parser catches violations.
6. **Wdgt-file marker/tooltip regressions** → Wdgt files are untouched by design; appearance
   rewrites preserve marker lines byte-verbatim (§1 list is the checklist).

## §8 Rejected alternatives (do-not-re-attempt, with reasons)

- **RGBA bitmap assets (PNG/data-URI)** — breaks the tint architecture (32 button sites +
  hover stain + theme outline, §1); adds an asset pipeline the build doesn't have; base64
  blobs are as unreviewable as the bezier soup. Falsifies owner problem #2.
- **SVG icons** — same SWCanvas AA problem as today (problem #3 survives); adds a parser
  dependency; not text-editable in any meaningfully better way at icon scale.
- **Icon fonts** — text-atlas machinery is for text; per-glyph theming/outline roles don't
  fit; authoring is worse than the status quo.
- **Fix SWCanvas AA instead** — a large project on a vendored rasterizer whose byte-
  determinism the entire reference-image system depends on; AA changes would invalidate all
  1,542 references AND re-open cross-engine (V8/JSC) determinism that the deterministic-trig
  shim only just closed. Vastly more risk for less benefit.
- **New class names / new call sites** (e.g. `HeartPixelIconAppearance`) — churns 90+ Wdgt
  and button files and the build's load-order edges for zero benefit; keeping names makes the
  diff purely per-file.
- **Auto-downscaling 32→16 at runtime** — produces exactly the mushy half-pixel artifacts
  this arc exists to eliminate; 16s are authored (tool-drafted, hand-finished).

## §9 Verification protocol (exact commands)

- Orient / re-orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status`
- Build: `/Users/davidedellacasa/code/Fizzygum-all/fg build`
- Boot smoke (both backends, console-error gate): `cd Fizzygum && ./build_and_smoke.sh`
- Single test: `/Users/davidedellacasa/code/Fizzygum-all/fg test <SystemTest_name>`
- Inner loop (only meaningful pre-conversion or post-recapture): `fg presuite`
- Mid-arc suite enumeration + long ops: background + log + task notification; peek with
  `cat /tmp/fg-<cmd>.verdict`. Never foreground-poll; never `| tail` the gating call.
- Diff review: `/Users/davidedellacasa/code/Fizzygum-all/fg diffpage <names...> [--dprs=1,2]`
- Recapture: `/Users/davidedellacasa/code/Fizzygum-all/fg recapture <name>` (serial for many)
- Close: `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` (background) + `fg homepage`
- Probes live in `Fizzygum-tests/.scratch/` (require() resolution), never the session
  scratchpad.

## §10 References

- `docs/architecture/integer-pixel-placement-and-sizing.md` — the integer-bounds guarantee
  §4.3 builds on (and the doc to amend in P5).
- `Fizzygum-tests/CLAUDE.md` + `DETERMINISM.md` (tests repo) — reference identity, dpr/backend
  matrix, capture flow, determinism case law.
- `docs/archive/INDEX.md` ⚖ bullets — recapture/diff case law from prior arcs (notably: a
  baked-in crash frame only surfaces on the webkit leg; stale-build trap after recapture —
  rebuild before re-verifying).
- Memory notes (umbrella memory dir): `ask-before-commit-push`, `owner-workflow-long-arcs`,
  `no-conclusions-before-evidence`, `dont-let-recapture-churn-dictate-design`,
  `swcanvas-reproduces-what-native-hides`, `fizzygum-runtime-backend-swcanvas`.
- Owner brainstorm (2026-07-17 session): problems 1–3, chunky-pixel reframe, locked decisions
  (a)/(b)/(c) — summarized in §0; this doc is the durable record.
