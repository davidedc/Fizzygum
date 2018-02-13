# WidgetHolderWithCaptionWdgt //////////////////////////////////////////////////////

# This is what typically people refer to as "icons", however that's not
# quite precise. An icon is just a symbol, it doesn't have a caption per se.
# This widget has a caption instead. Also, since it can hold any widget, the
# final name is WidgetHolderWithCaptionWdgt.

class WidgetHolderWithCaptionWdgt extends Widget

  labl: nil

  constructor: (@labelContent, @icon) ->
    super()
    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    @rawSetExtent new Point 95, 95
    @add @icon
    @label = new StringMorph2 @labelContent
    @label.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.color = new Color 255, 255, 255
    @label.hasDarkOutline = true
    @add @label, nil, nil, true
    @label.alignCenter()
    @label.alignMiddle()
    @label.isEditable = true
    # update layout
    @invalidateLayout()


  setColor: (theColor, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken

    @icon.setColor theColor

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  rawResizeToWithoutSpacing: ->
    @rawSetExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()
    @invalidateLayout()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    @rawResizeToWithoutSpacing()
    @rawSetExtent new Point newWidth, newWidth
    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

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
      @notifyChildrenThatParentHasReLayouted()
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

    squareDim = Math.min width, height

     # p0 is the origin, the origin being in the bottom-left corner
    p0 = @topLeft()

    # now the origin if on the left edge, in the middle height of the morph
    p0 = p0.add new Point width/2, height/2
    
    # now the origin is in the middle height of the morph,
    # on the left edge of the square incribed in the morph
    p0 = p0.subtract new Point squareDim/2, squareDim/2

    @icon.setExtent (new Point squareDim, squareDim*8/10).round()
    @icon.fullRawMoveTo p0.round()
    @label.setExtent (new Point squareDim, squareDim*2/10).round()
    @label.fullRawMoveTo (p0.add new Point 0, squareDim*8/10).round()


    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()