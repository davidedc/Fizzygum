# the speech bubble is similar to the Tooltip,
# however it's more like the callouts of some
# famous presentation software: you drop them
# somewhere and you type text in them. If you resize
# them, the text inside them is resized too.
# They don't pop up within a certain time.

class SpeechBubbleWdgt extends Widget

  contents: nil
  padding: nil # additional vertical pixels
  widgetInvokingThis: nil

  constructor: (@contents="hello") ->
    # console.log "bubble super"
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

    # console.log @color

  colloquialName: ->
    "speech bubble"
  
  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @contentsWidget = new TextWdgt(
      @contents,
      WorldWdgt.preferencesAndSettings.bubbleHelpFontSize,
      nil,
      false,
      true,
      "center")

    @contentsWidget.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @contentsWidget.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @contentsWidget.alignMiddle()
    @contentsWidget.alignCenter()
    @contentsWidget.isEditable = true


    @_addNoSettle @contentsWidget
    @_invalidateLayout()


  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  _reLayout: (newBoundsForThisLayout) ->

    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    # adjust my layout
    @_applyWidth newBoundsForThisLayout.width()
    @_applyHeight newBoundsForThisLayout.height()

    # adjust layout of my contents
    @contentsWidget._reLayout (
      (new Rectangle 0, 0,
        (newBoundsForThisLayout.width() - (2 * @cornerRadius)),
        (newBoundsForThisLayout.height() - (2 * @cornerRadius) - newBoundsForThisLayout.height()/5))
      .translateBy @position().add @padding + @cornerRadius
    )

    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()


