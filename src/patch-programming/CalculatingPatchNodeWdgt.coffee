class CalculatingPatchNodeWdgt extends Widget

  @augmentWith ControllerMixin

  tempPromptEntryField: nil
  defaultFormulaBoxContents: nil
  textWidget: nil

  formulaTextBoxLabel: nil
  outputTextBoxLabel: nil

  outputTextArea: nil
  outputTextAreaText: nil

  output: nil

  input1: nil
  input2: nil
  input3: nil
  input4: nil

  # we need to keep track of which inputs are
  # connected because we wait for those to be
  # all updated before the node fires
  setInput1IsConnected: false
  setInput2IsConnected: false
  setInput3IsConnected: false
  setInput4IsConnected: false

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

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    @updateTarget true

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.numericalSetters()

  # any input change (or a bang) marks me STALE — the drain recomputes me via dataflowRecompute (which pulls
  # ALL my stored inputs) then delivers @output along my out-edge. This replaces the legacy multi-input
  # FRESHNESS GATE (the allConnectedInputsAreFresh deadlock where two independently-sourced inputs never share
  # a token, spec §8). A bang marks me forced; markStale is echo-suppressed while the engine is applying an
  # input into me (setInput1..4's own updateTarget tail).
  updateTarget: (fireBecauseBang) ->
    world.dataflow.markStale @, (fireBecauseBang is true)
    return

  fireOutputToTarget: ->
    @_fireConnection @output

  reactToTargetConnection: ->
    @fireOutputToTarget()

  recalculateOutput: ->
    if @textWidget.text != ""
      @evaluateString "@functionFromCompiledCode = " + @textWidget.text
      # now we have the user-defined function in @functionFromCompiledCode
      @output = @functionFromCompiledCode?.call world, @input1, @input2, @input3, @input4
      @outputTextAreaText._setTextConnector @output + ""

  # ── dataflow node protocol (spec §8) ─────────────────────────────────────────────────────
  # A calc node is a COMPUTING node: recompute = run the user formula over the stored inputs (recalculateOutput,
  # which also refreshes the on-node output display), handing the engine the fresh @output. dataflowValue lets a
  # consumer PULL @output along my out-edge and lets the cutoff compare it — a plain Widget.exportedValue would
  # read my chrome text, not the computed output.
  dataflowRecompute: ->
    @recalculateOutput()
    @output

  dataflowValue: -> @output


  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "in1", "in2", "in3", "in4"
    functionNamesStrings.push "bang", "setInput1", "setInput2", "setInput3", "setInput4"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "in1", "in2", "in3", "in4"
    functionNamesStrings.push "bang", "setInput1", "setInput2", "setInput3", "setInput4"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    if world.isIndexPage
      menu.addMenuItem "connect to ➜", true, @, "openTargetSelector", "connect to\nanother widget"
    else
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another widget\nwhose numerical property\n will be" + " controlled by this one"
    @addFiresPerEventMenuEntry menu


  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt @defaultFormulaBoxContents, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = Color.WHITE
    @textWidget = @tempPromptEntryField.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget._setFontNameNoSettle nil, nil, @textWidget.monoFontStack
    @textWidget.isEditable = true
    @textWidget.enableSelecting()
    @_addNoSettle @tempPromptEntryField

    @outputTextArea = new SimplePlainTextScrollPanelWdgt "", false, 5
    @outputTextArea.disableDrops()
    @outputTextArea.contents.disableDrops()
    @outputTextArea.color = Color.WHITE
    @outputTextAreaText = @outputTextArea.textWdgt
    @outputTextAreaText.backgroundColor = Color.TRANSPARENT
    @outputTextAreaText._setFontNameNoSettle nil, nil, @outputTextAreaText.monoFontStack
    @outputTextAreaText.isEditable = false
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


    world.maybeEnableTrackChanges()
    @fullChanged()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    super
    @markLayoutAsFixed()

