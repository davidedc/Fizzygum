class CalculatingPatchNodeWdgt extends PatchNodeWdgt

  # shared dataflow-node behaviour (dataflow protocol, connect-to-target menu, setter menus, _reLayout
  # scaffold, padding, and the input1/input2/output/textWidget preamble) lives on PatchNodeWdgt.

  # the user formula COMPILED -- a derived Function (the formula TEXT is the truth,
  # and recalculateOutput re-derives this from it on every recompute), so it is
  # never serialized: an own function property has no editable source and would
  # crash the serializer; the restored node recompiles at its first recalculation.
  # A deep copy briefly SHARES it (the Duplicator passes functions through) --
  # harmless: it is closure-free, invoked with `.call world`, and the clone's own
  # first recalculateOutput overwrites it with its own compile.
  @serializationTransients: ["functionFromCompiledCode"]
  functionFromCompiledCode: undefined

  tempPromptEntryField: undefined
  defaultFormulaBoxContents: undefined

  formulaTextBoxLabel: undefined
  outputTextBoxLabel: undefined

  outputTextArea: undefined
  outputTextAreaText: undefined

  input3: undefined
  input4: undefined

  constructor: (@defaultFormulaBoxContents = "# function with formula here e.g.\n# (in1) -> in1 * 2\n") ->
    super()
    @_buildAndConnectChildren()


  setInput1: (newvalue, ignored) ->
    @input1 = Number(newvalue)
    @updateTarget()

  setInput2: (newvalue, ignored) ->
    @input2 = Number(newvalue)
    @updateTarget()

  setInput3: (newvalue, ignored) ->
    @input3 = Number(newvalue)
    @updateTarget()

  setInput4: (newvalue, ignored) ->
    @input4 = Number(newvalue)
    @updateTarget()

  recalculateOutput: ->
    if @textWidget.text != ""
      @evaluateString "@functionFromCompiledCode = " + @textWidget.text
      @output = @functionFromCompiledCode?.call world, @input1, @input2, @input3, @input4
      @outputTextAreaText._setTextConnector @output + ""

  _buildAndConnectChildrenNoSettle: ->

    theme = WorldWdgt.theme

    # my formula and output boxes are two of my text boxes (PatchNodeWdgt._newTextBox); the output one
    # is read-only
    @tempPromptEntryField = @_newTextBox @defaultFormulaBoxContents, true
    @textWidget = @tempPromptEntryField.textWdgt
    @_addNoSettle @tempPromptEntryField

    @outputTextArea = @_newTextBox "", false
    @outputTextAreaText = @outputTextArea.textWdgt
    @_addNoSettle @outputTextArea


    # my field labels, each over its header line: the small chrome labels' font, in the ink of a
    # patch node's field labels
    @formulaTextBoxLabel = new StringWdgt "Formula", fontRole: theme.fonts.buttonLabel, color: theme.patchNodeFieldLabelText
    @formulaTextBoxLabel.toggleHeaderLine()
    @_addNoSettle @formulaTextBoxLabel

    @outputTextBoxLabel = new StringWdgt "Output", fontRole: theme.fonts.buttonLabel, color: theme.patchNodeFieldLabelText
    @outputTextBoxLabel.toggleHeaderLine()
    @_addNoSettle @outputTextBoxLabel


    @_invalidateLayout()

  # My output box is laid out across my full width at my bottom (_layOutOwnContents), so it is the
  # child at my bottom-right corner, where my window's resizer sits (ViewportWdgt._resizerOverMyCorner).
  bottomRightCornerReachedBy: (child) ->
    child is @outputTextArea

  # subclass hook for PatchNodeWdgt::_reLayout — position my own children within the (already-applied) frame.
  # The formula box gets two thirds of the height the two labels leave and the output box the third
  # below it, but neither box shorter than one line of its text while both lines fit.
  _layOutOwnContents: ->

    availableHeight = @height() - 2 * @externalPadding - 3 * @internalPadding - 2 * 15
    [text1Height, text2Height] = @_heightsSplitByWeights availableHeight, [2, 1], [@tempPromptEntryField.heightShowingOneLine(), @outputTextArea.heightShowingOneLine()]

    textBottom = @top() + @externalPadding + 15 + @internalPadding + text1Height

    if @formulaTextBoxLabel.parent == @
      @formulaTextBoxLabel._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point @width() - 2 * @externalPadding, 15

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding + 15 + @internalPadding), new Point @width() - 2 * @externalPadding, text1Height

    if @outputTextBoxLabel.parent == @
      @outputTextBoxLabel._applyBounds (new Point @left() + @externalPadding, @tempPromptEntryField.bottom() + @internalPadding), new Point @width() - 2 * @externalPadding, 15

    if @outputTextArea.parent == @
      @outputTextArea._applyBounds (new Point @left() + @externalPadding, textBottom + @internalPadding + 15 + @internalPadding), new Point @width() - 2 * @externalPadding, text2Height
