# UpperRightTriangle ////////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions
#
# to test this:
# create a canvas. then:
# new UpperRightTriangle(world.children[0])

class UpperRightTriangle extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype


  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1

  constructor: (parent = null) ->
    super()
    @color = new Color 255, 255, 255
    @noticesTransparentClick = true
    size = WorldMorph.preferencesAndSettings.handleSize
    @silentRawSetExtent new Point size, size
    if parent
      parent.add @
    @updateResizerPosition()

  isFloatDraggable: ->
    if @parent?

      # an instance of ScrollFrameMorph is also an instance of FrameMorph
      # so gotta do this check first ahead of next paragraph.
      #if @parentThatIsA(ScrollFrameMorph)?
      #  return false

      if @parent instanceof WorldMorph
        return true
    return false


  updateResizerPosition: ->
    @silentRawSetExtent new Point 100, 100
    @silentFullRawMoveTo new Point 100, 100
  

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

    if @preliminaryCheckNothingToDraw false, clippingRectangle, aContext
      return

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

      if @state == @STATE_NORMAL
        @renderingHelper aContext, new Color(255, 0, 0), new Color(255, 100, 100)
      if @state == @STATE_HIGHLIGHTED
        @renderingHelper aContext, new Color(255, 255, 255), new Color(200, 200, 255)

      aContext.restore()

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio (i.e. after the restore)
      @paintHighlight aContext, al, at, w, h

  renderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 1
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()

    context.fillStyle = color.toString()

    context.beginPath()
    context.moveTo 0, 0
    context.lineTo @width(), @height()
    context.lineTo @width(), 0
    context.closePath()
    context.fill()

    context.restore()
  

  # implement dummy methods in here
  # so the morph catches the clicks and
  # prevents the parent from doing anything.
  mouseClickLeft: ->
  mouseUpLeft: ->
  mouseDownLeft: ->
  
  mouseDownLeft: (pos) ->
    return null  unless @parent
    @parent.bringToForegroud()
  
  
  # floatDragging and dropping:
  rootForGrab: ->
    @

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@boundsContainPoint aPoint
      return true
 
    thisMorphPosition = @position()
    radius = Math.max @cornerRadius, 0
 
    relativePoint = new Point aPoint.x - thisMorphPosition.x, aPoint.y - thisMorphPosition.y

    if relativePoint.x / relativePoint.y < @width()/@height()
      return true


    return false

  
  # events:
  mouseMove: ->
    if !@isTransparentAt(world.hand.position())
      if @state == @STATE_NORMAL
        @changed()
        @state = @STATE_HIGHLIGHTED
    else 
      if @state == @STATE_HIGHLIGHTED
        @changed()
        @state = @STATE_NORMAL

  mouseLeave: ->
    if @state == @STATE_HIGHLIGHTED
      @changed()
      @state = @STATE_NORMAL
  

  makeSolidWithParentMorph: (ignored, ignored2, morphAttachedTo)->
    morphAttachedTo.add @
    @updateResizerPosition()
    @noticesTransparentClick = true

    
  # menu:
  attach: ->
    choices = world.plausibleTargetAndDestinationMorphs @
    menu = new MenuMorph false, @, true, true, "choose parent:"
    if choices.length > 0
      choices.forEach (each) =>
        menu.addItem each.toString().slice(0, 50) + " ➜", true, @, 'makeSolidWithParentMorph', null, null, null, null, null, each, null, true
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible morphs to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # morphs then show some kind of message.
      menu = new MenuMorph false, @, true, true, "no morphs to attach to"
    menu.popUpAtHand @firstContainerMenu() if choices.length
