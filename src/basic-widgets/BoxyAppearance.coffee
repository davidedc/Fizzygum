class BoxyAppearance extends Appearance

  getCornerRadius: ->
    if @widget.cornerRadius?
      return @widget.cornerRadius
    else
      return 4

  constructor: (widget) ->
    super widget

  # The rounded box: the bounding box MINUS the four quarter-disc cut-outs the rounding
  # takes off the corners. A big cornerRadius therefore leaves a genuinely pointer-through
  # notch at each corner (SystemTest_macroRoundedBoxCornerClickThrough is exactly that).
  shapeContainsPoint: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@widget.boundsContainPoint aPoint
      return false

    thisWidgetPosition = @widget.position()
    radius = Math.max @getCornerRadius(), 0

    relativePoint = new Point aPoint.x - thisWidgetPosition.x, aPoint.y - thisWidgetPosition.y

    # top left corner
    if relativePoint.x < radius and relativePoint.y < radius
      if relativePoint.distanceTo(new Point radius,radius) > radius
        return false

    # top right corner
    else if relativePoint.x > @widget.width() - radius and relativePoint.y < radius
      if relativePoint.distanceTo(new Point @widget.width() - radius,radius) > radius
        return false

    # bottom left corner
    else if relativePoint.x < radius and relativePoint.y > @widget.height() - radius
      if relativePoint.distanceTo(new Point radius, @widget.height() - radius) > radius
        return false

    # bottom right corner
    else if relativePoint.x > @widget.width() - radius and relativePoint.y > @widget.height() - radius
      if relativePoint.distanceTo(new Point @widget.width() - radius, @widget.height() - radius) > radius
        return false


    return true

  # The inscribed box: the straight edges between the corners fill crisply to the bounds, and
  # the corner areas are cut away by the rounding (anti-aliased on native, hard-edged on
  # SWCanvas) -> inset every side by cornerRadius + 1, conservatively.
  opaqueCoveredRect: ->
    @widget.boundingBox().insetBy Math.max(@getCornerRadius(), 0) + 1

  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      if !@widget.color? then debugger
      ctx.fillStyle = @widget.color.toString()

      if appliedShadow?
        ctx.fillStyle = Color.BLACK.toString()

      @fillOutline ctx

      if @widget.strokeColor? and !appliedShadow?
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
  # are hard-edged. BubblyAppearance overrides BOTH of these with its
  # generic-path speech-bubble outline.
  fillOutline: (context) ->
    context.fillRoundRect 0, 0, @widget.width(), @widget.height(), @getCornerRadius()

  strokeOutline: (context) ->
    context.strokeRoundRect 0.5, 0.5, @widget.width() - 1, @widget.height() - 1, @getCornerRadius()

  cornerRadiusPopout: (menuItem)->
    # ⚠ through the GETTER, which owns the absent case: this appearance is worn by widgets that
    # never declare a cornerRadius of their own (a frame, a folder window), and reading the field
    # raw threw on every click of this item for those.
    @widget.prompt menuItem.parent.popUpTitle() + "\ncorner\nradius:", @widget, "setCornerRadius",
      defaultContents: @getCornerRadius().toString()
      floorNum: 0
      ceilingNum: 100
      isRounded: true
  
  # Boxy menus:
  addShapeSpecificMenuItems: (menu) ->
    menu.addLine()
    menu.addMenuItem "corner radius...", @, "cornerRadiusPopout", toolTip: "set the corner's\nradius"
    menu
  
  # The pins my SHAPE contributes to the widget wearing me (Widget.pins concatenates them). Write-only:
  # I do have a getCornerRadius, but it is a method on ME and a pin's reader is dispatched on the
  # WIDGET (`node[pin.getterName]()`), where no such method exists — the setter's twin, `setCornerRadius`,
  # is on BoxWdgt. Declaring `get: "getCornerRadius"` here would name a method the reader cannot reach.
  pins: ->
    [ new PinSpec "corner radius", "numerical", set: "setCornerRadius" ]
