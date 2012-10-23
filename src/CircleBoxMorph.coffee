# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders

class CircleBoxMorph extends Morph

  orientation: null
  autoOrient: true

  constructor: (@orientation = "vertical") ->
    super()
    @setExtent new Point(20, 100)
  
  autoOrientation: ->
    if @height() > @width()
      @orientation = "vertical"
    else
      @orientation = "horizontal"
  
  drawNew: ->
    @autoOrientation()  if @autoOrient
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
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
    if @orientation is "vertical"
      menu.addItem "horizontal...", "toggleOrientation", "toggle the\norientation"
    else
      menu.addItem "vertical...", "toggleOrientation", "toggle the\norientation"
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
    @drawNew()
    @changed()
