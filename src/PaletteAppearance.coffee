# Paints a PaletteWdgt in two halves: the colour field, blitted straight from the shared back
# buffer, and then — live, on top — the one thing that buffer structurally cannot carry, namely
# where THIS palette's own @choice sits on it.
#
# The split is forced, not stylistic: world.cacheForImmutableBackBuffers keys the buffer on class
# + extent, so every palette of the same size draws from ONE canvas and no per-instance mark can
# ever be painted into it. Hence blit (device space, BackBufferMixin's business) then mark (the
# standard logical-pixels local scope) — the same two-layer shape AnalogClockAppearance uses for
# its cached face plus live hands.
#
# The mark is drawn on the NORMAL pass only. A shadow is pure COVERAGE (Widget.coffee, "How the
# shadow painting works"), and the mark lands inside the buffer's own opaque footprint, clipped to
# it — so it contributes no coverage and painting it into the silhouette would cost a pass to
# change nothing.
#
# The marker is not a stored position. @choice ALONE decides it, inverted through the palette's
# own positionForColor on every paint (see PaletteWdgt) — so a colour that arrives from anywhere
# (a pick, a snapshot, a duplicate, a wire) is marked by the same one path, and there is no second
# statement of the fact to fall out of step with the first.

class PaletteAppearance extends Appearance

  # The choice ring's nominal radius in logical pixels: a black hairline just outside a white one,
  # a pairing that stays legible over any hue the field can show. Shrinks on a palette too small
  # to hold it (a colour picker's gray strip is ~5px tall) — see _paintRingAt.
  @RING_RADIUS: 4

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @widget.blitBackBufferInto aContext, clippingRectangle, appliedShadow
    return if appliedShadow?
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      @_paintChoiceMark ctx

  # ONE mark, two renderings, decided by whether the palette can honestly point at the colour.
  _paintChoiceMark: (ctx) ->
    choice = @widget.choice
    return unless choice?
    positionOnMe = @widget.positionForColor choice
    if positionOnMe?
      @_paintRingAt ctx, positionOnMe
    else
      @_paintOffMapFrame ctx, choice

  # ON THE MAP. Centred on the MIDDLE of the marked pixel (the +0.5), with the two hairlines at
  # half-integer radii so each covers exactly one whole logical pixel ring.
  _paintRingAt: (ctx, positionOnMe) ->
    extent = @widget.extent()
    # shrink rather than overflow: the gray strip inside a ColorPickerWdgt is only a few px tall,
    # and a ring bigger than the palette would read as a stray arc rather than as a marker.
    radius = Math.max 2, Math.min PaletteAppearance.RING_RADIUS, Math.floor(Math.min(extent.x, extent.y) / 2) - 1
    ctx.lineWidth = 1
    ctx.strokeStyle = Color.BLACK.toString()
    @_strokeCircle ctx, positionOnMe, radius + 0.5
    ctx.strokeStyle = Color.WHITE.toString()
    @_strokeCircle ctx, positionOnMe, radius - 0.5

  _strokeCircle: (ctx, centrePixel, radius) ->
    ctx.beginPath()
    ctx.arc centrePixel.x + 0.5, centrePixel.y + 0.5, radius, 0, 2 * Math.PI
    ctx.stroke()

  # OFF THE MAP: the colour is not a point on this palette at all — for the HSL field that is any
  # colour whose saturation isn't 100%, which is to say most colours. There is then nothing honest
  # to point AT, and snapping the ring to the nearest on-map pixel would draw a position the value
  # does not have. So say the true thing instead — "my value is this colour, and it is not on me" —
  # by framing the whole field in it.
  _paintOffMapFrame: (ctx, choice) ->
    extent = @widget.extent()
    # The band is laid down BETWEEN two black hairlines and never under one — the field behind it
    # runs from white to black, so a band bounded on only one side disappears against one corner or
    # the other (and a hairline painted OVER the band's outer half leaves too little colour to read).
    ctx.lineWidth = 1
    ctx.strokeStyle = Color.BLACK.toString()
    ctx.strokeRect 0.5, 0.5, extent.x - 1, extent.y - 1
    ctx.lineWidth = 2
    ctx.strokeStyle = choice.toString()
    ctx.strokeRect 2, 2, extent.x - 4, extent.y - 4
    # A palette too thin to hold the inner hairline (a colour picker's gray strip is a few px tall)
    # goes without it, rather than describing a negative rect: there the band fills the strip, which
    # says the same thing.
    return unless extent.x > 8 and extent.y > 8
    ctx.lineWidth = 1
    ctx.strokeStyle = Color.BLACK.toString()
    ctx.strokeRect 3.5, 3.5, extent.x - 7, extent.y - 7
