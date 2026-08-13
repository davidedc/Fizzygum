class CalculatingPatchNodeWdgt extends PatchNodeWdgt

  # shared dataflow-node behaviour (dataflow protocol, connect-to-target menu, setter menus, _reLayout
  # scaffold, padding, and the input1/input2/output/textWidget preamble) lives on PatchNodeWdgt.

  # the user formula COMPILED -- a derived Function (the formula TEXT is the truth,
  # and recalculateOutput re-derives this from it on every recompute), so it is
  # never serialized: an own function property has no editable source and would
  # crash the serializer; the restored node recompiles at its first recalculation.
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

  # ControllerMixin's setTargetAndActionWithOnesPickedFromMenu flips these true when a wire is
  # connected via the menu (@target[@action + "IsConnected"] = true) -- bookkeeping only,
  # nothing reads them. The old "wait for all connected inputs before firing" freshness gate
  # they were for is gone (see PatchNodeWdgt.updateTarget): any input change marks me STALE and
  # the drain pulls whatever is currently stored.
  setInput1IsConnected: false
  setInput2IsConnected: false
  setInput3IsConnected: false
  setInput4IsConnected: false

  constructor: (@defaultFormulaBoxContents = "# function with formula here e.g.\n# (in1) -> in1 * 2\n") ->
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Calculating patch node"

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

    @tempPromptEntryField = new SimpleTextScrollPanelWdgt @defaultFormulaBoxContents, false, 5
    @tempPromptEntryField.configureAsMonoTextPanel true
    @textWidget = @tempPromptEntryField.textWdgt
    @_addNoSettle @tempPromptEntryField

    @outputTextArea = new SimpleTextScrollPanelWdgt "", false, 5
    @outputTextArea.configureAsMonoTextPanel false
    @outputTextAreaText = @outputTextArea.textWdgt
    @_addNoSettle @outputTextArea


    @formulaTextBoxLabel = new StringWdgt "Formula", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @formulaTextBoxLabel.toggleHeaderLine()
    @_addNoSettle @formulaTextBoxLabel

    @outputTextBoxLabel = new StringWdgt "Output", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @outputTextBoxLabel.toggleHeaderLine()
    @_addNoSettle @outputTextBoxLabel


    @_invalidateLayout()

  # subclass hook for PatchNodeWdgt::_reLayout — position my own children within the (already-applied) frame.
  _layOutNodeContents: ->

    availableHeight = @height() - 2 * @externalPadding - 3 * @internalPadding - 2 * 15
    text1Height = Math.round(availableHeight * 2/3)
    text2Height = Math.round(availableHeight * 1/3)

    textBottom = @top() + @externalPadding + 15 + @internalPadding + text1Height

    if @formulaTextBoxLabel.parent == @
      @formulaTextBoxLabel._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point @width() - 2 * @externalPadding, 15

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding + 15 + @internalPadding), new Point @width() - 2 * @externalPadding, text1Height

    if @outputTextBoxLabel.parent == @
      @outputTextBoxLabel._applyBounds (new Point @left() + @externalPadding, @tempPromptEntryField.bottom() + @internalPadding), new Point @width() - 2 * @externalPadding, 15

    if @outputTextArea.parent == @
      @outputTextArea._applyBounds (new Point @left() + @externalPadding, textBottom + @internalPadding + 15 + @internalPadding), new Point @width() - 2 * @externalPadding, text2Height
