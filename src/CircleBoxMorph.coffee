# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders

class CircleBoxMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  orientation: null
  autoOrient: true

  constructor: (@orientation = "vertical") ->
    super()
    @silentRawSetExtent new Point 20, 100

  
  autoOrientation: ->
    if @height() > @width()
      @orientation = "vertical"
    else
      @orientation = "horizontal"


  calculateKeyPoints: ->
    @autoOrientation()  if @autoOrient
    if @orientation is "vertical"
      radius = @width() / 2
      x = @center().x
      center1 = new Point(x, @top() + radius).round()
      center2 = new Point(x, @bottom() - radius).round()
      rect = @topLeft().add(
        new Point(0, radius)).corner(@bottomRight().subtract(new Point(0, radius)))
    else
      radius = @height() / 2
      y = @center().y
      center1 = new Point(@left() + radius, y).round()
      center2 = new Point(@right() - radius, y).round()
      rect = @topLeft().add(
        new Point(radius, 0)).corner(@bottomRight().subtract(new Point(radius, 0)))
    return [radius,center1,center2,rect]

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@boundsContainPoint aPoint
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
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

    if @preliminaryCheckNothingToDraw false, clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null

      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = @alpha

      aContext.scale pixelRatio, pixelRatio
      morphPosition = @position()
      aContext.translate morphPosition.x, morphPosition.y

      [radius,center1,center2,rect] = @calculateKeyPoints()

      # the centers of two circles
      points = [center1.toLocalCoordinatesOf(@), center2.toLocalCoordinatesOf(@)]

      aContext.fillStyle = @color.toString()
      aContext.beginPath()

      # the two circles (one at each end)
      aContext.arc points[0].x, points[0].y, radius, 0, 2 * Math.PI, false
      aContext.arc points[1].x, points[1].y, radius, 0, 2 * Math.PI, false
      # the rectangle
      rect = rect.floor()
      rect = rect.toLocalCoordinatesOf @
      aContext.moveTo rect.origin.x, rect.origin.y
      aContext.lineTo rect.origin.x + rect.width(), rect.origin.y
      aContext.lineTo rect.origin.x + rect.width(), rect.origin.y + rect.height()
      aContext.lineTo rect.origin.x, rect.origin.y + rect.height()

      aContext.closePath()
      aContext.fill()

      aContext.restore()
      @paintHighlight aContext, al, at, w, h

  
  # CircleBoxMorph menu:
  developersMenu: ->
    menu = super()
    menu.addLine()
    # todo Dan Ingalls did show a neat demo where the
    # boxmorph was automatically changing the orientation
    # when resized, following the main direction.
    if @orientation is "vertical"
      menu.addItem "make horizontal", true, @, "toggleOrientation", "toggle the\norientation"
    else
      menu.addItem "make vertical", true, @, "toggleOrientation", "toggle the\norientation"
    menu
  
  toggleOrientation: ->
    center = @center()
    if @orientation is "vertical"
      @orientation = "horizontal"
    else
      @orientation = "vertical"
    @silentRawSetExtent new Point @height(), @width()
    @fullRawMoveCenterTo center
    @changed()
