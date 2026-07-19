# The single string-input field, backed by the modern StringWdgt.
# The field BOX follows @width() (flexible, set by the containing menu/prompt layout);
# the inner StringWdgt is given a generous fixed width + SCALEDOWN so short values never
# render "cropped" — that keeps StringWdgt.edit on its INLINE branch (e.g.
# PromptWdgt.takeSliderValue calls @text.edit() on every
# slider step and must NOT pop the "edit:" prompt).
# A stringWidget that can "scroll" as the cursor moves along the text
# but note that there are no scrollbars, since the container
# is just a Panel not a ScrollPanel.

class StringFieldWdgt extends PanelWdgt

  defaultContents: nil
  minTextWidth: nil
  fontSize: nil
  fontStyle: nil
  isBold: nil
  isItalic: nil
  isNumeric: nil
  text: nil
  isEditable: true
  # my as-built width, frozen at the first menuEntryPreferredWidth ask (see
  # that method); declared so DeepCopierMixin duplication carries it.
  menuEntryNaturalWidth: nil

  constructor: (
      @defaultContents = "",
      @minTextWidth = 100,
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false
      ) ->
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

  _applyWidth: (newWidth)->
    super
    @text._applyWidth 300


  calculateAndUpdateExtent: ->
    txt = (if @text then @getValue() else @defaultContents)
    # note: StringWdgt takes isHeaderLine as its 6th arg, so isNumeric is the 7th
    text = new StringWdgt txt, @fontSize, @fontStyle, @isBold, @isItalic, false, @isNumeric
    text.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    # THIS is the field's natural-width derivation — capture it for
    # menuEntryPreferredWidth at the source rather than reading applied
    # geometry back later (menu-row-conformance plan, Phase 1).
    @menuEntryNaturalWidth = Math.max @minTextWidth, text.width()
    @_applyWidth @menuEntryNaturalWidth

  _reLayoutSelf: ->
    super()
    txt = (if @text then @getValue() else @defaultContents)
    if !@text?
      @text = new StringWdgt(txt, @fontSize, @fontStyle, @isBold, @isItalic, false, @isNumeric)
      @text.isNumeric = @isNumeric # for whichever reason...
      @text.isEditable = @isEditable
      @text.enableSelecting()
      @text.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
      # _addNoSettle (NOT add): _reLayoutSelf runs inside a layout pass -- and via
      # _reactToBeingAdded -> _reLayoutSelf inside another mutation's settle -- so a
      # self-settle here would re-enter the flush guard and throw.
      @_addNoSettle @text
    @text._applyMoveTo @position().add new Point 5,2
    @text._applyExtent new Point 300, 18
    @__commitExtent new Point @width(), 18

  getValue: ->
    @text.text

  mouseClickLeft: (pos)->
    @bringToForeground()
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos


