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
  color: Color.WHITE

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

    #@color = Color.create 255, 152, 152
    #@color = Color.WHITE
    if @faceMorph?

      if (typeof @faceMorph) == "string"
        @faceMorph = (new StringMorph2 @faceMorph, WorldMorph.preferencesAndSettings.textInButtonsFontSize).alignCenter()
      @add @faceMorph
      @invalidateLayout()
  

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # TODO shouldn't be calling this rawSetBounds from here,
    # rather use super
    @rawSetBounds newBoundsForThisLayout

    # TODO can we use the more standard way i.e.
    # calculate the bounds and pass them as args in the doLayout method
    # of the faceMorph?

    if @faceMorph?.parent == @
      @faceMorph.rawSetBounds newBoundsForThisLayout.insetBy @padding

    super
    @markLayoutAsFixed()

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

  
  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()
    @escalateEvent "mouseClickLeft", arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

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

