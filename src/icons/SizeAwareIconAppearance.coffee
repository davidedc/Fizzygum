class SizeAwareIconAppearance extends IconAppearance

  # Base for SIZE-AWARE icons (extracted 2026-07-21 from TypewriterIconAppearance,
  # the reference implementation, on the second conversion — see
  # docs/plans/pixel-icons-plan.md §5b).
  #
  # A size-aware icon never draws in a fixed design space: it reads its ACTUAL
  # size in device pixels and computes integer-pixel geometry from that budget.
  # THE POINT: the non-AA backend (SWCanvas) renders it cleanly at every size —
  # no ragged or uneven strokes, no dropouts — because the icon is smart about
  # how it uses its space and aligns integer-width strokes to the grid per
  # size. The same discipline makes the HTML5-canvas render neater too (AA
  # itself was never a defect).
  #
  # The GEOMETRY is pixel-aligned; the RENDERING is each backend's business.
  # Icon code issues standard drawing commands — rects, the direct-call shape
  # vocabulary (fillCircle / fillStadium / fillRoundRect / strokeCircle /
  # strokeLine — SWCanvas's dedicated crisp rasterizers, path-based polyfills
  # on the native context; docs/architecture/integer-pixel-placement-and-
  # sizing.md §7), and plain paths for oblique edges and free curves — and
  # lets each backend rasterize them: SWCanvas non-AA, native AA. The two
  # backends therefore need not (and generally do not) produce identical
  # pixels; re-implementing a rasterization algorithm in icon code to force
  # them to agree duplicates the engine and is a defect. Only an EXTRA-SMALL
  # feature (a few pixels, where no drawing command expresses the intended
  # pixel placement) may be hand-placed as fillRect runs — such a feature may
  # happen to coincide across backends, which is fine but never the goal.
  #
  # Subclasses implement _paintSizeAware (all drawing) and typically follow the
  # reference implementation's shape: a metrics method computing every shared
  # measurement (line units, inner square, named-fraction layout) and one named
  # painter per visual region.

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return undefined unless keyValues?
    [damageBox,sl,st,al,at,w,h] = keyValues

    # the icon art (_paintSizeAware) sets its own colours, so the shadow pass renders it to
    # a scratch and blits the black silhouette (the shadow-pass paint contract). In that
    # scratch the LIGHT role ERASES coverage (see _useLight): the halo and the light
    # interiors are visually background, so the icon's shadow is its dark line-work —
    # never the fat halo-envelope blob.
    if appliedShadow?
      @_paintDamagedAreaAsBlackSilhouette aContext, al, at, w, h, appliedShadow, (sctx) =>
        @_paintingSilhouette = true
        try
          @_paintColoredIcon sctx, al, at, w, h
        finally
          @_paintingSilhouette = false
      return

    @_paintColoredIcon aContext, al, at, w, h
    return undefined

  _paintColoredIcon: (aContext, al, at, w, h) ->
    aContext.save()

    # clip out the damage rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = @widget.alpha

    [x0, y0, wDev, hDev] = @_paintBoxInDevicePx()

    # a glyph square is a clip too: inside it the art must be pixel for pixel
    # this icon at size g, which is what a g x g widget box paints -- clipped by
    # its own bounds. (Unclipped, the bin at g = 20 overhangs its square by a
    # halo row.)
    aContext.clipToRectangle x0, y0, wDev, hDev if @widget.glyphSize?

    # deliberately NO useLogicalPixelsUntilRestore(): subclasses draw in
    # integer DEVICE pixels, anchored to the paint box's origin — never to the
    # damage rect's corner (al/at), which shifts under partial repaints.
    @_paintSizeAware aContext, x0, y0, wDev, hDev

    aContext.restore()

  # THE BOX my art is painted into, as integer DEVICE px [x0, y0, wDev, hDev].
  # _paintColoredIcon is its one reader, and both the normal pass and the
  # shadow-pass silhouette run that, so a glyph's shadow is cast by exactly the
  # art it shadows.
  #   No glyphSize (a desktop icon, a toolbar thumbnail): my widget's WHOLE box,
  # and each subclass centres its own square in it with Math.floor in device px
  # -- which a non-square box such as the desktop's 95x60 icon band relies on.
  #   A glyphSize (a chrome button sized to its whole slot, ruling G3 -- see
  # IconButtonWdgt.glyphSize): the g x g square, g = min(glyphSize, width,
  # height) logical px, centred in my box the way calculateRectangleOfIcon
  # centres a legacy glyph (Math.round of the logical offset). It is computed
  # here in integers rather than read from calculateRectangleOfIcon, which
  # aspect-fits through preferredSize: g/100*100 is not exact in floating point
  # for every g, so a .5 offset can tip the other way and the box comes back a
  # pixel too wide (g = 14 in a 15 px box comes back 15 wide).
  #   The widget's bounds are integer logical px (integer-placement policy) and
  # g is rounded, so every product is an exact integer.
  _paintBoxInDevicePx: ->
    left = @widget.left()
    top = @widget.top()
    width = @widget.width()
    height = @widget.height()
    if @widget.glyphSize?
      side = Math.round Math.min @widget.glyphSize, width, height
      left = Math.round left + (width - side) / 2
      top = Math.round top + (height - side) / 2
      width = height = side
    [left * ceilPixelRatio, top * ceilPixelRatio, width * ceilPixelRatio, height * ceilPixelRatio]

  # subclass responsibility: all-integer device-pixel drawing into the
  # (x0, y0, wDev, hDev) box _paintBoxInDevicePx hands over
  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->

  # ---- colour roles --------------------------------------------------------
  # Every painter picks its colour through these — the ONE choke point that
  # keeps the shadow pass honest about the halo. Painting normally, they just
  # set fill/stroke style to the role's colour. Painting the shadow-pass
  # silhouette scratch (_paintingSilhouette), the LIGHT role switches the
  # context to destination-out so light paint ERASES coverage: the halo and
  # the light interiors are visually background, not ink, so they must not
  # cast shadow — the border idiom's "ink silhouette, then light interior"
  # then leaves exactly the dark line-work in the silhouette. Order matters
  # and the painters already honour it (halos before ink erase nothing;
  # interiors after ink punch through). DETAIL colours (literal greys/whites
  # drawn as visible content) count as coverage, like ink.

  _useInk: (ctx) ->
    ctx.globalCompositeOperation = 'source-over' if @_paintingSilhouette
    s = @_iconColorString()
    ctx.fillStyle = s
    ctx.strokeStyle = s

  _useLight: (ctx) ->
    ctx.globalCompositeOperation = 'destination-out' if @_paintingSilhouette
    s = @_outlineColorString()
    ctx.fillStyle = s
    ctx.strokeStyle = s

  _useDetail: (ctx, colorString) ->
    ctx.globalCompositeOperation = 'source-over' if @_paintingSilhouette
    ctx.fillStyle = colorString

  # ---- pixel-drawing vocabulary --------------------------------------------

  # four t-thick filled edges — the crisp replacement for a stroked rect
  _pxBorder: (ctx, x, y, w, h, t) ->
    ctx.fillRect x, y, w, t
    ctx.fillRect x, y + h - t, w, t
    ctx.fillRect x, y + t, t, h - 2 * t
    ctx.fillRect x + w - t, y + t, t, h - 2 * t

  # a rounded-rect PANEL: light halo envelope (expanded o), ink round-rect,
  # light interior inset by the border thickness tb. The corner radius tracks
  # each inset, so all four corners stay concentric and the ring reads tb
  # thick all the way around. Shared by the shortcut-arrow badge and the
  # slide-card family.
  _pxPanel: (ctx, x, y, w, h, r, tb, o) ->
    @_useLight ctx
    ctx.fillRoundRect x - o, y - o, w + 2 * o, h + 2 * o, r + o
    @_useInk ctx
    ctx.fillRoundRect x, y, w, h, r
    @_useLight ctx
    ctx.fillRoundRect x + tb, y + tb, w - 2 * tb, h - 2 * tb, Math.max 0, r - tb

  # the slide-card panel itself: the landscape rounded card of the family's
  # original 100-space drawings (ink rect 9..92 x 20..80, ~6-unit corner),
  # scaled to the glyph square S and painted through _pxPanel with border t.
  # Returns [px, py, pw, ph, r] -- the card's ink rect and corner radius --
  # for callers that lay out against it.
  SLIDE_CARD_L: 0.09
  SLIDE_CARD_T: 0.20
  SLIDE_CARD_R: 0.92
  SLIDE_CARD_B: 0.80
  SLIDE_CARD_RADIUS: 0.06
  _pxSlideCard: (ctx, x, y, S, t, o) ->
    px = x + Math.round S * @SLIDE_CARD_L
    py = y + Math.round S * @SLIDE_CARD_T
    pw = Math.round(S * @SLIDE_CARD_R) - Math.round(S * @SLIDE_CARD_L)
    ph = Math.round(S * @SLIDE_CARD_B) - Math.round(S * @SLIDE_CARD_T)
    r = Math.max t, Math.round(S * @SLIDE_CARD_RADIUS)
    @_pxPanel ctx, px, py, pw, ph, r, t, o
    [px, py, pw, ph, r]
