class SwitchButtonWdgt extends Widget

  buttons: nil
 
  highlightColor: Color.SILVER
  pressColor: Color.GRAY
 
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  buttonShown: 0

  # overrides to superclass
  color: Color.WHITE

  constructor: (@buttons) ->

    # additional properties:

    super()

    #@color = Color.create 255, 152, 152
    #@color = Color.WHITE
    for eachButton in @buttons
      @add eachButton

    @_invalidateLayout()
  
  # so that when you duplicate a "selected" toggle
  # and you pick it up and you attach it somewhere else
  # it gets automatically unselected
  _reactToBeingAdded: (whereTo, beingDropped) ->
    @resetSwitchButton()

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  _reLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout


    # TODO shouldn't be calling this _applyBoundsAndNotify from here,
    # rather use super
    @_applyBoundsAndNotify newBoundsForThisLayout

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


  # TODO
  getTextDescription: ->

  # if one calls "isSelected" it probably means that this SwitchButton
  # has two buttons: a "selected" button and an "unselected" button
  isSelected: ->
    return @buttonShown != 0

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

  resetSwitchButton: ->
    @buttonShown = 0
    @_invalidateLayout()
