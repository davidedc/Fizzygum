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

  # to keep track of whether each input is
  # up-to-date or not
  input1connectionsCalculationToken: 0
  input2connectionsCalculationToken: 0
  input3connectionsCalculationToken: 0
  input4connectionsCalculationToken: 0

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

  setInput1: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    return unless @_acceptsConnectionToken connectionsCalculationToken, superCall, "input1connectionsCalculationToken"
    @input1 = Number(newvalue)
    @updateTarget @input1connectionsCalculationToken

  setInput2: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    return unless @_acceptsConnectionToken connectionsCalculationToken, superCall, "input2connectionsCalculationToken"
    @input2 = Number(newvalue)
    @updateTarget @input2connectionsCalculationToken

  setInput3: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    return unless @_acceptsConnectionToken connectionsCalculationToken, superCall, "input3connectionsCalculationToken"
    @input3 = Number(newvalue)
    @updateTarget @input3connectionsCalculationToken

  setInput4: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    return unless @_acceptsConnectionToken connectionsCalculationToken, superCall, "input4connectionsCalculationToken"
    @input4 = Number(newvalue)
    @updateTarget @input4connectionsCalculationToken

  # the bang makes the node fire the current output value
  bang: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    return unless @_acceptsConnectionToken connectionsCalculationToken, superCall
    @updateTarget @connectionsCalculationToken, true

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.numericalSetters()

  updateTarget: (connectionsCalculationToken, fireBecauseBang) ->
    # 6b — under the engine, skip the legacy multi-input FRESHNESS GATE entirely (the allConnectedInputsAreFresh
    # deadlock where two independently-sourced inputs never share a token, spec §8): any input change just marks
    # me STALE (a bang marks me forced), and the drain recomputes me via dataflowRecompute — which pulls ALL my
    # stored inputs — then delivers @output along my out-edge. markStale is echo-suppressed while the engine is
    # applying an input into me (setInput1..4's own updateTarget tail).
    if world.dataflowWiresEnabled
      world.dataflow.markStale @, (fireBecauseBang is true)
      return
    if !@setInput1IsConnected and
     !@setInput2IsConnected and
     !@setInput3IsConnected and
     !@setInput4IsConnected
      return

    allConnectedInputsAreFresh = true
    if @setInput1IsConnected
      if @input1connectionsCalculationToken != connectionsCalculationToken
        allConnectedInputsAreFresh = false
    if @setInput2IsConnected
      if @input2connectionsCalculationToken != connectionsCalculationToken
        allConnectedInputsAreFresh = false
    if @setInput3IsConnected
      if @input3connectionsCalculationToken != connectionsCalculationToken
        allConnectedInputsAreFresh = false
    if @setInput4IsConnected
      if @input4connectionsCalculationToken != connectionsCalculationToken
        allConnectedInputsAreFresh = false

    # if we are firing via bang then we use
    # the existing output value, we don't
    # recalculate a new one
    if allConnectedInputsAreFresh and !fireBecauseBang
      # note that we calculate an output value
      # even if this node has no target. This
      # is because the node might be visualising the
      # output in some other way.
      @recalculateOutput()

    # if all the connected inputs are fresh OR we
    # are firing via bang, then at this point we
    # are going to update the target with the output
    # value.
    if allConnectedInputsAreFresh or fireBecauseBang
      @fireOutputToTarget connectionsCalculationToken

    return

  fireOutputToTarget: (calculationToken) ->
    # mark this node as fired.
    # if the update DOES come from the "bang!", then
    # @connectionsCalculationToken has already been updated
    # but we keep it simple and re-assign it here, not
    # worth complicating things with an additional check
    @connectionsCalculationToken = calculationToken

    @_fireConnection @output

  reactToTargetConnection: ->
    # we generate a new calculation token, that's OK because
    # we are definitely not in the middle of the calculation here
    # but we might be starting a new chain of calculations
    @fireOutputToTarget world.makeNewConnectionsCalculationToken()

  recalculateOutput: ->
    if @textWidget.text != ""
      @evaluateString "@functionFromCompiledCode = " + @textWidget.text
      # now we have the user-defined function in @functionFromCompiledCode
      @output = @functionFromCompiledCode?.call world, @input1, @input2, @input3, @input4
      @outputTextAreaText._setTextConnector @output + ""

  # ── dataflow node protocol (6b, spec §8) ─────────────────────────────────────────────────
  # A calc node is a COMPUTING node: recompute = run the user formula over the stored inputs (recalculateOutput,
  # which also refreshes the on-node output display), handing the engine the fresh @output. dataflowValue lets a
  # consumer PULL @output along my out-edge and lets the cutoff compare it — a plain Widget.exportedValue would
  # read my chrome text, not the computed output. Reached only while world.dataflowWiresEnabled.
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

