# SheetCellsPanelWdgt — the spreadsheet's DATA-CELL container (plan §3-F F5, owner direction
# 2026-07-17: "the cells attach into a subclass of the container widget"). Spans the data
# region (right of the row-number header column, below the column-letter header row) and hosts
# the sheet's 84 CellWdgt children; the frozen header cells are deliberately OUTSIDE it
# (direct sheet children), so the PanelWdgt clip below can never touch them.
#
# It is TRANSPARENT (nil @appearance — the CellWdgt idiom): the sheet NEVER painted a data
# background (its old paint passed the nil Widget-default @backgroundColor, a no-op), so the
# backdrop under the sheet — a window's content pane, the desktop — always showed through the
# data region, and it must keep showing through. (The F5 flesh-out's first reading — "the
# 248 in the reference is the sheet's background fill" — was FALSIFIED here: 248 is the
# WINDOW's backdrop seen through the transparent sheet; giving this panel a fill of its own
# would freeze that coincidence into the widget. The inherited PanelWdgt
# RectangularAppearance also cannot render a nil colour — it throws on every repaint — which
# is how the falsification announced itself.)
#
# It paints NO residual border either: the F5 receipts (plan §3-F) established that the
# grid's outermost right/bottom gridlines are clipped invisible today (the old strokes at
# gw+0.5/gh+0.5 rasterised one pixel past the sheet), so byte-identity demands nothing be
# drawn — the cheap-live-strokes slot here is reserved for the day a visible border is WANTED
# (a deliberate, recaptured pixel change).
#
# The PanelWdgt clipping (ClippingAtRectangularBoundsMixin, active at my bounds) is the
# viewport's standing GUARD: F1's CELL-QUANTIZED scroll reconcile keeps every visible cell
# tiling me exactly (an off-viewport cell is hidden or destroyed, never partially outside), so
# the clip crops nothing in practice — it exists so no future placement bug can ever paint a
# cell outside the data region. The frozen headers are direct sheet children, outside me,
# untouchable by it.
#
# v1 neutralisations of PanelWdgt behaviour — each preserves today's cells-parented-to-the-
# sheet semantics exactly (receipts in the F5 plan section):
#   - mouseClickLeft ESCALATES: PanelWdgt's own would bringToForeground and stop, swallowing
#     the click before the sheet's selection handler (the chain is cell → this panel → sheet);
#   - wantsDropOfChild false: F4 lands drops on CELLS; the panel between them never accepts;
#   - childrenCanLockToMe false: cells must not gain the "lock to panel" menu toggle they
#     did not have when sheet-parented;
#   - providesAmenitiesForEditing false: not an editing surface.

class SheetCellsPanelWdgt extends PanelWdgt

  providesAmenitiesForEditing: false

  constructor: ->
    super()
    # transparent (see the header): no fill, no inherited inset stroke over the cells' edge
    # pixels — the nil appearance paints nothing at all, exactly like a CellWdgt
    @appearance = nil

  colloquialName: ->
    "cells panel"

  # clicks pass through to the sheet — the selection owner (see the header)
  mouseClickLeft: (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    @escalateEvent "mouseClickLeft", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

  # drops land on CELLS (F4), never on the panel between them (the cells tile it anyway)
  wantsDropOfChild: (aWdgt) ->
    false

  # cells don't get the "lock to panel" menu toggle (they didn't have it when sheet-parented)
  childrenCanLockToMe: ->
    false
