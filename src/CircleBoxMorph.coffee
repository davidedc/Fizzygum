# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders
# REQUIRES BackingStoreMixin

class CircleBoxMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  orientation: null
  autoOrient: true

  constructor: (@orientation = "vertical") ->
    super()
    @silentSetExtent new Point(20, 100)

  
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
      rect = @bounds.origin.add(
        new Point(0, radius)).corner(@bounds.corner.subtract(new Point(0, radius)))
    else
      radius = @height() / 2
      y = @center().y
      center1 = new Point(@left() + radius, y).round()
      center2 = new Point(@right() - radius, y).round()
      rect = @bounds.origin.add(
        new Point(radius, 0)).corner(@bounds.corner.subtract(new Point(radius, 0)))
    return [radius,center1,center2,rect]

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@bounds.containsPoint aPoint
      return true

    [radius,center1,center2,rect] = @calculateKeyPoints()

    if center1.distanceTo(aPoint) < radius or
    center2.distanceTo(aPoint) < radius or
    rect.containsPoint aPoint
      return false

    return true
  
  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by recursivelyBlit, which
  # eventually invokes blit.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  blit: (aCanvas, clippingRectangle) ->
    return null  if @isMinimised or !@isVisible
    area = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if area.isNotEmpty()
      delta = @position().neg()
      src = area.copy().translateBy(delta).round()
      context = aCanvas.getContext("2d")
      sl = src.left() * pixelRatio
      st = src.top() * pixelRatio
      al = area.left() * pixelRatio
      at = area.top() * pixelRatio
      w = Math.min(src.width() * pixelRatio, @width() * pixelRatio - sl)
      h = Math.min(src.height() * pixelRatio, @height() * pixelRatio - st)
      return null  if w < 1 or h < 1

      # initialize my surface property
      #@image = newCanvas(@extent().scaleBy pixelRatio)
      #context = @image.getContext("2d")
      #context.scale pixelRatio, pixelRatio

      context.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      context.beginPath()
      context.moveTo(Math.round(al), Math.round(at))
      context.lineTo(Math.round(al) + Math.round(w), Math.round(at))
      context.lineTo(Math.round(al) + Math.round(w), Math.round(at) + Math.round(h))
      context.lineTo(Math.round(al), Math.round(at) + Math.round(h))
      context.lineTo(Math.round(al), Math.round(at))
      context.closePath()
      context.clip()

      context.globalAlpha = @alpha

      context.scale pixelRatio, pixelRatio
      morphPosition = @position()
      context.translate morphPosition.x, morphPosition.y

      [radius,center1,center2,rect] = @calculateKeyPoints()

      # the centers of two circles
      points = [center1.subtract(@bounds.origin), center2.subtract(@bounds.origin)]

      context.fillStyle = @color.toString()
      context.beginPath()

      # the two circles (one at each end)
      context.arc points[0].x, points[0].y, radius, 0, 2 * Math.PI, false
      context.arc points[1].x, points[1].y, radius, 0, 2 * Math.PI, false
      # the rectangle
      rect = rect.floor()
      rect = rect.translateBy(@bounds.origin.neg())
      context.moveTo rect.origin.x, rect.origin.y
      context.lineTo rect.origin.x + rect.width(), rect.origin.y
      context.lineTo rect.origin.x + rect.width(), rect.origin.y + rect.height()
      context.lineTo rect.origin.x, rect.origin.y + rect.height()

      context.closePath()
      context.fill()

      context.restore()

  
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
    @changed()
    if @orientation is "vertical"
      @orientation = "horizontal"
    else
      @orientation = "vertical"
    @silentSetExtent new Point(@height(), @width())
    @setCenter center
    @updateBackingStore()
    @changed()
