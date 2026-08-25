# The ONE shared toolbar construction (Frame-model plan §5.C): a scrollable
# strip of tool thumbnails -- a ViewportWdgt wrapping a ToolPanelWdgt grid.
# One subclass per palette; a subclass supplies only its item list
# (_toolbarItems) and, where it differs, its docking defaults. The SAME
# construction serves both toolbar homes, and in BOTH it is a FrameWdgt's content: FLOATING (a
# window on the desktop, built by the toolbar creator buttons / ToolbarsApp) and DOCKED (a band
# in a host frame's edge slot). The buttons inside don't bind to an editor instance -- they
# act on the focused widget or create-by-drag -- which is exactly what lets
# one construction serve every home.
#
# Colloquial name rides the contents: ToolPanelWdgt.viewportColloquialName
# names the whole strip "toolbar" in hierarchy menus.

class ToolbarWdgt extends ViewportWdgt

  # MY DEFAULT SIDE: which of a host frame's four edge slots my band takes when the host docks
  # me. A per-instance property with a per-TYPE class default, user-adjustable per frame via the
  # frame's "dock the toolbar ➜" context-menu popout, which edits the band's own edge spec.
  # FLOATING is not a state this field records: I am a PAYLOAD either way (program ruling C11) --
  # what docks and floats is the frame around me, and dragging its grip onto the desktop is
  # exactly what turns a band into a window.
  dockSide: 'left'

  # MY CROSS-AXIS SIZE when docked: width for left/right, height for top/bottom -- what I ask the
  # band to grant me, which the band then wraps in its own chrome. DERIVED, in the constructor,
  # from my grid's own cell metrics (ToolPanelWdgt.naturalGridCrossExtent: one strip-depth of
  # cells plus the grid's margins) -- the same capability the FLOATING manifestation hugs its
  # payload with, so a band is exactly as deep as its cells need and no constant anywhere says
  # otherwise (owner ruling: one criterion for every toolbar, docked or free). Still a CONSTANT
  # per instance, never a laid-out size -- the host's PURE measures read it through the band's
  # spec (§6.1 rule 1), so it must not depend on laid-out extents, and cell dials are not.
  dockThickness: undefined

  # a toolbar strip's scrolling is part of its design — a docked strip that
  # cannot scroll strands its off-edge buttons (see
  # ViewportWdgt.offersScrollPolicyToggle)
  offersScrollPolicyToggle: false

  constructor: ->
    super new ToolPanelWdgt
    @dockThickness = @contents.naturalGridCrossExtent()
    @_buildAndConnectChildren()

  # Clicking BETWEEN the buttons (the strip/grid background) must not steal the
  # editor focus pointer (world.editorFocusWdgt) from the widget being edited.
  excludedFromEditorFocusTracking: ->
    true

  # Subclass hook: the palette's item list. Keep every entry a literal `new X`
  # form so the boot dependency finder sees the class edges.
  _toolbarItems: ->
    []

  # THE BOX A FRAME AROUND ME TAKES WHEN I FLOAT -- my grid's own natural box within the `room`
  # the frame has left after its chrome (owner ruling: a free manifestation HUGS its payload, so
  # there are no per-toolbar size constants anywhere). Answered as a capability rather than
  # claimed by a type test, so the frame asks every payload the same question and only a payload
  # with an answer sizes its window. My DOCKED manifestation asks the same grid the same way --
  # it takes the cross axis alone (@dockThickness, granted through the edge-dock spec) because
  # its long axis is the host's to force.
  naturalPayloadExtentWithin: (room) ->
    @contents.naturalGridExtentWithin room

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

  # A width change re-WRAPS the grid, and the base viewport re-fit is
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
