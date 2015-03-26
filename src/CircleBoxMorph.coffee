# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders
# REQUIRES BackingStoreMixin

class CircleBoxMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith BackingStoreMixin

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
  
  # no changes of position or extent
  updateBackingStore: ->
    @autoOrientation()  if @autoOrient
    @image = newCanvas(@extent().scaleBy pixelRatio)
    context = @image.getContext("2d")
    context.scale pixelRatio, pixelRatio
    if @orientation is "vertical"
      radius = @width() / 2
      x = @center().x
      center1 = new Point(x, @top() + radius)
      center2 = new Point(x, @bottom() - radius)
      rect = @bounds.origin.add(
        new Point(0, radius)).corner(@bounds.corner.subtract(new Point(0, radius)))
    else
      radius = @height() / 2
      y = @center().y
      center1 = new Point(@left() + radius, y)
      center2 = new Point(@right() - radius, y)
      rect = @bounds.origin.add(
        new Point(radius, 0)).corner(@bounds.corner.subtract(new Point(radius, 0)))

    # draw the two circles and then the rectangle connecting them
    points = [center1.subtract(@bounds.origin), center2.subtract(@bounds.origin)]
    points.forEach (center) =>
      context.fillStyle = @color.toString()
      context.beginPath()
      context.arc center.x, center.y, radius, 0, 2 * Math.PI, false
      context.closePath()
      context.fill()
    rect = rect.translateBy(@bounds.origin.neg())
    ext = rect.extent()
    if ext.x > 0 and ext.y > 0
      context.fillRect rect.origin.x, rect.origin.y, rect.width(), rect.height()
  
  
  # CircleBoxMorph menu:
  developersMenu: ->
    menu = super()
    menu.addLine()
    # todo Dan Ingalls did show a neat demo where the
    # boxmorph was automatically chanding the orientation
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
