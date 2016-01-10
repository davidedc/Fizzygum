# SliderMorph ///////////////////////////////////////////////////
# Sliders (and hence slider button morphs)
# are also used in the ScrollMorphs .

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions
# REQUIRES ControllerMixin

class SliderMorph extends CircleBoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith ControllerMixin

  target: null
  action: null
  start: null
  stop: null
  value: null
  size: null
  offset: null
  button: null
  argumentToAction: null

  constructor: (
    @start = 1,
    @stop = 100,
    @value = 50,
    @size = 10,
    orientation,
    @color = (new Color 0, 0, 0)
    ) ->
    @button = new SliderButtonMorph()
    super orientation # if null, then a vertical one will be created
    @alpha = 0.1
    @silentRawSetExtent new Point 20, 100
    @silentAdd @button

  imBeingAddedTo: (newParentMorph) ->
    @reLayout()
    
    # might happen in phase of deserialization that
    # the button reference here is still a string
    # so skip in that case
    if @button? and @button instanceof SliderButtonMorph
      @button.reLayout()
      
    @changed()

  rawSetExtent: (a) -> 
    #console.log "move 17"
    @breakNumberOfRawMovesAndResizesCaches()  
    super a
    # my backing store had just been updated
    # in the call of super, now
    # it's the time of the button
    @button.reLayout()
    

  toggleOrientation: ->
    super()
    # the background CircleBoxMorph has just been updated
    # in the call of super, now
    # it's the time of the button
    @button.reLayout()
    
  
  autoOrientation: ->
      noOperation
  
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
    if @orientation is "vertical"
      return (@height() - @button.height()) / @rangeSize()
    else
      return (@width() - @button.width()) / @rangeSize()
    
  updateValue: ->
    if @orientation is "vertical"
      relPos = @button.top() - @top()
    else
      relPos = @button.left() - @left()
    newvalue = Math.round relPos / @unitSize() + @start
    if @value != newvalue
      @value = newvalue
      @updateTarget()
  
  updateTarget: ->
    if @action
      if typeof @action is "function"
        console.log "scrollbar invoked with function"
        debugger
        @action.call @target, @value, @target
      else # assume it's a String
        @target[@action].call @target, @value, @argumentToAction
    
  
  # SliderMorph menu:
  developersMenu: ->
    menu = super()
    menu.addItem "show value", true, @, "showValue", "display a dialog box\nshowing the selected number"
    menu.addItem "floor...", true, @, (->
      @prompt menu.title + "\nfloor:",
        @setStart,
        @start.toString(),
        null,
        0,
        @stop - @size,
        true
    ), "set the minimum value\nwhich can be selected"
    menu.addItem "ceiling...", true, @, (->
      @prompt menu.title + "\nceiling:",
        @setStop,
        @stop.toString(),
        null,
        @start + @size,
        @size * 100,
        true
    ), "set the maximum value\nwhich can be selected"
    menu.addItem "button size...", true, @, (->
      @prompt menu.title + "\nbutton size:",
        @setSize,
        @size.toString(),
        null,
        1,
        @stop - @start,
        true
    ), "set the range\ncovered by\nthe slider button"
    menu.addLine()
    menu.addItem "set target", true, @, "setTarget", "select another morph\nwhose numerical property\nwill be " + "controlled by this one"
    menu
  
  showValue: ->
    @inform @value
  
  userSetStart: (num) ->
    # for context menu demo purposes
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

    # for context menu demo purposes
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

    # for context menu demo purposes
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
  
  setSize: (sizeOrMorphGivingSize) ->
    if sizeOrMorphGivingSize.getValue?
      size = sizeOrMorphGivingSize.getValue()
    else
      size = sizeOrMorphGivingSize

    # for context menu demo purposes
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
  
  # setTarget: -> taken form the ControllerMixin

  swapTargetsTHISNAMEISRANDOM: (ignored, ignored2, theTarget, each) ->
    @target = theTarget
    @action = each
  
  setTargetSetter: (ignored, ignored2, theTarget) ->
    choices = theTarget.numericalSetters()
    menu = new MenuMorph false, @, true, true, "choose target property:"
    choices.forEach (each) =>
      menu.addItem each, true, @, "swapTargetsTHISNAMEISRANDOM", null, null, null, null, null,theTarget, each
    if choices.length == 0
      menu = new MenuMorph false, @, true, true, "no target properties available"
    menu.popUpAtHand @firstContainerMenu()

  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setStart", "setStop", "setSize"
    list
  
  