# SpeechBubbleMorph ///////////////////////////////////////////////////

#
#	I am a comic-style speech bubble that can display either a string,
#	a Morph, a Canvas or a toString() representation of anything else.
#	If I am invoked using popUp() I behave like a tool tip.
#

class SpeechBubbleMorph extends BoxMorph

  isPointingRight: true # orientation of text
  contents: null
  padding: null # additional vertical pixels
  isThought: null # draw "think" bubble
  isClickable: false

  constructor: (
    @contents="",
    color,
    edge,
    border,
    borderColor,
    @padding = 0,
    @isThought = false) ->
      super edge or 6, border or ((if (border is 0) then 0 else 1)), borderColor or new Color(140, 140, 140)
      @color = color or new Color(230, 230, 230)
      @updateRendering()
  
  @createBubbleHelpIfHandStillOnMorph: (contents, morphInvokingThis) ->
    if morphInvokingThis.bounds.containsPoint(morphInvokingThis.world().hand.position())
      new @(
        localize(contents), null, null, 1).popUp morphInvokingThis.world(),
        morphInvokingThis.rightCenter().add(new Point(-8, 0))

  @createInAWhileIfHandStillContainedInMorph: (morphInvokingThis, contents, delay = 500) ->
    if window.world.systemTestsRecorderAndPlayer.animationsTiedToTestCommandNumber and
     SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.IDLE
        @createBubbleHelpIfHandStillOnMorph contents, morphInvokingThis
    else
      setTimeout (=>
        @createBubbleHelpIfHandStillOnMorph contents, morphInvokingThis
        )
        , delay
  
  # SpeechBubbleMorph invoking:
  popUp: (world, pos, isClickable) ->
    @updateRendering()
    @setPosition pos.subtract(new Point(0, @height()))
    @addShadow new Point(2, 2), 80
    @keepWithin world
    world.add @
    @fullChanged()
    world.hand.destroyTemporaries()
    world.hand.temporaries.push @
    if isClickable
      @mouseEnter = ->
        @destroy()
    else
      @isClickable = false
    
  
  
  # SpeechBubbleMorph drawing:
  updateRendering: ->
    # re-build my contents
    @contentsMorph.destroy()  if @contentsMorph
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
      @contentsMorph.image = @contents
    else
      @contentsMorph = new TextMorph(
        @contents.toString(),
        WorldMorph.preferencesAndSettings.bubbleHelpFontSize,
        null,
        false,
        true,
        "center")
    @add @contentsMorph
    #
    # adjust my layout
    @silentSetWidth @contentsMorph.width() + ((if @padding then @padding * 2 else @edge * 2))
    @silentSetHeight @contentsMorph.height() + @edge + @border * 2 + @padding * 2 + 2
    #
    # draw my outline
    super()
    #
    # position my contents
    @contentsMorph.setPosition @position().add(
      new Point(@padding or @edge, @border + @padding + 1))
  
  outlinePath: (context, radius, inset) ->
    circle = (x, y, r) ->
      context.moveTo x + r, y
      context.arc x, y, r, radians(0), radians(360)
    offset = radius + inset
    w = @width()
    h = @height()
    #
    # top left:
    context.arc offset, offset, radius, radians(-180), radians(-90), false
    #
    # top right:
    context.arc w - offset, offset, radius, radians(-90), radians(-0), false
    #
    # bottom right:
    context.arc w - offset, h - offset - radius, radius, radians(0), radians(90), false
    unless @isThought # draw speech bubble hook
      if @isPointingRight
        context.lineTo offset + radius, h - offset
        context.lineTo radius / 2 + inset, h - inset
      else # pointing left
        context.lineTo w - (radius / 2 + inset), h - inset
        context.lineTo w - (offset + radius), h - offset
    #
    # bottom left:
    context.arc offset, h - offset - radius, radius, radians(90), radians(180), false
    if @isThought
      #
      # close large bubble:
      context.lineTo inset, offset
      #
      # draw thought bubbles:
      if @isPointingRight
        #
        # tip bubble:
        rad = radius / 4
        circle rad + inset, h - rad - inset, rad
        #
        # middle bubble:
        rad = radius / 3.2
        circle rad * 2 + inset, h - rad - inset * 2, rad
        #
        # top bubble:
        rad = radius / 2.8
        circle rad * 3 + inset * 2, h - rad - inset * 4, rad
      else # pointing left
        # tip bubble:
        rad = radius / 4
        circle w - (rad + inset), h - rad - inset, rad
        #
        # middle bubble:
        rad = radius / 3.2
        circle w - (rad * 2 + inset), h - rad - inset * 2, rad
        #
        # top bubble:
        rad = radius / 2.8
        circle w - (rad * 3 + inset * 2), h - rad - inset * 4, rad

  # SpeechBubbleMorph shadow
  #
  #    only take the 'plain' image, so the box rounding and the
  #    shadow doesn't become conflicted by embedded scrolling panes
  #
  shadowImage: (off_, color) ->
    
    # fallback for Windows Chrome-Shadow bug
    fb = undefined
    img = undefined
    outline = undefined
    sha = undefined
    ctx = undefined
    offset = off_ or new Point(7, 7)
    clr = color or new Color(0, 0, 0)
    fb = @extent()
    img = @image
    outline = newCanvas(fb)
    ctx = outline.getContext("2d")
    ctx.drawImage img, 0, 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, -offset.x, -offset.y
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.drawImage outline, 0, 0
    ctx.globalCompositeOperation = "source-atop"
    ctx.fillStyle = clr.toString()
    ctx.fillRect 0, 0, fb.x, fb.y
    sha

  shadowImageBlurred: (off_, color) ->
    fb = undefined
    img = undefined
    sha = undefined
    ctx = undefined
    offset = off_ or new Point(7, 7)
    blur = @shadowBlur
    clr = color or new Color(0, 0, 0)
    fb = @extent().add(blur * 2)
    img = @image
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.shadowOffsetX = offset.x
    ctx.shadowOffsetY = offset.y
    ctx.shadowBlur = blur
    ctx.shadowColor = clr.toString()
    ctx.drawImage img, blur - offset.x, blur - offset.y
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    ctx.shadowBlur = 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, blur - offset.x, blur - offset.y
    sha

  # SpeechBubbleMorph resizing
  layoutSubmorphs: ->
    @removeShadow()
    @updateRendering()
    @addShadow new Point(2, 2), 80
