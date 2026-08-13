# SpreadsheetApp — the desktop launcher/opener for the spreadsheet (one of the
# IconicDesktopSystemWindowedApp subclasses; the DegreesConverterApp shape). Its title/icon are
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
# its contents are invisible until it is opened, and IconicDesktopSystemShortcutWdgt.bringUpTarget is
# fire-and-forget, so it can await. See ExamplesFolderWindowWdgt and WorldWdgt.createDesktop — no
# icon, desktop or folder, needs an eager app sliver any more (docs/archive/app-descriptor-unification-plan.md).

class SpreadsheetApp extends IconicDesktopSystemWindowedApp

  requiredParts: ["spreadsheet"]

  slot:  undefined   # multiple sheets — a fresh window every launch (no world slot)

  # v1 placeholder icon (an existing shortcut glyph); a dedicated SpreadsheetIconWdgt is
  # deferred (recorded in the implementation plan's Phase-2a notes).
  buildWindow: ->
    # THE default-size pin (F6 V4): with fill-class sheet content the passed window extent is
    # AUTHORITATIVE, and 452×336 grants the content exactly 442×300 — the default 6×14 grid —
    # through the window's 36px chrome (titlebar 26 + 2×5 padding; width 452 − 2×5 padding =
    # 442). Pre-F6 the FIXED content DICTATED the window height: the old passed 334 was
    # overwritten to 336 by the content-driven arrange every pass, so the on-screen window was
    # always 452×336 — this pin preserves that exact render, byte-for-byte (the F6 hard gate:
    # the whole pre-F6 suite, zero recaptures). A resize from here shows MORE of the 26×100
    # logical sheet (partial edge cells; backdrop past the sheet edge).
    world.openFrameWith (new SpreadsheetWdgt), (new Point 452, 336), (new Point 120, 90)
