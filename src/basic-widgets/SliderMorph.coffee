# Sliders (and hence slider button morphs)
# are also used in the ScrollPanelWdgts .

# In previous versions the user could force an orientation, so
# that one could have a vertical slider even if the slider is
# more wide than tall. Simplified that code because it doesn't
# look like a common need.

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions
# REQUIRES ControllerMixin

class SliderMorph extends CircleBoxMorph

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
    @color = (new Color 0, 0, 0),
    @smallestValueIsAtBottomEnd = false
    ) ->
    @button = new SliderButtonMorph()
    super # if nil, then a vertical one will be created
    @alpha = 0.1
    @silentRawSetExtent new Point 20, 100
    @silentAdd @button

  colloquialName: ->
    "slider"


  initialiseDefaultVerticalStackLayoutSpec: ->
    # use the existing VerticalStackLayoutSpec (if it's there)
    if !(@layoutSpecDetails instanceof VerticalStackLayoutSpec) or !@layoutSpecDetails?
      @layoutSpecDetails = new VerticalStackLayoutSpec 0

  iHaveBeenAddedTo: (whereTo, beingDropped) ->
    @reLayout()
    
    # might happen in phase of deserialization that
    # the button reference here is still a string
    # so skip in that case
    if @button? and @button instanceof SliderButtonMorph
      @button.reLayout()
      
    @changed()

  rawSetExtent: (aPoint) ->
    unless aPoint.eq @extent()
      #console.log "move 17"
      @breakNumberOfRawMovesAndResizesCaches()  
      super aPoint
      # my backing store had just been updated
      # in the call of super, now
      # it's the time of the button
      @button.reLayout()
    
  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.THIS_ONE_I_HAVE_NOW , PreferredSize.THIS_ONE_I_HAVE_NOW, 0
    @layoutSpecDetails.resizerCanOverlapContents = false

  
  rangeSize: ->
    @stop - @start
  
  ratio: ->
    @size / @rangeSize()
  
  unitSize: ->
    # might happen in phase of deserialization that
    # the button reference here is still a string
    # so skip in that case
    if !(@button? and @button instanceof SliderButtonMorph)
      return 1
    if @autoOrientation() is "vertical"
      return (@height() - @button.height()) / @rangeSize()
    else
      return (@width() - @button.width()) / @rangeSize()

  setValue: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
    @value = Number(newvalue)
    @updateTarget()
    @reLayout()
    
    @button.reLayout()
    
    @changed()
    
  updateValue: ->
    if @autoOrientation() is "vertical"
      if @smallestValueIsAtBottomEnd
        relPos = @bottom() - @button.bottom()
      else
        relPos = @button.top() - @top()
    else
      relPos = @button.left() - @left()

    newvalue = Math.round relPos / @unitSize() + @start

    if @value != newvalue
      @setValue newvalue, nil, nil

  # the bang makes the node fire the current output value
  bang: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
    @updateTarget()

  
  updateTarget: ->
    debugger
    if @action and @action != ""
      @target[@action].call @target, @value, @argumentToAction, @connectionsCalculationToken
    return

  reactToTargetConnection: ->
    @updateTarget()

  # SliderMorph menu:
  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "show value", true, @, "showValue", "display a dialog box\nshowing the selected number"
    menu.addMenuItem "floor...", true, @, (->
      @prompt menu.title + "\nfloor:",
        @setStart,
        @start.toString(),
        nil,
        0,
        @stop - @size,
        true
    ), "set the minimum value\nwhich can be selected"
    menu.addMenuItem "ceiling...", true, @, (->
      @prompt menu.title + "\nceiling:",
        @setStop,
        @stop.toString(),
        nil,
        @start + @size,
        @size * 100,
        true
    ), "set the maximum value\nwhich can be selected"
    menu.addMenuItem "button size...", true, @, (->
      @prompt menu.title + "\nbutton size:",
        @setSize,
        @size.toString(),
        nil,
        1,
        @stop - @start,
        true
    ), "set the range\ncovered by\nthe slider button"
    menu.addLine()
    menu.addMenuItem "set target", true, @, "openTargetSelector", "select another morph\nwhose numerical property\nwill be " + "controlled by this one"
  
  showValue: ->
    @inform @value
  
  userSetStart: (num) ->
    @start = Math.max num, @stop

  
  # once you set all the properties of a slider you
  # call this method so it updates itself
  updateSpecs: (start, stop, value, size)->
    if start? then @start = start
    if stop? then @stop = stop
    if value? then @value = value
    if size? then @size = size
    @reLayout()
    
    @button.reLayout()
    
    # if the parent is the same as the target
    # then issue a fullChanged on the parent.
    # It's likely to be duplicate, which doesn't
    # matter, but it will consolidate the updates
    # of the scrollbars too
    if @parent != @target
      @changed()
    else
      @parent.fullChanged()
  
  setStart: (numOrMorphGivingNum) ->

    if numOrMorphGivingNum.getValue?
      num = numOrMorphGivingNum.getValue()
    else
      num = numOrMorphGivingNum

    if typeof num is "number"
      @start = Math.min Math.max(num, 0), @stop - @size
    else
      newStart = parseFloat num
      @start = Math.min Math.max(newStart, 0), @stop - @size  unless isNaN newStart
    @value = Math.max @value, @start
    @updateTarget()
    @reLayout()
    
    @button.reLayout()
    
    @changed()
  
  setStop: (numOrMorphGivingNum) ->

    if numOrMorphGivingNum.getValue?
      num = numOrMorphGivingNum.getValue()
    else
      num = numOrMorphGivingNum

    if typeof num is "number"
      @stop = Math.max num, @start + @size
    else
      newStop = parseFloat num
      @stop = Math.max newStop, @start + @size  unless isNaN newStop
    @value = Math.min @value, @stop
    @updateTarget()
    @reLayout()
    
    @button.reLayout()
    
    @changed()
  
  mouseDownLeft: (pos) ->
    if @button.parent == @ and ((@parent instanceof ScrollPanelWdgt) or (@parent instanceof PromptMorph))
      world.hand.nonFloatDragMorphFarAwayToHere @button, pos
      # in an ideal world when a widget moves under the pointer
      # it gets all the right events like mouseEnter etc.
      # however that's difficult to do, just set the "pressed"
      # color from here
      @button.setPressedColor()
    else
      @escalateEvent "mouseDownLeft", pos
    

  setSize: (sizeOrMorphGivingSize) ->
    if sizeOrMorphGivingSize.getValue?
      size = sizeOrMorphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

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
    @reLayout()
    
    @button.reLayout()
    
    @changed()
  
  # openTargetSelector: -> taken form the ControllerMixin
  
  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    [menuEntriesStrings, functionNamesStrings] = theTarget.numericalSetters()
    menu = new MenuMorph @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuMorph @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "value"
    functionNamesStrings.push "bang", "setValue"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "value", "start", "stop", "size"
    functionNamesStrings.push "bang", "setValue", "setStart", "setStop", "setSize"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings
  
  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!"
    functionNamesStrings.push "bang"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  