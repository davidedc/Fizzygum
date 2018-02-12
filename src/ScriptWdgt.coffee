# ScriptWdgt ///////////////////////////////////////////////////

class ScriptWdgt extends Widget

  tempPromptEntryField: nil
  textMorph: nil

  runItButton: nil

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

  constructor: (scriptStartingContent = "") ->
    super new Point 200,400
    @buildAndConnectChildren scriptStartingContent

  colloquialName: ->
    "script"

  representativeIcon: ->
    new ScriptIconWdgt()

  closeFromContainerWindow: (containerWindow) ->
    if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveReferencePromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()

  buildAndConnectChildren: (scriptStartingContent) ->
    debugger
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @tempPromptEntryField = new ScrollPanelWdgt()
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = new Color 255, 255, 255

    @textMorph = new SimplePlainTextWdgt scriptStartingContent
    @textMorph.setFontName nil, nil, @textMorph.monoFontStack     
    @textMorph.isEditable = true
    @textMorph.enableSelecting()

    @tempPromptEntryField.setContents @textMorph, 5
    @textMorph.softWrapOff()

    @add @tempPromptEntryField

    # buttons -------------------------------
    @runItButton = new SimpleButtonMorph true, @, "doAll", (new StringMorph2 "run it all").alignCenter()
    @add @runItButton

    @invalidateLayout()

  doAll: ->
    world.evaluateString @textMorph.text


  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    super
    debugger

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

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField.rawSetExtent new Point textWidth, textHeight


    # buttons -------------------------------
    

    buttonBounds = new Rectangle new Point @left() + @externalPadding, textBottom + @internalPadding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight textWidth - @internalPadding - WorldMorph.preferencesAndSettings.handleSize, 15
    @runItButton.doLayout buttonBounds 


    # ----------------------------------------------


    trackChanges.pop()
    @fullChanged()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

