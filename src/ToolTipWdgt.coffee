# when invoked using...
#    createInAWhileIfHandStillContainedInWidget / openAt
#	... I can temporarily display any widget.
# (is you just use the default constructor it will just sit there
# and basically _not_ behave like a tool tip)
# Note that I'm not a PopUp, for example I can't be pinned.
# I'm always attached to the world, without any layout constraints.

class ToolTipWdgt extends Widget

  @ongoingTimeouts: new Set

  contents: undefined
  padding: undefined # extra pixels around the contents, both axes; when 0 the cornerRadius supplies the horizontal margin
  widgetInvokingThis: undefined
  # per class, not pulled up: this extends Widget, not BoxWdgt
  cornerRadius: undefined
  # the widget child holding @contents, built when the tip is opened and torn down with it
  contentsWidget: undefined

  constructor: (@contents = "text here", opts = {}) ->
    @widgetInvokingThis = opts.widgetInvokingThis
    @color = opts.color ? WorldWdgt.preferencesAndSettings.menuBackgroundColor
    @padding = opts.padding ? 0
    super()
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor
    @cornerRadius = opts.cornerRadius or 6
    @appearance = new BubblyAppearance @
  
  @createBubbleHelpIfHandStillOnWidget: (contents, widgetInvokingThis) ->
    # Only proceed if the invoking widget is still rooted in the world and the
    # hand is still over it. The hand is SCREEN-plane and bounds are PLANE-local — map the point into
    # the widget's plane so the containment holds for tilted widgets too (off any island the
    # mapping returns the same point; the raw-pointer lint's same-line shape).
    if widgetInvokingThis.root() == world and widgetInvokingThis.boundsContainPoint (widgetInvokingThis.screenPointToMyPlane world.hand.position())
      theBubble = new @ contents, widgetInvokingThis: widgetInvokingThis
      theBubble.openAt widgetInvokingThis.topRight()

  @cancelAllScheduledToolTips: ->
    @ongoingTimeouts.forEach (eachTimeout) =>
      clearTimeout eachTimeout
    @ongoingTimeouts.clear()

  @createInAWhileIfHandStillContainedInWidget: (widgetInvokingThis, contents, delay = 500) ->
    if Automator? and Automator.animationsPacingControl and
     Automator.state != Automator.IDLE
        @createBubbleHelpIfHandStillOnWidget contents, widgetInvokingThis
    else
      @ongoingTimeouts.add setTimeout (=>
        @createBubbleHelpIfHandStillOnWidget contents, widgetInvokingThis
        )
        , delay
  
  openAt: (pos) ->
    @_buildAndConnectChildren()
    @_applyMoveTo pos.subtract new Point 8, @height()
    @_moveWithin world
    world.add @
    # addShadow's own _fullChanged closes the invalidation (the add already set the
    # dedup flag) — no trailing repaint call needed.
    @addShadow()
    world.destroyToolTips()
    world.toolTipsList.add @
    
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    # re-build my contents
    if @contentsWidget
      @contentsWidget = @contentsWidget._destroyNoSettle()
    if @contents instanceof Widget
      @contentsWidget = @contents
    else if Utils.isString @contents
      # "sans-serif" passed explicitly: the old text widget defaulted an undefined font
      # to "sans-serif", whereas TextWdgt's default is 'Arial, sans-serif'.
      # Color.BLACK passed explicitly: old text widget forced black, TextWdgt
      # defaults to (37,37,37).
      @contentsWidget = new TextWdgt @contents,
        fontSize: WorldWdgt.preferencesAndSettings.bubbleHelpFontSize
        fontName: "sans-serif"
        italic: true
        color: Color.BLACK
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
      @contentsWidget = new TextWdgt @contents.toString(),
        fontSize: WorldWdgt.preferencesAndSettings.bubbleHelpFontSize
        fontName: "sans-serif"
        italic: true
        color: Color.BLACK
      @contentsWidget.alignCenter()
    @_addNoSettle @contentsWidget

    # the modern family does not self-size; make the tooltip text hug its
    # content before we read its width/height to size the bubble around it.
    @contentsWidget._sizeToTextAndDisableFittingNoSettle() if @contentsWidget instanceof TextWdgt

    # adjust my layout
    @__commitWidth @contentsWidget.width() + ((if @padding then @padding * 2 else @cornerRadius * 2))
    @__commitHeight @contentsWidget.height() + @cornerRadius + @padding * 2 + 2

    # position my contents
    @contentsWidget._applyMoveTo @position().add(
      new Point(@padding or @cornerRadius, @padding + 1))


