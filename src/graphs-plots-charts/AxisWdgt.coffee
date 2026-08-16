class AxisWdgt extends Widget

  majorDimLine: undefined
  ticksRectangles: undefined
  labelsTextBoxes: undefined
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

  # the tick pitch along the axis' long dimension: one slot more than the
  # tick count (shared by distanceOfAxisOriginFromEdge and _reLayout)
  _tickPitch: ->
    numberOfTicks = @max - @min + 1
    if @height() > @width()
      @height() / (numberOfTicks + 1)
    else
      @width() / (numberOfTicks + 1)

  distanceOfAxisOriginFromEdge: ->
    tickHeight = @_tickPitch()
    if @height() > @width()
      # vert axis
      return new Point -5, tickHeight
    else
      # horiz axis
      return new Point tickHeight, 5


  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    height = @height()
    width = @width()

    numberOfTicks = @max - @min + 1
    tickHeight = @_tickPitch()
    heightOfTheDrawnBar = (numberOfTicks - 1) * tickHeight

    thickness = 2
    labelSizeReduction = 0.7
    labelSpace = tickHeight* labelSizeReduction

    # Integer placement (Layer A): tickHeight is a legitimately-fractional MEASURE (height/(numberOfTicks+1));
    # the tick + label POSITIONS derived from it must commit as integer @bounds, so round each placement point.
    # The arrange-apply path no longer rounds for us -- see docs/archive/fractional-widget-bounds-investigation-plan.md (Path 2).
    if height > width
      @majorDimLine._applyBounds ((new Point @right() - 5, @top() + tickHeight).round()), new Point thickness, heightOfTheDrawnBar
    else
      @majorDimLine._applyBounds ((new Point @left() + tickHeight, @top() + 5).round()), new Point heightOfTheDrawnBar, thickness

    # _reLayout runs INSIDE the layout pass (recalculateLayouts), so the tick labels are positioned
    # AND texted through the non-settling APIs (_applyExtent / _applyMoveTo / _setTextNoSettle) -- a
    # public settling setText here would re-enter the settle tier and throw the flow-violation.
    for i in [0 ... numberOfTicks]
      if height > width
        @ticksRectangles[i]._applyMoveTo (new Point @right()-10, @top() + tickHeight + Math.round(i * tickHeight)).round()
        @ticksRectangles[i]._applyExtent new Point 5 + thickness, thickness

        @labelsTextBoxes[i]._setTextNoSettle "" + (@max - i)
        @labelsTextBoxes[i]._applyMoveTo (new Point @left(), @top() + tickHeight + Math.round(i * tickHeight) - labelSpace/2).round()
        @labelsTextBoxes[i]._applyExtent new Point width - 10, labelSpace
        @labelsTextBoxes[i].alignMiddle()
        @labelsTextBoxes[i].alignRight()

      else
        @ticksRectangles[i]._applyMoveTo (new Point @left() + tickHeight + Math.round(i * tickHeight), @top() + 5).round()
        @ticksRectangles[i]._applyExtent new Point thickness, 5 + thickness

        @labelsTextBoxes[i]._setTextNoSettle "" + (@min + i)
        @labelsTextBoxes[i]._applyMoveTo (new Point @left() + tickHeight + Math.round(i * tickHeight) - labelSpace/2, @top() + 5 + 5).round()
        @labelsTextBoxes[i]._applyExtent new Point labelSpace, height - 10
        @labelsTextBoxes[i].alignTop()
        @labelsTextBoxes[i].alignCenter()

