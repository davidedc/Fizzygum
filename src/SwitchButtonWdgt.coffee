class SwitchButtonWdgt extends Widget

  buttons: undefined
 
  highlightColor: Color.SILVER
  pressColor: Color.GRAY
 
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  buttonShown: 0

  # overrides to superclass
  color: Color.WHITE

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

  # changes the shown button without firing the action
  # i.e. clicking the button
  # This is useful when the switch needs to reflect the
  # state of something that has been independently changed
  # (i.e. changed by something else than the user clicking this switch) --
  # including CROSS-OBJECT (the paint toolbar reflects arm/disarm on its tool
  # toggles, §5.D), hence the public wrap over the private core.
  setToggleState: (whichOne) ->
    @_setToggleState whichOne

  _setToggleState: (whichOne) ->
    if @buttonShown != whichOne
      @buttonShown = whichOne
      @_invalidateLayout()

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    # SELF-SETTLE the toggle (end-of-cycle-flush drawdown convert 2026-06-25): a discrete click is an
    # outermost public mutation, so it flushes ONCE on return instead of riding the per-frame end-of-cycle
    # flush (this was the biggest end-of-cycle residual). escalateEvent stays OUTSIDE the settle -- the
    # ancestor handler is its own outermost mutation and self-settles independently; nesting it would
    # re-enter this flush. Safe because the layout-pass collapse decisions it can trigger now route to the
    # idempotent _collapseNoSettle / _unCollapseNoSettle cores (no public re-entrant settle).
    @_settleLayoutsAfter =>
      @buttonShown++
      @buttonShown = @buttonShown % @buttons.length
      @_invalidateLayout()
    # TODO gross pattern break - usually mouseClickLeft has 9 params
    # none of which is a widget
    @escalateEvent "mouseClickLeft", @

  _resetSwitchButton: ->
    @buttonShown = 0
    @_invalidateLayout()
