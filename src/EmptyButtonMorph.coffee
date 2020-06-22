# sends a message to a target object when pressed.
# Doesn't have any particular shape, but can host
# a morph to be used as "face"

# TODO it's unclear to me why we pass a number of targets
# and actions in the constructor when what we could simply
# do is to extend this button and override the mouse events?

class EmptyButtonMorph extends Widget

  @augmentWith HighlightableMixin, @name

  target: nil
  action: nil
  dataSourceMorphForTarget: nil
  morphEnv: nil
 
 
  doubleClickAction: nil
  argumentToAction1: nil
  argumentToAction2: nil
 
  toolTipMessage: nil
 
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  # tells if the button represents a morph, in which
  # case we are going to highlight the Widget on hover
  representsAMorph: false

  padding: 0


  # overrides to superclass
  color: Color.white

  constructor: (
      @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true,
      @target = nil,
      @action = nil,

      @faceMorph = nil,

      @dataSourceMorphForTarget = nil,
      @morphEnv,
      @toolTipMessage = nil,

      @doubleClickAction = nil,
      @argumentToAction1 = nil,
      @argumentToAction2 = nil,
      @representsAMorph = false,
      @padding = 0
      ) ->

    # additional properties:

    super()
    @defaultRejectDrags = true

    #@color = new Color 255, 152, 152
    #@color = Color.white
    if @faceMorph?

      if (typeof @faceMorph) == "string"
        @faceMorph = (new StringMorph2 @faceMorph, WorldMorph.preferencesAndSettings.textInButtonsFontSize).alignCenter()
      @add @faceMorph
      @invalidateLayout()
  

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts
    #  debugger

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
      @faceMorph.rawSetBounds newBoundsForThisLayout.insetBy @padding

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
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
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

