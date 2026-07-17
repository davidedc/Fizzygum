# Integer pixel placement & sizing — policy and rationale

**Status**: reference. Distilled from the 2026-07-09 investigation that came out of the C1
clock back-buffer work (`docs/archive/interactive-render-perf-A-C-plan.md` §3.1; the runtime-perf
§8 ledger). Read this before adding a back buffer to a directly-drawn widget, before
"rounding" anything in the layout/paint path, or when a SystemTest shifts by 1px.

## TL;DR

- **Every widget is PLACED and SIZED in integer coordinates.** A widget's applied
  `@bounds` — its top-left position AND its width/height — are integers, in *logical*
  pixels, which become integer *device* pixels at any `ceilPixelRatio` (dpr 1 and 2).
- **Fractional "desired" geometry is allowed, but kept on the side.** Layout may *want*
  a fractional size/position (a stretchable panel splitting 100px among 3 children wants
  33.33 each); that intent is remembered separately, and the *applied* bounds are rounded.
- **Internal content rendering is NOT integer, and that is correct.** Vector/icon art,
  charts, and rotated/scaled strokes draw in floating-point design space inside their
  paint functions. Forcing that to integer would distort the artwork. It is not "placement".
- **Integer placement is NECESSARY but NOT SUFFICIENT for a back buffer to be byte-identical
  to a direct draw** (see §5, the C1 lesson).

## 1. The three layers of geometry

Keep these distinct — most confusion comes from conflating them:

| Layer | What | Integer? | Where |
|---|---|---|---|
| **A. Applied bounds** (`@bounds`) | where a widget is placed + its size on screen | **YES — enforced** | `@position()`, `@extent()` |
| **B. Desired / logical geometry** | what layout *wants* before rounding | may be fractional, **remembered on the side** | `@desiredPosition`, `@desiredExtent`, `@positionFractionalInHoldingPanel` |
| **C. Internal content rendering** | the pixels a widget draws *inside* its box | fractional & legitimate | appearance `paintFunction` / `renderingHelper` |

Layer A is the "placement & sizing" the policy governs. Layers B and C are *supposed* to
carry fractions.

## 2. How placement & sizing are kept integer (Layer A)

Rounding happens at the geometry-commit points, not scattered through callers:

- **Position** — `Widget._moveToNoSettle` (`src/basic-widgets/Widget.coffee:1365`):
  ```coffee
  aPoint = aPoint.round()
  newX = Math.max aPoint.x, 0
  newY = Math.max aPoint.y, 0
  ```
- **Size** — `Widget.__commitExtent` (`src/basic-widgets/Widget.coffee:1556`):
  ```coffee
  aPoint = aPoint.round()
  ```
  `__commitExtent` is the single bottom of the extent-apply path (`_applyExtent` /
  `_applyWidth` / `_applyHeight` / `setExtent` all funnel through it), so *every* size
  change is rounded.
- **The device blit coordinates** derived from bounds are integer too:
  `Widget.calculateKeyValues` (`:1815`) rounds the visible area and multiplies by
  `ceilPixelRatio`, so `al/at/sl/st/w/h` (the drawImage/fillRect args) are integer device
  pixels.
- **The arrange-APPLY path rounds AT THE PRODUCER.** `_moveToNoSettle` / `__commitExtent` above are
  the *desired-geometry* funnel; a container arranging children BYPASSES it, applying a computed
  target straight through `_applyMoveTo` / `_reLayout` (which deliberately do **not** re-round —
  the 2015 contract was "round once at the source, assert on apply"). So each arrange producer that
  computes a *fractional* target (`parentDim * fraction`, `height/n` tick spacing, `center()` on an
  odd extent, corner-internal `minDim`, the horizontal-stack distribution) rounds its own
  point/bounds — carrying an EXACT running accumulator where one exists (the horizontal stack) so
  proportions still telescope without drift. See `docs/archive/fractional-widget-bounds-investigation-plan.md`.
- **The always-on guard `Widget._assertBoundsWellFormed`** (finite + integer; formerly `_assertBoundsFinite`,
  when it checked finiteness only — called from every bounds-commit leaf —
  `__commitExtent`/`__commitWidth`/`__commitHeight`, `_applyMoveByBase`, `_applyBounds`,
  `_commitBounds`) `console.error`s `NON_FINITE_GEOMETRY` (NaN/Infinity) **and** `NON_INTEGER_GEOMETRY`
  (fractional applied bounds); **both are wired into the headless runners' fail-gate**, so a
  fractional `@bounds` FAILS the suite even when the pixels happen to match. It replaced the
  `debugIfFloats` hooks — a real integer assertion 2015→2018, silently stubbed to a no-op in 2018,
  and deleted in 2026 (`fbc2a3a4`) — restoring the enforcement that had lapsed for ~8 years.

Empirically confirmed: with the guard hard-gated, a full 249-test suite run (native + SWCanvas,
dpr 1 & 2, plus WebKit) reports **zero** `NON_INTEGER_GEOMETRY` — every widget's applied `@bounds`
is integer. (The earlier evidence was narrower: instrumenting `AnalogClockWdgt`'s paint logged
`@position()` always integer with an identity CTM — true, but it only exercised the desired funnel,
not the arrange-apply path, which is how the ~2018→2025 fractional-placement gap went unnoticed.)

