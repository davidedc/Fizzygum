# when invoked using...
#    createInAWhileIfHandStillContainedInWidget / openAt
#	... I can temporarily display any widget.
# (is you just use the default constructor it will just sit there
# and basically _not_ behave like a tool tip)
# Note that I'm not a PopUp, for example I can't be pinned.
# I'm always attached to the world, without any layout constraints.
#
# I am a PLATE, the label plate of docs/plans/redesign/UI-guidelines.md §5.3 (a desktop icon's
# caption stands on its sibling, painted by DesktopIconAppearance): a rounded box in my fill, with
# no border -- a bordered rounded rectangle means "press me", and I am not pressable -- and no tail,
# casting the desktop shadow. My margin around my contents is my own padding, never my corner
# radius. A text shows each of its lines centred, each on its own line box (the tooltip font role's
# line height), one under the other.

class ToolTipWdgt extends Widget

  @ongoingTimeouts: new Set

  contents: undefined
  # the plate's margin around my contents: at each side of them, and above and below them
  horizontalPadding: undefined
  verticalPadding: undefined
  widgetInvokingThis: undefined
  # per class, not pulled up: this extends Widget, not BoxWdgt
  cornerRadius: undefined
  # the children showing @contents, built when the tip is opened and torn down with it: one
  # TextWdgt per line of a text, or the one widget showing any other contents
  contentsWidgets: undefined

  # An opener may name my fill, my rounding, and a padding (both axes alike); what it leaves out
  # comes from the theme's tooltip roles and metrics.
  constructor: (@contents = "text here", opts = {}) ->
    @widgetInvokingThis = opts.widgetInvokingThis
    @color = opts.color ? WorldWdgt.theme.tooltipFill
    @horizontalPadding = opts.padding ? WorldWdgt.theme.tooltipHorizontalPadding
    @verticalPadding = opts.padding ? WorldWdgt.theme.tooltipVerticalPadding
    super()
    @cornerRadius = opts.cornerRadius ? WorldWdgt.theme.tooltipCornerRadius
    # the rounded box, and no strokeColor: a plate paints its fill and no border
    @appearance = new BoxyAppearance @
  
  @createBubbleHelpIfHandStillOnWidget: (contents, widgetInvokingThis) ->
    # Only proceed if the invoking widget is still rooted in the world and the
    # hand is still over it. The hand is SCREEN-plane and bounds are PLANE-local — map the point into
    # the widget's plane so the containment holds for tilted widgets too (off any island the
    # mapping returns the same point; the raw-pointer lint's same-line shape).
    if widgetInvokingThis.root() == world and widgetInvokingThis.boundsContainPoint (widgetInvokingThis.screenPointToMyPlane world.hand.position())
      theTip = new @ contents, widgetInvokingThis: widgetInvokingThis
      # the tip is a WORLD child placed against a widget whose plane may be MAPPED (scrolled
      # pane, tilted island) — aim at the widget's on-screen corner, not its plane corner
      # (identity for the common unmapped widget). Screen-family points can be FRACTIONAL
      # under a tilt: round before the integer placement funnel.
      theTip.openAt (widgetInvokingThis.localPointToScreen widgetInvokingThis.topRight()).round()

  @cancelAllScheduledToolTips: ->
    @ongoingTimeouts.forEach (eachTimeout) =>
      clearTimeout eachTimeout
    @ongoingTimeouts.clear()

  @createInAWhileIfHandStillContainedInWidget: (widgetInvokingThis, contents, delay = 500) ->
    if Automator? and Automator.animationsPacingControl and
     Automator.state != Automator.IDLE
        @createBubbleHelpIfHandStillOnWidget contents, widgetInvokingThis
    else
      # the set tracks PENDING timeouts only (cancelAllScheduledToolTips clears them):
      # a fired timeout removes itself, otherwise the set grows for the life of the page
      timeoutID = setTimeout (=>
        @ongoingTimeouts.delete timeoutID
        @createBubbleHelpIfHandStillOnWidget contents, widgetInvokingThis
        )
        , delay
      @ongoingTimeouts.add timeoutID
  
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
    if @contentsWidgets?
      eachContentsWidget._destroyNoSettle() for eachContentsWidget in @contentsWidgets
    if @contents instanceof Widget
      @contentsWidgets = [@contents]
      @_addNoSettle @contents
      slotHeight = @contents.height()
    # canvas-like (a DOM canvas OR an SWCanvasElement under the software backend)
    else if @contents? and typeof @contents.getContext is "function"
      canvasWidget = new Widget
      canvasWidget.__commitWidth @contents.width
      canvasWidget.__commitHeight @contents.height
      canvasWidget.backBuffer = @contents
      canvasWidget.backBufferContext = canvasWidget.backBuffer.getContext "2d"
      @contentsWidgets = [canvasWidget]
      @_addNoSettle canvasWidget
      slotHeight = canvasWidget.height()
    else
      # a text, or anything else shown as its string: one TextWdgt per line, in the tooltip's own
      # font and ink (both passed explicitly rather than left to TextWdgt's defaults), each hugging
      # its line -- the modern family does not self-size -- before I read its extent
      @contentsWidgets = for eachLine in @contents.toString().split "\n"
        lineWidget = new TextWdgt eachLine,
          fontRole: WorldWdgt.theme.fonts.tooltip
          color: WorldWdgt.theme.tooltipText
        lineWidget.alignCenter()
        @_addNoSettle lineWidget
        lineWidget._sizeToTextAndDisableFittingNoSettle()
        lineWidget
      # every line spans the widest one, so each centres its own text across the same width
      linesWidth = 0
      linesWidth = Math.max linesWidth, eachLineWidget.width() for eachLineWidget in @contentsWidgets
      eachLineWidget.__commitWidth linesWidth for eachLineWidget in @contentsWidgets
      # each line's slot is its own line box (the tooltip font role's line height), which the line
      # hugs, so the lines stack one line box apart
      slotHeight = @contentsWidgets[0].linePitch @contentsWidgets[0].originallySetFontSize

    # adjust my layout: my padding around the stacked slots
    @__commitWidth @contentsWidgets[0].width() + 2 * @horizontalPadding
    @__commitHeight @contentsWidgets.length * slotHeight + 2 * @verticalPadding

    # position my contents: each widget at the top of its slot, the slots stacked down from my top
    # padding (a slot is as tall as what stands in it)
    for eachContentsWidget, slotIndex in @contentsWidgets
      eachContentsWidget._applyMoveTo @position().add new Point @horizontalPadding, @verticalPadding + slotIndex * slotHeight

