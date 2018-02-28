class SimpleDocumentEditorWdgt extends Widget


  tempPromptEntryField: nil
  defaultContents: nil
  textMorph: nil

  outputTextArea: nil
  outputTextAreaText: nil

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

  constructor: (@defaultContents = "") ->
    super new Point 200,400
    @buildAndConnectChildren()

  colloquialName: ->
    "Simple document editor"

  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @tempPromptEntryField = new HorizontalMenuPanelWdgt()
    @tempPromptEntryField.rawSetExtent new Point 300,10

    @tempPromptEntryField.add new BoldButtonWdgt()
    @tempPromptEntryField.add new ItalicButtonWdgt()
    @tempPromptEntryField.add new FormatAsCodeButtonWdgt()
    @tempPromptEntryField.add new IncreaseFontSizeButtonWdgt()
    @tempPromptEntryField.add new DecreaseFontSizeButtonWdgt()

    @tempPromptEntryField.add new AlignLeftButtonWdgt()
    @tempPromptEntryField.add new AlignCenterButtonWdgt()
    @tempPromptEntryField.add new AlignRightButtonWdgt()


    @add @tempPromptEntryField

    @outputTextArea = new SimpleDocumentScrollPanelWdgt()
    @add @outputTextArea


    @invalidateLayout()

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

    availableHeight = @height() - 2 * @externalPadding - @internalPadding
    text1Height = 35
    text2Height = availableHeight - text1Height

    textBottom = @top() + @externalPadding + text1Height

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField.rawSetExtent new Point @width() - 2 * @externalPadding, text1Height

    if @outputTextArea.parent == @
      @outputTextArea.fullRawMoveTo new Point @left() + @externalPadding, textBottom + @internalPadding
      @outputTextArea.rawSetExtent new Point @width() - 2 * @externalPadding, text2Height


    trackChanges.pop()
    @fullChanged()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

