# HandleMorph ////////////////////////////////////////////////////////
# not to be confused with the HandMorph
# I am a resize / move handle that can be attached to any Morph

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

class HandleMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype


  target: null
  inset: null
  type: null # "resize" or "move"

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1

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
      # collapse some of the handles if the
      # morph gets too small because they
      # become unusable anyways once they
      # overlap
      if @type == "move"
        if @target.width() < 2 * @width()
          @hide()
          return
        else
          @show()
      else if @type == "resizeRight"
        if @target.height() < 3 * @height()
          @hide()
          return
        else
          @show()
      else if @type == "resizeDown"
        if @target.width() < 3 * @width()
          @hide()
          return
        else
          @show()

      @silentUpdateResizerHandlePosition()
      @changed()

  silentUpdateResizerHandlePosition: ->
    if @target
        if @type == "resize"
          @silentSetPosition @target.bottomRight().subtract(@extent().add(@inset))
        else if @type == "move"
          @silentSetPosition @target.topLeft().add(@inset)
        else if @type == "resizeRight"
          offsetFromMiddlePoint = new Point(@extent().x + @inset.x, Math.floor(@extent().y/2))
          @silentSetPosition @target.rightCenter().subtract(offsetFromMiddlePoint)
        else if @type == "resizeDown"
          offsetFromMiddlePoint = new Point(Math.floor(@extent().x/2), @extent().y + @inset.y)
          @silentSetPosition @target.bottomCenter().subtract(offsetFromMiddlePoint)
  
  

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by recursivelyPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

    if @isMinimised or !@isVisible
      return null

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

      debugger
      if @state == @STATE_NORMAL
        @handleMorphRenderingHelper aContext, @color, new Color(100, 100, 100)
      if @state == @STATE_HIGHLIGHTED
        @handleMorphRenderingHelper aContext, new Color(255, 255, 255), new Color(200, 200, 255)


      aContext.restore()

      if world.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)

        aContext.save()
        aContext.globalAlpha = 0.5
        aContext.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        aContext.fillRect  Math.round(al),
            Math.round(at),
            Math.round(w),
            Math.round(h)
        aContext.restore()

  doPath: (context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown) ->
    context.beginPath()
    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x, 0.5 + leftArrowPoint.y + arrowPieceLeftUp.y
    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftDown.x, 0.5 + leftArrowPoint.y + arrowPieceLeftDown.y

    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y

    context.lineTo 0.5 + rightArrowPoint.x + arrowPieceRightUp.x, 0.5 + rightArrowPoint.y + arrowPieceRightUp.y
    context.moveTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y
    context.lineTo 0.5 + rightArrowPoint.x + arrowPieceRightDown.x, 0.5 + rightArrowPoint.y + arrowPieceRightDown.y

    context.closePath()
    context.stroke()

  drawHandle: (context) ->
    if @type is "resizeRight" or @type is "move"
      p0 = @bottomLeft().subtract(@position())
      p0 = p0.subtract(new Point(0, Math.ceil(@height()/2)))
      
      leftArrowPoint = p0.copy()
      leftArrowPoint = leftArrowPoint.add(new Point(Math.ceil(@width()/15),0))

      rightArrowPoint = p0.add(new Point(@width() - Math.ceil(@width()/14), 0))
      arrowPieceLeftUp = new Point(Math.ceil(@width()/5),-Math.ceil(@height()/5))
      arrowPieceLeftDown = new Point(Math.ceil(@width()/5),Math.ceil(@height()/5))
      arrowPieceRightUp = new Point(-Math.ceil(@width()/5),-Math.ceil(@height()/5))
      arrowPieceRightDown = new Point(-Math.ceil(@width()/5),Math.ceil(@height()/5))
      @doPath(context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown)

    if @type is "resizeDown" or @type is "move"
      p0 = @bottomCenter().subtract(@position())
      
      leftArrowPoint = p0.copy()
      leftArrowPoint = leftArrowPoint.add(new Point(0,-Math.ceil(@height()/14)))

      rightArrowPoint = p0.add(new Point(0, -@height() + Math.ceil(@height()/15)))
      arrowPieceLeftUp = new Point(-Math.ceil(@width()/5),-Math.ceil(@height()/5))
      arrowPieceLeftDown = new Point(Math.ceil(@width()/5),-Math.ceil(@height()/5))
      arrowPieceRightUp = new Point(-Math.ceil(@width()/5), Math.ceil(@height()/5))
      arrowPieceRightDown = new Point(Math.ceil(@width()/5),Math.ceil(@height()/5))
      @doPath(context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown)


    if @type is "resize"
      debugger
      p0 = @topLeft().subtract(@position())
      
      leftArrowPoint = p0.copy()
      leftArrowPoint = leftArrowPoint.add( @extent().floorDivideBy(7) )

      rightArrowPoint = @bottomRight().subtract(@position()).subtract( @extent().floorDivideBy(7) )
      arrowPieceLeftUp = new Point(Math.ceil(@width()/4),0)
      arrowPieceLeftDown = new Point(0,Math.ceil(@height()/4))
      arrowPieceRightUp = new Point(0,-Math.ceil(@width()/4))
      arrowPieceRightDown = new Point(-Math.ceil(@width()/4),0)
      @doPath(context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown)

  handleMorphRenderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 1
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()
    context.strokeStyle = shadowColor.toString()
    context.translate 1,1
    @drawHandle(context)
    context.translate 1,0
    @drawHandle(context)
    context.restore()

    context.strokeStyle = color.toString()
    @drawHandle(context)


  

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
    else if @type is "move"
      @target.setPosition newPos.subtract @inset
    else if @type is "resizeRight"
      newWidth = newPos.x + @extent().x + @inset.x - @target.bounds.origin.x
      @target.setWidth newWidth
    else if @type is "resizeDown"
      newHeight = newPos.y + @extent().y + @inset.y - @target.bounds.origin.y
      @target.setHeight newHeight
  
  
  # HandleMorph floatDragging and dropping:
  rootForGrab: ->
    @
  
  # HandleMorph events:
  mouseEnter: ->
    console.log "<<<<<< handle mousenter"
    @state = @STATE_HIGHLIGHTED
    @changed()
  
  mouseLeave: ->
    console.log "<<<<<< handle mouseleave"
    @state = @STATE_NORMAL
    @changed()

  makeHandleSolidWithParentMorph: (ignored, ignored2, morphAttachedTo)->
    @isfloatDraggable = false
    @target = morphAttachedTo
    @target.add @
    @updateResizerHandlePosition()
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
