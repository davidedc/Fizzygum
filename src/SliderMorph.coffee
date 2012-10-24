# SliderMorph ///////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class SliderMorph extends CircleBoxMorph

  target: null
  action: null
  start: null
  stop: null
  value: null
  size: null
  offset: null
  button: null

  constructor: (@start = 1, @stop = 100, @value = 50, @size = 10, orientation, color) ->
    @button = new SliderButtonMorph()
    @button.isDraggable = false
    @button.color = new Color(200, 200, 200)
    @button.highlightColor = new Color(210, 210, 255)
    @button.pressColor = new Color(180, 180, 255)
    super orientation # if null, then a vertical one will be created
    @add @button
    @alpha = 0.3
    @color = color or new Color(0, 0, 0)
    @setExtent new Point(20, 100)
    @step = null
  
  
  # this.drawNew();
  autoOrientation: ->
      nop()
  
  rangeSize: ->
    @stop - @start
  
  ratio: ->
    @size / @rangeSize()
  
  unitSize: ->
    return (@height() - @button.height()) / @rangeSize()  if @orientation is "vertical"
    (@width() - @button.width()) / @rangeSize()
  
  drawNew: ->
    super()
    @button.orientation = @orientation
    if @orientation is "vertical"
      bw = @width() - 2
      bh = Math.max(bw, Math.round(@height() * @ratio()))
      @button.silentSetExtent new Point(bw, bh)
      posX = 1
      posY = Math.min(
        Math.round((@value - @start) * @unitSize()),
        @height() - @button.height())
    else
      bh = @height() - 2
      bw = Math.max(bh, Math.round(@width() * @ratio()))
      @button.silentSetExtent new Point(bw, bh)
      posY = 1
      posX = Math.min(
        Math.round((@value - @start) * @unitSize()),
        @width() - @button.width())
    @button.setPosition new Point(posX, posY).add(@bounds.origin)
    @button.drawNew()
    @button.changed()
  
  updateValue: ->
    if @orientation is "vertical"
      relPos = @button.top() - @top()
    else
      relPos = @button.left() - @left()
    @value = Math.round(relPos / @unitSize() + @start)
    @updateTarget()
  
  updateTarget: ->
    if @action
      if typeof @action is "function"
        @action.call @target, @value
      else # assume it's a String
        @target[@action] @value
  
  
  # SliderMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.target = (dict[@target])  if c.target and dict[@target]
    c.button = (dict[@button])  if c.button and dict[@button]
    c
  
  
  # SliderMorph menu:
  developersMenu: ->
    menu = super()
    menu.addItem "show value...", "showValue", "display a dialog box\nshowing the selected number"
    menu.addItem "floor...", (->
      @prompt menu.title + "\nfloor:",
        @setStart,
        @,
        @start.toString(),
        null,
        0,
        @stop - @size,
        true
    ), "set the minimum value\nwhich can be selected"
    menu.addItem "ceiling...", (->
      @prompt menu.title + "\nceiling:",
        @setStop,
        @,
        @stop.toString(),
        null,
        @start + @size,
        @size * 100,
        true
    ), "set the maximum value\nwhich can be selected"
    menu.addItem "button size...", (->
      @prompt menu.title + "\nbutton size:",
        @setSize,
        @,
        @size.toString(),
        null,
        1,
        @stop - @start,
        true
    ), "set the range\ncovered by\nthe slider button"
    menu.addLine()
    menu.addItem "set target", "setTarget", "select another morph\nwhose numerical property\nwill be " + "controlled by this one"
    menu
  
  showValue: ->
    @inform @value
  
  userSetStart: (num) ->
    # for context menu demo purposes
    @start = Math.max(num, @stop)
  
  setStart: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @start = Math.min(Math.max(num, 0), @stop - @size)
    else
      newStart = parseFloat(num)
      @start = Math.min(Math.max(newStart, 0), @stop - @size)  unless isNaN(newStart)
    @value = Math.max(@value, @start)
    @updateTarget()
    @drawNew()
    @changed()
  
  setStop: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @stop = Math.max(num, @start + @size)
    else
      newStop = parseFloat(num)
      @stop = Math.max(newStop, @start + @size)  unless isNaN(newStop)
    @value = Math.min(@value, @stop)
    @updateTarget()
    @drawNew()
    @changed()
  
  setSize: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @size = Math.min(Math.max(num, 1), @stop - @start)
    else
      newSize = parseFloat(num)
      @size = Math.min(Math.max(newSize, 1), @stop - @start)  unless isNaN(newSize)
    @value = Math.min(@value, @stop - @size)
    @updateTarget()
    @drawNew()
    @changed()
  
  setTarget: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.push @world()
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), =>
        @target = each
        @setTargetSetter()
    #
    if choices.length is 1
      @target = choices[0]
      @setTargetSetter()
    else menu.popUpAtHand @world()  if choices.length > 0
  
  setTargetSetter: ->
    choices = @target.numericalSetters()
    menu = new MenuMorph(@, "choose target property:")
    choices.forEach (each) =>
      menu.addItem each, =>
        @action = each
    #
    if choices.length is 1
      @action = choices[0]
    else menu.popUpAtHand @world()  if choices.length > 0
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setStart", "setStop", "setSize"
    list
  
  
  # SliderMorph stepping:
  mouseDownLeft: (pos) ->
    unless @button.bounds.containsPoint(pos)
      @offset = new Point() # return null;
    else
      @offset = pos.subtract(@button.bounds.origin)
    world = @root()
    # this is to create the "drag the slider" effect
    # basically if the mouse is pressing within the boundaries
    # then in the next step you remember to check again where the mouse
    # is and update the scrollbar. As soon as the mouse is unpressed
    # then the step function is set to null to save cycles.
    @step = =>
      if world.hand.mouseButton
        mousePos = world.hand.bounds.origin
        if @orientation is "vertical"
          newX = @button.bounds.origin.x
          newY = Math.max(
            Math.min(mousePos.y - @offset.y,
            @bottom() - @button.height()), @top())
        else
          newY = @button.bounds.origin.y
          newX = Math.max(
            Math.min(mousePos.x - @offset.x,
            @right() - @button.width()), @left())
        @button.setPosition new Point(newX, newY)
        @updateValue()
      else
        @step = null
