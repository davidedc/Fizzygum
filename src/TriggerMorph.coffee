# TriggerMorph ////////////////////////////////////////////////////////

# I provide basic button functionality

class TriggerMorph extends Morph
  constructor: (target, action, labelString, fontSize, fontStyle, environment, hint, labelColor) ->
    # additional properties:
    @target = target or null
    @action = action or null
    @environment = environment or null
    @labelString = labelString or null
    @label = null
    @hint = hint or null
    @fontSize = fontSize or MorphicPreferences.menuFontSize
    @fontStyle = fontStyle or "sans-serif"
    @highlightColor = new Color(192, 192, 192)
    @pressColor = new Color(128, 128, 128)
    @labelColor = labelColor or new Color(0, 0, 0)
    #
    # initialize inherited properties:
    super()
    #
    # override inherited properites:
    @color = new Color(255, 255, 255)
    @drawNew()
  
  
  # TriggerMorph drawing:
  drawNew: ->
    @createBackgrounds()
    @createLabel()  if @labelString isnt null
  
  createBackgrounds: ->
    context = undefined
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
    @label = new StringMorph(@labelString, @fontSize, @fontStyle, false, false, false, null, null, @labelColor)
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
    #	for selections, Yes/No Choices etc:
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
        @target.call @environment, @action.call()
      else
        @target.call @environment, @action
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
    new SpeechBubbleMorph(localize(contents), null, null, 1).popUp @world(), @rightCenter().add(new Point(-8, 0))
