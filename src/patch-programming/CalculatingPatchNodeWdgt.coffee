class CalculatingPatchNodeWdgt extends PatchNodeWdgt

  # shared dataflow-node behaviour (dataflow protocol, connect-to-target menu, setter menus, _reLayout
  # scaffold, padding, and the input1/input2/output/textWidget preamble) lives on PatchNodeWdgt.

  tempPromptEntryField: nil
  defaultFormulaBoxContents: nil

  formulaTextBoxLabel: nil
  outputTextBoxLabel: nil

  outputTextArea: nil
  outputTextAreaText: nil

  input3: nil
  input4: nil

  # we need to keep track of which inputs are
  # connected because we wait for those to be
  # all updated before the node fires
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
      # now we have the user-defined function in @functionFromCompiledCode
      @output = @functionFromCompiledCode?.call world, @input1, @input2, @input3, @input4
      @outputTextAreaText._setTextConnector @output + ""

  _buildAndConnectChildrenNoSettle: ->

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt @defaultFormulaBoxContents, false, 5
    @tempPromptEntryField.configureAsMonoTextPanel true
    @textWidget = @tempPromptEntryField.textWdgt
    @_addNoSettle @tempPromptEntryField

    @outputTextArea = new SimplePlainTextScrollPanelWdgt "", false, 5
    @outputTextArea.configureAsMonoTextPanel false
    @outputTextAreaText = @outputTextArea.textWdgt
    @_addNoSettle @outputTextArea


    @formulaTextBoxLabel = new StringWdgt "Formula", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @formulaTextBoxLabel.toggleHeaderLine()
    #@formulaTextBoxLabel.alignCenter()
    @_addNoSettle @formulaTextBoxLabel

    @outputTextBoxLabel = new StringWdgt "Output", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @outputTextBoxLabel.toggleHeaderLine()
    #@outputTextBoxLabel.alignCenter()
    @_addNoSettle @outputTextBoxLabel


    @_invalidateLayout()

  # subclass hook for PatchNodeWdgt::_reLayout — position my own children within the (already-applied) frame.
  _layOutNodeContents: ->

    availableHeight = @height() - 2 * @externalPadding - 3 * @internalPadding - 2 * 15
    text1Height = Math.round(availableHeight * 2/3)
    text2Height = Math.round(availableHeight * 1/3)

    textBottom = @top() + @externalPadding + 15 + @internalPadding + text1Height

    if @formulaTextBoxLabel.parent == @
      @formulaTextBoxLabel._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @formulaTextBoxLabel._applyExtent new Point @width() - 2 * @externalPadding, 15

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding + 15 + @internalPadding
      @tempPromptEntryField._applyExtent new Point @width() - 2 * @externalPadding, text1Height

    if @outputTextBoxLabel.parent == @
      @outputTextBoxLabel._applyMoveTo new Point @left() + @externalPadding, @tempPromptEntryField.bottom() + @internalPadding
      @outputTextBoxLabel._applyExtent new Point @width() - 2 * @externalPadding, 15

    if @outputTextArea.parent == @
      @outputTextArea._applyMoveTo new Point @left() + @externalPadding, textBottom + @internalPadding + 15 + @internalPadding
      @outputTextArea._applyExtent new Point @width() - 2 * @externalPadding, text2Height
