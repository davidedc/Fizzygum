# sends a message to a target object when pressed.
# Doesn't have any particular shape, but can host
# a widget to be used as "face"

# TODO it's unclear to me why we pass a number of targets
# and actions in the constructor when what we could simply
# do is to extend this button and override the mouse events?

class ButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name

  target: undefined
  action: undefined
  dataSourceWidgetForTarget: undefined
  widgetEnv: undefined
 
 
  doubleClickAction: undefined
  argumentToAction1: undefined
  argumentToAction2: undefined
 
  toolTipMessage: undefined

  # what the button SHOWS, from opts.face. A string is coerced to a centred StringWdgt
  # and added as a child in the constructor, so by then this always holds a widget.
  faceWidget: undefined

  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  # tells if the button represents a widget, in which
  # case we are going to highlight the Widget on hover
  representsAWidget: false

  padding: 0


  # overrides to superclass
  color: Color.WHITE

  # target and action are the identity: WHO to tell and WHAT to say. They are the
  # established pair, they are the only two a typical caller passes, and no reader has to
  # look up their order. Everything else is an independently-optional knob and rides `opts`
  # (docs/architecture/constructor-and-parameter-conventions.md).
  #
  # `closesUnpinnedPopUps` in particular is an OPTION rather than the leading positional: a bare
  # `true` opening nearly every call site is precisely the smell R1 names, and since it defaults
  # to true, the sites that only wanted the default simply do not say it.
  #
  # `face` (not `faceWidget`) because the value is as often a STRING as a widget — the body
  # below wraps a string into a centred StringWdgt — and an option is named for what the
  # CALLER means (R4).
  #
  # NOTHING here is a `@param` beyond the head: a `@param` assigns unconditionally, so a
  # subclass's prototype value for any of these fields is clobbered with `undefined` on every
  # construction. `toolTipMessage` in particular is read GUARDED, which is what lets a subclass
  # declare `toolTipMessage:` on its prototype and have it survive — the IconButtonWdgt family
  # states its hover text that way.
  constructor: (@target, @action, opts = {}) ->
    @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = opts.closesUnpinnedPopUps ? true
    @faceWidget = opts.face
    @dataSourceWidgetForTarget = opts.dataSource
    @widgetEnv = opts.widgetEnv
    @toolTipMessage = opts.toolTip if opts.toolTip?
    @doubleClickAction = opts.doubleClickAction
    @argumentToAction1 = opts.arg1
    @argumentToAction2 = opts.arg2
    @representsAWidget = opts.representsAWidget ? false
    @padding = opts.padding ? 0

    # additional properties:

    super()
    @defaultRejectDrags = true

    @_buildAndConnectChildren()

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # This REPLACES the old "defer the face's layout until attach" hack. The old fear -- "a settle in a
  # constructor leaks into ANY callback that builds a button (e.g. FrameWdgt._reactToChildDropped's chrome
  # rebuild via new *IconButtonWdgt, which must stay settle-neutral)" -- no longer bites: a button built
  # INSIDE such a callback runs in-flush, where the settle-tier's in-flush+orphan AUTO-DEFER
  # (Widget._settleLayoutsAfter: `return coreThunk() if @isOrphan()`) defers automatically. So no settle
  # leaks into the settle-neutral callback, while a top-level `new ButtonWdgt` settles its own orphan layout.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if @faceWidget?
      if (typeof @faceWidget) == "string"
        @faceWidget = (new StringWdgt @faceWidget, fontSize: WorldWdgt.preferencesAndSettings.textInButtonsFontSize).alignCenter()
      @_addNoSettle @faceWidget
      @_invalidateLayout()
  

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout

    if @faceWidget?.parent == @
      @faceWidget._applyGrantedBounds newBoundsForThisLayout.insetBy @padding

    super
    @_markLayoutAsFixed()

  # trigger button action:
  trigger: ->
    if @action? and @action != ""
      # dev-build type tripwire (2026-07-06 incident: an @action passed as a function CLOSURE fails
      # obscurely here — @target[<function>] coerces to an undefined key; SliderWdgt carried the same
      # latent misuse). @action must be a STRING method name on @target. `if Automator?` ⇒ absent
      # from a production build like all test-only code (the Automator is the harness part).
      if Automator? and typeof @action isnt 'string'
        throw new Error "ButtonWdgt action must be a STRING method name on the target (dispatched as @target[@action]) — got #{typeof @action}"
      @target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, @argumentToAction1, @argumentToAction2
    return

  triggerDoubleClick: ->
    # same as trigger() but use doubleClickAction instead of action property
    # note that specifying a doubleClickAction is optional
    return  unless @doubleClickAction
    @target[@doubleClickAction]()

  
  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()
    @escalateEvent "mouseClickLeft", arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

  mouseDoubleClick: ->
    @triggerDoubleClick()

  # you shouldn't be able to drag a compound
  # widgets containing a button by dragging the button
  # (because you expect buttons attached to anything but the
  # world to be "slippery", i.e.
  # you can "skid" your drag over it in case you change
  # your mind on pressing it)
  # and you shouldn't be able to drag the button away either
  # so the drag is entirely rejected
  #   UNLESS MY PARENT SAYS I AM A PAYLOAD RATHER THAN A PART. Slipperiness protects a
  # COMPOUND — it assumes the button is a piece of the thing containing it — so a container
  # that declares the opposite about me is answering the very question slipperiness assumes.
  # `wantsDetachOfChild` is the existing parent-side opt-in, and reusing it is the point:
  # Widget.grabsToParentWhenDragged consults the same declaration, so the two questions a grab
  # asks — "is this drag cancelled" and "does it lift my parent instead" — now read ONE fact
  # and cannot disagree. Resting on the desktop is the same statement, made by the one parent
  # with no reason to spell it out.
  #   Clients: a MenuRowsPanelWdgt whose pop-up is PINNED (dragging a command onto your own
  # control panel), and a spreadsheet CellWdgt's hosted payload.
  rejectDrags: ->
    return false if @parent == world
    return false if @parent?.wantsDetachOfChild? @
    return @defaultRejectDrags

