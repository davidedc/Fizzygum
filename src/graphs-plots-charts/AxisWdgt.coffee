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


  # immediate-resize-relay-exempt: no polymorphic raw _applyExtent receiver of this class (2026-07-16 census); containers size me via the settle-driven _reLayout handing bounds, or the override-BYPASSING _applyExtentBase (deliberately outside this mechanism)
  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout

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

    # Integer placement (Layer A): tickHeight is a legitimately-fractional MEASURE (height/(numberOfTicks+1));
    # the tick + label POSITIONS derived from it must commit as integer @bounds, so round each placement point.
    # The arrange-apply path no longer rounds for us -- see docs/fractional-widget-bounds-investigation-plan.md (Path 2).
    if height > width
      @majorDimLine._applyMoveTo (new Point @right() - 5, @top() + tickHeight).round()
      @majorDimLine._applyExtent new Point thickness, heightOfTheDrawnBar
    else
      @majorDimLine._applyMoveTo (new Point @left() + tickHeight, @top() + 5).round()
      @majorDimLine._applyExtent new Point heightOfTheDrawnBar, thickness

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


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()

