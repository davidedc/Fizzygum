# SimpleButtonMorph ////////////////////////////////////////////////////////

# sends a message to a target object when pressed.
# takes a rectangular shape, and can host
# a morph to be used as "face"

class SimpleButtonMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  target: null
  action: null
  dataSourceMorphForTarget: null
  morphEnv: null
 
 
  doubleClickAction: null
  argumentToAction1: null
  argumentToAction2: null
 
  hint: null
 
  # careful: Objects are shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color 192, 192, 192
  # see note above about Colors and shared objects
  pressColor: new Color 128, 128, 128
 
  closesUnpinnedMenus: true
  
  # tells if the button represents a morph, in which
  # case we are going to highlight the Morph on hover
  representsAMorph: false

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1
  STATE_PRESSED: 2

  # overrides to superclass
  color: new Color 255, 255, 255

  constructor: (
      @closesUnpinnedMenus = true,
      @target = null,
      @action = null,

      @faceMorph = null,

      @dataSourceMorphForTarget = null,
      @morphEnv,
      @hint = null,

      @doubleClickAction = null,
      @argumentToAction1 = null,
      @argumentToAction2 = null,
      @representsAMorph = false
      ) ->

    # additional properties:

    super()

    @appearance = new RectangularAppearance @

    #@color = new Color 255, 152, 152
    #@color = new Color 255, 255, 255
    if @faceMorph?
      @add @faceMorph
      @layoutSubmorphs()
  
  layoutSubmorphs: (morphStartingTheChange = null) ->
    super()
    if @faceMorph.parent == @
      @faceMorph.setBounds @bounds

  # TODO
  getTextDescription: ->

  

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

    if !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
      return null

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null

      color = switch @state
        when @STATE_NORMAL
          @color
        when @STATE_HIGHLIGHTED
          @highlightColor
        when @STATE_PRESSED
          @pressColor

      # paintRectangle is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio
      @paintRectangle \
        aContext,
        al, at, w, h,
        color,
        @alpha,
        true # push and pop the context

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio
      @paintHighlight aContext, al, at, w, h

  
  # TriggerMorph action:
  trigger: ->
    if @action
      if typeof @action is "function"
        console.log "trigger invoked with function"
        debugger
        @action.call @target, @dataSourceMorphForTarget
      else # assume it's a String
        #console.log "@target: " + @target + " @morphEnv: " + @morphEnv
        @target[@action].call @target, @dataSourceMorphForTarget, @morphEnv, @argumentToAction1, @argumentToAction2
    return

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
    world.hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: ->
    @state = @STATE_PRESSED
    @changed()
  
  mouseClickLeft: ->
    @bringToForegroud()
    @state = @STATE_HIGHLIGHTED
    @changed()
    if @closesUnpinnedMenus
      @propagateKillMenus()
    @trigger()
    @escalateEvent "mouseClickLeft"

  mouseDoubleClick: ->
    @triggerDoubleClick()

  # you shouldn't be able to floatDragging a compound
  # morphs containing a trigger by dragging the trigger
  # User might still move the trigger itself though
  # (if it's unlocked)
  rootForGrab: ->
    if @isFloatDraggable()
      return super()
    null
  
  # TriggerMorph bubble help:
  startCountdownForBubbleHelp: (contents) ->
    SpeechBubbleMorph.createInAWhileIfHandStillContainedInMorph @, contents
