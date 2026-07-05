# SpreadsheetApp — the desktop launcher/opener for the spreadsheet (one of the
# IconicDesktopSystemWindowedApp subclasses; the DegreesConverterApp shape). It declares the
# launcher title/icon and builds the window; the base owns createOpener + launch. `slot: nil`
# ⇒ a FRESH window every launch (multiple sheets allowed — the sheet is NOT a world singleton).
#
# The window content is a SpreadsheetWdgt (the painted grid). See docs/specs/dataflow-engine-
# spec.md §9.1 and src/spreadsheet/CLAUDE.md.

class SpreadsheetApp extends IconicDesktopSystemWindowedApp

  title: "Spreadsheet"
  slot:  nil   # multiple sheets — a fresh window every launch (no world slot)

  # v1 placeholder icon (an existing shortcut glyph); a dedicated SpreadsheetIconWdgt is
  # deferred (recorded in the implementation plan's Phase-2a notes).
  buildIcon: -> new GenericShortcutIconWdgt new TypewriterIconWdgt

  buildWindow: ->
    # window sized to fit the fixed grid (6×14) plus the title-bar/padding chrome (~34px tall)
    world.openWindowWith (new SpreadsheetWdgt), (new Point 452, 334), (new Point 120, 90)
