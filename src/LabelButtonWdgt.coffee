# A flat, label-bearing button: a filled rectangle drawn in the menu background
# colour normally, SILVER on hover, GRAY on press, with a single text label
# drawn on top. It extends the modern button family (ButtonWdgt), inheriting the
# target/action/trigger machinery and the HighlightableMixin state constants,
# but supplies its OWN flat paint -- the button family draws no flat fill
# (ButtonWdgt is transparent, SimpleButtonWdgt is a rounded box).
#
# This is the shared base of MenuItemMorph (menu rows) and MagnetWdgt
# (fizzytiles word tiles) -- the role the deprecated TriggerMorph used to fill,
# now on the modern button family.

class LabelButtonWdgt extends ButtonWdgt

  # label fields (the button family carries a faceMorph instead; a label button
  # draws its own @label)
  label: nil
  labelString: nil
  labelColor: nil
  labelBold: nil
  labelItalic: nil
  fontSize: nil
  fontStyle: nil

  # the flat state-fill look (formerly TriggerMorph's)
  highlightColor: Color.SILVER
  pressColor: Color.GRAY
  centered: false

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

    # ButtonWdgt owns the trigger machinery; map our label-button args onto its
    # constructor. We pass NO faceMorph (we draw our own @label), and our
    # "environment" arg is ButtonWdgt's dataSourceMorphForTarget.
    super ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, nil, environment, morphEnv, toolTipMessage, doubleClickAction, argumentToAction1, argumentToAction2, representsAMorph

    @labelString = labelString
    @fontSize = fontSize
    @fontStyle = fontStyle
    @centered = centered
    @labelColor = color
    @labelBold = bold
    @labelItalic = italic

    # the flat fill (ButtonWdgt defaults to white)
    @color = WorldMorph.preferencesAndSettings.menuBackgroundColor

    if @labelString?
      @reLayout()

  # the default label: a self-sized single-line StringWdgt that does NOT resize
  # the button's box. Subclasses that need the box to hug the label (e.g.
  # MenuItemMorph) override this.
  createLabel: ->
    @label = new StringWdgt(
      @labelString or "",
      @fontSize,
      @fontStyle,
      @labelBold,
      @labelItalic,
      false, # isHeaderLine
      false, # isNumeric
      @labelColor
    )
    @add @label
    # the modern family does not self-size; make the label hug its text so
    # reLayout's centring math (which reads @label.extent()) works.
    @label.sizeToTextAndDisableFitting()

  reLayout: ->
    if not @label?
      @createLabel()
    if @centered
      @label.fullRawMoveTo @center().subtract @label.extent().floorDivideBy 2

  # a label button has no faceMorph; use the base Widget layout rather than
  # ButtonWdgt's faceMorph-centric override.
  doLayout: (newBoundsForThisLayout) ->
    Widget::doLayout.call @, newBoundsForThisLayout

  # »>> this part is excluded from the fizzygum homepage build
  setLabel: (@labelString) ->
    # just recreate the label from scratch
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

  # This method only paints this very morph's "image"; it doesn't descend the
  # children recursively (that's fullPaintIntoAreaOrBlitFromBackBuffer's job).
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

    # paintRectangle works in actual (not logical) pixels, outside the
    # ceilPixelRatio scaling.
    @paintRectangle \
      aContext,
      al, at, w, h,
      color,
      @alpha,
      true, # push and pop the context
      appliedShadow

    @paintHighlight aContext, al, at, w, h

  # a copied label button usually wants to un-highlight itself (e.g. when you
  # duplicate by clicking a "duplicate" button INSIDE it).
  justBeenCopied: ->
    @mouseLeave()

  mouseEnter: ->
    @state = @STATE_HIGHLIGHTED
    @changed()
    @startCountdownForBubbleHelp @toolTipMessage  if @toolTipMessage

  mouseLeave: ->
    @state = @STATE_NORMAL
    @changed()
    world.destroyToolTips()  if @toolTipMessage

  mouseDownLeft: (pos) ->
    @state = @STATE_PRESSED
    @changed()
    # replicate Widget.mouseDownLeft inline (bringToForeground + escalate) rather
    # than calling super: ButtonWdgt's HighlightableMixin mouseDownLeft would run
    # updateColor, clobbering @color (our normal fill).
    @bringToForeground()
    @escalateEvent "mouseDownLeft", pos

  # HighlightableMixin would reset @state to NORMAL on mouse-up; a label button
  # must NOT (a selected list row keeps its STATE_PRESSED highlight, and
  # TriggerMorph -- our old base -- had no mouseUpLeft). So neutralise it.
  mouseUpLeft: ->

  mouseClickLeft: ->
    @bringToForeground()
    @state = @STATE_HIGHLIGHTED
    @changed()
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()
