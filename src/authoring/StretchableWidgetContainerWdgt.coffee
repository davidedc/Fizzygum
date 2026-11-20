# We need this because we need a panel that keeps its content
# all in the same relative positions and sizes when its
# resized, so you can drag and drop it inside stacks
# and resizable windows and it doesn't mangle the contents
# when it's resized. The way to achieve that is to
# have a container and a type of panel that works together
# to "crystallize" a specific width/height ratio as soon
# as there is one element dropped/added in the panel.
# So when the panel is empty, you can give it any shape you
# want, but as soon as there is one element, it sticks
# to the ratio it has.

class StretchableWidgetContainerWdgt extends Widget

  ratio: undefined
  contents: undefined

  # set at my subtree's destroy ENTRY (_fullDestroyNoSettle below), so the whole recursion knows I am
  # going away -- see _reactToChildRemoved
  _beingFullDestroyed: undefined

  constructor: (@contents) ->
    super()
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if !@contents?
      @contents = new StretchablePanelWdgt

    @_addNoSettle @contents

    @_applyExtent new Point 300, 300
    @contents._applyExtent new Point @width(), @height()
    @_invalidateLayout()

  # A PAGE THAT LEAVES ME LEAVES A FRESH ONE BEHIND, the rule my window keeps one level up
  # (MakerDocumentWdgt._resetToDefaultContents: losing the payload rebuilds a fresh one of its kind).
  # Every reader of my page reads @contents -- add, my drop receivers, my layout and sizing, the mode
  # my edit toggle flips (my window's question whether anything was put in it reads my ratio) -- so
  # a page living elsewhere would go on taking what is meant for my page wherever it stands. Whatever takes it away
  # ("Pick up", "Attach", "Delete", a destroy, or a "Pick up" or "Delete" of the island wrapping it) re-homes
  # it through _addNoSettle or ends it through _destroyNoSettle, and each tells me here once it is gone:
  # the ONE hook a departure of my own child reaches, after the fact, so one departure builds one page. A
  # page taken out of the island wrapping it (its own "Attach" or destroy) tells only the island. A page
  # that still stands under me has not left (a rotation wraps it in an island IN PLACE), and only a
  # departure that carries my page away concerns me.
  #   The fresh page is the departed page's own kind, which only the page can name (freshPageOfMyKind,
  # asked through ?(): a page that names none -- a drawing's canvas, whose glass its Maker lays,
  # ImageWdgt._makeStartingPayload -- is not replaced). It holds MY mode, taken through its own mode
  # core while it still stands alone, the core every page flips by: once in me it would hand the
  # flip to me (StretchablePanelWdgt's relay), and I already hold the mode. It is empty, so the ratio
  # the departed page crystallized goes (resetRatio), and it takes my box, as my construction gives
  # my first page my extent. Not while I am torn down myself (the flag), and not once I am destroyed:
  # a page built inside the destroy-until-empty iteration would never let it end, and one built into
  # a dead container would be pinned forever by the instances registry.
  _reactToChildRemoved: (child) ->
    return if @destroyed or @_beingFullDestroyed
    return unless @contents? and child.isAncestorOf(@contents) and !@isAncestorOf(@contents)
    freshPage = @contents.freshPageOfMyKind?()
    return unless freshPage?
    freshPage._disableDragsDropsAndEditingNoSettle() unless @dragsDropsAndEditingEnabled
    @contents = freshPage
    # public-call-sanctioned: resetRatio is the ratio's one release (the page's own hook calls it as
    # its last child leaves, StretchablePanelWdgt._reactToChildRemoved): field writes and a layout
    # mark, settle-free, so it rides the departure's settle like the add below
    @resetRatio()
    freshPage._applyMoveTo @position()
    freshPage._applyExtent @extent()
    @_addNoSettle freshPage
    @_invalidateLayout()

  # Consulted at the child-departure hook above; set here at the subtree's destroy ENTRY so every
  # teardown path (resetWorld's fullDestroyChildren, a direct fullDestroy, the bin's, my window's)
  # covers the whole recursion -- FrameWdgt._fullDestroyNoSettle keeps the same flag for the same
  # reason.
  _fullDestroyNoSettle: ->
    @_beingFullDestroyed = true
    super

  # actually
  # ends up in the Panel inside it
  add: (aWdgt, opts = {}) ->
    # annotation + handle both attach to the viewport directly (was their two instanceof)
    # (type-test-elimination campaign)
    if !@contents? or aWdgt.attachesToViewportDirectly?()
      super
    else
      @contents.add aWdgt, opts

  # Crystallizing a ratio pins canSetHeightFreely ONLY on a STACK spec (§5.B):
  # as a framed CITIZEN's direct content my FrameContentLayoutSpec stays FREE
  # (the window keeps its user-dragged size, content letterboxes) exactly as
  # the retired editor era behaved -- the ratio-LOCK of the holding frame
  # arrives only through the holder-frame stack-drop hook (_constrainToRatio
  # below), never from mere content crystallization. (Pre-§5.B these writes
  # hit an undefined/stack spec anyway -- the editor's own spec governed the window.)
  setRatio: (@ratio) ->
    unless @_contentStackSpec?.isFrameContentSpec?()
      @_contentStackSpec?.canSetHeightFreely = false

  resetRatio: ->
    if @ratio?
      @ratio = undefined
      @_contentStackSpec?.canSetHeightFreely = true
      @_invalidateLayout()


  colloquialName: ->
    "stretchable panel"

  # I am a PAGE, not a pane (a canvas, a slide, a dashboard, a patch board): a window holding me
  # keeps the theme's page gutter (windowPageGutter) around me on every side and between me and each
  # band it docks, and my own box carries no outer margin of its own for that purpose. Asked by that
  # window at every measure and arrange (FrameWdgt._hostsAPage), through ?(): a payload that does
  # not answer is a pane.
  wantsWindowPageGutter: -> true

  # THE RECEIVER OF DROPS AROUND ME: my content (a slide's, dashboard's or patch board's panel, a
  # drawing's canvas), the child of mine that receives drops -- I refuse them myself. Asked through
  # ?() by a window keeping its page gutter around me (FrameWdgt.dropReceiverForPointsOnMyBody), and
  # by me for my own letterbox margin (dropReceiverForPointsOnMyBody below), so a payload released
  # in that gutter or that margin goes to my content by its own rules (a panel places it, a canvas
  # stamps it), moved first inside its visible box (ActivePointerWdgt._moveGutterDropInsideTarget).
  receiverOfDropsAroundMe: ->
    @contents

  # WHO RECEIVES A DROP ON MY BODY -- on a point of it that none of my children covers: my LETTERBOX
  # margin, the room my ratio leaves beside my content once it has crystallized (_layOutOwnContents).
  # That room is my page's, as a window's page gutter is (FrameWdgt.dropReceiverForPointsOnMyBody),
  # so a payload released there goes to my content (receiverOfDropsAroundMe), by my content's own
  # drop rules -- a content that refuses a payload refuses it in my margin too, and the climb goes on
  # past me as it would from me -- moved first inside its visible box. Bare on the desk as in a
  # window: the margin is my page's own body either way. With my content collapsed, nobody: the
  # climb starts at me. PUBLIC: the hand asks it, through ?(), of the top widget under the pointer,
  # where both its drop climbs start (ActivePointerWdgt._dropClimbStart) and where its drop learns
  # that a release fell beside the receiver (_targetReachedThroughAGutter); its dock offer and a
  # press never ask it.
  dropReceiverForPointsOnMyBody: ->
    return undefined if @contents?.collapsed
    @receiverOfDropsAroundMe()

  # Do I stand in a window's PAGE GUTTER -- does my parent keep a gutter around me
  # (FrameWdgt.pageGutterAround, asked through ?(): a parent that does not answer keeps none)? Then
  # the window's body, its gutter and a panel content of mine are all paper, so that panel
  # (StretchablePanelWdgt) marks its extent with an edge on all four sides; elsewhere -- bare on the
  # desk, in a stack, in a window keeping no gutter -- only where I letterbox it
  # (StretchablePanelWdgt._insetEdgeRects). PUBLIC: the panel asks it, through ?(), at every paint
  # of its border. Read live and never kept, so it follows the theme and every re-parenting of mine.
  standsInWindowPageGutter: ->
    ((@parent?.pageGutterAround? @) ? 0) > 0

  # ===== holder-frame ratio hooks (§5.B) =====
  # As a framed citizen's direct content I answer the frame's dropped/grabbed
  # notifications myself. (Hand-written, NOT a RatioLockedWdgt -- deliberately: my
  # sizing pair is the PINNED @ratio variant (content-aware, super-fallback), not
  # RatioLockedWdgt's current-aspect one. Extending it would CHANGE behaviour: my
  # unpinned sizing falls back through `super` to Widget's pair, which would then be
  # its ratio pair.)
  _reactToHolderFrameDropped: (whereIn) ->
    if whereIn?.imposesRatioConstraintOnDroppedChildren?()
      @_constrainToRatio()

  _reactToHolderFrameGrabbed: (whereFrom) ->
    if whereFrom?.releasesRatioConstraintOnGrabbedChildren?()
      @_freeFromRatioConstraints()

  _constrainToRatio: ->
    if @_contentStackSpec?
      @_contentStackSpec.canSetHeightFreely = false
      # force a resize, so the holder frame takes the right ratio. The height
      # of 0 is ignored -- _setWidthSizeHeightAccordingly calculates it.
      if @ratio?
        @_applyExtent new Point @width(), 0

  _freeFromRatioConstraints: ->
    if @_contentStackSpec?
      @_contentStackSpec.canSetHeightFreely = true

      availableHeight = world.height() - 20
      if @parent.height() > availableHeight
        @parent._applyExtent (new Point Math.min((@width()/@height()) * availableHeight, world.width()), availableHeight).round()
        @parent._applyMoveTo world.hand.position().subtract @parent.extent().floorDivideBy 2
        @parent._moveWithin world

  # SMART PLACEMENT (CreatorWdgt.activated): a creator's click places the widget it makes into the
  # CONTENT of the topmost window that takes one, and for a window holding me that content is me; I
  # centre it in me and hand it to my content (add, above). I take one while my editing is on (a
  # window in view mode takes none) and while my content keeps what it is given: a content that
  # stamps what is dropped on it (a drawing's canvas, StretchableCanvasWdgt.stampsDroppedWidgets,
  # asked through ?()) takes no click-placed widget, because a click ends in the same kind of result
  # a drop would. Either way the search passes over my window to the next one down.
  acceptsSmartPlacedWidgets: ->
    @dragsDropsAndEditingEnabled and !@contents?.stampsDroppedWidgets?()

  smartPlace: (widgetToBePlaced, creator) ->
    widgetToBePlaced._applyMoveTo @center().round().subtract widgetToBePlaced.extent().floorDivideBy 2
    @add widgetToBePlaced
    @bringToForeground()
    creator.bringToForeground()

  # (§5.B) NO initialiseDefaultFrameContentLayoutSpec override: as a framed
  # citizen's content the spec keeps the base default canSetHeightFreely=true
  # -- free window sizing, like the retired editor's un-overridden spec. The
  # old `= !@ratio?` pin here dated from the ANCIENT direct-content era and
  # encoded the ratio-locked-window behaviour the editor era replaced.


  widthWithoutSpacing: ->
    height = @height()
    width = @width()

    if @ratio?
      widthBasedOnHeight = height * @ratio
      heightBasedOnWidth = width / @ratio

      if widthBasedOnHeight <= width
        return widthBasedOnHeight

      else if heightBasedOnWidth <= height
        return width

    else
        return width

  _resizeToWithoutSpacing: ->
    if @ratio?
      @_applyExtent new Point @widthWithoutSpacing(), Math.round(@widthWithoutSpacing()/@ratio)

  # (§5.B) The retired editor's early-out, one level down: a FREE frame-content
  # spec (canSetHeightFreely -- the base default; false only after a
  # holder-frame stack-drop constrains it) sizes width-only via super, so a
  # desktop citizen window keeps its dragged height and letterboxes. A stack
  # spec / undefined spec answers undefined here and falls to the ratio body --
  # bare-container-in-a-stack behaviour unchanged.
  _setWidthSizeHeightAccordingly: (newWidth) ->
    if @_contentStackSpec?.canSetHeightFreely
      return super  # Path B: propagate the resulting height. See Widget._setWidthSizeHeightAccordingly.

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    if childrenNotHandlesNorCarets.length != 0
      if !@ratio?
        @ratio = @width() / @height()
        unless @_contentStackSpec?.isFrameContentSpec?()
          @_contentStackSpec?.canSetHeightFreely = false
      @_applyExtent new Point newWidth, Math.round(newWidth/@ratio)
    else
      @_applyExtent new Point newWidth, @height()
    @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.

  # §4.1 pure measure (sizing-model unification U3-B): mirrors _setWidthSizeHeightAccordingly
  # above -- the free-spec early-out, then ratio-locked while holding content,
  # width-invariant when empty. When the sizing hasn't lazily initialised @ratio yet, the
  # SAME value is DERIVED locally with NO write -- a measure must not take the mutation's
  # lazy-init side effect (@ratio + canSetHeightFreely).
  preferredExtentForWidth: (availW) ->
    if @_contentStackSpec?.canSetHeightFreely then return super
    if (@childrenNotHandlesNorCarets @contents).length != 0
      ratio = @ratio ? (@width() / @height())
      new Point availW, Math.round(availW / ratio)
    else
      new Point availW, @height()



  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    height = @height()
    width = @width()

    if @ratio?
      widthBasedOnHeight = height * @ratio
      heightBasedOnWidth = width / @ratio

      # letterbox the ratio-box in my frame: center it on the axis with spare room
      if widthBasedOnHeight <= width
        contentsTopLeft = @topLeft().add new Point (width - widthBasedOnHeight) / 2 , 0
        newExtent = new Point widthBasedOnHeight, height

      else if heightBasedOnWidth <= height
        contentsTopLeft = @topLeft().add new Point 0 , (height - heightBasedOnWidth) / 2
        newExtent = new Point width, heightBasedOnWidth

      newBounds = (new Rectangle contentsTopLeft).setBoundsWidthAndHeight newExtent
      @contents._reLayout newBounds.round()

    else
      @contents._reLayout @bounds
  # same as VerticalStackViewportWdgt, you can lock the contents
  # (the rows both build: Widget._addEditingLockMenuEntries).
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addEditingLockMenuEntries menu, @childrenNotHandlesNorCarets()

  # I coordinate drags/drops/editing for my StretchablePanelWdgt child, which hands its
  # enable/disable to me (its cores ask this query rather than `@parent instanceof
  # StretchableWidgetContainerWdgt`: type-test-elimination campaign).
  coordinatesDragsDropsAndEditingForChildren: ->
    true

  # My toggle is Widget's -- it acts on me and on my contents -- but I tell my window's bar FIRST.
  # Widget's core returns before telling it when my contents already hold the new mode and I do not,
  # and my window's bar must follow my mode all the same. A panel page that leaves me is replaced by a
  # fresh one in my mode (_reactToChildRemoved), and a page's own toggle hands the flip to me
  # (StretchablePanelWdgt), but a drawing's canvas is not replaced and a tilted page answers its own
  # "Disable editing" -- so this guards the bar against a page whose mode was written apart from mine.
  _enableDragsDropsAndEditingNoSettle: ->
    if @dragsDropsAndEditingEnabled
      return
    @parent?.showEditModeInBar?()
    super()

  _disableDragsDropsAndEditingNoSettle: ->
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()
    super()
