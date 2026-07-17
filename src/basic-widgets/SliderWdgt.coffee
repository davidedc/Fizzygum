# Sliders (and hence slider button widgets)
# are also used in the ScrollPanelWdgts .

# In previous versions the user could force an orientation, so
# that one could have a vertical slider even if the slider is
# more wide than tall. Simplified that code because it doesn't
# look like a common need.

class SliderWdgt extends CircleBoxWdgt

  @augmentWith ControllerMixin

  target: nil
  action: nil

  start: nil
  stop: nil
  value: nil
  size: nil
  offset: nil
  button: nil
  argumentToAction: nil

  smallestValueIsAtBottomEnd: false

  idealRatioWidthToHeight: 1/4

  constructor: (
    @start = 1,
    @stop = 100,
    @value = 50,
    @size = 10,
    @color = Color.BLACK,
    @smallestValueIsAtBottomEnd = false
    ) ->
    super # if nil, then a vertical one will be created
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

  # As a menu entry, prefer my own current width (MenuWdgt.maxWidthOfMenuEntries
  # calls this polymorphically instead of type-checking the entry).
  menuEntryPreferredWidth: -> @width()


  initialiseDefaultVerticalStackLayoutSpec: ->
    # use the existing VerticalStackLayoutSpec (if it's there)
    unless @layoutSpecDetails instanceof VerticalStackLayoutSpec
      @layoutSpecDetails = new VerticalStackLayoutSpec 0

  _reactToBeingAdded: (whereTo, beingDropped) ->
    @_reLayoutSelfAndButton()

  # Re-lay-out me and my thumb, then repaint -- the couplet every value/geometry change
  # ends with. The button guard covers deserialization, where @button can still be a
  # string reference (see unitSize).
  _reLayoutSelfAndButton: ->
    @_reLayoutSelf()
    if @button? and @button instanceof SliderButtonWdgt
      @button._reLayoutSelf()
    @changed()

  _applyExtent: (aPoint) ->
    unless aPoint.equals @extent()
      super aPoint
      # my backing store had just been updated
      # in the call of super, now
      # it's the time of the button
      @button._reLayoutSelf()
    
  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW , WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW, 0
    @layoutSpecDetails.resizerCanOverlapContents = false

  
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
  # It is byte-identical to the old read-back: the raw move at SliderButtonWdgt:95
  # runs synchronously BEFORE this call, so @button.top() ≡ arg.y, @button.left() ≡
  # arg.x, @button.bottom() ≡ arg.y + @button.height() at that instant. No argument ⇒
  # fall back to the applied button geometry (safe for any other/serialization caller).
  # See docs/archive/softwrap-deferred-layout-conversion-plan.md §6a.
  updateValue: (constrainedButtonPosition = nil) ->
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
      @setValue newvalue, nil

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
        nil,
        0,
        @stop - @size,
        true
    ), "set the minimum value\nwhich can be selected"
    menu.addMenuItem "ceiling...", @, (->
      @prompt menu.title + "\nceiling:",
        @setStop,
        @stop.toString(),
        nil,
        @start + @size,
        @size * 100,
        true
    ), "set the maximum value\nwhich can be selected"
    menu.addMenuItem "button size...", @, (->
      @prompt menu.title + "\nbutton size:",
        @setSize,
        @size.toString(),
        nil,
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
    
    # if the parent is the same as the target
    # then issue a fullChanged on the parent.
    # It's likely to be duplicate, which doesn't
    # matter, but it will consolidate the updates
    # of the scrollbars too
    if @parent != @target
      @changed()
    else
      @parent.fullChanged()
  
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
    # was `(parent instanceof ScrollPanelWdgt) or (parent instanceof PromptWdgt)`
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
    # it just so happens that, as hoped but somewhat
    # unexpectedly, as the slider resizes,
    # the resize mechanism is such that the
    # button keeps the same value, so there
    # is no need to update the target.
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

  