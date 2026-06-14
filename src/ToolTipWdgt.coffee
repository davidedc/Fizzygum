# when invoked using...
#    createInAWhileIfHandStillContainedInMorph / openAt
#	... I can temporarily display any widget.
# (is you just use the default constructor it will just sit there
# and basically _not_ behave like a tool tip)
# Note that I'm not a PopUp, for example I can't be pinned.
# I'm always attached to the world, without any layout constraints.

class ToolTipWdgt extends Widget

  @ongoingTimeouts: new Set

  contents: nil
  padding: nil # additional vertical pixels
  morphInvokingThis: nil

  constructor: (
   @contents="text here",
   @morphInvokingThis,
   @color = WorldMorph.preferencesAndSettings.menuBackgroundColor,
   cornerRadius,
   @padding = 0) ->
    # console.log "bubble super"
    super()
    @strokeColor = WorldMorph.preferencesAndSettings.menuStrokeColor
    @cornerRadius = cornerRadius or 6
    @appearance = new BubblyAppearance @
    # console.log @color
  
  @createBubbleHelpIfHandStillOnMorph: (contents, morphInvokingThis) ->
    # console.log "bubble createBubbleHelpIfHandStillOnMorph"
    # let's check that the item that the
    # bubble is about is still actually there
    # and the mouse is still over it, otherwise
    # do nothing.
    if morphInvokingThis.root() == world and morphInvokingThis.boundsContainPoint world.hand.position()
      theBubble = new @ contents, morphInvokingThis
      theBubble.openAt morphInvokingThis.topRight()

  @cancelAllScheduledToolTips: ->
    @ongoingTimeouts.forEach (eachTimeout) =>
      clearTimeout eachTimeout
    @ongoingTimeouts.clear()

  @createInAWhileIfHandStillContainedInMorph: (morphInvokingThis, contents, delay = 500) ->
    # console.log "bubble createInAWhileIfHandStillContainedInMorph"
    if Automator? and Automator.animationsPacingControl and
     Automator.state != Automator.IDLE
        @createBubbleHelpIfHandStillOnMorph contents, morphInvokingThis
    else
      @ongoingTimeouts.add setTimeout (=>
        @createBubbleHelpIfHandStillOnMorph contents, morphInvokingThis
        )
        , delay
  
  # ToolTipWdgt invoking:
  openAt: (pos) ->
    @buildAndConnectChildren()
    @fullRawMoveTo pos.subtract new Point 8, @height()
    @fullRawMoveWithin world
    world.add @
    @addShadow()
    @fullChanged()
    world.destroyToolTips()
    world.toolTipsList.add @
    
  buildAndConnectChildren: ->
    # console.log "bubble buildAndConnectChildren"
    # re-build my contents
    if @contentsMorph
      @contentsMorph = @contentsMorph.destroy()
    if @contents instanceof Widget
      @contentsMorph = @contents
    else if Utils.isString @contents
      # "sans-serif" passed explicitly: the old TextMorph defaulted a nil font
      # to "sans-serif", whereas TextMorph2's default is 'Arial, sans-serif'.
      # Color.BLACK passed explicitly: old TextMorph forced black, TextMorph2
      # defaults to (37,37,37).
      @contentsMorph = new TextMorph2(
        @contents,
        WorldMorph.preferencesAndSettings.bubbleHelpFontSize,
        "sans-serif",
        false,
        true,
        Color.BLACK)
      @contentsMorph.alignCenter()
    # canvas-like (a DOM canvas OR an SWCanvasElement under the software backend);
    # Widget / string contents are already handled by the branches above.
    else if @contents? and typeof @contents.getContext is "function"
      @contentsMorph = new Widget
      @contentsMorph.silentRawSetWidth @contents.width
      @contentsMorph.silentRawSetHeight @contents.height
      @contentsMorph.backBuffer = @contents
      @contentsMorph.backBufferContext = @contentsMorph.backBuffer.getContext "2d"
    else
      @contentsMorph = new TextMorph2(
        @contents.toString(),
        WorldMorph.preferencesAndSettings.bubbleHelpFontSize,
        "sans-serif",
        false,
        true,
        Color.BLACK)
      @contentsMorph.alignCenter()
    @add @contentsMorph

    # the modern family does not self-size; make the tooltip text hug its
    # content before we read its width/height to size the bubble around it.
    @contentsMorph.sizeToTextAndDisableFitting() if @contentsMorph instanceof TextMorph2

    # adjust my layout
    @silentRawSetWidth @contentsMorph.width() + ((if @padding then @padding * 2 else @cornerRadius * 2))
    @silentRawSetHeight @contentsMorph.height() + @cornerRadius + @padding * 2 + 2

    # position my contents
    @contentsMorph.fullRawMoveTo @position().add(
      new Point(@padding or @cornerRadius, @padding + 1))


