# The WorldWdgt takes over the canvas on the page
class WorldWdgt extends IconGridPanelWdgt

  # We need to add and remove
  # the event listeners so we are
  # going to put them all in properties
  # here.
  # dblclickEventListener: undefined
  mousedownBrowserEventListener: undefined
  mouseupBrowserEventListener: undefined
  mousemoveBrowserEventListener: undefined
  contextmenuEventListener: undefined

  touchstartBrowserEventListener: undefined
  touchendBrowserEventListener: undefined
  touchmoveBrowserEventListener: undefined
  gesturestartBrowserEventListener: undefined
  gesturechangeBrowserEventListener: undefined

  # Note how there can be two handlers for
  # keyboard events.
  # This one is attached
  # to the canvas and reaches the currently
  # blinking caret if there is one.
  # See below for the other potential
  # handler. See "_initVirtualKeyboard"
  # method to see where and when this input and
  # these handlers are set up.
  keydownBrowserEventListener: undefined
  keyupBrowserEventListener: undefined
  keypressBrowserEventListener: undefined
  wheelBrowserEventListener: undefined

  cutBrowserEventListener: undefined
  copyBrowserEventListener: undefined
  pasteBrowserEventListener: undefined
  errorConsole: undefined

  # Scratch buffer holding the last serialised widget's string. It is a CARRIER between two
  # separate user actions -- the "serialise widget to memory" test-menu row (or a macro's
  # evaluateString step) writes it, and the "deserialize from memory..." row that follows reads
  # it back -- which is what lets serialization be driven as two menu picks instead of one
  # atomic call. Nothing else reads it, and its value means nothing outside the pair.
  lastSerializationString: ""

  # Note how there can be two handlers
  # for keyboard events. This one is
  # attached to a hidden
  # "input" div which keeps track of the
  # text that is being input. This is that hidden element; it is created on demand (when a
  # caret wants keyboard input) and torn down with the caret, so it is undefined most of the time.
  inputDOMElementForVirtualKeyboard: undefined
  inputDOMElementForVirtualKeyboardKeydownBrowserEventListener: undefined
  inputDOMElementForVirtualKeyboardKeyupBrowserEventListener: undefined
  inputDOMElementForVirtualKeyboardKeypressBrowserEventListener: undefined

  dragoverEventListener: undefined
  resizeBrowserEventListener: undefined
  dropBrowserEventListener: undefined

  # these variables shouldn't be static to the WorldWdgt, because
  # in pure theory you could have multiple worlds in the same
  # page with different settings
  @preferencesAndSettings: undefined

  @dateOfPreviousCycleStart: undefined
  @dateOfCurrentCycleStart: undefined

  # The .time of the input event currently being dispatched by _playQueuedEvents
  # (a deterministic scheduled ms for macro playback; a real ms for browser users).
  # Exposed so event handlers can reason in EVENT time rather than wall-clock time —
  # used by the hand's multi-click recognition to forget a stale double/triple-click
  # candidate on an event-time gap (deterministic), instead of depending on a
  # wall-clock setTimeout that can fire late under heavy-cycle load.
  @timeOfEventBeingProcessed: undefined

  showRedraws: false
  doubleCheckCachedMethodsResults: false

  # affine transforms (docs/plans/affine-transforms-plan.md §4.5): set to the island
  # currently refreshing its buffer while its content subtree paints INTO that
  # buffer (not the world canvas), so those descendants still record their
  # (virtual) last-painted bounds for the flesh-out "source" cleanup rect. undefined on
  # every ordinary paint — the whole affine machinery is dormant otherwise.
  paintingIntoIslandBuffer: undefined

  # The A/B switch for the _-private *DeferredSettle layout API (Widget._setMaxDimDeferredSettle, ...; _-private +
  # stream-handler-restricted by check-layering [O]). ON (default): a *DeferredSettle call defers its layout flush to
  # the ONE end-of-cycle settle (a gesture/stream draining many mutations per frame collapses N flushes into 1).
  # OFF: every *DeferredSettle call self-settles immediately (its NoSettle core under _settleLayoutsAfter, exactly like
  # the plain public setter), so we can A/B and MEASURE whether deferred settling is actually warranted for a given stream
  # -- toggle at runtime (`world.deferredSettlingEnabled = false`) and re-run docs/tooling/coalescing-measurement.md. (Default
  # ON keeps current behaviour: the *DeferredSettle calls are byte-identical to the _NoSettle cores they wrap.)
  deferredSettlingEnabled: true

  # *DeferredSettle DECLARATION tracking (Widget._deferredSettleDeclare / _setMaxDimDeferredSettle). _deferredSettleDeclarationDepth
  # is > 0 while a DECLARED deferred-settle mutation runs, so the off-settle invalidates it schedules are known to be
  # intentional. auditUndeclaredEndOfCycle (DEBUG, default off) turns on the end-of-cycle check that LOGS every
  # UNDECLARED off-settle push -- the "careless" set (a public method that forgot to self-settle, or a stream
  # not yet on a *DeferredSettle entrypoint) the eventual declared-deferred-settling gate will reject. Off => ~zero overhead.
  _deferredSettleDeclarationDepth: 0
  auditUndeclaredEndOfCycle: false
  _undeclaredEndOfCyclePushes: undefined

  # PAINT must be READ-ONLY: the cycle PROCESSES EVENTS (fixing layouts step by step) -> FIXES the deferred-settle
  # layouts (recalculateLayouts) -> PAINTS (_repaintDamagedRects), with NO layout work at paint. auditPaintTimeLayout-
  # Scheduling (DEBUG, default off) turns on the check that LOGS every layout (re-)schedule reached DURING the
  # paint pass (healingRectanglesPhase true) -- i.e. a widget that scheduled layout while being painted, crossing
  # the render/layout boundary. The caret's paint-time scroll-follow (the original offender) was moved off paint
  # and now settles per-event IN PLACE as the caret's _reLayout (CaretWdgt._requestScrollFollow). Off => ~zero overhead.
  auditPaintTimeLayoutScheduling: false
  _paintTimeLayoutSchedules: undefined

  # ⛔ The tier-naming and notification-settle gates deliberately have NO flag here, and adding one
  # is a mistake this note exists to prevent. Both take every observation from their prelude's own
  # prototype wrappers, which never consult a flag -- so a flag for either would have no reader, and
  # arming it would be a no-op in both directions (measured; docs/archive/world-reset-by-reconstruction-plan.md §D5c). Any flag in this family
  # needs a READER in product code first. auditUndeclaredEndOfCycle above is the live member: there
  # the recording genuinely sits behind it, in Widget._invalidateLayout.

  automator: undefined

  # this is the actual reference to the canvas
  # on the html page, where the world is
  # finally painted to.
  worldCanvas: undefined
  worldCanvasContext: undefined

  # where the world actually RENDERS, and the context that carries the result to the page.
  # Under the SWCanvas backend @worldRenderCanvas is a separate software canvas whose pixels
  # are blitted onto the DOM canvas once per painted frame through @domBlitContext (see
  # blitRenderCanvasToDOM). Under the native backend the render canvas IS the DOM canvas and
  # there is no blit, so @domBlitContext stays undefined. Both are set in the constructor.
  worldRenderCanvas: undefined
  domBlitContext: undefined

  canvasForTextMeasurements: undefined
  canvasContextForTextMeasurements: undefined
  cacheForTextMeasurements: undefined
  cacheForTextParagraphSplits: undefined
  cacheForParagraphsWordsSplits: undefined
  cacheForParagraphsWrappingData: undefined
  cacheForTextWrappingData: undefined
  cacheForTextBreakingIntoLinesTopLevel: undefined

  # the island back-buffer cache: rendered buffers of transform islands whose content is
  # unchanged, keyed by immutableBackBufferGeneration. Sized like the text caches above.
  cacheForImmutableBackBuffers: undefined

  # By default the world will always fill
  # the entire page, also when browser window
  # is resized.
  # When this flag is set, the onResize callback
  # automatically adjusts the world size.
  automaticallyAdjustToFillEntireBrowserAlsoOnResize: true

  # The "keep filling the browser on every resize" decision the world was BUILT with, recorded at the
  # end of the constructor — i.e. AFTER the constructor's own sizing branch, so on the index page the
  # recorded value is the latched true. It is load-bearing at reconstruction: resetWorld hands it to
  # the replacement's constructor, so the successor is built with the policy BOOT chose rather than
  # with whatever the finished session left in @automaticallyAdjustToFillEntireBrowserAlsoOnResize
  # ("fit whole page", the dev context-menu item, latches that ON for good).
  #   There is deliberately no companion record of the boot EXTENT. A world's size is world-level
  # mutable state, and coming back from a mid-session resize is CONSTRUCTION's job: the replacement
  # runs the same sizing branch boot's world ran — size the canvas, then set the bounds from it —
  # so a remembered extent would be a second, weaker answer to a question construction already
  # settles.
  _bootAutoAdjustToFillEntireBrowserAlsoOnResize: undefined

  wdgtsDetectingClickOutsideMeOrAnyOfMeChildren: undefined
  hierarchyOfClickedWdgts: undefined
  hierarchyOfClickedMenus: undefined
  popUpsMarkedForClosure: undefined
  freshlyCreatedPopUps: undefined
  openPopUps: undefined
  toolTipsList: undefined

  @frameCount: 0
  # Monotonic GEOMETRY-CACHE VERSIONS (integers; replaced the four numberOf* counters
  # whose string-concatenated key was rebuilt on every bounds query, Tier F 2026-07-02):
  #   structureVersion  -- bumped on tree adds/removes only
  #   visibilityVersion -- bumped on adds/removes + visibility flips + collapse flips
  #   geometryVersion   -- bumped on all of the above + raw moves/resizes
  # A cache stamps the version it was computed at and is valid iff it is unchanged; each
  # event bumps every version whose caches it could invalidate, so hit/miss behaviour is
  # IDENTICAL to the old concatenated keys (misses cost recompute, never values).
  @structureVersion: 0
  @visibilityVersion: 0
  @geometryVersion: 0

  @noteStructureChange: ->
    @structureVersion++
    @visibilityVersion++
    @geometryVersion++

  @noteVisibilityOrCollapseChange: ->
    @visibilityVersion++
    @geometryVersion++

  # Occlusion culling (docs/plans/occlusion-culling-plan.md P2, Avenue A). CLASS property so it is
  # untouched by world-snapshot serialization, and so a test / the profiler's --cull A/B and
  # DETERMINISM.md's "disable the mechanism" move can flip it globally. See
  # @fullPaintIntoAreaOrBlitFromBackBuffer / @_paintedFromFrontmostCoverer below.
  @occlusionCullingEnabled: true

  # §4.4 island buffer cache (docs/archive/island-buffer-cache-plan.md). CLASS property (untouched by
  # world-snapshot serialization; flippable by a test / the byte-identity A/B macro / the profiler's
  # --cache A/B). Default ON; a flip is pixel-invisible (the cache is byte-identical to rebuild-always
  # by construction, so it may simply drop caches). The per-island opt-out is
  # TransformFrameWdgt::cachesBuffer; the cache is active iff BOTH are on.
  @islandBufferCacheEnabled: true

  # §4.4 rect-list damage coalescing A/B (docs/archive/island-buffer-cache-rectlist-plan.md). Default ON: a frame
  # damaging several disjoint content regions rebuilds only those sub-rects. Flip OFF to force the v1
  # policy (collapse every deposit to one bounding box) — the instrument that proves the rect-list is
  # byte-identical to the bbox policy (macroIslandBufferCacheByteIdentity CASE 9) and measures the
  # multi-region win. Runtime-flippable; a flip is pixel-invisible (both policies keep the coverage
  # invariant). Class property, like islandBufferCacheEnabled.
  @damageRectListEnabled: true

  # §4.4 island buffer cache — the async-atlas invalidation epoch. SWCanvas loads glyph atlases
  # asynchronously; until warm, text rasterises as placeholder BLOCKS into cached back buffers
  # (SWCanvasElement-extensions swCanvasScheduleTextRefresh). When an atlas warms, the immutable
  # text-back-buffer cache is RESET so the text re-renders — and an island buffer is a FURTHER cache
  # downstream of those, so it must invalidate too (else a plain composite re-blits the frozen block
  # glyphs). This counter bumps on every immutable-cache reset (via resetImmutableBackBuffersCache
  # below); a TransformFrameWdgt full-rebuilds when its stored epoch is stale. Class property (survives
  # world-snapshot serialization; matched to islandBufferCacheEnabled). See docs/archive/island-buffer-cache-plan.md §6.
  @immutableBackBufferGeneration: 0

  # The single reset entry for the immutable text-back-buffer cache: resets it AND bumps the epoch so
  # downstream island buffers rebuild from the now-warm text, AND repaints everything — dropping the
  # cache means every text-bearing pixel on screen may be stale, so the full repaint is intrinsic to
  # the reset, not the caller's business (widget-citizenship point 2: I invalidate myself). Callers:
  # the test ground-truth oracles, and swCanvasScheduleTextRefresh's UNATTRIBUTED fallback — the
  # attributed atlas-warm path is the surgical noteColdGlyphRegionsWarm below. The requested repaint
  # needs no capture-side flag: every pixel read rides the end-of-cycle seam
  # (MacroToolkit.captureAtEndOfCycle, delivered after _repaintDamagedRects), so a read can never land
  # between this request and its flush.
  resetImmutableBackBuffersCache: ->
    @cacheForImmutableBackBuffers?.reset?()
    WorldWdgt.immutableBackBufferGeneration++
    @_fullChanged()

  # PUBLIC notification (SWCanvas pages only — the fillText seam in SWCanvasElement-extensions
  # records the callers per DRAW): these widgets painted placeholder glyphs while their atlas
  # was cold, and the atlas has now warmed. Evict exactly the cache entries built during the
  # cold window (they may embed placeholder pixels, and entries are shared content-keyed across
  # widgets, so a kept entry would re-blit placeholders on the next hit) and repaint exactly
  # the affected widgets, through their shadow owners. The island-buffer epoch stays put: each
  # widget's own damage deposits into its island buffer through the exact flesh-out lanes.
  # resetImmutableBackBuffersCache above remains the whole-world verb (test oracles; the
  # unattributed-cold-draw fallback).
  noteColdGlyphRegionsWarm: (widgets, cacheKeys) ->
    for key in cacheKeys
      @cacheForImmutableBackBuffers?.remove key
    for w in widgets
      continue unless w? and w.root() == @   # destroyed/detached: its pixels are already erased
      # cross-invalidation-sanctioned: atlas-warm orchestration — the world repaints the
      # widgets recorded as having painted cold placeholder glyphs
      w._fullChangedIncludingShadowOwner()
    return

  # PUBLIC notification — a widget currently marked in my damage-bookkeeping lists was
  # deep-copied: the copy must inherit the mark (it will paint this cycle exactly where the
  # original would). I mutate MY OWN lists here, in the method the widget's deep-copy hook
  # (Widget.alignCopiedWidgetToDamageInfoDataStructures) invokes on me — widgets never push
  # onto my lists directly (widget-citizenship point 2).
  noteWidgetCopied: (originalWidget, copiedWidget) ->
    if @widgetsWithMaybeChangedPaintBounds.includes(originalWidget) and
     !@widgetsWithMaybeChangedPaintBounds.includes(copiedWidget)
      @widgetsWithMaybeChangedPaintBounds.push copiedWidget

    if @widgetsWithMaybeChangedFullPaintBounds.includes(originalWidget) and
     !@widgetsWithMaybeChangedFullPaintBounds.includes(copiedWidget)
      @widgetsWithMaybeChangedFullPaintBounds.push copiedWidget

  # PUBLIC notification — the wallpaper (world.wallpaper, my delegated collaborator) changed its
  # pattern. My DesktopAppearance paints the backdrop by reading world.wallpaper, so a pattern
  # change means my own pixels are stale. I invalidate MYSELF here, in the method the wallpaper
  # invokes on me (widget-citizenship point 2) — the wallpaper never reaches into my _changed().
  noteWallpaperChanged: ->
    @_changed()

  damageRects: undefined
  duplicatedDamageRectsTracker: undefined
  numberOfDuplicatedDamageRects: 0

  # target -> style descriptor (HighlighterWdgt.fillStyle / — Phase 2 — outline styles). A Map, not
  # a Set: the drag-embed arc needs per-target highlight styles (the style channel). The two tracking
  # sets below stay Sets (membership only).
  widgetsToBeHighlighted: undefined
  currentHighlightingWidgets: undefined
  widgetsBeingHighlighted: undefined

  # --- drag-embed affordance overlays (docs/specs/drag-embed-interaction-spec.md §6/§11) --------
  # The hand's state machine sets the *Declared slots each cycle (undefined = not wanted); the pre-paint
  # reconciler addDragAffordanceWidgets creates/moves/destroys the reconciler-owned overlay widgets.
  # PRODUCT code (unlike the pinout debug path) — ships in the homepage build.
  dragEmbedChargeRingDeclared: undefined
  dragEmbedLabelDeclared: undefined
  dragEmbedLockBadgeDeclared: undefined
  dragEmbedChargeRingWdgt: undefined
  dragEmbedLabelWdgt: undefined
  dragEmbedLockBadgeWdgt: undefined

  # --- editor-focus selection (§5.D D-3/D21; selection-overlay-unification arc) --------------------
  # The widget generically SELECTED for editing this cycle, or undefined. PULL model: recomputed each cycle from
  # editorFocusWdgt + the edit-mode predicate (_updateEditorSelectionOverlay), so it can't drift. The
  # selection is drawn as a per-widget PAINT-TIME overlay (Widget._drawSelectionOverlay) on top of the
  # selected widget's own content, NOT a separate world-attached widget -- so it rides that widget's own
  # z-order + back-buffer for free. This is a once-per-cycle cache; the per-widget paint reads it via the
  # O(1) _isEditorSelected identity check (never the tree-walking _widgetBeingEdited).
  _editorSelectedWidget: undefined

  steppingWdgts: undefined

  # viewports whose post-release MOMENTUM glide is still running
  # (ViewportWdgt's drag-to-scroll step decaying its last delta by
  # friction each frame). Wall-clock/frame-cadence driven, so the macro
  # pump holds "waitNoInputsOngoing" and screenshots until this drains —
  # the same idea as waiting for font atlases before a capture.
  wdgtsWithOngoingScrollMomentum: undefined

  # widgets that entered a fractional-consuming holder (me, or a StretchablePanelWdgt) this
  # turn and whose proportional bookkeeping the drain station derives once their builder is
  # done placing them -- the __add seed (stretch-fractional auto-bookkeeping arc). Cleared
  # in the world teardown like every other world-level ephemeral collection.
  pendingFractionalBookkeepingSeeds: undefined

  # widgets whose fractional bookkeeping must be RE-derived because an external gesture just
  # changed their geometry (a resize/move HandleWdgt release -- the F6 re-record family,
  # deferred because the handle's writes are deferred-settle). Drained AFTER the geometry
  # flush, so the re-record reads the settled fixed point. Cleared in the world teardown.
  pendingFractionalReRecords: undefined

  anyScrollMomentumOngoing: ->
    @wdgtsWithOngoingScrollMomentum.size > 0

  binWdgt: undefined
  shelfWdgt: undefined

  # The flat margin every damage rect is grown by (AA fringe + slack). Shadows are NOT
  # covered by this margin: a shadow is covered EXACTLY, whatever its size or direction, by the
  # pre-map shadow extension in the widget's own plane — Widget.shadowExtendedRect at the record
  # site (source side) and at the flesh-out destination lanes.
  damageRectMargin: 6

  inputEventsQueue: undefined

  widgetsReferencingOtherWidgets: undefined
  incrementalGcSessionId: 0
  desktopSidesPadding: 10

  # the desktop lays down icons vertically
  laysIconsHorizontallyInGrid: false
  iconsLayingInGridWrapCount: 5

  errorsWhileRepainting: undefined
  paintingWidget: undefined
  widgetsGivingErrorWhileRepainting: undefined

  # errors thrown by a _reLayout() DURING the recalculateLayouts flush. We can't build the
  # error console there: createErrorConsole uses the public, self-flushing geometry setters,
  # which would re-enter recalculateLayouts and throw. So we stash them here and report them
  # next cycle, outside the flush -- exactly like errorsWhileRepainting. (task #18)
  layoutErrorsToReport: undefined

  # this one is so we can left/center/right align in
  # a document editor the last widget that the user "touched"
  # TODO this could be extended so we keep a "list" of
  # "selected" widgets (e.g. if the user ctrl-clicks on a widget
  # then it highlights in some manner and ends up in this list)
  # and then operations can be performed on the whole list
  # of widgets.
  editorFocusWdgt: undefined

  # the world's input and text-editing state, all established in the constructor.
  #   @hand — the ONE ActivePointerWdgt: the pointer, and the carrier of whatever is being dragged.
  #   @keyboardEventsReceivers — widgets currently listening for keyboard input.
  #   @caret — the single live CaretWdgt, or undefined when nothing is being edited.
  #   @lastEditedText — the widget the caret was last in, kept after the caret goes so an editor
  #     can still act on "the text the user last touched" (see @editorFocusWdgt above).
  #   @temporaryHandlesAndLayoutAdjusters — the ephemeral handles/adjusters overlaid on a widget.
  hand: undefined
  keyboardEventsReceivers: undefined
  caret: undefined
  lastEditedText: undefined
  temporaryHandlesAndLayoutAdjusters: undefined

  wallpaper: undefined

  untitledNamingService: undefined
  widgetFactory: undefined

  # world.parts — the runtime loader for lazily-loadable PARTS of the system
  # (buildSystem/parts.json), and world.dataflow / world.storageSorter / world.sourceEditsRegistry,
  # the three other shipped product collaborators. All four are constructed unguarded.
  parts: undefined
  dataflow: undefined
  storageSorter: undefined
  sourceEditsRegistry: undefined

  # the pinout debug overlay, a dev-only collaborator: present only when its class ships, so
  # every caller soaks (@pinouts?.…) and it is legitimately undefined in a production build.
  pinouts: undefined

  # the simple-editor templates carried in a whole-world snapshot; undefined until one is loaded.
  simpleEditorTemplates: undefined

  isIndexPage: undefined
  # dev mode: the in-world editing/inspection affordances. Toggled from the world menu.
  isDevMode: undefined

  healingRectanglesPhase: false

  # a DISSOLVED world is one that resetWorld has already replaced: its tree, hand and listeners are
  # gone, another WorldWdgt owns the page, and nothing will ever pump this one again. The flag is
  # what lets the corpse recognise itself at the two seams where it could still act — the damage
  # funnels below (_changed / _fullChanged) and the cycle it was dissolved in the middle of
  # (doOneCycle). Set LAST by _dissolveWorldNoSettle, never cleared: nothing revives a world.
  _dissolved: false

  # damage-suppression nesting depth (Widget._repaintAsOneUnit): while > 0,
  # _changed/_fullChanged marks are dropped — the unit's owner issues the one
  # covering mark at close. Transient (never serialized, like the trackChanges
  # stack it replaced); the teardown re-zeroes it, and _repaintDamagedRects self-heals
  # + reports DAMAGE_SUPPRESSION_UNBALANCED (a headless fail-gate token) if it
  # is ever nonzero at flush.
  _damageSuppressionDepth: 0

  # count of _changed/_fullChanged attempts dropped under the depth above.
  # MONOTONIC, never reset — only deltas are read: _repaintAsOneUnit snapshots
  # it at open and skips its closing cover when it did not advance (a provably
  # vacuous unit). Transient like the depth (never serialized); exempted by
  # name in the tests' world-state fingerprint audit.
  _suppressedMarkAttempts: 0

  widgetsWithMaybeChangedPaintBounds: undefined
  widgetsWithMaybeChangedFullPaintBounds: undefined
  widgetsThatMaybeChangedLayout: undefined
  # (ordered down-walk Stage B1) the nodes currently flagged hasDirtyDescendant, recorded by
  # Widget.__flagHasDirtyDescendantUpwards as it sets each flag, so the flush that drains
  # widgetsThatMaybeChangedLayout can clear exactly the flagged set (recalculateLayouts' finally).
  # The two lists share one lifecycle: dirt appears -> both grow; drain completes -> both empty.
  _widgetsFlaggedHasDirtyDescendant: undefined
  # (ordered down-walk Stage B2) re-lays performed by the current flush's down-walk; reset at each
  # _recalculateLayoutsBody entry. Feeds the RECALC_NONCONVERGENCE never-fire assert and the
  # zero-progress stuck-detection (DOWNWALK_UNREACHABLE_CHAINTOP).
  _downWalkRelaidCount: 0

  # self-settling public geometry API (prototype 2026-06-19): re-entrancy guards.
  # _inLayoutMutation is set while a public geometry setter is running its
  # core+flush; _recalculatingLayouts is set while recalculateLayouts runs. Both
  # exist to THROW on re-entry, so a public setter calling another (or a layout
  # pass calling a public setter) -- which would flush more than once per logical
  # mutation -- is found and removed rather than silently tolerated.
  _inLayoutMutation: false
  _recalculatingLayouts: false

  macroToolkit: undefined

  constructor: (
      @worldCanvas,
      @automaticallyAdjustToFillEntireBrowserAlsoOnResize = true
      ) ->

    # The WorldWdgt is the very first widget to
    # be created.

    # world at the moment is a global variable, there is only one
    # world and this variable needs to be initialised as soon as possible, which
    # is right here. This is because there is code in this constructor that
    # will reference that global world variable, so it needs to be set
    # very early
    window.world = @

    # The world's mutable containers are per-instance and must exist before super():
    # the ancestor constructors and the sizing/extent calls below already mark damage
    # and layout dirtiness into them, and a class-body initializer would be a
    # prototype-level object shared by every world ever constructed on the page.
    @wdgtsDetectingClickOutsideMeOrAnyOfMeChildren = new Set
    @hierarchyOfClickedWdgts = new Set
    @hierarchyOfClickedMenus = new Set
    @popUpsMarkedForClosure = new Set
    @freshlyCreatedPopUps = new Set
    @openPopUps = new Set
    @toolTipsList = new Set
    @widgetsToBeHighlighted = new Map
    @currentHighlightingWidgets = new Set
    @widgetsBeingHighlighted = new Set
    @steppingWdgts = new Set
    @wdgtsWithOngoingScrollMomentum = new Set
    @pendingFractionalBookkeepingSeeds = new Set
    @pendingFractionalReRecords = new Set
    @widgetsReferencingOtherWidgets = new Set
    @errorsWhileRepainting = []
    @widgetsGivingErrorWhileRepainting = []
    @layoutErrorsToReport = []
    @widgetsWithMaybeChangedPaintBounds = []
    @widgetsWithMaybeChangedFullPaintBounds = []
    @widgetsThatMaybeChangedLayout = []
    @_widgetsFlaggedHasDirtyDescendant = []

    if window.location.href.includes "worldWithSystemTestHarness"
      @isIndexPage = false
    else
      @isIndexPage = true

    WorldWdgt.preferencesAndSettings = new PreferencesAndSettings

    super()
    # the desktop's wallpaper (available patterns + current choice + picker menu),
    # constructed before @appearance, which paints the desktop reading from it.
    @wallpaper = new Wallpaper
    @appearance = new DesktopAppearance @

    @color = Color.create 205, 205, 205 # (130, 130, 130)
    @strokeColor = undefined

    @alpha = 1

    # additional properties:
    @isDevMode = false
    @hand = new ActivePointerWdgt
    @keyboardEventsReceivers = new Set
    @lastEditedText = undefined
    @caret = undefined
    @temporaryHandlesAndLayoutAdjusters = new Set
    @inputDOMElementForVirtualKeyboard = undefined

    if @automaticallyAdjustToFillEntireBrowserAlsoOnResize and @isIndexPage
      @stretchWorldToFillEntirePage()
    else
      @_sizeCanvasToTestScreenResolution()

    # @worldCanvas.width and height here are in physical pixels
    # so we want to bring them back to logical pixels
    @setBounds new Rectangle 0, 0, @worldCanvas.width / ceilPixelRatio, @worldCanvas.height / ceilPixelRatio

    @initEventListeners()
    if Automator?
      # the page's ONE automator (Automator.current) -- a reconstructed world re-aims at it, never replaces it
      @automator = Automator.current ?= new Automator
    if MacroToolkit?
      @macroToolkit = new MacroToolkit
    @untitledNamingService = new UntitledNamingService
    # the per-world log of in-world source edits (instance + class scope), embedded in and
    # replayed from a whole-world snapshot. A product collaborator (ships in production).
    @sourceEditsRegistry = new SourceEditsRegistry
    # WidgetFactory is dev/demo scaffolding (homepage-excluded), so guard like
    # the other test/dev collaborators above -- in a production build the class is
    # stripped and the demo menus that use it are stripped too.
    if WidgetFactory?
      @widgetFactory = new WidgetFactory
    # the pinout debug overlay (floating labels naming the widget they point at), same
    # dev-only collaborator shape as @widgetFactory above -- every caller soaks.
    if PinoutsOverlay?
      @pinouts = new PinoutsOverlay

    # world.parts — the runtime loader for lazily-loadable PARTS of the system
    # (buildSystem/parts.json). A shipped product collaborator, constructed unguarded: every
    # artifact has a partition, even one whose every part is eager.
    @parts = new PartsRegistry

    # world.dataflow — the ONE calculation/dataflow engine (spec docs/specs/dataflow-engine-spec.md).
    # A shipped product collaborator (like @sourceEditsRegistry above), so it is constructed
    # UNGUARDED, unlike the dev-only @widgetFactory. It drains once per cycle in doOneCycle,
    # between value-settling (its own) and geometry-settling (recalculateLayouts).
    @dataflow = new DataflowEngine

    # world.storageSorter — the eager bin/shelf sorter (StorageSorter): keeps the
    # standing storage invariant (shelf = reachable, bin = lost) by draining a
    # marked pending sort once per cycle in doOneCycle, right after dataflow.
    # A shipped product collaborator, constructed unguarded like @dataflow.
    @storageSorter = new StorageSorter

    # The DOM <canvas id="world"> (@worldCanvas) stays the event target. Under the
    # SWCanvas backend all rendering goes to a separate software render canvas
    # (@worldRenderCanvas), whose pixels are blitted onto the DOM canvas once per
    # painted frame (see _repaintDamagedRects / blitRenderCanvasToDOM). When the flag is
    # off, the render canvas IS the DOM canvas and there is no blit, so behaviour
    # is identical to before.
    if window.FIZZYGUM_USE_SWCANVAS and window.SWCanvas?
      @worldRenderCanvas = HTMLCanvasElement.createOfPhysicalDimensions new Point @worldCanvas.width, @worldCanvas.height
      @domBlitContext = @worldCanvas.getContext "2d"
    else
      @worldRenderCanvas = @worldCanvas
      @domBlitContext = undefined
    @worldCanvasContext = @worldRenderCanvas.getContext "2d"
    @worldCanvasContext.textPixelDensity = ceilPixelRatio if @worldCanvasContext.textPixelDensity?

    @canvasForTextMeasurements = HTMLCanvasElement.createOfPhysicalDimensions()
    @canvasContextForTextMeasurements = @canvasForTextMeasurements.getContext "2d"
    @canvasContextForTextMeasurements.useLogicalPixelsUntilRestore()
    @canvasContextForTextMeasurements.textAlign = "left"
    @canvasContextForTextMeasurements.textBaseline = "bottom"

    # when using an inspector it's not uncommon to render
    # 400 labels just for the properties, so trying to size
    # the cache accordingly...
    @cacheForTextMeasurements = new LRUCache 1000, 1000*60*60*24
    @cacheForTextParagraphSplits = new LRUCache 300, 1000*60*60*24
    @cacheForParagraphsWordsSplits = new LRUCache 300, 1000*60*60*24
    @cacheForParagraphsWrappingData = new LRUCache 300, 1000*60*60*24
    @cacheForTextWrappingData = new LRUCache 300, 1000*60*60*24
    @cacheForImmutableBackBuffers = new LRUCache 1000, 1000*60*60*24
    @cacheForTextBreakingIntoLinesTopLevel = new LRUCache 10, 1000*60*60*24

    @inputEventsQueue = new InputEventsQueue

    # the resize policy this world was built with, recorded so a reconstruction can be built with
    # the same one -- see the _bootAutoAdjustToFillEntireBrowserAlsoOnResize declaration above
    @_bootAutoAdjustToFillEntireBrowserAlsoOnResize = @automaticallyAdjustToFillEntireBrowserAlsoOnResize

    @_changed()

  # Memoised absolute position of the world canvas within the document.
  # Reading offsetLeft/offsetTop/offsetParent forces a synchronous style+layout
  # reflow whenever the DOM is dirty; the SystemTests control panel writes to the
  # DOM on every logged message, so recomputing this per synthesised input event
  # was ~5.8% of suite CPU (a forced reflow each time). The world canvas is
  # absolutely positioned and only moves on a resize / explicit reposition — and
  # appending control-panel messages (not an ancestor of the canvas) never moves
  # it — so we cache the value and invalidate it only where the canvas geometry
  # actually changes (see invalidateCanvasPositionCache callers). Fizzygum's world
  # canvas fills a fixed viewport, so page scroll is not a factor; add scroll
  # invalidation here if the canvas is ever embedded in a scrollable container.
  _cachedCanvasPosition: undefined

  invalidateCanvasPositionCache: ->
    @_cachedCanvasPosition = undefined

  # answer the absolute coordinates of the world canvas within the document
  getCanvasPosition: ->
    unless @_cachedCanvasPosition?
      if !@worldCanvas?
        # not cached: recompute once worldCanvas exists
        return {x: 0, y: 0}
      x = @worldCanvas.offsetLeft
      y = @worldCanvas.offsetTop
      offsetParent = @worldCanvas.offsetParent
      while offsetParent?
        x += offsetParent.offsetLeft
        y += offsetParent.offsetTop
        if offsetParent isnt document.body and offsetParent isnt document.documentElement
          x -= offsetParent.scrollLeft
          y -= offsetParent.scrollTop
        offsetParent = offsetParent.offsetParent
      @_cachedCanvasPosition = {x: x, y: y}
    # always hand back a fresh object — callers (e.g. stretchWorldToFillEntirePage)
    # mutate the returned position, which must never corrupt the cache
    {x: @_cachedCanvasPosition.x, y: @_cachedCanvasPosition.y}

  colloquialName: ->
    "Desktop"

  _makePrettier: ->
    WorldWdgt.preferencesAndSettings.menuFontSize = 14
    WorldWdgt.preferencesAndSettings.menuHeaderFontSize = 13
    WorldWdgt.preferencesAndSettings.menuHeaderColor = Color.create 125, 125, 125
    WorldWdgt.preferencesAndSettings.menuHeaderBold = false
    WorldWdgt.preferencesAndSettings.menuStrokeColor = Color.create 186, 186, 186
    WorldWdgt.preferencesAndSettings.menuBackgroundColor = Color.create 250, 250, 250
    WorldWdgt.preferencesAndSettings.menuButtonsLabelColor = Color.create 50, 50, 50

    WorldWdgt.preferencesAndSettings.normalTextFontSize = 13
    WorldWdgt.preferencesAndSettings.titleBarTextFontSize = 13
    WorldWdgt.preferencesAndSettings.titleBarTextHeight = 16
    WorldWdgt.preferencesAndSettings.titleBarBoldText = false
    WorldWdgt.preferencesAndSettings.bubbleHelpFontSize = 12


    WorldWdgt.preferencesAndSettings.iconDarkLineColor = Color.create 37, 37, 37


    WorldWdgt.preferencesAndSettings.defaultPanelsBackgroundColor = Color.create 249, 249, 249
    WorldWdgt.preferencesAndSettings.defaultPanelsStrokeColor = Color.create 198, 198, 198

    @wallpaper.setPattern "dots"

    @_changed()

  createErrorConsole: ->
    errorsLogViewerWdgt = new ErrorsLogViewerWdgt()
    wm = new FrameWdgt errorsLogViewerWdgt
    wm.setExtent new Point 460, 400
    @add wm


    @errorConsole = wm
    @errorConsole.setBounds (new Point 190,10), new Point 550,415
    @errorConsole.hide()

  # Remove the loading spinner and the fake desktop the page paints while the world is still being
  # built. Both elements belong to the LOADING PAGE, not to any world — which is why this is boot's
  # business (startWorld calls it) and NOT part of finishWorldSetup: a reconstructed world arrives
  # long after they are gone, and there is nothing for it to hide.
  # IDEMPOTENT: both lookups are soaked, so a second call finds nothing to remove rather than a
  # missing element to dereference.
  removeSpinnerAndFakeDesktop: ->
    spinner = document.getElementById 'spinner'
    spinner?.parentNode?.removeChild spinner
    splashScreenFakeDesktop = document.getElementById 'splashScreenFakeDesktop'
    splashScreenFakeDesktop?.parentNode?.removeChild splashScreenFakeDesktop

  createDesktop: ->
    @setColor Color.create 244,243,244
    @_makePrettier()

    acm = new AnalogClockWdgt
    acm._applyExtent new Point 80, 80
    # the creator ARMS the clock's corner knob (top-right); the corner pass places it, so
    # no hand-computed position here. Corner-anchored until the user grabs it -- the grab
    # disarms the slot and the membership rule takes over (proportional tracking).
    @add acm, layoutSpec: acm.cornerSpec

    # ⚠⚠ EVERY DESKTOP ICON IS BUILT WITHOUT ITS APP. An icon needs its ART -- all of it core, below
    # -- and the app's class NAME; the launcher resolves that name to a part when it is CLICKED
    # (AppLauncherWdgt's lazy mode). So the Makers' eight app classes sit
    # in the lazy 'authoring' part they already build from, the ninth opener's FridgeMagnetsApp sits
    # in lazy 'fizzytiles', and a session that never opens a Maker never downloads or compiles one.
    # ⇒ what forces an eager launcher is BOOT-TIME REACHABILITY, and an icon is not its app: reading
    # a name at boot is not reaching the class. (Before this, an eager sliver part existed for each
    # lazy app precisely because createDesktop constructed the app to ask it for its title and icon.)
    # ⚠ The guard is canEverProvideClass, NOT `if SimpleDocumentApp?`: for a lazy class an existence
    # test reads "not fetched yet" and would silently drop the icon for ever. This asks the other
    # question -- can this artifact EVER produce it -- so `lean`, which ships neither part, draws
    # none of these rather than icons whose click could only reject.
    # ⚠ ORDER IS THE LAYOUT: createDesktop places icons in call order down a column (wrapping after
    # 5), so this sequence, and the bin's position inside it, is what the user sees.
    # ⚠ A NAME IS ALL THIS NEEDS. The caption and the art come from AppCatalog, which is the one
    # place either is written down; naming them again here is how one of the two loses a field --
    # tooltips. The app class itself is NOT touched — that is what keeps every app lazy.
    addOpener = (appClassName) ->
      AppLauncherWdgt.addToDesktop appClassName
    addOpener "HowToSaveMessageApp"
    menusHelper.binIconAndText()
    addOpener "SimpleDocumentApp"
    addOpener "FizzyPaintApp"
    addOpener "SimpleSlideApp"
    addOpener "DashboardsApp"
    addOpener "PatchProgrammingApp"
    addOpener "GenericPanelApp"
    addOpener "ToolbarsApp"
    addOpener "FridgeMagnetsApp"
    # The Examples folder is created EMPTY and fills itself the first time it is opened: its five
    # openers, and the C-F art only they draw, are LAZY parts. See ExamplesFolderWindowWdgt for
    # the three tiers (boot / open / click) and why a folder — unlike the desktop icons above —
    # can defer its contents at all.
    @makeFolder "Examples", new ExamplesFolderWindowWdgt

    # Guard: VideoPlayerWithRecommendationsWdgt is only bundled with --includeVideoPlayer,
    # so in a default build this boot-time auto-launch would throw "...is not defined".
    # Only run it when the class is actually present. (Surfaced by the boot-smoke gate;
    # see ../Fizzygum-tests/scripts/smoke-boot-headless.js.)
    if window.VideoPlayerWithRecommendationsWdgt? then world.draftRunVideoPlayer()


  mostRecentlyCreatedPopUp: ->
    mostRecentPopUp = undefined
    mostRecentPopUpID = -1

    # Membership is doublechecked against the TREE here, and pruned lazily. The close
    # and destroy CORES drop a pop-up from @openPopUps as it dies, so a dying pop-up
    # announces itself; what nothing announces is a pop-up that merely LEAVES the tree
    # (isOrphan = my root is neither the world nor the hand). Pruning on this query --
    # which the pointer asks on a click, not the cycle -- keeps the set honest without
    # a per-cycle walk over it.
    @openPopUps.forEach (eachPopUp) =>
      if eachPopUp.isOrphan()
        @openPopUps.delete eachPopUp
      else if eachPopUp.instanceNumericID >= mostRecentPopUpID
        mostRecentPopUp = eachPopUp

    return mostRecentPopUp

  # used to close temporary menus
  # thin-wrap-exempt: NOT the canonical wrap over its _NoSettle twin -- the two are PARALLEL closers, not
  # wrapper/core. This one closes each marked popup via the self-settling close() (correct for the top-level
  # "pin" menu-click path, the title-bar tap -> pinPopUp); the twin closes via _closeNoSettle for the drop path
  # (FrameWdgt._reactToBeingDropped -> pinPopUp, inside the drop's settle). Separate keeps the menu path's
  # per-popup settle exactly (vs collapsing to one settle). Only TRANSIENT pop-ups ever enter the marked
  # set (propagateKillPopUps gates on the lifetime), so each drained close lands on
  # FrameWdgt._closeNoSettle's destroy branch.
  closePopUpsMarkedForClosure: ->
    @popUpsMarkedForClosure.forEach (eachWidget) =>
      eachWidget.close()
    @popUpsMarkedForClosure.clear()

  # NON-settling variant for the drop path (FrameWdgt._reactToBeingDropped -> pinPopUp, inside the drop's
  # settle): each marked popup closes through the core _closeNoSettle so it rides the drop's single
  # flush instead of re-entering the flush guard. The public version above stays for the top-level
  # menu-click "pin" path, where the self-settling close() is correct.
  _closePopUpsMarkedForClosureNoSettle: ->
    @popUpsMarkedForClosure.forEach (eachWidget) =>
      eachWidget._closeNoSettle()
    @popUpsMarkedForClosure.clear()
  
  # fullPaintIntoAreaOrBlitFromBackBuffer results into actual painting of pieces of
  # widgets done
  # by the paintIntoAreaOrBlitFromBackBuffer function.
  # The paintIntoAreaOrBlitFromBackBuffer function is defined in Widget.
  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, aRect) ->
    # invokes the Widget's fullPaintIntoAreaOrBlitFromBackBuffer, which has only three implementations:
    #  * the default one by Widget which just invokes the paintIntoAreaOrBlitFromBackBuffer of all children
    #  * the interesting one in PanelWdgt which a) narrows the damage
    #    rectangle (intersecting it with its border
    #    since the PanelWdgt clips at its border) and b) stops recursion on all
    #    the children that are outside such intersection.
    #  * this implementation which just takes into account that the hand
    #    (which could contain a Widget being floatDragged)
    #    is painted on top of everything.
    #
    # Occlusion culling (docs/plans/occlusion-culling-plan.md P2): if some top-level opaque widget fully
    # covers this damage rect, paint STARTING FROM it (skipping the desktop fill + every child behind
    # it, within this rect) instead of the full back-to-front super() pass. _paintedFromFrontmostCoverer
    # returns true iff it did that painting; otherwise we fall back to the normal super() path.
    if !@_paintedFromFrontmostCoverer aContext, aRect
      super aContext, aRect

    # the mouse cursor is always drawn on top of everything
    # and it's not attached to the WorldWdgt.
    @hand.fullPaintIntoAreaOrBlitFromBackBuffer aContext, aRect

  # Occlusion culling (docs/plans/occlusion-culling-plan.md P2, Avenue A -- a stateless per-rect pre-scan).
  # Reverse-scan world.children (the array is BACK-to-front, so reverse = front-to-back) for the
  # frontmost widget that provably paints a fully-opaque fill covering the WHOLE damage rect; if one
  # is found, paint only it and the widgets in front of it -- skipping the desktop self-paint and
  # every child behind the coverer (all pure overdraw in this rect). Returns true iff it painted (the
  # caller then skips super()); false = no coverer, caller paints the normal full-depth way.
  # CONSERVATIVE: opaqueCoveredRect and clippedThroughBounds both err to "not covered", so a wrong
  # answer here can only be a false NEGATIVE -> a redundant repaint, never a dropped pixel.
  _paintedFromFrontmostCoverer: (aContext, aRect) ->
    return false if !WorldWdgt.occlusionCullingEnabled
    # cull ONLY the live on-screen paint; scratch / back-buffer contexts (and their damage
    # bookkeeping) must be left exactly as they are
    return false if aContext != @worldCanvasContext
    damagedPart = aRect.intersect @boundingBox()          # identical to the mixin's narrowing of the damage rect to the desktop
    return false if damagedPart.isEmpty()
    testRect = damagedPart.expandBy 1                      # +1px margin: painting rounds on the logical grid (calculateKeyValues)
    covererIndex = undefined
    for i in [@children.length - 1 .. 0] by -1          # front-to-back
      child = @children[i]
      coveredRect = child.opaqueCoveredRect()
      if coveredRect? and coveredRect.containsRectangle(testRect) and
          child.clippedThroughBounds().containsRectangle damagedPart
        covererIndex = i
        break
    return false if !covererIndex?
    # A coverer owns every pixel of damagedPart. Preserve the world's OWN paint-record bookkeeping even
    # though its self-paint is bypassed -- the world can itself be a damagedWidget (e.g. wallpaper
    # change), see occlusion-culling-plan.md §1b(b).
    @_recordDrawnAreaForNextDamageRects()
    # paint the coverer and everything in front of it, narrowed to damagedPart (byte-identical child
    # trajectory to the mixin's own children loop, which narrows to the same rect)
    for i in [covererIndex ... @children.length]
      @children[i].fullPaintIntoAreaOrBlitFromBackBuffer aContext, damagedPart
    # replicate the mixin's trailing panel-stroke pass (a no-op for the world unless a strokeColor is
    # ever set -- RectangularAppearance.paintStroke gates on @widget.strokeColor?)
    @paintStroke aContext, aRect
    return true

  clippedThroughBounds: ->
    # always recompute -- the world is the clip terminal, so its clipped bounds ARE its boundingBox; trivial, no version cache.
    return @boundingBox()

  # terminal of every desktop widget's clipThrough recursion (via the firstParentClippingAtBounds -> world
  # fallback); recomputes trivially, does not participate in the version caches.
  clipThrough: ->
    return @boundingBox()

  # SLOW-oracle mirrors of the two overrides above (Tier J2): the world is the clip terminal, so its
  # clipped / clip-through bounds ARE its boundingBox -- exactly what the cached overrides return. These keep
  # the base SLOWclipThrough recursion terminating at the world, mirroring the cached recursion.
  SLOWclippedThroughBounds: ->
    return @boundingBox()

  SLOWclipThrough: ->
    return @boundingBox()

  _pushDamageRect: (damagedWidget, theRect, isSrc) ->
    if @duplicatedDamageRectsTracker[theRect.toString()]?
      @numberOfDuplicatedDamageRects++
    else
      if isSrc
        damagedWidget.srcDamageRectIndex = @damageRects.length
      else
        damagedWidget.dstDamageRectIndex = @damageRects.length
      if !theRect?
        debugger
      @damageRects.push theRect
    @duplicatedDamageRectsTracker[theRect.toString()] = true

  # both lanes produced a rect for this widget (e.g. it moved in place): push ONE merged
  # rect when merging wastes little area — the dominant case in practice — else push both
  _mergeDamageRectsIfCloseOrPushBoth: (damagedWidget, sourceDamageRect, destinationDamageRect) ->
    mergedDamageRect = sourceDamageRect.merge destinationDamageRect
    mergedDamageRectArea = mergedDamageRect.area()
    sumArea = sourceDamageRect.area() + destinationDamageRect.area()
    if mergedDamageRectArea < sumArea + sumArea/10
      @_pushDamageRect damagedWidget, mergedDamageRect, true
    else
      @_pushDamageRect damagedWidget, sourceDamageRect, true
      @_pushDamageRect damagedWidget, destinationDamageRect, false


  _checkARectWithHierarchy: (aRect, damagedWidget, isSrc) ->
    damagedWidgetAncestor = damagedWidget

    while damagedWidgetAncestor.parent?
      damagedWidgetAncestor = damagedWidgetAncestor.parent
      if damagedWidgetAncestor.srcDamageRectIndex?
        if !@damageRects[damagedWidgetAncestor.srcDamageRectIndex]?
          debugger
        if @damageRects[damagedWidgetAncestor.srcDamageRectIndex].containsRectangle aRect
          if isSrc
            @damageRects[damagedWidget.srcDamageRectIndex] = undefined
            damagedWidget.srcDamageRectIndex = undefined
          else
            @damageRects[damagedWidget.dstDamageRectIndex] = undefined
            damagedWidget.dstDamageRectIndex = undefined
        else if aRect.containsRectangle @damageRects[damagedWidgetAncestor.srcDamageRectIndex]
          @damageRects[damagedWidgetAncestor.srcDamageRectIndex] = undefined
          damagedWidgetAncestor.srcDamageRectIndex = undefined

      if damagedWidgetAncestor.dstDamageRectIndex?
        if !@damageRects[damagedWidgetAncestor.dstDamageRectIndex]?
          debugger
        if @damageRects[damagedWidgetAncestor.dstDamageRectIndex].containsRectangle aRect
          if isSrc
            @damageRects[damagedWidget.srcDamageRectIndex] = undefined
            damagedWidget.srcDamageRectIndex = undefined
          else
            @damageRects[damagedWidget.dstDamageRectIndex] = undefined
            damagedWidget.dstDamageRectIndex = undefined
        else if aRect.containsRectangle @damageRects[damagedWidgetAncestor.dstDamageRectIndex]
          @damageRects[damagedWidgetAncestor.dstDamageRectIndex] = undefined
          damagedWidgetAncestor.dstDamageRectIndex = undefined


  _rectAlreadyIncludedInParentDamagedWidget: ->
    for damagedWidget in @widgetsWithMaybeChangedPaintBounds
        if damagedWidget.srcDamageRectIndex?
          aRect = @damageRects[damagedWidget.srcDamageRectIndex]
          @_checkARectWithHierarchy aRect, damagedWidget, true
        if damagedWidget.dstDamageRectIndex?
          aRect = @damageRects[damagedWidget.dstDamageRectIndex]
          @_checkARectWithHierarchy aRect, damagedWidget, false

    for damagedWidget in @widgetsWithMaybeChangedFullPaintBounds
        if damagedWidget.srcDamageRectIndex?
          aRect = @damageRects[damagedWidget.srcDamageRectIndex]
          @_checkARectWithHierarchy aRect, damagedWidget
        if damagedWidget.dstDamageRectIndex?
          aRect = @damageRects[damagedWidget.dstDamageRectIndex]
          @_checkARectWithHierarchy aRect, damagedWidget

  _cleanupSrcAndDestRectsOfWidgets: ->
    for damagedWidget in @widgetsWithMaybeChangedPaintBounds
      damagedWidget.srcDamageRectIndex = undefined
      damagedWidget.dstDamageRectIndex = undefined
    for damagedWidget in @widgetsWithMaybeChangedFullPaintBounds
      damagedWidget.srcDamageRectIndex = undefined
      damagedWidget.dstDamageRectIndex = undefined


  _fleshOutDamage: ->
    for damagedWidget in @widgetsWithMaybeChangedPaintBounds
      # fresh per widget: a value carried over from a previous iteration would be
      # re-pushed attributed to THIS widget — spurious extra repaint area (any widget
      # lacking one of its own rects would consume its predecessor's)
      sourceDamageRect = undefined
      destinationDamageRect = undefined

      # let's see if this Widget that marked itself as damaged
      # was actually painted in the past frame.
      # If it was then we have to clean up the "before" area
      # even if the Widget is not visible anymore
      if damagedWidget.clippedBoundsWhenLastPainted?
        if damagedWidget.clippedBoundsWhenLastPainted.isNotEmpty()
          # affine transforms (§4.5): clippedBoundsWhenLastPainted is ALREADY the screen-plane footprint
          # (_recordDrawnAreaForNextDamageRects mapped it at paint time, while the widget was still attached),
          # so a widget detached between paint and flush (close/destroy) still erases its true rotated
          # footprint. Off any island the recorded rect is the raw rect ⇒ byte-identical dormant.
          # The record is also SHADOW-INCLUSIVE (extended by the shadow that painted), so the grow here is
          # pure margin — a shadow term would double-cover and hide a record-time regression.
          sourceDamageRect = damagedWidget.clippedBoundsWhenLastPainted.expandBy(1).growBy @damageRectMargin

      # §4.4 island buffer cache — source (old-position) lane (see _fleshOutFullDamage). Consumed by
      # whichever lane runs first (_fleshOutFullDamage is called before _fleshOutDamage); the field is
      # cleared on consumption so this second lane is a no-op when the full lane already handled it.
      if damagedWidget._islandBufferSourceIsland?
        damagedWidget._islandBufferSourceIsland._depositIslandBufferDamageRect damagedWidget._islandBufferSourceVirtualRect
        damagedWidget._islandBufferSourceIsland = undefined

      # for the "destination" damage rectangle we can actually
      # check whether the Widget is still visible because we
      # can skip the destination rectangle in that case
      # (not the source one!)
      unless damagedWidget.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()
        # @clippedThroughBounds() should be smaller area
        # than bounds because it clips
        # the bounds based on the clipping widgets up the
        # hierarchy
        boundsToBeChanged = damagedWidget.clippedThroughBounds()

        if boundsToBeChanged.isNotEmpty()
          # affine transforms (§4.5): map the current (virtual for island descendants)
          # rect to screen BEFORE spread/expand/margin-grow. Mapped BEFORE the merge/
          # dedupe below so those never see mixed planes. Identity → unchanged object.
          # depositBufferDamage=true deposits the NEW (destination) virtual footprint onto the island (§4.4).
          # The shadow of what is about to be painted is applied PRE-map, in the widget's own
          # plane (shadowExtendedRect: the map composes island scale and rotation over it), which
          # also makes the island deposits shadow-inclusive; the post-map grow is pure margin.
          destinationDamageRect = (damagedWidget.mapRectToScreen (damagedWidget.shadowExtendedRect boundsToBeChanged), true).spread().expandBy(1).growBy @damageRectMargin

      if sourceDamageRect? and destinationDamageRect?
        @_mergeDamageRectsIfCloseOrPushBoth damagedWidget, sourceDamageRect, destinationDamageRect
      else if sourceDamageRect? or destinationDamageRect?
        if sourceDamageRect?
          @_pushDamageRect damagedWidget, sourceDamageRect, true
        else
          @_pushDamageRect damagedWidget, destinationDamageRect, true

      damagedWidget.paintBoundsMaybeChanged = false
      damagedWidget.clippedBoundsWhenLastPainted = undefined

    

  _fleshOutFullDamage: ->
    for damagedWidget in @widgetsWithMaybeChangedFullPaintBounds
      # fresh per widget: see the twin note in _fleshOutDamage
      sourceDamageRect = undefined
      destinationDamageRect = undefined

      if damagedWidget.fullClippedBoundsWhenLastPainted?
        if damagedWidget.fullClippedBoundsWhenLastPainted.isNotEmpty()
          # affine transforms (§4.5): fullClippedBoundsWhenLastPainted is ALREADY the screen-plane footprint
          # (mapped at paint time), so a widget detached between paint and flush (close/destroy) erases its
          # true rotated footprint, not the un-transformed slot. Off any island it is the raw rect ⇒ dormant-identical.
          # The record is also SHADOW-INCLUSIVE (extended by the shadow that painted), so the grow here is
          # pure margin — a shadow term would double-cover and hide a record-time regression.
          sourceDamageRect = damagedWidget.fullClippedBoundsWhenLastPainted.expandBy(1).growBy @damageRectMargin

      # §4.4 island buffer cache — source (old-position) lane: erase the vacated buffer region of a
      # widget that MOVED within (or was removed from) its stationary island. The stashed island stays
      # alive even when the widget detached, so removal is ghost-free (_recordDrawnAreaForNextDamageRects).
      if damagedWidget._islandBufferSourceIsland?
        damagedWidget._islandBufferSourceIsland._depositIslandBufferDamageRect damagedWidget._islandBufferSourceVirtualRect
        damagedWidget._islandBufferSourceIsland = undefined

      # for the "destination" damage rectangle we can actually
      # check whether the Widget is still visible because we
      # can skip the destination rectangle in that case
      # (not the source one!)
      unless damagedWidget.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()

        boundsToBeChanged = damagedWidget.fullClippedBounds()

        if boundsToBeChanged.isNotEmpty()
          # affine transforms (§4.5): map to screen before spread/expand/margin-grow, before merge (identity → unchanged).
          # depositBufferDamage=true deposits the NEW (destination) virtual footprint onto each crossed island (§4.4).
          # Shadow applied PRE-map in the widget's own plane (see the twin note in _fleshOutDamage).
          destinationDamageRect = (damagedWidget.mapRectToScreen (damagedWidget.shadowExtendedRect boundsToBeChanged), true).spread().expandBy(1).growBy @damageRectMargin

      if sourceDamageRect? and destinationDamageRect?
        @_mergeDamageRectsIfCloseOrPushBoth damagedWidget, sourceDamageRect, destinationDamageRect
      else if sourceDamageRect? or destinationDamageRect?
        if sourceDamageRect?
          @_pushDamageRect damagedWidget, sourceDamageRect, true
        else
          @_pushDamageRect damagedWidget, destinationDamageRect, true

      damagedWidget.fullPaintBoundsMaybeChanged = false
      damagedWidget.fullClippedBoundsWhenLastPainted = undefined


  _showDamageRects: (aContext) ->
    aContext.save()
    aContext.globalAlpha = 0.5
    aContext.useLogicalPixelsUntilRestore()
 
    for eachDamageRect in @damageRects
      if eachDamageRect?
        randomR = Math.round Math.random() * 255
        randomG = Math.round Math.random() * 255
        randomB = Math.round Math.random() * 255

        aContext.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")"
        aContext.fillRect  Math.round(eachDamageRect.origin.x),
            Math.round(eachDamageRect.origin.y),
            Math.round(eachDamageRect.width()),
            Math.round(eachDamageRect.height())
    aContext.restore()


  # layouts are recalculated like so:
  # there will be several subtrees
  # that will need relayout.
  # So take the head of any subtree and re-layout it
  # The relayout might or might not visit all the subnodes
  # of the subtree, because you might have a subtree
  # that lives inside a floating widget, in which
  # case it's not re-layout.
  # So, a subtree might not be healed in one go,
  # rather we keep track of what's left to heal and
  # we apply the same process: we heal from the head node
  # and take out of the list what's healed in that step,
  # and we continue doing so until there is nothing else
  # to heal.
  # recalculateLayouts is the FLUSH primitive itself (re-entrancy guard + _recalculateLayoutsBody), not
  # a public geometry setter -- so its core is named _Body (the guarded recalc body), NOT the
  # _<name>NoSettle convention, and the thin-wrap lint does not pair it (no exempt marker needed).
  recalculateLayouts: ->
    # DEBUG (auditUndeclaredEndOfCycle): at the END-OF-CYCLE flush only (NOT a self-settle -- a settle has
    # @_inLayoutMutation set), report this frame's UNDECLARED off-settle pushes -- the "careless" set (a public
    # method that forgot to self-settle, or a stream not yet on a *DeferredSettle entrypoint) that the eventual
    # declared-deferred-settling gate will reject. Declared deferred settling (_setMaxDimDeferredSettle) is intentional and excluded.
    if @auditUndeclaredEndOfCycle and not @_inLayoutMutation and @_undeclaredEndOfCyclePushes?.length
      summary = {}
      for c in @_undeclaredEndOfCyclePushes
        summary[c] = (summary[c] ? 0) + 1
      parts = []
      for own k, v of summary
        parts.push k + " x" + v
      console.log "UNDECLARED-EOC frame=" + WorldWdgt.frameCount + " total=" + @_undeclaredEndOfCyclePushes.length + " :: " + parts.join(", ")
    # reset the per-frame accumulator at the end-of-cycle flush ONLY -- a mid-frame self-settle (which calls
    # recalculateLayouts with @_inLayoutMutation set) must not drop off-settle pushes recorded before it.
    @_undeclaredEndOfCyclePushes = undefined unless @_inLayoutMutation
    # re-entrancy guard: recalculateLayouts must not run inside itself. This fires if a
    # public geometry setter (which flushes via recalculateLayouts) is reached from a
    # layout pass (_reLayout/_positionAndResizeChildren). Internal layout must use the immediate (geometry)
    # mutators, never the public deferred API. (prototype 2026-06-19)
    if @_recalculatingLayouts
      throw new Error "Fizzygum: re-entrant recalculateLayouts() -- a public geometry setter was called from within a layout pass. Internal layout code must use the immediate (geometry) mutators, not the public deferred API."
    @_recalculatingLayouts = true
    try
      @_recalculateLayoutsBody()
    finally
      @_recalculatingLayouts = false
      # (ordered down-walk Stage B1) the hasDirtyDescendant flags mirror the work-list: once the
      # drain has emptied it no widget is pending, so no flag may survive (a stale true would
      # weaken the reachability audit and, come Stage B2, cause spurious walk visits). Clear
      # exactly the flagged set. If the body THREW with work still pending (RECALC_NONCONVERGENCE)
      # keep the flags — those widgets still need to be reachable on the next flush. This clearing
      # also covers resetWorld: the teardown rides a settle, so its flush lands here with the
      # work-list drained, leaving both structures empty for the next test (no state leak).
      if @widgetsThatMaybeChangedLayout.length == 0
        for w in @_widgetsFlaggedHasDirtyDescendant
          w.hasDirtyDescendant = false
        @_widgetsFlaggedHasDirtyDescendant = []

  # (ordered down-walk Stage B2, 2026-07-16 -- docs/archive/ordered-downwalk-stage-b-plan.md §4-B2) The
  # settle is now a ROOT-DOWN VISITATION of the dirty tree. The old shape (pop the work-list from
  # the tail; on an invalid entry CLIMB to the top-most invalid ancestor; _reLayout that chain-top)
  # discovered dirt bottom-up; this shape discovers it top-down along the hasDirtyDescendant flags
  # the Stage-B1 scaffold maintains (audit-verified suite-wide before any behaviour read them).
  # Equivalence to the old drain, piece by piece:
  #   - CLIMB-TO-TOPMOST-INVALID (Opt-2, 2026-07-02: a freefloating widget may be sized FROM its
  #     parent, so a dirty parent must lay out FIRST or the child settles against a stale size and
  #     again after -- a wasted double-lay): subsumed by parent-first order. The walk arrives from
  #     above, so a dirty ancestor is ALWAYS re-laid before its dirty descendants; the chain-top
  #     concept disappears because every visit IS its own chain-top.
  #   - POP-VALID: the walk re-lays only layoutIsValid==false nodes, so a child healed by its
  #     parent's arrange is skipped exactly like the old lazy tail-pop; the work-list sweep below
  #     drops the settled entries each round.
  #   - PROCESSING ORDER across disjoint subtrees changes (old: work-list LIFO; new: tree order,
  #     roots in work-list encounter order) -- byte-exact because the settled layout is an
  #     order-independent fixpoint (verified: reversing the loop's processing order was 165/165 at
  #     dpr1/dpr2/webkit), re-verified for this rewrite by the per-test re-laid-SET trace
  #     (relayset-prelude/diff, union identical over the full suite) plus the full §5 protocol.
  #   - The WORK-LIST stays -- deliberately, and not only as a trace: it is the enqueue-dedup
  #     structure (__markForRelayout's layoutIsValid flip) AND the loop-termination oracle. The
  #     flags STEER the descent; the work-list decides when the flush is done. A mid-walk enqueue
  #     (the settle-time re-fit's in-pass arm, the caret scroll-follow) lands in the work-list and
  #     re-flags its chain, and the next round's walk picks it up.
  #   - The settle-time up-edge (_reFitMyTrackingContainerAfterSettle) and the per-_reLayout error
  #     containment move unchanged into __downWalkLayout, applied at every walk re-lay exactly as
  #     they applied at every chain-top.
  _recalculateLayoutsBody: ->

    # DEFENSIVE ASSERTION -- NOT a convergence budget. (proper-layouts Stage 6, 2026-07-01; counter
    # moved to the walk's re-lay site in Stage B2, same RECALC_NONCONVERGENCE token.) Instrumenting
    # the FULL suite (dpr1 + dpr2) measured a peak of 428 re-lays in one flush -- 427 DISTINCT
    # widgets with ZERO re-visits (one big tree settling at once); the only residual iteration is a
    # small, bounded size-negotiation cycle for constrained NESTED containers (measured peak: 10
    # re-visits, down to 2 after the up-edge's no-op skip). The old recalcIterationsCap masked a
    # possible non-convergence SILENTLY (log + abandon the work-list + ship a broken layout); that
    # suppression is DELETED. What remains is a pure never-fire assertion at a generous-but-finite
    # bound: if the settle ever fails to TERMINATE it is a BUG (a real non-terminating layout
    # cycle), so THROW loudly rather than freeze the tab or silently ship broken layout.
    # (Per-_reLayout errors are a different path, handled inside __downWalkLayout.)
    @_downWalkRelaidCount = 0

    until @widgetsThatMaybeChangedLayout.length == 0
      # SWEEP the settled entries (the old loop's lazy tail-pop, as a whole-list filter): what
      # remains is the still-invalid set this round must reach. NB the REPLACED array: mid-walk
      # enqueues push through world.widgetsThatMaybeChangedLayout (a property read at push time),
      # so they land on the new array and are seen by the next round's sweep.
      stillInvalid = []
      for w in @widgetsThatMaybeChangedLayout
        # a DESTROYED entry has no layout to settle -- and laying out a corpse re-marks
        # paint damage on it (a teardown-then-flush would zombie the damage queues with
        # the widgets the teardown just destroyed)
        stillInvalid.push w unless w.layoutIsValid or w.destroyed
      @widgetsThatMaybeChangedLayout = stillInvalid
      break if stillInvalid.length == 0

      # DERIVE the dirtiness flags + the dirty roots FRESH from the still-invalid entries, by
      # climbing the CURRENT parent pointers -- flush-time truth. This is deliberately NOT
      # incremental enqueue-time bookkeeping (the first Stage-B2 cut maintained the flags in
      # __markForRelayout/__add and CLEARED them during the descent -- which broke the flagging
      # atom's stop-at-first-flagged short-circuit for mid-walk enqueues: propagation stopped at a
      # stale flag below the walk's cleared frontier, the upper chain stayed unflagged, the next
      # round could not descend to the entry, and the settle threw with the work-list non-empty).
      # Deriving per round flags every still-invalid entry INCLUSIVE (the atom starts at self), so
      # the walk below reaches every entry whose ancestor chain is traversable through the children
      # arrays -- the parent-pointer-only attachments it cannot see are settled by the FALLBACK
      # after the walks (see below). Parent pointers are STABLE
      # inside a flush (public add/remove self-settles and would throw on re-entry; the FLOWRULE
      # throw bars mid-pass scheduling), so flags accumulated across rounds stay correct and the
      # stop-at-first-flagged short-circuit is sound; recalculateLayouts' finally clears the whole
      # flagged set once the flush completes. Roots (the world, the hand, orphan roots -- an
      # off-world under-construction subtree settles here too, cf. PanelWdgt._reactToChildRemoved)
      # are collected in work-list encounter order, so root order is deterministic.
      dirtyRoots = []
      for w in stillInvalid
        w.__flagHasDirtyDescendantUpwards()
        r = w
        r = r.parent while r.parent?
        dirtyRoots.push r if dirtyRoots.indexOf(r) == -1

      progressAtRoundStart = @_downWalkRelaidCount

      for r in dirtyRoots
        @__downWalkLayout r

      # FALLBACK — the PARENT-POINTER-ONLY attachment class (found the hard way, 2026-07-16: the
      # first derive-per-round cut spun at 100% CPU during the harness boot). The derivation climbs
      # PARENT pointers, but the walk descends CHILDREN arrays — a widget attached by parent
      # pointer WITHOUT membership in its parent's children (the bin is the documented
      # example: "not attached to the world tree so it's not in the children") is flaggable but
      # structurally unreachable from any root, so a walk-only round made zero progress and the
      # outer until-loop never terminated. Any entry still invalid after the walks gets EXACTLY
      # the old drain's treatment — climb to the top-most contiguously-invalid ancestor, settle
      # that chain-top — which never touches children arrays, so it reaches this class the same
      # way the old engine always did. Set-equivalence is preserved by construction: this IS the
      # old per-entry processing, applied to the (normally tiny) remainder the walk cannot see.
      for w in stillInvalid
        continue if w.layoutIsValid
        chainTop = w
        while chainTop.parent? and not chainTop.parent.layoutIsValid
          chainTop = chainTop.parent
        @__reLayoutOneSettleNode chainTop

      # STUCK TRIPWIRE, reinstated. The first cut removed it as "structurally impossible" and the
      # impossibility proof was falsified within the hour (the parent-pointer-only class above) —
      # the failure mode without it is a SILENT infinite spin pegging the tab, strictly worse than
      # a loud throw. With the fallback in place a zero-progress round should be truly unreachable
      # (every still-invalid entry is either walked or fallback-settled); if it ever fires anyway,
      # console.error the greppable token (wired into the headless runners' fail-gate like
      # NON_INTEGER_GEOMETRY) and throw out of the flush.
      if @_downWalkRelaidCount == progressAtRoundStart
        console.error "DOWNWALK_UNREACHABLE_CHAINTOP: settle round made no progress with " + stillInvalid.length + " still-invalid widget(s); first: " + (stillInvalid[0]?.constructor?.name) + " spec=" + (stillInvalid[0]?.layoutSpec)
        throw new Error "Fizzygum: DOWNWALK_UNREACHABLE_CHAINTOP -- settle round made no progress with " + stillInvalid.length + " still-invalid widget(s); first: " + (stillInvalid[0]?.constructor?.name)
    return

  # (ordered down-walk Stage B2) ONE parent-first visitation of the dirty tree below (and including)
  # `node`. Re-lays exactly the layoutIsValid==false nodes it reaches; descends ONLY along the
  # Stage-B1 dirtiness flags, so a clean subtree costs nothing.
  __downWalkLayout: (node) ->
    unless node.layoutIsValid
      @__reLayoutOneSettleNode node
    # descend along the FLAGS ONLY -- the walk must not clear them (the per-round derivation in
    # _recalculateLayoutsBody owns their lifecycle; clearing mid-descent is exactly what broke the
    # first cut, see the derivation comment). Flags mark the still-invalid work-list entries and
    # their ancestor chains INCLUSIVE, so flags-only descent reaches every entry whose chain is
    # traversable through the children arrays; the parent-pointer-only attachments (a parent set
    # without children membership, e.g. the bin) are unreachable HERE by construction and are
    # settled by the fallback in _recalculateLayoutsBody instead. Deliberately NOT
    # `child.layoutIsValid == false` as a descent arm: a stale-invalid widget with NO work-list
    # entry (e.g. copied dirt -- a duplicate can clone layoutIsValid own-props) was invisible to
    # the old engine unless an entry's climb passed through it, and the walk must not start healing
    # a population the old engine ignored while the acceptance bar is set-equivalence.
    for child in node.children
      if child.hasDirtyDescendant
        @__downWalkLayout child
    return

  # (ordered down-walk Stage B2) settle ONE node: the old drain's per-chain-top processing --
  # snapshot frame, _reLayout, settle-time up-edge when the frame changed, minimal error
  # containment -- shared verbatim by the walk and by the unreachable-entry fallback.
  __reLayoutOneSettleNode: (node) ->
    try
      # (proper-layouts §4.3, 2026-07-01) ORDERED settle-time re-fit: now that this widget has
      # SETTLED, re-fit its size-tracking container so the container tracks the just-settled
      # geometry. This REPLACES the deleted mutation-time geometry seam
      # (_announceGeometryChangeToContainer): because the content is fully settled when this
      # fires, the container reads its FINAL geometry and re-fits correctly in one visit -- no
      # per-mutation notification, and no convergence iteration from a container reading
      # half-applied content. The method gates on the parent being a tracking container
      # (_reLayoutChildren?), so a non-tracking parent is a no-op.
      #
      # (proper-layouts Stage 6, 2026-07-01) NO-OP EARLY RETURN: only re-fit the container if this
      # _reLayout actually CHANGED my frame (position OR extent). A size-tracking container fits
      # itself to its content's FRAME, so if my frame is identical before and after I settle,
      # re-fitting the container is provably a no-op. Sound either way I am sized: if I am
      # fit-to-content my frame moves WITH my content, so a real content change IS caught here; if
      # I am fixed-size my container fits my fixed frame regardless of my subtree -- so an
      # unchanged frame always means my container's fit is unchanged. Measured byte-exact across
      # dpr1 / dpr2 / webkit + determinism torture when introduced; carried unchanged into the
      # down-walk (applied at every walk re-lay exactly as at every old chain-top).
      # (ordered down-walk Stage B3 — THE PAYOFF, docs/archive/ordered-downwalk-stage-b-plan.md §4-B3) the
      # ENGINE now guarantees what the per-class INV-2 idiom could not: a child-placing composite
      # whose frame my arrange is about to move or resize gets its OWN layout re-run afterwards.
      # This kills the bypass staleness class — VerticalStackPanelWdgt (and any arrange)
      # sizes a non-tracking child via the override-BYPASSING _applyExtentBase/_applyMoveToBase and
      # never calls the child's _reLayout: a leaf heals (the base fires _reLayoutSelf) but a
      # composite that places ITS children inside _reLayout stayed stale — the census's shipping
      # BinWdgt instance (viewport ~100px short after the bin opens). The predicate is
      # PER-CHILD frame delta (not my own frame delta, which the plan sketched): a divider drag
      # redistributes children while MY frame stays put, so gating on me would miss it. Snapshot
      # EVERY valid child (§9-N4, 2026-07-16: the _placesChildrenInLayout capability gate is GONE —
      # the engine guarantees every arrange-moved child a re-lay, no per-class declaration; a moved
      # LEAF's re-visit is a no-op via the equal-extent top guard, measured ~27 extra idempotent
      # re-lays per test, plan §11); skip already-invalid ones (the walk/fallback settles them
      # this flush anyway). Re-laying a CONVERGED child is idempotent (the order-independent
      # fixpoint), so extra visits are pixel-neutral; a STALE one heals — the deliberate behaviour
      # fix. Runs through this same method recursively, so heals cascade, the up-edge applies
      # (no-op unless the child's OWN _reLayout moved its frame — an arrange-placed child re-applies
      # the same frame), the error containment applies, and the RECALC counter bounds it.
      watchedChildren = undefined
      for c in node.children when c.layoutIsValid
        (watchedChildren ?= []).push [c, c.left(), c.top(), c.width(), c.height()]
      preL = node.left(); preT = node.top(); preW = node.width(); preH = node.height()
      node._reLayout()
      myFrameChanged = node.left() != preL or node.top() != preT or node.width() != preW or node.height() != preH
      node._reFitMyTrackingContainerAfterSettle() if myFrameChanged
      if watchedChildren?
        for [c, cLeft, cTop, cWidth, cHeight] in watchedChildren
          if c.layoutIsValid and (c.left() != cLeft or c.top() != cTop or c.width() != cWidth or c.height() != cHeight)
            @__reLayoutOneSettleNode c
    catch err
      # We are INSIDE the recalculateLayouts flush here (_recalculatingLayouts is true), so this
      # block must do the ABSOLUTE MINIMUM and stay strictly non-flushing / non-invalidating:
      #   - createErrorConsole uses public, self-flushing setters -> it would re-enter
      #     recalculateLayouts and throw BEFORE @errorConsole is assigned (masking the real error);
      #   - even _softResetWorld is unsafe here (its hand.drop -> target.add can flush too).
      # And because the throwing _reLayout() never reached its trailing _markLayoutAsFixed(),
      # node is still layoutIsValid==false, so unless we settle it here the outer until-loop
      # would spin (and the stuck-detection would fire on a genuine _reLayout bug's error). So:
      # settle + ban the offender (both layout-clean), then defer the softReset + reporting to the
      # next cycle's drain, outside the flush. (task #18)
      node._markLayoutAsFixed()   # it threw before doing this itself; do it now so the settle converges
      node.__hide()          # ban from paint -- silent: clears caches only, no _invalidateLayout/flush
      @layoutErrorsToReport.push err
    # the never-fire termination assert (see _recalculateLayoutsBody's header comment). Counted
    # OUTSIDE the try: this throw must propagate out of the flush, never be swallowed by the
    # per-_reLayout containment above.
    @_downWalkRelaidCount++
    if @_downWalkRelaidCount > 100000
      console.error "RECALC_NONCONVERGENCE: recalculateLayouts did not terminate after 100000 re-lays. Last widget: " + (node.constructor?.name) + " spec=" + node.layoutSpec
      throw new Error "Fizzygum: RECALC_NONCONVERGENCE -- recalculateLayouts did not terminate after 100000 re-lays (a non-terminating layout cycle). Last widget: " + (node.constructor?.name)


  clearPaintBoundsMaybeChangedFlags: ->
    for m in @widgetsWithMaybeChangedPaintBounds
      m.paintBoundsMaybeChanged = false

  clearFullPaintBoundsMaybeChangedFlags: ->
    for m in @widgetsWithMaybeChangedFullPaintBounds
      m.fullPaintBoundsMaybeChanged = false

  _repaintDamagedRects: ->
    @damageRects = []
    @duplicatedDamageRectsTracker = {}
    @numberOfDuplicatedDamageRects = 0

    @_fleshOutFullDamage()
    @_fleshOutDamage()
    @_rectAlreadyIncludedInParentDamagedWidget()
    @_cleanupSrcAndDestRectsOfWidgets()

    @clearPaintBoundsMaybeChangedFlags()
    @clearFullPaintBoundsMaybeChangedFlags()

    @widgetsWithMaybeChangedPaintBounds = []
    @widgetsWithMaybeChangedFullPaintBounds = []

    # each damage rectangle requires traversing the scenegraph to
    # redraw what's overlapping it. Not all Widgets are traversed
    # in particular the following can stop the recursion:
    #  - invisible Widgets
    #  - PanelWdgts that don't overlap the damage rectangle
    # Since potentially there is a lot of traversal ongoing for
    # each damage rectangle, one might want to consolidate overlapping
    # and nearby rectangles.

    @healingRectanglesPhase = true

    @errorsWhileRepainting = []

    # the phase flag clears in `finally`: the per-rect catch below contains widget paint
    # errors, but a throw from the whole-screen error recovery (or any other escape) would
    # otherwise leave the flag stuck true across frames
    try
      @damageRects.forEach (rect) =>
        if !rect?
          return
        if rect.isNotEmpty()
          try
            # public-call-sanctioned: fullPaintIntoAreaOrBlitFromBackBuffer is the polymorphic
            # paint recursion (parent paints child through it, tree-wide) — it stays public;
            # the paint executor here is simply its top-level entry.
            @fullPaintIntoAreaOrBlitFromBackBuffer @worldCanvasContext, rect
          catch err
            @resetWorldCanvasContext()
            @_queueErrorForLaterReporting err
            @_hideOffendingWidget()
            @_softResetWorld()

      # IF we got errors while repainting, the
      # screen might be in a bad state (because everything in front of the
      # "bad" widget is not repainted since the offending widget has
      # thrown, so nothing in front of it could be painted properly)
      # SO do COMPLETE repaints of the screen and hide
      # further offending widgets until there are no more errors
      # (i.e. the offending widgets are progressively hidden so eventually
      # we should repaint the whole screen without errors, hopefully)
      if @errorsWhileRepainting.length != 0
        @_findOutAllOtherOffendingWidgetsAndPaintWholeScreen()

      if @showRedraws
        @_showDamageRects @worldCanvasContext

      # Under the SWCanvas backend, everything above painted into the software
      # render surface; lift it onto the DOM <canvas id="world"> so it becomes
      # visible. Only when something was actually painted this cycle.
      if @domBlitContext? and @damageRects.length != 0
        @blitRenderCanvasToDOM()

      @_resetDataStructuresForDamageRects()
    finally
      @healingRectanglesPhase = false

    # DEBUG (auditPaintTimeLayoutScheduling, default off): report any layout scheduled DURING this frame's paint
    # pass, then reset for the next frame. A non-empty log => paint was NOT read-only (a widget scheduled layout
    # while being painted -- a render/layout boundary crossing). Recorded in Widget._invalidateLayout.
    if @auditPaintTimeLayoutScheduling and @_paintTimeLayoutSchedules?.length
      summary = {}
      for c in @_paintTimeLayoutSchedules
        summary[c] = (summary[c] ? 0) + 1
      parts = []
      for own k, v of summary
        parts.push k + " x" + v
      console.log "PAINT-SCHEDULES frame=" + WorldWdgt.frameCount + " total=" + @_paintTimeLayoutSchedules.length + " :: " + parts.join(", ")
    @_paintTimeLayoutSchedules = undefined

    # tripwire for the one corruption the _repaintAsOneUnit construct cannot
    # prevent (direct field tampering / a future bug): a nonzero depth at flush
    # means damage recording is silently OFF — report on the fail-gated token
    # channel and HEAL, so a live world degrades loudly-but-visibly instead of
    # going dark
    if @_damageSuppressionDepth isnt 0
      console.error "DAMAGE_SUPPRESSION_UNBALANCED depth=" + @_damageSuppressionDepth
      @_damageSuppressionDepth = 0

  # SWCanvas backend only: copy the whole software render surface onto the DOM
  # <canvas id="world"> so the frame becomes visible. (Per-damage-rect partial
  # blits via the putImageData dirty-rect overload are a future optimization.)
  blitRenderCanvasToDOM: ->
    w = @worldRenderCanvas.width
    h = @worldRenderCanvas.height
    return if w < 1 or h < 1
    # @worldRenderCanvas.data is the SWCanvas surface's Uint8ClampedArray
    # (non-premultiplied RGBA8); wrap it as a real ImageData with no copy.
    @domBlitContext.putImageData (new ImageData @worldRenderCanvas.data, w, h), 0, 0

  # SWCanvas backend only: keep the software render canvas the same physical size
  # as the DOM world canvas after a resize. Setting the size recreates the
  # SWCanvas surface (which resets textPixelDensity), so re-apply it.
  _syncRenderCanvasToWorldCanvas: ->
    return unless @worldRenderCanvas? and @worldRenderCanvas isnt @worldCanvas
    @worldRenderCanvas.width = @worldCanvas.width
    @worldRenderCanvas.height = @worldCanvas.height
    @worldCanvasContext = @worldRenderCanvas.getContext "2d"
    @worldCanvasContext.textPixelDensity = ceilPixelRatio if @worldCanvasContext.textPixelDensity?

  # True while the screen may still be showing SWCanvas placeholder boxes instead of real
  # glyphs — either an atlas is still loading, or one has landed and its placeholder-clearing
  # repaint has not been applied yet (SWCanvasElement-extensions). Both states are covered
  # deliberately: the half-warm one renders STABLY (the boxes sit in a cached back buffer that
  # re-blits identically), so a capture that merely waits for frame-to-frame convergence cannot
  # tell it from a finished render. Every pixel-reading gate waits on this. Always false under
  # the native backend.
  anyTextDirty: ->
    if window.swCanvasAnyTextDirty?
      window.swCanvasAnyTextDirty()
    else
      false

  _findOutAllOtherOffendingWidgetsAndPaintWholeScreen: ->
    # we keep repainting the whole screen until there are no
    # errors.
    # Why do we need multiple repaints and not just one?
    # Because remember that when a widget throws an error while
    # repainting, it bubble all the way up and stops any
    # further repainting of the other widgets, potentially
    # preventing the finding of errors in the other
    # widgets. Hence, we need to keep repainting until
    # there are no errors.

    currentErrorsCount = @errorsWhileRepainting.length
    previousErrorsCount = undefined
    numberOfTotalRepaints = 0
    until previousErrorsCount == currentErrorsCount
      numberOfTotalRepaints++
      try
        # public-call-sanctioned: fullPaintIntoAreaOrBlitFromBackBuffer is the public paint-pipeline
        # verb (externally driven); this error-recovery loop consciously re-drives the world repaint.
        @fullPaintIntoAreaOrBlitFromBackBuffer @worldCanvasContext, @bounds
      catch err
        @resetWorldCanvasContext()
        @_queueErrorForLaterReporting err
        @_hideOffendingWidget()
        @_softResetWorld()

      previousErrorsCount = currentErrorsCount
      currentErrorsCount = @errorsWhileRepainting.length


  resetWorldCanvasContext: ->
    # when an error is thrown while painting, it's
    # possible that we are left with a context in a strange
    # mixed state, so try to bring it back to
    # normality as much as possible
    # We are doing this for "cleanliness" of the context
    # state, not because we care of the drawing being
    # perfect (we are eventually going to repaint the
    # whole screen without the offending widgets)
    @worldCanvasContext.closePath()
    @worldCanvasContext.resetTransform?()
    for j in [1...2000]
      @worldCanvasContext.restore()

  _queueErrorForLaterReporting: (err) ->
    # now record the error so we can report it in the
    # next cycle, and add the offending widget to a
    # "banned" list
    @errorsWhileRepainting.push err
    if !@widgetsGivingErrorWhileRepainting.includes @paintingWidget
      @widgetsGivingErrorWhileRepainting.push @paintingWidget
      @paintingWidget.__hide()

  _hideOffendingWidget: ->
    if !@widgetsGivingErrorWhileRepainting.includes @paintingWidget
      @widgetsGivingErrorWhileRepainting.push @paintingWidget
      @paintingWidget.__hide()

  _resetDataStructuresForDamageRects: ->
    @damageRects = []
    @duplicatedDamageRectsTracker = {}
    @numberOfDuplicatedDamageRects = 0

  
  addHighlightingWidgets: ->
    @currentHighlightingWidgets.forEach (eachHighlightingWidget) =>
      target = eachHighlightingWidget.wdgtThisWdgtIsHighlighting
      if @widgetsToBeHighlighted.has target
        if target.hasMaybeChangedPaintBounds()
          # R2 (§6 affine): keep the highlight parented in the TARGET'S PLANE — inside its innermost
          # MAPPING ancestor (a non-identity island; a scrolled pane's viewport once the paint-time-
          # scroll model is live) — so it composites through the mapping (rotates/translates + clips
          # with the target for free, §4.6). Re-derived each update so a mid-hover rotate/unwrap
          # re-homes it; a target off any mapped plane resolves to the world ⇒ byte-identical dormant.
          # add() re-parents and (highlighter having no intrinsic layoutSpec) keeps it free-floating;
          # the common static case is already home, so this only fires on a membership transition.
          # ⚠ for a VIEWPORT root, add() redirects into its contents, so this parent-equality check
          # must compare against the redirect target when the scroll arm gains live providers
          # (paint-time-scroll-translation plan Phase 2c) — else it re-adds every cycle.
          desiredParent = target._enclosingMappedPlaneRoot() ? @
          desiredParent.add eachHighlightingWidget  if eachHighlightingWidget.parent != desiredParent
          eachHighlightingWidget._applyBounds target.clippedThroughBounds()
      else
        @currentHighlightingWidgets.delete eachHighlightingWidget
        @widgetsBeingHighlighted.delete target
        eachHighlightingWidget.wdgtThisWdgtIsHighlighting = undefined
        eachHighlightingWidget.fullDestroy()

    @widgetsToBeHighlighted.forEach (styleDescriptor, eachWidgetNeedingHighlight) =>
      unless @widgetsBeingHighlighted.has eachWidgetNeedingHighlight
        hM = new HighlighterWdgt
        # R2 (§6 affine): parent the highlight into the target's innermost MAPPING ancestor (island,
        # or a scrolled pane's viewport — whose add() redirects onto the scrolled plane) so it
        # warps/translates + clips with the target; the world when there is none (dormant
        # ⇒ byte-identical to the prior @add hM).
        (eachWidgetNeedingHighlight._enclosingMappedPlaneRoot() ? @).add hM
        hM.wdgtThisWdgtIsHighlighting = eachWidgetNeedingHighlight
        hM._applyBounds eachWidgetNeedingHighlight.clippedThroughBounds()
        hM.applyHighlightStyle styleDescriptor
        @currentHighlightingWidgets.add hM
        @widgetsBeingHighlighted.add eachWidgetNeedingHighlight

  # Reconcile the drag-embed AFFORDANCE overlays (charging ring / armed label / lock badge) to the
  # hand's declarative *Declared slots — created/moved/destroyed once per cycle just before paint, the
  # same declare-and-reconcile shape as addHighlightingWidgets. All are EPHEMERALS (isEphemeral ->
  # hit-test-excluded, shadow-free, snapshot-excluded). docs/specs/drag-embed-interaction-spec.md §11-12.
  addDragAffordanceWidgets: ->
    # charging ring — the DragChargingRingWdgt computes its own fill from the declared linger origin
    if @dragEmbedChargeRingDeclared?
      unless @dragEmbedChargeRingWdgt?
        @dragEmbedChargeRingWdgt = new DragChargingRingWdgt
        @add @dragEmbedChargeRingWdgt
      @dragEmbedChargeRingWdgt.updateChargeDeclaration @dragEmbedChargeRingDeclared
    else if @dragEmbedChargeRingWdgt?
      @dragEmbedChargeRingWdgt.fullDestroy()
      @dragEmbedChargeRingWdgt = undefined

    # armed label — a StringWdgt overlay near the cursor
    if @dragEmbedLabelDeclared?
      if @dragEmbedLabelWdgt? and @dragEmbedLabelWdgt.text isnt @dragEmbedLabelDeclared.text
        @dragEmbedLabelWdgt.fullDestroy()
        @dragEmbedLabelWdgt = undefined
      unless @dragEmbedLabelWdgt?
        @dragEmbedLabelWdgt = new StringWdgt @dragEmbedLabelDeclared.text
        @dragEmbedLabelWdgt._ephemeralOverlay = true
        @add @dragEmbedLabelWdgt
        @dragEmbedLabelWdgt.setColor Color.create(40, 40, 40, 1)
        @dragEmbedLabelWdgt.setWidth 320   # roomy enough for the full text (else a StringWdgt crops it)
      @dragEmbedLabelWdgt._applyMoveTo @dragEmbedLabelDeclared.point
    else if @dragEmbedLabelWdgt?
      @dragEmbedLabelWdgt.fullDestroy()
      @dragEmbedLabelWdgt = undefined

    # lock badge — a small StringWdgt at the reluctant (view-mode) target's title-bar right
    if @dragEmbedLockBadgeDeclared?
      unless @dragEmbedLockBadgeWdgt?
        @dragEmbedLockBadgeWdgt = new StringWdgt "view-only"
        @dragEmbedLockBadgeWdgt._ephemeralOverlay = true
        @add @dragEmbedLockBadgeWdgt
        @dragEmbedLockBadgeWdgt.setColor Color.create(120, 120, 120, 1)
      # the badge is a world child, so anchor it to the target's SCREEN footprint — the target can sit
      # inside a rotated/scaled island, where the plane-local box is the wrong plane (§7.11 mapping;
      # off any island mapRectToScreen returns the box unchanged)
      badgeTarget = @dragEmbedLockBadgeDeclared.target
      box = badgeTarget.mapRectToScreen badgeTarget.clippedThroughBounds()
      @dragEmbedLockBadgeWdgt._applyMoveTo new Point(box.right() - 70, box.top() + 4)
    else if @dragEmbedLockBadgeWdgt?
      @dragEmbedLockBadgeWdgt.fullDestroy()
      @dragEmbedLockBadgeWdgt = undefined

  # The widget the editor-focus indicator frames (§5.D D-3, decisions D18/D21), or undefined. editorFocusWdgt
  # is the sticky focus POINTER (the last content clicked/dropped); this narrows it to a SELECTED
  # op-target within an active editing context, so the indicator frames "this is what an op will act on":
  #   TEXT      — a caret is up editing exactly this focus widget. They coincide: the click that sets
  #               editorFocusWdgt = w dispatches to w, whose text handler calls world.edit @ (= w).
  #   CITIZEN   — a pencil-capable widget (providesAmenitiesForEditing) with the pencil engaged
  #               (dragsDropsAndEditingEnabled). Fires when the focus leaf IS the panel — a text leaf
  #               inside it has no amenities, so it goes through the caret branch instead.
  #   SELECTED  — (D21) a widget SELECTED inside an editable container that is in edit mode, e.g. a clock
  #     ITEM      or image dropped into a document: it has no "edit mode" of its own, but ops (alignment,
  #               …) target it, so it shows the same outline. Its nearest editing-amenities ANCESTOR
  #               (excluding the world) must be in edit mode — a bare selection on the desktop is NOT
  #               framed (the world is an editable panel but is not an "editor" holding selected items).
  # Stale-pointer guarded (belt to D2b's destroy-time clear): the target must still be attached here.
  _widgetBeingEdited: ->
    focus = @editorFocusWdgt
    return undefined unless focus?
    # Never frame the desktop itself: a click on empty desktop sets editorFocusWdgt = world (the world
    # is not editor-focus-excluded), and the world is a PanelWdgt with editing enabled, so the citizen
    # branch below would otherwise outline the WHOLE screen. The world is never a "widget being edited".
    return undefined if focus is @
    return undefined unless focus.root() is @
    # A transform ISLAND (the sugar wrapper setRotationDegrees / setScaleFactor materialises, or an explicit
    # TransformFrameWdgt) is structural chrome around content -- never editor content ITSELF. A MOVE of a
    # tilted widget makes the island the focus (a click INTO the content focuses the content directly), and
    # the island is a PanelWdgt with editing enabled, so the citizen branch below would frame the ISLAND --
    # drawing an AXIS-ALIGNED box around the island's own (un-rotated) bounds (the rotation lives in its
    # transformSpec, not its @bounds). Resolve to the wrapped CONTENT instead: it draws its frame WARPED
    # inside the island buffer, so a tilted editor is framed exactly like the non-tilted one. Loop for
    # nested islands (rotate-then-scale can wrap twice); an empty wrapper resolves to undefined.
    while focus.resolvesEditorSelectionToContent?()
      focus = focus.childrenNotHandlesNorCarets()?[0]
      return undefined unless focus?
    # A menu/list ROW (MenuItemWdgt) is the selectable UNIT, and it is FULL-WIDTH in its list; but a click
    # lands on its tight LABEL child (the deepest widget). Resolve the label up to the row so the selection
    # frame hugs the whole entry, not the label's text bounds (owner: a tight-text frame is visual noise).
    if focus.parent?.absorbsDescendantEditorSelection?()
      focus = focus.parent
    if @caret? and @caret.target is focus
      return focus
    if focus.providesAmenitiesForEditing and focus.dragsDropsAndEditingEnabled
      return focus
    # SELECTED ITEM (D21): frame focus when it sits inside an EDITABLE container that is in edit mode.
    # Walk to the nearest container that has an OPINION on editing amenities, stopping BEFORE the world
    # (a desktop selection is not "in an editor"):
    #   amenities === true  → frame focus, but only if the pencil is engaged (view mode ⇒ no indicator).
    #   amenities === false → STOP, no frame: a container that EXPLICITLY opts out manages its own
    #                         selection UI (a spreadsheet's cell grid draws its own cell highlight), so a
    #                         second outline would just be clutter.
    #   undefined (no opinion, the Widget default) → keep walking up.
    container = focus.parent
    while container? and container isnt @
      if container.providesAmenitiesForEditing is true
        return (if container.dragsDropsAndEditingEnabled then focus else undefined)
      if container.providesAmenitiesForEditing is false
        return undefined
      container = container.parent
    undefined

  # Recompute, once per cycle just before paint, which widget is generically SELECTED for editing
  # (_widgetBeingEdited, §5.D D-3/D21) and cache it for the per-widget paint-time selection overlay
  # (Widget._drawSelectionOverlay). On a CHANGE (retarget, or on/off) invalidate BOTH the old and new
  # widgets so their paint (hence the after-subtree overlay draw) re-runs and the damage-rect repaint
  # clears the old outline / draws the new one -- the selection-change invalidation the old HighlighterWdgt
  # used to get from its own _changed()/fullDestroy(). A MOVING target needs no handling here: moving a widget already
  # invalidates it, so its overlay follows for free (unlike the old reconciler, which had to re-bounds).
  # PULL, not push (D-3-iii): the target is recomputed here, never wired into the focus-set sites. Same
  # doOneCycle slot the old addEditorFocusIndicatorWidget reconciler ran in.
  _updateEditorSelectionOverlay: ->
    target = @_widgetBeingEdited()
    return if target is @_editorSelectedWidget
    previous = @_editorSelectedWidget
    @_editorSelectedWidget = target
    # only invalidate a still-attached previous widget: a destroyed one already invalidated its region on
    # fullDestroy, and _changed() on a detached widget can't reach the damage-rect list anyway.
    # cross-invalidation-sanctioned: selection-overlay reconciler — PULL model (D-3-iii), no
    # method ever runs on the old/new target in which it could self-invalidate
    previous._changed() if previous? and previous.root() is @
    # cross-invalidation-sanctioned: selection-overlay reconciler (see above)
    target?._changed()

  # Is w the widget generically selected for editing this cycle? PUBLIC query (called cross-object from
  # any widget's Widget._showsSelectionOverlay, like the spreadsheet's public isSelectedAddress): an O(1)
  # identity check against the once-per-cycle cache, so the per-widget paint never walks the tree (that is
  # _widgetBeingEdited, run once above).
  isEditorSelected: (w) ->
    w is @_editorSelectedWidget


  # The VideoPlayer family is its own part ('video-player'), shipped only with
  # --includeVideoPlayer. createDesktop's auto-launch is guarded, so nothing calls this without
  # the part -- but the guard belongs HERE too, on the method that names the class: a caller's
  # guard is not a property of the callee, and the next caller will not know to repeat it.
  # (buildSystem/check-part-edges.js is what insists.)
  draftRunVideoPlayer: ->
      return unless VideoPlayerWithRecommendationsWdgt?
      videoPlayer = new FrameWdgt new VideoPlayerWithRecommendationsWdgt
      world.add videoPlayer
      videoPlayer.setExtent new Point 934, 896
      # it would be -28 instead of zero here below, but the system doesn't allow
      # to put windows outside of the screen
      videoPlayer.moveTo new Point 174, 0


  _playQueuedEvents: ->
    try

      timeOfCurrentCycleStart = WorldWdgt.dateOfCurrentCycleStart.getTime()

      for event in @inputEventsQueue
        if !event.time? then debugger

        # this happens when you consume synthetic events: you can inject
        # MANY of them across frames (say, a slow drag across the screen),
        # so you want to consume only the ones that pertain to the current
        # frame and return
        if event.time > timeOfCurrentCycleStart
          @inputEventsQueue.removeEventsUpTo event
          return

        # Expose THIS event's own timestamp to its handlers (see
        # WorldWdgt.timeOfEventBeingProcessed): the hand's multi-click recognition
        # reads it to forget a stale double/triple-click candidate on an event-time
        # gap, deterministically — rather than depending on a wall-clock setTimeout.
        WorldWdgt.timeOfEventBeingProcessed = event.time

        # currently not handled: DOM virtual keyboard events
        event.processEvent()

    catch err
      # public-call-sanctioned: createErrorConsole stays public (its body drives the public
      # setExtent/moveTo/add — rule [A] forbids the _-form); this discrete error-recovery path
      # consciously pops it outside any pass.
      @_softResetWorld()
      if !@errorConsole? then @createErrorConsole()
      @errorConsole.contents.showUpWithError err

    @inputEventsQueue.clear()

  # Batch-FETCH pacing: each waitNextTurn parks its resolving function in the
  # framePacedPromises array and each frame we release one, so a sources-batch
  # <script> load gets a whole frame of network time without causing gitter.
  # This paces FETCHES only -- compiling the fetched sources goes through
  # window.SourceCompileScheduler, drained at END of frame under a time budget
  # (the compile station at the tail of doOneCycle).
  # At the moment using an array is overkill because
  # we only load one batch at a time.
  progressFramePacedActions: ->
    if window.framePacedPromises.length > 0
      resolvingFunction = window.framePacedPromises.shift()
      resolvingFunction.call()

  _showErrorsHappenedInRepaintingStepInPreviousCycle: ->
    # public-call-sanctioned: createErrorConsole stays public ([A] forbids the _-form — see its
    # public-api-allowlist entry); this discrete error-report path consciously pops it.
    for eachErr in @errorsWhileRepainting
      if !@errorConsole? then @createErrorConsole()
      @errorConsole.contents.showUpWithError eachErr

  # Drains layout errors stashed during the previous cycle's recalculateLayouts flush (see the
  # catch in _recalculateLayoutsBody). Runs at cycle start, OUTSIDE the flush, so building the
  # error console via the public setters is safe here. (task #18)
  _showLayoutErrorsFromPreviousCycle: ->
    if @layoutErrorsToReport.length == 0 then return
    errorsToShow = @layoutErrorsToReport
    @layoutErrorsToReport = []
    # We run at cycle start, OUTSIDE the recalculateLayouts flush, so the operations that were
    # unsafe in the catch are safe here: _softResetWorld (its hand.drop -> add may flush) and
    # createErrorConsole (public setters). This is the deferred tail of that catch. (task #18)
    @_softResetWorld()
    for eachErr in errorsToShow
      # Loud in the browser console too -- not only in the in-world error console. A _reLayout()
      # that throws is a real bug, and CI / the smoke-apps app-launch gate key off console.error;
      # without this a broken app would no longer freeze (good) but would also go undetected (bad).
      # public-call-sanctioned: createErrorConsole stays public ([A] forbids the _-form); discrete
      # error-report path, consciously popped.
      console.error "LAYOUT_ERROR: a _reLayout() threw during recalculateLayouts: " + (eachErr?.stack ? eachErr)
      if !@errorConsole? then @createErrorConsole()
      @errorConsole.contents.showUpWithError eachErr


  _updateTimeReferences: ->
    WorldWdgt.dateOfCurrentCycleStart = new Date
    if !WorldWdgt.dateOfPreviousCycleStart?
      WorldWdgt.dateOfPreviousCycleStart = new Date WorldWdgt.dateOfCurrentCycleStart.getTime() - 30

    # macro playback pacing — @macroToolkit only exists where the macro family ships
    # (WorldWdgt's constructor builds it behind `if MacroToolkit?`)
    if @macroToolkit?
      if !@macroToolkit.msSinceLastExecutedMacroStep?
        @macroToolkit.msSinceLastExecutedMacroStep = 0
      else
        @macroToolkit.msSinceLastExecutedMacroStep += WorldWdgt.dateOfCurrentCycleStart.getTime() - WorldWdgt.dateOfPreviousCycleStart.getTime()

  doOneCycle: ->
    # for the end-of-frame compile station only -- a local, deliberately not a
    # static: nothing for the resetWorld completeness audit to track
    cycleStartPerfMs = performance.now()

    @_updateTimeReferences()

    @_showErrorsHappenedInRepaintingStepInPreviousCycle()
    @_showLayoutErrorsFromPreviousCycle()

    @macroToolkit?.progressOnMacroSteps()

    @_playQueuedEvents()

    # THE DISSOLUTION SEAM. resetWorld can run from EITHER of the two stations that hand control to
    # user/test code — a queued event's menu action (just above), or the replayed command every
    # SystemTest opens with (just below) — and it DESTROYS this world and hands the page to its
    # replacement. Everything after this point in the cycle belongs to that replacement: this world
    # has no tree, no hand and no listeners left, and the animation pump gives the new world a whole
    # cycle of its own at the next frame, so nothing is skipped, only re-aimed.
    # ⚠ The concrete hazard is not theoretical: the stations below include
    # @hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges(), and dissolution has
    # destroyed the hand and cleared the field.
    # The FRAME still has to close out, though — that bookkeeping is the page's, not this world's.
    return @_closeCycleBookkeepingNoSettle cycleStartPerfMs  if @_dissolved

    # replays test actions at the right time
    if AutomatorPlayer? and Automator.state == Automator.PLAYING
      @automator.player.replayTestCommands()

    # the second half of the dissolution seam above: a reset reached from a replayed test command
    # lands here instead. Same reasoning, same close-out.
    return @_closeCycleBookkeepingNoSettle cycleStartPerfMs  if @_dissolved

    # paces the FETCHING of coffeescript source batches, one per frame (early in
    # the cycle so a fetch gets the whole frame of network time); compiling them
    # happens at the end-of-frame compile station below
    @progressFramePacedActions()
    
    @_runChildrensStepFunction()
    # Drain the dataflow engine's stale pool (spec docs/specs/dataflow-engine-spec.md §4.1). Two
    # deliberately-parallel drain stations sit here: recalculateDataflow settles VALUES,
    # recalculateLayouts settles GEOMETRY. Placed AFTER stepping so this frame's time-source ticks
    # join this frame's batch, and BEFORE recalculateLayouts so sink applications feed this frame's
    # geometry settle and paint (running after layouts would reintroduce the one-cadence-lag bug
    # class). The coupling is ONE-WAY: dataflow may dirty layout; layout must never mark dataflow
    # stale. Dark-cheap — early-returns on an empty stale pool.
    @dataflow.recalculateDataflow()
    # Drain the pending storage sort (bin/shelf eager sorting, StorageSorter):
    # reachability events mark, this station classifies ONCE and moves misplaced
    # residents between the bin and the shelf. AFTER dataflow (unrelated pools),
    # BEFORE recalculateLayouts: a move may dirty real layout when a bin window
    # is open, and that must feed THIS frame's geometry settle (the
    # recalculateDataflow station precedent above). Dark-cheap when nothing is
    # pending.
    @storageSorter.drainPendingSort()
    # Drain the pending fractional-bookkeeping seeds (the __add seed; stretch-fractional
    # auto-bookkeeping arc): bookkeeping-only writes, no geometry mutation, so it sits with
    # the other drain stations BEFORE the geometry settle. Dark-cheap when empty.
    @_drainPendingFractionalBookkeepingSeeds()
    @recalculateLayouts()
    # Hover re-sync AFTER the flush: re-derive the widgets-under-(stationary)-pointer set against the
    # frame's SETTLED geometry -- the same fixed point paint reads -- so hover never lags geometry within
    # a painted frame (pre-swap it read pre-flush bounds, one stage too early; deferred-settle drag geometry
    # was still unapplied). Handlers fired here write paint-layer state and at most SELF-SETTLING
    # mutations (tooltip fullDestroy), so the world is settled again before _repaintDamagedRects; a careless
    # (off-settle) push from a hover handler would be caught by the end-of-cycle capstone gate.
    # See docs/archive/hover-resync-after-flush-plan.md.
    @hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()
    # Re-derive fractional bookkeeping for handle-gestured widgets against the SETTLED
    # geometry (bookkeeping-only writes, no geometry mutation -- see the drain method).
    @_drainPendingFractionalReRecords()

    # (There is no caret scroll-follow step here any more: a caret MOVE settles its scroll-follow IN-PLACE,
    # during the event that moved it -- a discrete click/arrow move self-settles (CaretWdgt.gotoSlot), and a
    # typing/delete/paste advance settles at its editing handler's tail (CaretWdgt._settleScrollFollow).
    # The caret enqueues itself (CaretWdgt._requestScrollFollow) and its _reLayout runs the follow in-line with
    # every other widget, but it is drained by that in-place per-event settle, NOT this end-of-cycle
    # flush (the caret is discrete, not a deferred-settle stream). So the cycle is purely process events fixing layouts
    # step by step -> fix deferred-settle layouts -> re-sync hover to settled geometry -> paint, with NO caret
    # special-case and paint still read-only. A
    # plain wheel/scroll does not move the caret, so the panel still chases it only when the caret MOVES. Cf. the
    # paint-time-caret-resync arc, which first moved this work out of the paint pass into a post-flush step; the
    # Option-C arc folded it into the flush; this arc folds it into the per-event in-place settle.)

    @pinouts?.reconcile()
    @addHighlightingWidgets()
    @_updateEditorSelectionOverlay()
    @addDragAffordanceWidgets()

    # here is where the repainting on screen happens
    @_repaintDamagedRects()

    # END-OF-CYCLE pixel-read seam: deliver pending capture requests (macro screenshots,
    # page-side rig reads) now that this cycle's damage — including any repaint a cache
    # reset requested earlier in the cycle — has been painted. The position IS the contract:
    # delivered one cycle earlier, a read can catch a requested-but-unflushed warm repaint
    # (fuzz-proven at adoption). See MacroToolkit.captureAtEndOfCycle. Guarded like the
    # pump: absent from production.
    @macroToolkit?.drainEndOfCycleCaptures()

    @_closeCycleBookkeepingNoSettle cycleStartPerfMs

  # THE PAGE'S SHARE OF A CYCLE, as opposed to the world's: the source-compile budget drain and the
  # frame clock. It is its own method because a reset DISSOLVES the world half-way through a cycle
  # (see doOneCycle's dissolution seam) and that frame must still close out — none of this is
  # per-world. WorldWdgt.frameCount stamps geometry caches, and dateOfPreviousCycleStart paces macro
  # playback; a frame that silently failed to advance either would stall both.
  _closeCycleBookkeepingNoSettle: (cycleStartPerfMs) ->
    # END-OF-FRAME compile station: budget-drain pending class-source compiles
    # AFTER paint, so a lazy-part load burst spends only the frame time paint
    # left over -- and at least one source per frame regardless. Guarded: on a
    # precompiled boot the world steps before
    # js/src/loading-and-compiling-coffeescript-sources-min.js arrives.
    window.SourceCompileScheduler?.drainAtEndOfCycle cycleStartPerfMs

    WorldWdgt.frameCount++

    WorldWdgt.dateOfPreviousCycleStart = WorldWdgt.dateOfCurrentCycleStart
    WorldWdgt.dateOfCurrentCycleStart = undefined

  # Widget stepping:
  _runChildrensStepFunction: ->


    # note that a widget can remove itself while stepping using the
    # Set.delete method. This is fine, because the forEach method
    # is not affected by the removal of elements while iterating.
    #
    # TODO all these set modifications should be immutable...
    @steppingWdgts.forEach (eachSteppingWidget) =>

      # for objects where @fps is defined, check which ones are due to be stepped
      # and which ones want to wait.
      millisBetweenSteps = Math.round(1000 / eachSteppingWidget.fps)
      timeOfCurrentCycleStart = WorldWdgt.dateOfCurrentCycleStart.getTime()

      if eachSteppingWidget.fps <= 0
        # if fps 0 or negative, then just run as fast as possible,
        # so 0 milliseconds remaining to the next invocation
        millisecondsRemainingToWaitedFrame = 0
      else
        if eachSteppingWidget.synchronisedStepping
          millisecondsRemainingToWaitedFrame = millisBetweenSteps - (timeOfCurrentCycleStart % millisBetweenSteps)
          if eachSteppingWidget.previousMillisecondsRemainingToWaitedFrame != 0 and millisecondsRemainingToWaitedFrame > eachSteppingWidget.previousMillisecondsRemainingToWaitedFrame
            millisecondsRemainingToWaitedFrame = 0
          eachSteppingWidget.previousMillisecondsRemainingToWaitedFrame = millisecondsRemainingToWaitedFrame
        else
          # a RESTORED stepper has no lastTime: the "stepping" membership marker re-adds it
          # here, but lastTime is serialization-transient (a wall-clock instant) and the
          # deserializer's Object.create skips the constructor's Date.now() seed — without
          # this re-seed the subtraction below is NaN, "NaN <= 0" never fires, and the
          # widget silently never steps again (measured: a snapshot-restored fps-5 blinker
          # fired 0 steps while a fresh control fired 12). Treating "now" as its last step
          # is exactly the fresh-construction semantics.
          eachSteppingWidget.lastTime ?= timeOfCurrentCycleStart
          elapsedMilliseconds = timeOfCurrentCycleStart - eachSteppingWidget.lastTime
          millisecondsRemainingToWaitedFrame = millisBetweenSteps - elapsedMilliseconds
      
      # when the firing time comes (or as soon as it's past):
      if millisecondsRemainingToWaitedFrame <= 0
        @_stepWidget eachSteppingWidget

        # Increment "lastTime" by millisBetweenSteps. Two notes:
        # 1) We don't just set it to timeOfCurrentCycleStart so that there is no drifting
        # in running it the next time: we run it the next time as if this time it
        # ran exactly on time.
        # 2) We are going to update "last time" with the loop
        # below. This is because in case the window is not in foreground,
        # requestAnimationFrame doesn't run, so we might skip a number of steps.
        # In such cases, just bring "lastTime" up to speed here.
        # If we don't do that, "skipped" steps would catch up on us and run all
        # in contiguous frames when the window comes to foreground, so the
        # widgets would animate frantically (every frame) catching up on
        # all the steps they missed. We don't want that.
        #
        # while eachSteppingWidget.lastTime + millisBetweenSteps < timeOfCurrentCycleStart
        #   eachSteppingWidget.lastTime += millisBetweenSteps
        #
        # 3) and finally, here is the equivalent of the loop above, but done
        # in one shot using remainders.
        # Again: we are looking for the last "multiple" k such that
        #      lastTime + k * millisBetweenSteps
        # is less than timeOfCurrentCycleStart.

        eachSteppingWidget.lastTime = timeOfCurrentCycleStart - ((timeOfCurrentCycleStart - eachSteppingWidget.lastTime) % millisBetweenSteps)



  _stepWidget: (whichWidget) ->
    if whichWidget.onNextStep
      nxt = whichWidget.onNextStep
      whichWidget.onNextStep = undefined
      nxt.call whichWidget
    if !whichWidget.step?
      debugger
    try
      whichWidget.step()
    catch err
      # public-call-sanctioned: createErrorConsole stays public (its body drives the public
      # setExtent/moveTo/add — rule [A] forbids the _-form); this discrete error-recovery path
      # consciously pops it outside any pass.
      @_softResetWorld()
      if !@errorConsole? then @createErrorConsole()
      @errorConsole.contents.showUpWithError err

  stretchWorldToFillEntirePage: ->
    # once you call this, the world will forever take the whole page
    @automaticallyAdjustToFillEntireBrowserAlsoOnResize = true
    pos = @getCanvasPosition()
    clientHeight = window.innerHeight
    clientWidth = window.innerWidth
    if pos.x > 0
      @worldCanvas.style.position = "absolute"
      @worldCanvas.style.left = "0px"
      pos.x = 0
    if pos.y > 0
      @worldCanvas.style.position = "absolute"
      @worldCanvas.style.top = "0px"
      pos.y = 0
    # scrolled down b/c of viewport scaling
    clientHeight = document.documentElement.clientHeight  if document.body.scrollTop
    # scrolled left b/c of viewport scaling
    clientWidth = document.documentElement.clientWidth  if document.body.scrollLeft

    if (@worldCanvas.width isnt clientWidth) or (@worldCanvas.height isnt clientHeight)
      @_fullChanged()
      @worldCanvas.width = (clientWidth * ceilPixelRatio)
      @worldCanvas.style.width = clientWidth + "px"
      @worldCanvas.height = (clientHeight * ceilPixelRatio)
      @worldCanvas.style.height = clientHeight + "px"
      @_syncRenderCanvasToWorldCanvas()
      @_applyExtent new Point clientWidth, clientHeight
      @_reLayoutDesktop()
    # the canvas may have been repositioned (style.left/top above) and/or resized —
    # drop the memoised position so the next read reflects the new geometry
    @invalidateCanvasPositionCache()


  # The desktop consumes its children's proportional records (position-only, in
  # _reLayoutDesktop below) -- my COMPLETE child rule, asked by the __add seed, both drain
  # stations, and _reLayoutDesktop itself (see Widget.consumesFractionalGeometryOf):
  # layout-inert chrome (handles / carets / highlighters) is never a reflow subject, the
  # hand is world chrome, and desktop icons live in the icon grid -- _reLayoutDesktop
  # never repositions them, so seeding them would store records nothing reads.
  consumesFractionalGeometryOf: (child) ->
    !child.isLayoutInert?() and child != @hand and !child.isDesktopIcon?()

  # Drain station for the __add fractional-record seeds: derive the proportional
  # record (a StretchLayoutSpec) of every widget that entered a consuming holder since the
  # last cycle, AFTER its builder's JS turn finished placing it, and BEFORE geometry
  # settles and paints. FILL, never overwrite a RECORDED spec: existing records are
  # authoritative -- a builder's deliberate record, a drop's, or a spec that rode an
  # island wrap (the layoutSpec: add-arg, whose islands have a DIFFERENT box than the
  # figure the values were derived from) -- and a re-derive over an integer imposition
  # also drifts the fractions a little each time. The ONE sanctioned overwrite is a
  # PROVISIONAL spec (the stretch arrange's pre-placement heal guess, D8): re-derived
  # HERE, once, at builder-final geometry -- which is what retired the place-before-add
  # builder rule. The figure-parent gate skips widgets that moved on to a non-consuming
  # holder (or died) in the meantime -- deriving would write data nothing reads.
  # Dark-cheap when the set is empty. (Both halves measured: the overwriting form churned
  # the island-wrap and sample-slide tests, auto-bookkeeping arc P1 ledger.)
  _drainPendingFractionalBookkeepingSeeds: ->
    return if @pendingFractionalBookkeepingSeeds.size == 0
    @pendingFractionalBookkeepingSeeds.forEach (w) ->
      fig = w._enclosingIslandFigure()
      if !w.destroyed and fig.parent?.consumesFractionalGeometryOf(fig) and
      (!fig.layoutSpec?.isStretchElement?() or fig.layoutSpec.provisional)
        w._rememberFractionalSituationInHoldingPanel()
    @pendingFractionalBookkeepingSeeds.clear()

  # Drain the pending RE-records (HandleWdgt release enqueues its target): unlike the
  # fill-only seed drain above, a re-record OVERWRITES -- the gesture deliberately changed
  # the widget's geometry, so its stored proportions are stale by user intent. Runs AFTER
  # recalculateLayouts (the handle's writes are deferred-settle, so only the post-flush
  # geometry is the gesture's outcome). Without this, a handle-resized stretch child snapped
  # back to its pre-gesture proportions on the next holder reflow (the auto-bookkeeping
  # arc's P0 probe, GAP A -- a long-standing product bug). Dark-cheap when empty.
  _drainPendingFractionalReRecords: ->
    return if @pendingFractionalReRecords.size == 0
    @pendingFractionalReRecords.forEach (w) ->
      fig = w._enclosingIslandFigure()
      if !w.destroyed and fig.parent?.consumesFractionalGeometryOf(fig)
        w._rememberFractionalSituationInHoldingPanel()
    @pendingFractionalReRecords.clear()

  _reLayoutDesktop: ->
    @children.forEach (child) =>
      # reposition the consumed desktop children -- membership is the SAME
      # consumesFractionalGeometryOf rule the seed and the drains ask, so read-side and
      # seed-side exclusions (icons, chrome, the hand) cannot drift. A corner-ARMED child
      # (the clock) has no stretch record, so only the harmless keep-within clamp touches
      # it here before the corner pass below places it; the bin opener is an icon, outside
      # the rule entirely.
      if @consumesFractionalGeometryOf child
        if child.layoutSpec?.isStretchElement?()
          child._moveInDesktopToFractionalPosition()
        if !child.layoutSpec?.wasPositionedSlightlyOutsidePanel
          child._moveWithin @
    # the desktop furniture (bin opener bottom-right, clock top-right) rides the standard
    # corner pass; this reflow runs OUTSIDE the settle's base _reLayout (the browser-resize
    # handler calls it directly), so run the pass here too
    @_reLayoutCornerInternalChildren()
  
  # WorldWdgt events:

  _initVirtualKeyboard: ->
    if @inputDOMElementForVirtualKeyboard
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = undefined
    unless (WorldWdgt.preferencesAndSettings.isTouchDevice and WorldWdgt.preferencesAndSettings.useVirtualKeyboard)
      return
    @inputDOMElementForVirtualKeyboard = document.createElement "input"
    @inputDOMElementForVirtualKeyboard.type = "text"
    @inputDOMElementForVirtualKeyboard.style.color = Color.TRANSPARENT.toString()
    @inputDOMElementForVirtualKeyboard.style.backgroundColor = Color.TRANSPARENT.toString()
    @inputDOMElementForVirtualKeyboard.style.border = "none"
    @inputDOMElementForVirtualKeyboard.style.outline = "none"
    @inputDOMElementForVirtualKeyboard.style.position = "absolute"
    @inputDOMElementForVirtualKeyboard.style.top = "0px"
    @inputDOMElementForVirtualKeyboard.style.left = "0px"
    @inputDOMElementForVirtualKeyboard.style.width = "0px"
    @inputDOMElementForVirtualKeyboard.style.height = "0px"
    @inputDOMElementForVirtualKeyboard.autocapitalize = "none" # iOS specific
    document.body.appendChild @inputDOMElementForVirtualKeyboard

    @inputDOMElementForVirtualKeyboardKeydownBrowserEventListener = (event) =>
      @inputEventsQueue.push InputDOMElementForVirtualKeyboardKeydownInputEvent.fromBrowserEvent event

      # Default in several browsers
      # is for the backspace button to trigger
      # the "back button", so we prevent that
      # default here.
      if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
        event.preventDefault()

      # suppress tab override and make sure tab gets
      # received by all browsers
      if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
        event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keydown",
      @inputDOMElementForVirtualKeyboardKeydownBrowserEventListener, false

    @inputDOMElementForVirtualKeyboardKeyupBrowserEventListener = (event) =>
      @inputEventsQueue.push InputDOMElementForVirtualKeyboardKeyupInputEvent.fromBrowserEvent event
      event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keyup",
      @inputDOMElementForVirtualKeyboardKeyupBrowserEventListener, false

    # Keypress events are deprecated in the JS specs and are not needed
    @inputDOMElementForVirtualKeyboardKeypressBrowserEventListener = (event) =>
      #@inputEventsQueue.push event
      event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keypress",
      @inputDOMElementForVirtualKeyboardKeypressBrowserEventListener, false

  # -----------------------------------------------------
  # clipboard events processing
  # -----------------------------------------------------


  _initMouseEventListeners: ->
    canvas = @worldCanvas
    # there is indeed a "dblclick" JS event
    # but we reproduce it internally.
    # The reason is that we do so for "click"
    # because we want to check that the mouse
    # button was released in the same widget
    # where it was pressed (cause in the DOM you'd
    # be pressing and releasing on the same
    # element i.e. the canvas anyways
    # so we receive clicks even though they aren't
    # so we have to take care of the processing
    # ourselves).
    # So we also do the same internal
    # processing for dblclick.
    # Hence, don't register this event listener
    # below...
    #@dblclickEventListener = (event) =>
    #  event.preventDefault()
    #  @hand.processDoubleClick event
    #canvas.addEventListener "dblclick", @dblclickEventListener, false

    @mousedownBrowserEventListener = (event) =>
      @inputEventsQueue.push MousedownInputEvent.fromBrowserEvent event

    canvas.addEventListener "mousedown", @mousedownBrowserEventListener, false

    
    @mouseupBrowserEventListener = (event) =>
      @inputEventsQueue.push MouseupInputEvent.fromBrowserEvent event

    canvas.addEventListener "mouseup", @mouseupBrowserEventListener, false
        
    @mousemoveBrowserEventListener = (event) =>
      @inputEventsQueue.push MousemoveInputEvent.fromBrowserEvent event

    canvas.addEventListener "mousemove", @mousemoveBrowserEventListener, false

  _initTouchEventListeners: ->
    canvas = @worldCanvas
    
    @touchstartBrowserEventListener = (event) =>
      @inputEventsQueue.push TouchstartInputEvent.fromBrowserEvent event
      event.preventDefault() # (unsure that this one is needed)

    canvas.addEventListener "touchstart", @touchstartBrowserEventListener, false

    @touchendBrowserEventListener = (event) =>
      @inputEventsQueue.push TouchendInputEvent.fromBrowserEvent event
      event.preventDefault() # prevent mouse events emulation

    canvas.addEventListener "touchend", @touchendBrowserEventListener, false
        
    @touchmoveBrowserEventListener = (event) =>
      @inputEventsQueue.push TouchmoveInputEvent.fromBrowserEvent event
      event.preventDefault() # (unsure that this one is needed)

    canvas.addEventListener "touchmove", @touchmoveBrowserEventListener, false

    @gesturestartBrowserEventListener = (event) =>
      # we don't do anything with gestures for the time being
      event.preventDefault() # (unsure that this one is needed)

    canvas.addEventListener "gesturestart", @gesturestartBrowserEventListener, false

    @gesturechangeBrowserEventListener = (event) =>
      # we don't do anything with gestures for the time being
      event.preventDefault() # (unsure that this one is needed)

    canvas.addEventListener "gesturechange", @gesturechangeBrowserEventListener, false


  _initKeyboardEventListeners: ->
    canvas = @worldCanvas
    @keydownBrowserEventListener = (event) =>
      @inputEventsQueue.push KeydownInputEvent.fromBrowserEvent event

      # this paragraph is to prevent the browser going
      # "back button" when the user presses delete backspace.
      # taken from http://stackoverflow.com/a/2768256
      doPrevent = false
      if event.key == "Backspace"
        d = event.srcElement or event.target
        if d.tagName.toUpperCase() == 'INPUT' and
        (d.type.toUpperCase() == 'TEXT' or
          d.type.toUpperCase() == 'PASSWORD' or
          d.type.toUpperCase() == 'FILE' or
          d.type.toUpperCase() == 'SEARCH' or
          d.type.toUpperCase() == 'EMAIL' or
          d.type.toUpperCase() == 'NUMBER' or
          d.type.toUpperCase() == 'DATE') or
        d.tagName.toUpperCase() == 'TEXTAREA'
          doPrevent = d.readOnly or d.disabled
        else
          doPrevent = true

      # this paragraph is to prevent the browser scrolling when
      # user presses spacebar, see
      # https://stackoverflow.com/a/22559917
      if event.key == " " and event.target == @worldCanvas
        # Note that doing a preventDefault on the spacebar
        # causes it not to generate the keypress event
        # (just the keydown), so we had to modify the keydown
        # to also process the space.
        # (I tried to use stopPropagation instead/inaddition but
        # it didn't work).
        doPrevent = true

      # also browsers tend to do special things when "tab"
      # is pressed, so let's avoid that
      if event.key == "Tab" and event.target == @worldCanvas
        doPrevent = true

      if doPrevent
        event.preventDefault()

    canvas.addEventListener "keydown", @keydownBrowserEventListener, false

    @keyupBrowserEventListener = (event) =>
      @inputEventsQueue.push KeyupInputEvent.fromBrowserEvent event

    canvas.addEventListener "keyup", @keyupBrowserEventListener, false

    # keypress is deprecated in the latest specs, and it's really not needed/used,
    # since all keys really have an effect when they are pushed down
    @keypressBrowserEventListener = (event) =>

    canvas.addEventListener "keypress", @keypressBrowserEventListener, false

  _initClipboardEventListeners: ->
    # snippets of clipboard-handling code taken from
    # http://codebits.glennjones.net/editing/setclipboarddata.htm
    # Note that this works only in Chrome. Firefox and Safari need a piece of
    # text to be selected in order to even trigger the copy event. Chrome does
    # enable clipboard access instead even if nothing is selected.
    # There are a couple of solutions to this - one is to keep a hidden textfield that
    # handles all copy/paste operations.
    # Another one is to not use a clipboard, but rather an internal string as
    # local memory. So the OS clipboard wouldn't be used, but at least there would
    # be some copy/paste working. Also one would need to intercept the copy/paste
    # key combinations manually instead of from the copy/paste events.

    # -----------------------------------------------------
    # clipboard events listeners
    # -----------------------------------------------------
    # we deal with the clipboard here in the event listeners
    # because for security reasons the runtime is not allowed
    # access to the clipboards outside of here. So we do all
    # we have to do with the clipboard here, and in every
    # other place we work with text.

    @cutBrowserEventListener = (event) =>
      @inputEventsQueue.push CutInputEvent.fromBrowserEvent event

    document.body.addEventListener "cut", @cutBrowserEventListener, false
    
    @copyBrowserEventListener = (event) =>
      @inputEventsQueue.push CopyInputEvent.fromBrowserEvent event

    document.body.addEventListener "copy", @copyBrowserEventListener, false

    @pasteBrowserEventListener = (event) =>
      @inputEventsQueue.push PasteInputEvent.fromBrowserEvent event

    document.body.addEventListener "paste", @pasteBrowserEventListener, false

  _initOtherMiscEventListeners: ->
    canvas = @worldCanvas

    @contextmenuEventListener = (event) ->
      # suppress context menu for Mac-Firefox
      event.preventDefault()
    canvas.addEventListener "contextmenu", @contextmenuEventListener, false
    

    # Safari, Chrome
    
    @wheelBrowserEventListener = (event) =>
      @inputEventsQueue.push WheelInputEvent.fromBrowserEvent event
      event.preventDefault()

    canvas.addEventListener "wheel", @wheelBrowserEventListener, false

    # (Mobile-Safari wheel-event workaround, Oct 2020. The Jan-2021 re-check reminder went
    # unactioned 4+ yrs with no reported regression — reviewed & retained 2026-07-14.)
    # As of Oct 2020, using mouse/trackpad in
    # Mobile Safari, the wheel event is not sent.
    # See:
    #   https://github.com/cdr/code-server/issues/1455
    #   https://bugs.webkit.org/show_bug.cgi?id=210071
    # However, the scroll event is sent, and when that is sent,
    # we can use the window.pageYOffset
    # to re-create a passable, fake wheel event.
    if Utils.runningInMobileSafari()
      window.addEventListener "scroll", @wheelBrowserEventListener, false

    @dragoverEventListener = (event) ->
      event.preventDefault()
    window.addEventListener "dragover", @dragoverEventListener, false
    
    @dropBrowserEventListener = (event) =>
      event.preventDefault()
      # a Fizzygum file (*.fzw.json) dropped on the desktop is deserialised and attached at
      # the drop point; FileLoading sniffs the envelope and rejects non-Fizzygum files.
      # (Image-file drag-ingestion is a banked future extension.)
      files = event.dataTransfer?.files
      if files? and files.length > 0
        FileLoading.loadFile files[0], new Point event.clientX, event.clientY
    window.addEventListener "drop", @dropBrowserEventListener, false

    @resizeBrowserEventListener = =>
      # a window resize can move the canvas within the document even when it does
      # not route through stretchWorldToFillEntirePage — invalidate eagerly
      @invalidateCanvasPositionCache()
      @inputEventsQueue.push ResizeInputEvent.fromBrowserEvent event

    # this is a DOM thing, little to do with other r e s i z e methods
    window.addEventListener "resize", @resizeBrowserEventListener, false

  # note that we don't register the normal click,
  # we figure that out independently.
  initEventListeners: ->
    @_initMouseEventListeners()
    @_initTouchEventListeners()
    @_initKeyboardEventListeners()
    @_initClipboardEventListeners()
    @_initOtherMiscEventListeners()

  # Detach every browser event listener the _init*EventListeners family attached.
  #
  # This is the DETACH half of a PAIR: initEventListeners above (plus _initVirtualKeyboard) is the one
  # place listeners are attached and this is the one place they are detached, so the two must enumerate
  # the SAME listener set — a listener added in an _init* and forgotten here leaks on every
  # detach/attach cycle.
  #
  # ⚠ THIS IS A DETERMINISM MECHANISM, NOT MEMORY CLEANUP. Its only caller is
  # AutomatorPlayer.startTestPlaying, which calls it at the START of every SystemTest so that the
  # macro's synthetic events are the ONLY input: a listener that survives here can push a REAL browser
  # event into @inputEventsQueue mid-test and break the byte-exact contract (../Fizzygum-tests/DETERMINISM.md).
  #
  # ⚠⚠ EVERY LISTENER MUST BE REMOVED FROM THE SAME TARGET IT WAS ADDED TO — the listeners are spread
  # over THREE targets (@worldCanvas / document.body / window) and removeEventListener on the wrong
  # target is a SILENT NO-OP: no error, nothing removed, nothing logged. That is exactly the bug this
  # method shipped with (fixed 2026-07-15): it removed all 20 from `canvas`, so the 7 that had been
  # added to document.body (cut/copy/paste) or window (scroll/dragover/drop/resize) were never
  # detached at all, and stayed live through every test — including @resizeBrowserEventListener, which
  # pushes a ResizeInputEvent into the queue.
  #
  # So: keep the GROUPS below in sync with their _init* counterparts, and match the target exactly.
  removeEventListeners: ->
    canvas = @worldCanvas

    # ── added to @worldCanvas ──────────────────────────────────────────────────────────────────────
    # canvas.removeEventListener 'dblclick', @dblclickEventListener
    canvas.removeEventListener 'mousedown', @mousedownBrowserEventListener
    canvas.removeEventListener 'mouseup', @mouseupBrowserEventListener
    canvas.removeEventListener 'mousemove', @mousemoveBrowserEventListener
    canvas.removeEventListener 'contextmenu', @contextmenuEventListener

    canvas.removeEventListener "touchstart", @touchstartBrowserEventListener
    canvas.removeEventListener "touchend", @touchendBrowserEventListener
    canvas.removeEventListener "touchmove", @touchmoveBrowserEventListener
    canvas.removeEventListener "gesturestart", @gesturestartBrowserEventListener
    canvas.removeEventListener "gesturechange", @gesturechangeBrowserEventListener

    canvas.removeEventListener 'keydown', @keydownBrowserEventListener
    canvas.removeEventListener 'keyup', @keyupBrowserEventListener
    canvas.removeEventListener 'keypress', @keypressBrowserEventListener
    canvas.removeEventListener 'wheel', @wheelBrowserEventListener

    # ── added to document.body by _initClipboardEventListeners ─────────────────────────────────────
    document.body.removeEventListener 'cut', @cutBrowserEventListener
    document.body.removeEventListener 'copy', @copyBrowserEventListener
    document.body.removeEventListener 'paste', @pasteBrowserEventListener

    # ── added to window by _initOtherMiscEventListeners ────────────────────────────────────────────
    # the mobile-Safari fake-wheel workaround; guarded to mirror the add site (removing a listener
    # that was never added is a harmless no-op, but keep the pair symmetric so the reason stays visible)
    if Utils.runningInMobileSafari()
      window.removeEventListener 'scroll', @wheelBrowserEventListener
    window.removeEventListener 'dragover', @dragoverEventListener
    window.removeEventListener 'drop', @dropBrowserEventListener
    window.removeEventListener 'resize', @resizeBrowserEventListener

    # ── added to @inputDOMElementForVirtualKeyboard by _initVirtualKeyboard ────────────────────────
    # Defensive completeness, not a leak fix: that hidden input only exists on a touch device with
    # useVirtualKeyboard AND an open caret, and closing the caret already removes it from the DOM and
    # clears it (taking its listeners to GC), so this is a no-op in every environment tests run in.
    # It is here so the "detach everything" contract holds if a touch-device test ever exists.
    if @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard.removeEventListener 'keydown', @inputDOMElementForVirtualKeyboardKeydownBrowserEventListener
      @inputDOMElementForVirtualKeyboard.removeEventListener 'keyup', @inputDOMElementForVirtualKeyboardKeyupBrowserEventListener
      @inputDOMElementForVirtualKeyboard.removeEventListener 'keypress', @inputDOMElementForVirtualKeyboardKeypressBrowserEventListener

  mouseDownLeft: ->
    noOperation
  
  mouseClickLeft: ->
    noOperation
  
  mouseDownRight: ->
    noOperation
      

  # WorldWdgt text field tabbing:
  nextTab: (editField) ->
    next = @nextEntryField editField
    if next
      @switchTextFieldFocus editField, next
  
  previousTab: (editField) ->
    prev = @previousEntryField editField
    if prev
      @switchTextFieldFocus editField, prev

  switchTextFieldFocus: (current, next) ->
    current.clearSelection()
    next.bringToForeground()
    next.selectAll()
    next.edit()

  # if an error is thrown, the state of the world might
  # be messy, for example the pointer might be
  # dragging an invisible widget, etc.
  # So, try to clean-up things as much as possible.
  _softResetWorld: ->
    # nosettle-sanctioned: error-recovery reset, reached only from the catch paths outside any
    # settle/pass — the hand's public self-settling drop() is exactly what a cleanup wants here.
    @hand.drop()
    @hand.mouseOverList.clear()
    @hand.nonFloatDraggedWdgt = undefined
    @wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.clear()
    @editorFocusWdgt = undefined

  # There is something special about the
  # "world" version of fullDestroyChildren:
  # it resets the counter used to count
  # how many widgets exist of each Widget class.
  # That counter is also used to determine the
  # unique ID of a Widget. So, destroying
  # all widgets from the world causes the
  # counts and IDs of all the subsequent
  # widgets to start from scratch again.
  fullDestroyChildren: ->
    # Zero every per-class id counter (the actual population count is `instancesCounter`;
    # labels are built from instanceNumericID, set from lastBuiltInstanceNumericID) --
    # enumerated by the `instances`-Set marker every class carries (allClassFunctions),
    # NEVER by a name-suffix scan, which misses e.g. FrameContentsPlaceholderText. Only
    # widget-chain classes carry the field (declared on Widget); everything else skips.
    # ⚠ WorldWdgt is SKIPPED because this sweep serves BOTH callers of the shared teardown core, and
    # loadWorldSnapshot keeps its LIVE world — whose id must stay the one it was issued, since a
    # snapshot carries no WorldWdgt counter to restore it from (Serializer.collectIdCounters skips
    # it for the same reason). A world being REPLACED gives its id up in _dissolveWorldNoSettle
    # instead, which is the only path that builds a successor to hand it to.
    for eachClassFunction in allClassFunctions()
      continue if eachClassFunction is WorldWdgt
      if typeof eachClassFunction.lastBuiltInstanceNumericID is "number"
        eachClassFunction.lastBuiltInstanceNumericID = 0

    # The per-test automator display/pacing toggles come back to their defaults here, through an
    # existence-soaked hook the harness installs (WorldTestSupport._resetAutomatorTogglesNoSettle).
    # WHICH toggles exist is the harness's knowledge, not the world's — shipping code does not write
    # a harness class's statics — and an artifact without the harness has no toggles to reset, so the
    # soak is the whole conditional.
    # ⚠ THE CALL SITS HERE, not in the test teardown, because BOTH callers of the shared teardown
    # core reach it through this method: a serialization test loads a whole-world snapshot MID-test,
    # and the toggles must flip at exactly the same moment on that path as on the test reset —
    # otherwise macro pacing changes under a running test and its references churn.
    @_resetAutomatorTogglesNoSettle?()

    super()

  destroyToolTips: ->
    # "toolTipsList" keeps the widgets to be deleted upon
    # the next mouse click, or whenever another temporary Widget decides
    # that it needs to remove them.
    # Tooltips are destroyed outright: nothing revives a dismissed tooltip.
    # (Dismissed transient pop-ups die the same way -- FrameWdgt._closeNoSettle's
    # dismissal policy.)

    # Unconditional, deliberately: a click dismisses every tooltip, hovered or not — the
    # conventional behavior. (⛔ do not guard this with `boundsContainPoint @position()`:
    # on the WORLD that tests the world's own origin, not the pointer, so it keeps nothing
    # except — leakily — a tooltip overlapping the top-left corner. A keep-the-hovered-
    # tooltip policy, if ever wanted, tests the HAND's position mapped into the tooltip's
    # plane.)
    @toolTipsList.forEach (tooltip) =>
      tooltip.fullDestroy()
      @toolTipsList.delete tooltip
  

  # "open from file…" world-menu action: pop the file picker; FileLoading routes the chosen
  # *.fzw.json by its envelope `kind` (a widget is attached to the desktop, a world snapshot
  # replaces the world). A product feature — ships in all builds.
  openFromFile: ->
    FileLoading.openFromFileDialog()

  # --- whole-world snapshot save/load (kind:"world") ---------------------------------------
  # See docs/architecture/serialization-duplication-reference.md §11 and the plan §4.9. Serialization is a
  # PRODUCT feature — these ship in production (they are core-part code). The world is NOT saved as a
  # widget record (that would drag in its canvases/caches/hand/listener closures and crash the
  # walker, defect D8); Serializer.serializeWorld captures the desktop tree + off-tree bin
  # + app-slot windows into the object table, and the genuine world state into a `world` section.

  serializeWorldSnapshot: (opts = {}) ->
    Serializer.serializeWorld @, opts

  # `world.serialize()` is a GUIDED error: a world is not a widget subtree, so the inherited
  # Widget.serialize would crash the graph walker (D8). Point callers at the snapshot entry.
  serialize: (opts) ->
    throw new SerializationError "a whole world cannot be saved as a widget — call world.serializeWorldSnapshot() instead (menu: \"save world snapshot…\")",
      rootDescription: "the world"
      remediation: "Use world.serializeWorldSnapshot() to save the whole desktop, or serialize an individual widget subtree."

  # "save world snapshot…" world-menu action: serialize + download over file://.
  saveWorldSnapshotToFile: ->
    try
      envelope = @serializeWorldSnapshot prettyPrint: true
    catch error
      if error instanceof SerializationError
        world.inform error.toString()
        return
      else
        throw error
    FileSaving.saveStringAsFile envelope, "world.fzw.json"

  # Load a whole-world snapshot, REPLACING the current desktop. A snapshot can carry code
  # ($src methods, source edits), so a file/menu load confirms first; programmatic callers
  # (the rig, a macro) pass opts.skipConfirm. This is a PUBLIC orchestrator (like resetWorld):
  # it sequences self-settling operations at the top level, so its setColor / _settleLayoutsAfter
  # calls are the sanctioned public path. NB the teardown is the SHARED shipping core
  # (_teardownWorldStructureNoSettle) — NOT the TEST-REPO resetWorld/_resetWorldNoSettle, which
  # lives in ../Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee and travels
  # with the `harness` part, so this could never call it — and every step below is one half of that
  # core's split contract: the core drops all references to what it destroyed, and this method fills
  # the world back in.
  # Does restoring this snapshot need a reflective layer that is NOT here yet but still could be?
  # True only on a `sources: "lazy"` build, before anything has asked for it, for a file that
  # actually carries class- or mixin-scope source edits -- so no other build ever pays a wait.
  _snapshotNeedsTheReflectiveLayer: (envelope) ->
    return false if SourceEditsRegistry.canReplaySourceEdits()
    return false unless reflectiveLayerCanLoad()
    records = envelope?.world?.sourceEdits
    return false unless records?
    records.some (eachRecord) -> eachRecord.scope is "class" or eachRecord.scope is "mixin"

  loadWorldSnapshot: (envelopeOrString, opts = {}) ->
    # early-return-sanctioned: every guard below MUST precede the settle, and none of them can live
    # in a core that only runs after the teardown they exist to prevent — a format check that informs
    # and stops, a user confirm that may decline, and the lazy-part branch, which RE-ENTERS this same
    # public method once the parts arrive rather than continuing.
    envelope = if typeof envelopeOrString is "string" then JSON.parse(envelopeOrString) else envelopeOrString
    unless envelope? and envelope.format is Serializer.FORMAT and envelope.kind is "world"
      world.inform "This is not a Fizzygum world snapshot file."
      return
    unless opts.skipConfirm
      msg = "Load this world snapshot?\n\nIt REPLACES everything on your desktop, and can run code the snapshot carries."
      return unless (typeof window.confirm is "function") and window.confirm msg
    # 0. A snapshot can name classes that live in a LAZY part this page has never loaded (a saved
    #    Fizzytiles window on a freshly-booted index.html). Load those parts FIRST, then re-enter.
    #
    #    ⚠ THE POSITION OF THIS BLOCK IS THE WHOLE CORRECTNESS ARGUMENT. Step 1 below destroys the
    #    entire desktop, so the bail-out has to happen before ANY mutation: the re-entry then runs
    #    the body below exactly once, on an intact world, with every class already resident. Put it
    #    any lower and a lazy load would re-enter over a half-torn-down world — and a part that
    #    FAILS to load would leave the user with nothing instead of the desktop they still have.
    #    The scan itself is pure (it only reads the envelope), and it sits after the confirm so the
    #    user is asked exactly once; the re-entry passes skipConfirm for that reason and no other.
    missingParts = @parts.partsNeededFor Serializer.classNamesIn envelope
    if missingParts.length
      # double-settle-sanctioned: BRANCH-EXCLUSIVE, and that is the whole design. This branch
      # RETURNS before reaching any of the settling body below, so the re-entered call performs the
      # one and only flush; the two never run in one pass. It is a tail re-entry precisely so that
      # nothing is mutated twice (or, worse, torn down twice).
      return @parts.ensureAllLoaded(missingParts).then =>
        @loadWorldSnapshot envelope, Object.assign {}, opts, skipConfirm: true
    # 0b. Same bail-out-then-re-enter shape, and for the same reason, as the missing-parts block
    #     above: a snapshot's CLASS-level source edits are replayed against the META-SYSTEM, which on
    #     a `sources: "lazy"` build has not arrived unless something asked for it. Ask here -- before
    #     any mutation, after the confirm, so the user is prompted exactly once -- and re-enter.
    #     It cannot loop: the predicate requires the layer to be absent, and the re-entry runs with
    #     it present. A build that can NEVER load it (`sources: "none"`) does not come through here
    #     at all; it takes the refusal below instead.
    if @_snapshotNeedsTheReflectiveLayer envelope
      return ensureReflectiveLayerLoaded().then =>
        @loadWorldSnapshot envelope, Object.assign {}, opts, skipConfirm: true
    section = envelope.world or {}
    # 1. tear the current world down — one settle over the shared NoSettle core, which also zeroes
    #    every per-class lastBuiltInstanceNumericID, giving the clean id space the restored iids need.
    @_settleLayoutsAfter => @_teardownWorldStructureNoSettle()
    # 2. restore the per-class id counters into the freshly-zeroed space BEFORE deserializing,
    #    so registerThisInstance sees the right high-water marks (§4.4/§4.9).
    if section.idCounters?
      for own className, n of section.idCounters
        window[className].lastBuiltInstanceNumericID = n if window[className]?
    # 2b. replay CLASS-scope source edits against the live prototypes BEFORE deserializing, so
    #     restored shells (Object.create(prototype)) already see the edited methods (§12). The
    #     confirm above warned that a load can run code the snapshot carries. Instance-scope
    #     edits ride the normal {"$src"} path on their own widget. The rebuilt registry is
    #     installed AFTER deserialize (below), so the $src re-injections don't double-log into it.
    restoredRegistry = SourceEditsRegistry.fromRecords section.sourceEdits
    # An artifact that ships no class source text has no meta-system and can never replay these
    # (arc 5's lean profile). Say so ONCE, to the user, before restoring the rest: the alternative
    # is that their class edits vanish from the loaded world with only a console line to show for it.
    # The widgets and their per-widget {"$src"} function edits still load normally.
    if (unreplayableCount = restoredRegistry.unreplayableSourceEditsCount()) > 0
      @inform "This build cannot re-apply the " + unreplayableCount + " class-level source edit" +
        (if unreplayableCount is 1 then "" else "s") + " this file carries.\n" +
        "Everything else in it loads normally."
    restoredRegistry.replayMixinEdits()
    restoredRegistry.replayClassEdits()
    # 3. deserialize the object table (kind:"world" preserves each widget's iid).
    result = Deserializer.deserialize envelope
    shells = result.shells or []
    resolve = (refOrVal) ->
      return undefined unless refOrVal?
      return shells[refOrVal.$r] if refOrVal.$r?
      return WellKnownObjects.resolve refOrVal.$wk if refOrVal.$wk?
      refOrVal
    # 4. restore the static preferences bag (values only) from its forced data record.
    if section.preferences?
      restoredPrefs = resolve section.preferences
      if restoredPrefs?
        WorldWdgt.preferencesAndSettings[k] = v for own k, v of restoredPrefs
    # 5. apply the world-state scalars to the LIVE world.
    @isDevMode = section.isDevMode if section.isDevMode?
    @alpha = section.alpha if section.alpha?
    @numberOfIconsOnDesktop = section.numberOfIconsOnDesktop if section.numberOfIconsOnDesktop?
    @[name] = val for own name, val of (section.infoDocFlags or {})
    if section.untitledNamingCounters? and @untitledNamingService?
      @untitledNamingService.howManyUntitledShortcuts = section.untitledNamingCounters.howManyUntitledShortcuts or 0
      @untitledNamingService.howManyUntitledFoldersShortcuts = section.untitledNamingCounters.howManyUntitledFoldersShortcuts or 0
    # 6. swap in the restored (self-contained, off-tree) storage containers so every $r
    #    pointer at them (the bin opener's target, ...) stays consistent, and re-bind the
    #    app-slot / templates windows (orphaned-but-revivable — NOT re-attached to the
    #    desktop here).
    restoredBin = resolve section.bin
    @binWdgt = restoredBin if restoredBin?
    restoredShelf = resolve section.shelf
    @shelfWdgt = restoredShelf if restoredShelf?
    @[slot] = resolve(refVal) for own slot, refVal of (section.appSlots or {})
    @simpleEditorTemplates = resolve(section.simpleEditorTemplates) if section.simpleEditorTemplates?
    # 7. attach the desktop children in ONE settle batch, via the base _addNoSettle so the
    #    grid mixin does NOT re-place them (their restored positions are preserved) — the
    #    sanctioned public-equivalent path (never a raw layout core; see DETERMINISM.md).
    #    Clear each child's parent first (deserialize pre-set it to {"$wk":"world"}) so the
    #    attach is a clean re-parent. The SNAPSHOT's attachment state is authoritative:
    #    re-arm each child's deserialized spec explicitly, else the add would resolve
    #    defaultLayoutSpecWhenAddedTo (undefined) over it — disarming the furniture's corner
    #    knobs, and downgrading every stretch record to a geometry re-derive (the fraction
    #    drift the record law forbids).
    @_settleLayoutsAfter =>
      for childRef in (section.children or [])
        child = resolve childRef
        if child?
          child.parent = undefined
          @_addNoSettle child, layoutSpec: child.layoutSpec
    # 8. desktop colour + wallpaper (sequential self-settling public ops).
    restoredColor = resolve section.desktopColor
    @setColor restoredColor if restoredColor?
    @wallpaper.setPattern section.wallpaperPatternName if section.wallpaperPatternName? and @wallpaper?
    # 9. install the snapshot's source-edit registry (its class edits are already replayed;
    #    this makes the loaded world's edit history authoritative), then repaint now and again
    #    once any async image/canvas assets have decoded.
    @sourceEditsRegistry = restoredRegistry
    result.whenReady?.then? => @_fullChanged()
    @_fullChanged()
    # restore completion: storage membership was rebuilt wholesale -- mark for
    # the next cycle's sort (a snapshot saved with the sort still pending is
    # legitimate: each resident serialized wherever it rested, and re-sorts here).
    @noteStorageMembershipMayHaveChanged()
    return

  # A RESET IS A RECONSTRUCTION, not a cleaning. This world is torn down and DISSOLVED, a
  # replacement WorldWdgt is constructed over the same canvas, and the page runs on that one from
  # here on. The point of building rather than scrubbing is that "did the teardown forget field X?"
  # stops being a question anyone can ask: a world that has just been constructed cannot inherit a
  # stale field, because it has never had one. What survives a reset survives because it lives OFF
  # the world — PAGE lifetime: the class functions themselves, the font atlases and the metrics
  # probed off them, the interned immutables, the monotonic lifetime counters, the page's ONE
  # Automator (the constructor re-aims at `Automator.current`, it never replaces it) — never
  # because a cleanup pass happened to spare it. Doctrine:
  # docs/architecture/world-lifetime-and-inventory.md §1.
  #   The ONE invariant left is machine-checkable rather than argued: the world we replace must be
  # COLLECTIBLE. Anything still pinning it is a named bug, and `fg vmtruth`'s WeakRef oracle is
  # what names it.
  #
  # ⚠⚠ THE ORDER IS THE CORRECTNESS ARGUMENT: dissolution completes BEFORE the replacement is
  # constructed, because CONSTRUCTION is what moves `window.world` (WorldWdgt's constructor, first
  # statement). Widget._destroyNoSettle reads that global to unregister a dying widget from the
  # world's collections — so a widget destroyed AFTER the swap would reach into the LIVE world's
  # collections instead of its own, leaving the corpse's registrations behind in the world that
  # replaced it and mutating a world it never belonged to.
  #
  # The two `?.`-soaked hooks are the harness's seats, and WHERE each sits is its meaning:
  #   _beforeWorldDissolveNoSettle runs on the world the finished test ran IN. Its question — did
  #     this test leave residue the teardown could not reach — is about THIS world, and is
  #     meaningless asked of a world that has existed for no time at all.
  #   _afterWorldResetNoSettle runs on the world that now owns the page: construction determinism
  #     and the page-wide object-lifetime audit both need the incoming world, not the outgoing one.
  # Both are soaked because a product build ships no harness at all.
  #
  # SETTLE GRAMMAR — self-settling public API, like loadWorldSnapshot above: a SEQUENCE of
  # self-settling operations, each flushing once (_settleLayoutsAfter's doc blesses sequential
  # setters). _softResetWorld stays OUTSIDE the settle because its @hand.drop() is a real
  # re-parenting drop that self-flushes, and re-entering the flush would throw the flow violation.
  # @_dissolveWorldNoSettle() is deliberately NOT wrapped either, and for a different reason:
  # nothing may be laid out after dissolution — there is no tree, no hand and no listeners left —
  # and any damage mark it could still make is dropped at the funnel (see @_dissolved).
  #
  # It answers `undefined` ON PURPOSE. The new world is `window.world`, which is how everything
  # reaches a world anyway; answering it instead would make every `page.evaluate(-> world.resetWorld())`
  # serialise a cyclic widget graph over the debugger protocol.
  # thin-wrap-exempt: softReset (its hand.drop self-flushes) must precede the settle, and the
  # dissolution + reconstruction follow it, so this is a SEQUENCE, not the bare
  # @_settleLayoutsAfter => @_<name>NoSettle wrap.
  resetWorld: ->
    @_softResetWorld()
    @_settleLayoutsAfter => @_teardownWorldStructureNoSettle()
    @_beforeWorldDissolveNoSettle?()
    @_dissolveWorldNoSettle()
    # @_bootAutoAdjustToFillEntireBrowserAlsoOnResize is the value BOOT passed (the constructor
    # records it at its own tail), so the replacement is built the way boot built this one — NOT
    # with whatever a test happened to leave in @automaticallyAdjustToFillEntireBrowserAlsoOnResize.
    newWorld = new WorldWdgt @worldCanvas, @_bootAutoAdjustToFillEntireBrowserAlsoOnResize
    finishWorldSetup newWorld
    newWorld._afterWorldResetNoSettle?()
    return

  # DISSOLUTION: the last thing that happens to a world. It follows the shared structural teardown
  # (which destroys the TREE and drops every reference to what it destroyed) and takes care of the
  # world's own remains — the things a world holds that are not tree children, and the registrations
  # that would otherwise outlive it for the life of the page.
  _dissolveWorldNoSettle: ->
    # (a) THE BROWSER LISTENERS. All 20 are closures over THIS world pushing into THIS world's
    # @inputEventsQueue, and their targets (@worldCanvas, document.body, window) outlive every world
    # the page ever builds — so an undetached set keeps delivering a dead world's events forever.
    # initEventListeners / removeEventListeners are the attach/detach pair; that method's own comment
    # carries the target-matching rules.
    @removeEventListeners()
    # (b) THE WIDGETS A WORLD OWNS THAT ARE NOT TREE CHILDREN, and which fullDestroyChildren
    # therefore cannot reach: the hand (built by the constructor) and the two storage containers
    # (built by finishWorldSetup). Each of them sits in its class's `instances` registry, so leaving
    # one undestroyed pins it — and the whole object graph it references — for the life of the page.
    # The teardown core has already EMPTIED the containers of their residents (@binWdgt?.empty() /
    # @shelfWdgt?.empty()); this destroys the containers themselves.
    @hand._fullDestroyNoSettle()
    @binWdgt?._fullDestroyNoSettle()
    @shelfWdgt?._fullDestroyNoSettle()
    # ...and then hold no reference to what was just destroyed — the same seam contract the shared
    # teardown core keeps for the tree.
    @hand = undefined
    @binWdgt = undefined
    @shelfWdgt = undefined
    # (c) THE WORLD LEAVES ITS OWN CLASS CHAIN'S `instances` SETS. This is also the line that arms
    # the collectibility oracle for free: `fg vmtruth`'s prelude records a WeakRef at exactly this
    # seam and asserts, one teardown later, that the VM was allowed to let the object go.
    @unregisterThisInstance()
    # (d) EVERY REPLACEMENT IS WorldWdgt#1, exactly as this one was — world identity carries no run
    # history, and no drawn label shifts because a page has reset a few hundred times (Widget.toString
    # -> uniqueIDString is DRAWN in re-parent menu rows, wire labels, pinouts and the inspector).
    # ⚠ It is zeroed HERE and not in fullDestroyChildren's per-class sweep (which skips WorldWdgt)
    # because this is the one place a world is actually REPLACED. loadWorldSnapshot shares that
    # sweep and keeps its LIVE world, whose id must stay the one it was issued — and a snapshot
    # carries no WorldWdgt counter to restore it from (Serializer.collectIdCounters skips it too).
    WorldWdgt.lastBuiltInstanceNumericID = 0
    # (e) ...and a world that has been replaced READS as destroyed, like any other widget that has
    # been torn down. It matters to the liveness instruments rather than to the framework: the
    # registry cross-check in scripts/heap-forensics.js separates a VM-alive CORPSE (destroyed, out
    # of the registry — a retention to hunt) from a REGISTRATION HOLE (alive, never registered — a
    # bug in the meta-system) by exactly this flag, so a dissolved world that left `destroyed`
    # false would be filed as the second and send the reader looking for the wrong defect.
    @destroyed = true
    # (f) THE PAGE-LIFETIME COLD-GLYPH STORE, AGAIN. The shared teardown core already ran this filter,
    # but it runs it as ITS last act — and dissolution is a FOURTH destroy phase behind it, so at that
    # point the hand, the two containers and this world were all still `destroyed == false` and every
    # one of them survived the pass. The filter keys on `destroyed`, which is only true for them HERE.
    # Both calls are needed and neither is redundant: the core's covers the tree (and is the only one
    # loadWorldSnapshot gets, since that path keeps its world and never dissolves), this one covers
    # the four the core cannot yet see. Idempotent — it rebuilds the array from a predicate.
    window.swCanvasDropDestroyedColdGlyphEntriesForTeardown?()
    # (g) MY OWN DAMAGE QUEUES, for the same reason and at the same seam. The shared core filters
    # destroyed entries out of them as ITS last act, and destruction RE-MARKS a dying widget (it
    # posts damage so its pixels get erased) — so the hand, the containers and their subtrees, all
    # destroyed above, marked their way back in after that filter had already run. EMPTIED rather
    # than filtered: a dissolved world never repaints, so nothing in here is owed to anyone, and the
    # queues are exactly the "no reference to anything just destroyed" the lines above promise.
    # ⭐ It is also what keeps a future finding HONEST. These collections are the only edges from a
    # world to the off-tree containers that survive @binWdgt = undefined, so while they stand,
    # anything retaining a dissolved world transitively retains its whole bin subtree — measured
    # with a planted closure over one world: 8 worlds and 72 widgets reported, every widget reached
    # ONLY through one of these queues. One defect, ten lines of findings.
    # ⚠ ALL of them, not the ones that happened to show up in a retainer path: the paint queues and
    # the layout queue were each found this way in turn, and enumerating "the ones that bite" is how
    # the next one gets missed. Every widget collection the world owns is reset to its empty shape.
    @widgetsToBeHighlighted = new Map
    @widgetsBeingHighlighted = new Set
    @steppingWdgts = new Set
    @widgetsReferencingOtherWidgets = new Set
    @widgetsGivingErrorWhileRepainting = []
    @widgetsWithMaybeChangedPaintBounds = []
    @widgetsWithMaybeChangedFullPaintBounds = []
    @widgetsThatMaybeChangedLayout = []
    # (h) LAST: from here on I am a corpse, and the two damage funnels below drop everything I try
    # to mark — see the _changed / _fullChanged overrides.
    @_dissolved = true

  # A DISSOLVED WORLD MARKS NO DAMAGE. Every damage funnel routes its mark through the `world`
  # GLOBAL (Widget._changed pushes onto world.widgetsWithMaybeChangedPaintBounds, Widget._fullChanged
  # onto world.widgetsWithMaybeChangedFullPaintBounds) — so a mark made by a corpse AFTER the swap
  # would land a destroyed widget (this one) in the LIVE world's per-cycle queues, which is exactly
  # what the object-lifetime audit calls a zombie: the new world would then walk a dead world's
  # geometry on its way to paint.
  # This is the SECOND lock on that door, not the first — nothing pumps a corpse, because doOneCycle
  # returns at its dissolution seam and the animation loop reads the global. Both are cheap and the
  # failure they prevent is silent, so both stay.
  _changed: ->
    return if @_dissolved
    super

  _fullChanged: ->
    return if @_dissolved
    super

  # --- THE SHARED STRUCTURAL TEARDOWN ----------------------------------------------------------
  # ONE core, two callers: resetWorld (which dissolves this world after it returns and constructs
  # the replacement) and loadWorldSnapshot (which KEEPS this world and refills it from the file).
  # It discharges TWO obligations. They have different lifetimes, different failure modes and
  # different gates, so a line added here belongs to one of them and should say which:
  #
  #   (A) THE WORLD DROPS EVERY REFERENCE TO WHAT fullDestroyChildren() JUST DESTROYED, and every
  #       piece of bookkeeping that assumed it still exists. Only observable where the world
  #       SURVIVES, so loadWorldSnapshot is the enforcer and world.teardownHygiene.* in
  #       ../Fizzygum-tests/scripts/serialization-roundtrip-headless.js is the measurement. On the
  #       resetWorld path these are free — that world is dissolved and, per fg vmtruth's
  #       reachability gate, unreachable — which is not the same as optional: the OTHER caller has
  #       no reconstruction to hide behind, and this is the half that rots if anyone forgets that.
  #
  #   (B) PAGE-LIFETIME STATE LETS GO OF WHAT WAS JUST DESTROYED. Class statics, class-level timer
  #       registries and module-level stores outlive every world the page builds, so discarding a
  #       world does not touch them: (B) is owed on BOTH paths, and a miss pins a corpse for the
  #       life of the page rather than merely dangling inside one world. The object-lifetime tier
  #       enforces it — the WORLD_INVENTORY_* audits and fg vmtruth. There are three (B) items
  #       below, each marked at its line.
  #
  # Each obligation has a plant that proves it is load-bearing where it claims to be. Removing
  # `@errorConsole = undefined` leaves a 3-test reset sequence green and fails the snapshot rig on
  # teardownHygiene.noDanglingSlots; removing `WorldWdgt.timeOfEventBeingProcessed = undefined`
  # fails the RESET path with WORLD_INVENTORY_DRIFT, even though that world is discarded a phase
  # later. Neither result is reachable by reading the contract — measure before trusting either.
  #
  # Restoring what the world should LOOK like afterwards is the CALLER's business, and since Arc C
  # the two answer it differently: resetWorld restores nothing at all, because its replacement is
  # born correct; the loader paints the file's contents back on. That split is what lets one core
  # serve both.
  #
  # WHY IT IS SHARED RATHER THAN MIRRORED. fullDestroyChildren() is what creates the dangling
  # references, and both callers run it — but neither caller's name said "and I am responsible for
  # the dangling refs", so the obligation kept being satisfied on one path and forgotten on the
  # other. The two drifted twice in two days, in OPPOSITE directions. A shared core makes "did the
  # other teardown get this too?" un-askable, which is the point; hand-synchronised twins are what
  # this replaces. It SHIPS in every profile — it is `core`-part code, and loadWorldSnapshot is a
  # product feature — whereas the harness's own seats at this reset travel with the `harness` part
  # (../Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee), so a test-only verb
  # could never have been the shared one. Every (A) leak below was measured surviving a real
  # loadWorldSnapshot, not argued.
  #
  # NoSettle tier: BOTH callers already wrap this in exactly ONE @_settleLayoutsAfter, so no
  # self-settling public setter may move in here. The loader calls setColor / wallpaper setPattern
  # OUTSIDE its settle wrap on purpose, and resetWorld needs neither — it builds a fresh world
  # rather than repainting this one. Mixing tiers here is how the flow-violation throw gets
  # reintroduced.
  _teardownWorldStructureNoSettle: ->
    # destroys the widget TREE and zeroes every per-class lastBuiltInstanceNumericID, giving the
    # clean id space a snapshot's restored iids need. Everything after it exists because it CANNOT
    # reach world-level state held outside the tree.
    @fullDestroyChildren()
    # EPHEMERAL-OVERLAY bookkeeping is world-level state NOT held in the widget tree, so
    # fullDestroyChildren above (which destroys the reconciled highlighter WIDGETS as world children
    # / island descendants) does NOT empty these declare/current/being structures — they keep DEAD
    # references to the just-destroyed targets + overlays. Tearing down with a highlight still active
    # (e.g. nothing ever called turnOffHighlight) leaks those dead refs into whatever comes next, and
    # the reconciler (addHighlightingWidgets) then touches a destroyed target and mis-renders. Found
    # via the R2 highlight-tracking test, which deliberately leaves its highlight on to exercise this.
    # On the LOAD path it is worse than a dead ref: with the declaration surviving, the next cycle's
    # reconciler RE-MATERIALISES a HighlighterWdgt as a world child, so the restored desktop carries
    # a widget the snapshot file does not contain (measured 2026-07-29).
    @widgetsToBeHighlighted.clear()
    @currentHighlightingWidgets.clear()
    @widgetsBeingHighlighted.clear()
    @pinouts?.reset()
    # ...and the PINOUT twins of those three, which mirror them exactly. These used to be barred from
    # this core: the sets were declared inside `»>>` markers, so in a product build the fields did not
    # exist and clearing them threw — the strip boundary drew the seam, and the clears had to live with
    # the test-only caller. Arc 3 re-homed pinouts into the optional PinoutsOverlay collaborator, so the
    # soak below is correct in EVERY build (no overlay ⇒ nothing to reset) and the seam is gone.
    # the editor-focus selection is world-level state NOT held as tracked-tree bookkeeping: it is a bare
    # ref to a selected widget (which fullDestroyChildren above tears down), so just drop the dangling ref.
    # editorFocusWdgt itself is cleared in _softResetWorld, so the PULL update would compute undefined next cycle
    # regardless; the selected widget's own repaint clears its overlay.
    @_editorSelectedWidget = undefined
    # DANGLING WORLD SLOTS. These are bare world fields holding a widget that fullDestroyChildren
    # above just destroyed, so each would keep a DEAD reference into the next test (or, on the load
    # path, into the rest of the session). StorageSorter's furniture marking reads world[slot] and
    # simpleEditorTemplates unconditionally, so a dead ref there is walked every sort. The loader
    # re-binds both from the snapshot afterwards (step 6), which is exactly the teardown-empties /
    # caller-fills split this core is built on.
    @[slot] = undefined for slot in Serializer.WORLD_APP_SLOTS
    @simpleEditorTemplates = undefined
    # the error console is worse than a dead ref: _showErrorsHappenedInRepaintingStepInPreviousCycle
    # only builds one `if !@errorConsole?`, so a destroyed-but-non-undefined console makes every later
    # paint error in the page report into a dead widget -- silently swallowing the errors the
    # headless runners' fail-gate exists to catch. For a real user past a snapshot load, it silently
    # swallows every paint error for the rest of the session.
    @errorConsole = undefined
    # the last text the user edited (used by the document editor's align ops) -- a bare ref to a
    # widget fullDestroyChildren just destroyed.
    @lastEditedText = undefined
    # EPHEMERAL WORLD-LEVEL COLLECTIONS, same shape as the highlight/pinout sets above: none is
    # emptied by fullDestroyChildren (they are world state, not tree state) and none is emptied by
    # Widget._destroyNoSettle (which only unregisters from steppingWdgts / keyboardEventsReceivers /
    # the click-outside set -- world-level collections are outside its remit). So tearing down
    # with a tooltip up, a menu open, handles shown, or a scroll still gliding leaks dead refs into
    # whatever comes next -- the next test in the same headless process, or the loaded desktop.
    #   toolTipsList              destroyToolTips would then read bounds off a destroyed tooltip
    #   openPopUps / freshlyCreatedPopUps  mostRecentlyCreatedPopUp and the macro toolkit's
    #                             "the pop-up that just opened" both pick out of these
    #   popUpsMarkedForClosure    the next drain would close() an already-destroyed pop-up
    #   hierarchyOfClicked*       stale gesture bookkeeping (cleared per click, not per teardown)
    #   temporaryHandles...       dead resize/move handles
    #   wdgtsWithOngoingScrollMomentum  the worst: anyScrollMomentumOngoing() stays true FOREVER,
    #                             so the macro pump's waitNoInputsOngoing never settles and every
    #                             later test in the page STALLS rather than fails
    @toolTipsList.clear()
    # ...and the tooltips not yet BORN. ⭐ OBLIGATION (B): the pending timers live in a CLASS-level
    # set (ToolTipWdgt.ongoingTimeouts), which outlives every world the page builds, so unlike the
    # list above this is owed on the resetWorld path too — discarding the world cancels nothing. A
    # scheduled creation timer closes over the widget that invited it, so clearing the list above
    # (which only knows tips already open) leaves the corpse pinned until the timer fires -- and it
    # then aims a fresh tip at a destroyed widget. ToolTipWdgt is core, so no existence soak;
    # cancelling with nothing pending is a no-op.
    ToolTipWdgt.cancelAllScheduledToolTips()
    @openPopUps.clear()
    @freshlyCreatedPopUps.clear()
    @popUpsMarkedForClosure.clear()
    @hierarchyOfClickedWdgts.clear()
    @hierarchyOfClickedMenus.clear()
    @temporaryHandlesAndLayoutAdjusters.clear()
    @wdgtsWithOngoingScrollMomentum.clear()
    @pendingFractionalBookkeepingSeeds.clear()
    @pendingFractionalReRecords.clear()
    # ...and the drag-embed affordances, which are the same bug in a shape the list above does not
    # cover: the three *Declared records name the widget being dragged over, and the three *Wdgt
    # slots name overlays that ARE tree children, so fullDestroyChildren destroys them and leaves
    # every slot pointing at a corpse. The reconciler (addDragAffordanceWidgets) reads exactly
    # these six: a surviving declaration with a destroyed overlay makes it call
    # updateChargeDeclaration on the corpse, and a cleared declaration with a surviving slot makes
    # it fullDestroy() something already destroyed. Clearing the declarations alone is NOT enough --
    # the slots are what the reconciler tests for existence.
    # ⚠ This restores a CONTRACT; it is not a bug fix, and the difference is worth stating so nobody
    # re-derives it as a symptom. Three things narrow it: the hand rewrites all three declarations
    # every cycle it processes and clears them in its else-branch, so outside an in-flight drag all
    # six are already undefined; on the resetWorld path the world holding any corpses is itself
    # discarded a phase later; and even after a load-during-a-drag the next cycle SELF-HEALS (the
    # hand clears the declarations, then the reconciler destroys and nulls the overlay slots). What
    # is left is a real violation of the core's unconditional promise, observable in the window
    # between the teardown returning and the next cycle -- which is exactly where
    # world.teardownHygiene.dragAffordancesCleared reads it, because measured any later the
    # assertion passes with this clearing removed and is therefore vacuous.
    @dragEmbedChargeRingDeclared = undefined
    @dragEmbedLabelDeclared = undefined
    @dragEmbedLockBadgeDeclared = undefined
    @dragEmbedChargeRingWdgt = undefined
    @dragEmbedLabelWdgt = undefined
    @dragEmbedLockBadgeWdgt = undefined
    # paint-error bookkeeping: errorsWhileRepainting is re-emptied every paint, but its companion
    # list never was, so it accumulated dead widgets for the whole life of the page.
    @widgetsGivingErrorWhileRepainting = []
    # the current-event time register (the event-time clock the input consumers read --
    # multi-click staleness, the drag-charging ring's linger): between events it is stale
    # by definition, and across a teardown the next world's event clock may even REWIND
    # (synthetic test clocks restart) -- back to the declared "no event being processed"
    # default. ⭐ OBLIGATION (B): a world STATIC, so it survives the world being discarded and is
    # owed on both paths. The world-field ratchet cannot see it (it reads world FIELDS); the
    # inventory audit is what catches it drifting, and removing this line fires
    # WORLD_INVENTORY_DRIFT on the reset path.
    WorldWdgt.timeOfEventBeingProcessed = undefined
    # the HAND's gesture bookkeeping: the hand itself survives this teardown, so its
    # grab/press/drag-embed fields and armed multi-click records would keep DEAD
    # references to widgets fullDestroyChildren just destroyed -- and with the event
    # clock rewinding (above), a stale armed record could even RECOGNIZE a multi-click
    # across worlds. One verb owns the family (see its comment).
    @hand._forgetGestureBookkeepingNoSettle()
    # the damage-suppression depth: direct tampering (the serialization rig does it
    # deliberately) leaves it nonzero, and Widget._changed() drops marks while it is —
    # so a stuck depth means damage stops being recorded and the world stops repainting.
    # It is not serialized and not restored by the loader, so re-zeroing it is the only
    # thing that can put a loaded world back on its feet (the _repaintDamagedRects tripwire
    # heals mid-life corruption the same way).
    @_damageSuppressionDepth = 0
    # the one-shot "this info doc was already created" flags (InfoDocs.REGISTRY entries, set as
    # plain own booleans on the world): once set, InfoDocs.createNextTo early-returns, so the SAME
    # app launch silently builds NO info doc. Collected first, then deleted -- deleting while
    # iterating own props is not safe.
    # The loader's restore is ADDITIVE ONLY (`@[name] = val for own name, val of section.infoDocFlags`
    # -- it never deletes a flag the live world has and the file lacks), so without this clear a flag
    # set before a load would survive it FOREVER and that info doc could never be created again in
    # the loaded world. Teardown empties, loader fills.
    infoDocFlagNames = (name for own name of @ when name.indexOf("infoDoc") is 0)
    delete @[name] for name in infoDocFlagNames
    # the storage containers (bin, shelf) are not attached
    # to the world tree so they're not in the children,
    # so we need to clean them up separately
    @binWdgt?.empty()
    @shelfWdgt?.empty()
    # the SWCanvas cold-glyph store holds LIVE WIDGET REFS between a cold placeholder draw and the
    # atlas-warm refresh that drains it. ⭐ OBLIGATION (B): a module-level array outside the world
    # entirely, so nothing above can have emptied it, discarding the world does not empty it either,
    # and on a page whose atlases are all warm the drain may never come.
    # It sits BESIDE the damage-queue filter below rather than after it: both must
    # follow every destroy (the bin/shelf empties directly above included), but unlike the damage
    # queues this store feeds no repaint the reset caller is depending on, so their ordering
    # constraint neither reaches it nor is disturbed by it. Soaked because it is a boot-bundle
    # facility, reached the same way anyTextDirty reaches swCanvasAnyTextDirty.
    # ⚠ This pass covers the TREE, which is everything this core destroys — but it is not the last
    # word on the reset path: _dissolveWorldNoSettle destroys the hand, the two containers and the
    # world itself AFTER this returns, so those four are still `destroyed == false` right here and
    # survive the filter. Dissolution runs it a second time, once they are corpses. The load path
    # keeps its world and never dissolves, so for loadWorldSnapshot this call IS the whole story.
    window.swCanvasDropDestroyedColdGlyphEntriesForTeardown?()
    # the per-cycle damage queues (drained by the next _repaintDamagedRects) still hold
    # widgets destroyed above -- and destruction itself RE-MARKS them (a dying widget posts
    # damage so its pixels get erased), so this filter must be the teardown's LAST act,
    # after the bin/shelf empties directly above have destroyed their residents too. The
    # seam contract ("no reference to anything just destroyed") wants the dead entries gone
    # NOW, not next frame. A filter, not a clear, because a SURVIVING widget's pending damage is
    # still owed a repaint: on the load path the restored desktop is painted from marks made after
    # this, but anything the teardown did not destroy keeps whatever it had queued. (The reset path
    # does not depend on that -- this world is about to be dissolved, and the world that replaces it
    # marks its own whole screen in its constructor.)
    @widgetsWithMaybeChangedPaintBounds = (w for w in @widgetsWithMaybeChangedPaintBounds when !w.destroyed)
    @widgetsWithMaybeChangedFullPaintBounds = (w for w in @widgetsWithMaybeChangedFullPaintBounds when !w.destroyed)
    # the currently-painting register: nothing is painting at this seam, but the paint
    # loop's ERROR path can leave the last (possibly just-destroyed) painter here -- a
    # dead ref the seam contract forbids.
    @paintingWidget = undefined

  # ONE desktop menu, with no fork on which HTML file booted the world. What a desktop can offer
  # does not depend on the page: it depends on which PARTS shipped and whether dev mode is on, and
  # both of those are asked directly below, per item, where they are true facts about capability.
  #   ⚠ `isIndexPage` is false ONLY on the test harness, so a fork on it is a fork between "the
  # product" and "the tests" — a distinction the menu has no business drawing. It also compounded
  # rather than composed with the dev-mode gate: the six items its own comment called
  # "unconditional now, so the homepage gains them" sat inside `if @isDevMode` AND behind the
  # fork's early return, so a product desktop offered four rows, gained nothing from dev mode, and
  # had no row with which to turn dev mode on in the first place.
  #   ⚠ The per-item guards are deliberate rather than one contributor list appended at the end,
  # because the items INTERLEAVE (the demo tree before inspect, the test menu straight after it)
  # and a single append point cannot reproduce that order.
  buildContextMenu: ->

    # ⚠ the title is computed into a local FIRST. An `if` expression written directly as an
    # implicit-object value on its own line does not become that value — the menu comes out
    # title-less, which costs it its whole title bar, and with it the thing you click to
    # drag the menu and the thing you click to pin it.
    title = if @isDevMode
      @constructor.name or @constructor.toString().split(" ")[1].split("(")[0]
    else
      "Desktop"
    menu = new MenuWdgt @, target: @, title: title

    # DEV ONLY — the demo tree, and the bulk operations that reach every widget in the world.
    # `world.parts.isAvailable "demos"` is false in a production build, so those two are not
    # offered there even with dev mode on: the part gate is about what SHIPPED, the dev gate about
    # what is being SHOWN, and an item can need both.
    if @isDevMode
      menu.addMenuItem "demo ➜", @, "popUpDemoMenu", closesUnpinnedPopUps: false, toolTip: "sample widgets"  if world.parts.isAvailable "demos"
      menu.addLine()
      menu.addMenuItem "delete all", @, "closeChildren"
      menu.addMenuItem "move all inside", @, "keepAllSubwidgetsWithin", toolTip: "keep all subwidgets\nwithin and visible"

    # EVERY DESKTOP — look at it, size it, colour it, paper it, and say how you are driving it.
    # None of these is a developer's tool: they are what owning a desktop means.
    menu.addMenuItem "inspect", @, "inspect", toolTip: "open a window on\nall properties"
    menu.addMenuItem "test menu ➜", @, "popUpDemoTestMenu", closesUnpinnedPopUps: false, toolTip: "debugging and testing operations"  if @isDevMode and world.parts.isAvailable "demos"
    menu.addLine()
    menu.addMenuItem "fit whole page", @, "stretchWorldToFillEntirePage", toolTip: "let the World automatically\nadjust to browser resizings"
    menu.addMenuItem "color...", @, "popUpColorSetter", toolTip: "choose the World's\nbackground color"
    menu.addMenuItem "wallpapers ➜", @wallpaper, "wallpapersMenu", closesUnpinnedPopUps: false, toolTip: "choose a wallpaper for the Desktop"

    # ONE row that SHOWS the current input mode, rather than two rows chosen by an `if` at
    # build time: its wording is a view of the value, so it follows a toggle made anywhere —
    # in another open world menu, or by a script. The tooltip says what the row DOES (it is the
    # same act either way), so it does not need to reflect anything.
    menu.addMenuItem "touch screen settings", WorldWdgt.preferencesAndSettings, "toggleInputMode",
      toolTip: "switch between standard and\ntouch-screen menu fonts and sliders"
      reflection: new MenuRowReflectionSpec WorldWdgt.preferencesAndSettings, "currentInputMode",
        whenValue: PreferencesAndSettings.INPUT_MODE_MOUSE
        labelWhenTrue: "touch screen settings"
        labelWhenFalse: "standard settings"
    menu.addLine()

    if Automator?
      menu.addMenuItem "system tests ➜", @, "popUpSystemTestsMenu", closesUnpinnedPopUps: false, toolTip: ""

    # the door, and it swings both ways from every page — a desktop that cannot be switched INTO
    # dev mode is a desktop whose developer affordances do not exist
    if @isDevMode
      menu.addMenuItem "switch to user mode", @, "toggleDevMode", toolTip: "disable developers'\ncontext menus"
    else
      menu.addMenuItem "switch to dev mode", @, "toggleDevMode"

    menu.addMenuItem "new folder", @, "makeFolderFromMenu"
    menu.addMenuItem "save world snapshot…", @, "saveWorldSnapshotToFile", toolTip: "save the whole desktop\nto a *.fzw.json file"
    menu.addMenuItem "open from file…", @, "openFromFile", toolTip: "load a widget or world\nfrom a *.fzw.json file"
    menu



  create: (aWdgt) ->
    aWdgt.pickUp()

  # Wrap a content widget in a window, size and place it, add it to the world --
  # the windowed sibling of `create`. Returns the window. The single home for the
  # "fresh window" wrap (windowed apps' buildWindow, demoMenus' window demos, the
  # inspector/console/prompt spawners). Titled / _applyExtent windows build directly.
  # A framed CITIZEN (a FrameWdgt subclass that IS its own window -- Frame-model
  # plan §5.B) passes through un-wrapped: it is sized and placed directly.
  openFrameWith: (contentWidget, extent, position) ->
    if contentWidget.isFrame?()
      wm = contentWidget
    else
      wm = new FrameWdgt contentWidget
    wm.setExtent extent
    wm._applyMoveTo position
    wm._moveWithin @
    @add wm
    wm

  # The demo/parts-bin menu and the layout-tests menu. They stay on the WORLD (not in DemoMenus)
  # because they are bound as world ACTIONS: the world menu names them on `@`, and a SystemTest
  # builds a MenuItemWdgt wired to (world, "popUpDemoMenu") to exercise button float-drag
  # semantics. Their CONTENT is what is dev-only, and it is reached through @widgetFactory /
  # demoMenus, both absent from a production build -- where nothing links here either, since
  # the world menu offers "demo ➜" only when DemoMenus ships.
  # ONE catalogue (arc 3 phase 7). This forked on isIndexPage too — a short "parts bin" on the
  # product page and a long "make a widget" on the harness page — so the two disagreed both on
  # WHICH widgets you could make and on whether a palette arrived bare or wrapped in a window.
  # The union below keeps every distinct item from both; the window-wrapped palettes keep an
  # explicit label rather than silently replacing the bare ones.
  # The one item of the demo menu that reaches the LAZY `demos` part, routed through core so the
  # menu itself can still be BUILT synchronously -- the menu's other items are all widgetFactory's,
  # and offering "demo ➜" only says the part is available, never that it has arrived. Deferring the
  # whole popUpDemoMenu instead would move every item a world cycle later for the sake of one.
  # ⚠ The delegate is `demoMenus.analogClock`, which is a one-liner over the CORE AnalogClockWdgt --
  # so this awaits the part for the sake of where the method lives, not what it builds. If the demo
  # menu is ever reorganised, this item wants to become a plain widgetFactory entry and lose the
  # await entirely.
  createDemoAnalogClock: ->
    world.parts.whenAllLoaded ["demos"], ->
      window.demoMenus ?= new (window["DemoMenus"])
      window.demoMenus.analogClock()

  # THE DOOR into the demo family's "test menu", from the world menu AND from any widget's context
  # menu. `demos` is a LAZY part, so three things have to be true here and none is the obvious one:
  #
  # ⚠ 1. The menu ITEM's visibility asks `world.parts.isAvailable "demos"`, never `if DemoMenus?`.
  # For a lazy part an undefined class means BOTH "this artifact never shipped it" and "nobody has
  # fetched it yet", and those want opposite answers -- hide the entry forever, versus offer it and
  # fetch on click. Only the part-level question separates them.
  #
  # ⚠ 2. The item's target is `world`, not the widget and not the `demoMenus` singleton. The menu
  # binds its target when the menu is BUILT and on a lazy build there is no singleton yet to bind;
  # and it lives on WorldWdgt rather than Widget because a public member on Widget's prototype is
  # listed by every inspector, which churns the inspector-list references (measured: it failed
  # SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly, whose fixture is a RectangleWdgt).
  # The widget being inspected arrives through the ARGUMENTS instead.
  #
  # ⚠ 3. The singleton is built HERE on first use, naming the class as DATA (`window["DemoMenus"]`)
  # -- the check-part-edges blind spot that exists for exactly this. On a page that forces every
  # part eager (the harness, index-sw.html) startWorld already built it, whenAllLoaded runs inline,
  # and this whole path stays byte-identical to what the suite has always measured.
  popUpDemoTestMenu: (widgetOpeningThePopUp, targetWidget) ->
    world.parts.whenAllLoaded ["demos"], ->
      # door-callback law (PartsRegistry's header): both subjects can die during the fetch,
      # and a menu built for a corpse dispatches its every row at a destroyed widget
      return if widgetOpeningThePopUp?.destroyed or targetWidget?.destroyed
      window.demoMenus ?= new (window["DemoMenus"])
      window.demoMenus.testMenu widgetOpeningThePopUp, targetWidget

  popUpDemoMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "make a widget"
    menu.addMenuItem "rectangle", @widgetFactory, "createNewRectangleWdgt"
    menu.addMenuItem "box", @widgetFactory, "createNewBoxWdgt"
    menu.addMenuItem "circle box", @widgetFactory, "createNewCircleBoxWdgt"
    menu.addLine()
    menu.addMenuItem "slider", @widgetFactory, "createNewSliderWdgt"
    menu.addMenuItem "panel", @widgetFactory, "createNewPanelWdgt"
    menu.addMenuItem "viewport", @widgetFactory, "createNewViewportWdgt"
    menu.addMenuItem "canvas", @widgetFactory, "createNewCanvas"
    menu.addMenuItem "handle", @widgetFactory, "createNewHandle"
    menu.addLine()
    menu.addMenuItem "string", @widgetFactory, "createNewString"
    menu.addMenuItem "text", @widgetFactory, "createNewText"
    menu.addMenuItem "tool tip", @widgetFactory, "createNewToolTipWdgt"
    menu.addMenuItem "speech bubble", @widgetFactory, "createNewSpeechBubbleWdgt"
    menu.addLine()
    menu.addMenuItem "gray scale palette", @widgetFactory, "createNewGrayPaletteWdgt"
    menu.addMenuItem "color palette", @widgetFactory, "createNewColorPaletteWdgt"
    menu.addMenuItem "color picker", @widgetFactory, "createNewColorPickerWdgt"
    menu.addMenuItem "gray scale palette in window", @widgetFactory, "createNewGrayPaletteWdgtInWindow"
    menu.addMenuItem "color palette in window", @widgetFactory, "createNewColorPaletteWdgtInWindow"
    menu.addLine()
    menu.addMenuItem "analog clock", @, "createDemoAnalogClock"
    menu.addMenuItem "animation demo", @widgetFactory, "createNewAnimationDemo"
    menu.addMenuItem "pen", @widgetFactory, "createNewPenWdgt"

    menu.addLine()
    menu.addMenuItem "layout tests ➜", @, "layoutTestsMenu", closesUnpinnedPopUps: false, toolTip: "sample widgets"
    menu.addLine()
    menu.addMenuItem "under the carpet", @widgetFactory, "underTheCarpet"

    menu.popUpAtHand()

  layoutTestsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Layout tests"
    menu.addMenuItem "adjuster widget", @widgetFactory, "createNewStackElementsSizeAdjustingWdgt"
    menu.addMenuItem "adder/droplet", @widgetFactory, "createNewLayoutElementAdderOrDropletWdgt"
    menu.addMenuItem "test screen 1", @widgetFactory, "setupTestScreen1"
    menu.popUpAtHand()
    
  
  toggleDevMode: ->
    @isDevMode = not @isDevMode

  
  # edit self-settles via the public add / fullDestroy (EACH opens its own settle) exactly as it always has --
  # every event-time editing caller (inspectors, text fields) depends on that unchanged timing. _editNoSettle
  # shares the IDENTICAL caret-teardown-and-creation body via a strategy thunk (the _stopEditingTearingCaretDownWith
  # pattern below), but routes it through the NON-settling _fullDestroyNoSettle / _addNoSettle for a caller ALREADY
  # inside a layout flush/pass -- a dataflow connection sink delivering into a prompt slider's editable field
  # (PromptWdgt._takeSliderValueConnector -> StringWdgt._editNoSettle), where the public self-settling add /
  # fullDestroy would throw the flow-rule (Widget._settleLayoutsAfter's re-entrancy throw).
  # thin-wrap-exempt: shares its body with _editNoSettle via a teardown/add-strategy thunk -- NOT the bare
  # @_settleLayoutsAfter => @_editNoSettle wrap.
  edit: (aStringWidgetOrTextWidget) ->
    @_editTearingAndAddingCaretWith aStringWidgetOrTextWidget,
      ((caret) -> caret.fullDestroy()),
      ((parent, caret) -> parent.add caret)

  _editNoSettle: (aStringWidgetOrTextWidget) ->
    @_editTearingAndAddingCaretWith aStringWidgetOrTextWidget,
      ((caret) -> caret._fullDestroyNoSettle()),
      ((parent, caret) -> parent._addNoSettle caret)

  _editTearingAndAddingCaretWith: (aStringWidgetOrTextWidget, tearDownCaret, addCaret) ->
    # first off, if the Widget is not editable
    # then there is nothing to do
    # return undefined  unless aStringWidgetOrTextWidget.isEditable

    # there is only one caret in the World, so destroy
    # the previous one if there was one.
    if @caret
      # empty the previously ongoing selection
      # if there was one.
      previouslyEditedText = @lastEditedText
      @lastEditedText = @caret.target
      if @lastEditedText != previouslyEditedText
        @lastEditedText.clearSelection()
      @caret = tearDownCaret @caret

    # create the new Caret
    @caret = new CaretWdgt aStringWidgetOrTextWidget
    addCaret aStringWidgetOrTextWidget.parent, @caret
    # the only place where the caret is added to the keyboardEventsReceivers
    @keyboardEventsReceivers.add @caret

    if WorldWdgt.preferencesAndSettings.isTouchDevice and WorldWdgt.preferencesAndSettings.useVirtualKeyboard
      @_initVirtualKeyboard()
      # For touch devices, giving focus on the textbox causes
      # the keyboard to slide up, and since the page viewport
      # shrinks, the page is scrolled to where the texbox is.
      # So, it is important to position the textbox around
      # where the caret is, so that the changed text is going to
      # be visible rather than out of the viewport.
      pos = @getCanvasPosition()
      @inputDOMElementForVirtualKeyboard.style.top = @caret.top() + pos.y + "px"
      @inputDOMElementForVirtualKeyboard.style.left = @caret.left() + pos.x + "px"
      @inputDOMElementForVirtualKeyboard.focus()
    
    # Widgetic.js provides the "slide" method but I must have lost it
    # in the way, so commenting this out for the time being
    #
    #if WorldWdgt.preferencesAndSettings.useSliderForInput
    #  if !aStringWidgetOrTextWidget.parentThatIsA MenuWdgt
    #    @slide aStringWidgetOrTextWidget
  
  # Editing can stop because of three reasons:
  #   cancel (user hits ESC)
  #   accept (on string widget, user hits enter)
  #   user clicks/floatDrags another widget
  # Tearing the caret down re-fits the text it was editing, so stopEditing self-settles -- but ONLY
  # when there is a caret (no caret -> no geometry change -> no flush). The public method tears the
  # caret down via fullDestroy (which self-settles); _stopEditingNoSettle tears it down via the
  # non-settling _fullDestroyNoSettle, for callers already inside a layout flush (Widget._destroyNoSettle
  # stopping editing while it destroys a widget that contains the caret). Both share the body below.
  # thin-wrap-exempt: CONDITIONAL self-settle (only when a caret exists), shared with _stopEditingNoSettle
  # via a teardown-strategy thunk -- not the bare @_settleLayoutsAfter => @_stopEditingNoSettle wrap.
  stopEditing: ->
    @_stopEditingTearingCaretDownWith (caret) -> caret.fullDestroy()

  _stopEditingNoSettle: ->
    @_stopEditingTearingCaretDownWith (caret) -> caret._fullDestroyNoSettle()

  _stopEditingTearingCaretDownWith: (tearDownCaret) ->
    if @caret
      @lastEditedText = @caret.target
      @lastEditedText.clearSelection()
      @caret = tearDownCaret @caret

    # the only place where the caret is removed from the keyboardEventsReceivers
    # (and the hidden input is removed)
    @keyboardEventsReceivers.delete @caret
    if @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard.blur()
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = undefined
    @worldCanvas.focus()

  # Chokepoint mark for the eager storage sort (StorageSorter): called after
  # any event that may change which storage container a widget belongs in --
  # the reference tracker's mutations, wire add / un-wire / wire-holder death
  # (liveness follows wires too -- graph-edges plan §4.3), close filing,
  # arrivals into/departures from an open bin window, app-slot writes,
  # snapshot restore. Mark-only and O(1), so it is safe inside bulk destroy
  # storms; the sort itself drains once per cycle in doOneCycle.
  noteStorageMembershipMayHaveChanged: ->
    @storageSorter.noteMembershipMayHaveChanged()

  # Is any liveness edge -- a REFERENCE or a declared WIRE (flow), the same two
  # kinds that confer reachability in the storage classifier (graph-edges plan
  # §4.3, decisions G5/G8 there) -- aimed at this widget or anything inside it,
  # from OUTSIDE it? The close paths ask this to decide park-vs-destroy: an
  # inbound edge means something out there can still reach me, so park (the
  # storage drain then shelves whatever stays reachable). Internal wiring (a
  # window's own scrollbars track its panels) must not count, hence the
  # outside-the-figure test; and edges held by storage residents DO count --
  # the holder itself resting in the bin only means the rescue is one step
  # further away.
  # A tree walk, not an index read: wires live on each controller's own @wires
  # list and the engine index is derived lazily, so only the walk answers
  # completely. O(everything widget-bearing), and close is a user gesture, so
  # that is fine.
  anyReferenceOrWireIntoWdgt: (whichWdgt) ->
    @_livenessEdgesIntoWdgt(whichWdgt).length > 0

  # THE one enumeration of the world's liveness roots — shared by the trash-liveness
  # query/sever pair below AND the WorldInventory's containment reachability, so trash
  # logic and leak accounting structurally cannot disagree about what a root is. Note the
  # bin and shelf CONTAINERS are deliberately not roots (residency in the bin must not
  # read as an inbound edge) while their RESIDENTS are; an accounting consumer that must
  # also reach the containers' own chrome appends them itself (WorldInventory does).
  graphLivenessRoots: ->
    roots = [@, @hand]
    for slot in Serializer.WORLD_APP_SLOTS
      roots.push @[slot] if @[slot]?
    roots.push @simpleEditorTemplates if @simpleEditorTemplates?
    binContents = @binWdgt?.viewport?.contents
    roots.push binContents.children... if binContents?
    roots.push @shelfWdgt.children... if @shelfWdgt?
    roots

  # The shared enumeration under the query above AND the trash sever below — ONE walk, so the
  # two can never disagree about which edges exist: whatever the query counts is exactly what
  # the sever cuts, which is what makes "move to trash" land in the bin by graph truth rather
  # than by an intent tag (reference-widgets plan §4.3). Returns [{holder, edge}].
  _livenessEdgesIntoWdgt: (whichWdgt) ->
    found = []
    # public-call-sanctioned: graphLivenessRoots is a pure read (no settle, no mutation).
    for eachRoot in @graphLivenessRoots()
      @_collectLivenessEdgesIntoWdgtWithin eachRoot, whichWdgt, found
    found

  _collectLivenessEdgesIntoWdgtWithin: (subtreeRoot, whichWdgt, found) ->
    return if subtreeRoot == @binWdgt or subtreeRoot == @shelfWdgt
    # a holder inside the asked-about figure is internal wiring, not an inbound edge
    return if subtreeRoot == whichWdgt
    for edge in subtreeRoot.graphEdgesOut()
      continue unless edge.kind == 'flow' or edge.kind == 'reference'
      continue unless edge.to? and !edge.to.destroyed
      found.push {holder: subtreeRoot, edge: edge} if edge.to == whichWdgt or whichWdgt.isAncestorOf edge.to
    for child in subtreeRoot.children
      @_collectLivenessEdgesIntoWdgtWithin child, whichWdgt, found
    return

  # THE TRASH SEVER (reference-widgets plan §4.3): cut every liveness edge the walk above can
  # see into `whichWdgt`'s subtree, so the close that follows files it to the bin and the
  # end-of-cycle drain KEEPS it there — genuinely lost, by graph truth. A REFERENCE edge is
  # severed by its holder's own protocol (a shortcut dies with its edge; dispatched without
  # `?.` so a future emitter class must choose rather than silently inherit destruction); a
  # FLOW edge is derived from the holder's own wire records, so every record aimed at that
  # target is revoked through the one un-wire verb. Holders destroyed by an earlier
  # iteration's cascade are skipped — their edges died with them.
  _severLivenessEdgesIntoWdgtNoSettle: (whichWdgt) ->
    for {holder, edge} in @_livenessEdgesIntoWdgt whichWdgt
      continue if holder.destroyed
      if edge.kind == 'reference'
        holder._severReferenceEdgeToNoSettle edge.to
      else
        continue unless holder.wires?
        for wire in holder.wires.slice() when wire.target == edge.to
          # public-call-sanctioned: unwireFrom is THE one un-wire verb and is settle-neutral
          # (pure list + engine-index bookkeeping, no geometry).
          holder.unwireFrom wire.target, wire.action
    return
