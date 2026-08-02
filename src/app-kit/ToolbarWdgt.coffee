# The ONE shared toolbar construction (Frame-model plan §5.C): a scrollable
# strip of tool thumbnails -- a ScrollPanelWdgt wrapping a ToolPanelWdgt grid.
# One subclass per palette; a subclass supplies only its item list
# (_toolbarItems) and, where it differs, its docking defaults. The SAME
# construction serves both toolbar homes: FLOATING (wrapped in a FrameWdgt by
# the toolbar creator buttons / ToolbarsApp) and DOCKED (a FrameWdgt's
# toolbar-slot). The buttons inside don't bind to an editor instance -- they
# act on the focused widget or create-by-drag -- which is exactly what lets
# one construction serve every home.
#
# Colloquial name rides the contents: ToolPanelWdgt.scrollPanelColloquialName
# names the whole strip "toolbar" in hierarchy menus.

class ToolbarWdgt extends ScrollPanelWdgt

  # D9 (Frame-model plan §5.C): where this toolbar docks when it occupies a
  # frame's toolbar-slot. A per-instance property with a per-TYPE class
  # default. 'top' and 'left' have frame-arrange support; 'right' / 'bottom' /
  # 'float' are reserved values (docs/BACKLOG.md).
  dockSide: 'left'

  # The strip's cross-axis size when docked: width for left/right, height for
  # top/bottom. A CONSTANT, never a laid-out size -- the frame's PURE measures
  # read it (§6.1 rule 1), so it must not depend on laid-out extents.
  dockThickness: 95

  constructor: ->
    super new ToolPanelWdgt
    @_buildAndConnectChildren()

  # Clicking BETWEEN the buttons (the strip/grid background) must not steal the
  # editor focus pointer (world.editorFocusWdgt) from the widget being edited.
  excludedFromEditorFocusTracking: ->
    true

  # Subclass hook: the palette's item list. Keep every entry a literal `new X`
  # form so the boot dependency finder sees the class edges.
  _toolbarItems: ->
    []

  # Children are built in the core reached via the settling wrapper (the
  # check-constructors-build contract: a constructor must not @add its own
  # children inline). Constructed standalone (an orphan at each call site), the
  # wrapper's settle defers, so the batch is added NoSettle and the caller
  # settles once on attach. The batched _addManyNoSettle is deliberate: an
  # earlier measurement found it ~2x faster (avg ~5.4 ms vs ~10 ms) and
  # lower-variance than adding the widgets one at a time.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_addManyNoSettle @_toolbarItems()
    # born LOCKED: a toolbar's items are template thumbnails (dragging one out
    # yields a copy), not editable content -- every home wants the drops/edits
    # lock, so the build applies it once instead of each call site.
    @_disableDragsDropsAndEditingNoSettle()

  # A width change re-WRAPS the grid, and the base scroll-panel re-fit is
  # measure-then-commit: it reads the items' APPLIED bounds, commits the
  # contents frame from them, and only then re-places the items -- so wrapping
  # at a NEW width converges one pass late, leaving a stale contents frame at
  # the old wrap height (fg census caught it: a 2-row 75px grid frame inside
  # the 40px docked strip after a narrow->wide frame resize). Re-place the
  # items at my (already-applied) viewport width FIRST, so the base measures
  # the CURRENT wrap and the whole re-fit is a one-pass fixed point.
  _positionAndResizeChildren: ->
    @contents._reLayout @contents.bounds
    super
