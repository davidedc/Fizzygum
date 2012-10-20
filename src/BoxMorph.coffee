# BoxMorph ////////////////////////////////////////////////////////////

# I can have an optionally rounded border

class BoxMorph extends Morph
  constructor: (edge, border, borderColor) ->
    @edge = edge or 4
    @border = border or ((if (border is 0) then 0 else 2))
    @borderColor = borderColor or new Color()
    super()
  
  # BoxMorph drawing:
  drawNew: ->
    context = undefined
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    if (@edge is 0) and (@border is 0)
      super()
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
  
  outlinePath: (context, radius, inset) ->
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
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "border width...", (->
      @prompt menu.title + "\nborder\nwidth:", @setBorderWidth, @, @border.toString(), null, 0, 100, true
    ), "set the border's\nline size"
    menu.addItem "border color...", (->
      @pickColor menu.title + "\nborder color:", @setBorderColor, @, @borderColor
    ), "set the border's\nline color"
    menu.addItem "corner size...", (->
      @prompt menu.title + "\ncorner\nsize:", @setCornerSize, @, @edge.toString(), null, 0, 100, true
    ), "set the corner's\nradius"
    menu
  
  setBorderWidth: (size) ->
    # for context menu demo purposes
    newSize = undefined
    if typeof size is "number"
      @border = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @border = Math.max(newSize, 0)  unless isNaN(newSize)
    @drawNew()
    @changed()
  
  setBorderColor: (color) ->
    # for context menu demo purposes
    if color
      @borderColor = color
      @drawNew()
      @changed()
  
  setCornerSize: (size) ->
    # for context menu demo purposes
    newSize = undefined
    if typeof size is "number"
      @edge = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @edge = Math.max(newSize, 0)  unless isNaN(newSize)
    @drawNew()
    @changed()
  
  colorSetters: ->
    # for context menu demo purposes
    ["color", "borderColor"]
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setBorderWidth", "setCornerSize"
    list
