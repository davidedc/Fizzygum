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
      @drawNew()
  
  
  # SpeechBubbleMorph invoking:
  popUp: (world, pos) ->
    @drawNew()
    @setPosition pos.subtract(new Point(0, @height()))
    @addShadow new Point(2, 2), 80
    @keepWithin world
    world.add @
    @changed()
    world.hand.destroyTemporaries()
    world.hand.temporaries.push @
    @mouseEnter = ->
      @destroy()
  
  
  # SpeechBubbleMorph drawing:
  drawNew: ->
    # re-build my contents
    @contentsMorph.destroy()  if @contentsMorph
    if @contents instanceof Morph
      @contentsMorph = @contents
    else if isString(@contents)
      @contentsMorph = new TextMorph(
        @contents,
        WorldMorph.MorphicPreferences.bubbleHelpFontSize,
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
        WorldMorph.MorphicPreferences.bubbleHelpFontSize,
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
