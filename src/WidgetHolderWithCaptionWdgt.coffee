# This is what typically people refer to as "icons", however that's not
# quite precise. An icon is just a graphic symbol, it doesn't have a caption per se.
# This widget has a caption instead. Also, since it can hold any widget, the
# final name is WidgetHolderWithCaptionWdgt.

class WidgetHolderWithCaptionWdgt extends Widget

  label: nil

  constructor: (@labelContent, @icon) ->
    super()
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    @_applyExtentAndNotify new Point 95, 95
    @_addNoSettle @icon
    @label = new StringWdgt @labelContent, WorldWdgt.preferencesAndSettings.shortcutsFontSize
    @label.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @label.color = Color.WHITE
    @label.hasDarkOutline = true
    @_addNoSettle @label, nil, nil, true
    @label.alignCenter()
    @label.alignMiddle()
    @label.isEditable = true
    # update layout
    @_invalidateLayout()

  # I am a desktop icon (an icon with a caption). isDesktopIcon replaces the
  # `instanceof WidgetHolderWithCaptionWdgt` tests that find/skip icons among desktop
  # children; participatesInIconGrid additionally drives the auto grid-positioning of
  # newly-created icons -- BasementOpenerWdgt overrides it to false (it is an icon but the
  # desktop places it itself, not the grid). (type-test-elimination campaign)
  isDesktopIcon: ->
    true

  participatesInIconGrid: ->
    true


  setColor: (theColor, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken

    @icon.setColor theColor

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  _resizeToWithoutSpacing: ->
    @_applyExtentAndNotify new Point @widthWithoutSpacing(), @widthWithoutSpacing()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_resizeToWithoutSpacing()
    @_applyExtentAndNotify new Point newWidth, newWidth
    @_reLayout()
    @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  _reLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # TODO shouldn't be calling this _applyBoundsAndNotify from here,
    # rather use super
    @_applyBoundsAndNotify newBoundsForThisLayout

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

    height = @height()
    width = @width()

    squareDim = Math.min width, height

     # p0 is the origin, the origin being in the bottom-left corner
    p0 = @topLeft()

    # now the origin if on the left edge, in the middle height of the widget
    p0 = p0.add new Point width/2, height/2
    
    # now the origin is in the middle height of the widget,
    # on the left edge of the square inscribed in the widget
    p0 = p0.subtract new Point squareDim/2, squareDim/2

    @icon._applyExtentAndNotify (new Point squareDim, squareDim*8/10).round()
    @icon._applyMoveToAndNotify p0.round()
    @label._applyExtentAndNotify (new Point squareDim, squareDim*2/10).round()
    @label._applyMoveToAndNotify (p0.add new Point 0, squareDim*8/10).round()


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()