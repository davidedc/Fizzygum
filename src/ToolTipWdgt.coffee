# when invoked using...
#    createInAWhileIfHandStillContainedInWidget / openAt
#	... I can temporarily display any widget.
# (is you just use the default constructor it will just sit there
# and basically _not_ behave like a tool tip)
# Note that I'm not a PopUp, for example I can't be pinned.
# I'm always attached to the world, without any layout constraints.

class ToolTipWdgt extends Widget

  @ongoingTimeouts: new Set

  contents: nil
  padding: nil # additional vertical pixels
  widgetInvokingThis: nil

  constructor: (
   @contents="text here",
   @widgetInvokingThis,
   @color = WorldWdgt.preferencesAndSettings.menuBackgroundColor,
   cornerRadius,
   @padding = 0) ->
    # console.log "bubble super"
    super()
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor
    @cornerRadius = cornerRadius or 6
    @appearance = new BubblyAppearance @
    # console.log @color
  
  @createBubbleHelpIfHandStillOnWidget: (contents, widgetInvokingThis) ->
    # console.log "bubble createBubbleHelpIfHandStillOnWidget"
    # let's check that the item that the
    # bubble is about is still actually there
    # and the mouse is still over it, otherwise
    # do nothing.
    if widgetInvokingThis.root() == world and widgetInvokingThis.boundsContainPoint world.hand.position()
      theBubble = new @ contents, widgetInvokingThis
      theBubble.openAt widgetInvokingThis.topRight()

  @cancelAllScheduledToolTips: ->
    @ongoingTimeouts.forEach (eachTimeout) =>
      clearTimeout eachTimeout
    @ongoingTimeouts.clear()

  @createInAWhileIfHandStillContainedInWidget: (widgetInvokingThis, contents, delay = 500) ->
    # console.log "bubble createInAWhileIfHandStillContainedInWidget"
    if Automator? and Automator.animationsPacingControl and
     Automator.state != Automator.IDLE
        @createBubbleHelpIfHandStillOnWidget contents, widgetInvokingThis
    else
      @ongoingTimeouts.add setTimeout (=>
        @createBubbleHelpIfHandStillOnWidget contents, widgetInvokingThis
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
    if @contentsWidget
      @contentsWidget = @contentsWidget.destroy()
    if @contents instanceof Widget
      @contentsWidget = @contents
    else if Utils.isString @contents
      # "sans-serif" passed explicitly: the old text widget defaulted a nil font
      # to "sans-serif", whereas TextWdgt's default is 'Arial, sans-serif'.
      # Color.BLACK passed explicitly: old text widget forced black, TextWdgt
      # defaults to (37,37,37).
      @contentsWidget = new TextWdgt(
        @contents,
        WorldWdgt.preferencesAndSettings.bubbleHelpFontSize,
        "sans-serif",
        false,
        true,
        Color.BLACK)
      @contentsWidget.alignCenter()
    # canvas-like (a DOM canvas OR an SWCanvasElement under the software backend);
    # Widget / string contents are already handled by the branches above.
    else if @contents? and typeof @contents.getContext is "function"
      @contentsWidget = new Widget
      @contentsWidget.__commitWidth @contents.width
      @contentsWidget.__commitHeight @contents.height
      @contentsWidget.backBuffer = @contents
      @contentsWidget.backBufferContext = @contentsWidget.backBuffer.getContext "2d"
    else
      @contentsWidget = new TextWdgt(
        @contents.toString(),
        WorldWdgt.preferencesAndSettings.bubbleHelpFontSize,
        "sans-serif",
        false,
        true,
        Color.BLACK)
      @contentsWidget.alignCenter()
    @add @contentsWidget

    # the modern family does not self-size; make the tooltip text hug its
    # content before we read its width/height to size the bubble around it.
    @contentsWidget.sizeToTextAndDisableFitting() if @contentsWidget instanceof TextWdgt

    # adjust my layout
    @__commitWidth @contentsWidget.width() + ((if @padding then @padding * 2 else @cornerRadius * 2))
    @__commitHeight @contentsWidget.height() + @cornerRadius + @padding * 2 + 2

    # position my contents
    @contentsWidget.fullRawMoveTo @position().add(
      new Point(@padding or @cornerRadius, @padding + 1))


