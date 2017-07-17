# EmptyButtonMorph ////////////////////////////////////////////////////////

# sends a message to a target object when pressed.
# Doesn't have any particular shape, but can host
# a morph to be used as "face"

# REQUIRES HighlightableMixin

class EmptyButtonMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith HighlightableMixin, @name

  target: null
  action: null
  dataSourceMorphForTarget: null
  morphEnv: null
 
 
  doubleClickAction: null
  argumentToAction1: null
  argumentToAction2: null
 
  hint: null
 
  closesUnpinnedMenus: true
  
  # tells if the button represents a morph, in which
  # case we are going to highlight the Morph on hover
  representsAMorph: false


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

    
  # TriggerMorph action:
  trigger: ->
    if @action
      if typeof @action is "function"
        console.log "trigger invoked with function"
        alert "trigger invoked with function, this shouldn't happen"
        debugger
        @action.call @target, @dataSourceMorphForTarget
      else # assume it's a String
        if @action != ""
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

  
  mouseClickLeft: ->
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
