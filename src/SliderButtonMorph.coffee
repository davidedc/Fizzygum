# SliderButtonMorph ///////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class SliderButtonMorph extends CircleBoxMorph

  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(90, 90, 140)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(80, 80, 160)
  is3D: false
  hasMiddleDip: true

  constructor: (orientation) ->
    @color = new Color(80, 80, 80)
    super orientation
  
  autoOrientation: ->
      noOperation
  
  updateRendering: ->
    colorBak = @color.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @normalImage = @image
    @color = @highlightColor.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @highlightImage = @image
    @color = @pressColor.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @pressImage = @image
    @color = colorBak
    @image = @normalImage
  
  drawEdges: ->
    context = @image.getContext("2d")
    w = @width()
    h = @height()
    context.lineJoin = "round"
    context.lineCap = "round"
    if @orientation is "vertical"
      context.lineWidth = w / 3
      gradient = context.createLinearGradient(0, 0, context.lineWidth, 0)
      gradient.addColorStop 0, "white"
      gradient.addColorStop 1, @color.toString()
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo context.lineWidth * 0.5, w / 2
      context.lineTo context.lineWidth * 0.5, h - w / 2
      context.stroke()
      gradient = context.createLinearGradient(w - context.lineWidth, 0, w, 0)
      gradient.addColorStop 0, @color.toString()
      gradient.addColorStop 1, "black"
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo w - context.lineWidth * 0.5, w / 2
      context.lineTo w - context.lineWidth * 0.5, h - w / 2
      context.stroke()
      if @hasMiddleDip
        gradient = context.createLinearGradient(
          context.lineWidth, 0, w - context.lineWidth, 0)
        radius = w / 4
        gradient.addColorStop 0, "black"
        gradient.addColorStop 0.35, @color.toString()
        gradient.addColorStop 0.65, @color.toString()
        gradient.addColorStop 1, "white"
        context.fillStyle = gradient
        context.beginPath()
        context.arc w / 2, h / 2, radius, radians(0), radians(360), false
        context.closePath()
        context.fill()
    else if @orientation is "horizontal"
      context.lineWidth = h / 3
      gradient = context.createLinearGradient(0, 0, 0, context.lineWidth)
      gradient.addColorStop 0, "white"
      gradient.addColorStop 1, @color.toString()
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo h / 2, context.lineWidth * 0.5
      context.lineTo w - h / 2, context.lineWidth * 0.5
      context.stroke()
      gradient = context.createLinearGradient(0, h - context.lineWidth, 0, h)
      gradient.addColorStop 0, @color.toString()
      gradient.addColorStop 1, "black"
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo h / 2, h - context.lineWidth * 0.5
      context.lineTo w - h / 2, h - context.lineWidth * 0.5
      context.stroke()
      if @hasMiddleDip
        gradient = context.createLinearGradient(
          0, context.lineWidth, 0, h - context.lineWidth)
        radius = h / 4
        gradient.addColorStop 0, "black"
        gradient.addColorStop 0.35, @color.toString()
        gradient.addColorStop 0.65, @color.toString()
        gradient.addColorStop 1, "white"
        context.fillStyle = gradient
        context.beginPath()
        context.arc @width() / 2, @height() / 2, radius, radians(0), radians(360), false
        context.closePath()
        context.fill()
  
  
  #SliderButtonMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
  
  mouseDownLeft: (pos) ->
    @image = @pressImage
    @changed()
    @escalateEvent "mouseDownLeft", pos
  
  mouseClickLeft: ->
    @image = @highlightImage
    @changed()
  
  # prevent my parent from getting picked up
  mouseMove: ->
      noOperation
