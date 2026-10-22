# the speech bubble is similar to the Tooltip,
# however it's more like the callouts of some
# famous presentation software: you drop them
# somewhere and you type text in them. If you resize
# them, the text inside them is resized too.
# They don't pop up within a certain time.

class SpeechBubbleWdgt extends Widget

  contents: undefined
  padding: undefined # additional vertical pixels
  widgetInvokingThis: undefined
  # per class, not pulled up: this extends Widget, not BoxWdgt
  cornerRadius: undefined
  # the TextWdgt child holding @contents
  contentsWidget: undefined
  # the size a bubble takes when dragged out of the glass box
  extentToGetWhenDraggedFromGlassBox: undefined

  # no fill or stroke colour of my own until one is set on me (my color is declared undefined here,
  # over Widget's content default; my strokeColor is Widget's, undefined): until then my
  # BubblyAppearance paints me in the speech bubble's roles, read as I am painted (_surfaceFill,
  # _surfaceStroke), so a bubble saved, loaded or duplicated wears the world's look
  color: undefined

  constructor: (@contents="hello") ->
    super()
    @padding = 0
    @cornerRadius = WorldWdgt.theme.speechBubbleCornerRadius
    @appearance = new BubblyAppearance @
    @toolTipMessage = "speech bubble"
    @_buildAndConnectChildren()
    @minimumExtent = new Point 10,10
    @extentToGetWhenDraggedFromGlassBox = new Point 105,80

  # the fill and the 1 px border my BubblyAppearance paints me in while I hold no colour of my own
  _surfaceFill: ->
    WorldWdgt.theme.speechBubbleFill

  _surfaceStroke: ->
    WorldWdgt.theme.speechBubbleStroke


  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    # The text's ink is the speech bubble's text role, given here as the text is built. The
    # centring this widget wants is @contentsWidget.alignCenter() below — the layout verb, not a
    # constructor argument.
    theme = WorldWdgt.theme
    @contentsWidget = new TextWdgt @contents,
      fontRole: theme.fonts.speechBubble
      italic: true
      color: theme.speechBubbleText

    @contentsWidget.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @contentsWidget.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @contentsWidget.alignMiddle()
    @contentsWidget.alignCenter()
    @contentsWidget.isEditable = true


    @_addNoSettle @contentsWidget
    @_invalidateLayout()


  _reLayout: (newBoundsForThisLayout) ->


    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    @_repaintAsOneUnit =>

      # adjust my layout -- apply BOTH position and size up front (was _applyWidth + _applyHeight,
      # which left the origin stale, so @position() below lagged one cadence on a move)
      @_applyGrantedBounds newBoundsForThisLayout

      @contentsWidget._reLayout (
        (new Rectangle 0, 0,
          (newBoundsForThisLayout.width() - (2 * @cornerRadius)),
          (newBoundsForThisLayout.height() - (2 * @cornerRadius) - newBoundsForThisLayout.height()/5))
        .translateBy @position().add @padding + @cornerRadius
      )

    super
    @_markLayoutAsFixed()



