# TriggerMorph ////////////////////////////////////////////////////////

# I provide basic button functionality.
# All menu items and buttons are TriggerMorphs.
# The handling of the triggering is not
# trivial, as the concepts of
# environment, target and action
# are used - see comments.

class TriggerMorph extends Morph

  target: null
  action: null
  environment: null
  label: null
  labelString: null
  labelColor: null
  labelBold: null
  labelItalic: null
  doubleClickAction: null
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
      @labelItalic = false
      @doubleClickAction = null) ->

    # additional properties:
    @fontSize = fontSize or WorldMorph.preferencesAndSettings.menuFontSize
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
  
  
  
  # TriggerMorph action:
  trigger: ->

    # Here is the pseudocode for the
    # four cases. The four cases are
    # further explained later
    # with example.
    #
    #	If target is a function:
    #   use it as callback, i.e.
    #	  execute target as callback function passing the action as argument
    #	  (in the environment as optionally specified) (see case 1 below).
    #
    #	  If the action is a function too, then it's evaluated, so the
    #   callback is passed the result returned from the action.
    #   (see case 2 below)
    #
    #	  As second argument pass
    #   myself, so I can be modified to reflect status changes, e.g.
    #   inside a list box
    #
    #	else if (target is not a function):
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
        # case 1
        # console.log "action invokation case 1"
        # Example: color morph "Ok" and "Cancel" buttons
        # I.e.:
        #    menu.addItem "color...", (->
        #        @pickColor menu.title + "\ncolor:", @setColor, @, @color
        #      ), "choose another color \nfor this morph"
        #    [...]
        #    addItem: (labelString,action,hint,color,bold = false,italic = false, doubleClickAction)...
        #    [...]
        #    @pickColor menu.title + "\ncolor:", @setColor, @, @color
        #    [...]
        #    menu.addItem "Ok", ->
        #      colorPicker.getChoice()
        #    [...]
        #    pickColor: (msg, callback, environment, defaultContents) ->
        #       menu = new MenuMorph(callback or null, msg or "", environment or null)
        #    [...]
        #     MenuMorph constructor: (@target, @title = null, @environment = null, @fontSize = null) ...
        # i.e. a menu is created where the target is the
        # callback function "setColor"
        # which means that "Ok" invokes the callback (setColor) with the
        # result of getChoice (which just returns the selected color).
        @target.call @environment, @action.call(), @
      else
        # case 2
        # console.log "action invokation case 2"
        # case of selecting any entry from the
        # inspector menu pane on the left
        # that pane is a ListMorph, which builds a MenuMorph
        # like so:
        #   @list = new ListMorph((if @ ...
        #   [...]
        #   @list.action = (selected) => ...shows the content in the pane etc.
        #   [...] in the ListMorph:
        #   @listContents = new MenuMorph(@select, null, @)
        #   [...]
        #   @listContents.addItem @labelGetter(element), element, null, color, bold, italic, @doubleClickAction
        # so here the  target is "@select" and the action is "element"
        @target.call @environment, @action, @
    else
      if typeof @action is "function"
        # case 3
        # console.log "action invokation case 3"
        # case of all the menu entries from
        # the world menu
        # i.e.
        #   menu = new MenuMorph(@, "Morphic")
        #   [...]
        #   menu.addItem "hide all...", (->@minimiseAll())
        # as you see the target is not a function (@)
        # but the action is "(->@minimiseAll())"
        @action.call @target
      else # assume it's a String
        # case 4
        # console.log "action invokation case 4"
        # when instead of writing this (case 3):
        #    menu.addItem "demo...", (->@userCreateMorph()), "sample morphs"
        # you write:
        #    menu.addItem "demo...", "userCreateMorph", "sample morphs"
        # so it's like above but the action is a strind instead of
        # a function. Note that this version sould be used sparingly
        # because it's semantically less correct to identify a
        # function as a string.
        @target[@action]()

  triggerDoubleClick: ->
    # same as trigger() but use doubleClickAction instead of action property
    # note that specifying a doubleClickAction is optional
    return  unless @doubleClickAction
    if typeof @target is "function"
      if typeof @doubleClickAction is "function"
        @target.call @environment, @doubleClickAction.call(), this
      else
        @target.call @environment, @doubleClickAction, this
    else
      if typeof @doubleClickAction is "function"
        @doubleClickAction.call @target
      else # assume it's a String
        @target[@doubleClickAction]()  
  
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

  mouseDoubleClick: ->
    @triggerDoubleClick()

  # Disable dragging compound Morphs by Triggers
  # User can still move the trigger itself though
  # (it it's unlocked)
  rootForGrab: ->
    if @isDraggable
      return super()
    null
  
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
