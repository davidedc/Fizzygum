# SpreadsheetApp — the "Sheets Maker" desktop launcher/opener (one of the WindowedApp subclasses; the
# DegreesConverterApp shape). Its title/icon are read from AppCatalog (keyed by class name, not by this
# class); this file only builds the window -- the base owns createOpener + launch. `slot: undefined`
# ⇒ a FRESH window every launch (multiple sheets allowed — the sheet is NOT a world singleton).
#
# Opens a SpreadsheetWdgt citizen (a FrameWdgt over the SimpleSpreadsheetWdgt grid -- §5.B;
# openFrameWith passes the framed citizen through). See docs/specs/dataflow-engine-spec.md §9.1 and
# src/spreadsheet/CLAUDE.md.
#
# ⚠ THIS FILE IS IN src/spreadsheet/, BESIDE THE GRID IT OPENS, AND THAT IS THE POINT — a desktop icon
# is built at boot from core art and this class's NAME (AppLauncherWdgt's lazy mode), so the door costs
# nothing until it is clicked, and the click fetches door and grid as ONE part: one click, one fetch,
# the way the Makers live inside the 'authoring' part they build from. (The Examples folder's
# "Party budget" is a different door, SampleSheetApp, alone in its own one-class part.)

class SpreadsheetApp extends WindowedApp

  requiredParts: ["spreadsheet"]

  slot:  undefined   # multiple sheets — a fresh window every launch (no world slot)

  # My launcher wears the spreadsheet's own icon, SpreadsheetIconWdgt (core art, named by
  # AppCatalog's entry; the sheet's representativeIcon answers the same one).
  #   THE OPENING SIZE is the SHEET's, never the window's: a fresh sheet opens at its default
  # extent (SimpleSpreadsheetWdgt.defaultExtent: the formula bar over a 5 x 10 grid at 100%). The
  # window is sized AROUND that extent by the frame's own chrome query
  # (FrameWdgt.extentWrappingPayloadAt), so the sheet opens at the same grid whatever the window's
  # chrome measures — its toolbar band and its page gutter included. The sheet is fill-class window
  # content (F6): a resize from here shows more (or less) of the 26×100 logical sheet.
  buildWindow: ->
    sheetWindow = new SpreadsheetWdgt
    world.openFrameWith sheetWindow, (sheetWindow.extentWrappingPayloadAt sheetWindow.contents.defaultExtent()), (new Point 120, 90)
