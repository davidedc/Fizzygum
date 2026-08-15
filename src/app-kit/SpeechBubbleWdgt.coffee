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

  constructor: (@contents="hello") ->
    super()
    @color = WorldWdgt.preferencesAndSettings.menuBackgroundColor
    @padding = 0
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor
    @cornerRadius = 6
    @appearance = new BubblyAppearance @
    @toolTipMessage = "speech bubble"
    @_buildAndConnectChildren()
    @minimumExtent = new Point 10,10
    @extentToGetWhenDraggedFromGlassBox = new Point 105,80


  colloquialName: ->
    "speech bubble"
  
  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @contentsWidget = new TextWdgt @contents,
      fontSize: WorldWdgt.preferencesAndSettings.bubbleHelpFontSize
      italic: true
      color: "center"

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



