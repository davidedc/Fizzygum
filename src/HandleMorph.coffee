# HandleMorph ////////////////////////////////////////////////////////
# not to be confused with the HandMorph
# I am a resize / move handle that can be attached to any Morph

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions
# REQUIRES BackingStoreMixin

class HandleMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith BackingStoreMixin

  target: null
  inset: null
  type: null # "resize" or "move"

  constructor: (@target = null, @type = "resize") ->
    if @target?.padding?
      @inset = new Point(@target.padding, @target.padding)
    else
      @inset = new Point(0,0)
    super()
    @color = new Color(255, 255, 255)
    @noticesTransparentClick = true
    size = WorldMorph.preferencesAndSettings.handleSize
    @silentSetExtent new Point(size, size)
    if @target
      @target.add @
    @updateResizerHandlePosition()

  parentIsLayouting: ->
    @updateResizerHandlePosition()

  updateResizerHandlePosition: ->
    if @target
        @changed()
        @silentUpdateResizerHandlePosition()
        @changed()

  silentUpdateResizerHandlePosition: ->
    if @target
        @silentSetPosition @target.bottomRight().subtract(@extent().add(@inset))
  
  
  # HandleMorph drawing:
  # no changes of position or extent
  updateBackingStore: ->
    extent = @extent()
    
    highlighted = false
    if @image?
      if @image == @highlightImage
        highlighted = true

    @normalImage = newCanvas(extent.scaleBy pixelRatio)
    normalImageContext = @normalImage.getContext("2d")
    normalImageContext.scale pixelRatio, pixelRatio
    @highlightImage = newCanvas(extent.scaleBy pixelRatio)
    highlightImageContext = @highlightImage.getContext("2d")
    highlightImageContext.scale pixelRatio, pixelRatio
    @handleMorphRenderingHelper normalImageContext, @color, new Color(100, 100, 100)
    @handleMorphRenderingHelper highlightImageContext, new Color(100, 100, 255), new Color(255, 255, 255)
    
    if highlighted
      @image = @highlightImage
    else
      @image = @normalImage
  
  handleMorphRenderingHelper: (context, color, shadowColor) ->
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
  

  # implement dummy methods in here
  # so the handle catches the clicks and
  # prevents the parent to do anything.
  mouseClickLeft: ->
  mouseUpLeft: ->
  mouseDownLeft: ->
  
  mouseDownLeft: (pos) ->
    return null  unless @target
    @target.bringToForegroud()

  nonFloatDragging: (nonFloatDragPositionWithinMorphAtStart, pos, delta) ->
    newPos = pos.subtract nonFloatDragPositionWithinMorphAtStart
    if @type is "resize"
      newExt = newPos.add(@extent().add(@inset)).subtract(@target.bounds.origin)
      @target.setExtent newExt
      # the position of this handle will be changed when the
      # parentIsLayouting method of this handle will be called
      # as the parent is layouting following the setExtent call just
      # made
    else # type === 'move'
      @target.setPosition newPos.subtract(@target.extent()).add(@extent())
  
  
  # HandleMorph floatDragging and dropping:
  rootForGrab: ->
    @
  
  # HandleMorph events:
  mouseEnter: ->
    console.log "<<<<<< handle mousenter"
    @image = @highlightImage
    @changed()
  
  mouseLeave: ->
    console.log "<<<<<< handle mouseleave"
    @image = @normalImage
    @changed()

  makeHandleSolidWithParentMorph: (ignored, ignored2, morphAttachedTo)->
    @isfloatDraggable = false
    @target = morphAttachedTo
    @target.add @
    @updateResizerHandlePosition()

    @updateBackingStore()
    @noticesTransparentClick = true
  
    
  # HandleMorph menu:
  attach: ->
    choices = world.plausibleTargetAndDestinationMorphs(@)
    menu = new MenuMorph(false, @, true, true, "choose target:")
    if choices.length > 0
      choices.forEach (each) =>
        menu.addItem each.toString().slice(0, 50) + " ➜", true, @, 'makeHandleSolidWithParentMorph', null,null,null,null,null,each
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible morphs to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # morphs then show some kind of message.
      menu = new MenuMorph(false, @, true, true, "no morphs to attach to")
    menu.popUpAtHand(@firstContainerMenu())  if choices.length
