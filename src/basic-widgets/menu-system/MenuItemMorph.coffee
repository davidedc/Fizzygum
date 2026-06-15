# I automatically determine my bounds

# MenuItemMorph is now part of the modern button family: it extends
# EmptyButtonMorph (which owns the trigger/target/action machinery and the
# HighlightableMixin state constants). The deprecated TriggerMorph it used to
# extend has been deleted; its menu-row look (a flat rectangle that fills the
# menu background normally, SILVER on hover, GRAY on press) does NOT exist in
# the button family (EmptyButtonMorph paints nothing, SimpleButtonMorph paints
# a rounded box), so that flat paint + its state handlers are kept here as
# overrides — menus look exactly as before.

class MenuItemMorph extends EmptyButtonMorph

  # label fields (the button family carries a faceMorph instead; a menu item
  # draws its own @label, sized to its text)
  label: nil
  labelString: nil
  labelColor: nil
  labelBold: nil
  labelItalic: nil
  fontSize: nil
  fontStyle: nil

  # the flat menu-row look (formerly TriggerMorph's)
  highlightColor: Color.SILVER
  pressColor: Color.GRAY
  centered: false

  # labelString can also be a Widget or a Canvas or a tuple: [icon, string]
  constructor: (
      ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true,
      target = nil,
      action = nil,
      labelString = nil,
      fontSize = WorldMorph.preferencesAndSettings.menuFontSize,
      fontStyle = "sans-serif",
      centered = false,
      environment = nil,
      morphEnv,
      toolTipMessage = nil,
      color = WorldMorph.preferencesAndSettings.menuButtonsLabelColor,
      bold = false,
      italic = false,
      doubleClickAction = nil,
      argumentToAction1 = nil,
      argumentToAction2 = nil,
      representsAMorph = false
      ) ->
    #console.log "menuitem constructing"

    # EmptyButtonMorph owns the trigger machinery; map our menu-item args onto
    # its constructor. We pass NO faceMorph (we draw our own @label), and our
    # "environment" arg is EmptyButtonMorph's dataSourceMorphForTarget.
    super ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, nil, environment, morphEnv, toolTipMessage, doubleClickAction, argumentToAction1, argumentToAction2, representsAMorph

    @labelString = labelString
    @fontSize = fontSize
    @fontStyle = fontStyle
    @centered = centered
    @labelColor = color
    @labelBold = bold
    @labelItalic = italic

    # the flat menu-row background (EmptyButtonMorph defaults to white)
    @color = WorldMorph.preferencesAndSettings.menuBackgroundColor

    @actionableAsThumbnail = true

    if @labelString?
      @reLayout()

  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of menu item)"
    if @labelString
      textWithoutLocationOrInstanceNo = @labelString.replace /#\d*/, ""
      return textWithoutLocationOrInstanceNo + " (text in button)"
    else
      return super()

  # in theory this would be the right thing to do
  # but a bunch of tests break and it's not worth it
  # as we are going to remake the whole layout system anyways
  #reLayout: ->
  #  @label.setExtent @extent().subtract (@label.bounds.origin.subtract @.bounds.origin)

  reLayout: ->
    if not @label?
      @createLabel()
    if @centered
      @label.fullRawMoveTo @center().subtract @label.extent().floorDivideBy 2

  # a menu item has no faceMorph; use the base Widget layout (the pre-rebase
  # inherited behaviour) rather than EmptyButtonMorph's faceMorph-centric one.
  doLayout: (newBoundsForThisLayout) ->
    Widget::doLayout.call @, newBoundsForThisLayout

  # »>> this part is excluded from the fizzygum homepage build
  setLabel: (@labelString) ->
    # just recreated the label
    # from scratch
    if @label?
      @label = @label.fullDestroy()
    @reLayout()
  # this part is excluded from the fizzygum homepage build <<«

  alignCenter: ->
    if !@centered
      @centered = true
      @reLayout()

  alignLeft: ->
    if @centered
      @centered = false
      @reLayout()

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
    return nil if w < 1 or h < 1 or area.isEmpty()

    if appliedShadow?
      color = Color.BLACK
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

  isTicked: ->
    @label.text.isTicked()

  toggleTick: ->
    if @label.text.isTicked()
      @label.text = @label.text.toggleTick()
      # reLayout is a base no-op on the modern TextWdgt, so it would leave the
      # ticked/unticked label at a stale width; re-measure and re-size instead.
      @label.sizeToTextAndDisableFitting()
      @label.changed()
    else if @label.text.isUnticked()
      @label.text = @label.text.toggleTick()
      @label.sizeToTextAndDisableFitting()
      @label.changed()


  createLabel: ->
    # console.log "menuitem createLabel"
    @label = new TextWdgt @labelString, @fontSize, @fontStyle
    @label.setColor @labelColor

    @add @label
    # the modern family does not self-size; make the label hug its text before
    # we read @label.extent() below to size this menu item around it.
    @label.sizeToTextAndDisableFitting()

    w = @width()
    @silentRawSetExtent @label.extent().add new Point 8, 0
    @silentRawSetWidth w
    np = @position().add new Point 4, 0
    @label.silentFullRawMoveTo np

  shrinkToTextSize: ->
    # '5' is to add some padding between
    # the text and the button edge
    @rawSetWidth @widthOfLabel() + 5

  widthOfLabel: ->
    @label.width()

  # a copied menu item usually wants to un-highlight itself. This happens for
  # example when you duplicate by clicking on a "duplicate" button INSIDE it.
  justBeenCopied: ->
    @mouseLeave()

  # MenuItemMorph events:
  mouseEnter: ->
    #console.log "@target: " + @target + " @morphEnv: " + @morphEnv

    # this could be a way to catch menu entries that should cause
    # an highlighting but don't
    #if @labelString.startsWith("a ") and !@representsAMorph
    #  debugger

    if @representsAMorph
      if @argumentToAction1?
        # this first case handles when you pick a morph
        # as a target
        morphToBeHighlighted = @argumentToAction1
      else
        # this second case handles when you attach to a morph
        morphToBeHighlighted = @target
      morphToBeHighlighted.turnOnHighlight()
    unless @isListItem()
      @state = @STATE_HIGHLIGHTED
      @changed()
    if @toolTipMessage
      @startCountdownForBubbleHelp @toolTipMessage

  mouseLeave: ->
    if @representsAMorph
      if @argumentToAction1?
        # this first case handles when you pick a morph
        # as a target
        morphToBeHighlighted = @argumentToAction1
      else
        # this second case handles when you attach to a morph
        morphToBeHighlighted = @target
      morphToBeHighlighted.turnOffHighlight()
    unless @isListItem()
      @state = @STATE_NORMAL
      @changed()
    world.destroyToolTips()  if @toolTipMessage

  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    @state = @STATE_PRESSED
    @changed()
    # replicate Widget.mouseDownLeft inline (bringToForeground + escalate)
    # rather than calling super: EmptyButtonMorph's HighlightableMixin
    # mouseDownLeft would run updateColor (clobbering @color, our normal fill).
    @bringToForeground()
    @escalateEvent "mouseDownLeft", pos

  # HighlightableMixin (via EmptyButtonMorph) would reset @state to NORMAL on
  # mouse-up; a menu item must NOT do that — a selected list row keeps its
  # STATE_PRESSED highlight (see isSelectedListItem), and TriggerMorph (our old
  # base) had no mouseUpLeft handler. So neutralise it.
  mouseUpLeft: ->

  mouseClickLeft: ->
    @bringToForeground()
    @state = @STATE_HIGHLIGHTED
    @changed()
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()

  isListItem: ->
    return @parent.isListContents  if @parent
    false

  # »>> this part is excluded from the fizzygum homepage build
  isSelectedListItem: ->
    return @state is @STATE_PRESSED if @isListItem()
    false
  # this part is excluded from the fizzygum homepage build <<«
