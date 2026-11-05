# The framed SPREADSHEET citizen (Frame-model plan §5.B, owner decision D2):
# a spreadsheet IS its window. One of the Makers' documents (MakerDocumentWdgt,
# which owns the title, the save-or-destroy close and the payload rebuild every
# such document shares), and a thin one over the naked grid
# (SimpleSpreadsheetWdgt -- the model owner / formula scope / keyboard
# receiver): the grid manages its own editing (no providesAmenitiesForEditing,
# so the frame shows no edit toggle), its toolbar is the sheet toolbar, docked
# on top at construction (buildToolbar), and the frame's representativeIcon
# dispatch reaches the grid unchanged.

class SpreadsheetWdgt extends MakerDocumentWdgt

  _makeStartingPayload: ->
    new SimpleSpreadsheetWdgt

  # ⚠ Do NOT delete this as "the same as the derivation". It IS what Widget's derivation would
  # produce, but I extend FrameWdgt -- so without it the chain answers FrameWdgt's "window", not the
  # derivation, and the window's title goes with it: "Sheets Maker", as a Docs Maker window is titled
  # "Docs Maker", the desktop Maker's own name (MakerDocumentWdgt titles it with this). (GenericPanelWdgt
  # sits in the same trap.)
  colloquialName: ->
    "Sheets Maker"

  # the frame docks this variant in its toolbar-slot (§5.C): the text tools, which act on the
  # sheet's selected cell, and the sheet's own
  buildToolbar: ->
    new SheetToolbarWdgt

  # changed = some cell holds an entry or a format (SheetModel.isBlank)
  hasStartingContentBeenChangedByUser: ->
    !@contents.model.isBlank()
