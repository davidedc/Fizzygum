class SwitchButtonWdgt extends Widget

  buttons: undefined
 
  highlightColor: Color.SILVER
  pressColor: Color.GRAY
 
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  buttonShown: 0

  # overrides to superclass
  color: Color.WHITE

  # WHICH of my buttons is showing IS my value, and it is an INDEX into @buttons. That is why there is
  # no boolean payload kind here: a switch is n-way, and a boolean is only what the n=2 case looks
  # like from outside, so the two-button subclass exports 0 or 1 as an ordinary number and the whole
  # question of a fourth kind for one widget does not arise (connector plan §P10(d), answered by the
  # GENERAL class rather than by the toggle).
  #   It ANNOUNCES, and what earns that is the funnel below: every path that moves @buttonShown — a
  # click, a reflect from elsewhere, the reset on being added — goes through _setToggleState, which is
  # the one place that tells the dataflow. A pin that announced from only some of its write paths
  # would leave a follower silently stale exactly when it mattered.
  pins: -> super().concat [
    new PinSpec "shown button", "numerical", set: "setToggleState", get: "getToggleState", announces: true
  ]
  principalPinLabel: "shown button"

  constructor: (@buttons) ->

    super()

    @_buildAndConnectChildren()

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # This REPLACES the old "defer the layout until attach" hack. A switch built INSIDE a callback (e.g.
  # FrameWdgt._reactToChildDropped's chrome rebuild) runs in-flush, where the settle-tier's in-flush+orphan
  # AUTO-DEFER (Widget._settleLayoutsAfter: `return coreThunk() if @isOrphan()`) defers automatically -- so no
  # settle leaks into the settle-neutral callback. A top-level `new SwitchButtonWdgt` settles its own orphan.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    for eachButton in @buttons
      @_addNoSettle eachButton

    @_invalidateLayout()
  
  # so that when you duplicate a "selected" toggle
  # and you pick it up and you attach it somewhere else
  # it gets automatically unselected
  _reactToBeingAdded: (whereTo, beingDropped) ->
    @_resetSwitchButton()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout


    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout

    counter = 0
    for eachButton in @buttons
      if eachButton.parent == @
        eachButton._reLayout @bounds
        if counter % @buttons.length == @buttonShown
          eachButton.show()
        else
          eachButton.hide()
      counter++

    super newBoundsForThisLayout


  # if one calls "isSelected" it probably means that this SwitchButton
  # has two buttons: a "selected" button and an "unselected" button
  isSelected: ->
    return @buttonShown != 0

  getToggleState: ->
    @buttonShown

  # changes the shown button without firing the action
  # i.e. clicking the button
  # This is useful when the switch needs to reflect the
  # state of something that has been independently changed
  # (i.e. changed by something else than the user clicking this switch) --
  # including CROSS-OBJECT (the paint toolbar reflects arm/disarm on its tool
  # toggles, §5.D), hence the public wrap over the private core.
  #   It is also my `shown button` pin's setter, so it reads BOTH argument slots (the pin-setter
  # contract in docs/architecture/widget-authoring-guidelines.md) and clamps: a wire or a formula can
  # deliver any number at all, and an out-of-range index would show no button whatsoever. Clamping
  # rather than wrapping, because "show button 7" from outside means the last one, while the WRAP
  # belongs to the click below, where cycling is the gesture.
  setToggleState: (whichOne) ->
    return unless isFinite whichOne
    whichOne = Math.round whichOne
    whichOne = 0 if whichOne < 0
    whichOne = @buttons.length - 1 if whichOne > @buttons.length - 1
    @_setToggleState whichOne
    return whichOne

  # THE ONE PLACE @buttonShown MOVES — see the `announces` note on the pin. Every other path routes
  # here, so the announcement cannot be forgotten by a path added later.
  _setToggleState: (whichOne) ->
    return if @buttonShown == whichOne
    @buttonShown = whichOne
    @_invalidateLayout()
    # markStale, not markNonValueChange: this pin IS my principal one, so what changed is my VALUE,
    # and the stronger verb wakes the re-readers too (DataflowEngine header: markStale fires EVERY
    # out-edge, the firesOnAnyChange ones included).
    world.dataflow.markStale @
    return

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    # SELF-SETTLE the toggle (end-of-cycle-flush drawdown convert 2026-06-25): a discrete click is an
    # outermost public mutation, so it flushes ONCE on return instead of riding the per-frame end-of-cycle
    # flush (this was the biggest end-of-cycle residual). escalateEvent stays OUTSIDE the settle -- the
    # ancestor handler is its own outermost mutation and self-settles independently; nesting it would
    # re-enter this flush. Safe because the layout-pass collapse decisions it can trigger now route to the
    # idempotent _collapseNoSettle / _unCollapseNoSettle cores (no public re-entrant settle).
    @_settleLayoutsAfter =>
      @_setToggleState (@buttonShown + 1) % @buttons.length
    # TODO gross pattern break - usually mouseClickLeft has 9 params
    # none of which is a widget
    @escalateEvent "mouseClickLeft", @

  _resetSwitchButton: ->
    @_setToggleState 0
