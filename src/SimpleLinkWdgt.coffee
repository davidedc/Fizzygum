class SimpleLinkWdgt extends Widget


  tempPromptEntryField: nil
  textMorph: nil

  outputTextArea: nil
  outputTextAreaText: nil

  externalLinkIcon: nil

  externalPadding: 5
  # the internal padding is the space between the internal
  # components. It doesn't necessarily need to be equal to the
  # external padding
  internalPadding: 5

  descriptionString: nil
  linkString: nil

  constructor: (@descriptionString = "insert link caption here", @linkString = "http://www.google.com") ->
    super new Point 405, 50
    @buildAndConnectChildren()

  colloquialName: ->
    "Simple link"

  buildAndConnectChildren: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @tempPromptEntryField = new StringMorph2 @descriptionString
    @tempPromptEntryField.isEditable = true
    @tempPromptEntryField.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @tempPromptEntryField.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @tempPromptEntryField.alignMiddle()
    @tempPromptEntryField.alignRight()
    @add @tempPromptEntryField

    @outputTextArea = new StringMorph2 @linkString
    @outputTextArea.isEditable = true
    @outputTextArea.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @outputTextArea.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @outputTextArea.alignMiddle()
    @outputTextArea.alignRight()
    @add @outputTextArea
    @createLinkIcon()
    @add @externalLinkIcon

    @invalidateLayout()

  createLinkIcon: ->
    @externalLinkIcon = new ExternalLinkButtonWdgt

  rawSetExtent: (aPoint) ->
    super
    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    if @isCollapsed()
      @layoutIsValid = true
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
    world.trackChanges.push false

    availableHeight = @height() - 2 * @externalPadding - @internalPadding
    text1Height = Math.round availableHeight * 50/100
    text2Height = availableHeight - text1Height - @externalPadding

    squareSize = Math.min @width(), @height() - 2 * @externalPadding

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField.rawSetExtent new Point @width() - 2 * @externalPadding - @internalPadding - squareSize, text1Height

    if @outputTextArea.parent == @
      @outputTextArea.fullRawMoveTo new Point @left() + @externalPadding, @tempPromptEntryField.bottom() + @internalPadding
      @outputTextArea.rawSetExtent new Point @width() - 2 * @externalPadding - @internalPadding - squareSize, text2Height

    if @externalLinkIcon.parent == @
      @externalLinkIcon.fullRawMoveTo new Point @right() - @externalPadding - squareSize, @top() + @externalPadding
      @externalLinkIcon.rawSetExtent new Point squareSize, squareSize


    world.trackChanges.pop()
    @fullChanged()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    super
    @layoutIsValid = true

