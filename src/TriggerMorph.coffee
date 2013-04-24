# TriggerMorph ////////////////////////////////////////////////////////

# I provide basic button functionality

class TriggerMorph extends Morph

  target: null
  action: null
  environment: null
  label: null
  labelString: null
  labelColor: null
  labelBold: null
  labelItalic: null
  hint: null
  fontSize: null
  fontStyle: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(192, 192, 192)
  highlightImage: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(128, 128, 128)
  normalImage: null
  pressImage: null

  constructor: (
      @target = null,
      @action = null,
      @labelString = null,
      fontSize,
      fontStyle,
      @environment = null,
      @hint = null,
      labelColor,
      @labelBold = false,
      @labelItalic = false) ->
    
    # additional properties:
    @fontSize = fontSize or WorldMorph.MorphicPreferences.menuFontSize
    @fontStyle = fontStyle or "sans-serif"
    @labelColor = labelColor or new Color(0, 0, 0)
    #
    super()
    #
    @color = new Color(255, 255, 255)
    @updateRendering()
  
  
  # TriggerMorph drawing:
  updateRendering: ->
    @createBackgrounds()
    @createLabel()  if @labelString isnt null
  
  createBackgrounds: ->
    ext = @extent()
    @normalImage = newCanvas(ext)
    context = @normalImage.getContext("2d")
    context.fillStyle = @color.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @highlightImage = newCanvas(ext)
    context = @highlightImage.getContext("2d")
    context.fillStyle = @highlightColor.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @pressImage = newCanvas(ext)
    context = @pressImage.getContext("2d")
    context.fillStyle = @pressColor.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @image = @normalImage
  
  createLabel: ->
    @label.destroy()  if @label isnt null
    # bold
    # italic
    # numeric
    # shadow offset
    # shadow color
    @label = new StringMorph(
      @labelString,
      @fontSize,
      @fontStyle,
      false,
      false,
      false,
      null,
      null,
      @labelColor,
      @labelBold,
      @labelItalic
    )
    @label.setPosition @center().subtract(@label.extent().floorDivideBy(2))
    @add @label
  
  
  # TriggerMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.label = (dict[@label])  if c.label and dict[@label]
    c
  
  
  # TriggerMorph action:
  trigger: ->
    #
    #	if target is a function, use it as callback:
    #	execute target as callback function with action as argument
    #	in the environment as optionally specified.
    #	Note: if action is also a function, instead of becoming
    #	the argument itself it will be called to answer the argument.
    #	for selections, Yes/No Choices etc. As second argument pass
    # myself, so I can be modified to reflect status changes, e.g.
    # inside a list box:
    #
    #	else (if target is not a function):
    #
    #		if action is a function:
    #		execute the action with target as environment (can be null)
    #		for lambdafied (inline) actions
    #
    #		else if action is a String:
    #		treat it as function property of target and execute it
    #		for selector-like actions
    #	
    if typeof @target is "function"
      if typeof @action is "function"
        @target.call @environment, @action.call(), @
      else
        @target.call @environment, @action, @
    else
      if typeof @action is "function"
        @action.call @target
      else # assume it's a String
        @target[@action]()
  
  
  # TriggerMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
    @bubbleHelp @hint  if @hint
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
    @world().hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: ->
    @image = @pressImage
    @changed()
  
  mouseClickLeft: ->
    @image = @highlightImage
    @changed()
    @trigger()
  
  
  # TriggerMorph bubble help:
  bubbleHelp: (contents) ->
    @fps = 2
    @step = =>
      @popUpbubbleHelp contents  if @bounds.containsPoint(@world().hand.position())
      @fps = 0
      delete @step
  
  popUpbubbleHelp: (contents) ->
    new SpeechBubbleMorph(
      localize(contents), null, null, 1).popUp @world(),
      @rightCenter().add(new Point(-8, 0))
