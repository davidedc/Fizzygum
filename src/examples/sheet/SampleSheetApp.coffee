# SampleSheetApp — the Examples folder's "Party budget": a small budget that shows what this
# spreadsheet does that others do not. A slider lives in a cell (B3) and drives the formulas that read
# it (C3, then the total and what is left); a cell's formula returns a COLOUR (C8: green while the
# total is within the budget, red over it), which the cell shows as a swatch. Drag the slider and the
# totals and the swatch follow. Every entry is CoffeeScript, so text needs quotes.
#   One of the five doors of the Examples folder, alone in its own one-class LAZY part
# ('example-sheet'): opening the folder fetches the five doors and nothing else, and clicking this one
# fetches the grid through the `requiredParts` the inherited `launch` awaits. Its title and icon live in
# AppCatalog. The blank sheet is Sheets Maker on the desktop (SpreadsheetApp).

class SampleSheetApp extends WindowedApp

  requiredParts: ["spreadsheet"]

  slot:  "sampleSheetWindow"

  # [address, source] of every entry, one per line (a member body is compiled on its own, so the
  # array hangs off an arrow), and the one cell shown in bold
  _entries: -> [
    ["A1", '"Party budget"']
    ["A3", '"Guests"']
    ["B3", "new SliderWdgt 1, 40, 12, 1"]
    ["C3", "Math.round B3"]
    ["A4", '"Per guest"']
    ["C4", "15"]
    ["A5", '"Total"']
    ["C5", "C3 * C4"]
    ["A6", '"Budget"']
    ["C6", "250"]
    ["A7", '"Left"']
    ["C7", "C6 - C5"]
    ["A8", '"Status"']
    ["C8", "if C5 <= C6 then Color.SEAGREEN else Color.TOMATO"]
  ]
  BOLD: "A1"

  buildWindow: ->
    sheetWindow = new SpreadsheetWdgt
    sheet = sheetWindow.contents
    for [address, source] in @_entries()
      cell = sheet.model.getOrCreateCellAt address
      FormulaCompiler.commit cell, source
      world.dataflow.markStale cell
    sheet.model.getOrCreateCellAt(@BOLD).format = {bold: true}
    world.openFrameWith sheetWindow, (sheetWindow.extentWrappingPayloadAt sheet.defaultExtent()), (new Point 150, 110)
    sheetWindow.setTitleWithoutPrependedContentName @_title()
    # closing just closes (no save prompt) -- a sample is not worth saving (the SampleDocApp policy)
    sheetWindow.closeFromFrameBarPolicy = 'close'
    # return the WINDOW: the base stores it in world[@slot] for the bring-forward-on-relaunch path
    sheetWindow
