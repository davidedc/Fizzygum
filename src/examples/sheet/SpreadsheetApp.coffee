# SpreadsheetApp — the desktop launcher/opener for the spreadsheet (one of the
# WindowedApp subclasses; the DegreesConverterApp shape). Its title/icon are
# read from AppCatalog (keyed by class name, not by this class); this file only builds the window --
# the base owns createOpener + launch. `slot: undefined`
# ⇒ a FRESH window every launch (multiple sheets allowed — the sheet is NOT a world singleton).
#
# Opens a SpreadsheetWdgt citizen (a FrameWdgt over the SimpleSpreadsheetWdgt
# painted grid -- §5.B; openFrameWith passes the framed citizen through). See docs/specs/dataflow-engine-
# spec.md §9.1 and src/spreadsheet/CLAUDE.md.
#
# ⚠ THIS FILE IS NOT IN src/spreadsheet/, AND THAT IS THE POINT — the door and the engine are two
# things fetched at two moments. It is one of the five DOORS of the desktop's Examples folder, each
# alone in its own lazy one-class part (this one is 'example-sheet'); the grid it opens is the
# separate lazy 'spreadsheet' part. Two layers, two moments: opening the folder fetches this class
# and the four beside it, and NOTHING else; clicking this icon fetches the grid, through the
# `requiredParts` below that the inherited `launch` awaits. That works because a FOLDER IS A DOOR —
# its contents are invisible until it is opened, and ShortcutWdgt.bringUpReferencedWidget is
# fire-and-forget, so it can await. See ExamplesFolderWindowWdgt and WorldWdgt.createDesktop — no
# icon, desktop or folder, needs an eager app sliver any more (docs/archive/app-descriptor-unification-plan.md).

class SpreadsheetApp extends WindowedApp

  requiredParts: ["spreadsheet"]

  slot:  undefined   # multiple sheets — a fresh window every launch (no world slot)

  # My launcher wears the spreadsheet's own icon, SpreadsheetIconWdgt (core art, named by
  # AppCatalog's entry; the sheet's representativeIcon answers the same one).
  #   THE OPENING SIZE is the SHEET's, never the window's: a fresh sheet opens at its opening grid,
  # 446×280 -- six whole columns and a 4 px sliver of a seventh, by thirteen whole rows (a 7×13
  # viewport: 91 cells under 21 headers). The window is sized AROUND that extent by the frame's own
  # chrome query (FrameWdgt.extentWrappingPayloadAt), so the sheet opens at the same grid whatever
  # the window's chrome measures. The sheet is fill-class window content (F6): the window extent
  # passed here is authoritative and the sheet takes what it grants, so a resize from here shows
  # more (or less) of the 26×100 logical sheet -- partial edge cells, backdrop past its edge.
  buildWindow: ->
    sheetWindow = new SpreadsheetWdgt
    openingSheetExtent = new Point 446, 280
    world.openFrameWith sheetWindow, (sheetWindow.extentWrappingPayloadAt openingSheetExtent), (new Point 120, 90)
