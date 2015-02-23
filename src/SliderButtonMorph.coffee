# SliderButtonMorph ///////////////////////////////////////////////////
# This is the handle in the middle of any slider.
# Sliders (and hence this button)
# are also used in the ScrollMorphs.

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

  constructor: (orientation) ->
    @color = new Color(80, 80, 80)
    super orientation
  
  autoOrientation: ->
      noOperation

  updateBackingStore: ->
    if @parent?
      @orientation = @parent.orientation
      if @orientation is "vertical"
        bw = @parent.width() - 2
        bh = Math.max(bw, Math.round(@parent.height() * @parent.ratio()))
        @silentSetExtent new Point(bw, bh)
        posX = 1
        posY = Math.min(
          Math.round((@parent.value - @parent.start) * @parent.unitSize()),
          @parent.height() - @height())
      else
        bh = @parent.height() - 2
        bw = Math.max(bh, Math.round(@parent.width() * @parent.ratio()))
        @silentSetExtent new Point(bw, bh)
        posY = 1
        posX = Math.min(
          Math.round((@parent.value - @parent.start) * @parent.unitSize()),
          @parent.width() - @width())
      @setPosition new Point(posX, posY).add(@parent.bounds.origin)


    colorBak = @color.copy()
    super()
    @normalImage = @image
    @color = @highlightColor.copy()
    super()
    @highlightImage = @image
    @color = @pressColor.copy()
    super()
    @pressImage = @image
    @color = colorBak
    @image = @normalImage
    @changed()
    return null
    
  
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
