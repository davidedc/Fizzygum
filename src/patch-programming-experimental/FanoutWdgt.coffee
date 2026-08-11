class FanoutWdgt extends Widget

  @augmentWith ControllerMixin

  pinUp: nil
  pinDown: nil
  pinLeft: nil
  pinRight: nil
  inputValue: nil

  constructor: (@color) ->
    super
    @appearance = new FanoutAppearance @
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @pinUp = new FanoutPinWdgt
    @pinDown = new FanoutPinWdgt
    @pinLeft = new FanoutPinWdgt
    @pinRight = new FanoutPinWdgt

    @_addNoSettle @pinUp
    @_addNoSettle @pinDown
    @_addNoSettle @pinLeft
    @_addNoSettle @pinRight

    @_invalidateLayout()

  setInput: (newvalue, ignored) ->
    @inputValue = newvalue
    @updateTarget()

  updateTarget: ->
    for target in @children
      if target.isConnectionPin?()
        target.setInput @inputValue, nil
    return

  # ── dataflow node protocol ───────────────────────────────────────────────────────────────
  # A fanout is a CONSUMER (a setInput target) that re-fans @inputValue to its pins in updateTarget; the pins are
  # the producers carrying their own out-edges (each markStale'd via _fireConnection). dataflowValue answers
  # @inputValue for the cutoff. (homepage-excluded.)
  dataflowValue: -> @inputValue

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["input"], ["setInput"]

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["input"], ["setInput"]

  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["input"], ["setInput"]

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout

    @_repaintAsOneUnit =>

      # the largest square centred in my bounds: the fanout body fills it and the
      # four pins sit at its edge midpoints
      square = @boundingBox().largestCenteredSquare()
      squareDim = square.width()
      p0 = square.topLeft()

      pinSize = (new Point 22 * squareDim/100, 22*squareDim/100).round()

      @pinUp._applyExtent pinSize
      @pinDown._applyExtent pinSize
      @pinLeft._applyExtent pinSize
      @pinRight._applyExtent pinSize

      @pinUp._applyMoveTo (p0.add new Point 39 * squareDim/100, 1 * squareDim/100).round()
      @pinDown._applyMoveTo (p0.add new Point 39 * squareDim/100, 77 * squareDim/100).round()
      @pinLeft._applyMoveTo (p0.add new Point 1 * squareDim/100, 39 * squareDim/100).round()
      @pinRight._applyMoveTo (p0.add new Point 77 * squareDim/100, 39 * squareDim/100).round()

    super
    @_markLayoutAsFixed()

