# SheetFormulaBarWdgt — the spreadsheet's FORMULA BAR (docs/archive/spreadsheet-ux-plan.md R7/R8): a
# frozen row across the top of its SimpleSpreadsheetWdgt, above the column headers, showing the
# selected cell's ADDRESS, then its SOURCE in a text field, then — when the cell holds an error — the
# error's message, and at the right end the ZOOM control. It is part of the sheet, not a tool of a
# toolbar: what it shows is the sheet's selection, and a toolbar can dock on any side or float away
# from every sheet, where a field showing "the selected cell" would have nothing behind it.
#   It is CHROME, at the size a finger needs, and it does not zoom: the theme's
# spreadsheetFormulaBarHeight (44, the 44 rule), its field 4 in from its top and bottom (36, a row at
# 100%), its text in fonts.spreadsheetFormulaBar (16, the cells' size at 100%). The address stands over
# the row-number column at its 100% width; the field and the error take the rest, the zoom button its
# own width at the right. Its appearance (SheetFormulaBarAppearance) draws the field's well and the 1 px
# rule along its bottom, the line the column headers stand under.
#   Chrome the sheet builds, places and syncs (syncNoSettle) whenever the selection moves, the selected
# cell changes or the zoom does. Unlike the header cells it is ADOPTED on a restore or a duplicate,
# like the cells: the copy carries it, and the sheet re-attaches and re-syncs it (rebuilding it there
# would build its zoom button, which settles, inside the copy and restore notifications). While the sheet edits a cell, the field shows the
# edit's text: with the caret in it when the edit started here (a click on the field), or following
# the cell's editor as it is typed into (the sheet's reactToKeystroke). Enter, Tab and Escape in the
# field reach the sheet through my accept / nextTab / previousTab / cancel, exactly as from a cell.

