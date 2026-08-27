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
  label: undefined
  labelString: undefined
  labelColor: undefined
  labelBold: undefined
  labelItalic: undefined
  fontSize: undefined
  fontStyle: undefined

  # the flat state-fill look
  highlightColor: Color.SILVER
  pressColor: Color.GRAY
  centered: false

  # Same head as ButtonWdgt — target/action — and the same opts object, extended with the
  # label knobs this class adds. It forwards `opts` untouched rather than transcribing it,
  # which is what makes the two vocabularies ONE vocabulary: an option added to ButtonWdgt is
  # available here with no edit.
  #
  # It passes no `face`: a label button draws its own @label. An absent `face` and an
  # explicitly-undefined one are the same thing to ButtonWdgt, so there is nothing to say.
  #
  # ⚠ ONE field, ONE name: ButtonWdgt's `subjectOfAction` rides the `subject` option here too.
  # A second alias for it is exactly what an options vocabulary cannot afford (R4), because a
  # forwarded bag would then carry a key the receiver never reads.
  constructor: (target, action, opts = {}) ->
    super target, action, opts

    @labelString = opts.labelString
    @fontSize = opts.fontSize ? WorldWdgt.preferencesAndSettings.menuFontSize
    @fontStyle = opts.fontStyle ? "sans-serif"
    @centered = opts.centered ? false
    @labelColor = opts.color ? WorldWdgt.preferencesAndSettings.menuButtonsLabelColor
    @labelBold = opts.bold ? false
    @labelItalic = opts.italic ? false

    # the flat fill (ButtonWdgt defaults to white)
    @color = WorldWdgt.preferencesAndSettings.menuBackgroundColor
    @appearance = new LabelButtonAppearance @

    if @labelString?
      @_reLayoutSelf()

  # the default label: a self-sized single-line StringWdgt that does NOT resize
  # the button's box. Subclasses that need the box to hug the label (e.g.
  # MenuItemWdgt) override this.
  _createLabel: ->
    @label = new StringWdgt (@labelString or ""),
      fontSize: @fontSize
      fontName: @fontStyle
      bold: @labelBold
      italic: @labelItalic
      color: @labelColor
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
      # Integer placement (Layer A): @center() is fractional when my extent is odd, so round the centred
      # label position to commit an integer @bounds. docs/archive/fractional-widget-bounds-investigation-plan.md (Path 2).
      @label._applyMoveTo (@center().subtract @label.extent().floorDivideBy 2).round()

  # a label button has no faceWidget; use the base Widget layout rather than
  # ButtonWdgt's faceWidget-centric override. Then re-run _reLayoutSelf so a
  # CENTERED button keeps its label centred through ANY layout/resize: the base
  # pass applies the new bounds, then _reLayoutSelf re-centres the label against
  # them (a no-op when not centered). This is why a caller resizing a centered
  # label button no longer needs an explicit re-centre.
  _reLayout: (newBoundsForThisLayout) ->
    Widget::_reLayout.call @, newBoundsForThisLayout
    @_reLayoutSelf()

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

  alignCenter: ->
    if !@centered
      @centered = true
      @_reLayoutSelf()

  alignLeft: ->
    if @centered
      @centered = false
      @_reLayoutSelf()

  # a copied label button usually wants to un-highlight itself (e.g. when you
  # duplicate by clicking a "duplicate" button INSIDE it). Running an input-protocol verb on
  # the MID-ASSEMBLY clone (an orphan — the hook fires before any attach) is deliberate and
  # safe: hoverExited is the ONE home of the un-hover behaviour (state reset + tooltip
  # teardown; a hand-copied body here would be a drift-prone twin), and its _changed()
  # no-ops honestly on an orphan — the Duplicator drops the copied cache pairs, so the clone
  # derives its own orphan root rather than answering the ORIGINAL's world.
  _reactToBeingCopied: ->
    # public-call-sanctioned: hoverExited is the public pointer-event PROTOCOL verb (dispatched by
    # ActivePointerWdgt); reused to reset the copy's hover state — renaming it is not an option.
    @hoverExited()

  hoverEntered: ->
    @state = @STATE_HIGHLIGHTED
    @_changed()
    @startCountdownForBubbleHelp @toolTipMessage  if @toolTipMessage

  hoverExited: ->
    @state = @STATE_NORMAL
    @_changed()
    world.destroyToolTips()  if @toolTipMessage

  pressBegan: (pos) ->
    @state = @STATE_PRESSED
    @_changed()
    # replicate Widget.pressBegan inline (bringToForeground + escalate) rather
    # than calling super: ButtonWdgt's HighlightableMixin pressBegan would run
    # _updateColor, clobbering @color (our normal fill).
    @bringToForeground()
    @escalateEvent "pressBegan", pos

  # HighlightableMixin would reset @state to NORMAL on mouse-up; a label button
  # must NOT (a selected list row keeps its STATE_PRESSED highlight). So
  # neutralise it.
  pressEnded: ->

  activated: ->
    @bringToForeground()
    @state = @STATE_HIGHLIGHTED
    @_changed()
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()
