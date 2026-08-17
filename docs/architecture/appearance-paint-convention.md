# The appearance paint convention — local logical coordinates through the ctx matrix

**Status**: reference (present-tense, verified against src). Landed by the appearance
local-coords arc (affine plan §7.7 — `docs/archive/appearance-local-coords-plan.md`). Read this
before writing or modifying any `*Appearance` paint body, and together with
`integer-pixel-placement-and-sizing.md` (the C1 float-arithmetic case law it leans on) and
`transforms.md` (the island architecture this convention feeds).

## The law

> An appearance body draws its widget's OWN pixels in widget-local LOGICAL coordinates,
> through the ctx matrix, inside the standard scope
> (save → damage clip → alpha → `useLogicalPixelsUntilRestore` → translate to widget position).
> Damage clipping, the shadow-silhouette fallback, and back-buffer/pattern blitting are the
> PREAMBLE's device-space business — a body never touches `al/at/sl/st`. The body receives the
> damage box as a LOCAL rect for partial-repaint fills.
> Exception, by declaration only: a body may draw in integer DEVICE pixels anchored at the
> widget origin when its art is dpr-conditional pixel work (the SizeAware family) — such a body
> documents it and never reads `al/at`.
> Ctx state set by a body is contained by the preamble's save/restore; leaving state as a
> contract for a callee within one body is allowed, across bodies it is not.

## The one preamble

`Appearance._paintInLocalScope aContext, clippingRectangle, appliedShadow, bodyFn`
(`src/Appearance.coffee`) is the single spelling of the scope. It returns undefined when there is
nothing to draw, else runs `bodyFn ctx, localArea, appliedShadow` inside the scope and restores.
`localArea` = the damage box translated to widget-local logical coordinates (integer — both the
damage box and the widget position are integer by the placement law).

The block is the LAST argument, which is what the CoffeeScript idiom needs. The scope's two knobs
are therefore **declared by the appearance class**, not passed per call — no appearance varies
either between paints, so each is a class-level fact:

`@alphaPolicy` picks the globalAlpha policy:

| policy | effect | users |
|---|---|---|
| `undefined` (the base) | `(appliedShadow.alpha or 1) × @widget.alpha` — the norm | almost everyone |
| `"none"` | globalAlpha untouched (ambient) | the sheet cells (edge/ring chrome) |
| `"backgroundTransparencyNormalPass"` | `@widget.backgroundTransparency`, normal pass only | the plot family |

⚠ A subclass inherits these like any field. That is correct here only because each declaring class
is also where the `_paintInLocalScope` call lives, so the field cannot reach a subclass whose paint
the declaration was not already deciding. Check that before adding a third knob.

`@clipsToLocalArea: false` skips the scope's damage clip — for a body whose every draw provably
bounds itself to damage∩tight (`RectangularAppearance`: its fills and stroke are exact rects,
and its droplet hook self-clips). This is not an optimization but a PIXEL contract: in an
island buffer the ambient translate can be FRACTIONAL (a rotated-container payload's figure
has a fractional slot origin), where an added rect-clip's boundary quantization differs from
the fills' and cuts an edge column — the legacy device paint never clipped, so neither may
the converted one. (Found at dpr 2 via `macroDropIntoRotatedStretchablePanelStretchesOnResize`.)

`Appearance._fillLocalRectSnappedToDevicePixels` is the fill spelling for every fill that
legacy code routed through `Widget.paintRectangle`: it reproduces that path's `Math.round`
device-grid quantization. For integer geometry it is the identity; it exists because PLANE
positions can be legitimately fractional (the reparent-transparency figure landing), where
raw fractional fills would quantize at the rasterizer instead.

Class-specific pre-guards (shadow-pass early returns, `thisSpacerIsTransparent`, the sheet
back-ref checks) stay in the caller, before the scope call.

## Why through-the-matrix

- **Vector replay** (affine plan §7.1/§7.2): a body that draws through the CTM can be replayed
  under an arbitrary transform; a body that computes `* ceilPixelRatio` device coordinates
  cannot. After this arc, every body except the declared device-space family is replay-shaped.
- **No fast path is lost**: SWCanvas's direct-shape dispatchers gate on
  `isAxisAligned`/`isUniformScale`, never on `isIdentity` — a translate/scale CTM disengages
  nothing (the complete per-entry dispatch table lives in the SWCanvas repo's
  `DIRECT-RENDERING-SUMMARY.MD` §3).
- **Byte-identity is provable for integer/dyadic geometry**: under an integer translate and the
  dpr scale, integer/dyadic coordinates map to the exact same device values (IEEE-754 exact),
  so the conversion changed no reference. Non-dyadic arithmetic (`/3`, trig, fit-scales) is the
  C1 hazard — preserve association order when touching such a body
  (`integer-pixel-placement-and-sizing.md` §5).
- **Text wins at dpr 2**: the SWCanvas atlas direct-blit requires the CTM scale to equal the
  dpr; absolute-device text on the world context missed it.

## The declared device-space exceptions

- **The SizeAware icon family** (`src/icons/SizeAwareIconAppearance.coffee`, base + 9):
  dpr-conditional integer-device pixel art, by documented design. The law's exception clause.
- **Blits are preamble business**: `BackBufferMixin`'s buffer blit (named `blitBackBufferInto`, so
  an appearance can compose it), and `AnalogClockAppearance`'s cached-face blit (its background fill
  sits UNDER that blit, so both stay device-space in its own preamble; only the hands/live content
  ride the scope). `PaletteAppearance` is the same two-layer shape over the mixin's blit: a cached
  buffer is keyed on class + extent and therefore SHARED, so anything per-instance — a palette's
  choice marker — has to be drawn live on top, and that half rides the scope. Such an appearance
  keeps its own entry (it calls the blit before opening the scope) and its widget defines
  `paintIntoAreaOrBlitFromBackBuffer` as the plain delegation, to un-shadow the mixin's member.
- **Pattern fills**: a `CanvasPattern` anchors to the coordinate space — under the scope's CTM
  the tile would scale with the dpr and its phase would follow the translate.
  `DesktopAppearance._paintBackgroundPatternFill` therefore runs AFTER the scope closes, in
  device pixels (verified by the wallpaper A/B probe — the desktop has no suite coverage).
- **The world-level selection/highlight overlays** (`Widget._drawSelectionOverlay`) are not
  appearance bodies; they keep their device spelling (only the stroke THICKNESS is logical —
  `lineWidth ceilPixelRatio`, matching the rectangular-family border).

## Related spellings

- `IconAppearance` keeps its own scope: a different translate+scale into its 200×200 spec
  space — already through-the-matrix, untouched by this arc.
- `RectangularAppearance.paintStroke` draws the rectangular border at ONE LOGICAL pixel
  (2 device px at dpr 2) — the same thickness and the same raw local spelling as
  `BoxyAppearance.strokeOutline` (`lineWidth 1`, half-logical-pixel inset), so every
  rectangular-family border shares one look through the matrix. It is also a standalone entry
  (clipping panels and the world re-stroke after children), so it derives its own key values.
  Deliberately NOT device-grid-snapped: a widget's plane position is integer by the placement
  law (snapping is provably the identity), and the one genuinely fractional offset — a
  compensating wrapper's figure origin plus its rotation pair — lives in the CTM, which a body
  never reads. Thin strokes render CONTINUOUSLY under rotated composites: SWCanvas samples the
  rotation composite bilinear (`docs/architecture/transforms.md` §8, sampling contract), so a
  1-2px feature cannot disintegrate into dashes at the warp.
