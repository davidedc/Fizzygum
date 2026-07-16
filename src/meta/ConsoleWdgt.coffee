class ConsoleWdgt extends Widget

  tempPromptEntryField: nil
  textWidget: nil

  runSelectionButton: nil
  runAllButton: nil

  functionFromCompiledCode: nil

  # the external padding is the space between the edges
  # of the container and all of its internals. The reason
  # you often set this to zero is because windows already put
  # contents inside themselves with a little padding, so this
  # external padding is not needed. Useful to keep it
  # separate and know that it's working though.
  externalPadding: 0
  # the internal padding is the space between the internal
  # components. It doesn't necessarily need to be equal to the
  # external padding
  internalPadding: 5

  constructor: (@target) ->
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Console for: " + @target.colloquialName().toLowerCase()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt "", false, 5
    @tempPromptEntryField.configureAsMonoTextPanel true
    @textWidget = @tempPromptEntryField.textWdgt
    @_addNoSettle @tempPromptEntryField

    # "do" buttons -------------------------------
    # NOTE that you can also "doAll" or "doSelection" via
    # the context menu entries in the text panel!
    @runSelectionButton = new SimpleButtonWdgt true, @, "doSelection", "run selection"
    @runSelectionButton.editorContentPropertyChangerButton = true
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

  # immediate-resize-relay-exempt: no polymorphic raw _applyExtent receiver of this class (2026-07-16 census); containers size me via the settle-driven _reLayout handing bounds, or the override-BYPASSING _applyExtentBase (deliberately outside this mechanism)
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

    textHeight = @height() - 2 * @externalPadding - @internalPadding - 15
    textBottom = @top() + @externalPadding + textHeight
    textWidth = @width() - 2 * @externalPadding
    # Integer placement (Layer A): the two run-buttons share this width and are laid side by side, so a
    # fractional /2 makes the second button's origin (= first's right edge) fractional -- round it here so both
    # commit integer @bounds. docs/fractional-widget-bounds-investigation-plan.md (Path 2).
    buttonsWidth = Math.round (textWidth - 2 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize)/2

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField._applyExtent new Point textWidth, textHeight


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
    @fullChanged()

    super
    @_markLayoutAsFixed()

