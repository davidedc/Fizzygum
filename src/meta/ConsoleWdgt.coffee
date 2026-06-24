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
    @buildAndConnectChildren()

  colloquialName: ->
    "Console for: " + @target.colloquialName().toLowerCase()

  buildAndConnectChildren: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt "", false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = Color.WHITE

    @textWidget = @tempPromptEntryField.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget.setFontName nil, nil, @textWidget.monoFontStack
    @textWidget.isEditable = true
    @textWidget.enableSelecting()

    @add @tempPromptEntryField

    # "do" buttons -------------------------------
    # NOTE that you can also "doAll" or "doSelection" via
    # the context menu entries in the text panel!
    @runSelectionButton = new SimpleButtonWdgt true, @, "doSelection", "run selection"
    @runSelectionButton.editorContentPropertyChangerButton = true
    @add @runSelectionButton

    @runAllButton = new SimpleButtonWdgt true, @, "doAll", "run all"
    @add @runAllButton
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
      menu.addMenuItem "run selection", true, @, "doSelection"
    menu.addMenuItem "run contents", true, @, "doAll"

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

    textHeight = @height() - 2 * @externalPadding - @internalPadding - 15
    textBottom = @top() + @externalPadding + textHeight
    textWidth = @width() - 2 * @externalPadding
    buttonsWidth = (textWidth - 2 * @internalPadding - WorldWdgt.preferencesAndSettings.handleSize)/2

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField.rawSetExtent new Point textWidth, textHeight


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
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    super
    @markLayoutAsFixed()

