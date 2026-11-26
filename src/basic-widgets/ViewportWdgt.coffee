# The scrolling VIEWPORT — invisible in EFFECT, not by abstention: my color/alpha MIMIC the
# plane's (see _buildViewportChromeNoSettle), so my own painted rect lies under the plane,
# indistinguishable, and shows as the plane's own surround in the margin I may keep around it
# (planeMargin). I own three pieces of chrome: the contents panel (the PLANE its
# content lives on — PINNED: scrolling never moves it; the stored scrollOffsetX/Y applies as
# a paint-time translation, see _writeScrollOffset/_scrollTranslation) and two SliderWdgt
# bars. NOT a PanelWdgt: a
# panel is a SURFACE whose children are content, while my children are chrome — my content
# lives one level down, on the plane — so the panel-family answers (its menu rows, its
# lock-granting, its drop slots) are wrong here, and the few panel facts I do mean are stated
# explicitly below (scroll-frame role plan P4).
#   My two bars, and how they are presented -- where each stands and how long it runs, how thick it
# is, when it shows, the hover pass that fattens them -- are my base's (ScrollIndicatorHostWdgt): I
# build them with my two scroll setters, and answer whether my plane overflows me along a bar's axis
# (_scrollAxisOverflows) and the margin they keep from the ends of their run (_scrollBarRunMargin).
class ViewportWdgt extends ScrollIndicatorHostWdgt

  # As a ClippingWdgt I clip my chrome (and through it the scrolled content) at my bounds, as
  # PanelWdgt and FrameWdgt do. Clipping also decides hit-testing together with the
  # RectangularAppearance the constructor sets: opaque inside my bounds, even though my own rect
  # is painted UNDER the plane — occluded, not skipped — wherever the plane shows.

  # the panel facts I genuinely mean, restated off PanelWdgt:
  # around-the-content padding a caller can add via setContents (reads: the arrange, the caret
  # follow)
  extraPadding: 0
  # an EMPTY generic viewport accepts drops (wantsDropOfChild consults the contents' veto)
  _acceptsDrops: true
  # a viewport is an editing surface: FrameWdgt shows the edit toggle off its contents'
  # answer, and the edit-mode focus walk climbs to the first opinion
  providesAmenitiesForEditing: true

  hasVelocity: true
  # MY PLANE MARGIN: a fixed distance, in whole pixels, between my edge and the box my plane shows
  # through (_planeBox). My own fill and border and my indicators stand in it; my plane is cropped at
  # its inner edge wherever a walk knows where my plane shows: my two paint bodies, and the
  # clip-through edge (_clipThroughForChild) that hit-testing, damage and every visible-box query
  # read. My plane still counts it as padding around its content (_positionAndResizeChildren), so my
  # scroll range, my clamps and my caret follow are a marginless viewport's: at both ends of a scroll
  # the content rests at the margin's inner edge. It is MAPPING state, as my scroll offset is (the
  # version-keyed clip caches fold it in, see _writeScrollOffset): on a live viewport it is written
  # through its one door, _writePlaneMargin, as the offset is through _writeScrollOffset (a
  # document keeps the theme's item spacing as its margin: DocumentViewportWdgt._takeItemSpacing).
  # While I keep one, a click in it selects my plane (resolvesEditorSelectionToContent), my plane's
  # selection ring stands in it (hostedSelectionRingBox) and an overlay laid over me frames my plane
  # box (boxPresentedToOverlays). It is not called `padding`: a handle reads that name off whatever
  # it is attached to, to know how far in from the corner it sits (HandleWdgt._cornerInsetFrom), and
  # a handle on me sits by my corner whatever my margin.
  planeMargin: 0
  isTextLineWrapping: false
  isScrollingByfloatDragging: true

  # ── SCROLL POLICY ──────────────────────────────────────────────────────────
  # 'auto'  — scroll iff content overflows. Bars are not a mode, they are the
  #           visible CONSEQUENCE of overflow: a fitting viewport already hides
  #           both bars and escalates every wheel, so it is behaviorally a
  #           plain panel with nothing to flip.
  # 'never' — behave as a plain cropping panel: every scroll path refuses at
  #           the movement cores (_scrollX/_scrollY), the bars never show, the
  #           wheel always escalates, and no scroll gesture engages (a press
  #           passes on through me to a pane around me, as a notch does). Contents
  #           sizing is DELIBERATELY unchanged — the contents panel still
  #           grows to its merged bounds and the overflow is clipped at my
  #           viewport, which IS plain-panel semantics.
  # Flipped live via setScrollPolicy (menu: toggleScrollPolicyFromMenu) with
  # no widget-tree change — policy over structure, the same verdict the
  # pop-ups reached for their unconditional rows viewport
  # (PopUpRowsViewportWdgt).
  scrollPolicy: 'auto'

  # Only the GENERIC viewport offers the crop⇄scroll flip in its menu:
  # the dedicated subclasses (list, toolbar, text, stack, pop-up rows, an
  # inspector browser's set) design their scroll behavior in, so there the
  # row would be menu rent plus a
  # footgun (cropping an inspector's list pane hides properties with no cue).
  # Each opts out with a one-line reason at its own declaration.
  offersScrollPolicyToggle: true
  contents: undefined

  # A gesture's scroll step (_scrollStep) does not ride a file: a restored world has no gesture in
  # progress, and the step is a closure no file can carry. (My hover state stays out of a file by my
  # base's declaration: ScrollIndicatorHostWdgt.)
  @serializationTransients: [
    "_scrollStep"
  ]

  # THE PER-FRAME STEP OF THE SCROLL A GESTURE OF MINE RUNS -- a drag-scroll's stroke and glide
  # (takeStrokeScrollFrom), or the edge auto-scroll while something is carried over my edge -- held
  # only while one runs: its presence is THE answer to "does a gesture of mine run" (and, while I live,
  # I am in the stepping set exactly then). Runtime state of the gesture, never a member: a save leaves it out,
  # and a copy or a restore runs no gesture of mine (_reactToBeingCopied, _afterDeserialization).
  _scrollStep: undefined

  # My step runs my gesture's scroll step. A `step` of a subclass's, or one a person gives me (an
  # inspector's Save, a run), replaces mine as any override of a member does: it calls `super` to keep
  # my gestures scrolling.
  step: ->
    @_scrollStep?()

  # A COPY runs no gesture of mine: it was aligned into the stepping set because I was in it
  # (Widget.alignCopiedWidgetToSteppingStructures) and holds my scroll step, a closure bound to me, so
  # it ends that step rather than go on scrolling me.
  _reactToBeingCopied: ->
    @_stopScrollStep()

  # A RESTORED viewport lays itself out again at the next settle, so its arrange re-derives what no
  # file carries: my bars' indicator presentation (SliderWdgt.indicatorMode, from my overflow and the
  # dropped hover state, _refreshScrollIndicators). A restored world is otherwise already settled, so
  # no arrange would come, and my bars would wear the plain slider's look -- a hollow thumb over a
  # track the saved alpha hides -- until something re-laid me out. Nor does it run a gesture: one
  # saved mid-gesture comes back in the stepping set (its membership is saved; its scroll step, a
  # transient, is not), which it leaves.
  _afterDeserialization: ->
    world.steppingWdgts.delete @
    @_scheduleRelayoutRespectingPhase()

  # Role query, the plane-side twin of isMyScrollBar (ScrollIndicatorHostWdgt's): is aWdgt the
  # contents panel I clip and scroll? THE one place the viewport topology is stated — the chokepoints
  # (_amITheContentsPanelOfAViewport, _amIDirectlyInsideViewport, the hierarchy
  # menu) ask this rather than pattern-matching the composite's shape, so ANY class serving as
  # my plane (the default ScrolledPaneWdgt, a FolderPanelWdgt, a ToolPanelWdgt, a stack)
  # answers uniformly. (scroll-frame role plan P3; type-test-elimination ε.)
  isMyContentsPanel: (aWdgt) ->
    aWdgt is @contents

  # Do my plane's DIRECT children live there as LOOSE scrollable content — things a drag may
  # scroll-or-detach, a caret follows into view, a lone text child offers soft-wrap for, a
  # container re-fit climbs through? True for a generic viewport; a ListWdgt answers false —
  # its pane holds the list's own rows machinery, not loose content — which is the exclusion
  # `_amIDirectlyInsideViewport`'s consumers relied on as `!(instanceof ListWdgt)`.
  contentsPanelHoldsLooseContent: ->
    true

  # My contents panel is internal structure — hide it from the ancestor hierarchy
  # (disambiguation) menu. Asked by Widget.hierarchyMenuWidgets via ?(); replaces two of its
  # structural exclusions (plain-panel-in-viewport, stack-in-stack-viewport — the
  # stack IS its viewport's contents). FolderWindowWdgt declares the third the same way.
  hidesContainedWidgetFromHierarchyMenu: (aWdgt) ->
    @isMyContentsPanel aWdgt

  # While I keep a margin, selecting ME selects my PLANE: a click in my margin -- the only place a
  # pointer meets me rather than my plane -- selects the page, as a click on the page's empty area
  # does, and its ring stands in my margin (I host it, below). Asked through ?() by the world as it
  # reads what the editor focus selects (WorldWdgt._widgetTheFocusSelects resolves me to my first
  # child that is no handle and no caret: my plane, my first child), and as it looks for the frame a
  # transform island wraps (_frameSeenThroughIslands, which my three children leave unanswered).
  # Without a margin I am selected as myself, like any widget.
  resolvesEditorSelectionToContent: ->
    @planeMargin > 0

  # ── the plane's up-relays (scroll-frame role plan P3) ─────────────────────────────────────
  # My paint values MIMIC my contents' (I DO paint every repaint, at alpha 1 once
  # _buildViewportChromeNoSettle adopts the contents' own — UNDER the plane wherever it shows,
  # where no pixel of mine is visible, and as what shows in the margin I may keep around it;
  # menus and readers see my fields either way), and the plane keeps them true by notifying me
  # when it is recolored directly. With no margin the write is all there is to do: my own paint
  # is fully occluded, and the plane's own super covers every visible recoloured pixel. While I
  # keep a margin (planeMargin) I repaint as well: my rect is what shows there, and the plane's
  # own repaint is cropped to the box it shows through (_planeBox), so it never reaches the
  # margin. Guarded on a real value: Widget.setColor returns undefined on a no-change call, and
  # writing that through would clobber the mimic.
  _reactToChildColorChanged: (child, aColor) ->
    return unless child is @contents and aColor?
    return if @color?.equals aColor
    @color = aColor
    @_changed() if @planeMargin > 0

  _reactToChildAlphaChanged: (child, alpha) ->
    return unless child is @contents and alpha?
    unless @alpha == alpha
      @alpha = alpha
      @_changed() if @planeMargin > 0

  # ── MY LOOK, read as I am painted ─────────────────────────────────────────────────────────
  # No fill or stroke colour of my own until one is set on me (or, as the mimic, on my plane):
  # until then my RectangularAppearance paints me in the roles below, so a viewport saved, loaded or
  # duplicated wears the look of the world it is shown in. The box I present -- me and my plane --
  # wears ONE look, the PANE's: its fill is my class's (_defaultPaneFill: the generic panel's, a
  # list's, a text area's, a stack's, a document's), its border the generic panel's, or the window
  # content's while I am a window's whole content -- unless a BUILDER dresses me in roles of its own
  # (wearPaneRoles: an inspector's panes, a code area, a patch node's text box, the bin's
  # pane, a folder window's viewport). Those I keep by NAME, so I wear them, read at paint, wherever
  # I am taken; a plane that holds no colour of its own wears my pane's look (ScrolledPaneWdgt).
  color: undefined
  strokeColor: undefined
  # the names of the WorldWdgt.theme roles a builder dresses me in (wearPaneRoles): my pane's fill
  # and my border; undefined, my own
  paneFillRole: undefined
  paneStrokeRole: undefined

  # Dress me in a builder's roles, each the NAME of a WorldWdgt.theme role: `fill`, my pane's fill
  # (and so my plane's), and `stroke`, my border (and my plane's; a role holding no colour draws
  # none). A role left out leaves me my class's look for it. The name must be a role the theme has.
  # A builder dresses me as it builds me, before I am shown, so my arrange places my indicators by
  # the border I am dressed in (_indicatorEdgeInset); dressed while shown, I repaint with my plane.
  wearPaneRoles: (roles = {}) ->
    theme = WorldWdgt.theme
    for role in [roles.fill, roles.stroke] when role? and role not of theme
      throw new Error "wearPaneRoles: the theme has no role named " + role
    @paneFillRole = roles.fill
    @paneStrokeRole = roles.stroke
    @_fullChanged() unless @isOrphan()

  # What I paint myself, under my plane wherever it shows and, in my margin, as what shows: my
  # plane's fill (the MIMIC -- a plane wearing a role of its own, a folder's panel, answers it; a
  # default plane answers my pane's), else my pane's.
  _surfaceFill: ->
    @contents?._surfaceFill?() ? @_paneFill()

  # THE FILL OF THE BOX I PRESENT, which a default plane wears (ScrolledPaneWdgt._surfaceFill): the
  # role a builder dressed me in, else my class's.
  _paneFill: ->
    (if @paneFillRole? then WorldWdgt.theme[@paneFillRole]) ? @_defaultPaneFill()

  # my class's pane fill: the generic panel's (a list, a text area, a stack and a document answer
  # their own)
  _defaultPaneFill: ->
    WorldWdgt.theme.panelFill

  # MY BORDER, which a default plane wears too (ScrolledPaneWdgt._surfaceStroke): the role a builder
  # dressed me in (holding no colour: none), else the generic panel's -- or, while I am a window's
  # whole content (my frame's contents, asked of where I stand as I paint), the window content's.
  _surfaceStroke: ->
    theme = WorldWdgt.theme
    return theme[@paneStrokeRole] if @paneStrokeRole?
    if @parent?.isMyContents?(@) then theme.windowContentPanelStroke else theme.panelStroke

  # Two independent scroll-by-drag flags (only live while scrollbars show): drag the
  # contents, or drag the background — independently, e.g. useful for a geographic map.
  canScrollByDraggingBackground: false
  canScrollByDraggingForeground: false

  constructor: (
    @contents,
    @scrollBarsThickness = (WorldWdgt.theme.scrollBarsThickness),
    @sliderColor
    ) ->
    # seed alpha 0 here; _buildViewportChromeNoSettle immediately overwrites it with the
    # contents' own (which defaults to 1) — my own values just MIMIC the plane's, and my
    # painted rect ends up occluded under the plane wherever it shows, not skipped (in my
    # margin it is what shows)
    @alpha = 0
    super()
    # the appearance also decides hit-testing: an appearance-bearing widget answers opaque
    # inside its tight bounds. It DOES paint every repaint (once the mimic adopts the
    # contents' alpha, typically 1) -- occluded under the plane wherever it shows, and what
    # shows in my margin -- in the look my hooks answer (MY LOOK, above)
    @appearance = new RectangularAppearance @
    @_buildViewportChrome()

  # Build the viewport (contents + h/v scrollbars) via the NoSettle core, settling ONCE at the end
  # (orphan-settledness: `new ViewportWdgt` returns settled). The name is deliberately DISTINCT from the
  # leaf builder `_buildAndConnectChildren`: ViewportWdgt is a base whose subclass ListWdgt OVERRIDES
  # `_buildAndConnectChildren` to build its list CONTENTS, and CoffeeScript binds a subclass's constructor
  # params (@elements, …) only AFTER super(). If THIS base constructor called the (virtual)
  # `_buildAndConnectChildren`, `new ListWdgt` would dispatch into ListWdgt's contents-core during super()
  # with @elements still undefined → crash. So the base builds only its own chrome here (a name ListWdgt
  # does not override); ListWdgt's constructor builds its contents via `_buildAndConnectChildren` AFTER super().
  _buildViewportChrome: ->
    @_settleLayoutsAfter => @_buildViewportChromeNoSettle()

  _buildViewportChromeNoSettle: ->
    @contents = new ScrolledPaneWdgt() unless @contents?
    # _addNoSettle (NOT the self-settling public add): we are building our own innards
    # during construction; I am not parented yet, so a flush here would be a
    # redundant whole-world relayout (and would throw if we are built during a layout pass).
    @_addNoSettle @contents

    # the Viewport paints every repaint just like any RectangularAppearance widget, occluded
    # under its own contents wherever they show and showing only in its margin -- so what
    # matters is that its values MIMIC the contained Panel's: its own colour, when it holds one
    # (else none, and my look's hooks answer for both of us)
    @color = @contents.color
    @alpha = @contents.alpha

    # my two bars, each driving one of my scroll pins: my base builds and wires them
    # (ScrollIndicatorHostWdgt._buildScrollBarsNoSettle), and places them once my plane is in
    @_buildScrollBarsNoSettle "setScrollX", "setScrollY"

    @_reLayoutScrollbars()

  wantsDropOfChild: (aWdgt) ->
    # the CONTENTS vetoes raw drops into the viewport (a folder's contents are managed by the
    # folder-window machinery) — capability via ?(), instead of `@contents instanceof FolderPanelWdgt`
    # (type-test-elimination ε)
    return false if @contents?.vetoesViewportDrops?()
    # the base door: my drops on, and no view-mode content around me (Widget.wantsDropOfChild)
    super(aWdgt)

  # WHO RECEIVES A DROP ON MY BODY -- on a point of me that none of my children covers: my margin
  # (planeMargin), where my plane is cropped away and my thin indicators let the pointer through.
  # That room is my plane's, as a window's page gutter is its page's, so a payload released there
  # goes to my plane by my plane's own drop rules, moved first inside the box it shows through
  # (ActivePointerWdgt._moveGutterDropInsideTarget). With no margin, nobody. PUBLIC: the hand asks it,
  # through ?(), of the top widget under the pointer (ActivePointerWdgt._dropClimbStart,
  # _targetReachedThroughAGutter), and a window holding me as its pane asks it for the points of its
  # own body (FrameWdgt.dropReceiverForPointsOnMyBody); the hand's dock offer and a press never ask it.
  #   THE LIMIT: it covers my body, so not the side of my margin a bar of mine stands FAT over. A
  # carry with no button held sends hover moves, which fatten my bars within a bar's width of my
  # right and bottom edges (hoverMoved), and a fat bar covers my margin on its side: the release
  # then meets the bar and not my body, as on any viewport. The bar names nobody, the climb from
  # it reaches me, and a payload I take is mine to take as released: my add hands it to my plane
  # where it was let go, moved nowhere. A carry under a held button keeps my bars thin.
  dropReceiverForPointsOnMyBody: ->
    if @planeMargin > 0 then @contents else undefined

  # ── MY PLANE'S SELECTION RING ──────────────────────────────────────────────────────────────
  # My plane is as tall as its content, so a ring inside its box scrolls away with it. I am the box
  # that stays, so while my plane is the selected widget I paint its ring: in my margin, the theme's
  # air out from my plane box, while my margin holds the ring's reach; else at my own box. The world
  # decides once per cycle who paints the selected widget's ring and around which box
  # (WorldWdgt._updateEditorSelectionOverlay), through the three public answers below, which a window
  # gives too for the page it keeps a gutter around (FrameWdgt). Painted from the seat a clipping
  # widget already has, last, over my plane, my bars and my border; my thin thumb is not moved for it.

  # Do I paint the selection ring of `aWdgt`? Of my plane, and of nothing else: an item on my plane
  # keeps its ring inside its own box. PUBLIC: asked through ?() by the world of the nearest ancestor
  # of the selected widget that answers it (WorldWdgt._editorSelectionRingHostOf).
  hostsSelectionRingOf: (aWdgt) ->
    @isMyContentsPanel aWdgt

  # THE BOX OF THE RING I paint for my plane, in my bounds' coordinates (not my plane's, which my
  # scroll translates): my plane box grown by the ring's reach while my margin holds it, else my own
  # box. The one home of its geometry, read by my paint and by the world, which keeps the last answer
  # and tells me when it changes. PUBLIC query, read live.
  hostedSelectionRingBox: ->
    reach = WorldWdgt.theme.pageSelectionOutlineReach
    if @planeMargin >= reach then @_planeBox().expandBy reach else @boundingBox()

  # PUBLIC notification from the world: the ring I paint for my plane came, went or moved. It lies
  # inside my box, so my own repaint covers it.
  noteHostedSelectionRingChanged: ->
    @_changed()

  # I show a selection overlay while I am selected myself, as any widget, and while I paint my
  # plane's ring.
  _showsSelectionOverlay: ->
    super() or world?.editorSelectionRingHost() is @

  # My plane's ring in my margin: the selection outline's own spelling (Widget._drawSelectionOverlay),
  # translated to the ring's box, its corners the ones I show there, its stroke half off (no border
  # runs under it in my margin). Any other ring of mine -- my own, or my plane's when my margin does
  # not hold it, which then stands at my box -- is Widget's.
  _drawSelectionOverlay: (aContext, al, at, w, h) ->
    unless world.editorSelectionRingHost() is @ and @planeMargin >= WorldWdgt.theme.pageSelectionOutlineReach
      return super aContext, al, at, w, h
    ringBox = @hostedSelectionRingBox()
    theme = WorldWdgt.theme
    aContext.save()
    aContext.clipToRectangle al, at, w, h
    aContext.globalAlpha = 1
    aContext.useLogicalPixelsUntilRestore()
    aContext.translate ringBox.left(), ringBox.top()
    HighlightOutlineAppearance.paintRing aContext, ringBox.width(), ringBox.height(), theme.selectionOutlineWidth,
      (@cornerRadiiFollowingMyOutline ringBox), theme.selectionOutline, false
    aContext.restore()

  colloquialName: ->
    # the CONTENTS names the construct ("folder"/"toolbar") — capability via ?(), was two
    # `@contents instanceof` tests (type-test-elimination ε)
    @contents?.viewportColloquialName?() ? "viewport"

  # ── THE SCROLL PINS ──────────────────────────────────────────────────────────────────────────
  # How far my content is scrolled inside my viewport, along each axis: 0 at the top/left, growing
  # to the overflow. These are the numbers my scrollbars drive and show, and until §P8 they were
  # reachable only by direct assignment — no connect menu offered them, and nothing could read them.
  #
  # ⚠ READABLE, where Widget's `width`/`height` deliberately are not (widget-authoring-guidelines
  # §11): a reader is a licence to BIND, and geometry is where the one-way layout↔dataflow law makes
  # that expensive. A scrollbar is precisely the case that needs it — it must FOLLOW what it drives —
  # so §P8 pays that price here and nowhere else, and my bars' arrange (`_reLayoutScrollbars`,
  # ScrollIndicatorHostWdgt's) is where the bill comes due.

  getScrollX: -> @scrollOffsetX

  getScrollY: -> @scrollOffsetY

  # ── THE STORED SCROLL OFFSET (paint-time-scroll-translation plan §3.1) ────────────────────
  # THE scroll state: how far the visible window sits into the content FRAME, per axis —
  # `windowOrigin_in_plane = @contents.position() + offset`. INTEGER, ≥ 0, clamped to
  # [0, max(0, contentExtent − windowExtent)] (_keepScrollOffsetInBounds). Scrolling never moves
  # the plane: children keep their plane coordinates forever, and the offset is applied as a
  # paint-time translation (the content-recursion override below) and consumed by the
  # screen↔plane mapping walks through the plane-mapping protocol (mapsPlaneOfChild and its
  # verbs, below). Two scalar prototype
  # defaults — scalars, NOT a Point (⛔ a class-level constant may never reference another
  # class, docs/architecture/immutable-value-classes.md §3), and scalars serialize
  # own-only-when-scrolled (the spreadsheet's viewOriginCol/Row pattern).
  scrollOffsetX: 0
  scrollOffsetY: 0

  # The plane→screen translation for my contents subtree: the visible window's plane rect is
  # [contents.position() + offset, … + my extent] and it renders at my own box, so a plane
  # point p appears at p + t with t below. Measured from the FRAME's origin (not my own
  # position) so a frame the arrange legitimately extends above/left of my origin — loose
  # content dragged past the top edge — keeps its old reachability arithmetic: the offset
  # grows with the frame (the arrange's origin-shift bookkeeping) and t stays 0 until a real
  # scroll happens.
  _scrollTranslation: ->
    new Point @left() - (@contents.left() + @scrollOffsetX), @top() - (@contents.top() + @scrollOffsetY)

  # THE BOX MY PLANE SHOWS THROUGH: my box less my margin on every side (planeMargin), and my box
  # itself (the same object) while I keep none, so every walk that crops to it is then the stock
  # walk. The ONE home of that box for the walks that crop: the clip-through edge crops to it
  # (_clipThroughForChild), and my paint crops my plane by that same answer.
  _planeBox: ->
    @boundingBox().insetBy @planeMargin

  # The margin my bars keep from the ends of their run (ScrollIndicatorHostWdgt._scrollBarRunMargin):
  # my plane margin, so a thin bar of mine runs along the side of the box my plane shows through, and
  # a bar I present shows only where that side holds its thumb.
  _scrollBarRunMargin: ->
    @planeMargin

  # THE BOX I PRESENT TO AN OVERLAY laid over me (Widget's answer names the overlays that ask): what
  # shows of me (clippedThroughBounds), less my margin while I keep one, so such an overlay frames my
  # plane, where what I hold shows, and not the margin around it. In my bounds' coordinates, as
  # clippedThroughBounds is (not my plane's, which my scroll translates).
  boxPresentedToOverlays: ->
    shown = @clippedThroughBounds()
    if @planeMargin is 0 then shown else shown.intersect @_planeBox()

  # THE PLANE-MAPPING PROTOCOL, my half (TransformFrameWdgt answers it too, for its content).
  # Widget's screen↔plane walks — mapRectToScreen, screenPointToMyPlane, localPointToScreen,
  # screenBounds, and the iterator they share, _enclosingMappedPlaneRoot — ask every ancestor
  # they climb through whether it maps the plane of the child they climbed from. I do ONLY
  # for my contents edge — my bars are FIXED children of the same parent, so the §7.6
  # fixed-vs-scrolled-children split is answered structurally, per child edge, with no stored
  # role — and ONLY when the translation is real: at (0,0) I map nothing, the walks pass me
  # by, and their same-object dormant returns are preserved. The zero test reads the two
  # differences _scrollTranslation builds its Point from, so it builds none.
  mapsPlaneOfChild: (child) ->
    child is @contents and
      ((@left() - (@contents.left() + @scrollOffsetX)) isnt 0 or (@top() - (@contents.top() + @scrollOffsetY)) isnt 0)

  # The protocol's verbs: my contents' plane maps to mine by the translation t above, computed
  # first and then added (a point, a rect) or subtracted (the inverse) — EXACT: no padding, and
  # no buffer damage to deposit (nothing resamples), whatever the damage lane asks.
  mapPointFromChildPlane: (aPoint) ->
    aPoint.add @_scrollTranslation()

  mapPointIntoChildPlane: (aPoint) ->
    aPoint.subtract @_scrollTranslation()

  mapDamageRectFromChildPlane: (aRect, depositBufferDamage) ->
    aRect.translateBy @_scrollTranslation()

  mapRectExactFromChildPlane: (aRect) ->
    aRect.translateBy @_scrollTranslation()

  # an island's clip met further in is carried along, so the damage lane's one final intersect
  # meets the mapped damage in the same (screen) plane
  mapClipFromChildPlane: (clipSoFar) ->
    clipSoFar?.translateBy @_scrollTranslation()

  # The translation itself, for the walks that need the vector rather than a mapping
  # (cornerRadiiFollowingMyOutline, my own add, and my clip-through answer below): t when I map the
  # child's plane, else undefined.
  scrollTranslationOfChild: (child) ->
    if @mapsPlaneOfChild child then @_scrollTranslation() else undefined

  # THE CLIP ONE OF MY CHILDREN SHOWS THROUGH, IN THAT CHILD'S OWN PLANE. `clipSoFar` is the clip that
  # reaches me, in my plane. My contents show inside my plane box and through my scroll translation,
  # so theirs is that clip cropped to the box, then expressed in their plane (a screen box B
  # constrains plane points p with p + t in B, so p in B - t). My bars and whatever else stands on me
  # directly show in place, uncropped. With no margin and no translation the same object goes
  # through. My answer to ClippingWdgt's question, for my contents: the clip-through walk asks it, when
  # I am its first clipping ancestor, for my direct child on its chain -- per child edge, as
  # scrollTranslationOfChild is (ClippingWdgt.clipThroughForDescendant) -- and so does my paint.
  _clipThroughForChild: (clipSoFar, child) ->
    return clipSoFar unless child is @contents
    cropped = if @planeMargin is 0 then clipSoFar else clipSoFar.intersect @_planeBox()
    translation = @scrollTranslationOfChild child
    if translation? then cropped.translateBy translation.neg() else cropped

  # The paint-time scroll (plan §3.3), intercepted at the same content-recursion point the
  # island composites at: self (the mimic rect) and the BAR children paint in place; the
  # CONTENTS subtree paints inside my plane box (_planeBox: the damage is cropped to it, so with a
  # margin my own rect is what shows there) and through the scroll translation — the shadow-pass
  # two-step (cull rect moved opposite the paint, ctx translated with it; both integer × dpr, so
  # the CTM composition is FP-exact). Culling needs nothing more: each descendant intersects the
  # descending rect with its own plane-local bounds, so scrolled-out content prunes exactly
  # as clipped-out content does, and so does content under my margin (a cull that the crop leaves
  # empty paints nothing). Zero translation and no margin take the stock clipping path —
  # dormancy — ClippingWdgt's body, through `super`. The crop here IS the clip-through edge's answer
  # (_clipThroughForChild), so the paint and the visible boxes read one box, as they must: a resident
  # records the area it painted from the clip-through walk (_recordDrawnAreaForNextDamageRects).
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    t = @_scrollTranslation()
    if t.x is 0 and t.y is 0 and @planeMargin is 0
      return super aContext, clippingRectangle, appliedShadow
    damagedPartOfFrame = @boundingBox().intersect clippingRectangle
    if !damagedPartOfFrame.isEmpty()
      if aContext == world.worldCanvasContext
        @_recordDrawnAreaForNextDamageRects()
      @paintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow
      # my plane shows inside my plane box, through my translation; every other child in place
      planeCull = @_clipThroughForChild damagedPartOfFrame, @contents
      @children.forEach (child) =>
        if child is @contents
          aContext.save()
          aContext.translate t.x * ceilPixelRatio, t.y * ceilPixelRatio
          child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, planeCull, appliedShadow
          aContext.restore()
        else
          child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow

  # The SHADOW-pass twin of the interception above (paint-time scroll review F3): ClippingWdgt's
  # own-shadow entry enumerates children itself — bypassing the content pass — so without this
  # a viewport wearing its OWN shadow, painting translucent (alpha != 1, the one case whose
  # silhouette depends on the children), while scrolled or keeping a margin, would silhouette the
  # UNTRANSLATED, UNCROPPED content. Same crop and two-step around the contents child, same dormant
  # delegation to ClippingWdgt's body through `super`.
  _fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
    t = @_scrollTranslation()
    if t.x is 0 and t.y is 0 and @planeMargin is 0
      return super aContext, clippingRectangle, appliedShadow
    # from here: ClippingWdgt's JustShadow body (in lockstep with it, step for step, but for the
    # children's step: ClippingWdgt's ⚠ LOCKSTEP note), with the contents child painted inside my
    # plane box and through the scroll translation, my other children in place
    clippingRectangle = clippingRectangle.translateBy appliedShadow.offset.neg()
    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      damagedPartOfFrame = @boundingBox().intersect clippingRectangle
      if !damagedPartOfFrame.isEmpty()
        aContext.save()
        aContext.translate appliedShadow.offset.x * ceilPixelRatio, appliedShadow.offset.y * ceilPixelRatio
        @paintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow
        # opaque short-circuit as in ClippingWdgt's: a fully opaque box's silhouette IS its box
        if @alpha != 1
          shadowPlaneCull = @_clipThroughForChild damagedPartOfFrame, @contents
          @children.forEach (child) =>
            if child is @contents
              aContext.save()
              aContext.translate t.x * ceilPixelRatio, t.y * ceilPixelRatio
              child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, shadowPlaneCull, appliedShadow
              aContext.restore()
            else
              child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow
        aContext.restore()

  # The pin-setter contract (widget-authoring-guidelines §11): every delivery passes ONE argument,
  # the value.
  #   ⚠ CLAMPED, through the same `_scrollX`/`_scrollY` every other scroll path uses. The predecessor
  # moved the content raw, which could commit an over-scrolled state no gesture can produce (the
  # defect `scrollTo`'s own comment records). It also matters now that the bars are really wired: a
  # bar that is hidden because there is nothing to scroll still holds its constructed default, and
  # clamping is what makes delivering that a no-op instead of shoving the content off its viewport.
  setScrollX: (num) ->
    num = parseFloat num  unless typeof num is "number"
    return  if isNaN num
    if @_scrollX @scrollOffsetX - num
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()
    return num

  setScrollY: (num) ->
    num = parseFloat num  unless typeof num is "number"
    return  if isNaN num
    if @_scrollY @scrollOffsetY - num
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()
    return num

  # ⭐ Both ANNOUNCE, and the audit behind that word is short only because the class is built so that
  # it can be: EVERY path that moves my content — a wheel, a thumb drag, a track click, a caret
  # scrolled into view, a drop that re-fits me, `scrollTo`, `scrollToBottom`, the two setters above —
  # ends at `_reLayoutScrollbars`, and that is where the announcement is raised. So a follower is
  # woken whatever moved the scroll, which is exactly the promise `announces` makes.
  #   ⚠ The promise is about the FUNNEL, not about the setters. A class whose setter announces but
  # whose gesture path does not would be announcing a subset and saying so with the same word — see
  # PaletteWdgt, whose own audit found precisely that shape.
  pins: -> super().concat [
    new PinSpec "scroll x", "numerical", set: "setScrollX", get: "getScrollX", announces: true
    new PinSpec "scroll y", "numerical", set: "setScrollY", get: "getScrollY", announces: true
  ]

  # What SCALE does this pin of mine live on, for a slider bound to it? (SliderWdgt.reflectTarget.)
  # The VALUE itself the slider reads through the pin's own reader; these are the three numbers a
  # thumb needs besides it — which is why the reverse edge carries no payload of its own.
  sliderRangeForPin: (pin) ->
    switch pin.label
      when "scroll x" then @_scrollRangeAlong @width(), @contents.width()
      when "scroll y" then @_scrollRangeAlong @height(), @contents.height()
      else undefined

  # One axis' scale: I can be scrolled along it exactly when my content overflows my viewport — the
  # same test that decides whether the bar shows at all — the scale runs from 0 to that overflow, and
  # the thumb covers the visible fraction of it, all in pixels (SliderRange.forScrolling, the
  # arithmetic every scroller shares). `undefined` when there is nothing to scroll: a bar showing an
  # empty scale means nothing, and a zero-width one divides by zero in the thumb geometry.
  _scrollRangeAlong: (viewport, content) ->
    # under 'never' there is no scale to live on — a bound external slider gets
    # the same "nothing to scroll" answer as the fitting case
    return undefined if @scrollPolicy is 'never'
    SliderRange.forScrolling viewport, content

  # The runtime crop⇄scroll flip: validate, assign, then INVALIDATE inside a
  # settle — the flush re-lays me (my _reLayout is 'super; @_reLayoutChildren'),
  # so a flip on a live overflowing viewport shows/hides its bars and re-clamps
  # its contents in one pass, through the standard deferred shape. The scroll
  # pins stay advertised under 'never' (a policy flip mid-life must not sever
  # wires) — a delivery simply no-ops at the refused cores.
  setScrollPolicy: (policy) ->
    return unless policy is 'auto' or policy is 'never'
    return policy if policy is @scrollPolicy
    @scrollPolicy = policy
    @_settleLayoutsAfter => @_invalidateLayout()
    return policy

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu for the shape): the
  # menu items carry no arguments, and dispatch fills the leading slots with
  # the menu item + the enclosing panel's target, so the real setter must not
  # be wired directly.
  toggleScrollPolicyFromMenu: (ignored, ignored2) ->
    @setScrollPolicy (if @scrollPolicy is 'never' then 'auto' else 'never')

  setColor: (aColor) ->
    aColor = super aColor
    # keep in sync the color of the content.
    # Note that the container Viewport
    # paints every repaint too (mimicking this color): occluded underneath the content wherever
    # that shows, and what shows in its margin.
    @contents.setColor aColor
    return aColor

  setAlphaScaled: (alpha) ->
    alpha = super
    # update the alpha of the Viewport - note that I paint it every repaint too (occluded
    # under the contents wherever they show, and what shows in my margin), so keep updating
    # it so its value mimics the contained Panel's
    @contents.setAlphaScaled alpha
    return alpha

  # CAN I be scrolled right now: is there overflow to move, and does my policy allow moving it?
  # This is the question every scroll GESTURE asks — deliberately NOT "is a bar visible". Under
  # ruling G4 an indicator is a THIN hairline the pointer passes through, so keying a gesture to
  # a bar's visibility would key it to presentation.
  isScrollableNow: ->
    return false if @scrollPolicy is 'never'
    (@contents.width() >= @width() + 1) or (@contents.height() >= @height() + 1)

  # Would a plain drag pressed anywhere in me be MINE — a scroll of my pane? The hand asks this of
  # a press's ancestry to know whether a finger has to HOLD before its drag can mean what a mouse
  # drag means (ruling I2: a hold is demanded only where a plain drag already means scroll). It is
  # the same three facts that make me a pane a stroke can latch (strokeScrollPaneFor) — I take drags
  # at all, my policy allows scrolling, and there is overflow to move — asked before the press
  # instead of during it.
  claimsPlainDragsForScrolling: ->
    @isScrollingByfloatDragging and @isScrollableNow()

  # Does my plane overflow me along `bar`'s axis, under a policy that lets me scroll
  # (ScrollIndicatorHostWdgt._scrollAxisOverflows)? Along my horizontal bar's axis, my plane's width
  # against mine; along my vertical one's, its height against mine: the facts isScrollableNow reads,
  # one axis at a time. It decides whether that bar shows, and whether it crosses my corner.
  _scrollAxisOverflows: (bar) ->
    return false if @scrollPolicy is 'never'
    if bar is @hBar
      @contents.width() >= @width() + 1
    else
      @contents.height() >= @height() + 1

  # RE-PARENTED: the line at my edge is where I stand (a window holding me as its whole content
  # runs its own border round me, and I stroke none: _surfaceStroke), and my thin indicators stand
  # clear of that line (_indicatorEdgeInset), so they are placed again for my new parent. Not every
  # re-parenting arranges me: a window that adopts me while my layout is pending does, but dropped
  # back onto the desk I keep my extent, and an unchanged extent re-fits nothing. Placing my bars
  # settles nothing and marks no layout, so it is done here, inside the add, as the hover pass does
  # it on a flip of its own.
  _reactToBeingAdded: (whereTo, beingDropped) ->
    super
    @_reLayoutScrollbars()

  # The width my @contents must lay itself out within: my viewport width. Asked via ?() by
  # content that wraps to its container (ToolPanelWdgt's row-wrap). Capability, was
  # `parent instanceof ViewportWdgt` at the caller (type-test-elimination ε).
  widthContentsMustFitWithin: ->
    @width()

  # The height twin, for content that fits to BOTH axes of the box it is given (a toolbar
  # grid deciding how many cells its strip shows before the rest go behind the chevron).
  heightContentsMustFitWithin: ->
    @height()

  # (no childrenCanLockToMe here: my direct children are chrome, not user-lockable content, and
  # the lock-menu row keys on the capability EXISTING — see PanelWdgt.childrenCanLockToMe —
  # so a viewport simply not defining it is the opt-out)

  # Am I a content-sizing viewport — one whose content frame derives from a PURE measure
  # of @contents's children (§4.1 Stage C, see _positionAndResizeChildren)? A subclass whose plane
  # ALWAYS measures itself from its own children answers true at its own declaration (a text area's
  # text, a stack's elements, an inspector browser's set of columns); a plain viewport is one while it
  # wraps its text. A class-level query the arrange site asks, in place of a type test.
  _isContentSizing: ->
    @isTextLineWrapping

  # when you add things to the ViewportWdgt they actually
  # end up in the plane inside it.
  # This would also apply to resizing handles - so we need to
  # correct for that case
  add: (aWdgt, opts = {}) ->
    # annotation + handle both attach to the viewport directly (was their two instanceof)
    # (type-test-elimination campaign). Keyed off the WIDGET, not the layoutSpec argument:
    # handles are added with no explicit spec (defaultLayoutSpecWhenAddedTo resolves it inside
    # the add), so the argument is undefined exactly for the widgets this must catch.
    if aWdgt.attachesToViewportDirectly?()
      super
    else
      # crossing the plane edge: opts.positionInPlane arrives expressed in MY plane (the drop
      # dispatcher maps it for the drop TARGET, which is me on this path) — re-express it in
      # the CONTENTS plane, or a scrolled plane's insert-index compare is short by exactly the
      # scroll translation (paint-time scroll review F2). Inverse = subtract, the same
      # arithmetic screenPointToMyPlane applies at this edge; no-op when unscrolled.
      if opts.positionInPlane? and (translation = @scrollTranslationOfChild @contents)?
        opts = Object.assign {}, opts, positionInPlane: opts.positionInPlane.subtract translation
      @contents.add aWdgt, opts
      # Intentional synchronous APPLY (not an off-settle trigger to defer): add / addMany /
      # showResizeAndMoveHandlesAndLayoutAdjusters are public content-change ENDPOINTS, idempotent
      # with this viewport's own _reLayout ('super; @_reLayoutChildren'), distinct from the seam sites
      # (raw-mutator / gesture triggers), which DO defer -- see
      # docs/archive/deferred-layout-residuals-audit.md. Deferring this re-fit was tried and rejected
      # (diverges nested-scroll geometry for zero gain) -- see
      # docs/archive/layout-system-architecture-assessment.md, "Do not revisit (already falsified)".
      # layout-apply-sanctioned: public content-change endpoint, idempotent w/ _reLayout (OVERVIEW §11 PROOF 2)
      @_reLayoutChildren()

  # thin-wrap-exempt: SYNCHRONOUS content-change endpoint -- @contents.addMany + immediate @_reLayoutChildren
  # (re-reading APPLIED geometry is load-bearing; deferring it diverges nested-scroll geometry, exactly as
  # for add() -- see docs/archive/layout-system-architecture-assessment.md, "Do not revisit"). The
  # _addManyNoSettle twin below is the non-settling core for in-flush callers (createToolsPanel), NOT a
  # settle the public form should route through.
  addMany: (widgetsToBeAdded) ->
    @contents.addMany widgetsToBeAdded
    @_reLayoutChildren() # layout-apply-sanctioned: public content-change endpoint -- see add() (OVERVIEW §11 PROOF 2)

  # NON-settling core: forward to @contents' addMany core (the buttons attach to the scrolled ToolPanelWdgt, NOT
  # this viewport -- like add() -> @contents.add above), then SCHEDULE this viewport's re-fit. The enclosing wrapper's
  # flush applies it -- vs the public addMany's synchronous @_reLayoutChildren endpoint (which is off-settle).
  _addManyNoSettle: (widgetsToBeAdded) ->
    @contents._addManyNoSettle widgetsToBeAdded
    @_invalidateLayout()


  # Override the NON-settling CORE (the public showResizeAndMoveHandlesAndLayoutAdjusters wrapper is inherited from
  # Widget and self-settles once around the whole show-handles tree). super adds the handles + climbs; @_reLayout
  # Children re-fits my contents+scrollbars synchronously, riding that outer settle. (end-of-cycle-flush-drawdown.)
  _showResizeAndMoveHandlesAndLayoutAdjustersNoSettle: ->
    super
    @_reLayoutChildren()

  
  setContents: (aWdgt, extraPadding = 0) ->
    @extraPadding = extraPadding
    # the outgoing contents is construction scaffold (every caller replaces a
    # just-built default with the real content) -- destroy it outright: closing
    # it instead would file unreferenced debris into the bin on every panel build.
    @contents.fullDestroyChildren()
    @contents._applyMoveTo @position()
    # fresh content: any prior scroll state is meaningless
    @_writeScrollOffset 0, 0

    aWdgt._applyMoveTo @position().add @planeMargin + @extraPadding

    @add aWdgt


  # SCROLL-POSITION POLICY, not a child re-lay (schedule-valve V1): a REAL immediate resize of a
  # text-wrapping viewport resets its scroll to the content origin (offset := 0 — the shipped
  # reset-scroll-on-resize behaviour; re-wrapped text re-reads from the top), while a re-lay at an
  # unchanged viewport must never touch the scroll position. The reset lives AT the resize event
  # because only the event knows the delta — a scheduled/settle re-lay enters _reLayout with the
  # extent already committed, so an extent-delta gate inside _reLayout structurally cannot see an
  # immediate resize. Resetting BEFORE super is safe (the plane never moves; only the offset
  # zeroes); the arrange that follows (via the resize re-lay) then merges and clamps as usual.
  # A plane that keeps its scroll across resizes (a wrapping STACK, whose scroll position the
  # arrange's clamp owns and normalizes) declares itself out — managesOwnScrollPinning, the P5
  # contract: under the offset model the seam is purely this reset POLICY per plane kind, no
  # longer a question of who may write the plane's position (nobody moves a plane any more).
  _applyExtent: (aPoint) ->
    if !aPoint.equals(@extent()) and @isTextLineWrapping and !@contents.managesOwnScrollPinning?()
      @_writeScrollOffset 0, 0
    super aPoint


  # Gesture-driven container re-fit (a widget was dropped into / grabbed out of me): DEFER it to the
  # cycle via _reFitContainer -> _scheduleRelayoutRespectingPhase. These are dispatched from
  # ActivePointerWdgt.drop/grab AFTER a self-settling add, so they always run OUTSIDE any layout pass --
  # the off-pass arm (invalidate self; my _reLayout is 'super; @_reLayoutChildren', so the cycle re-fits
  # me identically) is what runs. The in-pass arm (a no-climb enqueue, for a caller that DOES fire
  # mid-pass) is never exercised here. See deferred-layout-residuals-audit.md fam 2.
  _reactToChildDropped: ->
    @_reFitContainer()

  _reactToChildGrabbed: (child) ->
    @_reFitContainer()

  # Re-fit my contents area and my scrollbars: the named "re-fit me" pair, shared
  # by every trigger that changes what I contain (drops, grabs, attaches, a
  # contained panel's notification). Inherited by ListWdgt and the other viewports
  # -- they all re-fit the same way (the ListWdgt opt-out below is ONLY
  # for the contained-panel notification, not for this pair).
  _reLayoutChildren: ->
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # ===== Phase 3b (Slice 1): re-fit on the _reLayout cycle =====
  # A viewport re-fits its contents+scrollbars during recalculateLayouts (deferred),
  # not only via the inline _reLayoutChildren triggers. super (Widget::_reLayout) applies
  # MY OWN new bounds FIRST -- consuming @desired* and, on a real resize, re-fitting via the
  # _applyExtent override -- and THEN we re-fit to the (now-applied) viewport. Establishing
  # own bounds before re-fitting the contents is the DETERMINISM.md case-3c discipline (a
  # custom _reLayout must apply its own bounds before laying out what it contains). On a pure
  # resize the re-fit here is redundant with the _applyExtent override and idempotent; on a
  # content-only change (Phase 3b Slice 2, when the inline triggers become _invalidateLayout)
  # it is the one that runs.
  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  # implementsDeferredLayout is `@_reLayout != Widget::_reLayout`, so the _reLayout above would
  # otherwise flip it true and change TWO read sites: (A) _setWidthSizeHeightAccordingly
  # (invalidate-on-resize) and, the load-bearing one, (B) subWidgetsMergedFullBounds -- a
  # deferred-layout child contributes only its viewport rect, not its scrolled subtree, which would
  # shrink a NESTED viewport's reported content size and regress nested-scroll (the proven 16->18
  # Path-A trap). We pin it PERMANENTLY to false, re-examined and reconfirmed through the sizing-model
  # unification arc (U3/U4): do not un-pin without a driving defect. See
  # docs/archive/sizing-model-unification-plan.md.
  implementsDeferredLayout: ->
    false

  _reLayoutChildrenAndScrollbars: ->
    @_reLayoutChildren()

  # A contained panel (e.g. a vertical stack acting as my @contents) tells me
  # its set of children changed, so I re-fit. I return true so the panel knows I
  # took over its re-layout (my _positionAndResizeChildren already re-lays my contents
  # out) and needn't do its own. This is the polymorphic replacement for
  # VerticalStackPanelWdgt testing `@amIPanelOfScrollPanelWdgt()`: the
  # stack just notifies its parent, and only a viewport reacts. NB kept
  # SEPARATE from _reLayoutChildrenAndScrollbars / _reactToChildDropped / _reactToChildGrabbed on
  # purpose -- a ListWdgt opts OUT of THIS notification (see ListWdgt) yet still
  # re-fits on its own drops/grabs/attaches.
  _reLayOutAfterContainedPanelChange: ->
    @_reLayoutChildrenAndScrollbars()
    return true

  _positionAndResizeChildren: ->

    # if the viewport has isTextLineWrapping set, it means that you don't want the text widget
    # to extend indefinitely as you are typing. Rather, the width will be constrained and the
    # text will wrap.
    padding = Math.floor @extraPadding + @planeMargin
    totalPadding = 2*padding

    # The scrolled-content CONTRACT (scroll-frame role plan P5): the plane DECLARES its sizing
    # relationship to me — width ownership, interior-arrange delegation, the measure — and I
    # read declarations here instead of testing its class.
    if @contents.arrangesOwnScrolledChildren?()
      # (schedule-valve V1) a WIDTH-CONSTRAINING stack's width is MY contract (it tracks the
      # viewport; macroWindowCellsInConstrainedScrollStackReflow regressed without this), its
      # height falls out of the merge-commit below. A FREE-width stack OWNS its width -- the
      # whole point of the horizontal scrollbar -- so normalizing it would valve-schedule a
      # re-grow every arrange and ping-pong onto the end-of-cycle flush (the capstone gate
      # caught exactly that on macroFreeWidthScrollStackShowsHorizontalScrollbar). Width-only:
      # nothing between here and the commit reads the stack's height.
      if @contents.viewportConstrainsMyWidth?() and @contents.width() != @width()
        @contents._applyWidth @width()
      # arrange the content stack's children; I OWN its frame regardless (I size it from the §4.1 pure
      # measure -- subBounds -> the frame commit below), and the stack's terminal self-resize notifies nobody
      # (the notify-by-mutation seam is deleted).
      @contents._positionAndResizeChildren()
    else if @isTextLineWrapping
      # (schedule-valve V1) wrap width derives from MY viewport, not @contents.width(): the two are
      # equal at the fixpoint (the merge-commit below pins contents width to mine for wrap viewports),
      # but mid-transient — my frame just resized, contents not yet re-committed — only @width() is
      # current. The re-wrap itself is the plane's (?.-dispatched; only a default plane defines it).
      @contents._reWrapTextChildrenTo? @width() - totalPadding

    # §4.1 Stage C (proper-layouts): a content-sizing viewport (text-wrapping / vertical-stack / plain-text)
    # derives its content frame from a PURE measure of @contents's children (subWidgetsMergedPreferredBounds)
    # rather than mutating them and reading their merged APPLIED bounds back. This breaks the frame-sizing's
    # dependency on the children having been resized first -- the mutate-then-read-back the re-fit seam exists
    # for (assessment §2.4) -- yet is byte-identical (measured extent == applied at the fixed point; Stage-C
    # probe 0/1429 converged mismatches). The stack measures at its own width (it subtracts its own padding);
    # a bare text panel measures its children at the scroll-padding-inset width (== the _applyWidth re-wrap
    # above). The else-branch (folder / toolbar) is NOT a content-sizing target and keeps the applied read-back.
    # The MEASURE is the plane's own declaration (scrolledContentMeasure — a stack measures at
    # its own width, a plain plane at the hint; the P5 contract), the width hint is mine.
    isContentSizing = @_isContentSizing()
    if isContentSizing
      # (schedule-valve V1) same viewport-derived width hint as the re-wrap above — see that comment.
      subBounds = (@contents.scrolledContentMeasure? @width() - totalPadding)?.ceil()
    else
      # (D4, U3-A) the ONE named state-read: user-placed free-floating children's positions
      # are state, and nothing above mutated them -- see subWidgetsMergedFullBounds's comment.
      subBounds = @contents.subWidgetsMergedFullBounds()?.ceil()
    if subBounds

      # For a content-sizing stack/text panel: never stretch the view past the end of @contents (e.g.
      # after deleting text while scrolled to the bottom -- we don't want to reveal vacant space, we
      # want to shrink up and keep the bottom in view). So size first to the components' minimum area,
      # then grow only enough to fill the viewport.
      if isContentSizing
        newBounds = subBounds.expandBy(padding).ceil()

        # A plane whose measure IS its whole frame (a tight both-axes hug — CommandPanelWdgt,
        # the P5 contract's scrolledContentMeasureIsMyFrame declaration) gets the measure
        # committed VERBATIM: the width floor and grow-to-fill below suit a tight:false plane,
        # and against a tight hug they manufacture a two-writer fight whenever the viewport is
        # transiently larger than the hug (measured in the menu-sandwich dissolution's Phase 0:
        # menu-compose and duplication livelocks).
        unless @contents.scrolledContentMeasureIsMyFrame?()
          # Anchor to the frame's own left/top even when subBounds starts elsewhere (e.g. a single
          # centered icon) -- otherwise merging bounds that start off-origin would shift the panel so
          # the icon's left aligns with the frame's left, un-centering it. The merge rect spans my
          # full width but only 1px of height, so it also guarantees newBounds.width() >= @width() --
          # only the height may still fall short of the viewport:
          newBounds = newBounds.merge new Rectangle @contents.left(), @contents.top(), @contents.left() + @width(), @contents.top() + 1

          if newBounds.height() < @height()
            newBounds = newBounds.growBy new Point 0, @height() - newBounds.height()
      else
        # the frame covers the padded content, the visible WINDOW, expressed in the frame's
        # plane (frame origin + offset), and my own box, which is the window at rest. My own
        # box keeps the vacant strip between my origin and content placed in from it inside
        # the frame whatever the scroll, so no scroll drops it: the offset moves by exactly a
        # scroll's travel, and scrolling back returns the content to where it rested. The
        # frame still extends above/left of my origin for content overhanging it (the D2
        # island-overhang scroll-reachability), which is why the offset is measured from the
        # FRAME origin rather than mine.
        windowInPlane = new Rectangle @contents.left() + @scrollOffsetX, @contents.top() + @scrollOffsetY,
          @contents.left() + @scrollOffsetX + @width(), @contents.top() + @scrollOffsetY + @height()
        newBounds = subBounds.expandBy(padding).merge(windowInPlane.ceil()).merge @boundingBox()
    else
      newBounds = @boundingBox()?.ceil()

    unless @contents.boundingBox().equals newBounds
      # frame-origin bookkeeping (paint-time scroll): the window's plane position is
      # frame origin + offset, so a commit that MOVES the frame's origin (content grew
      # above/left of it, or shrank away from the top) must slide the offset by the same
      # amount to keep the VISIBLE window put — the moved-plane model got this for free.
      # A resulting negative offset is the _keepScrollOffsetInBounds clamp's business (below).
      originShift = @contents.position().subtract newBounds.origin
      @_writeScrollOffset @scrollOffsetX + originShift.x, @scrollOffsetY + originShift.y
      # §4.2 Stage 3 (structural arrange): I OWN my content's frame -- I computed newBounds from the §4.1 pure
      # measure (subBounds), so apply it via the NON-notifying twin. The old _commitBounds fired the re-fit
      # seam back at ME (Intent-2 self-re-enqueue = the capstone's Pattern D), redundant since I am the one sizing
      # the content; the seam only delivered a confirm pass that the §4.1 measure already makes a no-op.
      @contents._commitBounds newBounds
      @contents._reLayoutSelf()
      # (schedule-valve V1; gate made STRUCTURAL by §9-N4, docs/archive/ordered-downwalk-stage-b-plan.md)
      # a contents WITH ITS OWN ARRANGE places its children in its _reLayout (ToolPanelWdgt wraps its
      # buttons); committing its new frame via the non-notifying twin re-fits only its SELF layer, so
      # schedule its full re-lay through the phase-valve -- in-pass the same flush's next round heals
      # it, off-pass the wrapping settle does. The engine heals the interior; this arrange never
      # re-lays it synchronously. (Also covers the FrameWdgt early-settle route, where the later
      # engine re-visit sees no frame delta for the injection to act on.) The gate is
      # implementsDeferredLayout, NOT children.length: a base-_reLayout contents (the plain PanelWdgt
      # of every ordinary viewport) gets nothing from a full re-lay beyond the _reLayoutSelf
      # above, and this arrange is ALSO reached off-settle by the sanctioned synchronous
      # content-change endpoints (public add/addMany -> _reLayoutChildren) and the drag-to-scroll
      # step -- a children.length gate made every such call push the contents onto the end-of-cycle
      # flush (34 careless pushes across 10 scroll tests, plan §11).
      if @contents.implementsDeferredLayout()
        @contents._scheduleRelayoutRespectingPhase()

    # Always run this check even when @contents.boundingBox() already equals newBounds: a stack can
    # resize itself in the foreach loop above without changing the outer frame, so the view can still
    # need fixing. Cheap to check when there's nothing to do.
    @_keepScrollOffsetInBounds()

  # THE offset write funnel (paint-time scroll): every `@scrollOffsetX/Y` change in the class
  # routes through here. The offset is MAPPING state — part of the screen↔plane translation the
  # version-keyed derived-geometry caches (clipThrough / clippedThroughBounds / fullClippedBounds)
  # fold in — so a change must break them exactly as a bounds write does (__breakMoveResizeCaches).
  # Paint needs no such break (it reads the offset live), but HIT-TESTING reads those caches:
  # a scrolled row whose stale clip box is EMPTY paints perfectly and is hit-INVISIBLE — clicks
  # fall through to the viewport (measured on the inspector list, plan §3.2). Never write the
  # fields bare and rely on a neighboring bounds commit to bump the version: whether one happens
  # is accidental (a 1-px scroll may not move the quantized thumb; the clamp fires on unchanged
  # frames too). Returns whether the offset actually moved — the cores' caller contract.
  _writeScrollOffset: (newX, newY) ->
    return false if newX is @scrollOffsetX and newY is @scrollOffsetY
    @scrollOffsetX = newX
    @scrollOffsetY = newY
    WorldWdgt.geometryVersion++
    @_changed()
    true

  # THE MARGIN WRITE DOOR: every write of my plane margin on a live viewport comes through here, for
  # the offset funnel's reason (above): the margin is mapping state the version-keyed clip caches fold
  # in, so a change breaks them, and my whole box repaints. A write of the margin I keep does nothing.
  _writePlaneMargin: (margin) ->
    return if margin is @planeMargin
    @planeMargin = margin
    WorldWdgt.geometryVersion++
    @_changed()

  # §4.2 Stage 3 (structural arrange): the SCROLL CLAMP keeping the visible window inside the
  # content frame — the offset stays in [0, max(0, content − window)] per axis, so a shrink
  # at the bottom scrolls back up (no vacant space revealed) and fitting content rests at 0.
  # The plane itself never moves; only the offset clamps. Callers pair with
  # _reLayoutScrollbars as every scroll path does.
  _keepScrollOffsetInBounds: ->
    newX = Math.min (Math.max 0, @scrollOffsetX), (Math.max 0, @contents.width() - @width())
    newY = Math.min (Math.max 0, @scrollOffsetY), (Math.max 0, @contents.height() - @height())
    @_writeScrollOffset newX, newY

  # ViewportWdgt scrolling by floatDragging:
  _scrollX: (steps) ->
    # under 'never' every scroll path refuses HERE, at the movement core: the
    # pin setters, scrollTo/scrollToBottom, the edge auto-scroll and the
    # momentum glide all route through this pair, and callers read the boolean
    # as "did the content actually move".
    return false if @scrollPolicy is 'never'
    # positive steps scroll the view back toward the content origin (the historical
    # "move the contents right" direction); the offset moves opposite the steps.
    # Math.round at the write funnel: the offset is INTEGER by contract (plan §4.3 —
    # fractional offsets are the fracplane bug class), and glide deltas arrive decayed.
    newX = Math.round @scrollOffsetX - steps
    newX = Math.min (Math.max 0, newX), (Math.max 0, @contents.width() - @width())
    # Return true iff the view actually moved -- callers use this to decide whether to trigger the
    # content/scrollbar update.
    @_writeScrollOffset newX, @scrollOffsetY

  # Scroll so CONTENT-point `whereTo` sits at my top-left. FRAME-RELATIVE (offset from my own
  # origin), so the result is independent of where I am in the world -- a caller's scroll survives
  # my being moved/resized (e.g. the sample-slide edit->view container shift). Not `-whereTo.x/.y`
  # (absolute world coords): those only land right for a frame at the world origin -- the root
  # of a real mis-scrolled-slide bug. The public door to a scroll to a place: a holder pins my
  # content where it wants it (SampleSlideApp), and a subclass brings a part of its plane into view
  # through it (ListWdgt.scrollRowIntoView, InspectorRowViewportWdgt.revealColumn).
  #
  # CLAMPED like every other scroll path: the request is expressed as deltas and routed through
  # _scrollX/_scrollY, so a target past the content's edge stops AT the edge -- a raw move here let a
  # too-far request commit an over-scrolled state no gesture can produce, with the contents frame
  # no longer covering the viewport (the arrange's own fit rule). After a real scroll, re-fit
  # contents + scrollbars, the standard post-scroll pair.
  scrollTo: (whereTo) ->
    scrolledX = @_scrollX @scrollOffsetX - whereTo.x
    scrolledY = @_scrollY @scrollOffsetY - whereTo.y
    if scrolledX or scrolledY
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()


  scrollToBottom: ->
    if @_scrollY -100000
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      # — the same moved-gated post-scroll arrange every other scroll path runs (scrollTo, the
      # pin setters, the drag step); the non-content-sizing arrange folds the offset into its
      # window merge, so it must re-run after a real scroll
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()
  
  _scrollY: (steps) ->
    # 'never' refuses at the core — see _scrollX (which also explains the sign and the
    # integer-offset rounding).
    return false if @scrollPolicy is 'never'
    newY = Math.round @scrollOffsetY - steps
    newY = Math.min (Math.max 0, newY), (Math.max 0, @contents.height() - @height())
    # Return true iff the view actually moved -- callers use this to decide whether to trigger the
    # content/scrollbar update.
    @_writeScrollOffset @scrollOffsetX, newY

  # A plain drag over my content scrolls me (particularly useful on touch devices); the same gesture
  # works with the mouse when dragging over content that isn't itself draggable (e.g. text in a
  # viewport anchored to a non-draggable background, such as a color palette).
  #   With panes NESTED, one pane takes a stroke and takes all of it — THE DIRECTION LATCH. As the
  # stroke first leaves the grab radius, the innermost pane above the press that can move in the
  # stroke's direction takes the whole stroke, catching up from the press point; nothing hands on to
  # another pane within the stroke, so travel past that pane's clamp is dropped until the next stroke
  # latches anew. It is the wheel's rule (scrolledBy) applied per stroke, and what WebKit, Chrome's
  # touch scrolling and iOS do with nested scrollers.
  #   The stroke's OWNER is the innermost pane the press reaches that has something to scroll: the one
  # the hand is told took the press (notePressTakenForScrolling), and the one it asks to latch
  # (latchStrokeScroll). Every pane above the owner still gets the press — its raise and the climb go
  # on — and installs nothing: ONE drag-scroll step per stroke, on the pane that scrolls it. Every
  # branch passes the press on (super).
  pressBegan: (pos) ->
    # A pane that takes no scroll gesture at all — 'never', or one that does not drag-scroll — is
    # TRANSPARENT to the press, as it is to the wheel (scrolledBy passes a notch on through it): the
    # climb goes on, so a drag over a cropping pane nested in a scrolling one reaches the scrolling one.
    if @scrollPolicy is 'never' or !@isScrollingByfloatDragging
      return super
    # a press that reaches me starts a new stroke, so what my last gesture left running on me (a
    # glide, an auto-scroll) ends here — the same press may latch me again
    @_stopScrollStep()
    # The hand is told at the press: my content carries whatever the press landed on along with the
    # pointer, so a scroll's release lands back on it, and this fact is what keeps that release from
    # reading as a click on it, and what tells the press's audience inside me that the stroke is a
    # scroll (ActivePointerWdgt._strokeScrolls, through the pane my latch chooses).
    if @claimsPlainDragsForScrolling() and !world.hand.isPressTakenForScrolling()
      world.hand.notePressTakenForScrolling @
      # With no pane above me that could take the stroke there is nothing to choose: I take it at the
      # press, so a lone pane scrolls from the stroke's first pixel.
      #   The press point is the hand read through the very mapping the step reads its per-frame
      # samples with, so the seed and the samples share MY plane by construction. A press point in my
      # scrolled content's plane would sit offset-pixels away (paint-time scroll), and one cross-plane
      # seed makes the first frame's delta the whole offset — the drag slams to the clamp on a
      # stationary click (measured).
      if (ViewportWdgt._strokeScrollCandidatesFrom @).length is 1
        @takeStrokeScrollFrom @screenPointToMyPlane world.hand.position()
    super

  # MY STROKE ENDS AT ITS OWN RELEASE. The pane a stroke's scroll went to is in that press's audience
  # and keeps the press when the stroke commits to scrolling it (the press lifecycle,
  # ActivePointerWdgt._pressAudience), so it is told the ending exactly once — and that ending, not
  # whichever frame first sees the hand let go, is where the stroke's step pays its release flush:
  # `pos` is the release point in my plane, an event-time fact. A frame that drains this release
  # together with the next press therefore finds nothing owed when that press stops my step
  # (pressBegan). With no scroll step of mine running I took no scroll from this stroke, and owe nothing.
  pressEnded: (pos) ->
    @_scrollStep pos  if @_scrollStep?

  # A stroke that stops being a press on me — confiscated (an abort), put away with me, or turned into
  # a lift — ends my part of it where the pointer stands as it ends; the step's own guards keep a lift
  # from getting a parting scroll.
  pressCancelled: ->
    @_scrollStep @screenPointToMyPlane world.hand.position()  if @_scrollStep?

  # THE LATCH, asked by the hand of this stroke's OWNER at the DRAINED EVENT where the press first
  # leaves the grab radius (ActivePointerWdgt._notePressTravelledPastDragThreshold), with the press
  # point and that event's point — two screen points the event stream fixed, so which pane takes the
  # stroke is a function of the events, never of which frame first saw the hand past the radius (and
  # nothing scrolls a nest before it, so every clamp it reads is the one the press found). Answers the
  # pane that took the stroke's scroll, which the hand keeps as the stroke's fact — or undefined when
  # the stroke is lifting what it pressed: then it is no scroll, and no pane takes it.
  latchStrokeScroll: (pressPoint, crossingPoint) ->
    return undefined  if world.hand.isThisPointerFloatDraggingSomething() or @_strokeWouldLiftWhatItPressed()
    # a scroll step of mine already running for this press means I took the stroke at the press, alone
    return @  if @_scrollStep?
    pane = ViewportWdgt.strokeScrollPaneFor pressPoint, (crossingPoint.subtract pressPoint), @
    return undefined  unless pane?
    # the latched pane scrolls the stroke from the press point, so it catches up the travel that
    # carried the stroke out of the grab radius
    pane.takeStrokeScrollFrom pane.screenPointToMyPlane pressPoint
    pane

  # WHICH PANE TAKES A STROKE — the latch's one decision, from the press point (screen), the stroke's
  # direction (a screen vector: where the stroke has gone from the press) and `hit`, the widget the
  # press reaches first. The latch asks it with the stroke's owner; the macro toolkit's aim check asks
  # it with the widget a press will meet, so the check cannot drift from the dispatch. The DOMINANT
  # axis of the direction decides: the innermost candidate that scrolls along that axis and is not
  # already at its clamp in the stroke's direction; else the innermost that scrolls along that axis at
  # all; else the innermost candidate. The direction is read in each candidate's own plane, so a
  # scrolled or tilted pane answers for the way the stroke would move it. undefined when nothing above
  # `hit` takes plain drags for scrolling.
  @strokeScrollPaneFor: (pressPoint, direction, hit) ->
    candidates = ViewportWdgt._strokeScrollCandidatesFrom hit
    horizontal = Math.abs(direction.x) > Math.abs(direction.y)
    alongTheAxis = candidates.filter (each) ->
      if horizontal then each._dragScrollsHorizontally() else each._dragScrollsVertically()
    for each in alongTheAxis
      travel = (each.screenPointToMyPlane pressPoint.add direction).subtract each.screenPointToMyPlane pressPoint
      if horizontal
        [step, offset, clamp] = [travel.x, each.scrollOffsetX, Math.max 0, each.contents.width() - each.width()]
      else
        [step, offset, clamp] = [travel.y, each.scrollOffsetY, Math.max 0, each.contents.height() - each.height()]
      # _scrollX/_scrollY's own sign: a step toward the content's end (negative) needs room before the
      # clamp, a step back toward its start (positive) needs offset to give back
      return each  if (step < 0 and offset < clamp) or (step > 0 and offset > 0)
    alongTheAxis[0] ? candidates[0]

  # The panes a stroke pressed at `hit` could latch, innermost first: every pane on the press's climb
  # that takes plain drags and has something to scroll (claimsPlainDragsForScrolling). A pane that takes
  # no scroll gesture — 'never', or not drag-scrolling — is not one, and does not stop the climb either
  # (pressBegan passes the press on), so the panes beyond it still are.
  @_strokeScrollCandidatesFrom: (hit) ->
    candidates = []
    each = hit
    while each?
      candidates.push each  if each.claimsPlainDragsForScrolling?() is true
      each = each.parent
    candidates

  # Does my drag-scroll step move me along this axis — the axis I present a bar for?
  _dragScrollsHorizontally: ->
    @hBar.visibleBasedOnIsVisibleProperty() and !@hBar.isInCollapsedSubtree()

  _dragScrollsVertically: ->
    @vBar.visibleBasedOnIsVisibleProperty() and !@vBar.isInCollapsedSubtree()

  # Is the stroke in flight about to LIFT what it pressed rather than scroll? A float-draggable widget
  # under the hand is probably about to be detached, so a pane holds steady instead of scrolling --
  # scrolling now would give the wrong cue right before the float-drag threshold is reached. A FINGER
  # whose stroke does not mean a mouse drag is the other way round (ruling I2): over my content a plain
  # finger drag is a scroll whatever it is over, and the thing under it lifts only once a hold has
  # armed the stroke. A mouse or pen stroke always means a mouse drag, so for them this reads exactly
  # as the detach test alone.
  _strokeWouldLiftWhatItPressed: ->
    world.hand.wdgtToGrab?.detachesWhenDragged() and world.hand.strokeMeansMouseDrag()

  # End my scroll step, whichever gesture runs it — a drag-scroll's stroke and glide, or an edge
  # auto-scroll — and with it everything the gesture knew: what it ran on is its own (a glide's flag, an
  # auto-scroll's start), so nothing of it is left to outlive it. Nothing to do when none runs.
  _stopScrollStep: ->
    return unless @_scrollStep?
    delete @_scrollStep
    world.steppingWdgts.delete @

  # Is a drag-scroll's glide of mine running? The world asks it of every stepping widget
  # (WorldWdgt.anyScrollMomentumOngoing); the answer is the running step's own, so it ends with the step.
  isScrollGliding: ->
    @_scrollStep?.glides is true

  # I TAKE THIS STROKE'S SCROLL, from `pressPoint` — the press point in MY plane. The stroke's one
  # drag-scroll step goes on me: called by its owner, which is me at the press when I am alone, or the
  # owner's latch on whichever pane it latched. Each frame the step maps the hand into my plane and
  # scrolls me, on my own axes, by how far it moved there. The mapping holds still under those samples:
  # only I scroll during the stroke, my own scroll never moves the plane I sit on, and a pane around me
  # still gliding from an earlier stroke was stopped by this stroke's press (pressBegan).
  #   The step is called two ways. Each FRAME, with no argument: while the stroke lasts it samples the
  # hand, and once the stroke has ended for me it only glides or stops. And ONCE, at the stroke's own
  # ending (pressEnded, pressCancelled), with the point the stroke ends at: that call pays the flush.
  takeStrokeScrollFrom: (pressPoint) ->
    oldPos = pressPoint
    deltaX = 0
    deltaY = 0
    friction = 0.8
    wasScrollDragging = false
    # Did ANY frame of this gesture see a float-drag in progress? A float-drag means
    # the gesture is MOVING a (detachable) widget, not scrolling, so it must never get
    # a parting scroll — even if its frames collapse (see the flush's collapse branch).
    everFloatDragged = false
    # has the stroke ENDED for me: its flush paid, so a frame only glides or stops from then on
    strokeEnded = false
    # THE FLUSH, paid once, where the stroke ends (`endPos`, in MY plane): the step samples the hand
    # once per FRAME, so the tail of the pointer's path that arrived after the last frame's sample was
    # never scrolled — without this the scroll total truncates at the last sample, a frame-cadence
    # artifact. Scrolling the leftover makes the total exactly end-point minus press-point —
    # event-determined, identical across engines — and the leftover doubles as the glide's seed
    # velocity. Only when this drag actually scroll-dragged (a float-move of the viewport must not get
    # a parting scroll), and only if it ends inside me (matching the per-frame gate below). Answers
    # whether I scrolled.
    #   CADENCE COLLAPSE: while a test plays (or just in a slow / HiDPI frame) the whole
    # press->drag->release can drain inside ONE cycle, so no frame sampled the stroke and
    # wasScrollDragging is false. When the gesture never float-dragged anything and the hand isn't
    # poised to detach a widget (so it IS a scroll-drag, not a float-move) and the press is inside me,
    # it is still a scroll-drag: oldPos is still the press point, so the flush scrolls exactly
    # release-minus-press — the SAME event-determined total the multi-frame path lands on.
    endStroke = (endPos) =>
      strokeEnded = true
      scrolledNow = false
      collapsedScrollDrag = !wasScrollDragging and
        !everFloatDragged and
        !@_strokeWouldLiftWhatItPressed() and
        @boundsContainPoint(oldPos)
      if (wasScrollDragging or collapsedScrollDrag) and @boundsContainPoint endPos
        # dropped past my clamp, as in the per-frame arm below
        if @_dragScrollsHorizontally()
          deltaX = endPos.x - oldPos.x
          if deltaX isnt 0
            scrolledNow = (@_scrollX deltaX) or scrolledNow
        if @_dragScrollsVertically()
          deltaY = endPos.y - oldPos.y
          if deltaY isnt 0
            scrolledNow = (@_scrollY deltaY) or scrolledNow
        oldPos = endPos
      wasScrollDragging = false
      scrolledNow
    world.steppingWdgts.add @
    @_scrollStep = strokeStep = (strokeEndPos) =>
      scrollbarJustChanged = false
      everFloatDragged ||= world.hand.isThisPointerFloatDraggingSomething()
      if strokeEndPos?
        # the stroke's own ending, told exactly once (the press lifecycle)
        scrollbarJustChanged = endStroke strokeEndPos  unless strokeEnded
      else
        if !strokeEnded
          if world.hand.mouseButton and
            !world.hand.isThisPointerFloatDraggingSomething() and
            !@_strokeWouldLiftWhatItPressed() and
            # per-frame samples of the hand are SCREEN-plane; map each into MY plane at the read
            # site (the raw-pointer lint enforces exactly this shape), so the containment gate
            # compares like planes and the deltas below are in-plane — a tilted viewport drag-scrolls
            # along its own axes. Off any island the mapping returns the same point (dormant
            # byte-identical). The press point (oldPos) is seeded by the SAME mapped read.
            @boundsContainPoint(@screenPointToMyPlane world.hand.position())
              wasScrollDragging = true
              newPos = @screenPointToMyPlane world.hand.position()
              # Travel past my clamp is DROPPED, not handed on: the stroke is mine alone (the latch),
              # so a step _scrollX/_scrollY cannot take simply ends there.
              if @_dragScrollsHorizontally()
                deltaX = newPos.x - oldPos.x
                if deltaX isnt 0
                  scrolled = @_scrollX deltaX
                  scrollbarJustChanged ||= scrolled
              if @_dragScrollsVertically()
                deltaY = newPos.y - oldPos.y
                if deltaY isnt 0
                  scrolled = @_scrollY deltaY
                  scrollbarJustChanged ||= scrolled
              oldPos = newPos
          else
            # the pointer left me mid-stroke, or the stroke became a lift: my part of it ends here,
            # where the pointer stands, and this same frame glides or stops below
            scrollbarJustChanged = endStroke @screenPointToMyPlane world.hand.position()
        if strokeEnded
          # POST-RELEASE MOMENTUM (the glide): keep scrolling by the flush's delta (else the last
          # frame's), decayed by friction each frame, until it fades. Both that delta and the glide
          # length are FRAME-CADENCE driven (how many queued events played back in the final frame),
          # so while a test plays the glide is SUPPRESSED outright —
          # the content stops exactly at the event-determined release offset and screenshots are
          # reproducible across engines. While a glide IS running (normal interactive use) the step
          # says so (isScrollGliding), so the macro pump can hold until it settles (the
          # font-atlas-wait idea).
          glideSuppressed = aTestIsPlaying()
          if !@hasVelocity or glideSuppressed or
          ((Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5))
            @_stopScrollStep()
          else
            strokeStep.glides = true
            if @_dragScrollsHorizontally()
              deltaX = deltaX * friction
              if deltaX isnt 0
                scrollbarJustChanged ||= @_scrollX Math.round deltaX
            if @_dragScrollsVertically()
              deltaY = deltaY * friction
              if deltaY isnt 0
                scrollbarJustChanged ||= @_scrollY Math.round deltaY
      if scrollbarJustChanged
        # layout-apply-sanctioned: scroll-input (drag-scroll frame, release flush, momentum glide),
        # determinism-exempt (residuals-audit fam 1)
        @_positionAndResizeChildren()
        @_reLayoutScrollbars()
  
  # During a float-drag, if I want the dragged widget and the pointer is in my edge band, I
  # auto-scroll. ActivePointerWdgt calls this instead of testing `newWdgt instanceof
  # ViewportWdgt` and driving the wantsDropOfChild / edge / _startAutoScrolling logic itself.
  # (type-test-elimination campaign)
  maybeStartAutoScrollForDraggedWidget: (widgetBeingFloatDragged, pointerPosition) ->
    # a 'never' viewport accepts the drop but does not creep toward it
    return if @scrollPolicy is 'never'
    if @wantsDropOfChild widgetBeingFloatDragged
      # the caller hands the hand's SCREEN position; my box is plane-local (I can myself be a
      # resident of a scrolled pane / island), so map the pointer into MY plane for the band
      # test — the identity (same object) for an un-nested viewport
      if !@boundingBox().insetBy(WorldWdgt.theme.scrollBarsThickness * 3).containsPoint @screenPointToMyPlane pointerPosition
        @_startAutoScrolling()

  _startAutoScrolling: ->
    # The edge auto-scroll is wall-clock driven (the Date.now() settle below
    # plus per-frame increments), but unlike the momentum glide in
    # takeStrokeScrollFrom it is NOT suppressed while a test plays: it is a
    # load-bearing interaction with its own SystemTest
    # (macroListWdgtAutoScrollsNearDraggedEdge). Its determinism contract is
    # SATURATION instead — a macro holds the drag in the edge band long
    # enough that the scroll CLAMPS, so the screenshotted endpoint is
    # frame-cadence-independent even though the path there isn't (see the
    # edge-auto-scroll entry in src/macros/MACRO-PATTERNS.md).
    inset = WorldWdgt.theme.scrollBarsThickness * 3
    if @isOrphan() then return undefined
    # an auto-scroll already running goes on: its start, and so its delay, is its own
    return undefined  if @_scrollStep?.autoScrolls
    # whatever else of mine runs — a drag-scroll's glide — ends here
    @_stopScrollStep()
    hand = world.hand
    # when the auto-scroll starts, kept by its step: it scrolls only once half a second has passed
    startedAt = Date.now()
    world.steppingWdgts.add @
    @_scrollStep = =>
      # mapped like every per-frame hand sample (identity for an un-nested viewport) — the
      # band test and _autoScroll's delta arithmetic below both run in MY plane
      pos = @screenPointToMyPlane hand.position()
      inner = @boundingBox().insetBy inset
      if @boundsContainPoint(pos) and
        !inner.containsPoint(pos) and
        hand.isThisPointerFloatDraggingSomething()
          @_autoScroll pos  unless Date.now() - startedAt < 500
      else
        @_stopScrollStep()
    @_scrollStep.autoScrolls = true

  _autoScroll: (pos) ->
    inset = WorldWdgt.theme.scrollBarsThickness * 3
    area = @topLeft().extent new Point @width(), inset
    scrollbarJustChanged = false
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @_scrollY inset - (pos.y - @top())
    area = @topLeft().extent new Point inset, @height()
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @_scrollX inset - (pos.x - @left())
    area = (new Point(@right() - inset, @top())).extent new Point inset, @height()
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @_scrollX -(inset - (@right() - pos.x))
    area = (new Point(@left(), @bottom() - inset)).extent new Point @width(), inset
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @_scrollY -(inset - (@bottom() - pos.y))
    if scrollbarJustChanged
      # scroll input (the edge auto-scroll), determinism-exempt (residuals-audit fam 1): the re-fit
      # of the contents and the bars every scroll path runs after it scrolls, here once the view moved
      @_positionAndResizeChildren()
      @_reLayoutScrollbars()
  
  # ViewportWdgt scrolling when editing text
  # so to bring the caret fully into view.
  # The caret is a resident of my PLANE (its parent is my contents), so its coordinates are
  # plane-local and never move on a scroll; bringing it into view means moving the OFFSET
  # until the caret's plane position falls inside the visible window's plane rect. The full
  # delta lands in ONE core call per axis (the single-pass law: CaretWdgt places itself at
  # its true, un-clamped slot position before asking), and the caret itself is never moved —
  # its screen appearance follows through the paint-time translation.
  scrollCaretIntoView: (caretWidget) ->
    # a 'never' viewport clips its caret like any other overflow — WYSIWYG of the
    # policy (a text viewport that wants the caret in view wants 'auto')
    return if @scrollPolicy is 'never'
    # layout-apply-sanctioned: scroll-input (caret-into-view), determinism-exempt (residuals-audit fam 1)
    @_positionAndResizeChildren()
    # the box my plane shows through (the visible window less my margin, _planeBox), expressed
    # in the caret's plane (frame origin + offset)
    ft = @contents.top() + @scrollOffsetY + @planeMargin
    fb = @contents.top() + @scrollOffsetY + @height() - @planeMargin
    fl = @contents.left() + @scrollOffsetX + @planeMargin
    fr = @contents.left() + @scrollOffsetX + @width() - @planeMargin
    # the ring of that box my own border covers: the border I paint over my edge lies in my margin
    # while my margin is as wide as it, and over my plane's outer ring where it is narrower (a
    # viewport on the desk, keeping no margin), so a caret that reaches into that ring is not in view
    borderOverMyPlane = Math.max 0, @_borderWidthOverMyEdge() - @planeMargin
    # how far inside that box the caret comes to stand once followed, on either axis, so some of
    # what surrounds it shows too: my margin and the padding a caller set around my content
    # (setContents), my layout inset -- and never less than keeps the caret clear of my border,
    # so the next pass finds it in view
    marginAroundCaret = Math.max @planeMargin + (@extraPadding ? 0), borderOverMyPlane
    # DIRECT, deliberately UN-clamped offset writes (the follow's one licence — the movement
    # cores clamp to the content frame, but a caret at the very end of the content needs the
    # window to overshoot by that margin). What the arrange below makes of an overshoot depends on
    # my plane: around free-floating content it GROWS the frame to cover the overshot window (the
    # window-in-plane merge) and its bookkeeping+clamp normalize the offset against the grown frame,
    # so the overshoot STICKS exactly as far as the margin — the same fixpoint the moved-plane follow
    # reached by moving the plane un-clamped; a content-sizing plane (a stack, a document, a text)
    # is framed from its measure alone, so the clamp takes the overshoot away and a caret on the
    # content's last lines comes to rest where the content ends.
    if caretWidget.top() < ft + borderOverMyPlane
      @_writeScrollOffset @scrollOffsetX, (Math.round @scrollOffsetY - (ft - caretWidget.top() + marginAroundCaret))
    else if caretWidget.bottom() > fb - borderOverMyPlane
      @_writeScrollOffset @scrollOffsetX, (Math.round @scrollOffsetY + (caretWidget.bottom() - fb + marginAroundCaret))
    if caretWidget.left() < fl + borderOverMyPlane
      @_writeScrollOffset (Math.round @scrollOffsetX - (fl - caretWidget.left() + marginAroundCaret)), @scrollOffsetY
    else if caretWidget.right() > fr - borderOverMyPlane
      @_writeScrollOffset (Math.round @scrollOffsetX + (caretWidget.right() - fr + marginAroundCaret)), @scrollOffsetY
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # ViewportWdgt events.
  scrolledBy: (xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg) ->

    x = xArg
    y = yArg

    # if we don't destroy the resizing handles,
    # they'll follow the contents being moved!
    world.hand.destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem @

    scrollbarJustChanged = false

    # squelch the minor axis + apply the invert preferences
    [x, y] = WorldWdgt.preferencesAndSettings.normalizedWheelDeltas x, y

    if y != 0
      # Escalate the scroll in case we are in a nested
      # Viewport situation and we already
      # scrolled this inner one "up/down to the end".
      # In such case, the outer one has to scroll...
      #
      # if scrolling up and the content top is already at (or below) the top
      #  OR
      # if scrolling down and the content bottom is already at (or above) the bottom
      #  THEN
      # escalate the method up, since there might be another scrollbar catching it.
      # Exact comparisons: the offset is integer by contract (the movement cores round at
      # the write funnel), and a tolerance here would hand a 1px-shy inner viewport's last
      # wheel step to the outer viewport instead of letting the inner one reach its edge.
      # 'never' escalates HERE, not at the refused core — the else arm would
      # otherwise mark scrollbarJustChanged and swallow the wheel dead over a
      # cropping viewport instead of handing it to an enclosing scroller.
      # at-top ⇔ offset 0; at-end ⇔ offset at the clamp limit (fitting content is both).
      if @scrollPolicy is 'never' or
       (y > 0 and @scrollOffsetY <= 0) or
       (y < 0 and @scrollOffsetY >= @contents.height() - @height())
        @escalateEvent 'scrolledBy', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
      else
        scrollbarJustChanged = true
        @_scrollY y * WorldWdgt.preferencesAndSettings.wheelScaleY
    if x != 0
      # similar to the vertical case, escalate the scroll in case
      # we are in a nested Viewport situation ('never' escalates too — see
      # the vertical case)
      if @scrollPolicy is 'never' or
       (x > 0 and @scrollOffsetX <= 0) or
       (x < 0 and @scrollOffsetX >= @contents.width() - @width())
        @escalateEvent 'scrolledBy', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
      else
        scrollbarJustChanged = true
        @_scrollX @_wheelTravelX x

    if scrollbarJustChanged
      # layout-apply-sanctioned: scroll-input (wheel), determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
      @_reLayoutScrollbars()

  # a sideways notch's travel in _scrollX's steps: my wheel scale's share (a subclass may rest it on its own unit)
  _wheelTravelX: (x) ->
    x * WorldWdgt.preferencesAndSettings.wheelScaleX


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    if @takesOverAndMergesChildrensMenus
      if @contents
        childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents
      if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length == 1
        childrenNotHandlesNorCarets[0].addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu
    else
      super
      if @offersScrollPolicyToggle
        if @scrollPolicy is 'never'
          menu.addMenuItem "Allow scrolling", @, "toggleScrollPolicyFromMenu", toolTip: "let the contents scroll\nwhen they overflow"
        else
          menu.addMenuItem "Don't scroll (crop)", @, "toggleScrollPolicyFromMenu", toolTip: "crop the contents at my\nedges instead of scrolling"
  
  # Set this viewport's text-line-wrapping state; turning wrapping ON fills
  # the content to the viewport's bounds. (Called by SimpleTextWdgt's soft-wrap
  # toggle, which used to write this flag + resize the content from outside.)
  #
  # The resize here is DELIBERATELY IMMEDIATE (raw geometry), not the framework's
  # ideal DEFERRED pattern (set a flag + _invalidateLayout(), let recalculateLayouts
  # -> _reLayout derive the geometry). This is INTERMEDIATE state, not an oversight:
  # the deferred mechanism is half-built by construction (the geometry accessors read
  # applied @bounds only, so handler-level raw geometry is a symptom of that
  # incompleteness, not a one-off). Soft-wrap has an EXTRA blocker on top: the content
  # panel + text are free-floating, so _invalidateLayout() on them does NOT
  # climb up to this viewport, and the wrap geometry lives in _positionAndResizeChildren
  # -- which the _reLayout cycle never reaches for a wrap toggle. Completing the
  # deferred model (and this case) is deliberate, sequenced work; see
  # docs/archive/softwrap-deferred-layout-conversion-plan.md for the model finding, the
  # obstacle map, and what a conversion would take.
  setTextLineWrapping: (wraps) ->
    @isTextLineWrapping = wraps
    if wraps
      @contents._applyBounds @position(), @extent()

  _enableDragsDropsAndEditingNoSettle: ->
    if @dragsDropsAndEditingEnabled
      return
    # public-call-sanctioned: enableDrops is the trivial public drop-acceptance setter
    # (macro/cross-object surface) — settle-free, consciously reused by this core.
    @enableDrops()
    @dragsDropsAndEditingEnabled = true
    # my flag is my mode, and the mode a window holding me answers with: its flip is told to the
    # world I stand in as the base core tells its own (Widget._enableDragsDropsAndEditingNoSettle)
    @root().noteEditModeChanged?()

    # told once my mode has changed, as every core in this family tells it: my window re-asks the
    # windows standing in me whether they offer a grip, and they read my mode to answer
    @parent?.showEditModeInBar?()

    @contents._enableDragsDropsAndEditingNoSettle()

  _disableDragsDropsAndEditingNoSettle: ->
    if !@dragsDropsAndEditingEnabled
      return
    # public-call-sanctioned: disableDrops — see the enableDrops note in the enable core above.
    @disableDrops()
    @dragsDropsAndEditingEnabled = false
    @root().noteEditModeChanged?()

    # (after the flag: see the enable core above)
    @parent?.showViewModeInBar?()

    @contents._disableDragsDropsAndEditingNoSettle()
    # ELIMINATE (end-of-cycle-flush-drawdown): a disable-probe proved the deferred re-fit that used to
    # live here redundant -- disabling only changes appearance/drop-handling, and the cascade's
    # @contents._disableDragsDropsAndEditingNoSettle above already did the synchronous work. See
    # docs/archive/end-of-cycle-flush-inventory.md.

