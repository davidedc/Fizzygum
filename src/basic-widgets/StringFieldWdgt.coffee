# The single string-input field, backed by the modern StringWdgt.
# The field BOX follows @width() (flexible, set by the containing menu/prompt layout);
# the inner StringWdgt is given a generous fixed width + SCALEDOWN so short values never
# render "cropped" — that keeps StringWdgt.edit on its INLINE branch (e.g.
# PromptWdgt.reactToSliderAction calls @text.edit() on every
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

  # As a menu entry, prefer my own current width (MenuWdgt.maxWidthOfMenuEntries
  # calls this polymorphically instead of type-checking the entry).
  menuEntryPreferredWidth: -> @width()

  _applyWidthAndNotify: (newWidth)->
    super
    @text._applyWidthAndNotify 300


  calculateAndUpdateExtent: ->
    txt = (if @text then @getValue() else @defaultContents)
    # note: StringWdgt takes isHeaderLine as its 6th arg, so isNumeric is the 7th
    text = new StringWdgt txt, @fontSize, @fontStyle, @isBold, @isItalic, false, @isNumeric
    text.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    #console.log "text widget extent: " + text.text + " : " + text.extent()
    @_applyWidthAndNotify Math.max @minTextWidth, text.width()
    #console.log "string field widget extent: " + @extent()

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
    @text._applyMoveToAndNotify @position().add new Point 5,2
    @text._applyExtentAndNotify new Point 300, 18
    @_commitExtentAndNotify new Point @width(), 18

  getValue: ->
    @text.text

  mouseClickLeft: (pos)->
    @bringToForeground()
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos


