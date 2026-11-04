# SheetHeaderCellWdgt — one spreadsheet HEADER cell, as a real widget (plan §3-F F5, owner
# direction 2026-07-17: anything selectable/clickable should be a Widget). Three kinds share
# this class: the column-letter cells across the top, the row-number cells down the left, and
# the blank top-left corner. Headers are inspectable, clickable widgets — a click escalates
# to the sheet exactly as a data-cell click does; column/row SELECTION semantics are a
# deliberate later arc, not part of the widgetisation.
#
# DERIVED chrome: carries no document state (@kind/@viewportSlot are construction facts re-derivable
# from the sheet's geometry constants), so the restore/duplicate re-index DESTROYS and
# REBUILDS header cells rather than adopting them (SimpleSpreadsheetWdgt._reindexCellsNoSettle).
#
# It paints its CHROME (the F5 "the sheet paints nothing" rule), through its
# SheetHeaderCellAppearance:
#   - its header fill (the theme's spreadsheetHeaderFill, read at paint time);
#   - its own TOP + LEFT grid edges via the sheet's paintGridEdges (the F5 edge-ownership
#     convention; the crossing rule lives there) — none along the sheet's outer top and left
#     boundary, which the corner, the column headers' tops and the row headers' lefts stand on.
# Its LABEL is a passive StringWdgt child ("scalar text is a StringWdgt child, period" —
# owner direction 2026-07-24, same as CellWdgt's branch-3 text) in fonts.buttonLabel and the
# theme's spreadsheetHeaderText, kept in sync by _syncLabelNoSettle from the sheet's chrome
# ensure (build/scroll/resize/restore all funnel there; a restore rebuilds the header, so the
# label wears the current look); scrolling relabels in place through _setTextNoSettle's
# no-change guard.

class SheetHeaderCellWdgt extends Widget

  # the back-ref would serialize a header→sheet→header cycle; it is re-set on build (and in
  # practice restored header cells are destroyed + rebuilt by the re-index, never adopted)
  @serializationTransients: ["_sheetWidget"]

  # "column" | "row" | "corner"
  kind: undefined
  # 0-based viewport SLOT index (the label = view origin + slot, F1); undefined for the corner
  viewportSlot: undefined
  # back-ref to the owning SimpleSpreadsheetWdgt (set by attachSheet)
  _sheetWidget: undefined
  # the label child (a passive StringWdgt); undefined for the corner
  _labelWdgt: undefined

  constructor: (kind, viewportSlot) ->
    super()
    @appearance = new SheetHeaderCellAppearance @
    @kind = kind
    @viewportSlot = viewportSlot
    @_sheetWidget = undefined
    @_labelWdgt = undefined
    # transparent by default — every visible pixel is painted explicitly by
    # SheetHeaderCellAppearance (the fill), so there is no boxy/rectangular paint to keep in sync
    @color = undefined

  colloquialName: ->
    "header cell"

  # the owning sheet, set at build time (a transient back-ref — see @serializationTransients)
  attachSheet: (sheetWidget) ->
    @_sheetWidget = sheetWidget
    return

  # The label derives from the sheet's view origin + my slot at label-sync time (F1) —
  # scrolling relabels the frozen headers in place (cell-quantized scroll means they never
  # move). At origin 0 slot and model index coincide.
  _labelText: ->
    switch @kind
      when "column" then @_sheetWidget.model.colToLetters (@_sheetWidget.viewOriginCol + @viewportSlot)
      when "row"    then "" + (@_sheetWidget.viewOriginRow + @viewportSlot + 1)
      else undefined

  # Keep my label child in sync (create / retext / place) — called from the sheet's chrome
  # ensure, whose build/scroll/resize/zoom/restore paths all funnel through buildHeader. The label
  # is a passive StringWdgt in the sheet's header font at its zoom (headerFontRole) and
  # spreadsheetHeaderText, read as it is built, standing the sheet's text inset in from my left and
  # centred on my height; a scroll relabels in place through _setTextNoSettle's no-change guard,
  # and a zoom (a different font size) rebuilds it. The corner has no label and never creates one.
  # NoSettle: runs inside the chrome ensure's enclosing settle.
  _syncLabelNoSettle: ->
    label = @_labelText()
    return unless label?
    role = @_sheetWidget.headerFontRole()
    if @_labelWdgt? and @_labelWdgt.originallySetFontSize isnt role.size
      @_labelWdgt._fullDestroyNoSettle()
      @_labelWdgt = undefined
    if @_labelWdgt?
      @_labelWdgt._setTextNoSettle label
    else
      labelWdgt = new StringWdgt label,
        fontRole: role
        color: WorldWdgt.theme.spreadsheetHeaderText
      labelWdgt.isEditable = false
      labelWdgt.verticalAlignment = AlignmentSpecVertical.MIDDLE
      @_addNoSettle labelWdgt
      @_labelWdgt = labelWdgt
    inset = @_sheetWidget.textInsetPx()
    @_labelWdgt._applyBounds (@position().add new Point inset, 0), new Point (Math.max 1, @width() - inset), @height()
    return
