class AxisWdgt extends Widget

  majorDimLine: nil
  ticksRectangles: nil
  labelsTextBoxes: nil
  min: 0
  max: 0

  constructor: (@min = -15, @max = 15) ->
    super()
    @ticksRectangles = []
    @labelsTextBoxes = []
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @majorDimLine = new RectangleWdgt
    @majorDimLine.minimumExtent = new Point 1,1

    @_addNoSettle @majorDimLine

    numberOfTicks = @max - @min + 1
    for i in [0 ... numberOfTicks]
      @ticksRectangles[i] = new RectangleWdgt
      @ticksRectangles[i].minimumExtent = new Point 1,1
      @_addNoSettle @ticksRectangles[i]

      @labelsTextBoxes[i] = new StringWdgt ""
      @labelsTextBoxes[i].fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
      @labelsTextBoxes[i].fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
      @_addNoSettle @labelsTextBoxes[i]

    @_invalidateLayout()

  # TODO some duplication of code here with
  # the method below
  distanceOfAxisOriginFromEdge: ->
    height = @height()
    width = @width()

    numberOfTicks = @max - @min + 1
    if height > width
      # vert axis
      tickHeight = height/(numberOfTicks + 1)
      return new Point -5, tickHeight
    else
      # horiz axis
      tickHeight = width/(numberOfTicks + 1)
      return new Point tickHeight, 5


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

    numberOfTicks = @max - @min + 1
    if height > width
      tickHeight = height/(numberOfTicks + 1)
    else
      tickHeight = width/(numberOfTicks + 1)
    heightOfTheDrawnBar = (numberOfTicks - 1) * tickHeight

    thickness = 2
    labelSizeReduction = 0.7
    labelSpace = tickHeight* labelSizeReduction

    if height > width
      @majorDimLine._applyMoveToAndNotify new Point @right() - 5, @top() + tickHeight
      @majorDimLine._applyExtentAndNotify new Point thickness, heightOfTheDrawnBar
    else
      @majorDimLine._applyMoveToAndNotify new Point @left() + tickHeight, @top() + 5
      @majorDimLine._applyExtentAndNotify new Point heightOfTheDrawnBar, thickness

    # _reLayout runs INSIDE the layout pass (recalculateLayouts), so the tick labels are positioned
    # AND texted through the non-settling APIs (_applyExtentAndNotify / _applyMoveToAndNotify / _setTextNoSettle) -- a
    # public settling setText here would re-enter the settle tier and throw the flow-violation.
    for i in [0 ... numberOfTicks]
      if height > width
        @ticksRectangles[i]._applyMoveToAndNotify new Point @right()-10, @top() + tickHeight + Math.round(i * tickHeight)
        @ticksRectangles[i]._applyExtentAndNotify new Point 5 + thickness, thickness

        @labelsTextBoxes[i]._setTextNoSettle "" + (@max - i)
        @labelsTextBoxes[i]._applyMoveToAndNotify new Point @left(), @top() + tickHeight + Math.round(i * tickHeight) - labelSpace/2
        @labelsTextBoxes[i]._applyExtentAndNotify new Point width - 10, labelSpace
        @labelsTextBoxes[i].alignMiddle()
        @labelsTextBoxes[i].alignRight()

      else
        @ticksRectangles[i]._applyMoveToAndNotify new Point @left() + tickHeight + Math.round(i * tickHeight), @top() + 5
        @ticksRectangles[i]._applyExtentAndNotify new Point thickness, 5 + thickness

        @labelsTextBoxes[i]._setTextNoSettle "" + (@min + i)
        @labelsTextBoxes[i]._applyMoveToAndNotify new Point @left() + tickHeight + Math.round(i * tickHeight) - labelSpace/2, @top() + 5 + 5
        @labelsTextBoxes[i]._applyExtentAndNotify new Point labelSpace, height - 10
        @labelsTextBoxes[i].alignTop()
        @labelsTextBoxes[i].alignCenter()


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()