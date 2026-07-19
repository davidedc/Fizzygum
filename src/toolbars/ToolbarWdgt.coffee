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
  # editor focus pointer (world.lastNonTextPropertyChangerButtonClickedOrDropped)
  # from the widget being edited -- the same opt-out HorizontalMenuPanelWdgt
  # declares.
  excludedFromLastFocusTracking: ->
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
