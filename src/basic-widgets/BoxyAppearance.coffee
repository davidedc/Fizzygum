class BoxyAppearance extends Appearance

  getCornerRadius: ->
    if @widget.cornerRadius?
      return @widget.cornerRadius
    else
      return 4

  constructor: (widget) ->
    super widget

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@widget.boundsContainPoint aPoint
      return true
 
    thisWidgetPosition = @widget.position()
    radius = Math.max @getCornerRadius(), 0
 
    relativePoint = new Point aPoint.x - thisWidgetPosition.x, aPoint.y - thisWidgetPosition.y

    # top left corner
    if relativePoint.x < radius and relativePoint.y < radius
      if relativePoint.distanceTo(new Point radius,radius) > radius
        return true

    # top right corner
    else if relativePoint.x > @widget.width() - radius and relativePoint.y < radius
      if relativePoint.distanceTo(new Point @widget.width() - radius,radius) > radius
        return true

    # bottom left corner
    else if relativePoint.x < radius and relativePoint.y > @widget.height() - radius
      if relativePoint.distanceTo(new Point radius, @widget.height() - radius) > radius
        return true

    # bottom right corner
    else if relativePoint.x > @widget.width() - radius and relativePoint.y > @widget.height() - radius
      if relativePoint.distanceTo(new Point @widget.width() - radius, @widget.height() - radius) > radius
        return true


    return false
  
  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return nil unless keyValues?
    [area,sl,st,al,at,w,h] = keyValues

    @_beginLogicalPixelsBox aContext, appliedShadow, al, at, w, h
    if !@widget.color? then debugger
    aContext.fillStyle = @widget.color.toString()
    
    if appliedShadow?
      aContext.fillStyle = Color.BLACK.toString()

    @fillOutline aContext

    if @widget.strokeColor? and !appliedShadow?
      aContext.lineWidth = 1 # TODO might look better if * ceilPixelRatio
      aContext.strokeStyle = @widget.strokeColor.toString()
      @strokeOutline aContext

    aContext.restore()

    # _drawHighlightOverlay is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @_drawHighlightOverlay aContext, al, at, w, h

  
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
    @widget.prompt menuItem.parent.title + "\ncorner\nradius:",
      @widget,
      "setCornerRadius",
      @widget.cornerRadius.toString(),
      nil,
      0,
      100,
      true
  
  # Boxy menus:
  addShapeSpecificMenuItems: (menu) ->
    menu.addLine()
    menu.addMenuItem "corner radius...", @, "cornerRadiusPopout", toolTip: "set the corner's\nradius"
    menu
  
  addShapeSpecificNumericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    if !menuEntriesStrings?
      menuEntriesStrings = []
      functionNamesStrings = []
    menuEntriesStrings.push "corner radius"
    functionNamesStrings.push "setCornerRadius"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings
