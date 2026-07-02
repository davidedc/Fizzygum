# sends a message to a target object when pressed.
# Doesn't have any particular shape, but can host
# a widget to be used as "face"

# TODO it's unclear to me why we pass a number of targets
# and actions in the constructor when what we could simply
# do is to extend this button and override the mouse events?

class ButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name

  target: nil
  action: nil
  dataSourceWidgetForTarget: nil
  widgetEnv: nil
 
 
  doubleClickAction: nil
  argumentToAction1: nil
  argumentToAction2: nil
 
  toolTipMessage: nil
 
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  # tells if the button represents a widget, in which
  # case we are going to highlight the Widget on hover
  representsAWidget: false

  padding: 0


  # overrides to superclass
  color: Color.WHITE

  constructor: (
      @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true,
      @target = nil,
      @action = nil,

      @faceWidget = nil,

      @dataSourceWidgetForTarget = nil,
      @widgetEnv,
      @toolTipMessage = nil,

      @doubleClickAction = nil,
      @argumentToAction1 = nil,
      @argumentToAction2 = nil,
      @representsAWidget = false,
      @padding = 0
      ) ->

    # additional properties:

    super()
    @defaultRejectDrags = true

    #@color = Color.create 255, 152, 152
    #@color = Color.WHITE
    @_buildAndConnectChildren()

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # This REPLACES the old "defer the face's layout until attach" hack. The old fear -- "a settle in a
  # constructor leaks into ANY callback that builds a button (e.g. WindowWdgt._reactToChildDropped's chrome
  # rebuild via new *IconButtonWdgt, which must stay settle-neutral)" -- no longer bites: a button built
  # INSIDE such a callback runs in-flush, where the settle-tier's in-flush+orphan AUTO-DEFER
  # (Widget._settleLayoutsAfter: `return coreThunk() if @isOrphan()`) defers automatically. So no settle
  # leaks into the settle-neutral callback, while a top-level `new ButtonWdgt` settles its own orphan layout.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if @faceWidget?
      if (typeof @faceWidget) == "string"
        @faceWidget = (new StringWdgt @faceWidget, WorldWdgt.preferencesAndSettings.textInButtonsFontSize).alignCenter()
      @_addNoSettle @faceWidget
      @_invalidateLayout()
  

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # TODO shouldn't be calling this _applyBounds from here,
    # rather use super
    @_applyBounds newBoundsForThisLayout

    # TODO can we use the more standard way i.e.
    # calculate the bounds and pass them as args in the _reLayout method
    # of the faceWidget?

    if @faceWidget?.parent == @
      @faceWidget._applyBounds newBoundsForThisLayout.insetBy @padding

    super
    @markLayoutAsFixed()

  # TODO
  getTextDescription: ->

    
  # trigger button action:
  trigger: ->
    if @action? and @action != ""
      #console.log "@target: " + @target + " @widgetEnv: " + @widgetEnv
      @target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, @argumentToAction1, @argumentToAction2
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
  # widgets containing a button by dragging the button
  # (because you expect buttons attached to anything but the
  # world to be "slippery", i.e.
  # you can "skid" your drag over it in case you change
  # your mind on pressing it)
  # and you shouldn't be able to drag the button away either
  # so the drag is entirely rejected
  rejectDrags: ->
    if @parent == world
      return false
    else
      return @defaultRejectDrags

