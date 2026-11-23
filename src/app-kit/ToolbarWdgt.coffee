# The ONE shared toolbar construction (Frame-model plan §5.C): a scrollable
# strip of tool thumbnails -- a ViewportWdgt wrapping a ToolPanelWdgt grid.
# The SAME construction serves both toolbar homes, and in BOTH it is a FrameWdgt's content: FLOATING
# (a window on the desktop, built by the toolbar creator buttons / ToolbarsApp) and DOCKED (a band
# in a host frame's edge slot). The tools inside don't bind to an editor instance, which is exactly
# what lets one construction serve every home.
#
# I ANSWER ONE QUESTION -- WHO I WORK FOR (hostWindow): the window whose edge slot I occupy while I
# am docked, the person while I float (or stand inside a window as its content, which is no dock).
# Each tool resolves its own subject from that answer (hostWindowOf), by its own kind, so a toolbar
# mixing kinds is right by construction:
#   - a PROPERTY tool (bold, an alignment, a font: EditorContentPropertyChangerButtonWdgt) acts on
#     the style the editor focus hands over -- within my host's reach while I am docked, anywhere
#     while I work for the person (WorldWdgt.editorStyleSubject);
#   - a CREATOR (CreatorWdgt) places what its click makes into my host's content, or nowhere when that
#     content takes none, while I am docked; into the topmost window that takes it, else the desktop,
#     while I work for the person;
#   - a PAINT tool (CodeInjectingSimpleRectangularButtonWdgt) sets its tool on its HOLDER: my host,
#     else the person.
#
# I HOLD THE ONE REFRESH of my tools' looks (noteToolStatesChanged) and the TWO EDGES a tool's look
# can depend on (_subscribeToWhatMyToolsShow): world -> me (the selection, its style, the mode
# holding it) and world.user -> me (the hand, the person's tool code). A host window tells me itself
# when its own tool changes (FrameWdgt.armDrawingTool), and I tell myself when I dock or leave.
#
# A subclass is an ITEM LIST (_toolbarItems) and, where it differs, its docking side -- plus, for the
# paint palette, the stock tool sources.
#
# Colloquial name rides the contents: ToolPanelWdgt.viewportColloquialName
# names the whole strip "toolbar" in hierarchy menus.

