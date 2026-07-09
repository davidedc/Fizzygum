# Occlusion culling in the broken-rectangles repaint — feasibility + plan

**Status**: AUTHORED 2026-07-08 (feasibility established), VERIFIED + CORRECTED 2026-07-09
(every file:line claim re-checked against source; key corrections: Boxy inscribed-rect coverage is
REQUIRED from P1 — free desktop windows are rounded, so a rect-only predicate captures ~nothing at
top level; `HighlighterWdgt extends RectangleWdgt` inheritance trap; a plain-paint-route identity
gate excludes the nine widget-level paint overrides + BackBufferMixin; the paint pass has a damage-
bookkeeping side effect analysed in §1b; broken rects are padded +7px/side), then HARDENED FOR COLD
EXECUTION (full orientation §0, P0 re-anchor phase, code sketches in P1/P2, binding verification
protocol §5, measurement methodology §6 — prof-interactive `--cull` flag A/B + `--occl` fire-rate
counters + new `covered` phase). **P0→P3 LANDED 2026-07-09** (Avenue A, top-level, stateless):
`Widget.opaqueCoveredRect` + `WorldWdgt._paintedFromFrontmostCoverer` +
`WorldWdgt.occlusionCullingEnabled` + the `prof-interactive.js` measurement harness. Gauntlet green
(dpr1/dpr2/webkit 196/196, apps/paint/tiernaming/settle/capstone PASS) + homepage boot OK; one
benign inspector member-list recapture (`macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2/3
— `opaqueCoveredRect` joins the inspected widget's inherited-method list). Same-build cull off→on
(2 reps): drag ~3.0×, draw ~2.1×, covered ~4.3×; fire-rate 72/68/99%; scan not a hotspot. The
shipped feature is distilled in [`docs/occlusion-culling.md`](occlusion-culling.md). **Remaining
P4/P5/P5b/P5c below are OWNER-GATED and NOT started** (Avenue B maintained list; descend /
per-widget partial coverage; hand-carried drag coverer). **Self-contained: a fresh session executes
§4 P0→P3 and stops** (already done — this banner records the outcome).
**Idea (owner, 2026-07-08)**: when a broken rectangle is repainted back-to-front, if some widget
in the paint stack draws a SOLID OPAQUE rect that fully covers the broken rect, everything
painted BENEATH it is wasted — detect that and skip painting what's underneath.
**Provenance**: interactive profiling (2026-07-08) showed ~35% of a busy-drag frame is raw fill
rasterization (`_fillPolygonsDirect`/`_fillAxisAlignedRect`/`fill_AA_Opaq`/`_fillPixelSpan`) —
much of it overdraw of widgets hidden behind opaque windows. Orthogonal to items A/C in
`docs/interactive-render-perf-A-C-plan.md` (which make the painting that DOES happen cheaper;
this AVOIDS painting occluded widgets at all).

## 0. Orientation — read this first if you are executing cold

**Workspace**: `/Users/davidedellacasa/code/Fizzygum-all/` is an UMBRELLA directory (NOT itself a
git repo) holding three sibling git repos: **`Fizzygum/`** (framework source, ~470 CoffeeScript
files under `src/` — the ONLY place this plan edits), **`Fizzygum-tests/`** (the screenshot-diff
SystemTest suite, currently 196 tests), **`Fizzygum-builds/`** (generated build output — NEVER
hand-edit; regenerated wholesale on every build). Read the umbrella `CLAUDE.md` and
`Fizzygum/CLAUDE.md` before coding. This plan touches Fizzygum ONLY — no SWCanvas change (⇒ no
re-vendor) and no tests-repo change expected.

**Commands** (use the `./fg` wrapper from the umbrella root — path-correct from any cwd, loud
PASS/FAIL; a PreToolUse guard hook blocks wrong-cwd hand-chained variants; use `git -C Fizzygum …`
rather than cd-chains for git):
- Inner loop: `./fg build` + `./fg suite` (or `cd Fizzygum && ./build_and_test.sh`) — full build +
  whole suite headless, parallel shards, dpr 1, ~1 min.
- Full gate: `./fg gauntlet` (build + suite dpr1 + dpr2 + WebKit + apps + paint gates) and
  `./fg homepage` — this plan's bar is ALL legs green with **zero reference churn**.
- One test: `./fg test <name>`; or open `Fizzygum-builds/latest/worldWithSystemTestHarness.html`
  and run `world.automator.loader.loadAndRunSingleTestFromName('SystemTest_<name>')` in the console.
- Profiling: `node docs/profiling/prof-interactive.js --sw` from `Fizzygum/docs/profiling/`
  (busy-desktop drag; see `docs/profiling/README.md`; the harness is committed). ⚠ ALWAYS pass
  `--sw`: the owner runs the world with `?sw=1` (SWCanvas software renderer) — that backend IS
  the felt performance; a native-canvas profile measures the wrong thing (memory:
  `fizzygum-runtime-backend-swcanvas`). **The full measurement methodology for this plan —
  which harness, which extensions, what to report — is §6.**

**Codebase conventions that bite here**: `nil` means `undefined` (a Fizzygum global — use it, not
null); one class per file, filename == class name; NO import/require — every class is a global, so
new code in Widget/WorldWdgt referencing `RectangularAppearance`/`BoxyAppearance`/`Rectangle` by
bare name just works (the load-order regex scan only matters for `extends`/`@augmentWith`/`new X`
at class-definition time — none of which this plan adds); sources ship as escaped text and compile
in-browser at boot (the build's syntax gate catches parse errors); scope every search to
`Fizzygum/src` (the builds dir is ~1.3 GB / 20k+ files). **You are modifying the paint loop — read
`Fizzygum-tests/DETERMINISM.md` before P2.** This feature is deterministic by construction: the
cull decision is a pure function of the frame's settled geometry, computed in LOGICAL px
(dpr-independent), no trig/wall-clock/randomness (backend- and engine-independent) — keep it that way.

**⚠ Line-number drift**: every `file:line` below was verified 2026-07-09 (Fizzygum HEAD
`25990333`), but parallel sessions land work in this repo frequently. Phase P0 re-anchors by
SYMBOL before any edit — treat cited line numbers as hints, not truth.

**Owner working agreements (binding)**: NEVER commit or push without explicit approval — at the end
present a summary + proposed commit message and WAIT (write the message to a file and use
`git commit -F <file>`: the Bash tool mangles backticks/`$()` inside `-m`). Run the phases straight
through with ONE end-of-arc review. Give an upfront ETA for long operations and a status update
every ~5 minutes. Evidence before conclusions: never write "byte-identical"/"safe"/"done" into
docs, commit messages, or memory before the gates have actually passed. Prefer reuse over
duplication; comments/docs are a deliverable.

## 1. Key facts (verified 2026-07-08, re-verified line-by-line 2026-07-09, cited)

**The architecture already anticipates this.** The exact optimization is a documented TODO citing
GitHub issue #149 at `src/mixins/ClippingAtRectangularBoundsMixin.coffee:152-159`, and an
opacity-driven child-skip ALREADY ships in the SHADOW path there (`:203-209`: an opaque panel
skips painting all children in its shadow — NB its gate is `@alpha != 1` ALONE, `:207`; do NOT
imitate it, it ignores `@color._a`). There is currently NO such skip for CONTENT painting.

**Paint recursion is back-to-front (confirmed):**
- `WorldWdgt.doOneCycle` (`src/WorldWdgt.coffee:1454`) → `@updateBroken()` (`:1514`).
- `WorldWdgt.updateBroken` (`:1085`) drives `@broken.forEach (rect) => @fullPaintIntoAreaOrBlitFromBackBuffer @worldCanvasContext, rect` (`:1119-1124`).
- `WorldWdgt.fullPaintIntoAreaOrBlitFromBackBuffer` (`:688`) → `super` — which is the
  `ClippingAtRectangularBoundsMixin` override (`:104`), NOT Widget's directly: it supers into
  Widget's and then re-paints the panel stroke on top of the content (`:112-116`). The world then
  paints `@hand`/cursor LAST, on top (`:702`); the hand is NOT a `world.children` member, and a
  floatDragged widget rides the hand (`:695-697`) — no drag ghost-alpha exists. The world's own
  fill is `DesktopAppearance` (`WorldWdgt.coffee:370-371`; `DesktopAppearance.coffee:1` extends
  RectangularAppearance) — desktop colour + wallpaper pattern fill; skipping it is part of the win.
- `Widget.fullPaintIntoAreaOrBlitFromBackBuffer` (`src/basic-widgets/Widget.coffee:1964`) → shadow first if `@shadowInfo?` (`:1975`) → `fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` (`:2012`): **self paints, THEN children in array order** (`children[0..n]`, later = on top). For panels the mixin's content override first narrows the rect to the panel box and recurses with the narrowed rect (`ClippingAtRectangularBoundsMixin.coffee:169-180`).
- Top-level widgets (windows, icons) are direct `world.children`, a flat ordered list — **array
  order is BACK-to-front** (`children[0]` = rearmost, painted first; later = on top). The
  frontmost-coverer pre-scan therefore iterates the array in REVERSE. Z-order between whole
  top-level SUBTREES is strict: an earlier sibling's entire subtree paints beneath a later sibling.

**Existing pruning (none is content occlusion):** `PanelWdgt` narrows the dirty rect to its box
+ stops recursion on children outside it (`ClippingAtRectangularBoundsMixin.coffee:119,169-171`);
`preliminaryCheckNothingToDraw` (`Widget.coffee:1905`) is a pure visibility gate (invisible / empty
clip / orphan) with no opacity notion. No `isOpaque`/`covers`/`occlus` flag exists in `src/`.

**Opacity must be DERIVED (no flag) — and it is per-REGION, not per-widget.** The region a widget
provably paints fully opaque (its *covered-rect*), by CURRENT appearance:
- Exact `RectangularAppearance`: the TIGHT box — the
  main fill clips to `boundingBoxTight()` (`RectangularAppearance.coffee:82,88`; tight box = bounds
  inset by the four paddings, `Widget.coffee:697-710`). (`DesktopAppearance` extends it but is
  EXCLUDED by exact-class dispatch — correctly so: it is the world's own fill, nothing is ever
  behind the world, and its wallpaper-pattern overlay would complicate the claim for zero benefit.) Padding need NOT be zero: testing against
  the tight box accounts for it. If additionally `backgroundColor?` with `_a == 1`, coverage
  extends to the FULL bounds — the background fills the whole (clipped) bounds unaffected by
  padding (`Widget.coffee:99-104`, painted at `RectangularAppearance.coffee:73-77`; NB
  `backgroundTransparency` is NOT applied in this paint path, and the legacy `texture` fill
  (`Widget.coffee:63`) is ignored by this appearance). Conversely a TRANSLUCENT backgroundColor
  does NOT invalidate tight-box coverage — it only tints the padding ring, outside the claimed region.
- Exact `BoxyAppearance` (rounded; corner-transparency test `BoxyAppearance.coffee:12-44`): the
  INSCRIBED box — bounds inset by `getCornerRadius() + 1` on every side (`getCornerRadius` =
  `@widget.cornerRadius ? 4`, `BoxyAppearance.coffee:3-7`; the straight edges between corner arcs
  fill crisply to the bounds, only the arcs anti-alias, so radius+1 is conservative). **This case
  is NOT optional** — free desktop windows ARE Boxy (below) and are the dominant occluders.
- Anything else → nil: `BackBufferMixin` blits (per-pixel opacity unknown; its users today are
  `StringWdgt`, `CanvasWdgt`, `PaletteWdgt` — NOT WindowWdgt/PanelWdgt, verified), gradient/pattern
  fills, unknown appearance subclasses (check the appearance by EXACT class / constructor identity,
  not instanceof — subclasses can add arbitrary drawing e.g. via `drawAdditionalPartsOnBaseShape`).

Widget-level gates on top, ALL evaluated at RUNTIME (never baked per class):
- **The paint route must be the plain appearance delegation**:
  `@paintIntoAreaOrBlitFromBackBuffer is Widget::paintIntoAreaOrBlitFromBackBuffer` —
  `Widget.coffee:401-402` is pure delegation to `@appearance`, but NINE widget classes override it
  to draw directly (`HandleWdgt`, `LayoutChromeWdgt`, `LabelButtonWdgt`, `PenWdgt`, `CellWdgt`,
  `SpreadsheetWdgt`, `AnalogClockWdgt`, `Example3DPlotWdgt`, `GraphsPlotsChartsWdgt` — verified by
  grep 2026-07-09) plus `BackBufferMixin` (`BackBufferMixin.coffee:98`), and any of them may hold a
  Rectangular-style `@appearance` while painting arbitrary pixels. The one prototype-identity check
  excludes them ALL (it subsumes the back-buffer exclusion — no per-mixin probe needed).
- `@alpha == 1`
(`Widget.coffee:77-78`; the fill runs at `globalAlpha = @alpha`, `RectangularAppearance.coffee:60`);
`@color._a == 1` (else fillStyle emits `rgba(`, `Color.coffee:201-209`; `Color.create` defaults
`a = 1`, `:187`); `not @isEphemeral()`. Dispatch on the CURRENT `@appearance` object, never on
widget class — appearances are SWAPPED at runtime: `WindowWdgt._deriveAndSetBodyAppearance`
(`WindowWdgt.coffee:431-435`, re-run on every re-parenting via `_reactToBeingAdded:411-416`) gives
a nested window flat `RectangularAppearance` and a free desktop window `BoxyAppearance`.

⚠ **Inheritance trap (why the runtime gates are mandatory)**: `HighlighterWdgt extends
RectangleWdgt` (`HighlighterWdgt.coffee:21`) — a translucent, screen-topping ephemeral sized
exactly to the widget it highlights (`WorldWdgt.coffee:1295-1315`). Its two styles are caught by
DIFFERENT gates: the fill wash only by `@alpha` (`setAlphaScaled 50`), the outline style only by
`@color._a == 0` (its `@alpha` is 1 — `HighlighterWdgt.coffee:43-54`). A per-class opt-in on
RectangleWdgt would silently include it; the `isEphemeral()` gate is the belt to those suspenders.

Concrete coverers on a busy desktop: free `WindowWdgt`s (Boxy; `@color` opaque 248,248,248,
`WindowWdgt.coffee:122`; cornerRadius default 4 → inscribed box ≈ bounds inset 5px), INTERNAL
window bodies and `PanelWdgt`s generally (flat rect; default panel colour opaque 255,250,245,
`PreferencesAndSettings.coffee:130`; PanelWdgt uses RectangularAppearance, `PanelWdgt.coffee:20`),
plain `RectangleWdgt`s (`RectangleWdgt.coffee:12-18`).

**Coverage test** (logical px; `Rectangle.containsRectangle` exists — inclusive containment,
`Rectangle.coffee:296-298`): first clamp `testRect = brokenRect.intersect world.boundingBox()` —
broken rects are PADDED (next paragraph) and overflow the screen at desktop edges, where a
maximized window would otherwise NEVER qualify; the canvas clips those pixels anyway. Then a widget
occludes iff `opaqueCoveredRect().containsRectangle testRect.expandBy(1)` — the covered-rect from
above, with a +1px margin because painting rounds on the logical grid (`calculateKeyValues` does
`clippingRectangle.intersect(@bounds).round()` then scales by ceilPixelRatio,
`Widget.coffee:1815-1828`) — AND `@clippedThroughBounds().containsRectangle testRect`
(`Widget.coffee:1196` — bounds ∩ ancestor clip chain, so an ancestor clip hasn't cut the fill;
BONUS: it returns `Rectangle.EMPTY` for orphaned / hidden / collapsed widgets, `:1200-1202`, so
the visibility gate comes for free).

**Broken rects are per-widget but PADDED +7 logical px per side.** Each broken widget contributes
src (where it was last painted) and/or dst (current clipped bounds) rects, every one
`.expandBy(1).growBy @maxShadowSize` with `maxShadowSize: 6` (`WorldWdgt.coffee:263`, applied at
`:829,846,877,888`) — so the rect for a widget-change is that widget's clipped bounds grown ~7px
on every side, and the coverer must contain THAT. Consolidation is limited: exact-duplicate dedup
(`:722-735`), per-widget src/dst merge-if-close (`:740-750`), drop-if-contained-in-an-ANCESTOR's
rect (`checkARectWithHierarchy`, `:753-802`) — no global merging. **So a single opaque widget
covering an ENTIRE broken rect is COMMON when the change originates inside or behind an opaque
window** (a button repaint inside a window body; an animating widget behind a front window —
everything beneath, in that small rect, is pure overdraw). It is NOT the shape of a window-drag's
OWN rects: those are window-sized-plus-7px, so the dragged window's src/dst rects are contained
only by a substantially BIGGER window behind — see §4 P5b/P5c for the drag-case extensions.

## 1b. The one paint-pass side effect a skip must respect (verified 2026-07-09)

Painting on the world canvas RECORDS where each widget was painted:
`recordDrawnAreaForNextBrokenRects` (`Widget.coffee:1924-1928`; called from `Widget.coffee:1980-1981`
and the panel path `ClippingAtRectangularBoundsMixin.coffee:173-174`; at most once per frame per
widget, only when `aContext == world.worldCanvasContext`). The damage system CONSUMES these records
as the SRC broken rects (`WorldWdgt.coffee:827-829`, `:875-877`) and NILs them after consumption
(`:860`, `:902`). Records refresh ONLY via paint-touch — `__commitMoveBy` / `_applyMoveBy` and the
panel-scroll fast path never touch them.

Skipping an occluded widget also skips its record refresh. This is SAFE, by this invariant: the
record's contract is "every on-screen pixel of mine lies inside my recorded rect; a nil record
means no pixel of mine has been painted since it was nil'd". A skip happens only when an opaque
coverer owns every pixel of the broken rect, so the skipped widget contributes NO new on-screen
pixels there; on-screen pixels can only be created by actually painting, which always refreshes
the record first. A stale record is therefore a SUPERSET-of-visible claim → costs at most a
redundant repaint later, never a dropped pixel. Worked nil-record case: widget W moves (src pushed
from record, record nil'd at `:860`, dst pushed) → W is skipped in its dst rect because window F
covers it → record stays nil → W moves again → NO src rect is pushed this time — and that is
CORRECT: W's pixels are nowhere on screen (its old area was repainted without it; its dst area
shows F). When F later moves away, the revealed-area repaint paints W and refreshes the record then.

Implementation consequences: (a) do NOT walk skipped subtrees just to refresh records — the
invariant holds without it, and the walk would eat the win; (b) the WORLD's own record MUST still
refresh when its self-paint is bypassed (one direct `@recordDrawnAreaForNextBrokenRects()` call —
the world can itself be a brokenWidget, e.g. on wallpaper change); (c) the pixel-exact suite is the
empirical proof of (a). Also skipped along with the paint: the `justBeforeBeingPainted?()`
pre-paint hook (`RectangularAppearance.coffee:57`) — sole implementor is the caret
(`CaretWdgt.coffee:50`, blink bookkeeping); skipping it for a fully-occluded caret is harmless
(nothing of it shows). The repaint-error fallback (`updateBroken:1139-1140`,
`findOutAllOtherOffendingWidgetsAndPaintWholeScreen`) needs no special-casing: a whole-screen rect
simply fails the containment test against everything but a maximized window, which is a valid skip.

## 2. Design — two avenues

The recursion is top-down back-to-front, so when a subtree starts you don't yet know a LATER
sibling covers it. Both avenues fix this by, before painting a broken rect, finding the frontmost
widget that fully+opaquely covers it and beginning actual painting from THERE (skipping everything
behind it, within that rect). They differ in HOW they find that widget — a stateless per-rect scan
vs a maintained coverage list. They are complementary and can coexist (start with Avenue A; Avenue
B is the scaling/generalising follow-up).

Both need the **coverage notion** derived in §1 (no `isOpaque` flag exists). Two shapes of it:
- `Widget::paintsOpaqueFillCovering(rect)` → boolean (does this widget paint a solid opaque fill
  that contains `rect`?). Used by Avenue A.
- `Widget::opaqueCoveredRect()` → the maximal axis-aligned rectangle this widget paints FULLY
  OPAQUE (or `nil`). Used by Avenue B. See the covered-rect note below.
A false positive in either silently drops pixels (only the pixel-exact SystemTests catch it), so
both must be CONSERVATIVE — err to `false` / a smaller rect.

### Avenue A — stateless front-to-back pre-scan per broken rect
Before painting each broken rect, walk the overlapping widgets front-to-back and start from the
frontmost `paintsOpaqueFillCovering(rect)`.
- **Start: top-level only, but BOTH coverage shapes.** Scan `world.children` in REVERSE (the array
  is back-to-front, §1); the first non-ephemeral child whose covered-rect (tight box OR Boxy
  inscribed box, §1) contains the clamped rect wins; skip the desktop self-paint and every child
  behind it. ⚠ **Rect-only coverage would capture ~NOTHING at top level**: free desktop windows
  are Boxy (`WindowWdgt.coffee:431-435`) and flat-rect (internal) windows are by definition NESTED
  — so the Boxy inscribed-rect case must ship in P1, or P2/P3 measures zero on the busy desktop.
- **Concrete P2 mechanics** (world-level only, no mixin change): in
  `WorldWdgt.fullPaintIntoAreaOrBlitFromBackBuffer` (`:688`), before `super`: compute
  `dirtyPart = aRect.intersect @boundingBox()` (identical to the mixin's narrowing at `:169`);
  reverse-scan for the frontmost coverer index k; if none → `super` exactly as today. If found:
  (1) `@recordDrawnAreaForNextBrokenRects()` — preserve the world's own bookkeeping, §1b;
  (2) `for child in @children[k..]` → `child.fullPaintIntoAreaOrBlitFromBackBuffer aContext,
  dirtyPart` — byte-identical child trajectory to the mixin's own loop (`:179-180`);
  (3) replicate the mixin's trailing `@paintStroke aContext, aRect` (`:112-116`; a no-op for the
  world unless a strokeColor is ever set — `RectangularAppearance.paintStroke` gates on
  `@widget.strokeColor?` at `:135`); then `:702` paints the hand as today. The world has no
  `shadowInfo`, so bypassing Widget's shadow branch (`Widget.coffee:1975`) loses nothing. Ephemeral
  overlays need no special handling for PAINTING: the reconcilers append them as topmost
  `world.children` right before `updateBroken` (`WorldWdgt.coffee:1508-1511`, adders at
  `:1265,1295,1320`), so they sit at indices ≥ any coverer and always get painted.
- **Cost**: stateless (no bookkeeping, never stale); the scan is O(|world.children|) cheap
  rectangle/property tests per broken rect (tens of children × tens of rects/frame — noise next to
  the fills it avoids). Only a later DESCEND into nested coverers pays a real traversal (no
  maintained global `fullBounds` index — issue #150; `PanelWdgt` clipping already prunes most of it).

### Avenue B — maintained "covered-rect" list of sizable opaque widgets
Keep a persistent, incrementally-maintained list of the SIZABLE opaque widgets, each paired with
the **rectangle it completely covers** (`opaqueCoveredRect()`, in world/device space, already
intersected with its `clippedThroughBounds()` so an ancestor clip can't over-claim) plus a z-order
key. Then repainting a broken rect is a fast scan of this SHORT list: find the frontmost entry
whose covered-rect `containsRectangle(brokenRect)`, start painting from that widget, and paint
only the widgets IN FRONT of it. This is the "top-n biggest opaque widgets" idea the TODO already
suggests (`ClippingAtRectangularBoundsMixin.coffee:156`), made precise.
- **The covered-rect is the key idea** — track the rectangle a widget *completely* covers, NOT its
  bounds, so **non-rectangular opaque shapes still participate** via their INSCRIBED opaque
  rectangle and every check stays a cheap rectangle-containment test. The geometry and gates are
  EXACTLY §1's `opaqueCoveredRect()` (tight box / full bounds with opaque backgroundColor / Boxy
  radius+1 inset / nil) — one definition, defined once in P1, shared by both avenues; do not fork it.
- **"Sizable"** = covered-rect area above a threshold (small widgets aren't worth tracking; the win
  is big background rects/windows). Keeps the list short → O(list) per broken rect.
- **Maintenance / invalidation** (the cost of this avenue): the list entry for a widget is
  (re)computed only when something that affects its coverage changes — add/remove, move/resize,
  alpha/color/backgroundColor/cornerRadius/padding change, **appearance swap** (a re-parented
  window flips Rectangular↔Boxy, `WindowWdgt.coffee:411-435` — easy to miss because it is not a
  geometry or colour change), re-parenting (which changes `clippedThroughBounds` and z-order),
  and show/hide. Hook these off the existing `changed()` /
  layout / add-remove paths rather than rebuilding per frame. Z-order key: for top-level widgets
  it's the `world.children` index; nested coverers need the ancestor chain's order (defer to a
  later phase — start with top-level coverers only, same as Avenue A's simple start).
- **Cost**: O(short-list) rectangle checks per broken rect (no traversal), at the price of
  maintenance + a staleness surface (a missed invalidation → dropped pixels). Favoured when there
  are many broken rects per frame and few large opaque widgets — exactly the busy-desktop drag.

**Recommendation**: implement Avenue A first (stateless, no staleness surface, easiest to prove
correct against the pixel-exact suite). Then add Avenue B as the scaling path once the predicate +
covered-rect geometry are trusted — B reuses A's coverage geometry unchanged and just CACHES it
(the maintenance/invalidation wiring is the only new surface). A can even validate B (run both,
assert B's chosen start-widget matches A's) during bring-up.

## 3. Risks / caveats (must handle)

1. **Correctness is a one-way trap** — a false "covers" drops pixels invisibly (only caught by the
   pixel-exact SystemTests). Gates (ALL runtime, §1): plain-paint-route prototype identity
   (excludes the nine widget-level paint overrides AND BackBufferMixin in one check), exact-class
   appearance dispatch, `@alpha == 1`, `@color._a == 1`, `not @isEphemeral()`,
   `clippedThroughBounds` containment (ancestor clip hasn't cut the fill), +1px rounding margin,
   Boxy inset = radius+1. Padding≠0 and a translucent `backgroundColor` are NOT exclusions — the
   tight-box covered-rect already accounts for both (§1). Prefer false negatives.
2. **Shadows paint OUTSIDE bounds** (`Widget.coffee:1975`, subtree re-painted offset/faint behind
   itself). The containment predicate already makes this safe: ALL painting during a broken-rect
   pass is confined to that rect (every paint path intersects the passed clip; the shadow path
   translates ctx AND clip together, `Widget.coffee:1995-2004`, so its screen footprint stays
   inside the rect), and requiring coveredRect ⊇ rect means every skipped pixel — including any of
   the coverer's OWN pre-content shadow pixels inside the rect — is overpainted by the coverer's
   opaque fill. The corollary stands: the coverer's shadow ring outside its bounds must never
   count as coverage (it doesn't — the covered-rect is derived from the fill, not fullBounds).
3. **Ephemeral overlays** (highlights, pinouts, drag affordances) are reconciled into place every
   cycle right before paint (`doOneCycle:1508-1511`) as TOPMOST world children and are translucent
   (highlight wash alpha 50, `Widget.coffee:1851`) — "always painted" falls out of z-order (they
   sit in front of any coverer, §2A); "never occluders" needs the runtime gates + `isEphemeral()`,
   and beware the inheritance trap: `HighlighterWdgt extends RectangleWdgt`, and its OUTLINE style
   is excluded only by the `@color._a` gate (§1). The **hand/cursor** paints unconditionally last
   (`WorldWdgt.coffee:702`) — outside the skip; fine (and see §4 P5b for using it AS a coverer).
4. **No maintained global `fullBounds` index** (issue #150, `Widget.coffee:1938-1941`) — a
   DESCEND-into-subtrees scan costs a traversal (top-level-only doesn't); `PanelWdgt` clipping
   already prunes most of it. Measure that scan cost stays below the savings — if it doesn't,
   that's the argument for Avenue B.
5. **Avenue B staleness (its defining risk)** — the covered-rect list is correct only if EVERY
   change that affects a tracked widget's coverage, geometry, opacity, z-order, or parentage
   invalidates/updates its entry. A missed invalidation → silently-dropped pixels. Enumerate the
   invalidation triggers exhaustively (add/remove, move/resize, alpha/color/backgroundColor/
   cornerRadius/padding, appearance swap on re-parent, re-parent, show/hide) and prefer
   over-invalidation (drop the entry on any doubt → falls back to painting, never to dropping).
   The inscribed covered-rect for rounded/Boxy shapes must be inset conservatively (never include
   an anti-aliased corner pixel).
6. **Paint-pass bookkeeping** — the skip bypasses `recordDrawnAreaForNextBrokenRects` for skipped
   widgets; §1b proves this safe (and requires the world's own record call in the bypass path).
   Any future consumer of `clippedBoundsWhenLastPainted` / `fullClippedBoundsWhenLastPainted` must
   preserve the §1b invariant.

## 4. Phased plan

**Scope for a cold executor: run P0 → P3 as one arc, then STOP and report.** P4/P5/P5b/P5c are
optional follow-ons gated on P3's measurements AND an explicit owner go-ahead.

0. **P0 — baseline + re-anchor (before ANY edit to `src/`).** `./fg build` + `./fg suite` must be
   green BEFORE you change anything (if not: STOP and report — you may be sitting on another
   session's in-flight state; `git -C Fizzygum status` to check). Re-locate the plan's anchors by
   SYMBOL (lines drift): `updateBroken`, `fullPaintIntoAreaOrBlitFromBackBuffer` (WorldWdgt +
   Widget + ClippingAtRectangularBoundsMixin), `recordDrawnAreaForNextBrokenRects`,
   `fleshOutBroken` / `fleshOutFullBroken`, `_deriveAndSetBodyAppearance`, `maxShadowSize`;
   confirm no `opaqueCoveredRect`/`paintsOpaqueFillCovering` exists yet. If any §1 fact no longer
   holds, STOP and re-derive before proceeding. Then do the MEASUREMENT-ONLY harness extension of
   `docs/profiling/prof-interactive.js` per §6 (`--cull` axis, `--occl` counters, `covered`
   phase — no `src/` change, no pixels) and run it once against the unmodified build: this
   shakes the harness down (pre-feature, `--occl` must report "n/a", `--cull` legs must be
   identical) and records an environment-sanity baseline. The authoritative before/after is P3's
   same-build flag A/B (§6), not this capture.
1. **P1 — coverage predicate/geometry.** ONE new method on `Widget`
   (`src/basic-widgets/Widget.coffee`, near the paint section) — no Appearance-class edits: the
   exact-class `switch` IS the dispatch, and it is deliberately NON-polymorphic (a subclass
   appearance must never inherit a coverage claim, §1). Sketch (every API verified, §1):

   ```coffee
   # Occlusion culling (docs/occlusion-culling-plan.md): the axis-aligned rectangle this widget
   # provably paints FULLY OPAQUE, in logical px world coords, or nil. CONSERVATIVE by design:
   # any uncertainty must yield nil — a wrong rect silently drops pixels under the coverer.
   opaqueCoveredRect: ->
     # paint must route through the plain appearance delegation (Widget:401-402): widget-level
     # overrides (AnalogClockWdgt, CellWdgt, SpreadsheetWdgt, HandleWdgt, BackBufferMixin, ...)
     # draw arbitrary pixels regardless of what @appearance claims
     return nil if @paintIntoAreaOrBlitFromBackBuffer isnt Widget::paintIntoAreaOrBlitFromBackBuffer
     return nil if @isEphemeral()
     return nil if @alpha != 1
     return nil if !@color? or @color._a != 1
     switch @appearance?.constructor
       when RectangularAppearance
         if @backgroundColor? and @backgroundColor._a == 1
           @boundingBox()        # opaque bg fills the FULL bounds, padding ring included (§1)
         else
           @boundingBoxTight()   # the main fill clips to the tight box (§1)
       when BoxyAppearance
         # inscribed box: corner arcs anti-alias, straight edges fill crisply -> radius+1 inset
         @boundingBox().insetBy Math.max(@appearance.getCornerRadius(), 0) + 1
       else
         nil                     # incl. DesktopAppearance -- the world occludes nothing (§1)
   ```

   Notes: `insetBy`/`expandBy` take a plain Number (`Rectangle.coffee:202,219`); an over-inset
   (inverted) rect can never satisfy `containsRectangle` — degenerate-safe; CoffeeScript `switch`
   compares with `===` → exact class. If a named boolean helper is wanted,
   `paintsOpaqueFillCovering: (rect) -> (@opaqueCoveredRect()?.containsRectangle(rect.expandBy 1) ? false) and @clippedThroughBounds().containsRectangle(rect)`
   — ONE geometry serves both avenues (B merely caches it). No behaviour change yet (unused);
   unit-reason each gate against §1 in the commit message.
2. **P2 — Avenue A, top-level skip.** Flag: `WorldWdgt.occlusionCullingEnabled = true` as a CLASS
   property (class-level ⇒ untouched by world-snapshot serialization; it exists for A/B
   measurement and for DETERMINISM.md's "disable the mechanism" diagnosis move). Mechanics per
   §2A, shaped as:

   ```coffee
   # WorldWdgt -- restructure fullPaintIntoAreaOrBlitFromBackBuffer (:688; keep its comment block)
   fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, aRect) ->
     if !@_paintedFromFrontmostCoverer aContext, aRect
       super aContext, aRect
     # the mouse cursor is always drawn on top of everything (pre-existing behaviour)
     @hand.fullPaintIntoAreaOrBlitFromBackBuffer aContext, aRect

   # Occlusion culling (docs/occlusion-culling-plan.md §2A): if the frontmost opaque coverer of
   # this broken rect exists, paint starting FROM it and report true; else false (normal path).
   _paintedFromFrontmostCoverer: (aContext, aRect) ->
     return false if !WorldWdgt.occlusionCullingEnabled
     return false if aContext != @worldCanvasContext    # cull ONLY the live screen paint
     dirtyPart = aRect.intersect @boundingBox()         # == the mixin's own narrowing (§2A)
     return false if dirtyPart.isEmpty()
     testRect = dirtyPart.expandBy 1                    # +1px rounding margin (§1)
     covererIndex = nil
     for i in [@children.length - 1 .. 0] by -1         # front-to-back (array is back-to-front)
       child = @children[i]
       coveredRect = child.opaqueCoveredRect()
       if coveredRect? and coveredRect.containsRectangle(testRect) and
           child.clippedThroughBounds().containsRectangle dirtyPart
         covererIndex = i
         break
     return false if !covererIndex?
     @recordDrawnAreaForNextBrokenRects()               # §1b(b): world's own bookkeeping must stay
     for i in [covererIndex ... @children.length]
       @children[i].fullPaintIntoAreaOrBlitFromBackBuffer aContext, dirtyPart
     @paintStroke aContext, aRect                       # replicate the mixin's trailing stroke (§2A)
     return true
   ```

   Notes: `dirtyPart` already equals §1's world-clamp, so no separate clamp; ephemerals and
   hidden/collapsed widgets exclude themselves (`opaqueCoveredRect` → nil,
   `clippedThroughBounds` → EMPTY); the world has no `shadowInfo`, so bypassing Widget's shadow
   branch loses nothing; `world.paintingWidget` error-attribution is set by every painted child
   itself (`Widget.coffee:1968`), and `updateBroken`'s try/catch is unaffected. Optional dev-only
   skip-rate instrumentation: a counter — but ⚠ never rely on `console.log` in shipped paths (the
   homepage minifier strips it via drop_console; memory: S1 lesson).
3. **P3 — verify A, then measure per §6.** Full `./fg gauntlet` (all legs green) + `./fg
   homepage`, **zero reference churn** (the pixel-exact suite is the correctness proof — any
   dropped pixel fails loudly; it also empirically covers §1b). Then the §6 protocol: same-build
   flag A/B (`--cull=both --occl --sw --wallpaper=plain`, ≥2 repetitions) across drag/draw/
   covered phases, plus the per-phase `--profile` fill-cluster check. **Calibrated
   expectations**: the skip fires on rects from widgets animating inside/behind covered regions
   (the `covered` phase — expect a HIGH fire-rate there) and saves desktop-wallpaper +
   rear-window fills; the drag's OWN window-sized-plus-7px rects (§1) rarely have a single
   container, and the dragged window rides the hand so it is never itself a coverer in P2 (§4
   P5b) — expect a LOW drag fire-rate. Read the fire-rate before judging ms deltas (§6); confirm
   scan cost < savings (the scan must not appear as a new profile hotspot).
   **End of the cold-execution arc — report and stop (§5).**
4. **P4 — Avenue B, maintained covered-rect list.** Build the persistent list of sizable opaque
   top-level widgets + their `opaqueCoveredRect()` + z-index, with the full invalidation wiring
   (§3-5, incl. appearance swap). Replace the per-rect traversal with the O(list) rectangle scan.
   Bring-up safety: run BOTH avenues and assert B's chosen start-widget matches A's, then drop A.
   Re-verify gauntlet + re-measure (expect the scan cost to fall vs P2, especially with many broken
   rects/frame).
5. **P5 — (optional) descend.** Extend either avenue to nested opaque panels/bodies (needs the
   ancestor z-order chain; internal window bodies and PanelWdgts are clean flat-rect coverers, §1)
   if the top-level win justifies the added complexity.
6. **P5b — (optional, targets the DRAG case directly) hand-carried coverer.** The floatDragged
   widget rides the hand, which paints LAST (`WorldWdgt.coffee:695-702`) — visually frontmost, yet
   NOT in `world.children`, so Avenues A/B never use it as an occluder even while it covers
   everything it is dragged across. Extension: test the hand's carried widget as coverer FIRST
   (same predicate; usually a Boxy window → inscribed box); if it covers the rect, skip the desktop
   + ALL world children for that rect — they would be entirely overpainted by the hand's paint.
   Safe for the same containment reason as §3-2 (the carried widget's own pre-content shadow pixels
   inside the rect are overpainted by its opaque fill).
7. **P5c — (optional) fringe decomposition.** The dragged window's own src/dst rects are its bounds
   +7px per side (§1) — never containable by the window itself. Split such a rect into the covered
   core (rect ∩ covered-rect), painted with the skip (per P5b the carried window covers the core),
   plus ≤4 thin fringe strips painted the normal full-depth way. This is what unlocks culling for
   the drag's OWN rects — the single biggest fill cluster in the busy-drag profile — at the price
   of more paint passes per rect. Only attempt if P3/P5b measurements still show those rects
   dominating.

## 5. Verification protocol & landing (binding)

- **Zero churn is the acceptance test**: `./fg gauntlet` + `./fg homepage`, every leg green with NO
  reference recapture. A failing screenshot = the predicate dropped pixels — fix the gate; NEVER
  recapture references in this arc (byte-identical is the whole point). Suite case law: a shard
  reporting zero failed screenshots but hanging = an uncaught error → stall; clear zombie browsers
  and check the console (memory: `macro-test-relocation-gotchas`).
- **Debugging a suspect test**: `./fg test <name>`, or in-browser via
  `worldWithSystemTestHarness.html` + `loadAndRunSingleTestFromName`. First move: flip
  `WorldWdgt.occlusionCullingEnabled = false` and re-run — if the failure persists, it is not this
  feature (the DETERMINISM.md disable-the-mechanism proof).
- **Measure**: per the full methodology in §6 — the authoritative number is P3's SAME-BUILD flag
  A/B (`--cull=both`) on the extended `prof-interactive.js`, phases drag/draw/covered, plus
  fire-rates from `--occl`. (Context: busy 21-window drag measured ~88 ms/frame plain on
  2026-07-08, BEFORE Items A/C1 landed — the current baseline is lower; P0 re-measures.)
- **Landing**: Fizzygum repo only; phases land as one arc. Present per-phase summary, gate results
  (exact pass counts), the §6 measurement tables, and a proposed commit message (written to a
  file, committed via `git commit -F` — never `-m` with backticks) — then WAIT for the owner.
  After approval: record the outcome in `docs/runtime-performance-optimization-plan.md` §8 ledger
  + memory. This plan composes with (does not depend on)
  `docs/interactive-render-perf-A-C-plan.md`: that one makes the painting that DOES happen
  cheaper; this one avoids occluded painting entirely.

## 6. Measurement methodology (harness inventory verified 2026-07-09)

**The instrument is `docs/profiling/prof-interactive.js`** (committed; full docs in
`docs/profiling/README.md`). It is the only harness that exercises this feature's target
workload — the suite-driven profiler (`prof-run.js`) is structurally blind to it (no window
churn, default wallpaper), and the "many overlapping windows being moved around" scenario IS
prof-interactive's `drag` phase: it boots the plain world (`index.html`), opens all 14 desktop
apps (~21 overlapping windows), float-drags the topmost window along a screen-spanning lissajous
over the others (`dragPhase`, 140 frames), runs a FizzyPaint pen-stroke `draw` phase (80 frames),
and times every `doOneCycle`, reporting n/median/p95/max/mean per phase. Deterministic fixed
paths; dpr 1; ALWAYS `--sw` (§0). Its `--cwc`/`--text` flags set the extension convention:
instrumentation is a prototype wrap installed from `page.evaluate` AFTER boot — counters live in
the HARNESS, never in `src/` (keeps the shipped paint loop clean and sidesteps the
minifier-drop_console trap that voided the S1 "win").

**P0 extends the harness (measurement-only commit; no `src/` change, no pixels), three additions:**
1. **`--cull=on|off|both` axis**, exactly parallel to the existing wallpaper A/B: run the
   identical scripted phases with `WorldWdgt.occlusionCullingEnabled` true vs false (set via
   `page.evaluate` after boot; tolerate the flag not existing = pre-feature build → report
   "n/a"). **This same-build flag A/B is the authoritative before/after**: the flag-off path is
   the untouched `super` path, so a separate before-build proves nothing extra, and environmental
   drift cancels within one session. Pin `--wallpaper=plain` for cull A/Bs — one axis at a time.
2. **`--occl` counters** (mirror `--cwc`'s shape): wrap
   `WorldWdgt.prototype._paintedFromFrontmostCoverer` to tally per phase {rects seen, culled
   fires, fire-rate %}, and wrap `Widget.prototype.opaqueCoveredRect` for a scan-call count.
   Without fire-rate you cannot distinguish the two null-result failure modes P3 must tell apart:
   "predicate never fires" (geometry/gates too strict, or workload has no containable rects) vs
   "fires but the scan cost eats the savings".
3. **A third scripted phase — name it `covered`, NOT `idle`** (`idle` is already the warm-up
   bucket name in `installTiming`): after `openAllApps`, deterministically place a large window
   fully over the AnalogClock window (locate it the way `fizzyPaintCanvasArea` locates FizzyPaint;
   drag it there or move it via the public API), release, then hold ~180 input-free frames. The
   clock still animates every cycle (post-Item-C1 its face is back-buffered but the hands repaint
   live), producing small broken rects fully inside the covering window — the exact §1 sweet spot;
   expect a high fire-rate here. Update the report loop's phase list (`['drag','draw']`) to
   include it.

**How to read the numbers**: `drag` frames run far over the 16.7 ms budget (~88 ms/frame plain
measured 2026-07-08, pre-Items-A/C1 — current baseline is lower), so savings appear ~1:1 in
median/p95, unmasked by vsync pacing. `covered` frames are mostly cheap no-ops, so its median is
meaningless — judge by MEAN (total work per frame) plus fire-rate. Always report fire-rate next to
ms deltas. prof-interactive is dpr1-only by construction (fixed `deviceScaleFactor:1`).

**Where-the-win-comes-from check**: `--profile` per phase, then the README's inline `.cpuprofile`
top-self-time parse, or `prof-aggregate.js` against a `mk-shadow-build.sh` shadow build (read
PERCENTAGES there — the shadow build inflates absolute ms ~3×). Expect the raw-fill cluster
(`_fillPolygonsDirect`/`_fillAxisAlignedRect`/`fill_AA_Opaq`/`_fillPixelSpan`; ~35% of busy-drag
at the 2026-07-08 baseline) to shrink in culled phases, and the new scan (`opaqueCoveredRect` /
`_paintedFromFrontmostCoverer`) NOT to appear as a hotspot.

**Secondary corroboration (optional, cheap)**: `prof-run.js --sw=1 --dpr=2 --tests=all` suite
wall-clock before/after — dpr2 is CPU-bound and responds ~1:1 (dpr1 wall time is frame-count
bound, do NOT use it); and/or `--counters` (draw-call totals should drop suite-wide; the
instrumented run still passing every test is itself a pixel-transparency proof). The full
`run-campaign.sh` (~55 min) + diff against `docs/profiling/results-2026-07-07/` only if the owner
asks for a ledger-grade refresh.

**Correctness instruments beyond the §5 gates (both optional, owner-priced):**
- **Dual-paint oracle (dev-only) — the strongest direct proof**: following the existing
  `world.doubleCheckCachedMethodsResults` oracle precedent, add
  `world.doubleCheckOcclusionCulling` (default false): whenever the bypass fires for rect R, ALSO
  paint R the normal un-culled way into a scratch offscreen context
  (`HTMLCanvasElement.createOfPhysicalDimensions`, honouring the backend switch) and byte-compare
  the R region; `debugger`/alert on mismatch. Sound because BOTH paints fully determine every
  pixel of R (normal path: the desktop fill covers R first; culled path: the coverer does), and
  scratch painting cannot disturb the damage bookkeeping (`recordDrawnAreaForNextBrokenRects`
  gates on `aContext == world.worldCanvasContext`, §1b). Run the suite + prof-interactive once
  with it on; ship default-off.
- **`torture-headless.js` overnight sample** (tests repo; the generic nondeterminism hunter): the
  feature adds a geometry-dependent BRANCH to the paint path — under load/dpr2 the per-cycle
  event drain shifts WHICH broken rects exist and hence which get culled, and the pixels must
  stay invariant regardless. A few-hour `node scripts/torture-headless.js --speeds=fast,fastest
  --shards=2,4` after landing samples exactly that claim. Not a gate; a confidence-builder.
