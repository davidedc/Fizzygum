# The single string-input field, backed by the modern StringWdgt.
# The field BOX follows @width() (flexible, set by the containing menu/prompt layout);
# the inner StringWdgt is given a generous fixed width + SCALEDOWN so short values never
# render "cropped" — that keeps StringWdgt.edit on its INLINE branch (e.g.
# PromptWdgt.takeSliderValue calls @text.edit() on every
# slider step and must NOT pop the "edit:" prompt).
# A stringWidget that can "scroll" as the cursor moves along the text
# but note that there are no scrollbars, since the container
# is just a Panel not a Viewport.

class StringFieldWdgt extends PanelWdgt

  defaultContents: undefined
  minTextWidth: undefined
  fontSize: undefined
  fontStyle: undefined
  isBold: undefined
  isItalic: undefined
  isNumeric: undefined
  text: undefined
  isEditable: true
  # my as-built width, frozen at the first menuEntryPreferredWidth ask (see
  # that method); declared so Duplicator duplication carries it.
  menuEntryNaturalWidth: undefined

  constructor: (@defaultContents = "", opts = {}) ->
    @minTextWidth = opts.minTextWidth ? 100
    @fontSize = opts.fontSize ? 12
    @fontStyle = opts.fontStyle ? "sans-serif"
    @isBold = opts.isBold ? false
    @isItalic = opts.isItalic ? false
    @isNumeric = opts.isNumeric ? false
    super()
    @color = Color.WHITE

  # As a menu entry, answer my natural width as DERIVED in
  # calculateAndUpdateExtent (max(minTextWidth, text width) — every prompt
  # builder runs it right after adding me). The `?=` arm only covers a field
  # built without that derivation: freeze the as-built width at the first ask.
  # Either way the answer is stretch-immune — the old `@width()` read-back
  # reported the post-stretch width forever, the no-shrink ratchet
  # (menu-row-conformance plan, Phase 1).
  menuEntryPreferredWidth: -> @menuEntryNaturalWidth ?= @width()

  # I am a size-tracking container of my one child: the inner text tracks my
  # frame -- pinned at my origin +(5,2), at the generous fixed 300x18 (see the
  # header comment: SCALEDOWN keeps StringWdgt.edit on its INLINE branch).
  # Conforming to the engine's child contract (menu-row-conformance plan,
  # Phase 2d) replaces the old bespoke `_applyWidth` hook (whose
  # `@text._applyWidth 300` duplicated the 300 sizing _reLayoutSelf applies):
  # a rows-panel arrange sizes me via _setWidthSizeHeightAccordingly (virtual
  # _applyWidth + synchronous _reLayout since I now defer), and any base
  # _applyExtent resize schedules my _reLayout via the valve -- both end HERE.
  _reLayoutChildren: ->
    return unless @text?
    @text._applyBounds (@position().add new Point 5,2), new Point 300, 18

  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  calculateAndUpdateExtent: ->
    txt = (if @text then @getValue() else @defaultContents)
    measuringText = new StringWdgt txt,
      fontSize: @fontSize
      fontName: @fontStyle
      bold: @isBold
      italic: @isItalic
      numeric: @isNumeric
    measuringText.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    # THIS is the field's natural-width derivation — capture it for
    # menuEntryPreferredWidth at the source rather than reading applied
    # geometry back later (menu-row-conformance plan, Phase 1).
    @menuEntryNaturalWidth = Math.max @minTextWidth, measuringText.width()
    # the measurer is an orphan INSTRUMENT, never a child: destroy it (through the
    # non-settling core -- this runs inside the prompt build's settle) or the
    # instances registry keeps it alive forever, one leaked StringWdgt per prompt.
    measuringText._fullDestroyNoSettle()
    @_applyWidth @menuEntryNaturalWidth

  _reLayoutSelf: ->
    super()
    txt = (if @text then @getValue() else @defaultContents)
    if !@text?
      @text = new StringWdgt txt,
        fontSize: @fontSize
        fontName: @fontStyle
        bold: @isBold
        italic: @isItalic
        numeric: @isNumeric
      @text.isNumeric = @isNumeric
      @text.isEditable = @isEditable
      @text.enableSelecting()
      @text.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
      # _addNoSettle (NOT add): _reLayoutSelf runs inside a layout pass -- and via
      # _reactToBeingAdded -> _reLayoutSelf inside another mutation's settle -- so a
      # self-settle here would re-enter the flush guard and throw.
      @_addNoSettle @text
    @_reLayoutChildren()
    @__commitExtent new Point @width(), 18

  getValue: ->
    @text.text

  # READ-ONLY principal pin: I hold my string in a child StringWdgt (@text is that WIDGET, not a
  # string), so getValue reaches through it and there is no one-call setter twin to pair it with.
  # Declaring the pin is what makes my exported value `@text.text` rather than the child widget
  # itself — see the warning on Widget.exportedValue.
  # (no `announces` question here: a follower follows the pin its own wire DRIVES, and a wire's
  # action is a setter — a read-only pin can never be one, so it is unfollowable by construction.)
  pins: -> super().concat [ new PinSpec "value", "string", get: "getValue" ]
  principalPinLabel: "value"

  activated: (pos)->
    @bringToForeground()
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'activated', pos


