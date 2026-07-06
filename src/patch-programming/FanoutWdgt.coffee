# this file is excluded from the fizzygum homepage build

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
    menuEntriesStrings.push "input"
    functionNamesStrings.push "setInput"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "input"
    functionNamesStrings.push "setInput"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "input"
    functionNamesStrings.push "setInput"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
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

    height = @height()
    width = @width()

    squareDim = Math.min width, height

     # p0 is the origin, the origin being in the bottom-left corner
    p0 = @topLeft()

    # now the origin is in the middle of the widget
    p0 = p0.add new Point width/2, height/2
    
    # now the origin is in the top left corner of the
    # square centered in the widget
    p0 = p0.subtract new Point squareDim/2, squareDim/2

    pinSize = (new Point 22 * squareDim/100, 22*squareDim/100).round()

    @pinUp._applyExtent pinSize
    @pinDown._applyExtent pinSize
    @pinLeft._applyExtent pinSize
    @pinRight._applyExtent pinSize

    @pinUp._applyMoveTo (p0.add new Point 39 * squareDim/100, 1 * squareDim/100).round()
    @pinDown._applyMoveTo (p0.add new Point 39 * squareDim/100, 77 * squareDim/100).round()
    @pinLeft._applyMoveTo (p0.add new Point 1 * squareDim/100, 39 * squareDim/100).round()
    @pinRight._applyMoveTo (p0.add new Point 77 * squareDim/100, 39 * squareDim/100).round()


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()