# Sliders (and hence slider button widgets)
# are also used in the ScrollPanelWdgts .

# The orientation is auto-derived from my geometry (taller-than-wide = vertical);
# a user-forced orientation existed once and was simplified away as uncommon.

class SliderWdgt extends CircleBoxWdgt

  @augmentWith ControllerMixin

  target: undefined
  action: undefined

  # A slider is editor content when dropped alone (a value control you can select/align), but a scroll
  # panel's scrollbar is CHROME and must NOT get the editor-focus SELECTION overlay (§5.D D-3/D21). The
  # SAME class serves both, so I can't blanket-exclude -- instead I ASK my parent whether it owns me as a
  # scrollbar (ScrollPanelWdgt.isMyScrollBar, dispatched via ?() so a non-scroll-panel parent answers
  # undefined). A content slider -- even one dropped INTO a scroll panel's content -- is never the panel's
  # vBar/hBar, so it stays framable; only the actual bars are excluded.
  excludedFromEditorFocusTracking: ->
    @parent?.isMyScrollBar?(@) is true

  start: undefined
  stop: undefined
  value: undefined
  size: undefined
  offset: undefined
  button: undefined
  argumentToAction: undefined
  # my as-built width, frozen at the first menuEntryPreferredWidth ask (see
  # that method); declared so Duplicator duplication carries it.
  menuEntryNaturalWidth: undefined

  smallestValueIsAtBottomEnd: false

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
    @alpha = 0.1
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

  colloquialName: ->
    "slider"

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

  setValue: (newvalue, ignored) ->
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
      @setValue newvalue, undefined

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    # a bang is a FORCE-fire (spec §8): mark stale+forced so it propagates despite the equal-value cutoff.
    world.dataflow.markStale @, true
    return


  updateTarget: ->
    @_fireConnection @value, @argumentToAction
    return

  reactToTargetConnection: ->
    @updateTarget()

  # The exported-value reader (dataflow spec §9.3): a slider joins the spreadsheet value protocol by
  # exposing its numeric @value, so Widget.exportedValue()'s `getColor?() ? getValue?() ? @text`
  # chain reads a slider-valued cell as its number (and a reference to that cell yields the number).
  # The duck-typed cluster already probed `x.getValue?()` at the setStart/setStop/setSize call sites;
  # this makes a SliderWdgt answer it on itself too.
  getValue: -> @value

  # SliderWdgt menu:
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "show value", @, "showValue", toolTip: "display a dialog box\nshowing the selected number"
    menu.addMenuItem "floor...", @, (->
      @prompt menu.title + "\nfloor:",
        @setStart,
        @start.toString(),
        undefined,
        0,
        @stop - @size,
        true
    ), "set the minimum value\nwhich can be selected"
    menu.addMenuItem "ceiling...", @, (->
      @prompt menu.title + "\nceiling:",
        @setStop,
        @stop.toString(),
        undefined,
        @start + @size,
        @size * 100,
        true
    ), "set the maximum value\nwhich can be selected"
    menu.addMenuItem "button size...", @, (->
      @prompt menu.title + "\nbutton size:",
        @setSize,
        @size.toString(),
        undefined,
        1,
        @stop - @start,
        true
    ), "set the range\ncovered by\nthe slider button"
    @_addTargetConnectionMenuEntries menu, "numerical"

  showValue: ->
    @inform @value

  # once you set all the properties of a slider you
  # call this method so it updates itself
  updateSpecs: (start, stop, value, size)->
    if start? then @start = start
    if stop? then @stop = stop
    if value? then @value = value
    if size? then @size = size
    @_reLayoutSelf()

    @button._reLayoutSelf()

    # self + thumb: the re-lays above move/resize the button through
    # non-notifying tiers. The caller covers its own repaint (a scroll
    # frame's _reLayoutScrollbars does its own _changed()) — a widget
    # invalidates only itself (widget-citizenship contract point 2).
    @_fullChanged()
  
  setStart: (numOrWidgetGivingNum) ->

    if numOrWidgetGivingNum.getValue?
      num = numOrWidgetGivingNum.getValue()
    else
      num = numOrWidgetGivingNum

    if typeof num is "number"
      @start = Math.min Math.max(num, 0), @stop - @size
    else
      newStart = parseFloat num
      @start = Math.min Math.max(newStart, 0), @stop - @size  unless isNaN newStart
    @value = Math.max @value, @start
    @updateTarget()
    @_reLayoutSelfAndButton()
  
  setStop: (numOrWidgetGivingNum) ->

    if numOrWidgetGivingNum.getValue?
      num = numOrWidgetGivingNum.getValue()
    else
      num = numOrWidgetGivingNum

    if typeof num is "number"
      @stop = Math.max num, @start + @size
    else
      newStop = parseFloat num
      @stop = Math.max newStop, @start + @size  unless isNaN newStop
    @value = Math.min @value, @stop
    @updateTarget()
    @_reLayoutSelfAndButton()
  
  mouseDownLeft: (pos) ->
    # jump-drag policy is the OWNING CONTEXT's (scroll frame / prompt) — capability via ?(),
    # instead of `(parent instanceof ScrollPanelWdgt) or (parent instanceof PromptWdgt)`
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
    

  setSize: (sizeOrWidgetGivingSize) ->
    if sizeOrWidgetGivingSize.getValue?
      size = sizeOrWidgetGivingSize.getValue()
    else
      size = sizeOrWidgetGivingSize

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
  
  # openTargetSelector: -> taken form the ControllerMixin
  
  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.numericalSetters()

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["bang!", "value"], ["bang", "setValue"]

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["bang!", "value", "start", "stop", "size"], ["bang", "setValue", "setStart", "setStop", "setSize"]
  
  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @_appendSettersAndDedup menuEntriesStrings, functionNamesStrings, ["bang!"], ["bang"]

  