class SheetFormulaBarWdgt extends Widget

  # the back-ref to my sheet is re-attached on restore and copy (the sheet's re-index), never saved:
  # it would make a sheet → bar → sheet cycle in a snapshot
  @serializationTransients: ["_sheetWidget"]

  # the owning sheet (attachSheet); my children, adopted with me on a restore or a copy
  _sheetWidget: undefined
  addressWdgt: undefined
  textWdgt: undefined
  errorWdgt: undefined
  zoomButton: undefined
  # the zoom my button's label was built for
  _zoomShown: undefined
  # the field's box, relative to my top-left, as last placed (my appearance draws its well there)
  fieldRect: undefined

  FIELD_INSET: 4        # the field stands this far in from my top, my bottom and its neighbours
  TEXT_INSET: 8         # the text stands this far in from the field's left edge
  ERROR_SHARE: 0.4      # an error's message takes at most this share of my width

  constructor: ->
    super()
    @appearance = new SheetFormulaBarAppearance @
    @color = undefined
    @fieldRect = Rectangle.EMPTY

  attachSheet: (sheetWidget) ->
    @_sheetWidget = sheetWidget
    return

  # Bring my children in line with the sheet: the selected cell's address and source (unless an edit
  # owns the field's text), its error's message if it holds one, the zoom button's level; then place
  # them in my box. NoSettle: the sheet calls it inside the settle of whatever moved.
  syncNoSettle: ->
    sheet = @_sheetWidget
    return unless sheet?
    theme = WorldWdgt.theme
    address = sheet.model.addressFor sheet.selectedCol, sheet.selectedRow
    record = sheet.model.cellAt address
    unless @addressWdgt?
      @addressWdgt = @_newLabel address, theme.spreadsheetHeaderText
      @_addNoSettle @addressWdgt
    @addressWdgt._setTextNoSettle address
    unless @textWdgt?
      @textWdgt = @_newLabel "", theme.spreadsheetValueText
      # an edit here never pops out to the "edit:" prompt; an over-long source stays inline
      @textWdgt.alwaysEditsInline = true
      @_addNoSettle @textWdgt
    @textWdgt._setTextNoSettle (record?.source ? "") unless sheet._editing
    error = if sheet.isErrorValue record?.value then record.value
    if error?
      message = "#" + error.kind + (if error.message then ": " + error.message else "")
      unless @errorWdgt?
        @errorWdgt = @_newLabel message, theme.spreadsheetErrorText
        @_addNoSettle @errorWdgt
      @errorWdgt._setTextNoSettle message
    else if @errorWdgt?
      @errorWdgt._fullDestroyNoSettle()
      @errorWdgt = undefined
    if @zoomButton? and @_zoomShown isnt sheet.zoomFactor
      @zoomButton._fullDestroyNoSettle()
      @zoomButton = undefined
    unless @zoomButton?
      @zoomButton = new SimpleButtonWdgt @, "openZoomMenu", face: (@_zoomLabel sheet.zoomFactor)
      @_zoomShown = sheet.zoomFactor
      @_addNoSettle @zoomButton
    @_placeChildrenNoSettle()
    @_changed()
    return

  _newLabel: (text, ink) ->
    label = new StringWdgt text,
      fontRole: WorldWdgt.theme.fonts.spreadsheetFormulaBar
      color: ink
    label.isEditable = false
    label.verticalAlignment = AlignmentSpecVertical.MIDDLE
    label

  _zoomLabel: (factor) ->
    Math.round(factor * 100) + "%"

  _placeChildrenNoSettle: ->
    sheet = @_sheetWidget
    inset = @FIELD_INSET
    h = @height()
    addressW = sheet.headerColWidth
    @addressWdgt._applyBounds (@position().add new Point sheet.textInset, 0), new Point (Math.max 1, addressW - sheet.textInset), h
    buttonExtent = @zoomButton.preferredExtent()
    buttonX = @width() - inset - buttonExtent.x
    @zoomButton._applyBounds (@position().add new Point buttonX, Math.floor (h - buttonExtent.y) / 2), buttonExtent
    fieldLeft = addressW + inset
    fieldRight = buttonX - inset
    if @errorWdgt?
      # the message's own width (its text measured in its font), up to its share of mine
      errorW = Math.min (Math.ceil @errorWdgt.calculateTextWidth @errorWdgt.text, @errorWdgt.originallySetFontSize), Math.floor(@width() * @ERROR_SHARE)
      errorW = Math.max 1, errorW
      @errorWdgt._applyBounds (@position().add new Point (fieldRight - errorW), 0), new Point errorW, h
      fieldRight -= errorW + inset
    fieldW = Math.max 1, fieldRight - fieldLeft
    @fieldRect = new Rectangle fieldLeft, inset, fieldLeft + fieldW, h - inset
    @textWdgt._applyBounds (@position().add new Point fieldLeft + @TEXT_INSET, inset), new Point (Math.max 1, fieldW - 2 * @TEXT_INSET), (Math.max 1, h - 2 * inset)
    return

  # ── editing in the field ──────────────────────────────────────────────────────────────────

  # an edit of the selected cell started (SimpleSpreadsheetWdgt._startEditNoSettle): the field
  # shows its text, and takes the caret when the edit started here
  beginEditNoSettle: (text, takesTheCaret) ->
    return unless @textWdgt?
    @textWdgt._setTextNoSettle text
    @textWdgt.isEditable = takesTheCaret
    return

  endEditNoSettle: ->
    @textWdgt.isEditable = false if @textWdgt?
    return

  # the text the field shows while the cell's editor holds the caret
  mirrorEditTextNoSettle: (text) ->
    @textWdgt?._setTextNoSettle text
    return

  # a click on my field (on the text, which escalates its activation to me, or on the well around
  # it) edits the selected cell here, the caret at the clicked slot; a click anywhere else on me is
  # nothing. The dispatcher's pos is already plane-mapped and the sheet shares my plane.
  activated: (pos) ->
    local = pos.subtract @position()
    @_sheetWidget?.editInFormulaBarAtPointer pos if @fieldRect.containsPoint local
    return

  # the caret's escalations from my field's text while it holds the caret: the sheet's, as from a
  # cell's editor (CellWdgt.accept and its siblings)
  accept: (how) ->
    @_sheetWidget?.acceptCellEdit how
    return

  cancel: ->
    @_sheetWidget?.cancelCellEdit()
    return

  nextTab: (editField) ->
    @_sheetWidget?.tabFromEdit 1
    return

  previousTab: (editField) ->
    @_sheetWidget?.tabFromEdit -1
    return

  # ── the zoom control ────────────────────────────────────────────────────────────────────

  # my zoom button's action: the levels the sheet zooms to, the current one ticked
  openZoomMenu: ->
    sheet = @_sheetWidget
    return unless sheet?
    menu = new MenuWdgt @zoomButton, target: sheet, title: "Zoom"
    for level in sheet.ZOOM_LEVELS
      menu.addMenuItem (@_zoomLabel level), sheet, "setZoomFromMenu", arg1: level, ticked: (level is sheet.zoomFactor)
    menu.popUpAtHand()
    return
