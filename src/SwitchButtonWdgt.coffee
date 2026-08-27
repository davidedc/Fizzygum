class SwitchButtonWdgt extends Widget

  buttons: undefined
 
  highlightColor: Color.SILVER
  pressColor: Color.GRAY
 
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  buttonShown: 0

  # The glyph side my buttons draw at, when whoever places me names one (see IconButtonWdgt's own
  # field): my buttons wear MY box, so they wear my glyph dial with it.
  glyphSize: undefined

  # My buttons are MY faces, so whoever owns my drags owns theirs (a chrome strip claims the drags
  # that start on its pieces -- FrameBarWdgt.ownsDragsOfMyChildren). Passing the question up rather
  # than answering it myself is what keeps a switch on a strip and a switch anywhere else telling
  # their buttons two different, correct things.
  ownsDragsOfMyChildren: ->
    @parent?.ownsDragsOfMyChildren?() ? false

  # overrides to superclass
  color: Color.WHITE

  # WHICH of my buttons is showing IS my value, and it is an INDEX into @buttons. That is why there is
  # no boolean payload kind here: a switch is n-way, and a boolean is only what the n=2 case looks
  # like from outside, so the two-button subclass exports 0 or 1 as an ordinary number and the whole
  # question of a fourth kind for one widget does not arise (connector plan §P10(d), answered by the
  # GENERAL class rather than by the toggle).
  #   It ANNOUNCES, and what earns that is the funnel below: every path that moves @buttonShown — a
  # click, a reflect from elsewhere, the reset on being added — goes through _setToggleStateNoSettle,
  # which is the one place that tells the dataflow. A pin that announced from only some of its write
  # paths would leave a follower silently stale exactly when it mattered.
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
        # my buttons take my box, and with it the glyph side that box was granted for
        eachButton.glyphSize = @glyphSize
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
  # (i.e. changed by something else than the user clicking this switch).
  #   It is also my `shown button` pin's setter (the pin-setter contract in
  # docs/architecture/widget-authoring-guidelines.md): the canonical thin settle over the funnel
  # core below, returning the clamped index through it. The engine's edge apply never lands HERE
  # (DataflowEngine._applyWireValue prefers the _setToggleStateConnector twin), and in-flush
  # reflectors (the paint toolbar's mode hooks, my own click/reset) reach the core directly --
  # this wrapper is the DIRECT entry (an in-world script, discrete framework code), which gets a
  # settled world on return like every public setter.
  setToggleState: (whichOne) ->
    @_settleLayoutsAfter => @_setToggleStateNoSettle whichOne

  # The reactive-CONNECTOR entrypoint (check-layering [P]; the setFontSize/_setFontSizeConnector
  # pattern): the dataflow engine delivers wired "setToggleState" deliveries HERE, JOINING the
  # drain's enclosing settle instead of opening a nested one (which the public wrapper's
  # _settleLayoutsAfter would reject mid-window). No cycle guard: the core's announce is
  # markStale, which the engine echo-suppresses for the node it is applying into; downstream
  # delivery belongs to the drain's own ordered walk.
  _setToggleStateConnector: (whichOne) ->
    @_settleLayoutsAfterOrJoinEnclosingPass => @_setToggleStateNoSettle whichOne

  # THE ONE PLACE @buttonShown MOVES — see the `announces` note on the pin. Every other path routes
  # here, so the announcement cannot be forgotten by a path added later. Coercion lives at the
  # funnel too, so no path can write an out-of-range index (a wire or a formula can deliver any
  # number at all, and an out-of-range index would show no button whatsoever): CLAMPING rather
  # than wrapping, because "show button 7" from outside means the last one — the WRAP belongs to
  # the click below, where cycling is the gesture (it takes its modulo before calling in).
  _setToggleStateNoSettle: (whichOne) ->
    return unless isFinite whichOne
    whichOne = Math.round whichOne
    whichOne = 0 if whichOne < 0
    whichOne = @buttons.length - 1 if whichOne > @buttons.length - 1
    if @buttonShown != whichOne
      @buttonShown = whichOne
      @_invalidateLayout()
      # markStale, not markNonValueChange: this pin IS my principal one, so what changed is my VALUE,
      # and the stronger verb wakes the re-readers too (DataflowEngine header: markStale fires EVERY
      # out-edge, the firesOnAnyChange ones included).
      world.dataflow.markStale @
    whichOne

  activated: (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    # SELF-SETTLE the toggle (end-of-cycle-flush drawdown convert 2026-06-25): a discrete click is an
    # outermost public mutation, so it flushes ONCE on return instead of riding the per-frame end-of-cycle
    # flush (this was the biggest end-of-cycle residual). escalateEvent stays OUTSIDE the settle -- the
    # ancestor handler is its own outermost mutation and self-settles independently; nesting it would
    # re-enter this flush. Safe because the layout-pass collapse decisions it can trigger now route to the
    # idempotent _collapseNoSettle / _unCollapseNoSettle cores (no public re-entrant settle).
    @_settleLayoutsAfter =>
      @_setToggleStateNoSettle (@buttonShown + 1) % @buttons.length
      # A RADIO group turns its other switches off when one of them is clicked, and the switch
      # that WAS clicked is the only widget that knows which one that is — the escalation below
      # carries the pointer position, never the sender. Capability via ?(), inside my own flush,
      # so the whole group settles once.
      @parent?.radioButtonWasSwitched? @
    @escalateEvent "activated", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

  _resetSwitchButton: ->
    @_setToggleStateNoSettle 0
