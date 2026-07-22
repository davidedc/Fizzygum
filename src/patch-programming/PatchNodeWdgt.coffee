# PatchNodeWdgt — shared base for the patch-programming compute nodes
# (CalculatingPatchNodeWdgt / RegexSubstitutionPatchNodeWdgt / DiffingPatchNodeWdgt).
#
# A patch node is a dataflow COMPUTING node (spec §8): it stores its inputs, and on any input change (or a
# bang) marks itself STALE; the drain then PULLS all stored inputs via dataflowRecompute — a subclass hook
# that runs the node's own computation (recalculateOutput) and refreshes its on-node display — and delivers
# @output along the out-edge. This base holds everything the three nodes share verbatim: the dataflow node
# protocol, the connect-to-target menu wiring, the setter menus, and the _reLayout scaffold. Each subclass
# supplies only what actually differs — its constructor / colloquialName / setInput* / recalculateOutput /
# _buildAndConnectChildrenNoSettle (children) / _layOutNodeContents (child geometry), and, if its inputs differ
# from the default in1..in4, _inputSetterMenuEntries.
#
# NOTE — this file carries NO "excluded from the fizzygum homepage build" marker ON PURPOSE:
# CalculatingPatchNodeWdgt ships in the --homepage build and extends this base, so the base must ship too.
# RegexSubstitution / Diffing keep their own exclusion markers and are stripped from --homepage — a present
# base with stripped subclasses is fine.

class PatchNodeWdgt extends Widget

  @augmentWith ControllerMixin

  textWidget: nil

  output: nil

  input1: nil
  input2: nil

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

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    @updateTarget true

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.numericalSetters()

  # any input change (or a bang) marks me STALE — the drain recomputes me via dataflowRecompute (which pulls
  # ALL my stored inputs) then delivers @output along my out-edge. This replaces the legacy multi-input
  # FRESHNESS GATE (the allConnectedInputsAreFresh deadlock where two independently-sourced inputs never share
  # a token, spec §8). A bang marks me forced; markStale is echo-suppressed while the engine is applying an
  # input into me (setInput*'s own updateTarget tail).
  updateTarget: (fireBecauseBang) ->
    world.dataflow.markStale @, (fireBecauseBang is true)
    return

  fireOutputToTarget: ->
    @_fireConnection @output

  reactToTargetConnection: ->
    @fireOutputToTarget()

  # ── dataflow node protocol (spec §8) ─────────────────────────────────────────────────────
  # A COMPUTING node: recompute = run the node's own computation over the stored inputs (recalculateOutput, a
  # subclass hook that also refreshes the on-node output display), handing the engine the fresh @output;
  # dataflowValue lets a consumer PULL @output along my out-edge and lets the cutoff compare it — a plain
  # Widget.exportedValue would read my chrome text, not the computed output.
  dataflowRecompute: ->
    @recalculateOutput()
    @output

  dataflowValue: -> @output


  # The (menu-label, setter-function-name) pairs this node's inputs contribute to BOTH the string and the
  # numerical connect-to-target setter menus. The default is in1..in4 (Calculating / Regex); a subclass whose
  # inputs differ (Diffing's hot inputs) overrides just this — stringSetters / numericalSetters stay shared.
  _inputSetterMenuEntries: ->
    [["bang!", "in1", "in2", "in3", "in4"], ["bang", "setInput1", "setInput2", "setInput3", "setInput4"]]

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    [entries, functionNames] = @_inputSetterMenuEntries()
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, entries, functionNames

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    [entries, functionNames] = @_inputSetterMenuEntries()
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, entries, functionNames

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addTargetConnectionMenuEntries menu, "numerical"


  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # _buildAndConnectChildrenNoSettle is the subclass hook that actually creates the node's children.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyGrantedBounds newBoundsForThisLayout

    # Disable broken-rectangle tracking while the children are repositioned: every subwidget is within my
    # own bounds, so my single broken rectangle already covers them. (Anything a subwidget sticks out past
    # my boundary is still painted and moved correctly.)
    world.disableTrackChanges()

    # subclass hook: position this node's own children within the (now-final) frame.
    @_layOutNodeContents()

    world.maybeEnableTrackChanges()
    @_fullChanged()

    super
    @_markLayoutAsFixed()
