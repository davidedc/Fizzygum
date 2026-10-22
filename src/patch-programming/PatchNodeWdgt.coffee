# PatchNodeWdgt — shared base for the patch-programming compute nodes
# (CalculatingPatchNodeWdgt / RegexSubstitutionPatchNodeWdgt / DiffingPatchNodeWdgt).
#
# A patch node is a dataflow COMPUTING node (spec §8): it stores its inputs, and on any input change (or a
# bang) marks itself STALE; the drain then PULLS all stored inputs via dataflowRecompute — a subclass hook
# that runs the node's own computation (recalculateOutput) and refreshes its on-node display — and delivers
# @output along the out-edge. This base holds everything the three nodes share verbatim: the dataflow node
# protocol, the connect-to-target menu wiring, the input PINS, the _reLayout scaffold, their text boxes
# (_newTextBox) and the floored height split those stacked boxes take (_heightsSplitByWeights). Each subclass
# supplies only what actually differs — its constructor / colloquialName / setInput* / recalculateOutput /
# _buildAndConnectChildrenNoSettle (children) / _layOutOwnContents (child geometry), and, if its inputs differ
# from the default in1..in4, _inputPins.
#
# NOTE — this base is in the CORE part while half its subclasses are not, and that is deliberate:
# CalculatingPatchNodeWdgt ships in production and extends this base, so the base has to ship too.
# The unfinished nodes (RegexSubstitution / Diffing / fanout) live in the
# `patch-programming-experimental` part, which production does not ship -- a present base with absent
# subclasses is fine. Arc 4 moved that FILES-not-markers way of saying it: the directory a file sits
# in decides its part (buildSystem/parts.json), and a mixed directory is resolved by moving files.

class PatchNodeWdgt extends Widget

  @augmentWith ControllerMixin

  textWidget: undefined

  output: undefined

  input1: undefined
  input2: undefined

  # I drive numbers (my computed @output). No principalPinLabel: what I export is @output, which is
  # not a pin of mine -- nothing drives it, my inputs do -- so dataflowValue answers it directly.
  producesPinKind: "numerical"

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


  # any input change (or a bang) marks me STALE — the drain recomputes me via dataflowRecompute (which pulls
  # ALL my stored inputs) then delivers @output along my out-edge. This replaces the legacy multi-input
  # FRESHNESS GATE (the allConnectedInputsAreFresh deadlock where two independently-sourced inputs never share
  # a token, spec §8). A bang marks me forced; markStale is echo-suppressed while the engine is applying an
  # input into me (setInput*'s own updateTarget tail).
  updateTarget: (fireBecauseBang) ->
    world.dataflow.markStale @, (fireBecauseBang is true)
    return

  reactToTargetConnection: ->
    @_fireConnection @output

  # ── dataflow node protocol (spec §8) ─────────────────────────────────────────────────────
  # A COMPUTING node: recompute = run the node's own computation over the stored inputs (recalculateOutput, a
  # subclass hook that also refreshes the on-node output display), handing the engine the fresh @output;
  # dataflowValue lets a consumer PULL @output along my out-edge and lets the cutoff compare it — a plain
  # Widget.exportedValue would read my chrome text, not the computed output.
  dataflowRecompute: ->
    @recalculateOutput()
    @output

  dataflowValue: -> @output


  # The pins this node's INPUTS contribute. The default is in1..in4 (Calculating / Regex); a subclass
  # whose inputs differ (Diffing's hot inputs) overrides just this, and `pins` stays shared.
  # ⚠ The inputs are ["string", "numerical"] and deliberately NOT "any": you can feed a patch node a
  # number or its string spelling, but a colour is not an operand for the arithmetic and regex nodes
  # that use these.
  _inputPins: ->
    [
      new PinSpec "bang!", "any",                   set: "bang"
      new PinSpec "in1",   ["string", "numerical"], set: "setInput1"
      new PinSpec "in2",   ["string", "numerical"], set: "setInput2"
      new PinSpec "in3",   ["string", "numerical"], set: "setInput3"
      new PinSpec "in4",   ["string", "numerical"], set: "setInput4"
    ]

  pins: -> super().concat @_inputPins()

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addTargetConnectionMenuEntries menu


  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # _buildAndConnectChildrenNoSettle is the subclass hook that actually creates the node's children.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  # One of my TEXT BOXES, which a subclass builds and stacks in its _buildAndConnectChildrenNoSettle: a
  # mono text panel (TextAreaWdgt.configureAsMonoTextPanel) holding a formula, a regex, a substitution or
  # an output as CODE, unwrapped -- its text born in the code role, fonts.code and the codeText ink, at
  # my own padding of 5 (a code pane's is codePanePadding) -- on a text area's fill, inside a 1 px
  # border in the patchNodeTextBoxStroke role, which the box is dressed in (ViewportWdgt.wearPaneRoles,
  # read as it paints, kept by name wherever it is taken). The border is the box's and its plane's
  # alike (the plane wears its box's look): each strokes its own outline over its children, so either
  # can be the line that shows. Editable and selectable, or read-only (an output box), as asked.
  _newTextBox: (text, isEditable) ->
    theme = WorldWdgt.theme
    textBox = new TextAreaWdgt text, false, 5, fontRole: theme.fonts.code, textColor: theme.codeText
    textBox.configureAsMonoTextPanel isEditable
    textBox.wearPaneRoles stroke: "patchNodeTextBoxStroke"
    textBox

  # the whole layout shape is Widget's own-contents template; each node subclass supplies only
  # its own _layOutOwnContents
  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # Splits `length` among boxes stacked one above the other, in proportion to `weights`, but gives no
  # box less than its entry in `floors` while the floors fit: a box whose share falls short takes its
  # floor, and the remaining boxes re-split what is left by their weights. When the floors alone
  # exceed `length` the plain weighted split stands, since something must scroll anyway. The heights
  # are rounded at their cumulative edges, so they sum to `length` exactly and a box held at its
  # (integer) floor keeps it exactly.
  _heightsSplitByWeights: (length, weights, floors) ->
    heldAtFloor = (false for w in weights)
    sumOf = (values) -> values.reduce ((a, b) -> a + b), 0
    floorsFit = (sumOf floors) <= length
    loop
      freeLength = length - sumOf (floors[i] for w, i in weights when heldAtFloor[i])
      freeWeight = sumOf (w for w, i in weights when !heldAtFloor[i])
      break unless floorsFit
      anyNewlyHeld = false
      for w, i in weights when !heldAtFloor[i] and freeLength * w / freeWeight < floors[i]
        heldAtFloor[i] = true
        anyNewlyHeld = true
      break unless anyNewlyHeld
    heights = []
    reached = 0
    edgeSoFar = 0
    for w, i in weights
      reached += if heldAtFloor[i] then floors[i] else freeLength * w / freeWeight
      edge = Math.round reached
      heights.push edge - edgeSoFar
      edgeSoFar = edge
    heights
