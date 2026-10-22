class BoxyAppearance extends Appearance

  # MY WIDGET'S ROUNDING, `@widget.cornerRadius`, comes in two shapes, both read the way HTML5's
  # roundRect() reads its radii:
  #   a number   every corner rounded alike (absent: my default, 4)
  #   a 4-array  per-corner radii [topLeft, topRight, bottomRight, bottomLeft], CSS border-radius
  #              order, so `[7, 7, 0, 0]` rounds only the top corners (a window's title bar)
  # The user-facing setter (Widget.setCornerRadius, the prompt and the pin) stays scalar: per-corner
  # radii are a decision of the code that builds a widget, not a dial.

  # TWO KNOBS a clipping widget sets on its appearance INSTANCE (both off by default; a frame sets
  # both from its look, FrameWdgt._deriveAndSetBodyAppearance). Set, each is an own field of the
  # instance, so it is saved and copied with the appearance; a fresh appearance starts with both off.
  #   strokesOverChildren      my outline is painted OVER the widget's content rather than under
  #                            it; see _strokesAfterChildren.
  #   clipsChildrenToOutline   the widget clips its children to my ROUNDED outline rather than to
  #                            its rectangle; FrameWdgt._roundedChildClipRadii reads it, and the
  #                            outline below (outlineCornerRadii, clipToOutline) is the clip.
  strokesOverChildren: false
  clipsChildrenToOutline: false

  # A RULE ALONG ONE OF MY EDGES -- a band's own edge (redesign plan §2, rule D: the line is part of
  # the band's look whatever its neighbour is, like CSS's border-bottom; a SEAM between two panes is
  # the other mechanism, Widget._seamRects). Three fields of the instance, all set together by the
  # code that shapes the band (FrameBarWdgt shapes a frame's strip):
  #   ruledEdge   "top" | "right" | "bottom" | "left", or undefined for no rule
  #   ruleColor   its ink
  #   ruleWidth   its thickness, in logical pixels
  # The rule lies INSIDE my box, along that edge, painted over my fill and under my stroke, in the
  # normal pass only: it is part of my look, not of my silhouette. Set, each is an own field of the
  # instance, so a saved or copied appearance keeps its rule; a fresh appearance has none.
  #   ⚠ The rule is a straight band across the whole edge, so the two corners at its ends should
  # be square: a rounded one would show the rule cutting straight across its curve.
  ruledEdge: undefined
  ruleColor: undefined
  ruleWidth: 1

  # ONE number, for the readers that want one (the "Corner radius…" prompt's default,
  # BubblyAppearance's outline): the uniform radius as stored, or the LARGEST of per-corner radii.
  getCornerRadius: ->
    if Array.isArray @widget.cornerRadius
      Math.max @_cornerRadii()...
    else
      @widget.cornerRadius ? 4

  # THE ONE NORMALISER of my rounding: the four corner radii [topLeft, topRight, bottomRight,
  # bottomLeft], each clamped to >= 0, whichever shape the widget stores. Every reader that needs
  # the corners one by one comes through here.
  _cornerRadii: ->
    radius = @widget.cornerRadius ? 4
    if Array.isArray radius
      [topLeft, topRight, bottomRight, bottomLeft] = radius
      [(Math.max topLeft, 0), (Math.max topRight, 0), (Math.max bottomRight, 0), (Math.max bottomLeft, 0)]
    else
      radius = Math.max radius, 0
      [radius, radius, radius, radius]

  # What my outline hands fillRoundRect / strokeRoundRect. ⚠ A uniform radius goes as the SCALAR
  # getCornerRadius answers, never as an array: a widget without per-corner radii makes the plain
  # scalar call (SWCanvas's scalar entry), and only per-corner radii travel as the normalised 4-array.
  _roundRectRadii: ->
    if Array.isArray @widget.cornerRadius then @_cornerRadii() else @getCornerRadius()

  constructor: (widget) ->
    super widget

  # The rounded box, corner by corner: a logical pixel is mine iff its pixel CENTRE lies inside the
  # outline fillOutline draws (the one test, roundedBoxContainsPixelCentreOf below). A big radius
  # therefore leaves a genuinely pointer-through notch at each rounded corner
  # (SystemTest_macroRoundedBoxCornerClickThrough is exactly that).
  shapeContainsPoint: (aPoint) ->
    # TOTAL (see Appearance): nothing outside my bounds is mine
    if !@widget.boundsContainPoint aPoint
      return false
    BoxyAppearance.roundedBoxContainsPixelCentreOf (aPoint.subtract @widget.position()), @widget.width(), @widget.height(), @_cornerRadii()

  # THE ROUNDED-BOX HIT TEST, the one every rounded shape asks (my shape above, and a desktop
  # icon's tile and plate, DesktopIconAppearance): does the logical pixel that `localPoint` falls in
  # belong to the w×h box at the origin, rounded at `radii` ([topLeft, topRight, bottomRight,
  # bottomLeft], each >= 0, as fillRoundRect takes them)? It does iff its pixel CENTRE lies inside
  # the box and inside the rounded outline -- the box minus, at each corner, whatever lies outside
  # that corner's quarter-circle (a 0 corner is square). Testing the CENTRE makes the hit shape the
  # FILLED pixels (SWCanvas's fill samples pixel centres too, so at dpr 1 the two agree pixel for
  # pixel) and makes all four corners alike. Asked of the CLASS: it needs only the box, not a widget
  # wearing me.
  #   The radii are fitted to the box as roundRect() fits them: when two corners on one side add up
  # to more than that side, all four shrink by the one factor that makes the tightest side fit.
  @roundedBoxContainsPixelCentreOf: (localPoint, w, h, radii) ->
    # the centre of the logical pixel the point falls in
    x = Math.floor(localPoint.x) + 0.5
    y = Math.floor(localPoint.y) + 0.5
    return false unless 0 < x < w and 0 < y < h

    [topLeft, topRight, bottomRight, bottomLeft] = radii
    sideFit = (side, sumOfTwoCorners) ->
      if sumOfTwoCorners > 0 then side / sumOfTwoCorners else 1
    fit = Math.min 1,
      (sideFit w, topLeft + topRight), (sideFit h, topRight + bottomRight),
      (sideFit w, bottomRight + bottomLeft), (sideFit h, bottomLeft + topLeft)
    if fit < 1
      topLeft *= fit
      topRight *= fit
      bottomRight *= fit
      bottomLeft *= fit

    # a corner cuts that centre off iff it lies past the corner's arc centre on BOTH axes (in the
    # corner's radius-sized square) and farther than the radius from it; outX / outY measure how far
    # past, toward the corner
    cutOff = (radius, outX, outY) ->
      outX > 0 and outY > 0 and outX * outX + outY * outY > radius * radius

    if cutOff topLeft, topLeft - x, topLeft - y
      return false
    if cutOff topRight, x - (w - topRight), topRight - y
      return false
    if cutOff bottomRight, x - (w - bottomRight), y - (h - bottomRight)
      return false
    if cutOff bottomLeft, bottomLeft - x, y - (h - bottomLeft)
      return false

    return true

  # The inscribed box: the straight edges between the corners fill crisply to the bounds, and
  # the corner areas are cut away by the rounding (anti-aliased on native, hard-edged on
  # SWCanvas) -> inset every side by the LARGEST corner radius + 1, conservatively.
  opaqueCoveredRect: ->
    @widget.boundingBox().insetBy Math.max(@_cornerRadii()...) + 1

  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localDamageBox) =>
      if !@widget.color? then debugger
      ctx.fillStyle = @widget.color.toString()

      if appliedShadow?
        ctx.fillStyle = WorldWdgt.theme.shadowColor.toString()

      @fillOutline ctx

      # the rules between my widget's panes, then the rule along my own edge: over my fill, under
      # its children and my stroke
      if !appliedShadow?
        @_paintSeamRules ctx, localDamageBox
        @_paintEdgeRule ctx, localDamageBox

      # THE STROKE, EXACTLY ONCE PER PAINT and never in the shadow pass: here, over my fill —
      # unless it is painted after my widget's children instead (_strokesAfterChildren).
      if !appliedShadow? and !@_strokesAfterChildren()
        @_strokeOutlineInStrokeColor ctx

  # My edge rule (ruledEdge), filled over the part of it being repainted, inside an open scope. A
  # fill, so it may be sized to the damage box; where it lies is my widget's own edge.
  _paintEdgeRule: (ctx, localDamageBox) ->
    rule = @_edgeRuleRect()
    return unless rule?
    toBePainted = rule.intersect localDamageBox
    return unless toBePainted.isNotEmpty()
    ctx.fillStyle = @ruleColor.toString()
    @_fillLocalRectSnappedToDevicePixels ctx, toBePainted

  # The widget-local rect my rule fills -- ruleWidth thick, along ruledEdge, the whole length of
  # that edge -- or undefined when I carry no rule.
  _edgeRuleRect: ->
    return undefined unless @ruledEdge? and @ruleColor?
    w = @widget.width()
    h = @widget.height()
    switch @ruledEdge
      when "top" then new Rectangle 0, 0, w, @ruleWidth
      when "right" then new Rectangle w - @ruleWidth, 0, w, h
      when "bottom" then new Rectangle 0, h - @ruleWidth, w, h
      when "left" then new Rectangle 0, 0, @ruleWidth, h

  # Is my stroke painted AFTER my widget's children rather than with my fill? Only when I am asked
  # to stroke over them (strokesOverChildren) AND my widget clips its children
  # (ClippingAtRectangularBoundsMixin: every frame) — the mixin's after-children call is what
  # reaches paintStroke below. Then the children paint over my fill and the 1 px outline over them.
  # Otherwise a clipping widget's children paint over my outline.
  _strokesAfterChildren: ->
    @strokesOverChildren and @widget.clipsAtRectangularBounds

  # My after-children stroke: ClippingAtRectangularBoundsMixin calls it (through Widget.paintStroke)
  # once my widget's children have all painted, and only in the normal pass. It paints only when
  # _strokesAfterChildren, so the base paint has not stroked already. A standalone entry, so it
  # opens its own scope — local logical coordinates, clipped to the damage box.
  #   ⚠ That `undefined` is the appliedShadow VALUE — "no shadow", the normal pass — not a skip to
  # reach the block: every caller of _paintInLocalScope passes all four arguments, because the
  # trailing bodyFn is required. It is NOT a hole under R3
  # (docs/architecture/constructor-and-parameter-conventions.md) — the same value
  # RectangularAppearance.paintStroke hands its scope; buildSystem/check-argument-holes.js counts it
  # because a regex cannot tell an absent value from a skipped parameter.
  paintStroke: (aContext, clippingRectangle) ->
    return unless @_strokesAfterChildren()
    @_paintInLocalScope aContext, clippingRectangle, undefined, (ctx) =>
      @_strokeOutlineInStrokeColor ctx

  # The one stroke body both entries share, inside an open scope: the 1-LOGICAL-px outline in my
  # widget's strokeColor (no strokeColor, no stroke). It goes through strokeOutline, so a subclass
  # with its own outline (BubblyAppearance) strokes that one from either entry.
  _strokeOutlineInStrokeColor: (ctx) ->
    return unless @widget.strokeColor?
    ctx.lineWidth = 1
    ctx.strokeStyle = @widget.strokeColor.toString()
    @strokeOutline ctx


  # Fill / stroke the rounded-box outline through the direct rounded-rect calls
  # (CanvasRenderingContext2D-extensions.coffee): SWCanvas's dedicated fast
  # rasterizers on the software backend, a roundRect() path on native. One
  # spelling covers every backend/dpr combination — the fill spans exactly the
  # widget box, and the 1-logical-px stroke path is inset half a logical pixel
  # so the stroke covers precisely the boundary pixel ring (the standard HTML5
  # crisp-stroke idiom; strokes need the displacement, fills would just look
  # fuzzy from it). On native the curved corners anti-alias; on SWCanvas they
  # are hard-edged. Per-corner radii ride the same two calls (both take
  # HTML5 roundRect() radii). BubblyAppearance overrides BOTH of these with
  # its generic-path speech-bubble outline.
  fillOutline: (context) ->
    context.fillRoundRect 0, 0, @widget.width(), @widget.height(), @_roundRectRadii()

  strokeOutline: (context) ->
    context.strokeRoundRect 0.5, 0.5, @widget.width() - 1, @widget.height() - 1, @_roundRectRadii()

  # ===== my outline as a CLIP, for a widget that clips its children to it =====
  # FrameWdgt's rounded child clip (redesign plan §3a option (a)) reads these two while my
  # clipsChildrenToOutline knob is on. ⚠ BubblyAppearance inherits them although its outline is not
  # a roundRect: no bubble clips its children, and one that did would have to re-answer both, as it
  # re-answers fillOutline / strokeOutline.

  # The per-corner radii of my outline, [topLeft, topRight, bottomRight, bottomLeft], as declared
  # (before roundRect() shrinks them to fit a box too small for them). A corner of radius r leaves
  # my box only inside its r×r corner square, which is what the reader needs them for.
  outlineCornerRadii: ->
    @_cornerRadii()

  # Does my widget's body draw a 1 px border along that outline? Exactly when it has a strokeColor
  # (_strokeOutlineInStrokeColor strokes nothing without one). A ring laid over a selected widget
  # strokes the outline too when it does (Widget._drawSelectionOverlay,
  # HighlightOutlineAppearance.paintRing), so the border's corner pixels stay inside the ring.
  outlineIsStroked: ->
    @widget.strokeColor?

  # Intersect aContext's clip with exactly the pixels fillOutline fills, so whatever is painted next
  # shows only inside my outline. The path is traced under the matrix fillOutline paints under
  # (logical pixels, translated to my widget) and the clip is set AFTER that matrix is restored: a
  # path's points are fixed in device space as they are added, and the current path is not part of
  # the saved drawing state. So the clip lands where my fill lands while aContext keeps exactly the
  # matrix it came in with — the one a clipping widget's children then paint under, whatever that
  # matrix carries (a back buffer's or an island buffer's offset, the shadow pass's translate).
  #   Measured on SWCanvas (spike S1b, redesign plan §3a): the clip covers exactly my fill's
  # pixels for every integer-placed box at dpr 1 and 2, at every integer offset the context
  # carries. A box at a FRACTIONAL plane position (a payload dropped into a rotated container)
  # can differ from the fill on a few pixels of the curve: the fill flattens its arcs in my local
  # space, this path flattens them as it is traced.
  clipToOutline: (aContext) ->
    aContext.save()
    aContext.useLogicalPixelsUntilRestore()
    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y
    aContext.beginPath()
    aContext.roundRect 0, 0, @widget.width(), @widget.height(), @_roundRectRadii()
    aContext.restore()
    aContext.clip()

  cornerRadiusPopout: (menuItem)->
    # ⚠ through the GETTER, which owns the absent case: this appearance is worn by widgets that
    # never declare a cornerRadius of their own (a frame, a folder window), and reading the field
    # raw threw on every click of this item for those.
    @widget.prompt menuItem.parent.promptTitleAsking("corner\nradius:"), @widget, "setCornerRadius",
      defaultContents: @getCornerRadius().toString()
      floorNum: 0
      ceilingNum: 100
      isRounded: true
  
  # Boxy menus:
  addShapeSpecificMenuItems: (menu) ->
    menu.addLine()
    menu.addMenuItem "Corner radius…", @, "cornerRadiusPopout", toolTip: "set the corner's\nradius"
    menu
  
  # The pins my SHAPE contributes to the widget wearing me (Widget.pins concatenates them). Write-only:
  # I do have a getCornerRadius, but it is a method on ME and a pin's reader is dispatched on the
  # WIDGET (`node[pin.getterName]()`), where no such method exists — the setter's twin, `setCornerRadius`,
  # is on Widget. Declaring `get: "getCornerRadius"` here would name a method the reader cannot reach.
  pins: ->
    [ new PinSpec "corner radius", "numerical", set: "setCornerRadius" ]
