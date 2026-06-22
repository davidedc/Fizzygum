class SimpleLinkWdgt extends Widget


  tempPromptEntryField: nil
  textWidget: nil

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
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    @tempPromptEntryField = new StringWdgt @descriptionString
    @tempPromptEntryField.isEditable = true
    @tempPromptEntryField.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @tempPromptEntryField.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @tempPromptEntryField.alignMiddle()
    @tempPromptEntryField.alignRight()
    @add @tempPromptEntryField

    @outputTextArea = new StringWdgt @linkString
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

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  _reLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

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


    world.maybeEnableTrackChanges()
    @fullChanged()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    super
    @markLayoutAsFixed()

