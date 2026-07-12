# A flat, label-bearing button: a filled rectangle drawn in the menu background
# colour normally, SILVER on hover, GRAY on press, with a single text label
# drawn on top. It extends the modern button family (ButtonWdgt), inheriting the
# target/action/trigger machinery and the HighlightableMixin state constants,
# but supplies its OWN flat paint -- the button family draws no flat fill
# (ButtonWdgt is transparent, SimpleButtonWdgt is a rounded box).
#
# This is the shared base of MenuItemWdgt (menu rows) and MagnetWdgt
# (fizzytiles word tiles).

class LabelButtonWdgt extends ButtonWdgt

  # label fields (the button family carries a faceWidget instead; a label button
  # draws its own @label)
  label: nil
  labelString: nil
  labelColor: nil
  labelBold: nil
  labelItalic: nil
  fontSize: nil
  fontStyle: nil

  # the flat state-fill look
  highlightColor: Color.SILVER
  pressColor: Color.GRAY
  centered: false

  constructor: (
      ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true,
      target = nil,
      action = nil,
      labelString = nil,
      fontSize = WorldWdgt.preferencesAndSettings.menuFontSize,
      fontStyle = "sans-serif",
      centered = false,
      environment = nil,
      widgetEnv,
      toolTipMessage = nil,
      color = WorldWdgt.preferencesAndSettings.menuButtonsLabelColor,
      bold = false,
      italic = false,
      doubleClickAction = nil,
      argumentToAction1 = nil,
      argumentToAction2 = nil,
      representsAWidget = false
      ) ->

    # ButtonWdgt owns the trigger machinery; map our label-button args onto its
    # constructor. We pass NO faceWidget (we draw our own @label), and our
    # "environment" arg is ButtonWdgt's dataSourceWidgetForTarget.
    super ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, nil, environment, widgetEnv, toolTipMessage, doubleClickAction, argumentToAction1, argumentToAction2, representsAWidget

    @labelString = labelString
    @fontSize = fontSize
    @fontStyle = fontStyle
    @centered = centered
    @labelColor = color
    @labelBold = bold
    @labelItalic = italic

    # the flat fill (ButtonWdgt defaults to white)
    @color = WorldWdgt.preferencesAndSettings.menuBackgroundColor

    if @labelString?
      @_reLayoutSelf()

  # the default label: a self-sized single-line StringWdgt that does NOT resize
  # the button's box. Subclasses that need the box to hug the label (e.g.
  # MenuItemWdgt) override this.
  _createLabel: ->
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
    # _addNoSettle (NOT add): _createLabel is driven by _reLayoutSelf (a layout pass), so a
    # self-settle here would re-enter the flush guard and throw.
    @_addNoSettle @label
    # the modern family does not self-size; make the label hug its text so
    # _reLayoutSelf's centring math (which reads @label.extent()) works. _createLabel is driven by
    # _reLayoutSelf (a layout pass), so use the NoSettle core -- the wrapper would throw mid-pass.
    @label._sizeToTextAndDisableFittingNoSettle()

  _reLayoutSelf: ->
    if not @label?
      @_createLabel()
    if @centered
      @label._applyMoveTo @center().subtract @label.extent().floorDivideBy 2

  # a label button has no faceWidget; use the base Widget layout rather than
  # ButtonWdgt's faceWidget-centric override. Then re-run _reLayoutSelf so a
  # CENTERED button keeps its label centred through ANY layout/resize: the base
  # pass applies the new bounds, then _reLayoutSelf re-centres the label against
  # them (a no-op when not centered). This is why a caller resizing a centered
  # label button no longer needs an explicit re-centre.
  _reLayout: (newBoundsForThisLayout) ->
    Widget::_reLayout.call @, newBoundsForThisLayout
    @_reLayoutSelf()

  # »>> this part is excluded from the fizzygum homepage build
  # THIN public wrapper over the non-settling core (canonical self-settling form): recreate the label, then
  # SELF-SETTLE (public tier, like setExtent/add) so the button's FULL re-layout -- _createLabel + centre, via
  # _reLayout -- runs synchronously and the world is consistent on return. This is the public label-setter
  # API; its one historical caller (FridgeMagnetsWdgt construction) now labels via the core directly, so the
  # wrapper has no in-tree caller and is intentionally dead-method-allowlisted (a runtime label change settles).
  setLabel: (labelString) ->
    @_settleLayoutsAfter => @_setLabelNoSettle labelString

  # NON-settling core -- the construction-time label path: a freshly-built button labels its ORPHAN member
  # before attach (FridgeMagnetsWdgt's magnets), reached from a low-level _NoSettle build. Tears down the old
  # label via the non-settling _fullDestroyNoSettle and SCHEDULES the re-layout (invalidate, not a bare settle);
  # the public wrapper -- or the enclosing construction settle -- does the one flush.
  _setLabelNoSettle: (@labelString) ->
    if @label?
      @label = @label._fullDestroyNoSettle()
    @_invalidateLayout()
  # this part is excluded from the fizzygum homepage build <<«

  alignCenter: ->
    if !@centered
      @centered = true
      @_reLayoutSelf()

  alignLeft: ->
    if @centered
      @centered = false
      @_reLayoutSelf()

  # This method only paints this very widget's "image"; it doesn't descend the
  # children recursively (that's fullPaintIntoAreaOrBlitFromBackBuffer's job).
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
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
  _reactToBeingCopied: ->
    # public-call-sanctioned: mouseLeave is the public pointer-event PROTOCOL verb (dispatched by
    # ActivePointerWdgt); reused to reset the copy's hover state — renaming it is not an option.
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
    # _updateColor, clobbering @color (our normal fill).
    @bringToForeground()
    @escalateEvent "mouseDownLeft", pos

  # HighlightableMixin would reset @state to NORMAL on mouse-up; a label button
  # must NOT (a selected list row keeps its STATE_PRESSED highlight). So
  # neutralise it.
  mouseUpLeft: ->

  mouseClickLeft: ->
    @bringToForeground()
    @state = @STATE_HIGHLIGHTED
    @changed()
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()
