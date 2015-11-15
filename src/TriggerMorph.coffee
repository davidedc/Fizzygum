# TriggerMorph ////////////////////////////////////////////////////////

# I provide basic button functionality.
# All menu items and buttons are TriggerMorphs.
# The handling of the triggering is not
# trivial, as the concepts of
# dataSourceMorphForTarget, target and action
# are used - see comments.

class TriggerMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  target: null
  action: null
  dataSourceMorphForTarget: null
  morphEnv: null
  label: null
  labelString: null
  labelColor: null
  labelBold: null
  labelItalic: null
  doubleClickAction: null
  argumentToAction1: null
  argumentToAction2: null
  hint: null
  fontSize: null
  fontStyle: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(192, 192, 192)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(128, 128, 128)
  centered: false
  closesUnpinnedMenus: true

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1
  STATE_PRESSED: 2

  constructor: (
      @closesUnpinnedMenus = true,
      @target = null,
      @action = null,
      @labelString = null,
      fontSize,
      fontStyle,
      @centered = false,
      @dataSourceMorphForTarget = null,
      @morphEnv,
      @hint = null,
      labelColor,
      @labelBold = false,
      @labelItalic = false,
      @doubleClickAction = null,
      @argumentToAction1 = null,
      @argumentToAction2 = null
      ) ->

    # additional properties:
    @fontSize = fontSize or WorldMorph.preferencesAndSettings.menuFontSize
    @fontStyle = fontStyle or "sans-serif"
    @labelColor = labelColor or new Color(0, 0, 0)

    super()

    #@color = new Color(255, 152, 152)
    @color = new Color(255, 255, 255)
    if @labelString?
      @layoutSubmorphs()
  
  layoutSubmorphs: (morphStartingTheChange = null) ->
    super()
    if not @label?
      @createLabel()
    if @centered
      @label.setPosition @center().subtract(@label.extent().floorDivideBy(2))

  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of button)"
    if @labelString
      textWithoutLocationOrInstanceNo = @labelString.replace(/\[\d*@\d*[ ]*\|[ ]*\d*@\d*\]/,"")
      textWithoutLocationOrInstanceNo = textWithoutLocationOrInstanceNo.replace(/#\d*/,"")
      return textWithoutLocationOrInstanceNo + " (text in button)"
    else
      return super()


  setLabel: (@labelString) ->
    # just recreated the label
    # from scratch
    if @label?
      @label = @label.destroy()
    @layoutSubmorphs()

  alignCenter: ->
    if !@centered
      @centered = true
      @layoutSubmorphs()

  alignLeft: ->
    if @centered
      @centered = false
      @layoutSubmorphs()
  

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by recursivelyPaintIntoAreaOrBlAtFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->
    return null  if @isMinimised or !@isVisible
    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      return null  if w < 1 or h < 1
      aContext.globalAlpha = @alpha

      aContext.save()
      if !@color?
        debugger

      if @state == @STATE_NORMAL
        aContext.fillStyle = @color.toString()
      if @state == @STATE_HIGHLIGHTED
        aContext.fillStyle = @highlightColor.toString()
      if @state == @STATE_PRESSED
        aContext.fillStyle = @pressColor.toString()

      aContext.fillRect  Math.round(al),
          Math.round(at),
          Math.round(w),
          Math.round(h)
      aContext.restore()

      if world.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)

        aContext.save()
        aContext.globalAlpha = 0.5
        aContext.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        aContext.fillRect  Math.round(al),
            Math.round(at),
            Math.round(w),
            Math.round(h)
        aContext.restore()


  createLabel: ->
    # bold
    # italic
    # numeric
    # shadow offset
    # shadow color
    @label = new StringMorph(
      @labelString or "",
      @fontSize,
      @fontStyle,
      @labelBold,
      @labelItalic,
      false,
      @labelColor      
    )
    @add @label
    
  
  # TriggerMorph action:
  trigger: ->
    if @action
      if typeof @action is "function"
        console.log "trigger invoked with function"
        debugger
        @action.call @target, @dataSourceMorphForTarget
      else # assume it's a String
        @target[@action].call @target, @dataSourceMorphForTarget, @morphEnv, @argumentToAction1, @argumentToAction2

  triggerDoubleClick: ->
    # same as trigger() but use doubleClickAction instead of action property
    # note that specifying a doubleClickAction is optional
    return  unless @doubleClickAction
    if typeof @target is "function"
      if typeof @doubleClickAction is "function"
        @target.call @dataSourceMorphForTarget, @doubleClickAction.call(), this
      else
        @target.call @dataSourceMorphForTarget, @doubleClickAction, this
    else
      if typeof @doubleClickAction is "function"
        @doubleClickAction.call @target
      else # assume it's a String
        @target[@doubleClickAction]()  
  
  # TriggerMorph events:
  mouseEnter: ->
    @state = @STATE_HIGHLIGHTED
    @changed()
    @startCountdownForBubbleHelp @hint  if @hint
  
  mouseLeave: ->
    @state = @STATE_NORMAL
    @changed()
    @world().hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: ->
    @state = @STATE_PRESSED
    @changed()
  
  mouseClickLeft: ->
    super()
    @state = @STATE_HIGHLIGHTED
    @changed()
    if @closesUnpinnedMenus
      @propagateKillMenus()
    @trigger()

  mouseDoubleClick: ->
    @triggerDoubleClick()

  # you shouldn't be able to floatDragging a compound
  # morphs containing a trigger by dragging the trigger
  # User might still move the trigger itself though
  # (if it's unlocked)
  rootForGrab: ->
    if @isfloatDraggable
      return super()
    null
  
  # TriggerMorph bubble help:
  startCountdownForBubbleHelp: (contents) ->
    SpeechBubbleMorph.createInAWhileIfHandStillContainedInMorph @, contents
