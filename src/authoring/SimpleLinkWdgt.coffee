class SimpleLinkWdgt extends Widget


  tempPromptEntryField: undefined
  textWidget: undefined

  outputTextArea: undefined
  outputTextAreaText: undefined

  externalLinkIcon: undefined

  externalPadding: 5
  # the internal padding is the space between the internal
  # components. It doesn't necessarily need to be equal to the
  # external padding
  internalPadding: 5

  descriptionString: undefined
  linkString: undefined

  constructor: (@descriptionString = "insert link caption here", @linkString = "http://www.google.com") ->
    super new Point 405, 50
    @_buildAndConnectChildren()


  # open my link's URL in a new browser tab. The external-link button calls this instead of
  # testing `@parent instanceof SimpleLinkWdgt` and reaching into my outputTextArea.
  # (type-test-elimination campaign)
  openExternalURL: ->
    window.open @outputTextArea.text

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @tempPromptEntryField = new StringWdgt @descriptionString
    @tempPromptEntryField.isEditable = true
    @tempPromptEntryField.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @tempPromptEntryField.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @tempPromptEntryField.alignMiddle()
    @tempPromptEntryField.alignRight()
    @_addNoSettle @tempPromptEntryField

    @outputTextArea = new StringWdgt @linkString
    @outputTextArea.isEditable = true
    @outputTextArea.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @outputTextArea.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @outputTextArea.alignMiddle()
    @outputTextArea.alignRight()
    @_addNoSettle @outputTextArea
    @_createLinkIcon()
    @_addNoSettle @externalLinkIcon

    @_invalidateLayout()

  _createLinkIcon: ->
    @externalLinkIcon = new ExternalLinkButtonWdgt

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    availableHeight = @height() - 2 * @externalPadding - @internalPadding
    text1Height = Math.round availableHeight * 50/100
    text2Height = availableHeight - text1Height - @externalPadding

    squareSize = Math.min @width(), @height() - 2 * @externalPadding

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point @width() - 2 * @externalPadding - @internalPadding - squareSize, text1Height

    if @outputTextArea.parent == @
      @outputTextArea._applyBounds (new Point @left() + @externalPadding, @tempPromptEntryField.bottom() + @internalPadding), new Point @width() - 2 * @externalPadding - @internalPadding - squareSize, text2Height

    if @externalLinkIcon.parent == @
      @externalLinkIcon._applyBounds (new Point @right() - @externalPadding - squareSize, @top() + @externalPadding), new Point squareSize, squareSize

