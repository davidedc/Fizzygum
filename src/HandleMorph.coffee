# HandleMorph ////////////////////////////////////////////////////////
# not to be confused with the HandMorph
# I am a resize / move handle that can be attached to any Morph

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class HandleMorph extends Morph

  target: null
  minExtent: null
  inset: null
  type: null # "resize" or "move"
  step: null

  constructor: (@target = null, minX = 0, minY = 0, insetX, insetY, @type = "resize") ->
    # if insetY is missing, it will be the same as insetX
    @minExtent = new Point(minX, minY)
    @inset = new Point(insetX or 0, insetY or insetX or 0)
    super()
    @color = new Color(255, 255, 255)
    @noticesTransparentClick = true
    size = WorldMorph.preferencesAndSettings.handleSize
    @silentSetExtent new Point(size, size)
    if @target
      @target.add @
    @updatePosition()

  updatePosition: ->
    if @target
        @setPosition @target.bottomRight().subtract(@extent().add(@inset))
        # todo wow, wasteful!
        @target.changed()
  
  
  # HandleMorph drawing:
  updateRendering: ->
    @normalImage = newCanvas(@extent())
    @highlightImage = newCanvas(@extent())
    @handleMorphRenderingHelper @normalImage, @color, new Color(100, 100, 100)
    @handleMorphRenderingHelper @highlightImage, new Color(100, 100, 255), new Color(255, 255, 255)
    @image = @normalImage
  
  handleMorphRenderingHelper: (aCanvas, color, shadowColor) ->
    context = aCanvas.getContext("2d")
    context.lineWidth = 1
    context.lineCap = "round"
    context.strokeStyle = color.toString()
    if @type is "move"
      p1 = @bottomLeft().subtract(@position())
      p11 = p1.copy()
      p2 = @topRight().subtract(@position())
      p22 = p2.copy()
      for i in [0..@height()] by 6
        p11.y = p1.y - i
        p22.y = p2.y - i
        context.beginPath()
        context.moveTo p11.x, p11.y
        context.lineTo p22.x, p22.y
        context.closePath()
        context.stroke()

    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    for i in [0..@width()] by 6
      p11.x = p1.x + i
      p22.x = p2.x + i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()

    context.strokeStyle = shadowColor.toString()
    if @type is "move"
      p1 = @bottomLeft().subtract(@position())
      p11 = p1.copy()
      p2 = @topRight().subtract(@position())
      p22 = p2.copy()
      for i in [-1..@height()] by 6
        p11.y = p1.y - i
        p22.y = p2.y - i
        context.beginPath()
        context.moveTo p11.x, p11.y
        context.lineTo p22.x, p22.y
        context.closePath()
        context.stroke()

    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    for i in [2..@width()] by 6
      p11.x = p1.x + i
      p22.x = p2.x + i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()
  
  
  # HandleMorph stepping:

  mouseDownLeft: (pos) ->
    world = @root()
    offset = pos.subtract(@bounds.origin)
    return null  unless @target
    @step = =>
      if world.hand.mouseButton
        newPos = world.hand.bounds.origin.copy().subtract(offset)
        if @type is "resize"
          newExt = newPos.add(@extent().add(@inset)).subtract(@target.bounds.origin)
          newExt = newExt.max(@minExtent)
          @target.setExtent newExt
          @setPosition @target.bottomRight().subtract(@extent().add(@inset))
          # not all morphs provide a layoutSubmorphs, so check
          if @target.layoutSubmorphs?
            @target.layoutSubmorphs()
        else # type === 'move'
          @target.setPosition newPos.subtract(@target.extent()).add(@extent())
      else
        @step = null
    
    unless @target.step
      @target.step = noOperation
  
  
  # HandleMorph dragging and dropping:
  rootForGrab: ->
    @
  
  
  # HandleMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
  
    
  # HandleMorph menu:
  attach: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), ->
        @isDraggable = false
        @target = each
        @updateRendering()
        @noticesTransparentClick = true
    menu.popUpAtHand()  if choices.length
