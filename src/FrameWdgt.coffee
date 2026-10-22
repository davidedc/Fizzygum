# THE ONE CHROME CONTAINER. A frame wraps ONE payload (@contents) in the manipulation chrome a
# user handles it by — a title strip, a resize affordance, four edge slots — and MANIFESTS
# differently according to two runtime facts and nothing else (program rulings C1/C4/C12):
#
#   my LIFETIME    'persistent' (furniture: a window, a card, a docked band) or 'transient'
#                  (mid-gesture UI: a menu, a prompt). It changes mid-life — pinning IS that
#                  change — which is why it is a state here and not a class hierarchy.
#   my ATTACHMENT  free-floating on the desktop (a window: the window look, close, resizer),
#                  nested in a container (a card: the card look, no close), or held by a host's
#                  edge spec (a docked band: the card look, a grip across it, no close, no resizer).
#
# So a window, a card, a menu, a prompt and a docked toolbar are the SAME class in five states;
# a frame is stackable and dockable anywhere, and every transition (pin, nest, dock, undock,
# duplicate) is a state change or a reparent, never a rebuild.

class FrameWdgt extends Widget

  # A frame's content can transiently stick out of the frame (mid width/height
  # negotiation, mid drop), so clip at the bounds. The mixin also carries the
  # _applyMoveTo scroll-optimization override -- the repaint path a parent stack
  # takes when it moves this frame as a tracking-container child.
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  # my four edge slots, in the order my arrange places them: the two full-width bands first, so
  # the flank columns share the vertical span left between them
  @DOCK_SIDES: ["top", "bottom", "left", "right"]

  # TODO we already have the concept of "droplet" widget
  # so probably we should re-use that. The current drop
  # area management seems a little byzantine...

  # An EMPTY frame accepts drops (Widget's class default is false); the
  # ctor/reset/content paths then enable/disable per content state.
  _acceptsDrops: true

  # the title bar -- ONE child (FrameBarWdgt) owning the five title-strip
  # pieces and the title half of the skin
  bar: undefined
  # ALIASES into the bar's pieces: same instances, frame-side names -- these are
  # load-bearing contracts (MacroToolkit + the macro tests reach win.label /
  # win.closeButton / win.editButton / win.collapseUncollapseSwitchButton /
  # win.titlebarBackground; FolderWindowWdgt supplies its own closeButton;
  # showEditModeInBar drives @editButton). Kept in sync at the three mutation
  # points: build, edit-button destroy on collapse, recreate on uncollapse.
  label: undefined
  closeButton: undefined
  editButton: undefined
  collapseUncollapseSwitchButton: undefined
  titlebarBackground: undefined
  resizer: undefined
  padding: undefined
  contents: undefined
  defaultContents: undefined
  # MY FOUR EDGE SLOTS: a `side -> FrameWdgt` map, at most one docked frame per side (program
  # ruling C12). The occupant is an ordinary frame carrying an EdgeDockLayoutSpec of mine — no
  # type test, no docked SKIN: the spec owns its placement, and its card skin, its grip and its
  # missing close/resizer all derive from that. A content that declares a toolbar variant
  # (@contents.buildToolbar?()) gets it docked here at construction, and the occupant is STABLE
  # across mode flips: view mode DISENGAGES the dock (zero layout contribution, hidden) instead
  # of churning the tree. Built per instance in the constructor -- a class-level object literal
  # would be ONE map shared by every frame.
  dockedFrames: undefined

  # ===== LIFETIME: one state, two manifestations of it (program rulings C2/C3) =====
  # MY ONE LIFETIME STATE, which every transient-vs-furniture branch below reads:
  #   'transient'  — mid-gesture UI (a menu, a prompt). The next click outside me (or on a
  #                  descendant that triggers) dismisses me; a world snapshot drops me;
  #                  dismissal destroys me outright.
  #   'persistent' — furniture: a window, or a pinned pop-up. Nothing outside me dismisses me,
  #                  a snapshot saves me, and closing me re-homes me to the bin like any widget.
  # It CHANGES mid-life — pinning is exactly that change — which is why it is a state on one
  # class rather than two class hierarchies. Set through setLifetime / _setLifetimeNoSettle,
  # which is also where every consequence of the change lives. A frame is born furniture; the
  # pop-up citizens (MenuWdgt / PromptWdgt) declare 'transient' in their own constructors.
  lifetime: 'persistent'
  # Serialization: my closure mark pairs with the world.popUpsMarkedForClosure set, which is never
  # serialized, so it must not persist — a triggering menu-item click marks its menu BEFORE running
  # the action, so a menu-driven save would otherwise bake the mark into the file. (__add also
  # clears it on attach, but the file should not carry it in the first place.) A deep-copied true
  # mark (the same menu action can duplicate its own menu) is inert on the clone: it is never in the
  # world's set (no aligner puts it there), and that same __add clear wipes the field on the clone's
  # first attach. Merged up the chain by Serializer.transientsForClass — this ADDS to Widget's list.
  @serializationTransients: ["isPopUpMarkedForClosure"]
  isPopUpMarkedForClosure: false
  # the widgetOpeningThePopUp is only useful to get the "parent" pop-up.
  # the "parent" pop-up is the menu that this menu is attached to,
  # but we need this extra property because it's not the
  # actual parent. The reason is that menus are actually attached
  # to the world widget. This is for a couple of reasons:
  # 1) they can still appear at the top even if the "parent menu"
  #    or the parent object are not in the foreground. This is
  #    what happens for example in OSX, you can right-click on a
  #    widget that is not in the background but the menu that comes up
  #    will be in the foreground.
  # 2) they can appear unoccluded if the "parent widget" or "parent object"
  #    are in a widget that clips at its boundaries.
  # undefined on a window: nothing opened it.
  widgetOpeningThePopUp: undefined

  # the geometry remembered ACROSS a collapse, so uncollapsing restores what was there:
  # recorded in _beforeChildCollapsed (the un-collapsed width, and both extents) and in
  # _beforeChildUnCollapsed (the collapsed width). undefined until the first collapse.
  widthWhenUnCollapsed: undefined
  widthWhenCollapsed: undefined
  contentsExtentWhenCollapsed: undefined
  extentWhenCollapsed: undefined

  # the extent my payload had in a dock band, carried across the grab that lifts me out of it:
  # read in _beforeBeingGrabbed, applied (and cleared) in _reactToBeingGrabbed
  _payloadExtentInTheBand: undefined

  # set at the subtree's destroy ENTRY (_fullDestroyNoSettle) so the whole recursion knows
  # the window is going away -- see the note there.
  _beingFullDestroyed: undefined

  # §4.1 pure measure (Stage D): a window's preferred height-at-width, side-effect-free (no
  # @bounds write, no seam) -- it MIRRORS the steady-state _positionAndResizeChildren WITHOUT
  # mutating anything, so a parent (a stack/scroll holding this window) can MEASURE this window
  # instead of mutating-it-and-reading-the-applied-height-back. Replaces the Stage-B stub.
  #
  #   window height = content height-at-its-allotted-width + title/resizer chrome
  #
  # - chrome (== the arrange's partOfHeightUsedUp): the strip plus the body's edges and margins,
  #   and a row for the resizer when it may not overlap the contents -- chrome comes from the
  #   shared _chromeHeight (one home for the measure and the arrange).
  # - content height: when the content sets its height FREELY (a scroller / slider / document fills
  #   whatever height the window is dragged to), the height is the window's OWN height minus chrome
  #   (mirrors the contentsRecursivelyCanSetHeightFreely branch); otherwise the content DICTATES the
  #   height (wrapping text, a stack, an aspect widget), so we RECURSE into its measure at the width
  #   it gets in the window -- getWidthInStack(availW - _chromeWidth()), which reproduces the
  #   arrange's no-arg getWidthInStack() since availableWidthForContents() == width() - _chromeWidth().
  # contentsRecursivelyCanSetHeightFreely is width-independent, so testing it here (before the
  # recursion) matches the arrange's post-width-set test. A collapsed window is just its titlebar.

  # THE bar spec -- what my title bar carries, at which metrics, along which axis. ONE
  # derivation, read by the bar for BOTH its build and its arrange and by my own chrome
  # accounting, so a manifestation of a frame is a ROSTER OF PIECES and a set of dials, never
  # a bar subclass (program rulings C5/C6/C13/C15/G2/G3). The fields:
  #
  #   pieces        the strip's roster, left to right. The names before "title" lead from the
  #                 bar's left edge, the ones after it trail from its right edge, "title" takes
  #                 the span between. A free-floating frame offers "close"; a HOST-OWNED one
  #                 does not -- a host that owns my placement owns my membership, and you leave
  #                 such a host by dragging out, with right-click ➜ close as the fallback (C6).
  #   resizer       which resize affordance the frame offers: "payloadSized" (the grip, iff the
  #                 payload sizes freely) or "none". The grip answers the same free-floating
  #                 predicate itself in HandleWdgt.updateVisibility -- ONE home, so this field
  #                 states the policy the payload half adds to it.
  #   axis          the direction the strip runs. A free frame's bar is on top, always (C15).
  #   showsText     whether the title piece carries its text (a bar too thin for text does not).
  #   naturalWidth  what the bar contributes to its frame's width hug: "none" asks for nothing,
  #                 "titleText" hugs the title text.
  #   thickness / slotSize / glyphSizes / padding / ruleWidth / textHeight
  #                 the metrics, each read off the theme (G2): the strip's own thickness, the
  #                 target box a piece advances the strip by, the side of the glyph each button
  #                 piece draws inside that box, by piece name (G3: a target and its mark are
  #                 separate dials; the window controls and the pencil are two glyph sizes, and a
  #                 strip that carries no button piece names none), the inset the strip keeps
  #                 from my edges, the width of the rule the strip draws along its content-facing
  #                 edge, and the title's height. Every strip's padding is my BORDER: its
  #                 background sits inside it along my outer side (and, for a window strip, at
  #                 both ends, with its pieces), so its thickness is that border, its band and
  #                 its own rule (redesign plan §4 W1, W2). A window strip's band is one row of
  #                 abutting targets. A window title's height is its piece's own line height,
  #                 read off the piece once it exists (the theme's stand-in before).
  #   bandInset / titleInset
  #                 a pop-up header's own two, named by its spec alone: how far past my border, at
  #                 both ends, its band stops (my content padding, so the band spans exactly the
  #                 content box my rows span), and how far into the band its title text starts.
  #   fontRole      the title's font: a theme font role (family, size and weight together).
  #
  #   titleStyle    how the title strip is built and laid out: "windowBar" (the strip spans my
  #                 whole top edge inside my border, the title text centred in the span the
  #                 pieces leave) or "menuHeader" (a flat header band across my content box,
  #                 inside my border, ruled along its bottom; the title text hugs itself, starts
  #                 the title inset into the band and is centred down it).
  #
  # WHICH row applies is my LIFETIME (program ruling C4): a TRANSIENT frame is a menu and wears
  # the pop-up row -- `pieces: ["title"]` (a tap on it pins the frame), `naturalWidth: "titleText"`,
  # the menu-header metrics. A PERSISTENT one is furniture and wears the window row, whatever it
  # was born as: a pinned menu IS a window, down to its strip. Both are laid out by the same bar
  # through the same arrange. What the strip LOOKS like -- its background's appearance and colours,
  # its title's ink, its glyphs' ink -- is not the spec's: it is my look (_frameLook), which the bar
  # reads.
  _barSpec: ->
    return @_transientBarSpec() if @isTransientPopUp()
    theme = WorldWdgt.theme
    pieces = []
    pieces.push "close" if @isFreeFloating()
    pieces.push "collapse"
    pieces.push "title"
    # A DOCKED band's strip is a GRIP: take hold of it, or collapse it, and nothing else (program
    # ruling C12) -- editing what a band holds is not a band gesture, and a host that owns my
    # placement owns what my strip offers, exactly as it owns my close piece. Set free on the
    # desktop I am an ordinary window again and carry the pencil my payload's amenities call for
    # (ruling C5).
    pieces.push "edit" if !@_myEdgeDockSpec()? and (@providesAmenitiesForEditing or @contents?.providesAmenitiesForEditing)

    axis = @_barAxis()
    pieces: pieces
    resizer: if @isFreeFloating() then "payloadSized" else "none"
    axis: axis
    # a strip running along my side is too narrow for a title, so it carries pieces only
    showsText: axis is "horizontal"
    naturalWidth: "none"
    # the strip, measured from my OUTER edge: my border, one row of targets, then the strip's own
    # rule, which my payload lies past.
    thickness: theme.frameBorderWidth + theme.barIconSize + theme.barRuleWidth
    slotSize: theme.barIconSize
    glyphSizes:
      close: theme.barControlGlyphSize
      collapse: theme.barControlGlyphSize
      edit: theme.barActionGlyphSize
    padding: theme.frameBorderWidth
    ruleWidth: theme.barRuleWidth
    textHeight: @_windowTitleTextHeight()
    fontRole: theme.fonts.windowTitle
    titleStyle: "windowBar"

  # The height my window title takes in my strip: the title piece's own line height (a fitted
  # string paints its text at the TOP of the box it is granted, so the box is exactly its text and
  # the strip centres that), its line box's pitch at its set font size. My strip derives in my
  # constructor before the piece exists, and the theme's stand-in answers until then -- every
  # arrange of the strip runs after the piece is built, so the title is placed by the real height.
  _windowTitleTextHeight: ->
    title = @bar?.label
    return WorldWdgt.theme.titleBarTextHeight unless title?
    title.linePitch title.originallySetFontSize

  # WHICH DIRECTION MY STRIP RUNS (program rulings C13/C15). A free frame's bar is on TOP, always
  # -- no per-frame orientation knob, because a window whose bar could be anywhere costs more
  # predictability than it buys. A DOCKED frame's follows the shape the band gives it, and the
  # frame's shape is what changes, never the bar's meaning:
  #   EXPANDED, the strip runs ACROSS the band at its leading end -- vertical at the left end of
  # a top/bottom band, horizontal at the top of a left/right one -- so the band's thickness stays
  # the payload's alone and the grip costs only along the edge.
  #   COLLAPSED, I AM my bar, so it spans the axis the band keeps: a full-width strip for a
  # top/bottom dock, a full-height sliver for a side one.
  _barAxis: ->
    dockSpec = @_myEdgeDockSpec()
    return "horizontal" unless dockSpec?
    bandRunsHorizontally = dockSpec.side is "top" or dockSpec.side is "bottom"
    if @contents?.collapsed
      if bandRunsHorizontally then "horizontal" else "vertical"
    else
      if bandRunsHorizontally then "vertical" else "horizontal"

  # The edge spec a HOST handed me, if I am docked in one of its slots; undefined otherwise (a
  # desktop window, a card in a stack, a pop-up). The one place the "am I a band?" question is
  # asked, through the spec family's duck-typed capability query.
  _myEdgeDockSpec: ->
    return @layoutSpec if @layoutSpec?.isEdgeDock?()
    undefined

  # The POP-UP row of the same vocabulary: my strip is my header BAND -- inside my border, across
  # my content box (bandInset past the border at both ends, so it spans exactly what my rows
  # span), the title text plus a pixel of air above and below it, and below that the band's own
  # rule, its bottom edge (redesign plan §2 rule D). A tap on it pins me. Measured from my OUTER
  # edge like a window strip -- my border, the band, the rule -- so at its floor it is exactly as
  # thick as a window strip, and pinning me moves nothing below it. An UNTITLED pop-up carries no
  # strip at all: an empty roster, and a thickness of 0 so my rows start just inside my border.
  #   The band's height is read off the title piece, which hugs its own text and never
  # stretches (the bar sizes it to text and disables fitting), so this is stable applied
  # geometry, not a mutate-then-read-back. Before the piece exists -- the appearance derivation
  # runs in my constructor -- the window title's own height stands in.
  #   A titled band is floored at menuRowHeight: the tap that pins me lands on it, so it is a
  # target of the same size as a row (G3/G5), and it is one of my rows in every other respect.
  _transientBarSpec: ->
    theme = WorldWdgt.theme
    titled = !!@_titleForContents @contents
    textHeight = @bar?.label?.height() ? theme.titleBarTextHeight
    bandHeight = Math.max textHeight + 2, theme.menuRowHeight
    pieces: (if titled then ["title"] else [])
    resizer: "none"
    axis: "horizontal"
    showsText: true
    naturalWidth: "titleText"
    thickness: (if titled then theme.frameBorderWidth + bandHeight + theme.menuHeaderRuleWidth else 0)
    slotSize: theme.barIconSize
    # a pop-up strip carries no button piece, so no glyph to size
    glyphSizes: {}
    padding: theme.frameBorderWidth
    bandInset: theme.menuContentPadding
    titleInset: theme.menuHeaderTitleInset
    ruleWidth: theme.menuHeaderRuleWidth
    textHeight: textHeight
    fontRole: theme.fonts.menuHeader
    titleStyle: "menuHeader"

  # What my title contributes to my payload's OWN row width: a pop-up's rows all equalize to the
  # widest entry, and its title is one of those entries even though it lives in my chrome (the
  # spec's "titleText" natural width): the title text, and its band's title inset on both sides of
  # it (the band spans the rows' width, so this is what keeps a long title clear of the band's
  # ends). The rows panel PULLS this through the pop-up climb, so a rows panel outside a frame (a
  # list's) simply gets nothing, and so does an untitled pop-up's, which has no title piece.
  _titleEntryWidth: ->
    spec = @_barSpec()
    return 0 unless spec.naturalWidth is "titleText" and @bar?.label?
    @bar.label.width() + 2 * spec.titleInset

  # What the titlebar strip takes out of my HEIGHT -- the bar spec's own thickness when the strip
  # runs across my top, nothing when it runs down my side. The measure, the arrange and the bar
  # itself read ONE number (§6.1 rule 1).
  _titlebarHeight: ->
    return 0 unless @_barSpec().axis is "horizontal"
    @_barSpec().thickness

  # The WIDTH twin: what a strip running down my side takes out of my width, and nothing when it
  # runs across my top. Exactly one of the two is ever non-zero -- a strip has one direction.
  _titlebarWidth: ->
    return 0 unless @_barSpec().axis is "vertical"
    @_barSpec().thickness

  # ===== my body's edges =====
  # My BODY is what my border encloses, less my strip: my payload and my docked bands lie in it.
  # Its inner edge sits in from my outer edge by my STRIP's thickness on the side my strip runs
  # along (the strip spans my border, its band and its rule: _barSpec) and by my BORDER INSET
  # on every other side. Past those edges my payload keeps my BODY MARGIN, and the same margin
  # parts a band from my payload. A band stands in from those edges, on every side but the one it
  # faces my payload across, by the larger of my body margin and the theme's band inset
  # (_dockedBandInset is what the band inset adds past my margin). My body margin depends on what
  # my payload IS: a PAGE (a surface you work on, which declares wantsWindowPageGutter) keeps the
  # theme's page gutter, a PANE (a view whose edges are my lines) the theme's frame body margin.
  # My padding (_chromePadding) is border inset plus the frame body margin: a pane's inset where no
  # strip runs, whatever my payload is.

  # The part of my padding that is my border: the theme's border width, which my padding always
  # holds (_chromePadding), whatever my payload is.
  _borderInset: ->
    WorldWdgt.theme.frameBorderWidth

  # The margin my payload keeps from every inner edge of my body, a strip's rule and a docked band's
  # side included. A PAGE keeps the theme's page gutter, read here at every measure and arrange and
  # never copied into me, so a saved or duplicated window keeps the gutter of the world it lands
  # in; a PANE keeps the part of my padding past my border (the theme's frame body margin,
  # _chromePadding). Every chrome term below reads this one answer, so the measure and the arrange
  # agree whichever it is.
  _bodyMargin: ->
    return WorldWdgt.theme.windowPageGutter if @_hostsAPage()
    @padding - @_borderInset()

  # Is my payload a PAGE -- a surface you work on (a document, a canvas, a board) -- rather than a
  # PANE whose edges are my own lines? The payload's class declares it (wantsWindowPageGutter, a
  # capability asked through ?(): a payload that does not answer is a pane). Asked at every read and
  # never kept, stored or serialized, because my payload can be swapped.
  _hostsAPage: ->
    !!@contents?.wantsWindowPageGutter?()

  # THE GUTTER I KEEP AROUND `aPayload` as my page: my body margin (the theme's page gutter) when
  # aPayload is my content and a PAGE, else 0 -- around a pane, a band, my strip or a widget that is
  # not mine I keep none. A page asks it of its parent through ?() at every arrange, so content
  # spacing it keeps for itself can yield to the room I already give it (a document's items stand
  # the theme's item spacing from my body's edge, my gutter counted toward it:
  # DocumentViewportWdgt._itemInset); a parent that does not answer keeps no gutter. Read live and
  # never stored, so it follows the theme and every re-parenting.
  pageGutterAround: (aPayload) ->
    return 0 unless aPayload is @contents and @_hostsAPage()
    @_bodyMargin()

  # WHO RECEIVES A DROP ON MY BODY -- on a point of it that none of my children covers: my page
  # gutter, my border. While I keep a gutter around a PAGE that room is the page's, so a payload
  # released there goes to the page: to the child my page names as receiving drops around it
  # (receiverOfDropsAroundMe, asked through ?(): a document's stack, a stretchable page's content),
  # else to my page itself, and the page's own drop rules decide from there (a page that refuses a
  # payload refuses it in my gutter too, and the climb goes on past me as it would from me). Around
  # a pane, or a collapsed page, nobody: the climb starts at me, and I refuse drops while I hold
  # content. A point on my strip, my grip or a docked band is that child's, never mine. PUBLIC: the
  # hand asks it, through ?(), of the top widget under the pointer, where both its drop climbs start
  # (ActivePointerWdgt._dropClimbStart) and where its drop learns that a release fell in my gutter
  # (_targetReachedThroughAGutter); its dock offer and a press never ask it.
  dropReceiverForPointsOnMyBody: ->
    return undefined unless @_hostsAPage() and !@contents.collapsed
    @contents.receiverOfDropsAroundMe?() ? @contents

  # How far in from my outer TOP my body's inner edge sits: my strip, when it runs across my top
  # (it always spans my border), else my border inset.
  _bodyEdgeTop: ->
    Math.max @_titlebarHeight(), @_borderInset()

  # The LEFT twin: my strip when it runs down my side, else my border inset. My right and bottom
  # edges are always my border inset: a strip runs along my top or my left, never elsewhere.
  _bodyEdgeLeft: ->
    Math.max @_titlebarWidth(), @_borderInset()

  # Where my payload's top-left sits from mine when it fills its region: past my body's leading
  # edges, a band docked at my left or my top (with its inset), and my body margin. The arrange
  # seats it there, and a frame re-wrapping a payload in place reads the same offset
  # (floatOutOfDock).
  _payloadOffset: ->
    new Point (@_bodyEdgeLeft() + @_leftDockThickness() + @_bodyMargin()),
      (@_bodyEdgeTop() + @_topDockThickness() + @_bodyMargin())

  # Window chrome height -- everything that is NOT content: my body's top and bottom edges, my
  # body margin past each, the bands docked at my top and bottom with their insets, and -- when
  # my payload must keep clear of my resizer -- the grip's row: how far the grip reaches up from
  # my content area's bottom edge (FrameGripWdgt.footprint, its inset plus its side), so my
  # payload stops my body margin above the grip. ONE home for the measure
  # (preferredExtentForWidth) and the arrange (_positionAndResizeChildren): they MUST agree, or
  # the window's measure diverges from what its arrange then applies (assessment §6.1 rule 1).
  _chromeHeight: (spec) ->
    chrome = @_bodyEdgeTop() + @_borderInset() + 2 * @_bodyMargin() + @_topDockThickness() + @_bottomDockThickness()
    chrome += FrameGripWdgt.footprint() unless spec.resizerCanOverlapContents
    chrome

  # ===== the four edge slots' layout terms =====
  # The frame docked at one of my edges, WHEN IT COUNTS: the slot's occupant, still my child, its
  # dock engaged (view mode disengages every dock), and my body actually there to hold it -- a
  # collapsed frame is just its titlebar, so it has no body and no bands. Pure reads: the measures
  # consume these, so they never touch a laid-out extent (the band's thickness is recorded on the
  # spec).
  _dockedFrameAt: (side) ->
    return undefined if @contents?.collapsed
    dockedFrame = @dockedFrames?[side]
    return undefined unless dockedFrame? and dockedFrame.parent == @
    return undefined unless dockedFrame._myEdgeDockSpec()?.engaged
    dockedFrame

  # What a docked frame takes out of my body at `side`, past the body margin my payload offset and
  # my chrome already count at that edge: what the band's inset adds past that margin
  # (_dockedBandInset), the band it occupies, and the gap between the band and my content (my body
  # margin again). 0 for an empty, disengaged or collapsed-away slot.
  _dockThicknessAt: (side) ->
    dockedFrame = @_dockedFrameAt side
    return 0 unless dockedFrame?
    @_dockedBandInset() + dockedFrame._dockedBandThickness() + @_bodyMargin()

  # How much further a band docked in one of my slots stands in, on its three outer sides, past my
  # body margin: what the theme's dockedBandInset asks beyond that margin, and nothing once my margin
  # reaches it. So every band stands the larger of my body margin and the band inset in from my
  # body's inner edges, whatever my payload is -- a page's gutter no wider than the band inset moves
  # no band, it only parts the band from the page (its fourth side, toward my payload, keeps my body
  # margin alone). Read at every measure and arrange, never copied into me, so a saved or duplicated
  # host places its bands in the current theme. A pure dial, as the slot terms above must be.
  _dockedBandInset: ->
    Math.max 0, WorldWdgt.theme.dockedBandInset - @_bodyMargin()

  # MY OWN cross extent as a band in somebody's slot (program ruling C13): expanded, what the
  # band grants my payload (EdgeDockLayoutSpec.thicknessGrantedTo: a toolbar's own dockThickness,
  # asked now, or the extent my payload arrived with) plus my own chrome across it (my border and
  # body margin on both sides), so the payload gets exactly the extent it asked for and my grip,
  # running ACROSS the band, adds nothing; collapsed, I AM my bar, so the band is the strip's
  # thickness (never 0 -- there has to be something left to tap). 0 when I am not docked at all.
  _dockedBandThickness: ->
    dockSpec = @_myEdgeDockSpec()
    return 0 unless dockSpec?
    return @_barSpec().thickness if @contents?.collapsed
    payloadThickness = dockSpec.thicknessGrantedTo @contents
    if dockSpec.side is "top" or dockSpec.side is "bottom"
      payloadThickness + @_chromeHeight @contents.contentStackSpec()
    else
      payloadThickness + @_chromeWidth()

  # The four named terms my chrome accounting reads (one home each side, so _chromeHeight and
  # _chromeWidth stay readable).
  _topDockThickness: ->
    @_dockThicknessAt "top"

  _bottomDockThickness: ->
    @_dockThicknessAt "bottom"

  _leftDockThickness: ->
    @_dockThicknessAt "left"

  _rightDockThickness: ->
    @_dockThicknessAt "right"

  # Frame chrome WIDTH -- everything that is not content width: my body's left and right edges (a
  # strip running down my side is the left one), my body margin past each, and the bands docked
  # on either flank with their insets. The width sibling of _chromeHeight, and the ONE home the
  # measures and the arrange both read (§6.1 rule 1): availableWidthForContents, the width
  # negotiation and the first-placement hug all route through it.
  _chromeWidth: ->
    @_bodyEdgeLeft() + @_borderInset() + 2 * @_bodyMargin() + @_leftDockThickness() + @_rightDockThickness()

  # (U2) The first-placement WIDTH negotiation, as a PURE function of the spec's
  # preferredStartingWidth sentinels -- ONE home for the measure's pre-capture branch (below)
  # and the arrange's first-placement branch: they MUST agree (assessment §6.1 rule 1), or a
  # parent measuring this window mid-construction diverges from what the window's own arrange
  # then applies -- that divergence (the old flag guard reported the CURRENT, pre-negotiation
  # extent) was the root of the nested-window settle re-visits. availW = the window width the
  # caller proposes (the arrange passes its own current width).
  _negotiatedContentWidth: (availW) ->
    spec = @contents.contentStackSpec()
    if spec.preferredStartingWidth == FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW
      # (U3-C) "the size I have now" through the content's preferredExtent, not its raw
      # width(): identical for plain content (base preferredExtent IS the applied extent),
      # but content whose OWN first placement is pending (a nested window) answers with the
      # extent that placement will produce -- so this window places it at its FINAL size in
      # one shot and the settle loop's injection never has to re-visit us.
      @contents.preferredExtent().x
    else if spec.preferredStartingWidth == FrameContentLayoutSpec.DONT_MIND
      availW - @_chromeWidth()
    else
      spec.preferredStartingWidth

  # (§9.7-Q, owner-decided 2026-07-17) THE width a first placement hands the content, as a
  # pure function of MY OWN attachment -- ONE home for the arrange's first-placement branch
  # and the measure's pre-capture branch (§6.1 rule 1, same contract as _negotiatedContentWidth):
  # - my own attachment is FREE-FLOATING (a desktop window): the content gets the width it
  #   asked for (the sentinel negotiation above) and the window HUGS it -- unchanged.
  # - I am CONTAINER-OWNED (window content / stack element): THE CONTAINER OWNS MY WIDTH.
  #   I never self-resize to the content, and the content gets the same container-derived
  #   width a captured window would hand it (getWidthInStack is total pre-capture, U2) --
  #   a container-owned window sizes like a captured one FROM BIRTH. This deletes the
  #   first-placement shrink->re-widen width ping-pong structurally (suite-verified
  #   byte-identical: every suite-covered hug of a container-owned window was anyway
  #   reasserted to exactly this width by its container's re-fit).
  _firstPlacementContentWidth: (availW) ->
    if @isFreeFloating()
      @_negotiatedContentWidth availW
    else
      @contents.contentStackSpec().getWidthInStack availW - @_chromeWidth()

  # (U3-C) A window whose first placement is PENDING (content spec uncaptured) answers
  # preferredExtent with the extent that placement will produce -- the PURE mirror of the
  # arrange's first-placement branch (width: the negotiation + padding + the not-freefloating
  # clamp; height: the pre-capture measure at that width, which mirrors the height sentinels).
  # A collapsed-content or captured (steady-state) window IS its applied extent, like any
  # plain widget. Recursion (a window in a window in ...) terminates at plain content.
  preferredExtent: ->
    spec = @contents?.contentStackSpec()
    if !spec? or spec.desiredWidth? or @contents.collapsed then return @extent()
    if @isFreeFloating() and spec.preferredStartingWidth != FrameContentLayoutSpec.DONT_MIND
      # the width hug (DESKTOP windows only -- §9.7-Q, same own-layoutSpec predicate as the
      # arrange's first-placement branch, incl. the not-recursively-freefloating min-clamp;
      # keep the two in lockstep)
      windowWidth = @_negotiatedContentWidth(@width()) + @_chromeWidth()
      if !@recursivelyAttachedAsFreeFloating()
        windowWidth = Math.min @width(), windowWidth
    else
      # container-owned (or DONT_MIND): the width stays what the container hands me
      windowWidth = @width()
    new Point windowWidth, @preferredExtentForWidth(windowWidth).y

  preferredExtentForWidth: (availW) ->
    if @contents? and !@contents.collapsed
      spec = @contents.contentStackSpec()
      # A content transiently WITHOUT its layoutSpec (mid drop/delete) has no derivable measure --
      # keep the measure total and report the current extent.
      if !spec? then return new Point (availW ? @width()), @height()
      chrome = @_chromeHeight spec
      if !spec.desiredWidth?
        # FIRST placement hasn't run yet -- the spec capture is the one-shot latch (U2; this
        # branch replaced the deleted contentNeverSetInPlaceYet guard). Mirror the arrange's
        # first-placement negotiation PURELY, so an outer container measuring this window
        # DURING construction already sees the extent the window's own arrange will take --
        # not the garbage pre-negotiation extent the old guard reported. The recursion into
        # the content's measure is safe pre-capture: getWidthInStack is total (U2).
        if spec.preferredStartingHeight == FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW
          # (U3-C) through preferredExtent, not raw height() -- see _negotiatedContentWidth
          desiredHeight = @contents.preferredExtent().y
          if !@recursivelyAttachedAsFreeFloating()
            desiredHeight = Math.min desiredHeight, @height() - chrome
        else if spec.preferredStartingHeight == FrameContentLayoutSpec.DONT_MIND
          desiredHeight = Math.round @height() - chrome
        else
          # (§9.7-Q) through the shared first-placement width -- container-owned windows
          # measure at the container-derived width, desktop windows at the negotiated one,
          # exactly as the arrange will apply (lockstep via _firstPlacementContentWidth).
          desiredHeight = @contents.preferredExtentForWidth(@_firstPlacementContentWidth(availW ? @width())).y
        return new Point (availW ? @width()), desiredHeight + chrome
      if @contentsRecursivelyCanSetHeightFreely()
        desiredHeight = Math.round @height() - chrome
      else
        recommendedElementWidth = spec.getWidthInStack(availW - @_chromeWidth())
        desiredHeight = @contents.preferredExtentForWidth(recommendedElementWidth).y
      return new Point availW, desiredHeight + chrome
    else if @contents?.collapsed
      return new Point availW, @_titlebarHeight()
    return new Point availW, @height()

  # `contents` (the widget this window wraps) is the one meaningful argument; every call site
  # passes only it. closeButton is optional, supplied via the opts object (FolderWindowWdgt
  # injects its own). The former `internal` / `alwaysShowInternalExternalButton`
  # positional args are GONE (P5 arg-object conversion): internal-ness is DERIVED from parentage
  # (see isInternal) and the internal/external switch button is gone, so both were inert — neither
  # was ever bound to `@`, stored, or serialized.
  constructor: (@contents, opts = {}) ->
    super()
    @closeButton = opts.closeButton

    @defaultContents = new FrameContentsPlaceholderText
    if !@contents?
      @contents = @defaultContents
    else if @contents._contentStackSpec?.isFrameContentSpec?()
      # (U2 re-arm, constructor edition) ctor-supplied content may be a VETERAN
      # of a previous windowed life (the bin: closed with its window destroyed,
      # then re-wrapped fresh at the next open), carrying a spec still LATCHED
      # and still BOUND (@stack) to the dead window -- widths would then be
      # granted from the dead frame's frozen geometry (the reopened-bin bug,
      # 2026-07-23). Un-latch exactly as the public add does for a cross-window
      # remount (see add's isSameContentRemount note): this mount's first
      # placement then re-captures and re-binds. A fresh spec is already
      # unlatched, so this is a no-op for the universal fresh-content case.
      @contents._contentStackSpec.desiredWidth = undefined

    @dockedFrames = {}
    @padding = @_chromePadding()
    # TODO this looks better:
    #@padding = 10
    # I am born in my look's body (the one derivation that decides it); my strip, built next, is
    # skinned by its own build. A pop-up citizen declares its lifetime before this constructor
    # runs, so a menu is born in the menu box.
    @_deriveAndSetBodyAppearance()
    @_buildAndConnectChildren()

    if @contents == @defaultContents
      @_setEmptyWindowLabelNoSettle()
    else
      @disableDrops()
      # an UNTITLED pop-up carries no title piece at all, so there is nothing to title
      @_retitleNoSettle @_titleForContents @contents

    # settled-after-new: SETTLE the starting extent as the constructor's LAST act (was
    # @_applyExtent, which left a pending re-fit -- and, for default contents, the
    # _setEmptyWindowLabelNoSettle label too -- so `new FrameWdgt` returned UNsettled). This flushes both.
    # Kept on the public setExtent rather than folded into _buildAndConnectChildrenNoSettle: that core is
    # SHARED with the rebuild-on-drop paths, which must NOT reset a user-resized window back to its default.
    @setExtent @_initialExtent()

  # The extent I take at construction. A window opens at a default size the opener then imposes
  # over; a frame born TRANSIENT is mid-gesture UI, sized by what it holds from the moment it
  # exists, so `new MenuWdgt` hands back something with a real extent rather than a placeholder one.
  _initialExtent: ->
    if @isTransientPopUp()
      @preferredExtent()
    else
      new Point 300, 300

  # SIZE ME TO MY PAYLOAD -- the one derivation a free-floating home with a self-measuring payload
  # uses instead of a number from its opener (owner ruling: a floating toolbar hugs its cells, one
  # criterion for every toolbar). The payload names its own box within the ROOM I have left, which
  # is the world minus my chrome: C10's never-bigger-than-the-world, handed to the payload as a
  # budget so a payload that must give something up knows exactly how much there is.
  #   Capability-dispatched (the isFrame?() idiom): a payload with no answer is untouched, so this
  # is a door a payload opts into, never a type test here.
  sizeToPayloadNaturalExtent: ->
    return unless @contents?.naturalPayloadExtentWithin?
    spec = @contents.contentStackSpec()
    return unless spec?
    chromeWidth = @_chromeWidth()
    chromeHeight = @_chromeHeight spec
    room = new Point (world.width() - chromeWidth), (world.height() - chromeHeight)
    payloadExtent = @contents.naturalPayloadExtentWithin room
    @setExtent new Point (payloadExtent.x + chromeWidth), (payloadExtent.y + chromeHeight)

  # MY PADDING: my border (a payload lies inside the outline I stroke over it) plus the theme's
  # frame body margin past it -- how far a PANE payload sits in from my OUTER edge where no strip
  # runs (see "my body's edges" for how the strip side and a docked band read it). The same for
  # every manifestation: a pop-up's rows lie inside my border like any pane, and the padding they
  # keep inside it is their rows panel's own (the pop-up's content padding, handed to its
  # CommandPanelWdgt). Read once, at construction, and kept as my padding whatever my payload is: a
  # PAGE payload's margin is the theme's page gutter, which _bodyMargin reads at every measure in
  # place of this.
  _chromePadding: ->
    theme = WorldWdgt.theme
    theme.frameBorderWidth + theme.frameBodyMargin


  # in general, windows just create a reference of themselves and
  # that is it. However, windows containing a ScriptWdgt create
  # a special type of reference that has a slightly different icon
  # and when double-clicked actually runs the script rather than
  # bringing up the script
  # (the trailing opts rides through — the arrow-contract declaration, plan §4.4)
  createReference: (placeToDropItIn = world, referenceName, opts = {}) ->
    # ScriptWdgt content yields a special script shortcut (runs the script on double-click);
    # any other content falls to the default reference via super. The content type decides via
    # specialFrameReferenceShortcut instead of `@contents instanceof ScriptWdgt`.
    # (type-test-elimination campaign)
    widgetToAdd = @contents?.specialFrameReferenceShortcut?(@, referenceName, opts)
    if widgetToAdd?
      # this "add" is going to try to position the reference
      # in some smart way (i.e. according to a grid)
      placeToDropItIn.add widgetToAdd
      widgetToAdd.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
      @bringToForeground()
    else
      super

  # The core's shortcut-class seam (Widget._buildShortcutWidget): my content's specialization
  # must hold on the paths that never reach the menu override above — a folder-drop FILING and
  # the save-close prompt both route through _createReferenceAndCloseNoSettle, so a filed script
  # window keeps its script-ness (a run-on-double-click ScriptShortcutWdgt, not a plain document
  # shortcut). Content without a specialization falls to the base document shortcut.
  _buildShortcutWidget: (referenceName, opts) ->
    @contents?.specialFrameReferenceShortcut?(@, referenceName, opts) ? super referenceName, opts


  # A window is "internal" -- drawn with the flat, embedded title-bar skin and called an
  # "internal window" -- exactly when it is NESTED inside a real container: its parent is
  # neither the desktop (world) nor the hand (world.hand, its transient parent while being
  # float-dragged). DERIVED from parentage rather than a stored flag, so the skin simply
  # FOLLOWS where the window lives -- drag it into a container and it reads internal, out to
  # the desktop and it reads external -- re-applied on every (re)parenting by _reactToBeingAdded.
  # This is what let us delete makeInternal / makeExternal and the manual internal/external
  # switch button: nesting a window (drag-with-dwell) or ejecting it (drag-out, Phase 3 rule
  # flip) now updates the skin automatically, no toggle needed.
  isInternal: ->
    # A sugar island -- the transient TransformFrameWdgt that setRotationDegrees/setScaleFactor wraps a
    # widget in to tilt/scale it -- is an IMPLEMENTATION DETAIL of "this window is tilted", NOT a real
    # container the window was nested into. Classify against my REAL container (through any sugar wrap):
    # tilting an EXTERNAL window keeps it external (true parent still world), a tilted INTERNAL window keeps
    # it internal (true parent still the real container). The look-through idiom is shared with
    # BinWdgt.holds (§7.5 Bug A/B) -- one _parentThroughIslands, not a bespoke check per site.
    # Option B (latent 2): the look-through also climbs EXPLICIT sole-content islands, so an
    # explicitly-islanded window on the desktop reads EXTERNAL (its real home is the world).
    p = @_parentThroughIslands()
    p? and p isnt world and p isnt world?.hand

  # The window title a (re)mounted content yields -- ONE home for the ctor and
  # _addNoSettle title sites. A framed CITIZEN (a FrameWdgt subclass that IS its
  # kind -- Frame-model plan §5.B) overrides this to its own colloquialName: the
  # kind names the window, not the generic payload inside it.
  _titleForContents: (aWdgt) ->
    titleToBeSet = aWdgt.colloquialName()
    if titleToBeSet == "window"
      titleToBeSet = "window with another " + titleToBeSet
    if titleToBeSet == "internal window"
      titleToBeSet = "window with an " + titleToBeSet
    titleToBeSet

  # The name my title strip carries, as stored (the display case is my title piece's, not the
  # name's). A ROW of a pop-up asks its pop-up for this to prefix the question its prompt opens with
  # ("rectangle\nalpha\nvalue:", CommandPanelWdgt.promptTitleAsking), which is why it is public: the
  # asker is the row, several classes away. The citizens answer their own kind of title.
  titleText: ->
    @_titleForContents @contents

  # HOW MY TITLE SHOWS: the display case my strip's title piece wears (StringWdgt.displayCase) over
  # the words my title stores, which stay as they are for every reader of them -- a pinned menu's
  # window title, a prompt's title built from a menu's, a saved file's name. The ONE place the case
  # is decided: my bar builds every title piece in it, in either style, and I re-assert it whenever
  # I re-title. A pop-up's header that NAMES something shows in capitals ("RECTANGLE", "DESKTOP",
  # "FONTS"); every other title reads as a sentence, its first character a capital: a window's, a
  # pinned or collapsed one's, a card's, a prompt's question and a pop-up's message.
  _titleDisplayCase: ->
    if @isTransientPopUp() and @_headerIsAName() then "upper" else "sentence"

  # Does my pop-up header NAME something (a widget, a section, a chooser), rather than say
  # something? A plain frame is never a pop-up, and a prompt's header is the question it asks, so
  # neither does; a menu says per title (MenuWdgt).
  _headerIsAName: ->
    false

  # Re-derive the bar title from my CURRENT contents' colloquialName. Intent-named public
  # note (the noteWallpaperChanged idiom) for a contents whose ANSWER to colloquialName
  # changes after the mount captured it — the materialize homes an EMPTY island into me
  # before its content moves in (the load-bearing skin-derivation order), so the island
  # nudges me here once it holds the content its lens name reads through to. Non-settling
  # label core: the nudge arrives inside the add's own settle (same reason as the
  # _addNoSettle title site).
  noteContentsNameMayHaveChanged: ->
    return unless @contents? and @contents != @defaultContents
    @_retitleNoSettle @_titleForContents @contents

  # A title that carries a NAME (a shortcut bringing me up names me by its caption,
  # ShortcutWdgt._bringUpReferencedWidgetNow): my content's kind, then the name after a dash, as
  # stored -- "folder — Examples", shown "Folder — Examples" in my title's display case
  # (visual-design-system §4.9; the inspector titles are stored the same way).
  setTitle: (newTitle) ->
    @_settleLayoutsAfter => @_retitleNoSettle @contents.colloquialName() + " — " + newTitle

  setTitleWithoutPrependedContentName: (newTitle) ->
    @_settleLayoutsAfter => @_retitleNoSettle newTitle

  # THE ONE WAY MY TITLE'S TEXT CHANGES, through the non-settling label core: every title write of
  # mine comes here. The text is an INPUT to my strip's arrange -- FrameBarWdgt._layOutTitleInStrip
  # grades how much of it survives the box it is granted, and a strip whose title gives itself up
  # centres its pieces -- so new text re-lays my strip. My label is fitted to that box, so its own
  # text change invalidates nothing above it. An untitled pop-up carries no title piece, so there is
  # nothing to re-title. The text is shown in my title's display case (_titleDisplayCase), asserted
  # before the text is set so the label measures the shown form; a change of case alone re-lays my
  # strip too, since it changes what shows.
  _retitleNoSettle: (newTitle) ->
    return unless @label?
    titleBefore = @label.text
    caseBefore = @label.displayCase
    @label._setDisplayCaseNoSettle @_titleDisplayCase()
    @label._setTextNoSettle newTitle
    @bar?._invalidateLayout() unless @label.text is titleBefore and @label.displayCase is caseBefore

  representativeIcon: ->
    if @contents == @defaultContents
      return super
    else
      return @contents.representativeIcon()

  # paintingOverlay() capability chain (§5.D): a paint toolbar resolving its
  # injection target asks the frame, which asks its content
  # (container -> canvas -> glass). Frames over non-paintable content answer
  # undefined through the ?.
  #   A DOCKED BAND answers its HOST'S surface: a band's own content is the toolbar, so asking it
  # alone would say "nothing paintable" for the one arrangement where the paintable thing is
  # certain -- the strip is chrome the host is wearing, and the surface its tools act on is the
  # host's content. A FLOATING toolbar's frame is docked in nothing and still answers undefined,
  # which is what routes a floating press to the focus pointer instead
  # (PaintToolbarWdgt.resolveInjectionTarget).
  paintingOverlay: ->
    ownAnswer = @contents?.paintingOverlay?()
    return ownAnswer if ownAnswer?
    return undefined unless @_myEdgeDockSpec()?
    @parent?.paintingOverlay?()

  # The close-from-bar POLICY (Frame-model plan §5.E E2): a tracked field replaces
  # the per-instance `closeFromFrameBar = -> …` monkey-patches the sample/info
  # factories used to inject (InfoDocs._buildInfoDocNextTo's own TODO:
  # "should be done using a flag ... the source is not tracked"). 'saveOrAsk'
  # (default) runs the per-kind hook below; 'close'/'destroy' are the one-shot
  # sample/info behaviours -- a property, not injected code.
  closeFromFrameBarPolicy: 'saveOrAsk'

  closeFromFrameBar: ->
    switch @closeFromFrameBarPolicy
      when 'close' then @close()
      when 'destroy' then @destroy()
      else @_closeFromFrameBarWhenSaveOrAsk()

  # The 'saveOrAsk' hook. Base = a plain frame lets its CONTENT decide how to
  # close (ScriptWdgt/ErrorsLogViewer/BinWdgt/generic windows, via
  # Widget.closeFromContainerFrame); the document/panel citizens override this
  # with @_saveOrAskThenCloseCitizen, and FolderWindowWdgt with its own variant.
  _closeFromFrameBarWhenSaveOrAsk: ->
    @contents?.closeFromContainerFrame @

  # Shared save-or-ask-then-close for the document/panel citizens (§5.E E2: the
  # body was duplicated verbatim on DocumentWdgt + GenericPanelWdgt). Template
  # method: it calls the per-kind @hasStartingContentBeenChangedByUser(). No real
  # contents to save -> fullDestroy; else the save prompt; else just close.
  _saveOrAskThenCloseCitizen: ->
    # public-call-sanctioned + nosettle-sanctioned: this IS the close-from-bar
    # action (a top-level bar-button event handler); @fullDestroy / @close are the
    # public self-settling close verbs it legitimately triggers -- exactly as the
    # public closeFromFrameBar it was extracted from did (this dedup only moved the
    # shared body down a level). Reaching the NoSettle cores would leave the world
    # unsettled after a top-level bar press.
    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceOrWireIntoWdgt @
      @fullDestroy()
    else if !world.anyReferenceOrWireIntoWdgt @
      prompt = new SaveShortcutPromptWdgt @, @
      prompt.popUpAtHand()
    else
      @close()

  # The title-bar buttons announce their press to their holder (the bar, which
  # forwards here) instead of testing `@parent instanceof FrameWdgt` themselves
  # -- the frame owns what its bar buttons MEAN. closeButtonInBarPressed mirrors
  # the old button branch exactly (a contents-bearing window closes from the
  # bar, an empty one just closes); a non-bar container of a close button has no
  # such method, so that button falls back to Widget.close().
  # (type-test-elimination campaign; A2b routes the asks through FrameBarWdgt.)
  closeButtonInBarPressed: ->
    if @contents? then @closeFromFrameBar() else @close()

  editButtonInBarPressed: ->
    @contents?.editButtonPressedFromFrameBar?()

  collapseButtonInBarPressed: ->
    @contents.collapse()

  uncollapseButtonInBarPressed: ->
    @contents.unCollapse()

  # duringReInflation: true ONLY for the one synchronous re-fit inside _reactToChildUnCollapsed --
  # the content must KEEP its just-restored extent instead of being stretched to a mid-restore
  # window height; every other caller (incl. the preferredExtentForWidth measure) takes the
  # default false. History/rationale: docs/archive/upedge-endgame-plan.md §9-E4.
  contentsRecursivelyCanSetHeightFreely: (duringReInflation = false) ->
    # instead of `!(@contents instanceof FrameWdgt)` (type-test-elimination campaign)
    if !@contents.isFrame?()
      # FIT_BOX_TO_TEXT content drives its OWN height from its wrapped text, so the
      # window must FOLLOW that height (shrinking when a widen re-wraps to fewer
      # lines), not stretch the content to fill a freely-dragged height. A
      # SimpleTextWdgt already forces this via its content spec's canSetHeightFreely
      # = false in its ctor; keying off the mode generalizes it to any contained
      # TextWdgt (a non-text content has no fittingSpec, so this is a no-op for it).
      if @contents.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT then return false
      return (@contents.contentStackSpec().canSetHeightFreely and !@contents.isInCollapsedSubtree()) and !duringReInflation
    return @contents.contentsRecursivelyCanSetHeightFreely()

  recursivelyAttachedAsFreeFloating: ->
    if @isFreeFloating()
      return true

    if @parent?
      # instead of `@parent instanceof FrameWdgt` (type-test-elimination campaign)
      if @parent.isFrame?()
        return @parent.recursivelyAttachedAsFreeFloating()

    return false


  # A FRAME is the DELIBERATE-EMBED payload class (drag-embed spec §4): dropping one into a container
  # must be armed by a dwell (spec §6), so a frame is never nested by accident during the constant
  # move-a-window gesture. (Overrides Widget's plain default.)
  #   ONE rule for every frame, whatever it was born as (program ruling C8): taking hold of a menu
  # already makes it furniture, so carrying it onwards is the same move-it-around gesture a window's
  # drag is, and it passes over containers on the way exactly as often.
  requiresDeliberateEmbedding: ->
    true

  # A frame does NOT impose its ratio on dropped children (was the
  # `!(whereIn instanceof FrameWdgt)` exclusion in the ratio mixin /
  # Example3DPlotWdgt) -- but it DOES release the constraint when a child is
  # grabbed back out, exactly as a stack does. The ratio mixin queries the
  # holder via ?(), so an absent release method would silently stop releasing.
  # (type-test-elimination campaign; the release was inherited from the stack
  # until the A2a de-inherit made it explicit.)
  imposesRatioConstraintOnDroppedChildren: ->
    false

  releasesRatioConstraintOnGrabbedChildren: ->
    true

  # Re-title the (content-less) window through the NON-settling label core (hence the NoSettle
  # name): reached either during construction (orphan -> deferred) or from _resetToDefaultContents
  # inside a close/destroy settle, so the enclosing settle flushes it -- a self-settling setText
  # would open a nested settle mid-pass. (The label is fitted to its box, so the swap moves no
  # geometry of its own; _retitleNoSettle re-lays the strip, whose arrange grades the title.)
  _setEmptyWindowLabelNoSettle: ->
    # a strip too narrow for text carries no title piece, so there is nothing to title
    if @isInternal()
      @_retitleNoSettle "empty internal window"
    else
      @_retitleNoSettle "empty window"

  # Polymorphic replacement for `instanceof FrameWdgt`: lets Widget / the smart-placer
  # ask "are you a window?" without naming this subclass. Defined ONLY here -- there is NO
  # Widget base default (Widget is the God class under decomposition), so every call site
  # dispatches via `?()` and a non-window answers undefined (falsy). (type-test-elimination campaign)
  isFrame: -> true

  # Role query, the frame-side twin of ViewportWdgt.isMyContentsPanel: is aWdgt my WHOLE CONTENT
  # (@contents, the payload my chrome wraps -- never my strip, my grip or a docked band)? A panel or
  # viewport asks it of its parent as it paints (PanelWdgt / ViewportWdgt / VerticalStackPanelWdgt
  # ._surfaceStroke): along my content my border and my strip's rule are the line, so the content
  # wears the window content's border role -- derived from where it stands at every paint, so it
  # follows every re-parenting and is never stored. Only a frame answers (?.()-dispatched).
  isMyContents: (aWdgt) ->
    aWdgt is @contents

  colloquialName: ->
    if @isInternal()
      return "internal window"
    else
      return "window"

  # What tells me from another window on a row that names me (Widget.distinguishedRowName): my
  # title as my strip SHOWS it ('Window "Docs Maker"'). Nothing when I show no title, or when my
  # name already says it — a menu's and a prompt's name quote their title, a Maker's name is its
  # title — where it would tell nothing more.
  _rowNameDistinction: ->
    return undefined unless @label?
    title = @label.transformTextOneToOne @label.text
    return undefined if @colloquialName().toLowerCase().includes title.toLowerCase()
    title

  # The re-fit chokepoint (the `_reLayoutChildren?` size-tracking marker keys off this
  # definition): re-fit chrome + content via the frame's own arrange below.
  _reLayoutChildren: ->
    @_positionAndResizeChildren()

  # Stack-pattern deferred re-fit (A2a: was inherited from the stack): super applies my
  # own bounds first (bounds-first rule), then the arrange, then re-place the
  # corner-internal overlays at the FINAL frame -- the arrange may have re-committed my
  # own height after super's corner tail already placed them (idempotent when not).
  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()
    @_reLayoutCornerInternalChildren()

  # Pinned false, NOT derived: defining _reLayout above would flip the derived answer
  # and mis-route the two read sites (_setWidthSizeHeightAccordingly's invalidate +
  # subWidgetsMergedFullBounds) -- the same pin the stack carries.
  implementsDeferredLayout: ->
    false

  # The width this frame offers its content -- consumed by the content's spec
  # (FrameContentLayoutSpec / VerticalStackLayoutSpec call
  # `@stack.availableWidthForContents()`, and for frame content that "@stack" IS
  # this frame). (A2a: was inherited from the stack.) Routed through
  # _chromeWidth so a band docked on either flank -- and a strip running down my
  # own side -- narrows the content everywhere the specs read it.
  availableWidthForContents: ->
    @width() - @_chromeWidth()

  # A window fits its OWN width to its content -- but ONLY in the FIRST-PLACEMENT branch of its
  # arrange (the steady-state branch re-fits height alone, exactly like a stack), and -- post
  # §9.7-Q (rule B2+D, owner-decided 2026-07-17) -- ONLY when the window is itself attached
  # FREE-FLOATING: a CONTAINER-OWNED window never self-resizes its width (its container owns it,
  # see the first-placement branch's own-layoutSpec gate in _positionAndResizeChildren). So this
  # capability -- "re-laying me synchronously while my container is mid-arrange may re-negotiate
  # my width, diverging from my normal independent settle" (the historical failure: an outer
  # window's early settle collapsed an inner window to its content's aspect width) -- DERIVES
  # from BOTH one-shot states: TRUE only while the content spec is uncaptured (first placement
  # pending, U2-B) AND my own attachment is free-floating (the only case whose first placement
  # touches my width). A captured window is height-only under re-lay; so is a container-owned
  # window even pre-capture -- both safe to early-settle single-pass in
  # FrameWdgt._positionAndResizeChildren. Narrowing the pre-capture term to own-FF is what
  # retires the LAST nested-window settle re-visits: a first-placement inner window now settles
  # inside its outer's arrange instead of on its own later turn + an up-edge re-visit of the
  # outer (up-edge endgame V1-b, docs/archive/upedge-endgame-plan.md §9). Absent (undefined via ?()) on
  # a stack, whose synchronous re-lay keeps its container-assigned width.
  _reLayoutMayResizeOwnWidth: ->
    @isFreeFloating() and !@contents?.contentStackSpec()?.desiredWidth?

  # opts.notContent -- add as CHROME, not as my content: skip the title/@contents bookkeeping below.
  # The frame is the only receiver in the add family that acts on it.
  add: (aWdgt, opts = {}) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, opts

  # _addNoSettle -- the non-settling core of add() (mirrors Widget.add/_addNoSettle).
  # Folds in the frame's content bookkeeping (title, @contents swap, spec init +
  # first-placement re-arm) so the build/teardown chain (_buildAndConnectChildrenNoSettle)
  # adds chrome + content WITHOUT flushing layouts: super reaches Widget._addNoSettle
  # directly (A2a de-inherit), all non-settling. Adding @contents through THIS core (vs
  # the bare base _addNoSettle) is exactly what keeps the content wired by the deferred re-fit.
  _addNoSettle: (aWdgt, opts = {}) ->
    # opts.dockSide -- the incoming widget takes one of my EDGE SLOTS, not my content slot: the
    # hand's drop-to-dock names the side the release resolved to, and the dock core arms the edge
    # spec that places it. One structural entry, one option, so a docked arrival is the same add
    # every other arrival is.
    return @_dockFrameNoSettle aWdgt, opts.dockSide if opts.dockSide?
    notContent = opts.notContent
    # the polymorphic strip-spacing hook (a base no-op; some widget types override
    # it) runs on every add, mirroring the stack's add core.
    aWdgt._resizeToWithoutSpacing()
    # caret + handle are the layout decorations (was their two instanceof) (type-test-elimination campaign)
    unless notContent or aWdgt.isLayoutInert?()
      # re-title through the NON-settling label core: _addNoSettle already runs inside the
      # add's settle, so the title change rides that flush instead of opening a nested one.
      # An untitled pop-up carries no title piece, so there is nothing to re-title.
      @_retitleNoSettle @_titleForContents aWdgt
      # (§9.7-Q, owner-decided 2026-07-17) a chrome rebuild (_buildAndConnectChildrenNoSettle,
      # reached from _reactToChildDropped / _resetToDefaultContents) re-adds the widget that
      # is ALREADY my content. That is bookkeeping, not a re-mount: the placement it would
      # re-negotiate was just negotiated in the same flush, so re-arming for it only produced
      # a duplicate first-placement pass (one settle re-visit per drop, probe-verified).
      isSameContentRemount = aWdgt == @contents
      # detach the OLD occupant -- but only if it is actually MY child:
      # TreeNode.removeChild clears node.parent unconditionally, so in the ctor
      # case (@contents pre-assigned to the incoming widget) removing a widget
      # that still belongs to ANOTHER parent would clobber that parentage --
      # Widget._addNoSettle below would then see no previousParent, so the real
      # old parent would neither be notified (_reactToChildRemoved, its re-fit)
      # nor have its children list cleaned by __add. It matters wherever a ctor
      # is handed a widget that still has a home.
      @removeChild @contents if @contents.parent == @
      @contents = aWdgt
      # Deferred-layout (capstone probe): the window-content re-fit now DEFERS to the settle cycle
      # (super -> _addNoSettle invalidates the window; the inherited _reLayout runs @_reLayoutChildren on
      # the recalculateLayouts pass). The old synchronous pre-fit (@_reLayoutChildren here) is removed.
      # Init the content's FrameContentLayoutSpec up-front -- the pre-fit used to do this implicitly
      # via _positionAndResizeChildren, so without it the deferred re-fit would deref an uninitialised spec.
      aWdgt.initialiseDefaultFrameContentLayoutSpec() unless aWdgt._contentStackSpec?.isFrameContentSpec?()
      # a kept spec may come from a STACK life (attachedAsFrameContent flipped false by the
      # stack's adoption) — this mount makes it frame content again
      aWdgt._contentStackSpec.attachedAsFrameContent = true
      # (U2) re-arm the first-placement ONE-SHOT for this mount: content (re)mounted into a
      # window re-negotiates its placement. The old model re-ran the capture via
      # the contentNeverSetInPlaceYet flag; the CAPTURE is now itself the latch, so un-latch it
      # (a fresh spec is already unlatched; this covers content carrying a spec from a prior
      # life) -- but NOT for a same-widget chrome-rebuild re-add (§9.7-Q above): the standing
      # capture is exactly the placement this mount already has.
      aWdgt._contentStackSpec.desiredWidth = undefined unless isSameContentRemount
      super aWdgt, Object.assign {}, opts, layoutSpec: aWdgt._contentStackSpec
    else
      super aWdgt, opts
    @resizer?._moveInFrontOfSiblings()

  # (A2a, was inherited from the stack) membership-change re-fit -- same
  # absorb-or-refit contract as the inline in _reactToChildDropped below.
  #   A departing SLOT OCCUPANT frees its slot here: the grab that lifts a docked frame out
  # re-homes it and notifies me, and a slot still pointing at a child that lives somewhere else
  # would reserve a band for it forever.
  _reactToChildRemoved: (child) ->
    @_freeDockSlotOf child
    return if @parent?._reLayOutAfterContainedPanelChange?()
    @_reFitContainer()

  # Forget a slot's occupant, wherever it went (dragged out, destroyed, re-docked elsewhere).
  _freeDockSlotOf: (child) ->
    for side in FrameWdgt.DOCK_SIDES
      delete @dockedFrames[side] if @dockedFrames?[side] == child
    return

  _beforeChildDestroyed: (child) ->
    # NOT while I myself am being torn down: the rebuild would re-title a bar the
    # destroy-until-empty iteration has already destroyed and detached, and mount a
    # placeholder that iteration can never reach -- alive, unowned, and pinned forever
    # by the instances registry.
    return if @_beingFullDestroyed
    if child == @contents
      @_resetToDefaultContents()

  _beforeChildPickedUp: (child) ->
    if child == @contents
      @_resetToDefaultContents()

  _beforeChildClosed: (child) ->
    if child == @contents
      @_resetToDefaultContents()

  _beforeChildCollapsed: (child) ->
    if child == @contents
      @widthWhenUnCollapsed = @width()
      @contentsExtentWhenCollapsed = @contents.extent()
      @extentWhenCollapsed = @extent()

      # tear down the edit button through the bar's non-settling core: this hook fires inside
      # collapse's settle, so the public self-settling destroy() would throw under the
      # single-mutation tier. The enclosing collapse settle covers the re-layout.
      @bar._destroyEditButtonNoSettle()
      @editButton = undefined

  _beforeChildUnCollapsed: (child) ->
    if child == @contents
      @widthWhenCollapsed = @width()

    @_createAndAddEditButton()

  # Do I offer a resize grip right now? Only while my payload is actually SIZING (ruling C5: the
  # resizer belongs to a frame whose payload sizes freely). Collapsed I AM my bar -- there is
  # nothing to size, and a grip the size of a touch target would blanket the whole sliver and
  # defeat the tap that expands it (ruling C17). My resizer's own visibility asks this.
  offersAResizeHandle: ->
    !@contents?.collapsed

  # Which of my children run out to my bottom-right corner, where my resizer sits: my payload, unless
  # it is collapsed away or keeps clear of the resizer (its spec's resizerCanOverlapContents), and a
  # frame docked in my bottom or right slot, whose far corner the resizer overlaps on purpose. A
  # payload with an engaged band below or beside it does not reach the corner; it is still named,
  # which only keeps a reserve the band has made unnecessary -- the safe way to be wrong. A viewport
  # in that chain reserves the corner from its bars (ViewportWdgt._resizerOverMyCorner).
  bottomRightCornerReachedBy: (child) ->
    if child is @contents
      return !@contents.collapsed and @contents.contentStackSpec?()?.resizerCanOverlapContents isnt false
    child is @_dockedFrameAt('bottom') or child is @_dockedFrameAt('right')

  _reactToChildCollapsed: (child) ->
    if child == @contents
      # a collapsed window is JUST its titlebar, so its bands are gone with its body
      # (_dockedFrameAt already reads them out of the layout; the pixels follow here)
      @_reflectDockVisibilityNoSettle()
      # ... and so is the resize grip: nothing is sizing, and it would sit over the tap zone
      @resizer?.updateVisibility()
      if @widthWhenCollapsed?
        @_applyWidth @widthWhenCollapsed
      # layout-apply-sanctioned: collapse re-fit (must stay synchronous, residuals-audit fam 4)
      @_reLayoutChildren()
      @_invalidateLayout()   # (property sub-seam deletion) uniform climb replaces the property re-fit seam
      @parent.parent._invalidateLayout() if @_amIDirectlyInsideNonTextWrappingViewport()   # (proper-layouts) reach the viewport grandparent; the window's bare climb is dropped at the non-tracking @contents PanelWdgt

  _reactToChildUnCollapsed: (child) ->
    if child == @contents
      # my body is back, so the bands engaged in it are back with it -- and the grip that sizes it
      @_reflectDockVisibilityNoSettle()
      @resizer?.updateVisibility()
      @_applyExtent @extentWhenCollapsed
      @contents._applyExtent @contentsExtentWhenCollapsed
      if @widthWhenUnCollapsed?
        @_applyWidth @widthWhenUnCollapsed
      # layout-apply-sanctioned: uncollapse re-fit (must stay synchronous, residuals-audit fam 4).
      # duringReInflation=true -- the content keeps its just-restored extent; see
      # contentsRecursivelyCanSetHeightFreely. (Direct arrange call: _reLayoutChildren is exactly
      # this dispatch, and only THIS caller carries the mode.)
      @_positionAndResizeChildren true
      # RE-RECORD (the F6 family, auto-bookkeeping arc): uncollapse just restored my extent,
      # so my extent fractions are stale -- a geometry-change re-record, which the fill-only
      # seed (placement-time, fresh widgets only) deliberately does not cover.
      @_rememberFractionalSituationInHoldingPanel()
      @_invalidateLayout()   # (property sub-seam deletion) uniform climb replaces the property re-fit seam
      @parent.parent._invalidateLayout() if @_amIDirectlyInsideNonTextWrappingViewport()   # (proper-layouts) reach the viewport grandparent; the window's bare climb is dropped at the non-tracking @contents PanelWdgt

  # ===== the slots' occupants =====

  # THE DOCK OFFER. WHICH edge band, if any, is at this point of my body — 'top' | 'bottom' |
  # 'left' | 'right', or undefined for a point that belongs to my content. My bands are the strips
  # `dockBandDepth` deep along the four edges of the region my content otherwise fills; releasing a
  # dragged FRAME in one docks it there instead of dropping it into that content, which is the whole
  # of what a band is (program ruling C12 — no type test on WHAT docks, only on where it lands).
  #   PUBLIC because the asker is the hand: its drop resolution consults every frame on the climb
  # from the pointer, handing each the point IN THAT FRAME'S OWN PLANE. Mid-gesture UI offers no
  # bands (a menu is not furniture to dock into), and neither does a collapsed frame — it has no
  # body to give away.
  dockSideAt: (aPointInMyPlane) ->
    return undefined if @isTransientPopUp()
    return undefined if @contents?.collapsed
    body = @_dockBandsBox()
    return undefined unless body.containsPoint aPointInMyPlane
    depth = WorldWdgt.preferencesAndSettings.dockBandDepth
    # the NEAREST edge wins, so the corners belong to the band whose edge they are closest to and
    # every point of the body has exactly one answer
    distances =
      top: aPointInMyPlane.y - body.top()
      bottom: body.bottom() - aPointInMyPlane.y
      left: aPointInMyPlane.x - body.left()
      right: body.right() - aPointInMyPlane.x
    nearestSide = undefined
    for side in FrameWdgt.DOCK_SIDES
      continue if distances[side] > depth
      nearestSide = side if !nearestSide? or distances[side] < distances[nearestSide]
    nearestSide

  # The region my bands divide up: everything inside me that is not my own strip. Pure geometry the
  # hand's hit resolution and the band highlight both read, so the offer and the picture of it
  # cannot disagree.
  _dockBandsBox: ->
    new Rectangle (new Point @left() + @_titlebarWidth(), @top() + @_titlebarHeight()), @bottomRight()

  # The band rectangle at `side`, in my own plane — what the hand outlines while a frame hovers
  # over the offer. Same box, same depth, as the answer above.
  dockBandBoxAt: (side) ->
    body = @_dockBandsBox()
    depth = WorldWdgt.preferencesAndSettings.dockBandDepth
    switch side
      when 'top' then new Rectangle body.origin, new Point body.right(), Math.min(body.top() + depth, body.bottom())
      when 'bottom' then new Rectangle (new Point body.left(), Math.max(body.bottom() - depth, body.top())), body.corner
      when 'right' then new Rectangle (new Point Math.max(body.right() - depth, body.left()), body.top()), body.corner
      else new Rectangle body.origin, new Point Math.min(body.left() + depth, body.right()), body.bottom()

  # Am I holding this widget in one of my slots? (asked by the content hooks, which must let a band
  # through: a band is a payload I HOLD, never the payload I WRAP)
  _isMyDockedFrame: (aWdgt) ->
    for side in FrameWdgt.DOCK_SIDES
      return true if @dockedFrames?[side] == aWdgt
    false

  # THE UNDOCK GESTURE, as one declaration (the container gate of the notification grid): a band
  # in one of my slots is a payload I HOLD, not a part of me, so a drag on its grip lifts THE BAND
  # out instead of moving me -- the same parent-side opt-in the spreadsheet's widget-entry cell
  # uses (Widget.grabsToParentWhenDragged asks its parent this). Everything else about me stays
  # solid under a drag: my bar, my pieces, my resizer.
  wantsDetachOfChild: (aWdgt) ->
    @_isMyDockedFrame aWdgt

  # The public, self-settling dock: the hand's drop lands here (through the add's dockSide option),
  # and so does the toolbar row on my own menu. A top-level gesture declares its own flush.
  dockFrame: (aFrame, side) ->
    @_settleLayoutsAfter => @_dockFrameNoSettle aFrame, side

  # Dock a frame in my slot at `side`. The spec is the whole act: it says WHERE and HOW MUCH of my
  # body the band gets -- and everything else about the docked manifestation (card skin, a grip
  # across the band, no close, no resizer) derives from the frame's no-longer-free-floating
  # attachment. What the band grants the PAYLOAD is the thickness the payload declares for itself
  # if it declares one (dockThickness, which the spec asks at every measure, so nothing about it
  # is recorded), else the extent it arrives with, which the spec records. An occupied slot's
  # previous holder is set free first -- one frame per side.
  _dockFrameNoSettle: (aFrame, side) ->
    payload = aFrame.contents
    unless payload.dockThickness?
      arrivalThickness = if side is "top" or side is "bottom" then payload.height() else payload.width()
    dockSpec = new EdgeDockLayoutSpec side, arrivalThickness
    # armed BEFORE the add, so the band's own roster derive already sees the mode it lands in. A
    # dock is engaged on arrival; only a host whose payload HAS an edit mode and is currently
    # viewing lands it disengaged, because that host's view mode is what disengages every dock.
    dockSpec.engaged = !@contents?.providesAmenitiesForEditing or @contents.dragsDropsAndEditingEnabled == true
    @dockedFrames[side]?._fullDestroyNoSettle()
    @_addNoSettle aFrame, notContent: true, layoutSpec: dockSpec
    # after the add: a re-dock's own departure notification would otherwise free the slot I just filled
    @dockedFrames[side] = aFrame
    @_reflectDockVisibilityNoSettle()
    @_invalidateLayout()

  # Whether a band is DRAWN follows its dock's engagement -- never the other way round, because
  # visibility is never a layout input (the layout reads the spec, in _dockedFrameAt). One place,
  # re-driven wherever engagement can change: the mode flip, my own collapse, a fresh dock.
  _reflectDockVisibilityNoSettle: ->
    for side in FrameWdgt.DOCK_SIDES
      dockedFrame = @dockedFrames?[side]
      continue unless dockedFrame? and dockedFrame.parent == @
      # public-call-sanctioned: show/hide are the public visibility pair (driven cross-object all
      # over the system) -- they settle nothing and touch no geometry, so reaching them from a
      # NoSettle core is settle-neutral.
      if @_dockedFrameAt(side)? then dockedFrame.show() else dockedFrame.hide()
    return

  # My mode's half of the same question: editing ENGAGES every dock, viewing disengages it. The
  # user's own collapse of a band is the band's business and survives the round trip.
  _engageDocksNoSettle: (engaged) ->
    changed = false
    for side in FrameWdgt.DOCK_SIDES
      dockSpec = @dockedFrames?[side]?._myEdgeDockSpec()
      continue unless dockSpec? and dockSpec.engaged isnt engaged
      dockSpec.engaged = engaged
      changed = true
    return unless changed
    @_reflectDockVisibilityNoSettle()
    @_invalidateLayout()

  # The docked frame holding my content's toolbar variant, and the strip inside it. The strip is
  # the PAYLOAD (program ruling C11) -- the frame around it is the same chrome any other frame
  # wears, which is what lets the one object dock and float without being rebuilt.
  _dockedToolbarFrame: ->
    for side in FrameWdgt.DOCK_SIDES
      dockedFrame = @dockedFrames?[side]
      return dockedFrame if dockedFrame? and dockedFrame.parent == @
    undefined

  _dockedToolbar: ->
    @_dockedToolbarFrame()?.contents

  # Build my content's toolbar variant and dock it, framed, at the side the variant asks for. A
  # framed CITIZEN declares its kind's variant itself (§5.B); a plain frame asks the content it
  # wraps; a content that declares none leaves every slot empty.
  # `side` overrides the variant's own default (the "Toolbar" submenu's rows name one).
  _buildDockedToolbarNoSettle: (side) ->
    toolbar = @buildToolbar?() ? @contents?.buildToolbar?()
    return unless toolbar?
    @_dockFrameNoSettle (new FrameWdgt toolbar), (side ? toolbar.dockSide)

  # the content owns the slot's occupant, so a content CHANGE retires it -- the
  # rebuild then makes the NEW content's variant (or none)
  _retireDockedFramesNoSettle: ->
    for side in FrameWdgt.DOCK_SIDES
      dockedFrame = @dockedFrames?[side]
      continue unless dockedFrame?
      delete @dockedFrames[side]
      # the SUBTREE: a frame owns a bar, its pieces and a payload, and destroying it alone would
      # leave all of those alive and off-tree -- escaped widgets the instances registry pins forever
      dockedFrame._fullDestroyNoSettle()
    return

  # The frame's own context-menu entries (on top of the generic Widget set):
  # the toolbar-slot's dock-side chooser and undock action, on the frame's menu
  # because the frame OWNS the slot -- and DELIBERATELY menu entries, never bar
  # buttons (owner ruling D9, Frame-model plan §5.C: don't spend bar space on
  # them). Gated on the toolbar actually showing (you adjust what you can see)
  # -- or, for the chooser alone, on an EMPTY slot the content could refill
  # (the re-dock path after "float the toolbar").
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    # A BAND's own rows: where it sits, and how to stop being a band at all. They are the band's
    # because a docked frame owns its own placement question -- the host owns only whether there is
    # a slot to sit in (program ruling C12).
    if @_myEdgeDockSpec()?
      menu.addLine()
      menu.addMenuItem "Dock", @, "dockSideMenu", closesUnpinnedPopUps: false, opensSubmenu: true, toolTip: ""
      menu.addMenuItem "Float", @, "floatOutOfDock", toolTip: "leave the slot for a window on the desktop"
    # A HOST's row: fill an empty slot with the toolbar my content declares. Offered only while
    # there IS one to make and no slot already holds it -- you cannot dock a second copy of the
    # same variant, and DELIBERATELY a menu entry, never a bar button (owner ruling D9: don't spend
    # bar space on it).
    if @_offersAFreshToolbar()
      menu.addLine()
      menu.addMenuItem "Toolbar", @, "toolbarSideMenu", closesUnpinnedPopUps: false, opensSubmenu: true, toolTip: ""
    # the pin is offered only while there is something to pin: furniture is already staying
    if @isTransientPopUp()
      menu.addLine()
      menu.addMenuItem "Pin", @, "pinPopUp", closesUnpinnedPopUps: false

  # Is there a toolbar to dock that is not docked already? The content must declare a variant (a
  # framed citizen declares its own -- §5.B) and no slot may hold one.
  _offersAFreshToolbar: ->
    return false if @_dockedToolbarFrame()?
    (@buildToolbar? or @contents?.buildToolbar?) == true

  # The BAND's side chooser (the "Dock" submenu): the three sides I am not on (the VSLS-alignment /
  # division-cell menu pattern -- the current one is nothing to choose). A row SHOWS its side
  # capitalised ("Top") and carries the side itself ("top"), the name my slots are keyed by.
  dockSideMenu: (widgetOpeningThePopUp, targetWidget) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: targetWidget
    currentSide = @_myEdgeDockSpec()?.side
    for side in FrameWdgt.DOCK_SIDES
      menu.addMenuItem (CommandPanelWdgt.rowLabelOfValue side), @, "dockAtSide", arg1: side  if side isnt currentSide
    menu.popUpAtHand()

  # The HOST's side chooser (the "Toolbar" submenu): all four, since the slot the row fills is
  # empty; its rows are labelled like the "Dock" submenu's.
  toolbarSideMenu: (widgetOpeningThePopUp, targetWidget) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: targetWidget
    for side in FrameWdgt.DOCK_SIDES
      menu.addMenuItem (CommandPanelWdgt.rowLabelOfValue side), @, "addToolbarAtSide", arg1: side
    menu.popUpAtHand()

  # Move me to another of my host's slots. A dock IS a placement, so re-siding is an edit to the
  # spec that places me -- the same frame, the same payload, a different edge. (Menu-dispatched:
  # the first two slots of the four-slot convention are the row and the menu's subject, and this
  # verb wants neither.)
  dockAtSide: (ignored, ignored2, side) ->
    @_settleLayoutsAfter => @_reSideMyDockNoSettle side

  _reSideMyDockNoSettle: (side) ->
    dockSpec = @_myEdgeDockSpec()
    return unless dockSpec?
    return if dockSpec.side == side
    host = @parent
    return unless host?._isMyDockedFrame? @
    host._freeDockSlotOf @
    host.dockedFrames[side]?._fullDestroyNoSettle()
    dockSpec.side = side
    host.dockedFrames[side] = @
    host._invalidateLayout()
    # the new side may move me into or out of the corner my host's grip covers (it names its right
    # and bottom bands, bottomRightCornerReachedBy), while my extent can stay the same (a bottom
    # band and a top band are equally long), so nothing else re-lays what my viewports keep clear
    # of that corner: tell my corner chain. Docking and undocking reach the same chain without this
    # call: they change my spec, which shows or hides my own grip (Widget._setLayoutSpec ->
    # HandleWdgt.updateVisibility), and its coming or going tells the chain.
    @noteCornerChainChanged()

  # Fill one of my empty slots with my content's toolbar variant, framed. (Menu-dispatched -- see
  # dockAtSide for the two named-as-unread slots.)
  addToolbarAtSide: (ignored, ignored2, side) ->
    @_settleLayoutsAfter => @_buildDockedToolbarNoSettle side

  # LEAVE THE SLOT for the desktop, AS I AM. There is nothing to convert -- I am already a frame,
  # and everything that made me look docked was my edge spec, which the desktop does not give me:
  # I land wearing a window's skin, close piece, resize handle and top bar. I pop out IN PLACE (my
  # payload keeps its own top-left) and my payload serves any widget via the focus pointer, like
  # every summoned toolbar.
  floatOutOfDock: ->
    return unless @_myEdgeDockSpec()?
    payload = @contents
    payloadPosition = payload.position()
    payloadExtent = payload.extent()
    # the add re-homes me out of my host (Widget._addNoSettle notifies its _reactToChildRemoved,
    # which frees the slot and re-fits its chrome over the freed region)
    world.add @
    # the desktop gives me a window's chrome where the band gave me a grip, so re-wrap my payload
    # at the extent it had
    @setExtent @extentWrappingPayloadAt payloadExtent
    # the arrange seats my payload inside my chrome: past my body's edges (my border, my bar), a
    # band of my OWN docked at my left or top (a Docs frame's text toolbar, with its inset) and my
    # body margin, so I land that far up-left of it
    @_applyMoveTo payloadPosition.subtract @_payloadOffset()
    @_moveWithin world

  # LIFTED OUT OF A DOCK SLOT by my grip: the band's look goes (Widget._beforeBeingGrabbed drops my
  # edge spec) and a window's comes, whose bar runs across my top where the band's ran down my side.
  # Kept at my outer size, a top or bottom band would hand its payload the bar's height out of its
  # own and squeeze it; so, as floatOutOfDock does, I re-wrap my payload at the extent it had in the
  # band. That extent is read HERE, while the band still grants it, and applied once I am on the
  # hand (_reactToBeingGrabbed): resized while still my host's child, I would make the host re-fit
  # around a band I am leaving, in the very pass that lays it out. My top-left stays, so I do not
  # jump under the pointer that holds me. A collapsed band is just its bar, with no extent to keep.
  _beforeBeingGrabbed: ->
    @_payloadExtentInTheBand = @contents.extent()  if @_myEdgeDockSpec()? and @contents? and !@contents.collapsed
    super()

  # My extent around a payload of `payloadExtent`, in the chrome I wear NOW: read off the mounted
  # content's own spec, the one home the measure and the arrange share, no literals. Both ways out of
  # a dock slot re-wrap with it (floatOutOfDock and a grab of my grip), so the two cannot disagree.
  # PUBLIC because an opener sizes a window by what it must GRANT its payload: it states the
  # payload's extent and asks me for mine (SpreadsheetApp opens its sheet at its opening grid
  # whatever my chrome measures).
  extentWrappingPayloadAt: (payloadExtent) ->
    payloadExtent.add new Point @_chromeWidth(), @_chromeHeight @contents.contentStackSpec()

  # Consulted at the child-death hook (_beforeChildDestroyed: a mid-teardown rebuild
  # strands fresh chrome on already-destroyed parts of me) and by a framed CITIZEN's
  # _resetToDefaultContents (§5.B): a payload dying because the WHOLE frame is going
  # away must NOT be replaced -- a citizen constructs a FRESH payload per reset, and
  # each fresh child re-enters the destroy-until-empty iteration, an unbounded
  # rebuild-destroy loop. Set here at the subtree's destroy ENTRY so every teardown
  # path (resetWorld's fullDestroyChildren, a direct fullDestroy, the bin)
  # covers the whole recursion.
  _fullDestroyNoSettle: ->
    @_beingFullDestroyed = true
    super
    # the spare placeholder is an OFF-TREE collaborator (mounted as a child only while
    # the window is empty): when it is unmounted at teardown, the destroy-until-empty
    # iteration cannot reach it, and the instances registry would keep it alive forever.
    @defaultContents._fullDestroyNoSettle() if @defaultContents? and !@defaultContents.destroyed

  _resetToDefaultContents: ->
    # public-call-sanctioned: enableDrops is the trivial public drop-acceptance setter (macros and
    # cross-object code drive it) — settle-free, consciously reused here.
    @enableDrops()
    @_retireDockedFramesNoSettle()
    @contents = @defaultContents
    # Reached only from a child-lifecycle hook (_beforeChildDestroyed/PickedUp/Closed). Rebuild through
    # the non-settling core so a hook firing INSIDE an enclosing settle (destroy/close) is absorbed by
    # that operation's settle instead of re-entering the public self-settler. (window-rebuild follow-up)
    @_buildAndConnectChildrenNoSettle()
    @_setEmptyWindowLabelNoSettle()
    if @recursivelyAttachedAsFreeFloating()
      @_applyExtent new Point 300, 300

  _beforeChildDropped: (child) ->
    @removeChild @contents

  # Landing decides my shadow: the hand's lifted one goes away with the hand, and where I come to
  # rest says what I cast instead (see the policy below).
  _reactToBeingDropped: (whereIn) ->
    super
    @contents?._reactToHolderFrameDropped? whereIn
    @_updatePopUpShadow()

  # "You moved it, it stays" (program ruling C8): taking hold of a TRANSIENT frame makes it
  # furniture at the GRAB, not at the drop — carry a menu anywhere, including straight back onto the
  # desktop, and it survives the next click. A notification callback declares no settle of its own
  # (layering rule [J]), so this takes the NoSettle entry and the mark it leaves rides the flush the
  # grab dispatcher owns around this gesture.
  _reactToBeingGrabbed: (whereFrom) ->
    @contents?._reactToHolderFrameGrabbed? whereFrom
    @_setLifetimeNoSettle 'persistent' if @isTransientPopUp()
    # lifted out of a dock slot: re-wrap my payload at the extent it had in the band (see
    # _beforeBeingGrabbed, which read it while the band still granted it)
    if @_payloadExtentInTheBand?
      @_setExtentNoSettle @extentWrappingPayloadAt @_payloadExtentInTheBand
      @_payloadExtentInTheBand = undefined

  # ===== the transient policy: registries, dismissal, pinning =====

  hierarchyOfPopUps: ->
    ascendingWdgts = @
    hierarchy = new Set [ascendingWdgts]
    while ascendingWdgts?.getParentPopUp?
      ascendingWdgts = ascendingWdgts.getParentPopUp()
      if ascendingWdgts?
        hierarchy.add ascendingWdgts
    return hierarchy

  # for pop ups, the propagation happens through the getParentPopUp method
  # rather than the parent property, but for other normal widgets it goes
  # up the parent property
  propagateKillPopUps: ->
    if @isTransientPopUp()
      @getParentPopUp()?.propagateKillPopUps()
      @_markPopUpForClosure()

  _markPopUpForClosure: ->
    world.popUpsMarkedForClosure.add @
    @isPopUpMarkedForClosure = true

  # "Am I furniture?" — the persistent half of the lifetime state, under the name the rows
  # (CommandPanelWdgt.wantsDetachOfChild), the shadow policy and the close policy ask by.
  #   This and its transient twin below are the ONLY readers of the lifetime field: every branch
  # that turns on the state asks one of them, so the enum's spelling is stated twice and nowhere
  # else, and a question about the state is asked in words rather than by string comparison.
  isPersistent: ->
    @lifetime is 'persistent'

  # Role query for the world snapshot (Serializer.serializeWorld): a TRANSIENT frame is
  # mid-gesture UI — it auto-closes on the next outside click / item trigger (indeed the very
  # menu-item click that starts a "Save world snapshot…" has already marked its menu for
  # closure) — so a snapshot drops it, exactly like the ephemeral overlays. A PERSISTENT one
  # is desktop furniture and is saved. Dispatched via ?() (nothing on Widget), like isMenu.
  #   It is also my own branches' reader (see isPersistent above): the strip spec, the birth
  # extent, the dock offer, the grab pin, the closure sweep, the shadow, the skin and the
  # citizens' names all ask HERE rather than comparing the field to a string.
  isTransientPopUp: ->
    @lifetime is 'transient'

  getParentPopUp: ->
    if @isPersistent()
      return @parent
    else
      if @widgetOpeningThePopUp?
        return @widgetOpeningThePopUp.enclosingFrame()
    return undefined

  # The climb STOPS AT ME (the base walks on to the root): I am the pop-up my subtree belongs
  # to — the rows that ask whether they may be lifted, the hand's dismissal sweep and my own
  # rows viewport's re-hug all mean ME. A frame MARKED for closure is on its way out, so the
  # question passes through it to whatever holds it.
  enclosingFrame: ->
    if !@isPopUpMarkedForClosure or !@parent? then return @
    return @parent.enclosingFrame()

  # The public, self-settling half of the lifetime state (the core below does the work).
  setLifetime: (aLifetime) ->
    @_settleLayoutsAfter => @_setLifetimeNoSettle aLifetime

  # THE ONE PLACE MY LIFETIME CHANGES, so the one place every consequence of the change lives.
  #   Entering 'persistent' hands me to the user: the click-outside dismissal callback goes (nothing
  # outside me may dismiss me any more) and my rows re-read the grip fact (see
  # _invalidateRowsAfterPinChange).
  #   Entering 'transient' makes me mid-gesture UI: I join the open set the world sweeps and arms the
  # click-outside dismissal that ends me.
  #   Either way my MANIFESTATION follows (program ruling C4): my skin (_deriveAndSetSkin) and the
  # shadow are derived here and now, and my strip is re-derived — but a strip that gains or loses a piece
  # CONSTRUCTS one, so the derive itself runs only inside a flush. In-pass (a lifetime change reached
  # from an arrange) that flush is the one already running; out of pass I only MARK, and the arrange
  # derives at its top on the flush the gesture supplies. Same two tiers, same discriminator, as
  # _setLayoutSpec's roster derive.
  #   Nothing settles here, so every caller must bring a declared flush for that mark to ride: the
  # user-facing pins (the strip tap, the "Pin" row) come through the setLifetime wrapper above, and
  # the grab reaches me from a notification callback, whose settle the grab dispatcher owns.
  _setLifetimeNoSettle: (aLifetime) ->
    # public-call-sanctioned: onClickOutsideMeOrAnyOfMyChildren is pure REGISTRY bookkeeping (one
    # add/delete on world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren) — it settles nothing and
    # touches no geometry, so calling it from a NoSettle core is settle-neutral (the same sign-off
    # Widget._destroyNoSettle carries for the same call).
    @lifetime = aLifetime
    if aLifetime is 'persistent'
      @onClickOutsideMeOrAnyOfMyChildren undefined
      @_invalidateRowsAfterPinChange()
    else
      world.openPopUps.add @
      @onClickOutsideMeOrAnyOfMyChildren "close"
    @_deriveAndSetSkin()
    @_updatePopUpShadow()
    if world?._recalculatingLayouts
      @_reDeriveBarRosterNoSettle()
    else
      @_invalidateLayout() if @bar?._rosterDisagreesWithSpec()
    return

  # The user-facing verb for "this pop-up stays" — the header tap and the "Pin" row land here. The
  # pin itself is the lifetime entry above; what belongs to THIS verb is the sibling sweep: the
  # pop-ups I was opened from are mid-gesture UI that the pin ends, so the chain above me is marked
  # for closure and drained. It is invoked on the pop-up to be pinned; the triggering menu item — the
  # row or the strip that was tapped — is the first parameter, and it is what the sweep starts from.
  #   Both callers are top-level gestures, so the pin goes through the SELF-SETTLING lifetime entry:
  # the change marks my strip, and a public mutator declares its own flush rather than leaving the
  # mark for the end of the cycle. The sweep that follows settles per closed pop-up, as it always has.
  pinPopUp: (pinMenuItem)->
    @setLifetime 'persistent'
    pinMenuItem.enclosingFrame().propagateKillPopUps()
    world.closePopUpsMarkedForClosure()

  # Pinning changes what my ROWS draw: a command row in a pinned menu wears a grip, because
  # being pinned is what makes it liftable (ButtonWdgt.isDetachablePayloadOfMyParent →
  # CommandPanelWdgt.wantsDetachOfChild). That is a fact about ME which they read, so nothing
  # marks them stale unless I do — and the shadow swap above cannot stand in for it: it marks
  # ME, which re-blits my buffer without re-rendering the rows inside it, and on a pop-up pinned
  # into a non-world parent it drops the shadow instead and may not mark anything at all.
  #   No self-marking twin on the row can replace this: a verb whose only job is "repaint
  # yourself" is the general-purpose public repaint verb the invalidation-privacy campaign
  # removed, and the row has no way to notice a state change on me.
  _invalidateRowsAfterPinChange: ->
    # cross-invalidation-sanctioned: own sub-parts — my rows' paint derives from the lifetime I just set
    row._changed() for row in (@rowsPanel?.children ? [])
    return

  # WHETHER I cast a shadow is my PARENTAGE (program ruling C4): standing on the desktop I float
  # over it, held in a container I am part of what holds me and cast nothing, and riding the hand I
  # cast the hand's lifted one, which the hand adds itself right after this. WHAT the desktop
  # shadow looks like is my look's, and that is the addShadow policy below. Orphan: nothing to
  # cast onto and no home to read — the placement that gives me one asks again.
  _updatePopUpShadow: ->
    return unless @parent?
    # public-call-sanctioned: addShadow/removeShadow are the public shadow API (also driven
    # externally, e.g. by the grab gesture) — consciously reused by this shadow-policy core.
    if @parent == world
      @addShadow()
    else
      @removeShadow()

  # The shadow I cast at rest is my look's (_frameLook): the one desktop shadow every world child
  # wears, transient or persistent alike. An EXPLICIT offset or alpha always wins: the hand adds its
  # lifted one while it carries me.
  addShadow: (offset, alpha) ->
    look = @_frameLook()
    super (offset ? look.shadowOffset), (alpha ? look.shadowAlpha)

  # ALWAYS-ON invariant, in the family of Widget._assertBoundsWellFormed: a pop-up bigger
  # than the world is a pop-up with rows nothing can click. It needs a guard of its own
  # because NO screenshot test reliably catches one — a reference disagrees only if a macro
  # happens to click the row that went missing, which is why menus were shipping rows off
  # the bottom edge unnoticed. The headless runners fail-gate on this token (like
  # NON_INTEGER_GEOMETRY), so the invariant is checked by every test that opens any pop-up
  # rather than by remembering to look.
  _assertFitsInTheWorld: ->
    return unless world?
    return unless @width() > world.width() or @height() > world.height()
    console.error "POPUP_LARGER_THAN_WORLD -- #{@constructor.name} is #{@width()}x#{@height()} in a #{world.width()}x#{world.height()} world, so part of it cannot be reached"
    return

  # ===== the placement verbs =====

  # Placed with my FIRST ROW under the pointer, and centred on the hand across: the row a user
  # is about to want is already where the pointer is, so the click that opened me can dismiss me
  # without moving. Deliberately never the strip itself: a tap there PINS me, which is the
  # opposite of dismissing me.
  #   Both coordinates are the LAYOUT's own, read before the add that lays me out runs it (my
  # composer adds my rows after I am built, and that add is where I take their size): down, where
  # my arrange seats my payload (_payloadOffset) plus how far below its top my payload seats its
  # first row, plus the one pixel that lands the pointer INSIDE the row rather than on its edge;
  # across, the middle of the width my first placement will give me (_widthAtFirstPlacement). So
  # it holds for an untitled pop-up (no strip) exactly as for a titled one, and cannot drift from
  # where the row really lands.
  popUpCenteredAtHand: (world) ->
    firstRowTop = @_payloadOffset().y + (@contents?.firstRowTopInset?() ? 0)
    offset = new Point (Math.floor @_widthAtFirstPlacement() / 2), (firstRowTop + 1)
    @popUp (world.hand.position().subtract offset), world

  # The width my next FIRST PLACEMENT lays me out at: the arrange's own hug (my payload's
  # negotiated width plus my chrome, the free-floating branch of _positionAndResizeChildren), asked
  # before it runs. A pop-up's add re-arms that placement (PopUpRowsViewportWdgt
  # ._reLayOutAfterContainedPanelChange), so until the add my applied width can predate my rows.
  _widthAtFirstPlacement: ->
    @_negotiatedContentWidth(@width()) + @_chromeWidth()

  popUpAtHand: ->
    @popUp world.hand.position(), world

  popUp: (pos, widgetToAttachTo) ->
    @__commitMoveTo pos
    widgetToAttachTo.add @
    # the @_moveWithin method
    # needs to know the extent of the widget
    # so it must be called after the widgetToAttachTo.add
    # method: the add's own settle is where my content measure caps me and I take that size,
    # and clamping decides WHERE that fits.
    @_moveWithin world
    @_assertFitsInTheWorld()
    # shadow must be added after the widget
    # has been placed somewhere because
    # otherwise there is no visible image
    # to base the shadow on
    # P.S. this is the thing that causes the MenuWdgt buffer
    # to be painted after the creation.
    # (addShadow's own _fullChanged closes the invalidation — the add dispatcher
    # already set the dedup flag, so no trailing repaint call is needed here.)
    @addShadow()

  # ===== teardown =====

  # Leaving the open set belongs in the CORE, beside the _closeNoSettle half below: bulk teardown
  # recurses core-to-core (fullDestroyChildren / _fullDestroyNoSettle) and never calls the public
  # destroy(), so an override there misses every pop-up destroyed as part of a subtree. WorldWdgt's
  # per-cycle openPopUps sweep already covers the gap, which is why this is a tier correction rather
  # than a visible-leak fix.
  _destroyNoSettle: ->
    super
    world.openPopUps.delete @

  # Dismissal policy: a PERSISTENT frame is furniture -- closing it is the ordinary
  # widget close (re-homed to the bin, revivable like any widget). A TRANSIENT one
  # is mid-gesture UI (menus, prompts, informs): dismissal destroys it outright,
  # like tooltips -- it is rebuilt fresh by its opener every time, so warehousing it
  # would only grow the bin and every world snapshot.
  # Either way I leave the open set here, in the core: the public close() is the
  # inherited canonical wrap, and the NoSettle drain reaches me directly.
  # Idempotent (return if @destroyed): a stale widgetOpeningThePopUp chain can re-mark
  # an already-dismissed pop-up; the destroy branch explicitly no-ops on it.
  _closeNoSettle: (restingContainer) ->
    return if @destroyed
    world.openPopUps.delete @
    if @isPersistent()
      super
    else
      @_fullDestroyNoSettle()

  # A duplicate is born furniture: nobody is mid-gesture with a copy, so it must not evaporate on
  # the next click (SystemTest_macroDuplicatedMenuAutoPinsOnDesktop asserts exactly that).
  # The state is written directly rather than through the lifetime entry: the copy is a fresh ORPHAN,
  # so the entry's registry and strip work has nothing to reach and its shadow derive has no home to
  # read — the copy carries my shadow verbatim until the copy gesture lands it somewhere. What the
  # copy DOES need at once is the skin its new lifetime calls for (_deriveAndSetSkin), so that it
  # never spends the carry wearing a menu box: its body now, while its strip, still built in the
  # pop-up style, is rebuilt in the window style on the first arrange, and that build skins it.
  # That skin derive is the CHANGE's consequence, so it runs only where there is one — copying
  # furniture copies its skin along with everything else.
  fullCopy: ->
    copiedWidget = super
    lifetimeChanges = copiedWidget.isTransientPopUp()
    copiedWidget.onClickOutsideMeOrAnyOfMyChildren undefined
    copiedWidget.lifetime = 'persistent'
    copiedWidget._deriveAndSetSkin() if lifetimeChanges
    return copiedWidget

  # My whole skin follows my nesting (isInternal, derived from parentage), so it is re-derived
  # (_deriveAndSetSkin) whenever I land in a new home: a container makes me a card, the desktop a
  # window. Drag-drop and a programmatic add both route through here after the reparent, so a
  # dashboard/document that builds a nested window via `container.add` gets the card skin too. The
  # transient pick-up by the hand (whereTo is world.hand) is SKIPPED: the skin stays put during a
  # drag and settles on release.
  _reactToBeingAdded: (whereTo, beingDropped) ->
    super
    # the roster is derived from my ATTACHMENT, not from my parentage, so it holds on the hand
    # too (a frame in the hand owns its own placement, hence carries its close piece)
    @_reDeriveBarRosterNoSettle()
    @_deriveAndSetSkin() if whereTo isnt world?.hand

  _reactToChildDropped: (theWidget) ->
    # a band that just landed in one of my slots is a payload I HOLD: it does not become my content,
    # and it retires nothing of what I already hold (the slot registration is the add's own work)
    return if @_isMyDockedFrame theWidget
    @_retireDockedFramesNoSettle()
    @contents = theWidget
    # (A2a, was the stack super) membership-change re-fit: if my container absorbs the
    # change (a viewport re-fits me + its scrollbars), skip my own re-fit; else it
    # DEFERS to the cycle. My own bookkeeping below runs either way, as it always did.
    unless @parent?._reLayOutAfterContainedPanelChange?()
      @_reFitContainer()
    # public-call-sanctioned: disableDrops is the trivial public drop-acceptance setter (macro-visible
    # behaviour: an occupied window stops accepting drops) — settle-free, consciously reused here.
    @disableDrops()
    # _reactToChildDropped runs inside the drop's single settle, so rebuild through the NON-settling core
    # (not the public _buildAndConnectChildren wrapper, which would re-enter the flush guard) -- same
    # as the _resetToDefaultContents lifecycle path above.
    @_buildAndConnectChildrenNoSettle()

  # MY LOOK: every value my skin wears, as ONE plain record -- the one place a frame's look is
  # decided. My body (_deriveAndSetBodyAppearance), my strip (FrameBarWdgt: its background's build,
  # skin and shape, its title's and its glyphs' ink) and my own shadow (addShadow) READ it; none of
  # them decides a look of its own. A pure query: it reads my state and the theme, writes nothing,
  # and answers at any time (a pop-up citizen asks before its own super has run).
  #   The inputs are my MANIFESTATION (program ruling C4) -- my lifetime crossed with my parentage:
  # transient is a MENU (its pop-up header style goes with it), persistent on the desktop a WINDOW,
  # persistent nested in a real container a CARD -- plus, for a menu's rounding, the world's
  # flat-look preference. Collapsed and docked are not
  # inputs: a collapsed frame wears the look it wears expanded, and a docked band is the card its
  # parentage makes it. (WHICH corners my strip rounds and WHETHER it draws its rule do follow
  # those two -- they change with no re-derivation of the look -- so my strip decides them from its
  # own axis and my collapsed state, at its arrange: FrameBarWdgt._shapeTitlebarBackground.) A FOCUS
  # state would enter here, and only here (redesign plan §0.5.2).
  #   The fields:
  #     manifestation       "menu" | "window" | "card"
  #     bodyAppearance      the appearance class my body wears: the menu box for a menu, the
  #                         rounded box for a window and a card alike
  #     bodyFill, bodyStroke, bodyCornerRadius
  #                         my body's colours and rounding (an undefined rounding is the
  #                         appearance's own default). A menu box is paper with the menu stroke --
  #                         nothing else paints it: my rows panel is a transparent stack inside me.
  #     bodyStrokesOverChildren
  #                         whether my 1 px outline is stroked ONCE, after my children, rather than
  #                         with my fill under them (BoxyAppearance.strokesOverChildren), so content
  #                         laid against my border never covers it
  #     bodyClipsChildrenToOutline
  #                         whether my children are clipped to my ROUNDED outline rather than to my
  #                         rectangle (BoxyAppearance.clipsChildrenToOutline -- the rounded child
  #                         clip, below), so they neither paint nor catch presses in my corner notches
  #     barAppearance       the appearance class my strip's background wears: the rounded box, for
  #                         every strip
  #     barFill, barStroke  its colours. No look strokes a strip, and the stroke is applied as
  #                         given, so an undefined one clears a stroke an earlier look left
  #     barCornerRadius     a pop-up header band's rounding, given when the strip builds it: none,
  #                         since the band's rule is its bottom edge and a ruled band wants square
  #                         rule ends (BoxyAppearance.ruledEdge). A persistent frame's look names
  #                         none: its strip rounds the corners it shares with my outline to the body
  #                         I wear, less my border, at its arrange (FrameBarWdgt._shapeTitlebarBackground)
  #     barRule             the ink of the rule my strip draws along its content-facing edge
  #     barGlyph, barGlyphActive
  #                         the ink of the glyphs my strip's button pieces draw (close, collapse /
  #                         uncollapse, the pencil / eye): at rest, and while one is hovered or
  #                         pressed. Undefined for a strip that carries no button piece (a pop-up
  #                         header)
  #     titleText           my title's ink (painted straight onto my strip's background)
  #     shadowOffset, shadowAlpha
  #                         the shadow I cast at rest on the desktop
  _frameLook: ->
    theme = WorldWdgt.theme
    if @isTransientPopUp()
      return {
        manifestation: "menu"
        bodyAppearance: MenuAppearance
        bodyFill: theme.menuBodyFill
        bodyStroke: theme.menuStroke
        # rounded titled or not, and not at all in a flat look
        bodyCornerRadius: if WorldWdgt.preferencesAndSettings.isFlat then 0 else theme.menuCornerRadius
        # a pop-up clips and strokes last like a window: an overflowing pop-up's scrolled rows and
        # its scroll indicator stop at its outline, and its rows panel catches nothing in its notches
        bodyStrokesOverChildren: true
        bodyClipsChildrenToOutline: true
        barAppearance: BoxyAppearance
        barFill: theme.menuHeaderFill
        barStroke: undefined
        barCornerRadius: 0
        barRule: theme.menuHeaderRule
        barGlyph: undefined
        barGlyphActive: undefined
        titleText: theme.menuHeaderText
        shadowOffset: theme.desktopShadowOffset
        shadowAlpha: theme.desktopShadowAlpha
      }

    internal = @isInternal()
    manifestation: if internal then "card" else "window"
    bodyAppearance: BoxyAppearance
    bodyFill: if internal then theme.cardBodyFill else theme.windowBodyFill
    bodyStroke: if internal then theme.cardFrameStroke else theme.windowFrameStroke
    bodyCornerRadius: if internal then theme.cardCornerRadius else theme.windowCornerRadius
    bodyStrokesOverChildren: true
    bodyClipsChildrenToOutline: true
    barAppearance: BoxyAppearance
    barFill: if internal then theme.cardBarFill else theme.windowBarFill
    barStroke: undefined
    barCornerRadius: undefined
    barRule: theme.barRule
    barGlyph: if internal then theme.cardBarGlyph else theme.windowBarGlyph
    barGlyphActive: theme.barGlyphActive
    titleText: theme.windowTitleText
    shadowOffset: theme.desktopShadowOffset
    shadowAlpha: theme.desktopShadowAlpha

  # MY WHOLE SKIN, re-derived from my look as ONE act: my body (below) and my strip
  # (FrameBarWdgt._deriveAndSetStripSkin: its background's skin and shape, its title's and its
  # glyphs' ink), then a repaint of me. Every derivation after my birth runs it -- each re-parenting
  # (_reactToBeingAdded), each lifetime change (_setLifetimeNoSettle, the pin among them), a copy
  # that changes lifetime (fullCopy) -- and so does a transform island I ride in as its sole content
  # whenever IT is re-homed (TransformFrameWdgt._reactToBeingAdded): only the root of an add hears
  # it, and my look follows the container I really live in, seen through that island
  # (isInternal), which the island's move changes. My constructor derives only my body: my strip
  # does not exist yet, and its build skins it.
  _deriveAndSetSkin: ->
    @_deriveAndSetBodyAppearance()
    @bar?._deriveAndSetStripSkin()
    @_changed()

  # The BODY half of my skin (_deriveAndSetSkin runs it with the strip's half): my WHOLE body look,
  # applied from _frameLook on EVERY derivation, whatever my lifetime -- the appearance (the menu
  # box, or the rounded box of a window and a card), its fill, stroke and rounding, and its two
  # knobs. There is deliberately no fourth, "pinned menu" look: that would key on what I once was,
  # the one input a derived look may never take, so a pinned menu wears the window's body.
  #   The rule this makes: my look WINS at every derivation, so a body colour or a corner radius set
  # by hand ("Corner radius…", its pin) lasts until I next change parent or lifetime.
  #   The knobs go on the NEW appearance: they live on the appearance instance, and a fresh one
  # starts with both off. As the appearance's own fields they are saved with it, so a frame a
  # snapshot restores WITHOUT re-deriving (a nested one: only the top-level frames hear
  # _reactToBeingAdded on a load) keeps the look it was saved in.
  _deriveAndSetBodyAppearance: ->
    look = @_frameLook()
    @appearance = new look.bodyAppearance @
    @appearance.strokesOverChildren = look.bodyStrokesOverChildren
    @appearance.clipsChildrenToOutline = look.bodyClipsChildrenToOutline
    @color = look.bodyFill
    @strokeColor = look.bodyStroke
    @cornerRadius = look.bodyCornerRadius

  # ===== the ROUNDED CHILD CLIP (redesign plan §3a option (a), spikes S1b/S1c) =====
  # My LOOK decides it (_frameLook's bodyClipsChildrenToOutline, set on my body's appearance as its
  # clipsChildrenToOutline knob): every rounded frame -- a window, a card, a docked band, a menu or a
  # prompt -- clips its children to its rounded OUTLINE rather than to its rectangle, so content laid
  # flush into it cannot paint (or catch presses) in the notches outside its corners; a square one
  # (a pop-up in the flat look) has no notch and keeps the rectangle. With the knob off, every paint
  # and hit test of mine runs exactly the code a rectangular clip runs.

  # The per-corner radii [topLeft, topRight, bottomRight, bottomLeft] of the ROUNDED outline I clip my
  # children to, or undefined when I clip them to my rectangle: my body's own radii, read through my
  # appearance, when its clip knob is on and my body is rounded. My paint asks it, and so does every
  # descendant's pointer test (Widget.isPointerTargetAt probes EVERY ancestor for it on EVERY hit
  # test) -- which is why the decision is a FIELD read off my appearance, set once per derivation,
  # and never a fresh derivation of my look.
  _roundedChildClipRadii: ->
    return undefined unless @appearance?.clipsChildrenToOutline
    radii = @appearance.outlineCornerRadii?()
    return undefined unless radii? and Math.max(radii...) > 0
    radii

  # My children's paint, intercepted at the content-recursion point the clipping mixin owns (the
  # ViewportWdgt idiom). With no rounded child clip it IS the mixin's body, reached through
  # PanelWdgt's injected copy (`super` here would bind to base Widget's un-clipping version); with
  # one it is that body (kept in lockstep with it) with my children painted inside my outline.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    radii = @_roundedChildClipRadii()
    if !radii?
      return PanelWdgt::_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow.call @, aContext, clippingRectangle, appliedShadow
    damagedPartOfFrame = @boundingBox().intersect clippingRectangle
    if !damagedPartOfFrame.isEmpty()
      if aContext == world.worldCanvasContext
        @_recordDrawnAreaForNextDamageRects()
      @paintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow
      @_paintChildrenInsideMyRoundedOutline aContext, damagedPartOfFrame, appliedShadow, radii

  # The shadow-pass twin. An OPAQUE frame's silhouette is its own box and paints no child (the
  # mixin's short-circuit), so only a translucent frame has children to clip here — under the
  # shadow offset this pass translates by, which the clip follows because it is traced under the
  # context's own matrix.
  _fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
    radii = @_roundedChildClipRadii()
    if !radii? or @alpha == 1
      return PanelWdgt::_fullPaintIntoAreaOrBlitFromBackBufferJustShadow.call @, aContext, clippingRectangle, appliedShadow
    clippingRectangle = clippingRectangle.translateBy appliedShadow.offset.neg()
    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      damagedPartOfFrame = @boundingBox().intersect clippingRectangle
      if !damagedPartOfFrame.isEmpty()
        aContext.save()
        aContext.translate appliedShadow.offset.x * ceilPixelRatio, appliedShadow.offset.y * ceilPixelRatio
        @paintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow
        @_paintChildrenInsideMyRoundedOutline aContext, damagedPartOfFrame, appliedShadow, radii
        aContext.restore()

  # (Painting my children inside my rounded outline -- _paintChildrenInsideMyRoundedOutline and the
  # helpers it calls -- is Widget's, shared with the other widget that cuts its children to its
  # outline, a tool cell.)

  # ===== my page's SELECTION RING, in my page gutter (window-page-gutter plan D3, D8) =====
  # While I keep a gutter around a PAGE, the editor-selection ring of my page lies OUTSIDE the page,
  # in that gutter, and I paint it: the space is mine, so what lies in it is mine to paint. It stands
  # theme.pageSelectionOutlineOffset out from my page's box, selectionOutlineWidth thick, its corners
  # my page's grown by that reach (a square corner stays square), painted after my own fill and
  # before my children -- so my grip, my last child, lies over it. I host it only while my gutter is
  # at least that reach wide, so nothing else reaches it (a band stands a whole gutter from my page,
  # my border a whole gutter from its edges). The selected widget then paints no ring of its own
  # (Widget._paintEditorSelectionOverlayIfSelected). The world decides once per cycle whose ring I
  # paint and around which box, by asking hostsSelectionRingOf and pageSelectionRingBox below, and
  # tells me when that ring comes, goes, changes hands or moves (notePageSelectionRingChanged). Every
  # other selection ring -- a paragraph's, a board's, the page's in a window whose gutter cannot
  # hold it -- stays inside its own widget.

  # Do I paint the selection ring of `aWdgt`? Only while my gutter HOLDS the ring (my payload is a
  # PAGE, my body margin is at least the ring's reach, my page is not collapsed and shows) and
  # `aWdgt` FILLS my page: my page itself, or a widget inside it whose visible box is my page's
  # visible box. A narrower gutter would put the ring over my border or a band, so there the
  # selected widget keeps its own ring, inside its box. A click on a page selects the child that
  # covers it -- a document's stack, a canvas's glass, a stretchable page's panel -- and never the
  # page, so that child's ring is my page's ring; an item ON my page (a paragraph, a letterboxed
  # slide, a Fizzytiles board) keeps its ring inside its own box. PUBLIC: the world's selection
  # reconciler asks it, through ?(), of the nearest frame above the selected widget
  # (WorldWdgt._editorSelectionRingHostOf); a widget that does not answer hosts no ring.
  hostsSelectionRingOf: (aWdgt) ->
    return false unless @_hostsAPage() and @_bodyMargin() >= @_pageSelectionRingReach() and !@contents.collapsed
    return false unless @contents.isAncestorOf aWdgt
    pageBox = @contents.clippedThroughBounds()
    # nothing of my page shows (hidden, or clipped away by a container I stand in): no ring to paint
    return false if pageBox.isEmpty()
    pageBox.equals @_visibleBoxOnMyPage aWdgt

  # `aWdgt`'s visible box (its clippedThroughBounds, in its own plane) carried into my page's plane
  # across the scroll translations between them: a scrolled document's stack lies in its viewport's
  # translated plane, where its box stands wherever its content has scrolled to. undefined when a
  # transform island stands between them -- past one a box is turned or scaled, so it is no box of my
  # page's. `aWdgt` is my page or a widget inside it.
  _visibleBoxOnMyPage: (aWdgt) ->
    return undefined unless aWdgt._enclosingNonIdentityIsland() is @contents._enclosingNonIdentityIsland()
    box = aWdgt.clippedThroughBounds()
    child = aWdgt
    until child is @contents
      translation = child.parent.scrollTranslationOfChild? child
      box = box.translateBy translation if translation?
      child = child.parent
    box

  # How far my page's ring reaches out past my page's box: the theme's air, then the ring's width.
  # Read by the guard above (my gutter must hold it) and by the ring's box below.
  _pageSelectionRingReach: ->
    theme = WorldWdgt.theme
    theme.pageSelectionOutlineOffset + theme.selectionOutlineWidth

  # THE BOX OF THE RING I paint around my page: my page's visible box grown by the ring's reach (the
  # ring is the band between this box and my page's box grown by the air alone). The ONE home of the
  # ring's geometry, read by my paint (_paintPageSelectionRing) and by the world's selection
  # reconciler, which keeps the last answer beside the host and tells me when it changes
  # (WorldWdgt._updateEditorSelectionOverlay) -- so the box the world compares is the box I paint.
  # PUBLIC query, read live at every ask: my page's box moves with my resizes and with every band
  # floated out of me, docked into me or collapsed.
  pageSelectionRingBox: ->
    @contents.clippedThroughBounds().expandBy @_pageSelectionRingReach()

  # PUBLIC notification -- the page selection ring I paint came to me, left me, moved (my page's box
  # changed while it stayed selected), or now belongs to a different selected widget's page. The
  # world's selection reconciler calls it on any such change
  # (WorldWdgt._updateEditorSelectionOverlay). The ring lies in MY gutter, outside the selected
  # widget's box, so that widget's own repaint cannot cover it: a widget's damage reaches 1 px past
  # its top and left edges (and the damage margin past its right and bottom), so the ring's top and
  # left sides would stay on screen. I invalidate MYSELF here, in the method the world invokes on me
  # (widget-citizenship point 2) -- the world never reaches into my _changed().
  notePageSelectionRingChanged: ->
    @_changed()

  # My body's own paint (my appearance: my fill), then -- in the normal pass, while the world names me
  # the host of the selection ring (WorldWdgt.editorSelectionRingHost) -- my page's ring, over that
  # fill and under my children. Both of my paint paths reach here before they paint my children: the
  # rounded child clip's (_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow above) and
  # the clipping mixin's. The shadow pass never paints the ring: a selection is no part of my
  # silhouette.
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    super
    return if appliedShadow? or world?.editorSelectionRingHost() isnt @
    @_paintPageSelectionRing aContext, clippingRectangle

  # THE PAGE RING: selectionOutlineWidth thick, pageSelectionOutlineOffset out from my page's visible
  # box, filling pageSelectionRingBox to its edges, in the selectionOutline role, its corners the
  # ones my page shows (cornerRadiiFollowingMyOutline) each grown by the ring's reach, a square corner
  # staying square. Painted by the selection outline's own painter in its own spelling
  # (Widget._drawSelectionOverlay): clipped to the damaged part of me (device pixels), at full alpha,
  # laid out in logical pixels with the origin moved to the ring's top-left, in whatever context I am
  # painted into -- the world canvas, or the buffer of the transform island I sit in, where it warps
  # with me. Its geometry is pageSelectionRingBox, never the damage box. Its stroke half stays off:
  # the ring's outer edge lies over my own fill in the gutter, where no border runs under it.
  _paintPageSelectionRing: (aContext, clippingRectangle) ->
    [damageBox, sl, st, al, at, w, h] = @calculateKeyValues aContext, clippingRectangle
    return unless damageBox? and damageBox.isNotEmpty() and w >= 1 and h >= 1
    theme = WorldWdgt.theme
    reach = @_pageSelectionRingReach()
    ringBox = @pageSelectionRingBox()
    pageBox = ringBox.insetBy reach
    radii = ((if radius > 0 then radius + reach else 0) for radius in @contents.cornerRadiiFollowingMyOutline pageBox)
    aContext.save()
    aContext.clipToRectangle al, at, w, h
    aContext.globalAlpha = 1
    aContext.useLogicalPixelsUntilRestore()
    aContext.translate ringBox.left(), ringBox.top()
    HighlightOutlineAppearance.paintRing aContext, ringBox.width(), ringBox.height(), theme.selectionOutlineWidth,
      radii, theme.selectionOutline, false
    aContext.restore()

  # ONE settle around the whole rebuild via the single-mutation tier (_settleLayoutsAfter). The
  # core is non-settling: it adds the bar (whose pieces build through the bar's own non-settling
  # core) AND the content through @_addNoSettle, so nothing self-settles per add and nothing
  # re-fits the HALF-built window mid-loop -- the window's content bookkeeping rides along in
  # FrameWdgt._addNoSettle. The single settle runs AFTER the core: O(1) relayouts.
  #
  # This PUBLIC self-settler is only ever called STANDALONE (the constructor). Every rebuild path that
  # fires from inside an enclosing settle -- a child-lifecycle hook (_beforeChildDestroyed/Closed/PickedUp)
  # -> _resetToDefaultContents -> rebuild, or _reactToChildDropped inside the drop's settle -- goes through the
  # non-settling @_buildAndConnectChildrenNoSettle directly, never this wrapper, so the wrapper never
  # re-enters a flush. The chrome the core constructs adds to ORPHANS, exempt from the flush-throw
  # (Widget._settleLayoutsAfter's orphan guard precedes the throw). (Phase 3b; window-rebuild follow-up.)
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    if !@bar?
      @bar = new FrameBarWdgt @
      @_addNoSettle @bar, notContent: true
    # the bar builds/keeps its pieces (label rebuilt every time, the rest
    # keep-if-exist); @closeButton is the ctor-supplied one on the first build
    # (FolderWindowWdgt injects its own), then the alias of the bar's.
    @bar._buildAndConnectPiecesNoSettle @closeButton
    # re-point the aliases at the (possibly fresh) pieces -- see the field block.
    @titlebarBackground = @bar.titlebarBackground
    @label = @bar.label
    @closeButton = @bar.closeButton
    @collapseUncollapseSwitchButton = @bar.collapseUncollapseSwitchButton

    @_createAndAddEditButton()

    @_addNoSettle @contents

    # the toolbar's slot occupant (keep-if-exist like the bar pieces; the
    # content-CHANGE points retire it first so a new content gets its own
    # variant). Born disengaged when viewing.
    @_buildDockedToolbarNoSettle() unless @_dockedToolbarFrame()?

    # the resize affordance the spec names: a frame that sizes to what it holds (a pop-up hugs
    # its rows) offers none. A frame is an ORPHAN while it builds -- hence free-floating, hence
    # offering the grip -- so a window always gets one and hides it while a host owns its
    # placement (HandleWdgt.updateVisibility); only a manifestation that says "none" from birth
    # goes without. The grip is the frame's own resizer (FrameGripWdgt: its look, size, inset and
    # square hit area), never the plain handle a halo puts on a widget.
    if !@resizer? and @_barSpec().resizer isnt "none"
      # Attach the resizer, then record it. @resizer stays undefined DURING its own add so the
      # `@resizer?._moveInFrontOfSiblings()` in _addNoSettle (above) is a no-op for the resizer
      # itself -- it only re-fronts the resizer when LATER content is added.
      resizer = new FrameGripWdgt
      @_addNoSettle resizer, layoutSpec: resizer.defaultLayoutSpecWhenAddedTo(@)
      @resizer = resizer

  # My bar's roster follows my ATTACHMENT (a host that owns my placement owns my membership,
  # so a host-owned frame carries no close piece -- ruling C6) and my LIFETIME (a menu wears the
  # title-only strip, furniture the window strip -- ruling C4), so it is re-derived wherever either
  # can change: at every (re)parenting, at every layout-spec change -- the very seam the resize
  # handle's own visibility rides (HandleWdgt.updateVisibility, driven from Widget::_setLayoutSpec)
  # -- and at every lifetime change. Re-points the aliases at what the bar now holds (a strip that
  # changes style carries a fresh title piece and background), and invalidates only when the roster
  # really moved -- a spec-less chrome child rides the freefloating skip in Widget._addNoSettle's
  # container invalidate, so the frame's own layout is not reached by the add alone.
  _reDeriveBarRosterNoSettle: ->
    return unless @bar?
    return unless @bar._reDeriveRosterNoSettle()
    @titlebarBackground = @bar.titlebarBackground
    @label = @bar.label
    @closeButton = @bar.closeButton
    @collapseUncollapseSwitchButton = @bar.collapseUncollapseSwitchButton
    # the pencil is the one piece whose BUILD carries a mode to reflect, so the bar retires it
    # with the rest of the roster and I put it back: docking me drops it, setting me free on the
    # desktop hands it back, showing the mode my payload is in at that moment.
    @editButton = @bar.editButton
    @_createAndAddEditButton()
    # OFF-PASS the roster change needs a re-lay scheduled. IN-PASS it does not: the only
    # in-pass reach is an arrange handing my content its frame-content spec, and that same
    # arrange re-lays my bar a few lines later -- while scheduling mid-pass is the flow-rule
    # violation (Widget._invalidateLayout reads the same flag for the same reason).
    @_invalidateLayout() unless world?._recalculatingLayouts

  # A spec that OWNS my placement makes me host-owned, which is exactly what my bar's roster
  # (and the resize handle's visibility, in the base) turns on.
  #   THE PRINCIPLE: deriving the roster CONSTRUCTS a gained piece, and a widget constructor
  # settles — so the derive runs ONLY inside a flush. Two tiers, split by the world's own pass
  # state (the same discriminator the derive's invalidate reads):
  #   IN-PASS — a host handing me a spec mid-arrange, after my own arrange has already run in this
  # pass — derive NOW: the fresh piece is an orphan, so its constructor's settle is the auto-defer
  # (Widget._settleLayoutsAfter) and the derive is settle-neutral by construction.
  #   OUT-OF-PASS — a notification callback dropping my spec on a grab
  # (Widget._beforeBeingGrabbed), and every other spec change outside a flush — MARK only: a
  # callback owns no settle (layering rule [J]), and my arrange derives at its top on the flush the
  # gesture's own settle supplies. The mark is worth making only when the strip actually disagrees
  # with the spec, which is what the bar's query answers.
  _setLayoutSpec: (newLayoutSpec) ->
    super
    if world?._recalculatingLayouts
      @_reDeriveBarRosterNoSettle()
      return
    @_invalidateLayout() if @bar?._rosterDisagreesWithSpec()

  # Reflect the content's edit/view mode in the title-bar edit button. The glyph
  # NAMES the current mode (pencil = editing now, eye = viewing now); the button
  # owns its own rest/hover appearance (the current mode's glyph at rest, the next
  # mode's on hover as feedforward — see EditIconButtonWdgt; its inks are its
  # strip's), so this just sets the mode.
  # Driven from the enable/disable state-reflection callers, not from clicks.
  showEditModeInBar: ->
      @editButton?.showPencilGlyph()
      # my slots follow the mode: editing ENGAGES every dock (the band takes its space back and
      # is drawn again). NoSettle core -- this protocol is driven from inside the content's
      # enable/disable settle; the engagement invalidates, and that flush covers it.
      @_engageDocksNoSettle true
      # a mode-reactive toolbar (PaintToolbarWdgt re-arms/disarms its tools,
      # §5.D) rides the SAME protocol; the hooks transition-guard themselves
      # because this reflector is idempotently re-driven (e.g. the edit-button
      # recreate on window uncollapse).
      @_dockedToolbar()?.reactToEditModeInFrame?()

  showViewModeInBar: ->
      @editButton?.showEyeGlyph()
      @_engageDocksNoSettle false
      @_dockedToolbar()?.reactToViewModeInFrame?()

  # Frame-level edit-mode switch (§5.B): route through the PAYLOAD's own core --
  # the payload owns the canonical dragsDropsAndEditingEnabled flag and its core
  # does the recursive child locking/unlocking -- then flip my own bar (I am the
  # bar owner; the payload's `@parent?.show*ModeInBar?()` notify reaches me too,
  # idempotently). The Widget base core would act SHALLOWLY on @contents (one
  # child level, no payload-specific propagation) and notify only @parent. My
  # own flag mirrors the payload's so a frame nested as another frame's content
  # keeps Widget.editButtonPressedFromFrameBar's toggle direction honest.
  # ⚠ NO `triggeringWidget` parameter here, unlike the Stretchables. That parameter exists ONLY to
  # stop an edit-mode change bubbling back to whoever triggered it, and the only code that reads it
  # is BubblesEditModeToCoordinatorMixin's `@parent != triggeringWidget` — which is the CORE of the
  # two Stretchables, not of a frame. A frame that declared it would be accepting a value it then
  # drops on the floor. The `@` passed DOWN to @contents below is a different thing and IS live:
  # the contents may be mixin-cored, and that core reads it.
  enableDragsDropsAndEditing: ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle()

  _enableDragsDropsAndEditingNoSettle: ->
    @dragsDropsAndEditingEnabled = true
    @contents?._enableDragsDropsAndEditingNoSettle @
    # public-call-sanctioned: showEditModeInBar is the window-bar mode PROTOCOL, driven
    # cross-object by content widgets (`@parent?.showEditModeInBar?()`), so it stays public — and
    # it settles nothing (it marks; my own settling wrapper above flushes the mark)
    @showEditModeInBar()

  disableDragsDropsAndEditing: ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle()

  _disableDragsDropsAndEditingNoSettle: ->
    @dragsDropsAndEditingEnabled = false
    @contents?._disableDragsDropsAndEditingNoSettle @
    # public-call-sanctioned: showViewModeInBar is the window-bar mode PROTOCOL, driven
    # cross-object by content widgets (`@parent?.showViewModeInBar?()`), so it stays public — and
    # it settles nothing (it marks; my own settling wrapper above flushes the mark)
    @showViewModeInBar()

  _createAndAddEditButton: ->
    # public-call-sanctioned: showEditModeInBar/showViewModeInBar are the window-bar mode PROTOCOL —
    # content widgets drive them cross-object (`@parent?.showEditModeInBar?()`), so they stay public.
    # The roster carries the pencil exactly when the amenities are there to drive — a framed
    # CITIZEN provides them itself (its payload may be a plain Widget container, §5.B), a plain
    # frame gets them from the content it wraps — so the spec is the one home for that question.
    if ("edit" in @_barSpec().pieces) and !@editButton?
      @editButton = @bar._createAndAddEditButtonNoSettle()

      if @contents.dragsDropsAndEditingEnabled
        @showEditModeInBar()
      else
        @showViewModeInBar()

  # (A2a, was inherited from the stack) when THIS frame is another frame's CONTENT (a
  # window nested in a window), its spec pins canSetHeightFreely = false on top of the
  # base init -- byte-what the stack's override did.
  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @_contentStackSpec.canSetHeightFreely = false

  # The re-fit chokepoint for a window (no scrollbars): re-fit chrome + content. Reached via my own
  # _reLayoutChildren (above, FrameWdgt's own -- A2a de-inherited the stack base), which dispatches straight here.
  # duringReInflation: passed true ONLY by _reactToChildUnCollapsed's synchronous re-fit -- see
  # contentsRecursivelyCanSetHeightFreely (up-edge endgame V1-d).
  _positionAndResizeChildren: (duringReInflation = false) ->

    # The roster is my spec's consequence and lands HERE, at the top of the arrange, because
    # gaining a piece CONSTRUCTS one: inside this flush the piece is an orphan and its
    # constructor's settle defers, while every other reach — a notification callback dropping my
    # spec on a grab — would open a flush of its own. The strip is laid out a few lines below, so
    # a piece gained here is placed in this same pass.
    @_reDeriveBarRosterNoSettle()

    stackHeight = 0

    if @contents? and !@contents.collapsed
      # Order-independent spec init: (re)init whenever the content's ACTIVE spec is not
      # frame-content — a fresh mount's active spec is set by _addNoSettle before this
      # deferred re-fit runs, so the common steady state skips; anything else (transient /
      # stack-flavoured / missing spec) gets a fresh FrameContentLayoutSpec and is adopted.
      if !@contents.layoutSpec?.isFrameContentActive?()
        @contents.initialiseDefaultFrameContentLayoutSpec()
        @contents._setLayoutSpec @contents._contentStackSpec

      # (U2) the first-placement ONE-SHOT is CONTENT-owned: an uncaptured spec (desiredWidth
      # unset -- fresh init above, or re-armed on content (re)mount in _addNoSettle) selects
      # the negotiation branch ONCE; captureInitialPlacement below is itself the latch. Computed
      # BEFORE the capture latches, and used by BOTH the width branch here and the height branch below.
      firstPlacement = !@contents.contentStackSpec().desiredWidth?

      if firstPlacement
        recommendedElementWidth = @_firstPlacementContentWidth @width()
        if @isFreeFloating() and @contents.contentStackSpec().preferredStartingWidth != FrameContentLayoutSpec.DONT_MIND
          # THIS_ONE_I_HAVE_NOW / an explicit px on a DESKTOP window: the WINDOW resizes
          # (hugs) to the content's width. A CONTAINER-OWNED window never self-resizes its
          # width -- the container owns it (§9.7-Q, owner-decided 2026-07-17; the predicate
          # is MY OWN layoutSpec, NOT recursivelyAttachedAsFreeFloating(), which answers for
          # the ISLAND -- a window nested in a desktop window IS recursively-freefloating).
          # ⚠ suppressing the hug ALONE (still handing the content the negotiated width) is
          # the U3-C falsified shape (plan §6): the content freezes at a width its window
          # never converges to (stale applied-vs-spec, clipped text). The sound form is the
          # PAIRED rule in _firstPlacementContentWidth: no hug AND the container-derived
          # content width, so window and content agree from birth.
          if @recursivelyAttachedAsFreeFloating()
            windowWidth = recommendedElementWidth + @_chromeWidth()
          else
            windowWidth = Math.min @width(), recommendedElementWidth + @_chromeWidth()
          @_applyExtentBase new Point windowWidth, @height()

        @contents._contentStackSpec.captureInitialPlacement @contents, @


      else
        recommendedElementWidth = @contents.contentStackSpec().getWidthInStack()

      partOfHeightUsedUp = @_chromeHeight @contents.contentStackSpec()

      # this re-layouts each widget to fit the width.
      if firstPlacement
        if @contents.contentStackSpec().preferredStartingHeight == FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW
          # (U3-C) through preferredExtent, not raw height() -- see _negotiatedContentWidth
          desiredHeight = @contents.preferredExtent().y
          if !@recursivelyAttachedAsFreeFloating()
            desiredHeight = Math.min desiredHeight, @height() - partOfHeightUsedUp
          @contents._applyWidth recommendedElementWidth
          @contents._applyHeight desiredHeight
        else if @contents.contentStackSpec().preferredStartingHeight == FrameContentLayoutSpec.DONT_MIND
          @contents._applyWidth recommendedElementWidth
          desiredHeight = Math.round @height() - partOfHeightUsedUp
          @contents._applyHeight desiredHeight
        else
          # Path B: the sizing HANDS its resulting height back -- no read-back of @contents.height().
          desiredHeight = @contents._setWidthSizeHeightAccordingly recommendedElementWidth

        # (no flag clear -- captureInitialPlacement above latched the one-shot)
      else
        # Path B: take the resulting height from the sizing call, not a read-back of @contents.height().
        desiredHeight = @contents._setWidthSizeHeightAccordingly recommendedElementWidth

        # (proper-layouts residual, 2026-07-01) Single-pass fit-to-content: settle a NON-deferred size-tracking
        # container content (a stack) NOW, synchronously, so I fit its FINAL height in THIS pass. Otherwise the
        # content settles independently LATER (as its own settle-loop chain-top) and its settle-time re-fit
        # re-VISITS me to re-fit -- the residual FrameWdgt content-negotiation re-visits. This is the SAME
        # _reLayout() the settle loop would call on the content's own turn, pulled one iteration earlier, so it
        # is byte-exact. _setWidthSizeHeightAccordingly already settles DEFERRED-layout content (a viewport);
        # a stack pins implementsDeferredLayout false, so we settle it here. EXCLUDES content that re-fits its OWN
        # width when re-laid (a nested window, _reLayoutMayResizeOwnWidth): settling THAT early re-negotiates its
        # width and diverges from its normal independent settle -- its re-visit is a GENUINE width<->height
        # convergence, correctly left to the settle loop.
        if @contents._reLayoutChildren? and not @contents.implementsDeferredLayout() and not @contents.layoutIsValid and not @contents._reLayoutMayResizeOwnWidth?()
          @contents._reLayout()
          desiredHeight = @contents.height()

        if @contentsRecursivelyCanSetHeightFreely duringReInflation
          desiredHeight = Math.round @height() - partOfHeightUsedUp
          @contents._applyHeight desiredHeight

      # contained text that has OPTED INTO FIT_BOX_TO_TEXT (a SimpleTextWdgt,
      # or any bare TextWdgt put into that mode) fits its BOX to the TEXT: it wraps
      # to the width we set generically above and its height follows the wrapped
      # content. We RESPECT the mode rather than imposing it, so the empty-window
      # placeholder — a TextWdgt that stays FIT_TEXT_TO_BOX — is left alone. Here we
      # only (re)assert soft-wrap (the actual reflow is driven by the generic
      # width-set above → the widget's own FIT_BOX_TO_TEXT _reLayoutSelf).
      if @contents.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
        @contents.softWrap = true

      # centre the content in its REGION -- the width my chrome leaves it (my body's edges, my
      # body margin past them, a band docked on either flank), starting where a payload that
      # fills it starts (_payloadOffset), so content as wide as its region sits exactly there
      payloadOffset = @_payloadOffset()
      leftPosition = @left() + payloadOffset.x + Math.floor (@width() - @_chromeWidth() - recommendedElementWidth) / 2

      @contents._applyMoveTo new Point leftPosition, @top() + payloadOffset.y
      stackHeight += desiredHeight

    if @contents? and @contents.collapsed
      partOfHeightUsedUp = @_titlebarHeight()


    # A strip running down my SIDE spans my whole height, so my height is my HOST's grant, not my
    # content's sum: a band is exactly as thick as the host reserved for it, whether my payload
    # fills it or my collapsed body leaves nothing in it at all.
    if @_barSpec().axis is "vertical"
      newHeight = @height()
    else
      newHeight = stackHeight + partOfHeightUsedUp

    @_applyExtentBase new Point @width(), newHeight

    # the title strip: hand the bar its bounds (my top strip at the FINAL width, or my leading
    # side strip at my final height -- the first-placement hug above may have just re-committed
    # them); the bar's own arrange places the pieces along whichever direction it runs.
    if @bar? and @bar.parent == @
      barBounds = new Rectangle @position()
      if @_barSpec().axis is "vertical"
        barBounds = barBounds.setBoundsWidthAndHeight @_titlebarWidth(), @height()
      else
        barBounds = barBounds.setBoundsWidthAndHeight @width(), @_titlebarHeight()
      @bar._reLayout barBounds

    # the four slots: place each docked band in my body, past its inner edges
    # (my border or my bar) and my body margin, standing my band inset
    # (_dockedBandInset: what the theme's band inset adds past that margin)
    # further in on its three OUTER sides, its fourth side facing the content
    # across my body margin -- TOP/BOTTOM: a band across my whole body less the
    # inset at each end, the content starting a body margin below it (top) or
    # ending a body margin above it (bottom); LEFT/RIGHT: a column on that flank
    # spanning the content's vertical span less the inset at each end, so a
    # column and a top or bottom band stand as far apart where they meet as a
    # band stands in from my body's edges (stackHeight is the content height
    # this pass just derived, so every placement is pass-local -- no
    # applied-bounds read-back). Driven SYNCHRONOUSLY via _reLayout bounds,
    # the same drive as @bar above -- a band's _reLayout applies its own
    # bounds THEN re-fits its chrome and payload, and the payload viewport in
    # turn re-fits its contents+scrollbars, so a width change that
    # re-wraps the tool grid converges IN THIS PASS. (A bare
    # _applyMoveTo/_applyExtent drive commits the viewport but re-fits
    # nothing, leaving the inner panel at a stale wrap height -- fg census
    # caught exactly that: ToolPanel 75 tall inside the 40 strip after a
    # narrow->wide window resize.)
    # ⚖ The bottom-right RESIZER may OVERLAP a right/bottom band's far corner
    # -- accepted DELIBERATELY (layout follow-ups plan F4), the same trade the
    # content already makes under resizerCanOverlapContents: the resizer is
    # corner-internal and always re-fronted, and what runs out to that corner
    # keeps its own pieces clear of it by occupancy (I name a right or bottom
    # band in bottomRightCornerReachedBy, so a toolbar strip in it ends its
    # last slot short of my grip, ToolPanelWdgt._farAlongPadding); the band
    # inset is the same on all four sides and does not grow to clear the
    # resizer, because that would couple the band's extent to the resizer and
    # break the left/right, top/bottom mirror symmetry.
    bodyMargin = @_bodyMargin()
    bandInset = @_dockedBandInset()
    bodyLeft = @left() + @_bodyEdgeLeft() + bodyMargin
    bodyTop = @top() + @_bodyEdgeTop() + bodyMargin
    bodyWidth = @width() - @_bodyEdgeLeft() - @_borderInset() - 2 * bodyMargin
    bandRun = Math.max 0, bodyWidth - 2 * bandInset
    columnTop = bodyTop + @_topDockThickness() + bandInset
    columnRun = Math.max 0, stackHeight - 2 * bandInset
    for side in FrameWdgt.DOCK_SIDES
      dockedFrame = @_dockedFrameAt side
      continue unless dockedFrame?
      bandThickness = dockedFrame._dockedBandThickness()
      switch side
        when 'top'
          bandBounds = new Rectangle new Point bodyLeft + bandInset, bodyTop + bandInset
          bandBounds = bandBounds.setBoundsWidthAndHeight bandRun, bandThickness
        when 'bottom'
          # just below the content: the band's top lands a body margin below
          # the content, and its bottom stands the band inset above where the
          # content region's bottom sits for the content's spec branch (my
          # bottom edge and body margin, or the reserved grip row above them
          # -- _chromeHeight carries the matching reservation either way)
          bandBounds = new Rectangle new Point bodyLeft + bandInset, bodyTop + @_topDockThickness() + stackHeight + bodyMargin
          bandBounds = bandBounds.setBoundsWidthAndHeight bandRun, bandThickness
        when 'right'
          bandBounds = new Rectangle new Point @right() - @_borderInset() - bodyMargin - bandInset - bandThickness, columnTop
          bandBounds = bandBounds.setBoundsWidthAndHeight bandThickness, columnRun
        else # 'left'
          bandBounds = new Rectangle new Point bodyLeft + bandInset, columnTop
          bandBounds = bandBounds.setBoundsWidthAndHeight bandThickness, columnRun
      dockedFrame._reLayout bandBounds

    # (the resizer needs no placement here: it is corner-attached — its CornerInternalLayoutSpec,
    # bottom-right at the grip's own inset past my border (FrameGripWdgt._cornerInsetFrom), is
    # applied by base _reLayout's corner tail against my final frame)
