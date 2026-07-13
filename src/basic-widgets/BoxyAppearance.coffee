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

    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil

    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.alpha

    aContext.useLogicalPixelsUntilRestore()
    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y
    if !@widget.color? then debugger
    aContext.fillStyle = @widget.color.toString()
    
    if appliedShadow?
      aContext.fillStyle = Color.BLACK.toString()

    aContext.beginPath()
    @outlinePath aContext, @getCornerRadius(), false
    aContext.closePath()
    aContext.fill()

    if @widget.strokeColor? and !appliedShadow?
      aContext.lineWidth = 1 # TODO might look better if * ceilPixelRatio
      aContext.strokeStyle = @widget.strokeColor.toString()
      aContext.beginPath()
      @outlinePath aContext, @getCornerRadius(), true
      aContext.closePath()
      aContext.stroke()

    aContext.restore()

    # paintHighlight is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @paintHighlight aContext, al, at, w, h

  
  outlinePath: (context, radius, isStroke) ->
    offset = radius
    # in order to be crisp, strokes have to be displaced a bit
    # (while fills don't, they'd look fuzzy instead).
    # Note that the curved corners will be drawn with antialiasing,
    # which for small dimensions and/or for small curvatures looks messy.
    # There is really no way to disable antialiasing when drawing
    # vector graphics (see:
    # https://stackoverflow.com/questions/195262/can-i-turn-off-antialiasing-on-an-html-canvas-element
    # ). A possible solution is to detect when you are
    # drawing small components (somehow track the scale that it's drawn at)
    # and small radius, and in those cases avoid to paint the arc, but
    # rather fiddle with pixels individually (following the equation of the
    # circle or just manually pixel-painting the curve).
    if isStroke
      offset += 0.5
    w = @widget.width()
    h = @widget.height()
    # top left (from -180 to -90 degrees):
    context.arc offset, offset, radius, -Math.PI, -Math.PI/2
    # top right (from -90 to 0 degrees):
    context.arc w - offset, offset, radius, -Math.PI/2, 0
    # bottom right (from 0 to 90 degrees):
    context.arc w - offset, h - offset, radius, 0, Math.PI/2
    # bottom left (from 90 to 180 degrees):
    context.arc offset, h - offset, radius, Math.PI/2, Math.PI

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
    # »>> this part is excluded from the fizzygum homepage build
    menu.addMenuItem "pick inset...", @widget, "doNothingInsetsFunctionalityHasBeenRemoved", toolTip: "put a widget as inset"
    # this part is excluded from the fizzygum homepage build <<«
    menu
  
  addShapeSpecificNumericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    if !menuEntriesStrings?
      menuEntriesStrings = []
      functionNamesStrings = []
    menuEntriesStrings.push "corner radius"
    functionNamesStrings.push "setCornerRadius"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings
