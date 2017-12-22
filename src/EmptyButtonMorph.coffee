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

  target: nil
  action: nil
  dataSourceMorphForTarget: nil
  morphEnv: nil
 
 
  doubleClickAction: nil
  argumentToAction1: nil
  argumentToAction2: nil
 
  hint: nil
 
  closesUnpinnedMenus: true
  
  # tells if the button represents a morph, in which
  # case we are going to highlight the Morph on hover
  representsAMorph: false


  # overrides to superclass
  color: new Color 255, 255, 255

  constructor: (
      @closesUnpinnedMenus = true,
      @target = nil,
      @action = nil,

      @faceMorph = nil,

      @dataSourceMorphForTarget = nil,
      @morphEnv,
      @hint = nil,

      @doubleClickAction = nil,
      @argumentToAction1 = nil,
      @argumentToAction2 = nil,
      @representsAMorph = false
      ) ->

    # additional properties:

    super()

    #@color = new Color 255, 152, 152
    #@color = new Color 255, 255, 255
    if @faceMorph?
      @add @faceMorph
      @layoutSubmorphs()
  
  layoutSubmorphs: (morphStartingTheChange = nil) ->
    super()
    if @faceMorph.parent == @
      @faceMorph.setBounds @bounds

  # TODO
  getTextDescription: ->

    
  # TriggerMorph action:
  trigger: ->
    if @action? and @action != ""
      #console.log "@target: " + @target + " @morphEnv: " + @morphEnv
      @target[@action].call @target, @dataSourceMorphForTarget, @morphEnv, @argumentToAction1, @argumentToAction2
    return

  triggerDoubleClick: ->
    # same as trigger() but use doubleClickAction instead of action property
    # note that specifying a doubleClickAction is optional
    return  unless @doubleClickAction
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
    nil
  
  # TriggerMorph bubble help:
  startCountdownForBubbleHelp: (contents) ->
    SpeechBubbleMorph.createInAWhileIfHandStillContainedInMorph @, contents
