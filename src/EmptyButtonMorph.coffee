# EmptyButtonMorph ////////////////////////////////////////////////////////

# sends a message to a target object when pressed.
# Doesn't have any particular shape, but can host
# a morph to be used as "face"

# REQUIRES HighlightableMixin

class EmptyButtonMorph extends Morph

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
    @defaultRejectDrags = true

    #@color = new Color 255, 152, 152
    #@color = new Color 255, 255, 255
    if @faceMorph?
      @add @faceMorph
      @invalidateLayout()
  

  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    @rawSetBounds newBoundsForThisLayout

    if @faceMorph?.parent == @
      @faceMorph.rawSetBounds newBoundsForThisLayout

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

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

  # you shouldn't be able to drag a compound
  # morphs containing a button by dragging the button
  # (because you expect buttons attached to anything but the
  # world to be "slippery", i.e.
  # you can "skid" your drag over it in case you change
  # your mind on pressing it)
  # and you shouldn't be able to drag the button away either
  # so the drag is entirely rejected
  rejectDrags: ->
    if @parent instanceof WorldMorph
      return false
    else
      return @defaultRejectDrags


  
  # TriggerMorph bubble help:
  startCountdownForBubbleHelp: (contents) ->
    SpeechBubbleMorph.createInAWhileIfHandStillContainedInMorph @, contents
