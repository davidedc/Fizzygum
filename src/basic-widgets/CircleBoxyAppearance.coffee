class CircleBoxyAppearance extends Appearance

  constructor: (morph) ->
    super morph

  autoOrientation: ->
    if @morph.height() > @morph.width()
      return "vertical"
    else
      return "horizontal"


  calculateKeyPoints: ->
    orientation = @autoOrientation()
    if orientation is "vertical"
      radius = @morph.width() / 2
      x = @morph.center().x
      center1 = new Point(x, @morph.top() + radius).round()
      center2 = new Point(x, @morph.bottom() - radius).round()
      rect = @morph.topLeft().add(
        new Point(0, radius)).corner(@morph.bottomRight().subtract(new Point(0, radius)))
    else
      radius = @morph.height() / 2
      y = @morph.center().y
      center1 = new Point(@morph.left() + radius, y).round()
      center2 = new Point(@morph.right() - radius, y).round()
      rect = @morph.topLeft().add(
        new Point(radius, 0)).corner(@morph.bottomRight().subtract(new Point(radius, 0)))
    return [radius,center1,center2,rect]

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@morph.boundsContainPoint aPoint
      return true

    [radius,center1,center2,rect] = @calculateKeyPoints()

    if center1.distanceTo(aPoint) < radius or
    center2.distanceTo(aPoint) < radius or
    rect.containsPoint aPoint
      return false

    return true
  
  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @morph.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil

    [area,sl,st,al,at,w,h] = @morph.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @morph.alpha

    aContext.useLogicalPixelsUntilRestore()
    morphPosition = @morph.position()
    aContext.translate morphPosition.x, morphPosition.y

    [radius,center1,center2,rect] = @calculateKeyPoints()

    # the centers of two circles
    points = [center1.toLocalCoordinatesOf(@morph), center2.toLocalCoordinatesOf(@morph)]

    color = @morph.color

    if appliedShadow?
      aContext.fillStyle = "black"
    else
      aContext.fillStyle = color.toString()

    aContext.beginPath()

    # the two circles (one at each end)
    aContext.arc points[0].x, points[0].y, radius, 0, 2 * Math.PI
    aContext.arc points[1].x, points[1].y, radius, 0, 2 * Math.PI
    # the rectangle
    rect = rect.floor()
    rect = rect.toLocalCoordinatesOf @morph
    aContext.moveTo rect.origin.x, rect.origin.y
    aContext.lineTo rect.origin.x + rect.width(), rect.origin.y
    aContext.lineTo rect.origin.x + rect.width(), rect.origin.y + rect.height()
    aContext.lineTo rect.origin.x, rect.origin.y + rect.height()

    aContext.closePath()
    aContext.fill()

    aContext.restore()

    # paintHighlight is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @paintHighlight aContext, al, at, w, 
