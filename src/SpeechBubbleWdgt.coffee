# the speech bubble is similar to the Tooltip,
# however it's more like the callouts of some
# famous presentation software: you drop them
# somewhere and you type text in them. If you resize
# them, the text inside them is resized too.
# They don't pop up within a certain time.

class SpeechBubbleWdgt extends Widget

  @ongoingTimeouts: []

  contents: nil
  padding: nil # additional vertical pixels
  morphInvokingThis: nil

  constructor: (@contents="hello") ->
    # console.log "bubble super"
    super()
    @color = WorldMorph.preferencesAndSettings.menuBackgroundColor
    @padding = 0
    @strokeColor = WorldMorph.preferencesAndSettings.menuStrokeColor
    @cornerRadius = 6
    @appearance = new BubblyAppearance @
    @toolTipMessage = "speech bubble"
    @buildAndConnectChildren()
    @minimumExtent = new Point 10,10
    @extentToGetWhenDraggedFromGlassBox = new Point 105,80

    # console.log @color
  
  buildAndConnectChildren: ->
    @contentsMorph = new TextMorph2(
      @contents,
      WorldMorph.preferencesAndSettings.bubbleHelpFontSize,
      nil,
      false,
      true,
      "center")

    @contentsMorph.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @contentsMorph.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @contentsMorph.alignMiddle()
    @contentsMorph.alignCenter()
    @contentsMorph.isEditable = true


    @add @contentsMorph
    @invalidateLayout()

  rawSetExtent: (aPoint) ->
    super
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

    # adjust my layout
    @silentRawSetWidth newBoundsForThisLayout.width()
    @silentRawSetHeight newBoundsForThisLayout.height()

    @contentsMorph.rawSetWidth newBoundsForThisLayout.width() - (2 * @cornerRadius)
    @contentsMorph.rawSetHeight newBoundsForThisLayout.height() - (2 * @cornerRadius) - newBoundsForThisLayout.height()/5


    # position my contents
    @contentsMorph.fullRawMoveTo @position().add(
      new Point(@padding + @cornerRadius, @padding + @cornerRadius))

    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


