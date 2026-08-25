# Sliders (and hence slider button widgets)
# are also used in the ViewportWdgts .

# The orientation is auto-derived from my geometry (taller-than-wide = vertical);
# a user-forced orientation existed once and was simplified away as uncommon.

class SliderWdgt extends CircleBoxWdgt

  @augmentWith ControllerMixin

  # A slider is editor content when dropped alone (a value control you can select/align), but a
  # viewport's scrollbar is CHROME and must NOT get the editor-focus SELECTION overlay (§5.D D-3/D21). The
  # SAME class serves both, so I can't blanket-exclude -- instead I ASK my parent whether it owns me as a
  # scrollbar (ViewportWdgt.isMyScrollBar, dispatched via ?() so a non-viewport parent answers
  # undefined). A content slider -- even one dropped INTO a viewport's content -- is never the viewport's
  # vBar/hBar, so it stays framable; only the actual bars are excluded.
  excludedFromEditorFocusTracking: ->
    @parent?.isMyScrollBar?(@) is true

  start: undefined
  stop: undefined
  value: undefined
  size: undefined
  offset: undefined
  button: undefined
  # my as-built width, frozen at the first menuEntryPreferredWidth ask (see
  # that method); declared so Duplicator duplication carries it.
  menuEntryNaturalWidth: undefined

  smallestValueIsAtBottomEnd: false

  # ── SCROLL-INDICATOR PRESENTATION (program ruling G4) ─────────────────────────────────────
  # A viewport's scrollbar wears an indicator presentation: 'thin' (thumb only, untouchable) or
  # 'fat' (the full control, under a hovering pointer). undefined on every OTHER slider — a value
  # control is not an indicator, and none of this touches it.
  indicatorMode: undefined
  # the alphas the two states wear: the track's (fat only — a thin indicator paints no track) and
  # the thumb's
  indicatorTrackAlpha: 0.1
  indicatorThumbAlpha: 0.4
  # and the pair a PLAIN slider wears — a translucent track and a solid thumb. Named because two
  # places need them: my constructor, and the return from an indicator presentation.
  plainTrackAlpha: 0.1
  plainThumbAlpha: 1
  # The presentation does not ride a file: my viewport RE-DERIVES it from its own overflow at the
  # first arrange after a restore, exactly as it does on a freshly built world, so a snapshot
  # carrying a mode could only ever disagree with it. Merged up the chain by
  # Serializer.transientsForClass, which ADDS to Widget's list.
  @serializationTransients: ["indicatorMode"]

  # I drive numbers, and the number I export is my `value` pin (see `pins`, below).
  producesPinKind: "numerical"
  principalPinLabel: "value"

  idealRatioWidthToHeight: 1/4

  # POSITIONAL for the four numbers, an OPTIONS object for the rest.
  #
  # The numbers are a natural ordered tuple (range, then value, then size) and they are the
  # USER-FACING spelling: a spreadsheet cell accepts typed CoffeeScript, so `new SliderWdgt 0, 100,
  # 30, 10` is a formula a user enters (FormulaCompiler), and it is the documented idiom in
  # src/macros/MACRO-PATTERNS.md. Keeping them positional keeps that terse.
  #
  # The two trailing knobs are FLAGS, and they are why the options object exists: they used to be
  # reachable only by passing holes through the four numbers, and the two groups of callers that
  # wanted them wanted DISJOINT tails — 6 sites wanted only the flag, 2 only the colour — so no
  # parameter ORDER could serve both. Those callers now state the numbers they want and name the
  # knob. Assigned before the super call, preserving the order the all-`@param` form compiled to.
  constructor: (@start = 1, @stop = 100, @value = 50, @size = 10, opts = {}) ->
    @color = opts.color ? Color.BLACK
    @smallestValueIsAtBottomEnd = opts.smallestValueIsAtBottomEnd ? false
    super()
    @alpha = @plainTrackAlpha
    # a scrollbar wearing its THIN indicator presentation is narrower than the generic 5px
    # floor every widget carries, and the dial that names that width must mean what it says.
    # (DividerWdgt relaxes its own minimum the same way, for the same kind of reason.)
    @_setMinimumExtent new Point 1, 1
    @__commitExtent new Point 20, 100
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  # The button used to be built BEFORE super -- legacy placement, nothing in the
  # constructor chain reads @button (Widget/CircleBoxWdgt ctors size through the
  # _commitBounds/__commitExtent leaves, which never dispatch to _applyExtent).
  _buildAndConnectChildrenNoSettle: ->
    @button = new SliderButtonWdgt
    @_addNoSettle @button

  # ⚠ Do NOT delete this as "the same as the derivation". It IS what Widget's derivation would
  # produce, but I extend CircleBoxWdgt -- so without it the chain answers "circle-box".
  colloquialName: ->
    "slider"

  # Wear an indicator presentation (my viewport derives it; see ViewportWdgt._refreshScrollIndicators).
  # PRESENTATION ONLY: my value, my range and my wiring are untouched, which is exactly why the
  # bars stay SliderWdgts instead of becoming a second overlay family. The thin state paints the
  # thumb alone — the track's alpha goes to zero. `undefined` is the third state and means "not an
  # indicator at all": the plain slider look, and a pointer that stops on me again.
  showAsScrollIndicator: (mode) ->
    return if @indicatorMode is mode
    @indicatorMode = mode
    @alpha = switch mode
      when 'fat'  then @indicatorTrackAlpha
      when 'thin' then 0
      else             @plainTrackAlpha
    @button?.showAsScrollIndicatorThumb? (if mode? then @indicatorThumbAlpha else @plainThumbAlpha)
    @_fullChanged()

  # Am I an indicator the pointer must pass THROUGH? True in every state but 'fat': an indicator
  # is not a target (ruling G3), so a click over a thin bar reaches the content under it.
  # Asked by me and by my thumb.
  indicatorIsIntangible: ->
    @indicatorMode? and @indicatorMode isnt 'fat'

  catchesPointerAt: (aPoint) ->
    return false if @indicatorIsIntangible()
    super

  # How far my thumb sits inside my track, read by the thumb's own arrange. A thin indicator
  # paints no track for a thumb to sit inside, so there the thumb fills the bar.
  thumbInsetInTrack: ->
    if @indicatorIsIntangible() then 0 else 2

  # As a menu entry, prefer the width I was BUILT at, frozen at the first ask
  # (a slider is a stretch control with no intrinsic content width, so its
  # natural width IS its as-built width). The first ask happens at the rows-
  # panel's first arrange — byte-what the old `@width()` read-back answered —
  # but freezing kills the no-shrink ratchet: after the panel stretches me to
  # the widest row, later asks kept reporting the STRETCHED width, so a menu
  # could never narrow again (menu-row-conformance plan, Phase 1).
  menuEntryPreferredWidth: -> @menuEntryNaturalWidth ?= @width()


  initialiseDefaultVerticalStackLayoutSpec: ->
    # use the existing VerticalStackLayoutSpec (if it's there)
    unless @_contentStackSpec?.isContentStackCapable?()
      @_contentStackSpec = new VerticalStackLayoutSpec 0

  _reactToBeingAdded: (whereTo, beingDropped) ->
    @_reLayoutSelfAndButton()
    # An indicator presentation is something a VIEWPORT puts on the bar it HOLDS. Landing anywhere
    # else — the hand, the desktop, a panel — I am a plain slider again, and a plain slider is a
    # target: a thin, pointer-through look must not survive being picked up, or the bar becomes a
    # widget on the desktop that nothing can ever click, with no scroll band left to hover it back.
    # public-call-sanctioned: showAsScrollIndicator IS the one door onto this presentation (my
    # viewport comes through it too) and it settles nothing — it writes two alphas and repaints.
    @showAsScrollIndicator undefined  unless whereTo.isMyScrollBar? @
    # A DUPLICATED or re-parented control carries its wire records but NO edges — the engine's index
    # is derived and never duplicated or serialized, and the client re-declares it (dataflow spec §2).
    # Joining a live world is the moment a copy can do that, so a duplicated scrollbar follows its
    # content from the start rather than only from its first drag.
    @_ensureTrackingEdges()

  # Re-lay-out me and my thumb, then repaint -- the couplet every value/geometry change
  # ends with.
  _reLayoutSelfAndButton: ->
    @_reLayoutSelf()
    @_reLayoutChildren()
    @_changed()

  # I am a size-tracking container of my one child: the thumb tracks my frame
  # (its position is derived from my value + my track geometry). Conforming to
  # the engine's child contract (menu-row-conformance plan, Phase 2b) replaces
  # the old bespoke `_applyExtent` re-lay hook: in a stack/rows-panel arrange
  # the tracking branch sizes me via _setWidthSizeHeightAccordingly (virtual
  # _applyWidth + synchronous _reLayout since I now defer), and any base
  # _applyExtent resize schedules my _reLayout via the valve -- both end HERE.
  # The button guard covers deserialization, where @button can still be a
  # string reference (see unitSize).
  _reLayoutChildren: ->
    if @button? and @button instanceof SliderButtonWdgt
      @button._reLayoutSelf()

  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()
    
  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW , FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW, 0
    @_contentStackSpec.resizerCanOverlapContents = false

  
  rangeSize: ->
    @stop - @start
  
  ratio: ->
    @size / @rangeSize()
  
  unitSize: ->
    # might happen in phase of deserialization that
    # the button reference here is still a string
    # so skip in that case
    if !(@button? and @button instanceof SliderButtonWdgt)
      return 1
    if @autoOrientation() is "vertical"
      return (@height() - @button.height()) / @rangeSize()
    else
      return (@width() - @button.width()) / @rangeSize()

  # it does what setValue does, but it doesn't update the
  # target i.e. it doesn't "fire" as when the user
  # moves the slider.
  # This is useful when the slider needs to reflect the
  # state of something that has been independently changed
  # (i.e. changed by something else than the user moving the slider)
  _updateHandlePosition: (newvalue) ->
    @value = Number(newvalue)
    @_reLayoutSelfAndButton()

  setValue: (newvalue) ->
    @value = Number(newvalue)
    @updateTarget()
    @_reLayoutSelfAndButton()
    
  # `constrainedButtonPosition`, when supplied, is the button's already-clamped
  # new top-left (passed by SliderButtonWdgt.nonFloatDragging right after it moves
  # the thumb there). Deriving the value from it — instead of reading the just-moved
  # @button.top()/.left()/.bottom() back — decouples value-derivation from the thumb's
  # APPLIED geometry, which is the precondition for ever deferring the thumb's move.
  # It is byte-identical to the old read-back: the raw move inside
  # SliderButtonWdgt.nonFloatDragging (its @_applyMoveTo newPosition call) runs
  # synchronously BEFORE this call, so @button.top() ≡ arg.y, @button.left() ≡
  # arg.x, @button.bottom() ≡ arg.y + @button.height() at that instant. No argument ⇒
  # fall back to the applied button geometry (safe for any other/serialization caller).
  # See docs/archive/softwrap-deferred-layout-conversion-plan.md §6a.
  updateValue: (constrainedButtonPosition) ->
    if constrainedButtonPosition?
      buttonTop = constrainedButtonPosition.y
      buttonLeft = constrainedButtonPosition.x
      buttonBottom = constrainedButtonPosition.y + @button.height()
    else
      buttonTop = @button.top()
      buttonLeft = @button.left()
      buttonBottom = @button.bottom()

    if @autoOrientation() is "vertical"
      if @smallestValueIsAtBottomEnd
        relPos = @bottom() - buttonBottom
      else
        relPos = buttonTop - @top()
    else
      relPos = buttonLeft - @left()

    newvalue = Math.round relPos / @unitSize() + @start

    if @value != newvalue
      @setValue newvalue

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    # a bang is a FORCE-fire (spec §8): mark stale+forced so it propagates despite the equal-value cutoff.
    world.dataflow.markStale @, true
    return


  updateTarget: ->
    @_fireConnection @value
    return

  reactToTargetConnection: ->
    @updateTarget()

  # The REVERSE half of my wire (connector plan §P8): my target announced that something about it
  # changed, and I RE-READ it instead of being handed a value — a `firesOnAnyChange` edge, the same
  # shape a reflected menu row uses (MenuItemWdgt._subscribeToMyReflectedSource, which likewise
  # ignores what is delivered). What I re-read is the pin my TRACKING WIRE's own action writes, so I
  # follow exactly what I drive.
  #   A target that a slider can be bound to also says what SCALE that pin lives on
  # (`sliderRangeForPin`, capability-probed — most targets have no answer and want none). Without a
  # range there is no thumb geometry to derive, so I keep what I have; a degenerate range would
  # divide by zero in unitSize.
  #   Public, and sound as the edge's action with no `_<action>Connector` lane: _updateSpecs applies
  # through the non-notifying re-lay tiers and opens no settle, so it JOINS the drain's pass settle
  # the way setValue / setColor do (ControllerMixin._fireConnection's note on routing).
  reflectTarget: ->
    wire = @_trackingWire()
    return unless wire?
    pin = wire.target.pinDrivenBy? wire.action
    return unless pin?.getterName?
    range = wire.target.sliderRangeForPin? pin
    return unless range?
    @_updateSpecs range.start, range.stop, wire.target[pin.getterName](), range.size

  # Could I FOLLOW this pin of this target — is there a thumb geometry to derive?
  # (ControllerMixin._canTrackWire, which asks this of the follower because only the follower knows
  # what it can render.) A scale is what I need and what most targets have no answer for, so this is
  # the condition that keeps the "follows it too" row off almost every wire.
  #   ⚠ Asked again at fire time by reflectTarget, deliberately rather than cached: a menu is built
  # at one moment and clicked at another, and a target can be re-sized or emptied in between — the
  # same reasoning _bindableTargets states for the bind chooser.
  _canReflectPin: (theTarget, pin) ->
    return (theTarget.sliderRangeForPin? pin)?

  # My `value` pin's reader (dataflow spec §9.3), which is also what exportedValue answers because
  # `value` is my principal pin: a slider-valued spreadsheet cell reads as its number, and a
  # reference to that cell yields the number. The duck-typed cluster already probed `x.getValue?()`
  # at the setStart/setStop/setSize call sites; this makes a SliderWdgt answer it on itself too.
  getValue: -> @value

  # SliderWdgt menu:
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "show value", @, "showValue", toolTip: "display a dialog box\nshowing the selected number"
    menu.addMenuItem "floor...", @, "floorPopout", toolTip: "set the minimum value\nwhich can be selected"
    menu.addMenuItem "ceiling...", @, "ceilingPopout", toolTip: "set the maximum value\nwhich can be selected"
    menu.addMenuItem "button size...", @, "buttonSizePopout", toolTip: "set the range\ncovered by\nthe slider button"
    @_addTargetConnectionMenuEntries menu

  # The three range prompts. ⚠ An action MUST be a STRING method name: ButtonWdgt dispatches
  # `@target[@action]`, so a function literal indexes the target with a stringified function,
  # finds nothing, and throws (its own dev tripwire says so). These read the menu's title from
  # the dispatcher's first slot — the MENU ITEM — which is the same idiom
  # Widget.transparencyPopout uses: the row climbs to its own pop-up and asks it for its title.
  floorPopout: (menuItem) ->
    @prompt menuItem.parent.popUpTitle() + "\nfloor:", @, "setStart",
      defaultContents: @start.toString()
      floorNum: 0
      ceilingNum: @stop - @size
      isRounded: true

  ceilingPopout: (menuItem) ->
    @prompt menuItem.parent.popUpTitle() + "\nceiling:", @, "setStop",
      defaultContents: @stop.toString()
      floorNum: @start + @size
      ceilingNum: @size * 100
      isRounded: true

  buttonSizePopout: (menuItem) ->
    @prompt menuItem.parent.popUpTitle() + "\nbutton size:", @, "setSize",
      defaultContents: @size.toString()
      floorNum: 1
      ceilingNum: @stop - @start
      isRounded: true

  showValue: ->
    @inform @value

  # Adopt a whole scale at once — the APPLY half of reflectTarget, and reflect-without-firing like
  # _updateHandlePosition above (it deliberately does not call updateTarget: I am SHOWING a value,
  # not producing one, so announcing would drive my target from my own reflection).
  #   PRIVATE: the only caller is my own reflectTarget. It was public while a viewport pushed
  # four numbers into the bars it held fields for; the reverse edge (connector §P8) makes the bar
  # pull instead, so there is no external caller left and the [U] call-separation rule is right to
  # say so.
  _updateSpecs: (start, stop, value, size)->
    if start? then @start = start
    if stop? then @stop = stop
    if value? then @value = value
    if size? then @size = size
    @_reLayoutSelf()

    @button._reLayoutSelf()

    # self + thumb: the re-lays above move/resize the button through
    # non-notifying tiers — a widget invalidates only itself
    # (widget-citizenship contract point 2).
    @_fullChanged()
  
  setStart: (num) ->
    if typeof num is "number"
      @start = Math.min Math.max(num, 0), @stop - @size
    else
      newStart = parseFloat num
      @start = Math.min Math.max(newStart, 0), @stop - @size  unless isNaN newStart
    @value = Math.max @value, @start
    @updateTarget()
    @_reLayoutSelfAndButton()
  
  setStop: (num) ->
    if typeof num is "number"
      @stop = Math.max num, @start + @size
    else
      newStop = parseFloat num
      @stop = Math.max newStop, @start + @size  unless isNaN newStop
    @value = Math.min @value, @stop
    @updateTarget()
    @_reLayoutSelfAndButton()
  
  mouseDownLeft: (pos) ->
    # jump-drag policy is the OWNING CONTEXT's (viewport / prompt) — capability via ?(),
    # instead of `(parent instanceof ViewportWdgt) or (parent instanceof PromptWdgt)`
    # (type-test-elimination ε)
    if @button.parent == @ and @parent?.sliderTrackPressJumpsButton?()
      world.hand.nonFloatDragWdgtFarAwayToHere @button, pos
      # in an ideal world when a widget moves under the pointer
      # it gets all the right events like mouseEnter etc.
      # however that's difficult to do, just set the "pressed"
      # color from here
      @button.setPressedColor()
    else
      @escalateEvent "mouseDownLeft", pos
    

  setSize: (size) ->
    if typeof size is "number"
      @size = Math.min Math.max(size, 1), @stop - @start
    else
      newSize = parseFloat size
      @size = Math.min Math.max(newSize, 1), @stop - @start  unless isNaN newSize
    @value = Math.min @value, @stop - @size
    # the resize mechanism happens to keep the
    # button's value stable, so there is no
    # need to update the target.
    #@updateTarget()
    @_reLayoutSelfAndButton()
  
  
  # `value` is my principal pin and the only READABLE one here (getValue -> @value). start/stop/size
  # are write-only for want of readers, not by policy. Each pin states its own kinds, so "a bang takes
  # anything" and "a value takes a number or the string spelling of one" are said once each.
  # ⚠ `value` is the ONE readable pin in the tree that cannot declare `announces`, and the reason is
  # worth keeping because the answer looks like "obviously yes". Every value-PRODUCING path
  # (setValue / setStart / setStop) does announce — but my two value-SHOWING paths do not, and must
  # not yet: `_updateHandlePosition` and `_updateSpecs` are how I REFLECT a target, and an
  # announcement there would re-fire on every drain pass, because neither has an equal-value cutoff.
  # That is a self-sustaining loop with no cycle in it at all.
  #   ⇒ closing it is the follower arc's business, not a one-liner: those two need the cutoff first,
  # and the only thing it would buy is a follower OF a follower — which needs a second reflector to
  # exist, since I am the only one and I can only render a pin whose target answers
  # `sliderRangeForPin`. Filed in BACKLOG.
  pins: -> super().concat [
    new PinSpec "bang!", "any",                    set: "bang"
    new PinSpec "value", ["numerical", "string"],  set: "setValue", get: "getValue"
    new PinSpec "start", "numerical",              set: "setStart"
    new PinSpec "stop",  "numerical",              set: "setStop"
    new PinSpec "size",  "numerical",              set: "setSize"
  ]

  