# IconWithTextWdgt //////////////////////////////////////////////////////

class IconWithTextWdgt extends Morph

  labl: nil

  constructor: (@labelContent, @icon) ->
    super()
    @rawSetExtent new Point 95, 95
    @add @icon
    @label = new StringMorph2 @labelContent
    @label.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.color = new Color 255, 255, 255
    @add @label, nil, nil, true
    @label.alignCenter()
    @label.alignMiddle()
    # update layout
    @invalidateLayout()

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

  mouseClickLeft: ->
    #world.inform "clicked!"
    world.setColor new Color 0,255,0

  mouseDoubleClick: ->
    world.setColor new Color 255,0,0
  
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
    # bounds of the parent Morph. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    @icon.setExtent new Point @width(), Math.round(@height()*8/10)
    @icon.fullRawMoveTo new Point @left(), @top()
    @label.setExtent new Point @width(), Math.round(@height()*2/10)
    @label.fullRawMoveTo new Point @left(), @top() + Math.round(@height()*8/10)


    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()