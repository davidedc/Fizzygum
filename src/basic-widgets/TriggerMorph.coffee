# **************************************
# This Widget is now deprecated, use the
# SimpleButton instead
# **************************************

# I provide basic button functionality.
# All menu items and buttons are TriggerMorphs.
# The handling of the triggering is not
# trivial, as the concepts of
# dataSourceMorphForTarget, target and action
# are used - see comments.

class TriggerMorph extends Widget

  target: nil
  action: nil
  dataSourceMorphForTarget: nil
  morphEnv: nil
  label: nil
  labelString: nil
  labelColor: nil
  labelBold: nil
  labelItalic: nil
  doubleClickAction: nil
  argumentToAction1: nil
  argumentToAction2: nil
  toolTipMessage: nil
  fontSize: nil
  fontStyle: nil
  # careful: Objects are shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color 192, 192, 192
  # see note above about Colors and shared objects
  pressColor: new Color 128, 128, 128
  centered: false
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  # tells if the button represents a morph, in which
  # case we are going to highlight the Widget on hover
  representsAMorph: false

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1
  STATE_PRESSED: 2


  constructor: (
      @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true,
      @target = nil,
      @action = nil,
      @labelString = nil,
      @fontSize = WorldMorph.preferencesAndSettings.menuFontSize,
      @fontStyle = "sans-serif",
      @centered = false,
      @dataSourceMorphForTarget = nil,
      @morphEnv,
      @toolTipMessage = nil,
      @labelColor = WorldMorph.preferencesAndSettings.menuButtonsLabelColor,
      @labelBold = false,
      @labelItalic = false,
      @doubleClickAction = nil,
      @argumentToAction1 = nil,
      @argumentToAction2 = nil,
      @representsAMorph = false
      ) ->

    # additional properties:

    super()

    # you shouldn't be able to drag a compound
    # morphs containing a trigger by dragging the trigger
    # (because you expect buttons attached to anything but the
    # world to be "slippery", i.e.
    # you can "skid" your drag over it in case you change
    # your mind on pressing it)
    # and at the same time (again if it's not on the desktop)
    # you don't want it to be "floating"
    # either
    @defaultRejectDrags = true

    @color = WorldMorph.preferencesAndSettings.menuBackgroundColor
    if @labelString?
      @layoutSubmorphs()
  
  layoutSubmorphs: (morphStartingTheChange = nil) ->
    super()
    if not @label?
      @createLabel()
    if @centered
      @label.fullRawMoveTo @center().subtract @label.extent().floorDivideBy 2

  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of button)"
    if @labelString
      textWithoutLocationOrInstanceNo = @labelString.replace /#\d*/, ""
      return textWithoutLocationOrInstanceNo + " (text in button)"
    else
      return super()


  setLabel: (@labelString) ->
    # just recreated the label
    # from scratch
    if @label?
      @label = @label.fullDestroy()
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
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
      return nil

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil

      if appliedShadow?
        color = "black"
      else
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
      # of the ceilPixelRatio
      @paintRectangle \
        aContext,
        al, at, w, h,
        color,
        @alpha,
        true, # push and pop the context
        appliedShadow

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the ceilPixelRatio
      @paintHighlight aContext, al, at, w, h

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
  
  # TriggerMorph action:
  trigger: ->
    if @action and @action != ""
      #console.log "@target: " + @target + " @morphEnv: " + @morphEnv
      @target[@action].call @target, @dataSourceMorphForTarget, @morphEnv, @argumentToAction1, @argumentToAction2
    return

  triggerDoubleClick: ->
    # same as trigger() but use doubleClickAction instead of action property
    # note that specifying a doubleClickAction is optional
    return  unless @doubleClickAction
    @target[@doubleClickAction]()  
  
  # TriggerMorph events:
  mouseEnter: ->
    @state = @STATE_HIGHLIGHTED
    @changed()
    @startCountdownForBubbleHelp @toolTipMessage  if @toolTipMessage
  
  # a copied trigger usually wants to un-highlight
  # itself. This happens for example when you duplicate
  # by clicking on a "duplicate" button INSIDE it.
  justBeenCopied: ->
    @mouseLeave()

  mouseLeave: ->
    @state = @STATE_NORMAL
    @changed()
    world.hand.destroyToolTips()  if @toolTipMessage
  
  mouseDownLeft: ->
    @state = @STATE_PRESSED
    @changed()
    super
  
  mouseClickLeft: ->
    @bringToForeground()
    @state = @STATE_HIGHLIGHTED
    @changed()
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()

  mouseDoubleClick: ->
    @triggerDoubleClick()

