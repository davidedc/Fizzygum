# SpreadsheetApp — the desktop launcher/opener for the spreadsheet (one of the
# IconicDesktopSystemWindowedApp subclasses; the DegreesConverterApp shape). It declares the
# launcher title/icon and builds the window; the base owns createOpener + launch. `slot: nil`
# ⇒ a FRESH window every launch (multiple sheets allowed — the sheet is NOT a world singleton).
#
# Opens a SpreadsheetWdgt citizen (a FrameWdgt over the SimpleSpreadsheetWdgt
# painted grid -- §5.B; openFrameWith passes the framed citizen through). See docs/specs/dataflow-engine-
# spec.md §9.1 and src/spreadsheet/CLAUDE.md.
#
# ⚠ THIS FILE IS NOT IN src/spreadsheet/, AND THAT IS THE POINT. It is the whole of the EAGER
# 'spreadsheet-launcher' part, while the grid it opens is the LAZY 'spreadsheet' part. The split is
# forced: WorldWdgt.createDesktop calls createOpener at BOOT to place the Examples-folder icon, so
# a launcher inside the lazy directory would mean no icon until something else pulled the part in
# -- i.e. never. Exactly the fizzytiles / fizzytiles-launcher shape.

class SpreadsheetApp extends IconicDesktopSystemWindowedApp

  title: "Spreadsheet"
  slot:  nil   # multiple sheets — a fresh window every launch (no world slot)

  # v1 placeholder icon (an existing shortcut glyph); a dedicated SpreadsheetIconWdgt is
  # deferred (recorded in the implementation plan's Phase-2a notes).
  buildIcon: -> new GenericShortcutIconWdgt new TypewriterIconWdgt

  # THE ONE LAZY DOOR into the spreadsheet. Everything buildWindow touches — SpreadsheetWdgt,
  # SimpleSpreadsheetWdgt and the cell/model classes behind them — is the lazy 'spreadsheet' part,
  # so it has to be here before super() runs. An `if SpreadsheetWdgt?` guard would be WRONG: for a
  # lazy part that reads "not fetched yet", i.e. a click that silently does nothing.
  #
  # ⚠ whenAllLoaded, not `.then`, and the difference is CORRECTNESS rather than speed: it runs the
  # callback INLINE when the part is already in. Every build the SystemTest suite runs presets
  # FIZZYGUM_EAGER_ALL_PARTS, so it always is — and going through a promise regardless would defer
  # the window by a microtask, which moves it a whole world CYCLE later. The 19 spreadsheet tests
  # measure cycles (several open the sheet and read it in the same macro step).
  launch: ->
    world.parts.whenAllLoaded ["spreadsheet"], => super()

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
