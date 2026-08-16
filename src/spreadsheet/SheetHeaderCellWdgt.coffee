# SheetHeaderCellWdgt — one spreadsheet HEADER cell, as a real widget (plan §3-F F5, owner
# direction 2026-07-17: anything selectable/clickable should be a Widget). Three kinds share
# this class: the column-letter cells across the top, the row-number cells down the left, and
# the blank top-left corner. Headers are now inspectable, clickable widgets — a click
# escalates to the sheet exactly as a data-cell click does (today's behaviour, unchanged);
# column/row SELECTION semantics are a deliberate later arc, not part of the widgetisation.
#
# DERIVED chrome: carries no document state (@kind/@index are construction facts re-derivable
# from the sheet's geometry constants), so the restore/duplicate re-index DESTROYS and
# REBUILDS header cells rather than adopting them (SimpleSpreadsheetWdgt._reindexCellsNoSettle).
#
# It paints its CHROME (the F5 "the sheet paints nothing" flip):
#   - its header-strip fill (the sheet's headerFillColor — was the sheet's strip fillRects);
#   - its own TOP + LEFT grid edges via the sheet's paintGridEdges (the F5 edge-ownership
#     convention; the crossing rule lives there).
# Its LABEL is a passive StringWdgt child ("scalar text is a StringWdgt child, period" —
# owner direction 2026-07-24, same as CellWdgt's branch-3 text), kept in sync by
# _syncLabelNoSettle from the sheet's chrome ensure (build/scroll/resize/restore all funnel
# there); scrolling relabels in place through _setTextNoSettle's no-change guard.

class SheetHeaderCellWdgt extends Widget

  # the back-ref would serialize a header→sheet→header cycle; it is re-set on build (and in
  # practice restored header cells are destroyed + rebuilt by the re-index, never adopted)
  @serializationTransients: ["_sheetWidget"]

  # "column" | "row" | "corner"
  kind: undefined
  # 0-based viewport SLOT index (the label = view origin + slot, F1); undefined for the corner
  index: undefined
  # back-ref to the owning SimpleSpreadsheetWdgt (set by attachSheet)
  _sheetWidget: undefined
  # the label child (a passive StringWdgt); undefined for the corner
  _labelWdgt: undefined

  constructor: (kind, index) ->
    super()
    @appearance = new SheetHeaderCellAppearance @
    @kind = kind
    @index = index
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

  # @index is the viewport SLOT; the label derives from the sheet's view origin + slot at
  # label-sync time (F1) — scrolling relabels the frozen headers in place (cell-quantized
  # scroll means they never move). At origin 0 this is the identity.
  _labelText: ->
    switch @kind
      when "column" then @_sheetWidget.model.colToLetters (@_sheetWidget.viewOriginCol + @index)
      when "row"    then "" + (@_sheetWidget.viewOriginRow + @index + 1)
      else undefined

  # Keep my label child in sync (create / retext / place) — called from the sheet's chrome
  # ensure, whose build/scroll/resize/restore paths all funnel through buildHeader. The label
  # is a passive StringWdgt (the CellWdgt scalar-text configuration); a scroll relabels in
  # place through _setTextNoSettle's no-change guard. The corner has no label and never
  # creates one. NoSettle: runs inside the chrome ensure's enclosing settle.
  _syncLabelNoSettle: ->
    label = @_labelText()
    return unless label?
    if @_labelWdgt?
      @_labelWdgt._setTextNoSettle label
    else
      labelWdgt = new StringWdgt label, fontSize: 12
      labelWdgt.color = @_sheetWidget.headerTextColor
      labelWdgt.isEditable = false
      @_addNoSettle labelWdgt
      @_labelWdgt = labelWdgt
    # the (4,2) box inset places the TOP/LEFT-aligned glyphs at the exact position the
    # pre-conversion painted label had (x 4, baseline height−6) — measured, a pure
    # translation of identical glyph rasters (same idiom as CellWdgt's scalar child)
    @_labelWdgt._applyBounds (@position().add new Point 4, 2), @extent().subtract new Point 4, 2
    return