## 3. Fractional geometry "on the side" (Layer B)

The framework deliberately keeps the *fractional* intent even though it applies integers.
The canonical case is a child inside a **stretchable panel**: its applied position is
rounded, but its *fractional position relative to the holding panel* is remembered
(`Widget._moveToNoSettle:1379-1392` → `@positionFractionalInHoldingPanel`), so that when the
panel is later resized, the child is repositioned from the exact fraction rather than
drifting off the accumulated rounding. The comment at `Widget.coffee:1372-1378` spells this
out. Same idea for `@desiredPosition` / `@desiredExtent`: layout records what it wants; the
mutator rounds what it commits.

**Rule:** never "fix" a fractional *desired* value by rounding it at the source — that
destroys the information Layer B exists to preserve. Rounding belongs only at the commit
points in §2.

## 4. Why the policy exists

- **The software renderer (SWCanvas) is non-antialiased.** A fractional device position
  does not render at sub-pixel precision — it only changes *which* integer pixels a shape
  covers, frame to frame. Integer placement gives stable, jitter-free motion; fractional
  placement would buy nothing but shimmer. (The native canvas backend *is* AA, so it would
  render sub-pixel — but production defaults to native only for non-`?sw=1` users; the
  owner and the test suite run SWCanvas.)
- **The SystemTests assert byte-exact pixels.** Deterministic output requires geometry to be
  a pure function of the event stream + final integer bounds. See `Fizzygum-tests/DETERMINISM.md`.
- **dpr-independence.** Integer *logical* bounds × `ceilPixelRatio` = integer *device* pixels
  at dpr 1 and dpr 2 alike, so the same integer discipline holds at both densities.
- **Back-buffer alignment.** A widget cached to an offscreen buffer (`BackBufferMixin`) is
  blitted at its rounded device origin; integer placement is what lets that blit land on the
  pixel grid (see §5 for the important caveat).

## 5. Integer placement is necessary but NOT sufficient for back-buffer byte-identity

This is the sharp lesson from **C1** (back-buffering `AnalogClockWdgt`'s static tick face).
Placing a widget at an integer position does **not** guarantee that rendering its content
into an origin buffer and blitting it is byte-identical to drawing it directly — because
relocating the draw changes the floating-point CTM:

- **Direct draw** bakes the widget position into the float transform, so a tick endpoint
  rasterises as `floor(a·squareDim + position + w/2)`.
- **Buffer + blit** draws at the buffer origin, then adds the position back as an *integer*
  pixel offset: `floor(a·squareDim + w/2) + position`.

These are equal in exact arithmetic but **IEEE-754 addition is not associative**, so they
differ by ≤1px when the endpoint sits near a pixel boundary. It is **size- and
dpr-dependent**: for the clock, byte-exact at 70/130px on dpr 1, but 130px diverges on dpr 2
(867/900 offsets) and the 200px default diverges on both — which is exactly why the resize
and nested-window clock tests passed at dpr 1 yet failed at dpr 2. (Isolated repro:
`scratchpad/clock-sweep.js` + `clock-dpr.js` at the time of writing.)

**Consequences / guidance for future back-buffer conversions:**

- Content that is **axis-aligned rects + text at integer positions** is FP-robust — a back
  buffer of it is byte-safe. (This is why regular `TextWdgt` labels back-buffer cleanly.)
- Content with **rotated / non-uniformly scaled strokes or vector paths** (clock ticks,
  angled icons) is FP-sensitive: expect ≤1px shifts and plan for a reference recapture, or
  keep drawing it live.
- Do **not** try to "gate" a back buffer on an integer-transform check — positions are
  already integer; the divergence is in the internal float rasterisation, not the placement.

## 6. What is legitimately fractional (Layer C) — do not "fix" these

The paint-time fractional device transforms you will see (e.g. via a transform-op probe)
come from *content rendering*, not placement:

- **Vector / icon art** — `IconAppearance` subclasses draw a fixed floating-point **design**
  (e.g. `AngledArrowUpLeftIconAppearance`: `translate 90,37; moveTo -25,-9.04; lineTo
  16.6,32.5; … lineTo 79,-102.5`), **scaled to fit** the integer box. The fit-scale and the
  design's own fractional coordinates make the drawn content land at fractional device
  positions. Rounding these would deform the icons.
- **Charts / plots** — data-driven `scale`+`translate` to fractional positions
  (`renderingHelper` in the sample-dashboard plots).
- **The clock face** — internal `translate(w/2,h/2)` + `scale(0.9)` + `rotate` (the C1 case).

All of this is Layer C: correct, inherent, and out of scope for the integer-placement policy.

## 7. Contributor checklist

- Adding a geometry mutator? Round at the commit point (mirror `__commitExtent` /
  `_moveToNoSettle`), and preserve any fractional *desired* value on the side — don't round it away.
- Adding a back buffer to a directly-drawn widget? Verify with the full gauntlet. Axis-aligned
  + text content is usually byte-safe; rotated/scaled/vector content may shift ≤1px (§5) and
  need a recapture — decide that up front.
- Seeing a 1px SystemTest shift after a paint/layout change? Check §5 (FP-sensitive content
  relocated) before assuming a placement bug — placement is almost certainly already integer.
