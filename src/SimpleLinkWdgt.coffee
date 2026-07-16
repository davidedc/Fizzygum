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
    @_buildAndConnectChildren()

  colloquialName: ->
    "Simple link"

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

  # (ordered-downwalk plan §9-N3, 2026-07-16) Replaces the Stage-A-era exempt marker: its census
  # boilerplate answered "who raw-_applyExtents me?", but Stage B3 changed the question to "can an
  # ARRANGE move/resize me without my _reLayout running?" -- yes: I sit as a vertical-stack element in documents,
  # so I can sit bypass-sized (_applyExtentBase) with my children laid for the OLD frame. Declaring
  # puts me under the settle engine's frame-changed child re-lay (__reLayoutOneSettleNode injection)
  # and the base Widget._applyExtent immediate-resize hook.
  _placesChildrenInLayout: ->
    true

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
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

    availableHeight = @height() - 2 * @externalPadding - @internalPadding
    text1Height = Math.round availableHeight * 50/100
    text2Height = availableHeight - text1Height - @externalPadding

    squareSize = Math.min @width(), @height() - 2 * @externalPadding

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField._applyExtent new Point @width() - 2 * @externalPadding - @internalPadding - squareSize, text1Height

    if @outputTextArea.parent == @
      @outputTextArea._applyMoveTo new Point @left() + @externalPadding, @tempPromptEntryField.bottom() + @internalPadding
      @outputTextArea._applyExtent new Point @width() - 2 * @externalPadding - @internalPadding - squareSize, text2Height

    if @externalLinkIcon.parent == @
      @externalLinkIcon._applyMoveTo new Point @right() - @externalPadding - squareSize, @top() + @externalPadding
      @externalLinkIcon._applyExtent new Point squareSize, squareSize


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()