class ToolbarWdgt extends ViewportWdgt

  # MY DEFAULT SIDE: which of a host frame's four edge slots my band takes when the host docks
  # me. A per-instance property with a per-TYPE class default, user-adjustable per frame via the
  # band's "Dock" context-menu submenu, which edits the band's own edge spec.
  # FLOATING is not a state this field records: I am a PAYLOAD either way (program ruling C11) --
  # what docks and floats is the frame around me, and dragging its grip onto the desktop is
  # exactly what turns a band into a window.
  dockSide: 'left'

  # a toolbar strip's scrolling is part of its design — a docked strip that
  # cannot scroll strands its off-edge buttons (see
  # ViewportWdgt.offersScrollPolicyToggle)
  offersScrollPolicyToggle: false

  constructor: ->
    super new ToolPanelWdgt
    @appearance = @createAppearance()
    @_buildAndConnectChildren()

  # I paint nothing of my own, neither a fill nor a border (one line per edge, visual-design-system
  # §4.1): every home I have is a FrameWdgt's payload -- a docked band's card, a floating
  # toolbar's window -- whose body is my background and whose outline is my edge, so a fill or a
  # border of mine would paint those lines a second time. A press anywhere in my box still lands
  # on me: the base appearance's shape is my whole box.
  createAppearance: -> new SeamRulesAppearance @

  # MY CROSS-AXIS SIZE when docked: width for left/right, height for top/bottom -- what I ask the
  # band to grant me, which the band then wraps in its own chrome. DERIVED from my grid's own cell
  # metrics (ToolPanelWdgt.naturalGridCrossExtent: one strip-depth of cells, with no padding across
  # them, so a one-row band with its card's two lines is a frame strip's 46) -- the same capability
  # the FLOATING manifestation hugs its payload with, so a band is exactly as deep as its cells
  # need and no constant anywhere says otherwise (owner ruling: one criterion for every toolbar,
  # docked or free). Answered at every measure and never recorded
  # (the band's edge spec asks me, EdgeDockLayoutSpec.thicknessGrantedTo), so a host saved and
  # loaded, or duplicated, lays its band out in the current theme. Never a laid-out size -- the
  # host's PURE measures read it through the band's spec (§6.1 rule 1), so it must not depend on
  # laid-out extents, and theme dials are not.
  dockThickness: ->
    @contents.naturalGridCrossExtent()

  # THE SHORTEST RUN I STAY USABLE AT, DOCKED: the twin of dockThickness along the band's run -- my
  # grid's one-slot run, where my overflow chevron stands whole (ToolPanelWdgt.shortestUsableRun).
  # The host whose edge slot I occupy asks it of each docked payload, as a capability, so a payload
  # that is no toolbar answers nothing (FrameWdgt.smallestExtentKeepingMyControlsUsable). Pure, like
  # dockThickness.
  shortestDockedRun: ->
    @contents.shortestUsableRun()

  # WHAT I SHOW SAYS WHAT I AM: my tools are my identity, so a frame around me needs no title while I
  # show (FrameWdgt._payloadIdentifiesItself, which adds the "while"), and with nothing to read its
  # bar is free to run down its side (FrameWdgt._runAxis). Not true of every payload: two text panes
  # look alike and only their titles tell them apart, and a menu's rows are commands like mine but
  # its title names the widget they act on, which its rows do not.
  identifiesItself: ->
    true

  # Clicking BETWEEN the buttons (the strip/grid background) must not steal the
  # editor focus pointer (world.editorFocusWdgt) from the widget being edited.
  excludedFromEditorFocusTracking: ->
    true

  # Subclass hook: the toolbar's item list. Keep every entry a literal `new X`
  # form so the boot dependency finder sees the class edges.
  _toolbarItems: ->
    []

  # MY ROSTER, EACH TOOL AT ITS OWN SIZE: a tool whose class states the size it has as a tool (toolExtent:
  # a map pin's, a speech bubble's) is given it before its cell takes it in, so that is the size the cell
  # keeps (GlassBoxBottomWdgt.toolOwnExtent) and a copy leaves at. A tool that states none comes in as it
  # is built. Only my own roster passes here: a widget a person puts into a toolbar comes in at the size
  # the person gave it.
  _rosterAtToolExtents: ->
    for tool in @_toolbarItems()
      tool._applyExtent tool.toolExtent if tool.toolExtent?
      tool

  # ===== who I work for =====

  # The window I work for: the one whose edge slot my frame occupies (FrameWdgt.dockHost), asked of my
  # frame at every asking. undefined: I work for the person -- I float, or my frame is another
  # window's content, which is no dock. Every edge-slot dock ties me, whatever the host holds.
  hostWindow: ->
    @parent?.dockHost?()

  # THE TOOLBAR A WIDGET STANDS IN: found by climbing from it, itself first, to its nearest ancestor
  # that answers whom it works for (hostWindow) -- a capability, so no tool names a toolbar class.
  # undefined when it stands in no toolbar. The one climb: who a tool works for is asked through it
  # (hostWindowOf), and so is who announces what a tool shows through a menu of its own
  # (ChangeFontButtonWdgt._fontsMenuAnnouncer).
  @toolbarOf: (aWidget) ->
    each = aWidget
    while each?
      return each if each.hostWindow?
      each = each.parent
    undefined

  # WHO A TOOL WORKS FOR, the one home every tool asks: the window the toolbar it stands in
  # (toolbarOf) works for (hostWindow). undefined when the tool stands in no toolbar or its toolbar
  # floats: the tool then works for the person.
  @hostWindowOf: (aWidget) ->
    @toolbarOf(aWidget)?.hostWindow()

  # Do I carry a DRAWING tool -- a tool that names a paint tool by its key (drawingToolKey), whatever
  # else I carry beside it? A window wearing me then holds a tool of its own (FrameWdgt
  # .armedDrawingTool), which the drawings in its content paint with.
  holdsDrawingTools: ->
    @allChildrenBottomToTop().some (each) -> each.drawingToolKey?

  # Does `aFrame` WEAR drawing tools -- does one of the payloads in its edge slots carry them? Asked
  # by a paint surface looking for its holder, and by a palette leaving a window. A frame with no
  # slots wears nothing.
  @wearsDrawingTools: (aFrame) ->
    (aFrame.dockedPayloads?() ? []).some (each) -> each.holdsDrawingTools?()

  # MY TOOLS' STATES MAY HAVE MOVED: the selection, its style or where it stands moved, or an edit
  # mode flipped (the world's announcement), the person's hand or tool code did (the user's), the window I work for
  # changed its tool (FrameWdgt.armDrawingTool), or I changed whom I work for by docking or leaving.
  # Every one of my cells re-derives its look, asking its tool (a tool with no state to show answers
  # nothing and stays at rest), the hidden ones too, so a cell my strip shows later is already right;
  # each cell passes the news on to what shows it through it (a toolbar overflow menu's row). And I
  # pass it on myself, so what shows my tools' subject THROUGH me re-reads it: the rows of my font
  # tool's Fonts menu, which name me as their announcer (ChangeFontButtonWdgt._fontsMenuAnnouncer),
  # ticked by the tool's currentFontName and enabled while it has something to act on.
  # markNonValueChange: what moved is not my value (I have none to deliver).
  noteToolStatesChanged: ->
    for cell in @contents.childrenNotHandlesNorCarets()
      cell.noteItemStateChanged?()
    world.dataflow?.markNonValueChange @
    return

  # THE TWO EDGES a tool's look can depend on, made once each (the index already knows whether I
  # hold one): world -> me, which announces the editor focus, its style, where it stands and every
  # edit-mode flip (WorldWdgt._setEditorFocusNoSettle / noteStyleChanged /
  # _keepEditingOnScreenNoSettle / noteEditModeChanged), and
  # world.user -> me, which announces the person's hand and the person's tool code (User). Both
  # firesOnAnyChange, because neither announcement is the producer's VALUE (each is a
  # markNonValueChange); I never read what is delivered, my tools re-read their subjects. There is no
  # list of toolbars anywhere: the engine's edge index is the set, and Widget._destroyNoSettle takes
  # me out of it as I die. The drain runs in the cycle's dataflow station, ahead of layout and
  # paint, so what my cells show is a function of the event stream. Then I show the state as it
  # stands, so a toolbar built, loaded or copied while a bold text is being edited shows B active from
  # the start. Made with my tools, and again by a deserialized shell and by a duplicate, neither of
  # which runs a constructor.
  _subscribeToWhatMyToolsShow: ->
    return unless world?.dataflow?
    unless world.dataflow.hasEdge world, @
      world.dataflow.addEdge world, @, action: "noteToolStatesChanged", firesOnAnyChange: true
    if world.user? and !world.dataflow.hasEdge world.user, @
      world.dataflow.addEdge world.user, @, action: "noteToolStatesChanged", firesOnAnyChange: true
    @noteToolStatesChanged()
    return

  _afterDeserialization: ->
    super
    @_subscribeToWhatMyToolsShow()

  _reactToBeingCopied: ->
    super
    @_subscribeToWhatMyToolsShow()

  # I ARRIVED in `host`'s edge slot (told by FrameWdgt._dockFrameNoSettle, my slot already mine), so
  # I work for `host` from now on and every tool of mine re-derives its look. Moving a palette changes
  # neither what it shows nor what the drawing it joins paints with: so when I carry drawing tools and
  # no other payload `host` wears does, the host adopts the person's tool as it stands, an empty hand
  # included. A host already wearing drawing tools keeps its own, which I show from now on.
  noteDockedOn: (host) ->
    if @holdsDrawingTools()
      othersHoldDrawingTools = host.dockedPayloads().some (each) => each isnt @ and each.holdsDrawingTools?()
      host.armDrawingTool world.user?.armedDrawingTool unless othersHoldDrawingTools
    @noteToolStatesChanged()
    return

  # I LEFT `host`'s edge slot by being re-homed (told by FrameWdgt._reactToChildRemoved, my slot
  # already free; never for a destroy, a re-side, a disengage or a collapse), so I work for the person
  # from now on and every tool of mine re-derives its look. The same invariant: when I carried drawing
  # tools and `host` wears none any more, the person takes the host's tool, which I go on showing, and
  # the host gives it up.
  noteUndockedFrom: (host) ->
    if @holdsDrawingTools()
      unless ToolbarWdgt.wearsDrawingTools host
        toolKey = host.armedDrawingTool
        host.armDrawingTool undefined
        world.user.armDrawingTool toolKey
    @noteToolStatesChanged()
    return

  # THE BOX A FRAME AROUND ME TAKES WHEN I FLOAT -- my grid's own natural box within the `room`
  # the frame has left after its chrome (owner ruling: a free manifestation HUGS its payload, so
  # there are no per-toolbar size constants anywhere). Answered as a capability rather than
  # claimed by a type test, so the frame asks every payload the same question and only a payload
  # with an answer sizes its window. My DOCKED manifestation asks the same grid the same way --
  # it takes the cross axis alone (dockThickness, granted through the edge-dock spec) because
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
    @_addManyNoSettle @_rosterAtToolExtents()
    # born LOCKED: a toolbar's items are template thumbnails (dragging one out
    # yields a copy), not editable content -- every home wants the drops/edits
    # lock, so the build applies it once instead of each call site.
    @_disableDragsDropsAndEditingNoSettle()
    @_subscribeToWhatMyToolsShow()

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
