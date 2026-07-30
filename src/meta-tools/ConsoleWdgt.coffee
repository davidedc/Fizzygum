class ConsoleWdgt extends CodeAreaWdgt

  runSelectionButton: nil
  runAllButton: nil

  functionFromCompiledCode: nil

  constructor: (@target) ->
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Console for: " + @target.colloquialName().toLowerCase()

  _buildAndConnectChildrenNoSettle: ->

    @_buildMonoCodeAreaNoSettle ""

    # "do" buttons -------------------------------
    # NOTE that you can also "doAll" or "doSelection" via
    # the context menu entries in the text panel!
    @runSelectionButton = new SimpleButtonWdgt true, @, "doSelection", "run selection"
    # editor chrome: "run selection" reads the current text selection, so its
    # press must not steal the focus pointer or end the edit (§5.D D2a).
    @runSelectionButton.actsAsEditorChrome = true
    @_addNoSettle @runSelectionButton

    @runAllButton = new SimpleButtonWdgt true, @, "doAll", "run all"
    @_addNoSettle @runAllButton
    # ---------------------------------------

    @_invalidateLayout()

  doSelection: ->
    savedScript = @textWidget.selection()
    compiled = compileFGCode savedScript, true
    functionFromCompiledCode = new Function compiled
    functionFromCompiledCode.call @target

  doAll: ->
    savedScript = @textWidget.text
    compiled = compileFGCode savedScript, true
    functionFromCompiledCode = new Function compiled
    functionFromCompiledCode.call @target

  # I contribute my own "run" entries to the context menu of the text I contain (run the
  # selection if any, then run all), targeting my doSelection/doAll. The text calls this
  # instead of reaching up three levels and testing `instanceof ConsoleWdgt`; a text not in a
  # console adds its own plain "run contents" instead. (type-test-elimination campaign)
  addRunMenuEntriesForText: (menu, textWidget) ->
    if textWidget.currentlySelecting()
      menu.addMenuItem "run selection", @, "doSelection"
    menu.addMenuItem "run contents", @, "doAll"

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyGrantedBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this widget are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    textHeight = @height() - 2 * @externalPadding - @internalPadding - 15
    textBottom = @top() + @externalPadding + textHeight
    textWidth = @width() - 2 * @externalPadding
    # Integer placement (Layer A): the two run-buttons share this width and are laid side by side, so a
    # fractional /2 makes the second button's origin (= first's right edge) fractional -- round it here so both
    # commit integer @bounds. docs/archive/fractional-widget-bounds-investigation-plan.md (Path 2).
    buttonsWidth = Math.round (textWidth - 2 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize)/2

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point textWidth, textHeight


    # buttons -------------------------------
    

    if @runSelectionButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding, textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonsWidth, 15
      @runSelectionButton._reLayout buttonBounds

    if @runAllButton.parent == @
      buttonBounds = new Rectangle new Point buttonBounds.right() + @internalPadding, textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonsWidth, 15
      @runAllButton._reLayout buttonBounds


    # ----------------------------------------------


    world.maybeEnableTrackChanges()
    @_fullChanged()

    super
    @_markLayoutAsFixed()

