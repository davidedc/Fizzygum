# SpeechBubbleMorph ///////////////////////////////////////////////////

#
#	I am a comic-style speech bubble that can display either a string,
#	a Morph, a Canvas or a toString() representation of anything else.
#	If I am invoked using popUp() I behave like a tool tip.
#

class SpeechBubbleMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  isPointingRight: true # orientation of text
  contents: null
  padding: null # additional vertical pixels
  isThought: null # draw "think" bubble
  isClickable: false
  morphInvokingThis: null

  constructor: (
    @contents="",
    @morphInvokingThis,
    color,
    cornerRadius,
    @padding = 0,
    @isThought = false) ->
      # console.log "bubble super"
      @color = color or new Color(230, 230, 230)
      super(cornerRadius or 6)
      # console.log @color
  
  @createBubbleHelpIfHandStillOnMorph: (contents, morphInvokingThis) ->
    # console.log "bubble createBubbleHelpIfHandStillOnMorph"
    # let's check that the item that the
    # bubble is about is still actually there
    # and the mouse is still over it, otherwise
    # do nothing.
    if (morphInvokingThis.root() == world) and morphInvokingThis.boundsContainPoint(world.hand.position())
      theBubble = new @(localize(contents), morphInvokingThis, null, null)
      theBubble.popUp theBubble.morphInvokingThis.rightCenter().add(new Point(-8, 0))

  @createInAWhileIfHandStillContainedInMorph: (morphInvokingThis, contents, delay = 500) ->
    # console.log "bubble createInAWhileIfHandStillContainedInMorph"
    if AutomatorRecorderAndPlayer.animationsPacingControl and
     AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE
        @createBubbleHelpIfHandStillOnMorph contents, morphInvokingThis
    else
      setTimeout (=>
        @createBubbleHelpIfHandStillOnMorph contents, morphInvokingThis
        )
        , delay
  
  # SpeechBubbleMorph invoking:
  popUp: (pos, isClickable) ->
    # console.log "bubble popup"
    @fullRawMoveTo pos.subtract(new Point(0, @height()))
    @fullMoveWithin world

    @buildAndConnectChildren()

    world.add @
    @addFullShadow()
    @fullChanged()
    world.hand.destroyTemporaries()
    world.hand.temporaries.push @
    if isClickable
      @mouseEnter = ->
        @destroy()
    else
      @isClickable = false
    
  buildAndConnectChildren: ->
    # console.log "bubble buildAndConnectChildren"
    # re-build my contents
    if @contentsMorph
      @contentsMorph = @contentsMorph.destroy()
    if @contents instanceof Morph
      @contentsMorph = @contents
    else if isString(@contents)
      @contentsMorph = new TextMorph(
        @contents,
        WorldMorph.preferencesAndSettings.bubbleHelpFontSize,
        null,
        false,
        true,
        "center")
    else if @contents instanceof HTMLCanvasElement
      @contentsMorph = new Morph()
      @contentsMorph.silentSetWidth @contents.width
      @contentsMorph.silentSetHeight @contents.height
      @contentsMorph.backBuffer = @contents
      @contentsMorph.backBufferContext = @contentsMorph.backBuffer.getContext("2d")
    else
      @contentsMorph = new TextMorph(
        @contents.toString(),
        WorldMorph.preferencesAndSettings.bubbleHelpFontSize,
        null,
        false,
        true,
        "center")
    @add @contentsMorph

    # adjust my layout
    @silentSetWidth @contentsMorph.width() + ((if @padding then @padding * 2 else @cornerRadius * 2))
    @silentSetHeight @contentsMorph.height() + @cornerRadius + @padding * 2 + 2

    # draw my outline
    #super()

    # position my contents
    @contentsMorph.fullRawMoveTo @position().add(
      new Point(@padding or @cornerRadius, @padding + 1))


  outlinePath: (context, radius) ->
    # console.log "bubble outlinePath"
    circle = (x, y, r) ->
      context.moveTo x + r, y
      context.arc x, y, r, degreesToRadians(0), degreesToRadians(360)
    offset = radius
    w = @width()
    h = @height()

    # top left:
    context.arc offset, offset, radius, degreesToRadians(-180), degreesToRadians(-90), false

    # top right:
    context.arc w - offset, offset, radius, degreesToRadians(-90), degreesToRadians(-0), false

    # bottom right:
    context.arc w - offset, h - offset - radius, radius, degreesToRadians(0), degreesToRadians(90), false
    unless @isThought # draw speech bubble hook
      if @isPointingRight
        context.lineTo offset + radius, h - offset
        context.lineTo radius / 2, h
      else # pointing left
        context.lineTo w - (radius / 2), h
        context.lineTo w - (offset + radius), h - offset

    # bottom left:
    context.arc offset, h - offset - radius, radius, degreesToRadians(90), degreesToRadians(180), false

    if @isThought
      # close large bubble:
      context.lineTo 0, offset

      # draw thought bubbles:
      if @isPointingRight

        # tip bubble:
        rad = radius / 4
        circle rad, h - rad, rad

        # middle bubble:
        rad = radius / 3.2
        circle rad * 2, h - rad, rad

        # top bubble:
        rad = radius / 2.8
        circle rad * 3, h - rad, rad
      else # pointing left
        # tip bubble:
        rad = radius / 4
        circle w - (rad), h - rad, rad

        # middle bubble:
        rad = radius / 3.2
        circle w - (rad * 2), h - rad, rad

        # top bubble:
        rad = radius / 2.8
        circle w - (rad * 3), h - rad, rad

