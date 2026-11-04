# SheetCellStyle — what the editing tools act on while a spreadsheet is the editor focus: the STYLE of
# its selected cell (docs/archive/spreadsheet-ux-plan.md R4/R5). The text tools duck-type their target
# (EditorContentPropertyChangerButtonWdgt._styleSubject asks the focus for textStyleSubject, else uses
# the focus itself), so this answers the same small protocol a StringWdgt does — the FIELDS they read
# (isBold, isItalic, fontName, originallySetFontSize, horizontalAlignment, and the font stacks a font
# tool picks from) and the METHODS they call (toggleWeight, toggleItalic, setFontName, setFontSize, the
# three aligns) — plus the sheet's own tools' (pickFillColor, fewerDecimals, moreDecimals, enterSource).
#   It holds no style of its own. The style is the cell's FORMAT (SheetCellRecord.format, document
# state, so it survives scroll, zoom, save/load and duplicate); the fields below are read from it as
# this object is made, which is when a tool asks, and every method writes it through the sheet
# (SimpleSpreadsheetWdgt.restyleCell), which shows the cell in its new style and tells the tools.
#   A plain class, never a widget, never kept: the sheet makes a fresh one per ask.

class SheetCellStyle

  # the default a cell without a format of its own shows: the theme's cell role at 100%
  constructor: (@sheet, @address) ->
    format = @sheet.model.cellAt(@address)?.format
    base = WorldWdgt.theme.fonts.spreadsheetCell
    @isBold = (format?.bold ? base.bold) is true
    @isItalic = format?.italic is true
    @fontName = format?.fontName ? base.family
    @originallySetFontSize = format?.fontSize ? base.size
    @horizontalAlignment = if format?.align? then AlignmentSpecHorizontal[format.align] else @_defaultAlignment()
    # the font stacks a font tool sets by name (ChangeFontButtonWdgt, FormatAsCodeButtonWdgt): the
    # text widget's, so a cell and a text agree on what "mono" is
    for own key, value of StringWdgt.prototype when /FontStack$/.test key
      @[key] = value

  # numbers stand right, everything else left (the sheet's own rule, SimpleSpreadsheetWdgt._textLookFor)
  _defaultAlignment: ->
    value = @sheet.model.cellAt(@address)?.value
    if typeof value is "number" then AlignmentSpecHorizontal.RIGHT else AlignmentSpecHorizontal.LEFT

  toggleWeight: ->
    bold = not @isBold
    @sheet.restyleCell @address, (format) -> format.bold = bold

  toggleItalic: ->
    italic = not @isItalic
    @sheet.restyleCell @address, (format) -> format.italic = italic

  setFontName: (fontName) ->
    @sheet.restyleCell @address, (format) -> format.fontName = fontName

  setFontSize: (size) ->
    @sheet.restyleCell @address, (format) -> format.fontSize = size

  alignLeft: ->
    @sheet.restyleCell @address, (format) -> format.align = "LEFT"

  alignCenter: ->
    @sheet.restyleCell @address, (format) -> format.align = "CENTER"

  alignRight: ->
    @sheet.restyleCell @address, (format) -> format.align = "RIGHT"

  # ── the sheet's own tools ───────────────────────────────────────────────────────────────

  # the fill tool: the colour prompt, whose choice fills the cell
  pickFillColor: ->
    @sheet.pickFillFor @address

  # the decimals tools: one place fewer or more, counted from what the cell shows when its format
  # sets none (the decimals of the number's own text)
  fewerDecimals: ->
    current = @_decimalsShown()
    return unless current?
    @sheet.restyleCell @address, (format) -> format.decimals = Math.max 0, current - 1

  moreDecimals: ->
    current = @_decimalsShown()
    return unless current?
    @sheet.restyleCell @address, (format) -> format.decimals = Math.min 10, current + 1

  # the decimal places the cell shows now, or undefined when it shows no number
  _decimalsShown: ->
    record = @sheet.model.cellAt @address
    return undefined unless typeof record?.value is "number"
    return record.format.decimals if record.format?.decimals?
    text = record.value.toString()
    point = text.indexOf "."
    if point < 0 then 0 else text.length - point - 1

  # the slider-in-cell tool: a source entered in the cell as if typed
  enterSource: (source) ->
    @sheet.enterSource @address, source
