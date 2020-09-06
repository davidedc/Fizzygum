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
    @buildAndConnectChildren()

  buildAndConnectChildren: ->

    @majorDimLine = new RectangleMorph
    @majorDimLine.minimumExtent = new Point 1,1

    @add @majorDimLine

    numberOfTicks = @max - @min + 1
    for i in [0 ... numberOfTicks]
      @ticksRectangles[i] = new RectangleMorph
      @ticksRectangles[i].minimumExtent = new Point 1,1
      @add @ticksRectangles[i]

      @labelsTextBoxes[i] = new StringMorph2 ""
      @labelsTextBoxes[i].fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
      @labelsTextBoxes[i].fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
      @add @labelsTextBoxes[i]

    @invalidateLayout()

  rawSetExtent: (aPoint) ->
    super
    @invalidateLayout()

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


  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts
    #  debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      return

    @rawSetBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

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
      @majorDimLine.fullRawMoveTo new Point @right() - 5, @top() + tickHeight
      @majorDimLine.setExtent new Point thickness, heightOfTheDrawnBar
    else
      @majorDimLine.fullRawMoveTo new Point @left() + tickHeight, @top() + 5
      @majorDimLine.setExtent new Point heightOfTheDrawnBar, thickness 

    for i in [0 ... numberOfTicks]
      if height > width
        @ticksRectangles[i].fullRawMoveTo new Point @right()-10, @top() + tickHeight + Math.round(i * tickHeight)
        @ticksRectangles[i].setExtent new Point 5 + thickness, thickness

        @labelsTextBoxes[i].setText "" + (@max - i)
        @labelsTextBoxes[i].fullRawMoveTo new Point @left(), @top() + tickHeight + Math.round(i * tickHeight) - labelSpace/2
        @labelsTextBoxes[i].setExtent new Point width - 10, labelSpace
        @labelsTextBoxes[i].alignMiddle()
        @labelsTextBoxes[i].alignRight()

      else
        @ticksRectangles[i].fullRawMoveTo new Point @left() + tickHeight + Math.round(i * tickHeight), @top() + 5
        @ticksRectangles[i].setExtent new Point thickness, 5 + thickness

        @labelsTextBoxes[i].setText "" + (@min + i)
        @labelsTextBoxes[i].fullRawMoveTo new Point @left() + tickHeight + Math.round(i * tickHeight) - labelSpace/2, @top() + 5 + 5
        @labelsTextBoxes[i].setExtent new Point labelSpace, height - 10
        @labelsTextBoxes[i].alignTop()
        @labelsTextBoxes[i].alignCenter()


    trackChanges.pop()
    @fullChanged()

    super
    @layoutIsValid = true

    if Automator and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()