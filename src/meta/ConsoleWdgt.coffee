class ConsoleWdgt extends Widget

  tempPromptEntryField: nil
  textMorph: nil

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
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt "", false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = new Color 255, 255, 255

    @textMorph = @tempPromptEntryField.textWdgt
    @textMorph.backgroundColor = new Color 0,0,0,0
    @textMorph.setFontName nil, nil, @textMorph.monoFontStack
    @textMorph.isEditable = true
    @textMorph.enableSelecting()

    @add @tempPromptEntryField

    # "do" buttons -------------------------------
    # NOTE that you can also "doAll" or "doSelection" via
    # the context menu entries in the text panel!
    @runSelectionButton = new SimpleButtonMorph true, @, "doSelection", "run selection"
    @runSelectionButton.editorContentPropertyChangerButton = true
    @add @runSelectionButton

    @runAllButton = new SimpleButtonMorph true, @, "doAll", "run all"
    @add @runAllButton
    # ---------------------------------------

    @invalidateLayout()

  doSelection: ->
    savedScript = @textMorph.selection()
    compiled = compileFGCode savedScript, true
    functionFromCompiledCode = new Function compiled
    functionFromCompiledCode?.call @target


  doAll: ->
    savedScript = @textMorph.text
    compiled = compileFGCode savedScript, true
    functionFromCompiledCode = new Function compiled
    functionFromCompiledCode?.call @target

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts
    #  debugger

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    super

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

    textHeight = @height() - 2 * @externalPadding - @internalPadding - 15
    textBottom = @top() + @externalPadding + textHeight
    textWidth = @width() - 2 * @externalPadding
    buttonsWidth = (textWidth - 2 * @internalPadding - WorldMorph.preferencesAndSettings.handleSize)/2

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField.rawSetExtent new Point textWidth, textHeight


    # buttons -------------------------------
    

    if @runSelectionButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @externalPadding, textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonsWidth, 15
      @runSelectionButton.doLayout buttonBounds 

    if @runAllButton.parent == @
      buttonBounds = new Rectangle new Point buttonBounds.right() + @internalPadding, textBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonsWidth, 15
      @runAllButton.doLayout buttonBounds 


    # ----------------------------------------------


    trackChanges.pop()
    @fullChanged()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

