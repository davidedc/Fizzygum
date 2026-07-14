# this file is excluded from the fizzygum homepage build

class RegexSubstitutionPatchNodeWdgt extends Widget

  @augmentWith ControllerMixin

  regexEntryField: nil
  defaultContents: nil
  textWidget: nil

  substitutionTextArea: nil
  substitutionTextAreaText: nil

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

  constructor: (@defaultContents = "") ->
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Regex subst. patch node"

  setInput1: (newvalue, ignored) ->
    @input1 = newvalue
    @updateTarget()

  setInput2: (newvalue, ignored) ->
    @input2 = newvalue
    @updateTarget()

  setInput3: (newvalue, ignored) ->
    @input3 = newvalue
    @updateTarget()

  setInput4: (newvalue, ignored) ->
    @input4 = newvalue
    @updateTarget()

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    @updateTarget true

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.numericalSetters()

  # any input change (or a bang) marks me STALE — the drain recomputes me via dataflowRecompute (pulling all
  # stored inputs) then delivers @output along my out-edge. This replaces the legacy multi-input FRESHNESS GATE
  # (the allConnectedInputsAreFresh deadlock, spec §8). A bang marks me forced; markStale is echo-suppressed
  # while the engine is applying an input into me.
  updateTarget: (fireBecauseBang) ->
    world.dataflow.markStale @, (fireBecauseBang is true)
    return

  fireOutputToTarget: ->
    @_fireConnection @output

  reactToTargetConnection: ->
    @fireOutputToTarget()

  recalculateOutput: ->
    if @textWidget.text != ""

      # from: https://stackoverflow.com/a/22763959
      regParts = @textWidget.text.match(/^\/(.*?)\/([gim]*)$/)
      if regParts
        # the parsed pattern had delimiters and modifiers. handle them.
        regexp = new RegExp(regParts[1], regParts[2])
      else
        # we got pattern string without delimiters
        regexp = new RegExp(@textWidget.text)

      @output = @input1.replace regexp, @substitutionTextAreaText.text
      @outputTextAreaText._setTextConnector @output

  # ── dataflow node protocol (spec §8) ─────────────────────────────────────────────────────
  # A COMPUTING node: recompute = re-run the substitution over the stored inputs (recalculateOutput refreshes the
  # on-node display too), handing the engine the fresh @output; dataflowValue lets a consumer PULL @output and the
  # cutoff compare it.
  dataflowRecompute: ->
    @recalculateOutput()
    @output

  dataflowValue: -> @output


  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["bang!", "in1", "in2", "in3", "in4"], ["bang", "setInput1", "setInput2", "setInput3", "setInput4"]

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["bang!", "in1", "in2", "in3", "in4"], ["bang", "setInput1", "setInput2", "setInput3", "setInput4"]

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addTargetConnectionMenuEntries menu, "numerical"


  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @regexEntryField = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @regexEntryField.disableDrops()
    @regexEntryField.contents.disableDrops()
    @regexEntryField.color = Color.WHITE
    @textWidget = @regexEntryField.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget._setFontNameNoSettle nil, nil, @textWidget.monoFontStack
    @textWidget.isEditable = true
    @textWidget.enableSelecting()
    @_addNoSettle @regexEntryField

    @substitutionTextArea = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @substitutionTextArea.disableDrops()
    @substitutionTextArea.contents.disableDrops()
    @substitutionTextArea.color = Color.WHITE
    @substitutionTextAreaText = @substitutionTextArea.textWdgt
    @substitutionTextAreaText.backgroundColor = Color.TRANSPARENT
    @substitutionTextAreaText._setFontNameNoSettle nil, nil, @substitutionTextAreaText.monoFontStack
    @substitutionTextAreaText.isEditable = true
    @substitutionTextAreaText.enableSelecting()
    @_addNoSettle @substitutionTextArea

    @outputTextArea = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @outputTextArea.disableDrops()
    @outputTextArea.contents.disableDrops()
    @outputTextArea.color = Color.WHITE
    @outputTextAreaText = @outputTextArea.textWdgt
    @outputTextAreaText.backgroundColor = Color.TRANSPARENT
    @outputTextAreaText._setFontNameNoSettle nil, nil, @outputTextAreaText.monoFontStack
    @outputTextAreaText.isEditable = false
    @_addNoSettle @outputTextArea


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

    availableHeight = @height() - 2 * @externalPadding - 2 * @internalPadding
    text1Height = Math.round(availableHeight * 1/4)
    text2Height = Math.round(availableHeight * 1/4)
    text3Height = Math.round(availableHeight * 2/4)

    if @regexEntryField.parent == @
      @regexEntryField._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @regexEntryField._applyExtent new Point @width() - 2 * @externalPadding, text1Height

    if @substitutionTextArea.parent == @
      @substitutionTextArea._applyMoveTo new Point @left() + @externalPadding, @regexEntryField.bottom() + @internalPadding
      @substitutionTextArea._applyExtent new Point @width() - 2 * @externalPadding, text2Height

    if @outputTextArea.parent == @
      @outputTextArea._applyMoveTo new Point @left() + @externalPadding, @substitutionTextArea.bottom() + @internalPadding
      @outputTextArea._applyExtent new Point @width() - 2 * @externalPadding, text3Height


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()

