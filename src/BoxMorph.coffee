# BoxMorph ////////////////////////////////////////////////////////////

# I can have an optionally rounded border

class BoxMorph
  constructor: (edge, border, borderColor) ->
    @init edge, border, borderColor

# BoxMorph inherits from Morph:
BoxMorph:: = new Morph()
BoxMorph::constructor = BoxMorph
BoxMorph.uber = Morph::

# BoxMorph instance creation:
BoxMorph::init = (edge, border, borderColor) ->
  @edge = edge or 4
  @border = border or ((if (border is 0) then 0 else 2))
  @borderColor = borderColor or new Color()
  BoxMorph.uber.init.call this


# BoxMorph drawing:
BoxMorph::drawNew = ->
  context = undefined
  @image = newCanvas(@extent())
  context = @image.getContext("2d")
  if (@edge is 0) and (@border is 0)
    BoxMorph.uber.drawNew.call this
    return null
  context.fillStyle = @color.toString()
  context.beginPath()
  @outlinePath context, Math.max(@edge - @border, 0), @border
  context.closePath()
  context.fill()
  if @border > 0
    context.lineWidth = @border
    context.strokeStyle = @borderColor.toString()
    context.beginPath()
    @outlinePath context, @edge, @border / 2
    context.closePath()
    context.stroke()

BoxMorph::outlinePath = (context, radius, inset) ->
  offset = radius + inset
  w = @width()
  h = @height()
  
  # top left:
  context.arc offset, offset, radius, radians(-180), radians(-90), false
  
  # top right:
  context.arc w - offset, offset, radius, radians(-90), radians(-0), false
  
  # bottom right:
  context.arc w - offset, h - offset, radius, radians(0), radians(90), false
  
  # bottom left:
  context.arc offset, h - offset, radius, radians(90), radians(180), false


# BoxMorph menus:
BoxMorph::developersMenu = ->
  menu = BoxMorph.uber.developersMenu.call(this)
  menu.addLine()
  menu.addItem "border width...", (->
    @prompt menu.title + "\nborder\nwidth:", @setBorderWidth, this, @border.toString(), null, 0, 100, true
  ), "set the border's\nline size"
  menu.addItem "border color...", (->
    @pickColor menu.title + "\nborder color:", @setBorderColor, this, @borderColor
  ), "set the border's\nline color"
  menu.addItem "corner size...", (->
    @prompt menu.title + "\ncorner\nsize:", @setCornerSize, this, @edge.toString(), null, 0, 100, true
  ), "set the corner's\nradius"
  menu

BoxMorph::setBorderWidth = (size) ->
  
  # for context menu demo purposes
  newSize = undefined
  if typeof size is "number"
    @border = Math.max(size, 0)
  else
    newSize = parseFloat(size)
    @border = Math.max(newSize, 0)  unless isNaN(newSize)
  @drawNew()
  @changed()

BoxMorph::setBorderColor = (color) ->
  
  # for context menu demo purposes
  if color
    @borderColor = color
    @drawNew()
    @changed()

BoxMorph::setCornerSize = (size) ->
  
  # for context menu demo purposes
  newSize = undefined
  if typeof size is "number"
    @edge = Math.max(size, 0)
  else
    newSize = parseFloat(size)
    @edge = Math.max(newSize, 0)  unless isNaN(newSize)
  @drawNew()
  @changed()

BoxMorph::colorSetters = ->
  
  # for context menu demo purposes
  ["color", "borderColor"]

BoxMorph::numericalSetters = ->
  
  # for context menu demo purposes
  list = BoxMorph.uber.numericalSetters.call(this)
  list.push "setBorderWidth", "setCornerSize"
  list
