# The WorldWdgt takes over the canvas on the page
class WorldWdgt extends PanelWdgt

  @augmentWith GridPositioningOfAddedShortcutsMixin, @name
  @augmentWith KeepIconicDesktopSystemLinksBackMixin, @name

  # We need to add and remove
  # the event listeners so we are
  # going to put them all in properties
  # here.
  # dblclickEventListener: nil
  mousedownBrowserEventListener: nil
  mouseupBrowserEventListener: nil
  mousemoveBrowserEventListener: nil
  contextmenuEventListener: nil

  touchstartBrowserEventListener: nil
  touchendBrowserEventListener: nil
  touchmoveBrowserEventListener: nil
  gesturestartBrowserEventListener: nil
  gesturechangeBrowserEventListener: nil

  # Note how there can be two handlers for
  # keyboard events.
  # This one is attached
  # to the canvas and reaches the currently
  # blinking caret if there is one.
  # See below for the other potential
  # handler. See "initVirtualKeyboard"
  # method to see where and when this input and
  # these handlers are set up.
  keydownBrowserEventListener: nil
  keyupBrowserEventListener: nil
  keypressBrowserEventListener: nil
  wheelBrowserEventListener: nil

  cutBrowserEventListener: nil
  copyBrowserEventListener: nil
  pasteBrowserEventListener: nil
  errorConsole: nil

  # the string for the last serialised widget
  # is kept in here, to make serialization
  # and deserialization tests easier.
  # The alternative would be to refresh and
  # re-start the tests from where they left...
  lastSerializationString: ""

  # Note how there can be two handlers
  # for keyboard events. This one is
  # attached to a hidden
  # "input" div which keeps track of the
  # text that is being input.
  inputDOMElementForVirtualKeyboardKeydownBrowserEventListener: nil
  inputDOMElementForVirtualKeyboardKeyupBrowserEventListener: nil
  inputDOMElementForVirtualKeyboardKeypressBrowserEventListener: nil

  dragoverEventListener: nil
  resizeBrowserEventListener: nil
  otherTasksToBeRunOnStep: []
  # »>> this part is excluded from the fizzygum homepage build
  dropBrowserEventListener: nil
  # this part is excluded from the fizzygum homepage build <<«

  # these variables shouldn't be static to the WorldWdgt, because
  # in pure theory you could have multiple worlds in the same
  # page with different settings
  @preferencesAndSettings: nil

  @dateOfPreviousCycleStart: nil
  @dateOfCurrentCycleStart: nil

  # The .time of the input event currently being dispatched by playQueuedEvents
  # (a deterministic scheduled ms for macro playback; a real ms for browser users).
  # Exposed so event handlers can reason in EVENT time rather than wall-clock time —
  # used by the hand's multi-click recognition to forget a stale double/triple-click
  # candidate on an event-time gap (deterministic), instead of depending on a
  # wall-clock setTimeout that can fire late under heavy-cycle load.
  @timeOfEventBeingProcessed: nil

  showRedraws: false
  doubleCheckCachedMethodsResults: false

  # The A/B switch for the _-private *DeferredSettle layout API (Widget._setMaxDimDeferredSettle, ...; _-private +
  # stream-handler-restricted by check-layering [O]). ON (default): a *DeferredSettle call defers its layout flush to
  # the ONE end-of-cycle settle (a gesture/stream draining many mutations per frame collapses N flushes into 1).
  # OFF: every *DeferredSettle call self-settles immediately (its NoSettle core under _settleLayoutsAfter, exactly like
  # the plain public setter), so we can A/B and MEASURE whether deferred settling is actually warranted for a given stream
  # -- toggle at runtime (`world.deferredSettlingEnabled = false`) and re-run docs/coalescing-measurement.md. (Default
  # ON keeps current behaviour: the *DeferredSettle calls are byte-identical to the _NoSettle cores they wrap.)
  deferredSettlingEnabled: true

  # *DeferredSettle DECLARATION tracking (Widget._deferredSettleDeclare / _setMaxDimDeferredSettle). _deferredSettleDeclarationDepth
  # is > 0 while a DECLARED deferred-settle mutation runs, so the off-settle invalidates it schedules are known to be
  # intentional. auditUndeclaredEndOfCycle (DEBUG, default off) turns on the end-of-cycle check that LOGS every
  # UNDECLARED off-settle push -- the "careless" set (a public method that forgot to self-settle, or a stream
  # not yet on a *DeferredSettle entrypoint) the eventual declared-deferred-settling gate will reject. Off => ~zero overhead.
  _deferredSettleDeclarationDepth: 0
  auditUndeclaredEndOfCycle: false
  _undeclaredEndOfCyclePushes: nil

  # PAINT must be READ-ONLY: the cycle PROCESSES EVENTS (fixing layouts step by step) -> FIXES the deferred-settle
  # layouts (recalculateLayouts) -> PAINTS (updateBroken), with NO layout work at paint. auditPaintTimeLayout-
  # Scheduling (DEBUG, default off) turns on the check that LOGS every layout (re-)schedule reached DURING the
  # paint pass (healingRectanglesPhase true) -- i.e. a widget that scheduled layout while being painted, crossing
  # the render/layout boundary. The caret's paint-time scroll-follow (the original offender) was moved off paint
  # and now settles inside the flush as the caret's _reLayout (CaretWdgt._requestScrollFollow). Off => ~zero overhead.
  auditPaintTimeLayoutScheduling: false
  _paintTimeLayoutSchedules: nil

  # auditTierAndApplyNaming (DEBUG, default off): the RUNTIME twin of the static [K] apply-2x2 name-consistency lint
  # (check-layering.js). The static gate enforces the surviving NEGATIVE (a _apply*Base bypass twin must not fire the
  # container re-fit nor dispatch to its polymorphic _apply* sibling); the live runtime checks are __-leaf-fires-nothing
  # (a __ leaf is a true bottom) + tier monotonicity (a __ frame calling out reaches only __) -- the dynamic-dispatch
  # ground truth a name scanner can't follow. The old "*AndNotify reaches the re-fit seam" POSITIVE is retired: the
  # notify seam was deleted 2026-07-01 (replaced by the settle-time up-edge) and the *AndNotify corners renamed to the
  # bare polymorphic _apply* 2026-07-02 (Tier B). Driven by Fizzygum-tests/scripts/tier-naming-audit/
  # run-tier-naming-gate.sh (the prelude installs the wrapping + the per-frame lattice assertions). Off => zero overhead.
  auditTierAndApplyNaming: false

  # auditNotificationSettleNeutrality (DEBUG, default off): the RUNTIME twin of the static [J] settle-neutral-callback
  # ban (layering/naming convention §3/§4). Asserts NO nested recalculateLayouts fires INSIDE a _reactTo*/_before*
  # callback (the dynamic twin of [J], catching dynamic dispatch), and that exactly one settle brackets each
  # gesture/structural dispatch batch. Driven by notification-settle-audit/run-notification-settle-gate.sh. Off => zero overhead.
  auditNotificationSettleNeutrality: false

  automator: nil

  # this is the actual reference to the canvas
  # on the html page, where the world is
  # finally painted to.
  worldCanvas: nil
  worldCanvasContext: nil

  canvasForTextMeasurements: nil
  canvasContextForTextMeasurements: nil
  cacheForTextMeasurements: nil
  cacheForTextParagraphSplits: nil
  cacheForParagraphsWordsSplits: nil
  cacheForParagraphsWrappingData: nil
  cacheForTextWrappingData: nil
  cacheForTextBreakingIntoLinesTopLevel: nil

  # By default the world will always fill
  # the entire page, also when browser window
  # is resized.
  # When this flag is set, the onResize callback
  # automatically adjusts the world size.
  automaticallyAdjustToFillEntireBrowserAlsoOnResize: true

  # »>> this part is excluded from the fizzygum homepage build
  # keypad keys map to special characters
  # so we can trigger test actions
  # see more comments below
  @KEYPAD_TAB_mappedToThaiKeyboard_A: "ฟ"
  @KEYPAD_SLASH_mappedToThaiKeyboard_B: "ิ"
  @KEYPAD_MULTIPLY_mappedToThaiKeyboard_C: "แ"
  @KEYPAD_DELETE_mappedToThaiKeyboard_D: "ก"
  @KEYPAD_7_mappedToThaiKeyboard_E: "ำ"
  @KEYPAD_8_mappedToThaiKeyboard_F: "ด"
  @KEYPAD_9_mappedToThaiKeyboard_G: "เ"
  @KEYPAD_MINUS_mappedToThaiKeyboard_H: "้"
  @KEYPAD_4_mappedToThaiKeyboard_I: "ร"
  @KEYPAD_5_mappedToThaiKeyboard_J: "่" # looks like empty string but isn't :-)
  @KEYPAD_6_mappedToThaiKeyboard_K: "า"
  @KEYPAD_PLUS_mappedToThaiKeyboard_L: "ส"
  @KEYPAD_1_mappedToThaiKeyboard_M: "ท"
  @KEYPAD_2_mappedToThaiKeyboard_N: "ท"
  @KEYPAD_3_mappedToThaiKeyboard_O: "ื"
  @KEYPAD_ENTER_mappedToThaiKeyboard_P: "น"
  @KEYPAD_0_mappedToThaiKeyboard_Q: "ย"
  @KEYPAD_DOT_mappedToThaiKeyboard_R: "พ"
  # this part is excluded from the fizzygum homepage build <<«

  wdgtsDetectingClickOutsideMeOrAnyOfMeChildren: new Set
  hierarchyOfClickedWdgts: new Set
  hierarchyOfClickedMenus: new Set
  popUpsMarkedForClosure: new Set
  freshlyCreatedPopUps: new Set
  openPopUps: new Set
  toolTipsList: new Set

  # »>> this part is excluded from the fizzygum homepage build
  @ongoingUrlActionNumber: 0
  # this part is excluded from the fizzygum homepage build <<«

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

  broken: nil
  duplicatedBrokenRectsTracker: nil
  numberOfDuplicatedBrokenRects: 0
  numberOfMergedSourceAndDestination: 0

  # target -> style descriptor (HighlighterWdgt.fillStyle / — Phase 2 — outline styles). A Map, not
  # a Set: the drag-embed arc needs per-target highlight styles (the style channel). The two tracking
  # sets below stay Sets (membership only).
  widgetsToBeHighlighted: new Map
  currentHighlightingWidgets: new Set
  widgetsBeingHighlighted: new Set

  # »>> this part is excluded from the fizzygum homepage build
  widgetsToBePinouted: new Set
  currentPinoutingWidgets: new Set
  widgetsBeingPinouted: new Set
  # this part is excluded from the fizzygum homepage build <<«

  # --- drag-embed affordance overlays (docs/specs/drag-embed-interaction-spec.md §6/§11) --------
  # The hand's state machine sets the *Declared slots each cycle (nil = not wanted); the pre-paint
  # reconciler addDragAffordanceWidgets creates/moves/destroys the reconciler-owned overlay widgets.
  # PRODUCT code (unlike the pinout debug path) — ships in the homepage build.
  dragEmbedChargeRingDeclared: nil
  dragEmbedLabelDeclared: nil
  dragEmbedLockBadgeDeclared: nil
  dragEmbedChargeRingWdgt: nil
  dragEmbedLabelWdgt: nil
  dragEmbedLockBadgeWdgt: nil

  steppingWdgts: new Set

  # scroll panels whose post-release MOMENTUM glide is still running
  # (ScrollPanelWdgt's drag-to-scroll step decaying its last delta by
  # friction each frame). Wall-clock/frame-cadence driven, so the macro
  # pump holds "waitNoInputsOngoing" and screenshots until this drains —
  # the same idea as waiting for font atlases before a capture.
  wdgtsWithOngoingScrollMomentum: new Set

  anyScrollMomentumOngoing: ->
    @wdgtsWithOngoingScrollMomentum.size > 0

  basementWdgt: nil

  # since the shadow is just a "rendering" effect
  # there is no widget for it, we need to just clean up
  # the shadow area ad-hoc. We do that by just growing any
  # broken rectangle by the maximum shadow offset.
  # We could be more surgical and remember the offset of the
  # shadow (if any) in the start and end location of the
  # widget, just like we do with the position, but it
  # would complicate things and probably be overkill.
  # The downside of this is that if we change the
  # shadow sizes, we have to check that this max size
  # still captures the biggest.
  maxShadowSize: 6

  inputEventsQueue: nil

  widgetsReferencingOtherWidgets: new Set
  incrementalGcSessionId: 0
  desktopSidesPadding: 10

  # the desktop lays down icons vertically
  laysIconsHorizontallyInGrid: false
  iconsLayingInGridWrapCount: 5

  errorsWhileRepainting: []
  paintingWidget: nil
  widgetsGivingErrorWhileRepainting: []

  # errors thrown by a _reLayout() DURING the recalculateLayouts flush. We can't build the
  # error console there: createErrorConsole uses the public, self-flushing geometry setters,
  # which would re-enter recalculateLayouts and throw. So we stash them here and report them
  # next cycle, outside the flush -- exactly like errorsWhileRepainting. (task #18)
  layoutErrorsToReport: []

  # this one is so we can left/center/right align in
  # a document editor the last widget that the user "touched"
  # TODO this could be extended so we keep a "list" of
  # "selected" widgets (e.g. if the user ctrl-clicks on a widget
  # then it highlights in some manner and ends up in this list)
  # and then operations can be performed on the whole list
  # of widgets.
  lastNonTextPropertyChangerButtonClickedOrDropped: nil

  wallpaper: nil

  untitledNamingService: nil
  widgetFactory: nil

  isIndexPage: nil

  # »>> this part is excluded from the fizzygum homepage build
  # This method also handles keypresses from a special
  # external keypad which is used to
  # record tests commands (such as capture screen, etc.).
  # These external keypads are inexpensive
  # so they are a good device for this kind
  # of stuff.
  # http://www.amazon.co.uk/Perixx-PERIPAD-201PLUS-Numeric-Keypad-Laptop/dp/B001R6FZLU/
  # They keypad is mapped
  # to Thai keyboard characters via an OSX app
  # called keyremap4macbook (also one needs to add the
  # Thai keyboard, which is just a click from System Preferences)
  # Those Thai characters are used to trigger test
  # commands. The only added complexity is about
  # the "00" key of such keypads - see
  # note below.
  doublePressOfZeroKeypadKey: nil
  # this part is excluded from the fizzygum homepage build <<«

  healingRectanglesPhase: false

  # we use the trackChanges array as a stack to
  # keep track whether a whole segment of code
  # (including all function calls in it) will
  # record the broken rectangles.
  # Using a stack we can correctly track nested "disabling of track
  # changes" correctly.
  trackChanges: [true]

  widgetsWithMaybeChangedPaintBounds: []
  widgetsWithMaybeChangedFullPaintBounds: []
  widgetsThatMaybeChangedLayout: []

  # self-settling public geometry API (prototype 2026-06-19): re-entrancy guards.
  # _inLayoutMutation is set while a public geometry setter is running its
  # core+flush; _recalculatingLayouts is set while recalculateLayouts runs. Both
  # exist to THROW on re-entry, so a public setter calling another (or a layout
  # pass calling a public setter) -- which would flush more than once per logical
  # mutation -- is found and removed rather than silently tolerated.
  _inLayoutMutation: false
  _recalculatingLayouts: false

  macroToolkit: nil

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

    #console.log WorldWdgt.preferencesAndSettings.menuFontName
    @color = Color.create 205, 205, 205 # (130, 130, 130)
    @strokeColor = nil

    @alpha = 1

    # additional properties:
    @isDevMode = false
    @hand = new ActivePointerWdgt
    @keyboardEventsReceivers = new Set
    @lastEditedText = nil
    @caret = nil
    @temporaryHandlesAndLayoutAdjusters = new Set
    @inputDOMElementForVirtualKeyboard = nil

    if @automaticallyAdjustToFillEntireBrowserAlsoOnResize and @isIndexPage
      @stretchWorldToFillEntirePage()
    else
      @sizeCanvasToTestScreenResolution()

    # @worldCanvas.width and height here are in physical pixels
    # so we want to bring them back to logical pixels
    @setBounds new Rectangle 0, 0, @worldCanvas.width / ceilPixelRatio, @worldCanvas.height / ceilPixelRatio

    @initEventListeners()
    if Automator?
      @automator = new Automator
    if MacroToolkit?
      @macroToolkit = new MacroToolkit
    @untitledNamingService = new UntitledNamingService
    # the per-world log of in-world source edits (instance + class scope), embedded in and
    # replayed from a whole-world snapshot. A product collaborator (ships in --homepage).
    @sourceEditsRegistry = new SourceEditsRegistry
    # WidgetFactory is dev/demo scaffolding (homepage-excluded), so guard like
    # the other test/dev collaborators above -- under --homepage the class is
    # stripped and the demo menus that use it are stripped too.
    if WidgetFactory?
      @widgetFactory = new WidgetFactory

    # world.dataflow — the ONE calculation/dataflow engine (spec docs/specs/dataflow-engine-spec.md).
    # A shipped product collaborator (like @sourceEditsRegistry above), so it is constructed
    # UNGUARDED, unlike the dev-only @widgetFactory. It drains once per cycle in doOneCycle,
    # between value-settling (its own) and geometry-settling (recalculateLayouts).
    @dataflow = new DataflowEngine

    # The DOM <canvas id="world"> (@worldCanvas) stays the event target. Under the
    # SWCanvas backend all rendering goes to a separate software render canvas
    # (@worldRenderCanvas), whose pixels are blitted onto the DOM canvas once per
    # painted frame (see updateBroken / blitRenderCanvasToDOM). When the flag is
    # off, the render canvas IS the DOM canvas and there is no blit, so behaviour
    # is identical to before.
    if window.FIZZYGUM_USE_SWCANVAS and window.SWCanvas?
      @worldRenderCanvas = HTMLCanvasElement.createOfPhysicalDimensions new Point @worldCanvas.width, @worldCanvas.height
      @domBlitContext = @worldCanvas.getContext "2d"
    else
      @worldRenderCanvas = @worldCanvas
      @domBlitContext = nil
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

    @changed()

  # answer the absolute coordinates of the world canvas within the document
  getCanvasPosition: ->
    if !@worldCanvas?
      return {x: 0, y: 0}
    pos =
      x: @worldCanvas.offsetLeft
      y: @worldCanvas.offsetTop

    offsetParent = @worldCanvas.offsetParent
    while offsetParent?
      pos.x += offsetParent.offsetLeft
      pos.y += offsetParent.offsetTop
      if offsetParent isnt document.body and offsetParent isnt document.documentElement
        pos.x -= offsetParent.scrollLeft
        pos.y -= offsetParent.scrollTop
      offsetParent = offsetParent.offsetParent
    pos

  colloquialName: ->
    "Desktop"

  makePrettier: ->
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

    @wallpaper.setPattern nil, nil, "dots"

    @changed()

  wantsDropOfChild: (aWdgt) ->
    return @_acceptsDrops

  createErrorConsole: ->
    errorsLogViewerWdgt = new ErrorsLogViewerWdgt "Errors", @, "modifyCodeToBeInjected", ""
    wm = new WindowWdgt nil, nil, errorsLogViewerWdgt
    wm.setExtent new Point 460, 400
    @add wm


    @errorConsole = wm
    @errorConsole.moveTo new Point 190,10
    @errorConsole.setExtent new Point 550,415
    @errorConsole.hide()

  removeSpinnerAndFakeDesktop: ->
    # remove the fake desktop for quick launch and the spinner
    spinner = document.getElementById 'spinner'
    spinner.parentNode.removeChild spinner
    splashScreenFakeDesktop = document.getElementById 'splashScreenFakeDesktop'
    splashScreenFakeDesktop.parentNode.removeChild splashScreenFakeDesktop

  createDesktop: ->
    @setColor Color.create 244,243,244
    @makePrettier()

    acm = new AnalogClockWdgt
    acm._applyExtent new Point 80, 80
    acm._applyMoveTo new Point @right()-80-@desktopSidesPadding, @top() + @desktopSidesPadding
    @add acm

    # TODO find a way to put this back
    # menusHelper.createWelcomeMessageWindowAndShortcut()
    (new HowToSaveMessageApp).createOpener()
    menusHelper.basementIconAndText()
    (new SimpleDocumentApp).createOpener()
    (new FizzyPaintApp).createOpener()
    (new SimpleSlideApp).createOpener()
    (new DashboardsApp).createOpener()
    (new PatchProgrammingApp).createOpener()
    (new GenericPanelApp).createOpener()
    (new ToolbarsApp).createOpener()
    exampleDocsFolder = @makeFolder nil, nil, "examples"
    (new DegreesConverterApp).createOpener exampleDocsFolder
    (new SampleSlideApp).createOpener exampleDocsFolder
    (new SampleDashboardApp).createOpener exampleDocsFolder
    (new SampleDocApp).createOpener exampleDocsFolder
    (new SpreadsheetApp).createOpener exampleDocsFolder

    # »>> this part is only needed for VideoPlayer
    # Guard: VideoPlayerWithRecommendationsWdgt is only bundled with --includeVideoPlayer,
    # so in a default build this boot-time auto-launch would throw "...is not defined".
    # Only run it when the class is actually present. (Surfaced by the boot-smoke gate;
    # see ../Fizzygum-tests/scripts/smoke-boot-headless.js.)
    if window.VideoPlayerWithRecommendationsWdgt? then world.draftRunVideoPlayer()
    # this part is only needed for VideoPlayer <<«


  # »>> this part is excluded from the fizzygum homepage build

  getParameterPassedInURL: (name) ->
    name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]')
    regex = new RegExp '[\\?&]' + name + '=([^&#]*)'
    results = regex.exec location.search
    if results?
      return decodeURIComponent results[1].replace(/\+/g, ' ')
    else
      return nil

  # some test urls:

  # this one contains two actions, two tests each, but only
  # the second test is run for the second group.
  # file:///Users/daviddellacasa/Fizzygum/Fizzygum-builds/latest/worldWithSystemTestHarness.html?startupActions=%7B%0D%0A++%22paramsVersion%22%3A+0.1%2C%0D%0A++%22actions%22%3A+%5B%0D%0A++++%7B%0D%0A++++++%22name%22%3A+%22runTests%22%2C%0D%0A++++++%22testsToRun%22%3A+%5B%22bubble%22%5D%0D%0A++++%7D%2C%0D%0A++++%7B%0D%0A++++++%22name%22%3A+%22runTests%22%2C%0D%0A++++++%22testsToRun%22%3A+%5B%22shadow%22%2C+%22SystemTest_basicResize%22%5D%2C%0D%0A++++++%22numberOfGroups%22%3A+2%2C%0D%0A++++++%22groupToBeRun%22%3A+1%0D%0A++++%7D++%5D%0D%0A%7D
  #
  # just one simple quick test about shadows
  #file:///Users/daviddellacasa/Fizzygum/Fizzygum-builds/latest/worldWithSystemTestHarness.html?startupActions=%7B%0A%20%20%22paramsVersion%22%3A%200.1%2C%0A%20%20%22actions%22%3A%20%5B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22name%22%3A%20%22runTests%22%2C%0A%20%20%20%20%20%20%22testsToRun%22%3A%20%5B%22shadow%22%5D%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D

  nextStartupAction: ->
    if (@getParameterPassedInURL "startupActions")?
      startupActions = JSON.parse @getParameterPassedInURL "startupActions"

    if (!startupActions?) or (WorldWdgt.ongoingUrlActionNumber == startupActions.actions.length)
      WorldWdgt.ongoingUrlActionNumber = 0
      if Automator?
        if window.location.href.includes("worldWithSystemTestHarness")
          if @automator.atLeastOneTestHasBeenRun
            if @automator.allTestsPassedSoFar
              document.getElementById("background").style.background = Color.GREEN.toString()
      return

    if !@isIndexPage then console.log "nextStartupAction " + (WorldWdgt.ongoingUrlActionNumber+1) + " / " + startupActions.actions.length

    currentAction = startupActions.actions[WorldWdgt.ongoingUrlActionNumber]
    if Automator? and currentAction.name == "runTests"
      if currentAction.numberOfGroups?
        @automator.numberOfGroups = currentAction.numberOfGroups
      else
        @automator.numberOfGroups = 1
      if currentAction.groupToBeRun?
        @automator.groupToBeRun = currentAction.groupToBeRun
      else
        @automator.groupToBeRun = 0

      # selectTestsFromTagsOrTestNames loads every test's metadata ASYNChronously and only THEN
      # populates selectedTestsBasedOnTags. runAllSystemTests must WAIT for that — otherwise
      # testsList() races: until the selection lands it falls back to the full manifest, so the
      # wrong test's _automationCommands get read (window[...] undefined) and the run crashes. This
      # only bit on a COLD cache (a reload appeared to "fix" it). So run the tests from the
      # selection callback — mirroring the headless runner, which likewise waits for the selection.
      @automator.loader.selectTestsFromTagsOrTestNames currentAction.testsToRun, =>
        @automator.player.runAllSystemTests()
    WorldWdgt.ongoingUrlActionNumber++

  getWidgetViaTextLabel: ([textDescription, occurrenceNumber, numberOfOccurrences]) ->
    allCandidateWidgetsWithSameTextDescription =
      @allChildrenTopToBottomSuchThat (m) ->
        m.getTextDescription() == textDescription

    return allCandidateWidgetsWithSameTextDescription[occurrenceNumber]
  # this part is excluded from the fizzygum homepage build <<«

  mostRecentlyCreatedPopUp: ->
    mostRecentPopUp = nil
    mostRecentPopUpID = -1

    # we have to check which menus
    # are actually open, because
    # the destroy() function used
    # everywhere is not recursive and
    # that's where we update the @openPopUps
    # set so we have to doublecheck here
    @openPopUps.forEach (eachPopUp) =>
      if eachPopUp.isOrphan()
        @openPopUps.delete eachPopUp
      else if eachPopUp.instanceNumericID >= mostRecentPopUpID
        mostRecentPopUp = eachPopUp

    return mostRecentPopUp

  # »>> this part is excluded from the fizzygum homepage build
  # see roundNumericIDsToNextThousand method in
  # Widget for an explanation of why we need this
  # method.
  alignIDsOfNextWidgetsInSystemTests: ->
    if Automator? and Automator.state != Automator.IDLE
      # Check which objects end with the word Widget
      theWordWdgt = "Wdgt"
      theWordWidget = "Widget"
      listOfWidgetsClasses = (Object.keys(window)).filter (i) ->
        i.includes(theWordWdgt, i.length - theWordWdgt.length) or
        i.includes(theWordWidget, i.length - theWordWidget.length)
      for eachWidgetClass in listOfWidgetsClasses
        #console.log "bumping up ID of class: " + eachWidgetClass
        window[eachWidgetClass].roundNumericIDsToNextThousand?()
  # this part is excluded from the fizzygum homepage build <<«

  # used to close temporary menus
  # thin-wrap-exempt: NOT the canonical wrap over its _NoSettle twin -- the two are PARALLEL closers, not
  # wrapper/core. This one closes each marked popup via the self-settling close() (correct for the top-level
  # "pin" menu-click path, MenuHeader -> pinPopUp); the twin closes via _closeNoSettle for the drop path
  # (PopUpWdgt._reactToBeingDropped -> pinPopUp, inside the drop's settle). Separate keeps the menu path's per-popup
  # settle exactly (vs collapsing to one settle, which could shift size-dependent basement re-home spots).
  closePopUpsMarkedForClosure: ->
    @popUpsMarkedForClosure.forEach (eachWidget) =>
      eachWidget.close()
    @popUpsMarkedForClosure.clear()

  # NON-settling variant for the drop path (PopUpWdgt._reactToBeingDropped -> pinPopUp, inside the drop's
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
    #  * the interesting one in PanelWdgt which a) narrows the dirty
    #    rectangle (intersecting it with its border
    #    since the PanelWdgt clips at its border) and b) stops recursion on all
    #    the children that are outside such intersection.
    #  * this implementation which just takes into account that the hand
    #    (which could contain a Widget being floatDragged)
    #    is painted on top of everything.
    super aContext, aRect

    # the mouse cursor is always drawn on top of everything
    # and it's not attached to the WorldWdgt.
    @hand.fullPaintIntoAreaOrBlitFromBackBuffer aContext, aRect

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

  pushBrokenRect: (brokenWidget, theRect, isSrc) ->
    if @duplicatedBrokenRectsTracker[theRect.toString()]?
      @numberOfDuplicatedBrokenRects++
    else
      if isSrc
        brokenWidget.srcBrokenRect = @broken.length
      else
        brokenWidget.dstBrokenRect = @broken.length
      if !theRect?
        debugger
      # if @broken.length == 0
      #  debugger
      @broken.push theRect
    @duplicatedBrokenRectsTracker[theRect.toString()] = true

  # using the code coverage tool from Chrome, it
  # doesn't seem that this is ever used
  # TODO investigate and see whether this is needed
  mergeBrokenRectsIfCloseOrPushBoth: (brokenWidget, sourceBroken, destinationBroken) ->
    mergedBrokenRect = sourceBroken.merge destinationBroken
    mergedBrokenRectArea = mergedBrokenRect.area()
    sumArea = sourceBroken.area() + destinationBroken.area()
    #console.log "mergedBrokenRectArea: " + mergedBrokenRectArea + " (sumArea + sumArea/10): " + (sumArea + sumArea/10)
    if mergedBrokenRectArea < sumArea + sumArea/10
      @pushBrokenRect brokenWidget, mergedBrokenRect, true
      @numberOfMergedSourceAndDestination++
    else
      @pushBrokenRect brokenWidget, sourceBroken, true
      @pushBrokenRect brokenWidget, destinationBroken, false


  checkARectWithHierarchy: (aRect, brokenWidget, isSrc) ->
    brokenWidgetAncestor = brokenWidget

    while brokenWidgetAncestor.parent?
      brokenWidgetAncestor = brokenWidgetAncestor.parent
      if brokenWidgetAncestor.srcBrokenRect?
        if !@broken[brokenWidgetAncestor.srcBrokenRect]?
          debugger
        if @broken[brokenWidgetAncestor.srcBrokenRect].containsRectangle aRect
          if isSrc
            @broken[brokenWidget.srcBrokenRect] = nil
            brokenWidget.srcBrokenRect = nil
          else
            @broken[brokenWidget.dstBrokenRect] = nil
            brokenWidget.dstBrokenRect = nil
        else if aRect.containsRectangle @broken[brokenWidgetAncestor.srcBrokenRect]
          @broken[brokenWidgetAncestor.srcBrokenRect] = nil
          brokenWidgetAncestor.srcBrokenRect = nil

      if brokenWidgetAncestor.dstBrokenRect?
        if !@broken[brokenWidgetAncestor.dstBrokenRect]?
          debugger
        if @broken[brokenWidgetAncestor.dstBrokenRect].containsRectangle aRect
          if isSrc
            @broken[brokenWidget.srcBrokenRect] = nil
            brokenWidget.srcBrokenRect = nil
          else
            @broken[brokenWidget.dstBrokenRect] = nil
            brokenWidget.dstBrokenRect = nil
        else if aRect.containsRectangle @broken[brokenWidgetAncestor.dstBrokenRect]
          @broken[brokenWidgetAncestor.dstBrokenRect] = nil
          brokenWidgetAncestor.dstBrokenRect = nil


  rectAlreadyIncludedInParentBrokenWidget: ->
    for brokenWidget in @widgetsWithMaybeChangedPaintBounds
        if brokenWidget.srcBrokenRect?
          aRect = @broken[brokenWidget.srcBrokenRect]
          @checkARectWithHierarchy aRect, brokenWidget, true
        if brokenWidget.dstBrokenRect?
          aRect = @broken[brokenWidget.dstBrokenRect]
          @checkARectWithHierarchy aRect, brokenWidget, false

    for brokenWidget in @widgetsWithMaybeChangedFullPaintBounds
        if brokenWidget.srcBrokenRect?
          aRect = @broken[brokenWidget.srcBrokenRect]
          @checkARectWithHierarchy aRect, brokenWidget
        if brokenWidget.dstBrokenRect?
          aRect = @broken[brokenWidget.dstBrokenRect]
          @checkARectWithHierarchy aRect, brokenWidget

  cleanupSrcAndDestRectsOfWidgets: ->
    for brokenWidget in @widgetsWithMaybeChangedPaintBounds
      brokenWidget.srcBrokenRect = nil
      brokenWidget.dstBrokenRect = nil
    for brokenWidget in @widgetsWithMaybeChangedFullPaintBounds
      brokenWidget.srcBrokenRect = nil
      brokenWidget.dstBrokenRect = nil


  fleshOutBroken: ->
    #if @widgetsWithMaybeChangedPaintBounds.length > 0
    #  debugger

    sourceBroken = nil
    destinationBroken = nil


    for brokenWidget in @widgetsWithMaybeChangedPaintBounds

      # let's see if this Widget that marked itself as broken
      # was actually painted in the past frame.
      # If it was then we have to clean up the "before" area
      # even if the Widget is not visible anymore
      if brokenWidget.clippedBoundsWhenLastPainted?
        if brokenWidget.clippedBoundsWhenLastPainted.isNotEmpty()
          sourceBroken = brokenWidget.clippedBoundsWhenLastPainted.expandBy(1).growBy @maxShadowSize

        #if brokenWidget!= world and (brokenWidget.clippedBoundsWhenLastPainted.containsPoint (new Point(10,10)))
        #  debugger

      # for the "destination" broken rectangle we can actually
      # check whether the Widget is still visible because we
      # can skip the destination rectangle in that case
      # (not the source one!)
      unless brokenWidget.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()
        # @clippedThroughBounds() should be smaller area
        # than bounds because it clips
        # the bounds based on the clipping widgets up the
        # hierarchy
        boundsToBeChanged = brokenWidget.clippedThroughBounds()

        if boundsToBeChanged.isNotEmpty()
          destinationBroken = boundsToBeChanged.spread().expandBy(1).growBy @maxShadowSize
          #if brokenWidget!= world and (boundsToBeChanged.spread().containsPoint new Point 10, 10)
          #  debugger


      if sourceBroken? and destinationBroken?
        @mergeBrokenRectsIfCloseOrPushBoth brokenWidget, sourceBroken, destinationBroken
      else if sourceBroken? or destinationBroken?
        if sourceBroken?
          @pushBrokenRect brokenWidget, sourceBroken, true
        else
          @pushBrokenRect brokenWidget, destinationBroken, true

      brokenWidget.paintBoundsMaybeChanged = false
      brokenWidget.clippedBoundsWhenLastPainted = nil

    

  fleshOutFullBroken: ->
    #if @widgetsWithMaybeChangedFullPaintBounds.length > 0
    #  debugger

    sourceBroken = nil
    destinationBroken = nil

    for brokenWidget in @widgetsWithMaybeChangedFullPaintBounds

      #console.log "fleshOutFullBroken: " + brokenWidget

      if brokenWidget.fullClippedBoundsWhenLastPainted?
        if brokenWidget.fullClippedBoundsWhenLastPainted.isNotEmpty()
          sourceBroken = brokenWidget.fullClippedBoundsWhenLastPainted.expandBy(1).growBy @maxShadowSize

      # for the "destination" broken rectangle we can actually
      # check whether the Widget is still visible because we
      # can skip the destination rectangle in that case
      # (not the source one!)
      unless brokenWidget.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()

        boundsToBeChanged = brokenWidget.fullClippedBounds()

        if boundsToBeChanged.isNotEmpty()
          destinationBroken = boundsToBeChanged.spread().expandBy(1).growBy @maxShadowSize
          #if brokenWidget!= world and (boundsToBeChanged.spread().containsPoint (new Point(10,10)))
          #  debugger
      
   
      if sourceBroken? and destinationBroken?
        @mergeBrokenRectsIfCloseOrPushBoth brokenWidget, sourceBroken, destinationBroken
      else if sourceBroken? or destinationBroken?
        if sourceBroken?
          @pushBrokenRect brokenWidget, sourceBroken, true
        else
          @pushBrokenRect brokenWidget, destinationBroken, true

      brokenWidget.fullPaintBoundsMaybeChanged = false
      brokenWidget.fullClippedBoundsWhenLastPainted = nil


  # »>> this part is excluded from the fizzygum homepage build
  showBrokenRects: (aContext) ->
    aContext.save()
    aContext.globalAlpha = 0.5
    aContext.useLogicalPixelsUntilRestore()
 
    for eachBrokenRect in @broken
      if eachBrokenRect?
        randomR = Math.round Math.random() * 255
        randomG = Math.round Math.random() * 255
        randomB = Math.round Math.random() * 255

        aContext.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")"
        aContext.fillRect  Math.round(eachBrokenRect.origin.x),
            Math.round(eachBrokenRect.origin.y),
            Math.round(eachBrokenRect.width()),
            Math.round(eachBrokenRect.height())
    aContext.restore()
    # this part is excluded from the fizzygum homepage build <<«


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
    @_undeclaredEndOfCyclePushes = nil unless @_inLayoutMutation
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

  _recalculateLayoutsBody: ->

    # DEFENSIVE ASSERTION -- NOT a convergence budget. (proper-layouts Stage 6, 2026-07-01.)
    # This loop is a work-list DRAIN: each _reLayout() marks its chain-top valid (so it is popped),
    # and _reFitMyTrackingContainerAfterSettle re-fits the chain-top's size-tracking container as a
    # bounded O(depth) up-walk. Instrumenting the FULL suite (dpr1 + dpr2) measured a peak of 428
    # iterations in one flush -- but that was 427 DISTINCT widgets with ZERO re-visits (one big tree
    # settled at once, a pure drain). The only residual iteration is a small, bounded size-negotiation
    # cycle for constrained NESTED containers (measured peak: 10 re-visits of a 5-widget
    # Window -> VerticalStack -> ScrollPanel chain in macroWindowCellsInConstrainedScrollStackReflow) --
    # so the loop still CONVERGES (fast + bounded) rather than strictly draining. The old
    # recalcIterationsCap masked a possible non-convergence SILENTLY (log + abandon the work-list +
    # ship a broken layout); that suppression is DELETED. What remains is a pure never-fire assertion
    # at a generous-but-finite bound: if the drain ever fails to TERMINATE it is a BUG (a real
    # non-terminating layout cycle), so THROW loudly rather than freeze the tab or silently ship
    # broken layout. (Per-_reLayout errors are a different path, handled by the catch below.)
    layoutIterationsSanityLimit = 100000
    recalcIterations = 0

    until @widgetsThatMaybeChangedLayout.length == 0
      recalcIterations++
      if recalcIterations > layoutIterationsSanityLimit
        # Never fires in normal operation (peak measured 428, bound 100000). Reaching here means a real
        # non-terminating layout cycle. console.error first (keeps the RECALC_NONCONVERGENCE token the
        # determinism torture greps for), then THROW so it surfaces loudly instead of being tolerated.
        console.error "RECALC_NONCONVERGENCE: recalculateLayouts did not terminate after " + layoutIterationsSanityLimit + " iterations. Last widget: " + (tryThisWidget?.constructor?.name) + " spec=" + (tryThisWidget?.layoutSpec)
        throw new Error "Fizzygum: RECALC_NONCONVERGENCE -- recalculateLayouts did not terminate after " + layoutIterationsSanityLimit + " iterations (a non-terminating layout cycle). Last widget: " + (tryThisWidget?.constructor?.name)
      # starting from the last element,
      # find the first Widget which has a broken layout,
      # (and pop out of the queue all the Widgets we encounter
      # on the way that have a valid layout)
      loop
        tryThisWidget = @widgetsThatMaybeChangedLayout[@widgetsThatMaybeChangedLayout.length - 1]
        if tryThisWidget.layoutIsValid
          @widgetsThatMaybeChangedLayout.pop()
          if @widgetsThatMaybeChangedLayout.length == 0
            return
        else
          break

      # now that you have a Widget with a broken layout, go up the chain of broken layouts as much
      # as possible: climb to the TOP-MOST invalid widget -- on the way up, stop at the LAST widget
      # with an invalid layout (parent valid or absent), NOT at the first freefloating boundary.
      # (Opt-2, 2026-07-02 -- implements the long-standing TODO that used to live here.) A
      # freefloating widget may be sized/positioned FROM its parent (e.g. a StretchablePanel's
      # fractional children), so the parent must lay out FIRST and the freefloating child settle
      # AFTER. The old `tryThisWidget.isFreeFloating()` early-break made the freefloating child the
      # chain-top, so it was laid out first against the parent's STALE size and then AGAIN once the
      # parent settled -- a wasted double-layout. Climbing past it lays the parent out first; the
      # freefloating child then settles once, correctly. (This does NOT pull the freefloating child
      # into the parent's own _reLayout -- the freefloating-skip in _invalidateLayout keeps that
      # boundary; the climb only matters when the parent is ALSO invalid from its own source, and the
      # freefloating child still settles as its own chain-top on a later iteration, now against the
      # parent's FINAL size.) Byte-exact: the settled layout is an order-independent fixpoint
      # (verified -- reversing the loop's processing order is 165/165 at dpr1/dpr2/webkit), so laying
      # the parent out first only removes a redundant pass, it does not change the result.
      while tryThisWidget.parent? and not tryThisWidget.parent.layoutIsValid
        tryThisWidget = tryThisWidget.parent

      try
        # so now you have a "top" element up a chain
        # of widgets with broken layout. Go do a
        # _reLayout on it, so it might fix a bunch of those
        # on the chain (but not all)
        # (proper-layouts §4.3, 2026-07-01) ORDERED settle-time re-fit: now that this chain-top has SETTLED, re-fit
        # its size-tracking container so the container tracks the just-settled geometry. This REPLACES the deleted
        # mutation-time geometry seam (_announceGeometryChangeToContainer): because the content is fully settled when
        # this fires, the container reads its FINAL geometry and re-fits correctly in one visit -- no per-mutation
        # notification, and no convergence iteration from a container reading half-applied content. The method gates
        # on the parent being a tracking container (_reLayoutChildren?), so a non-tracking parent is a no-op.
        #
        # (proper-layouts Stage 6, 2026-07-01) NO-OP EARLY RETURN: only re-fit the container if this _reLayout
        # actually CHANGED my frame (position OR extent). A size-tracking container fits itself to its content's
        # FRAME, so if my frame is identical before and after I settle, re-fitting the container is provably a
        # no-op. This was the dominant residual "re-visit": a chain-top re-enqueued only to be re-laid to the same
        # box (e.g. a scroll panel 362x204 -> 362x204 after its content settled unchanged). Skipping it removes
        # those wasted passes. Sound either way I am sized: if I am fit-to-content my frame moves WITH my content,
        # so a real content change IS caught here; if I am fixed-size my container fits my fixed frame regardless
        # of my subtree -- so an unchanged frame always means my container's fit is unchanged. Measured byte-exact
        # across dpr1 / dpr2 / webkit + determinism torture; suite-wide peak re-visits dropped from 10 to 2 (the
        # residual 2 being the genuine one-round bidirectional negotiation: top-down size, then bottom-up re-fit).
        preL = tryThisWidget.left(); preT = tryThisWidget.top(); preW = tryThisWidget.width(); preH = tryThisWidget.height()
        tryThisWidget._reLayout()
        myFrameChanged = tryThisWidget.left() != preL or tryThisWidget.top() != preT or tryThisWidget.width() != preW or tryThisWidget.height() != preH
        tryThisWidget._reFitMyTrackingContainerAfterSettle() if myFrameChanged
      catch err
        # We are INSIDE the recalculateLayouts flush here (_recalculatingLayouts is true), so this
        # block must do the ABSOLUTE MINIMUM and stay strictly non-flushing / non-invalidating:
        #   - createErrorConsole uses public, self-flushing setters -> it would re-enter
        #     recalculateLayouts and throw BEFORE @errorConsole is assigned (masking the real error);
        #   - even softResetWorld is unsafe here (its hand.drop -> target.add can flush too).
        # And because the throwing _reLayout() never reached its trailing markLayoutAsFixed(),
        # tryThisWidget is still layoutIsValid==false, so unless we settle it here this until-loop
        # would spin forever. So: settle + ban the offender (both layout-clean), then defer the
        # softReset + reporting to the next cycle's drain, outside the flush. (task #18)
        tryThisWidget.markLayoutAsFixed()   # it threw before doing this itself; do it now so the loop converges
        tryThisWidget.__hide()          # ban from paint -- silent: nils caches only, no _invalidateLayout/flush
        @layoutErrorsToReport.push err


  clearPaintBoundsMaybeChangedFlags: ->
    for m in @widgetsWithMaybeChangedPaintBounds
      m.paintBoundsMaybeChanged = false

  clearFullPaintBoundsMaybeChangedFlags: ->
    for m in @widgetsWithMaybeChangedFullPaintBounds
      m.fullPaintBoundsMaybeChanged = false

  disableTrackChanges: ->
    @trackChanges.push false

  maybeEnableTrackChanges: ->
    @trackChanges.pop()

  updateBroken: ->
    #console.log "number of broken rectangles: " + @broken.length
    @broken = []
    @duplicatedBrokenRectsTracker = {}
    @numberOfDuplicatedBrokenRects = 0
    @numberOfMergedSourceAndDestination = 0

    @fleshOutFullBroken()
    @fleshOutBroken()
    @rectAlreadyIncludedInParentBrokenWidget()
    @cleanupSrcAndDestRectsOfWidgets()

    @clearPaintBoundsMaybeChangedFlags()
    @clearFullPaintBoundsMaybeChangedFlags()

    @widgetsWithMaybeChangedPaintBounds = []
    @widgetsWithMaybeChangedFullPaintBounds = []
    # »>> this part is excluded from the fizzygum homepage build
    #ProfilingDataCollector.profileBrokenRects @broken, @numberOfDuplicatedBrokenRects, @numberOfMergedSourceAndDestination
    # this part is excluded from the fizzygum homepage build <<«

    # each broken rectangle requires traversing the scenegraph to
    # redraw what's overlapping it. Not all Widgets are traversed
    # in particular the following can stop the recursion:
    #  - invisible Widgets
    #  - PanelWdgts that don't overlap the broken rectangle
    # Since potentially there is a lot of traversal ongoing for
    # each broken rectangle, one might want to consolidate overlapping
    # and nearby rectangles.

    @healingRectanglesPhase = true

    @errorsWhileRepainting = []

    @broken.forEach (rect) =>
      if !rect?
        return
      if rect.isNotEmpty()
        try
          @fullPaintIntoAreaOrBlitFromBackBuffer @worldCanvasContext, rect
        catch err
          @resetWorldCanvasContext()
          @queueErrorForLaterReporting err
          @hideOffendingWidget()
          @softResetWorld()

    # IF we got errors while repainting, the
    # screen might be in a bad state (because everything in front of the
    # "bad" widget is not repainted since the offending widget has
    # thrown, so nothing in front of it could be painted properly)
    # SO do COMPLETE repaints of the screen and hide
    # further offending widgets until there are no more errors
    # (i.e. the offending widgets are progressively hidden so eventually
    # we should repaint the whole screen without errors, hopefully)
    if @errorsWhileRepainting.length != 0
      @findOutAllOtherOffendingWidgetsAndPaintWholeScreen()

    if @showRedraws
      @showBrokenRects @worldCanvasContext

    # Under the SWCanvas backend, everything above painted into the software
    # render surface; lift it onto the DOM <canvas id="world"> so it becomes
    # visible. Only when something was actually painted this cycle.
    if @domBlitContext? and @broken.length != 0
      @blitRenderCanvasToDOM()

    @resetDataStructuresForBrokenRects()

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
    @_paintTimeLayoutSchedules = nil

    if @trackChanges.length != 1 and @trackChanges[0] != true
      alert "trackChanges array should have only one element (true)"

  # SWCanvas backend only: copy the whole software render surface onto the DOM
  # <canvas id="world"> so the frame becomes visible. (Per-broken-rect partial
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
  syncRenderCanvasToWorldCanvas: ->
    return unless @worldRenderCanvas? and @worldRenderCanvas isnt @worldCanvas
    @worldRenderCanvas.width = @worldCanvas.width
    @worldRenderCanvas.height = @worldCanvas.height
    @worldCanvasContext = @worldRenderCanvas.getContext "2d"
    @worldCanvasContext.textPixelDensity = ceilPixelRatio if @worldCanvasContext.textPixelDensity?

  # True while any SWCanvas glyph atlas is still loading (text would still show
  # placeholder boxes). The SystemTest screenshot gate waits on this so it never
  # captures un-settled text. Always false under the native backend.
  anyTextDirty: ->
    if window.swCanvasAnyTextDirty?
      window.swCanvasAnyTextDirty()
    else
      false

  findOutAllOtherOffendingWidgetsAndPaintWholeScreen: ->
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
    previousErrorsCount = nil
    numberOfTotalRepaints = 0
    until previousErrorsCount == currentErrorsCount
      numberOfTotalRepaints++
      try
        @fullPaintIntoAreaOrBlitFromBackBuffer @worldCanvasContext, @bounds
      catch err
        @resetWorldCanvasContext()
        @queueErrorForLaterReporting err
        @hideOffendingWidget()
        @softResetWorld()

      previousErrorsCount = currentErrorsCount
      currentErrorsCount = @errorsWhileRepainting.length

    #console.log "total repaints: " + numberOfTotalRepaints

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

  queueErrorForLaterReporting: (err) ->
    # now record the error so we can report it in the
    # next cycle, and add the offending widget to a
    # "banned" list
    @errorsWhileRepainting.push err
    if !@widgetsGivingErrorWhileRepainting.includes @paintingWidget
      @widgetsGivingErrorWhileRepainting.push @paintingWidget
      @paintingWidget.__hide()

  hideOffendingWidget: ->
    if !@widgetsGivingErrorWhileRepainting.includes @paintingWidget
      @widgetsGivingErrorWhileRepainting.push @paintingWidget
      @paintingWidget.__hide()

  resetDataStructuresForBrokenRects: ->
    @broken = []
    @duplicatedBrokenRectsTracker = {}
    @numberOfDuplicatedBrokenRects = 0
    @numberOfMergedSourceAndDestination = 0

  # »>> this part is excluded from the fizzygum homepage build
  addPinoutingWidgets: ->
    @currentPinoutingWidgets.forEach (eachPinoutingWidget) =>
      if @widgetsToBePinouted.has eachPinoutingWidget.wdgtThisWdgtIsPinouting
        if eachPinoutingWidget.wdgtThisWdgtIsPinouting.hasMaybeChangedPaintBounds()
          # reposition the pinout widget if needed
          peekThroughBox = eachPinoutingWidget.wdgtThisWdgtIsPinouting.clippedThroughBounds()
          eachPinoutingWidget._applyMoveTo new Point(peekThroughBox.right() + 10,peekThroughBox.top())

      else
        @currentPinoutingWidgets.delete eachPinoutingWidget
        @widgetsBeingPinouted.delete eachPinoutingWidget.wdgtThisWdgtIsPinouting
        eachPinoutingWidget.wdgtThisWdgtIsPinouting = nil
        eachPinoutingWidget.fullDestroy()

    @widgetsToBePinouted.forEach (eachWidgetNeedingPinout) =>
      unless @widgetsBeingPinouted.has eachWidgetNeedingPinout
        hM = new StringWdgt eachWidgetNeedingPinout.toString()
        # this bare StringWdgt is used as an ephemeral overlay — mark the INSTANCE before @add so it
        # is hit-test-excluded and shadow-free (isEphemeral capability), like the HighlighterWdgt.
        hM._ephemeralOverlay = true
        @add hM
        hM.wdgtThisWdgtIsPinouting = eachWidgetNeedingPinout
        peekThroughBox = eachWidgetNeedingPinout.clippedThroughBounds()
        hM._applyMoveTo new Point(peekThroughBox.right() + 10,peekThroughBox.top())
        hM.setColor Color.BLUE
        hM.setWidth 400
        @currentPinoutingWidgets.add hM
        @widgetsBeingPinouted.add eachWidgetNeedingPinout
  # this part is excluded from the fizzygum homepage build <<«
  
  addHighlightingWidgets: ->
    @currentHighlightingWidgets.forEach (eachHighlightingWidget) =>
      if @widgetsToBeHighlighted.has eachHighlightingWidget.wdgtThisWdgtIsHighlighting
        if eachHighlightingWidget.wdgtThisWdgtIsHighlighting.hasMaybeChangedPaintBounds()
          eachHighlightingWidget._applyBounds eachHighlightingWidget.wdgtThisWdgtIsHighlighting.clippedThroughBounds()
      else
        @currentHighlightingWidgets.delete eachHighlightingWidget
        @widgetsBeingHighlighted.delete eachHighlightingWidget.wdgtThisWdgtIsHighlighting
        eachHighlightingWidget.wdgtThisWdgtIsHighlighting = nil
        eachHighlightingWidget.fullDestroy()

    @widgetsToBeHighlighted.forEach (styleDescriptor, eachWidgetNeedingHighlight) =>
      unless @widgetsBeingHighlighted.has eachWidgetNeedingHighlight
        hM = new HighlighterWdgt
        @add hM
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
      @dragEmbedChargeRingWdgt = nil

    # armed label — a StringWdgt overlay near the cursor
    if @dragEmbedLabelDeclared?
      if @dragEmbedLabelWdgt? and @dragEmbedLabelWdgt.text isnt @dragEmbedLabelDeclared.text
        @dragEmbedLabelWdgt.fullDestroy()
        @dragEmbedLabelWdgt = nil
      unless @dragEmbedLabelWdgt?
        @dragEmbedLabelWdgt = new StringWdgt @dragEmbedLabelDeclared.text
        @dragEmbedLabelWdgt._ephemeralOverlay = true
        @add @dragEmbedLabelWdgt
        @dragEmbedLabelWdgt.setColor Color.create(40, 40, 40, 1)
        @dragEmbedLabelWdgt.setWidth 320   # roomy enough for the full text (else a StringWdgt crops it)
      @dragEmbedLabelWdgt._applyMoveTo @dragEmbedLabelDeclared.point
    else if @dragEmbedLabelWdgt?
      @dragEmbedLabelWdgt.fullDestroy()
      @dragEmbedLabelWdgt = nil

    # lock badge — a small StringWdgt at the reluctant (view-mode) target's title-bar right
    if @dragEmbedLockBadgeDeclared?
      unless @dragEmbedLockBadgeWdgt?
        @dragEmbedLockBadgeWdgt = new StringWdgt "view-only"
        @dragEmbedLockBadgeWdgt._ephemeralOverlay = true
        @add @dragEmbedLockBadgeWdgt
        @dragEmbedLockBadgeWdgt.setColor Color.create(120, 120, 120, 1)
      box = @dragEmbedLockBadgeDeclared.target.clippedThroughBounds()
      @dragEmbedLockBadgeWdgt._applyMoveTo new Point(box.right() - 70, box.top() + 4)
    else if @dragEmbedLockBadgeWdgt?
      @dragEmbedLockBadgeWdgt.fullDestroy()
      @dragEmbedLockBadgeWdgt = nil


  # »>> this part is only needed for VideoPlayer
  draftRunVideoPlayer: ->
      videoPlayer = new WindowWdgt nil, nil, new VideoPlayerWithRecommendationsWdgt, true, true
      world.add videoPlayer
      videoPlayer.setExtent new Point 934, 896
      # it would be -28 instead of zero here below, but the system doesn't allow
      # to put windows outside of the screen
      videoPlayer.moveTo new Point 174, 0

  # this part is only needed for VideoPlayer <<«


  playQueuedEvents: ->
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
      @softResetWorld()
      if !@errorConsole? then @createErrorConsole()
      @errorConsole.contents.showUpWithError err

    @inputEventsQueue.clear()

  # we keep the "pacing" promises in this
  # framePacedPromises array, (or, more precisely,
  # we keep their resolving functions) and each frame
  # we resolve one, so we don't cause gitter.
  # At the moment using an array is overkill because
  # we only use this when loading the coffeescript sources batches
  # and we only load one batch at a time.
  progressFramePacedActions: ->
    if window.framePacedPromises.length > 0
      resolvingFunction = window.framePacedPromises.shift()
      resolvingFunction.call()

  showErrorsHappenedInRepaintingStepInPreviousCycle: ->
    for eachErr in @errorsWhileRepainting
      if !@errorConsole? then @createErrorConsole()
      @errorConsole.contents.showUpWithError eachErr

  # Drains layout errors stashed during the previous cycle's recalculateLayouts flush (see the
  # catch in _recalculateLayoutsBody). Runs at cycle start, OUTSIDE the flush, so building the
  # error console via the public setters is safe here. (task #18)
  showLayoutErrorsFromPreviousCycle: ->
    if @layoutErrorsToReport.length == 0 then return
    errorsToShow = @layoutErrorsToReport
    @layoutErrorsToReport = []
    # We run at cycle start, OUTSIDE the recalculateLayouts flush, so the operations that were
    # unsafe in the catch are safe here: softResetWorld (its hand.drop -> add may flush) and
    # createErrorConsole (public setters). This is the deferred tail of that catch. (task #18)
    @softResetWorld()
    for eachErr in errorsToShow
      # Loud in the browser console too -- not only in the in-world error console. A _reLayout()
      # that throws is a real bug, and CI / the smoke-apps app-launch gate key off console.error;
      # without this a broken app would no longer freeze (good) but would also go undetected (bad).
      console.error "LAYOUT_ERROR: a _reLayout() threw during recalculateLayouts: " + (eachErr?.stack ? eachErr)
      if !@errorConsole? then @createErrorConsole()
      @errorConsole.contents.showUpWithError eachErr


  updateTimeReferences: ->
    WorldWdgt.dateOfCurrentCycleStart = new Date
    if !WorldWdgt.dateOfPreviousCycleStart?
      WorldWdgt.dateOfPreviousCycleStart = new Date WorldWdgt.dateOfCurrentCycleStart.getTime() - 30

    # »>> this part is only needed for Macros
    if !@macroToolkit.msSinceLastExecutedMacroStep?
      @macroToolkit.msSinceLastExecutedMacroStep = 0
    else
      @macroToolkit.msSinceLastExecutedMacroStep += WorldWdgt.dateOfCurrentCycleStart.getTime() - WorldWdgt.dateOfPreviousCycleStart.getTime()
    # this part is only needed for Macros <<«

  doOneCycle: ->
    @updateTimeReferences()

    @showErrorsHappenedInRepaintingStepInPreviousCycle()
    @showLayoutErrorsFromPreviousCycle()

    # »>> this part is only needed for Macros
    @macroToolkit?.progressOnMacroSteps()
    # this part is only needed for Macros <<«

    @playQueuedEvents()

    # replays test actions at the right time
    if AutomatorPlayer? and Automator.state == Automator.PLAYING
      @automator.player.replayTestCommands()
    
    # currently unused
    @runOtherTasksStepFunction()
    
    # used to load fizzygum sources progressively
    @progressFramePacedActions()
    
    @runChildrensStepFunction()
    # Drain the dataflow engine's stale pool (spec docs/specs/dataflow-engine-spec.md §4.1). Two
    # deliberately-parallel drain stations sit here: recalculateDataflow settles VALUES,
    # recalculateLayouts settles GEOMETRY. Placed AFTER stepping so this frame's time-source ticks
    # join this frame's batch, and BEFORE recalculateLayouts so sink applications feed this frame's
    # geometry settle and paint (running after layouts would reintroduce the one-cadence-lag bug
    # class). The coupling is ONE-WAY: dataflow may dirty layout; layout must never mark dataflow
    # stale. Dark-cheap — early-returns on an empty stale pool.
    @dataflow.recalculateDataflow()
    @recalculateLayouts()
    # Hover re-sync AFTER the flush: re-derive the widgets-under-(stationary)-pointer set against the
    # frame's SETTLED geometry -- the same fixed point paint reads -- so hover never lags geometry within
    # a painted frame (pre-swap it read pre-flush bounds, one stage too early; deferred-settle drag geometry
    # was still unapplied). Handlers fired here write paint-layer state and at most SELF-SETTLING
    # mutations (tooltip fullDestroy), so the world is settled again before updateBroken; a careless
    # (off-settle) push from a hover handler would be caught by the end-of-cycle capstone gate.
    # See docs/hover-resync-after-flush-plan.md.
    @hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()

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

    # »>> this part is excluded from the fizzygum homepage build
    @addPinoutingWidgets()
    # this part is excluded from the fizzygum homepage build <<«
    @addHighlightingWidgets()
    @addDragAffordanceWidgets()

    # here is where the repainting on screen happens
    @updateBroken()

    WorldWdgt.frameCount++

    WorldWdgt.dateOfPreviousCycleStart = WorldWdgt.dateOfCurrentCycleStart
    WorldWdgt.dateOfCurrentCycleStart = nil

  # Widget stepping:
  runChildrensStepFunction: ->


    # note that a widget can remove itself while stepping using the
    # Set.delete method. This is fine, because the forEach method
    # is not affected by the removal of elements while iterating.
    #
    # TODO all these set modifications should be immutable...
    @steppingWdgts.forEach (eachSteppingWidget) =>

      #if eachSteppingWidget.isBeingFloatDragged()
      #  continue

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
          #console.log millisBetweenSteps + " " + millisecondsRemainingToWaitedFrame
        else
          elapsedMilliseconds = timeOfCurrentCycleStart - eachSteppingWidget.lastTime
          millisecondsRemainingToWaitedFrame = millisBetweenSteps - elapsedMilliseconds
      
      # when the firing time comes (or as soon as it's past):
      if millisecondsRemainingToWaitedFrame <= 0
        @stepWidget eachSteppingWidget

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



  stepWidget: (whichWidget) ->
    if whichWidget.onNextStep
      nxt = whichWidget.onNextStep
      whichWidget.onNextStep = nil
      nxt.call whichWidget
    if !whichWidget.step?
      debugger
    try
      whichWidget.step()
      #console.log "stepping " + whichWidget
    catch err
      @softResetWorld()
      if !@errorConsole? then @createErrorConsole()
      @errorConsole.contents.showUpWithError err

  
  runOtherTasksStepFunction : ->
    for task in @otherTasksToBeRunOnStep
      #console.log "running a task: " + task
      task()

  # »>> this part is excluded from the fizzygum homepage build
  sizeCanvasToTestScreenResolution: ->
    @worldCanvas.width = Math.round(960 * ceilPixelRatio)
    @worldCanvas.height = Math.round(440 * ceilPixelRatio)
    @worldCanvas.style.width = "960px"
    @worldCanvas.style.height = "440px"
    @syncRenderCanvasToWorldCanvas()

    bkground = document.getElementById("background")
    bkground.style.width = "960px"
    bkground.style.height = "720px"
    bkground.style.backgroundColor = Color.WHITESMOKE.toString()
  # this part is excluded from the fizzygum homepage build <<«

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
      @fullChanged()
      @worldCanvas.width = (clientWidth * ceilPixelRatio)
      @worldCanvas.style.width = clientWidth + "px"
      @worldCanvas.height = (clientHeight * ceilPixelRatio)
      @worldCanvas.style.height = clientHeight + "px"
      @syncRenderCanvasToWorldCanvas()
      @_applyExtent new Point clientWidth, clientHeight
      @_reLayoutDesktop()
  

  _reLayoutDesktop: ->
    basementOpenerWdgt = @firstChildSuchThat (w) ->
      w instanceof BasementOpenerWdgt
    if basementOpenerWdgt?
      if basementOpenerWdgt.userMovedThisFromComputedPosition
        basementOpenerWdgt._moveInDesktopToFractionalPosition()
        if !basementOpenerWdgt.wasPositionedSlightlyOutsidePanel
          basementOpenerWdgt._moveWithin @
      else
        basementOpenerWdgt._applyMoveTo @bottomRight().subtract (new Point 75, 75).add @desktopSidesPadding

    analogClockWdgt = @firstChildSuchThat (w) ->
      w instanceof AnalogClockWdgt
    if analogClockWdgt?
      if analogClockWdgt.userMovedThisFromComputedPosition
        analogClockWdgt._moveInDesktopToFractionalPosition()
        if !analogClockWdgt.wasPositionedSlightlyOutsidePanel
          analogClockWdgt._moveWithin @
      else
        analogClockWdgt._applyMoveTo new Point @right() - 80 - @desktopSidesPadding, @top() + @desktopSidesPadding

    @children.forEach (child) =>
      # reposition the non-icon desktop children (the basement opener and clock are handled
      # above); !child.isDesktopIcon?() replaces `!(child instanceof WidgetHolderWithCaptionWdgt)`
      # (type-test-elimination campaign)
      if child != basementOpenerWdgt and child != analogClockWdgt and !child.isDesktopIcon?()
        if child.positionFractionalInHoldingPanel?
          child._moveInDesktopToFractionalPosition()
        if !child.wasPositionedSlightlyOutsidePanel
          child._moveWithin @
  
  # WorldWdgt events:

  # »>> this part is excluded from the fizzygum homepage build
  initVirtualKeyboard: ->
    if @inputDOMElementForVirtualKeyboard
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = nil
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
  # this part is excluded from the fizzygum homepage build <<«

  # -----------------------------------------------------
  # clipboard events processing
  # -----------------------------------------------------


  initMouseEventListeners: ->
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

  initTouchEventListeners: ->
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


  initKeyboardEventListeners: ->
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

  initClipboardEventListeners: ->
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
      # TODO this should follow the fromBrowserEvent pattern
      @inputEventsQueue.push CutInputEvent.fromBrowserEvent event

    document.body.addEventListener "cut", @cutBrowserEventListener, false
    
    @copyBrowserEventListener = (event) =>
      # TODO this should follow the fromBrowserEvent pattern
      @inputEventsQueue.push CopyInputEvent.fromBrowserEvent event

    document.body.addEventListener "copy", @copyBrowserEventListener, false

    @pasteBrowserEventListener = (event) =>
      # TODO this should follow the fromBrowserEvent pattern
      @inputEventsQueue.push PasteInputEvent.fromBrowserEvent event

    document.body.addEventListener "paste", @pasteBrowserEventListener, false

  initOtherMiscEventListeners: ->
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

    # CHECK AFTER 15 Jan 2021 00:00:00 GMT
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
      @inputEventsQueue.push ResizeInputEvent.fromBrowserEvent event

    # this is a DOM thing, little to do with other r e s i z e methods
    window.addEventListener "resize", @resizeBrowserEventListener, false

  # note that we don't register the normal click,
  # we figure that out independently.
  initEventListeners: ->
    @initMouseEventListeners()
    @initTouchEventListeners()
    @initKeyboardEventListeners()
    @initClipboardEventListeners()
    @initOtherMiscEventListeners()

  # »>> this part is excluded from the fizzygum homepage build
  removeEventListeners: ->
    canvas = @worldCanvas
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
    if Utils.runningInMobileSafari()
      canvas.removeEventListener 'scroll', @wheelBrowserEventListener

    canvas.removeEventListener 'cut', @cutBrowserEventListener
    canvas.removeEventListener 'copy', @copyBrowserEventListener
    canvas.removeEventListener 'paste', @pasteBrowserEventListener

    canvas.removeEventListener 'dragover', @dragoverEventListener
    canvas.removeEventListener 'resize', @resizeBrowserEventListener
    canvas.removeEventListener 'drop', @dropBrowserEventListener
  # this part is excluded from the fizzygum homepage build <<«
  
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
  softResetWorld: ->
    @hand.drop()
    @hand.mouseOverList.clear()
    @hand.nonFloatDraggedWdgt = nil
    @wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.clear()
    @lastNonTextPropertyChangerButtonClickedOrDropped = nil

  # »>> this part is excluded from the fizzygum homepage build
  # resetWorld self-settles like any public API method: it is a SEQUENCE of two self-settling
  # operations (each flushes once -- _settleLayoutsAfter's doc blesses sequential setters), and
  # the geometry teardown lives in _resetWorldNoSettle so an internal caller already inside a settle can
  # reach it without re-entering the flush. softResetWorld stays OUTSIDE the settle on purpose: its
  # @hand.drop() does a real re-parenting drop (target.add, which self-flushes), so running it inside
  # the settle below would re-enter recalculateLayouts and throw the flow-violation (see ~:930).
  # thin-wrap-exempt: softReset (its hand.drop self-flushes) must precede the settle, so this is a
  # two-statement sequence, not the bare @_settleLayoutsAfter => @_resetWorldNoSettle wrap (see above).
  resetWorld: ->
    @softResetWorld()
    @_settleLayoutsAfter => @_resetWorldNoSettle()

  _resetWorldNoSettle: ->
    @changed() # redraw the whole screen
    @fullDestroyChildren()
    # the "basementWdgt" is not attached to the
    # world tree so it's not in the children,
    # so we need to clean up separately
    @basementWdgt?.empty()
    # some tests might change the background
    # color of the world so let's reset it.
    @setColor Color.create 205, 205, 205
    # make sure thw window is scrolled to top
    # so we can see the test results while tests
    # are running.
    document.body.scrollTop = document.documentElement.scrollTop = 0
  # this part is excluded from the fizzygum homepage build <<«
  
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
    # Check which objects end with the word Widget
    theWordWdgt = "Wdgt"
    theWordWidget = "Widget"
    ListOfWidgets = (Object.keys(window)).filter (i) ->
      i.includes(theWordWdgt, i.length - theWordWdgt.length) or
      i.includes(theWordWidget, i.length - theWordWidget.length)
    for eachWidgetClass in ListOfWidgets
      if eachWidgetClass != "WorldWdgt"
        #console.log "resetting " + eachWidgetClass + " from " + window[eachWidgetClass].instancesCounter
        # the actual count is in another variable "instancesCounter"
        # but all labels are built using instanceNumericID
        # which is set based on lastBuiltInstanceNumericID
        window[eachWidgetClass].lastBuiltInstanceNumericID = 0

    # »>> this part is excluded from the fizzygum homepage build
    if Automator?
      Automator.animationsPacingControl = false
      Automator.alignmentOfWidgetIDsMechanism = false
      Automator.hidingOfWidgetsContentExtractInLabels = false
      Automator.hidingOfWidgetsNumberIDInLabels = false
    # this part is excluded from the fizzygum homepage build <<«

    super()

  destroyToolTips: ->
    # "toolTipsList" keeps the widgets to be deleted upon
    # the next mouse click, or whenever another temporary Widget decides
    # that it needs to remove them.
    # Note that we actually destroy toolTipsList because we are not expecting
    # anybody to revive them once they are gone (as opposed to menus)

    @toolTipsList.forEach (tooltip) =>
      unless tooltip.boundsContainPoint @position()
        tooltip.fullDestroy()
        @toolTipsList.delete tooltip
  

  # "open from file…" world-menu action: pop the file picker; FileLoading routes the chosen
  # *.fzw.json by its envelope `kind` (a widget is attached to the desktop, a world snapshot
  # replaces the world). A product feature — ships in all builds.
  openFromFile: ->
    FileLoading.openFromFileDialog()

  # --- whole-world snapshot save/load (kind:"world") ---------------------------------------
  # See docs/serialization-duplication-reference.md §11 and the plan §4.9. Serialization is a
  # PRODUCT feature — these ship in --homepage (no strip markers). The world is NOT saved as a
  # widget record (that would drag in its canvases/caches/hand/listener closures and crash the
  # walker, defect D8); Serializer.serializeWorld captures the desktop tree + off-tree basement
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
  # calls are the sanctioned public path. NB the teardown is built from PRODUCT-safe primitives
  # — NOT the homepage-stripped resetWorld/_resetWorldNoSettle — since this ships in --homepage.
  loadWorldSnapshot: (envelopeOrString, opts = {}) ->
    envelope = if typeof envelopeOrString is "string" then JSON.parse(envelopeOrString) else envelopeOrString
    unless envelope? and envelope.format is Serializer.FORMAT and envelope.kind is "world"
      world.inform "This is not a Fizzygum world snapshot file."
      return
    unless opts.skipConfirm
      msg = "Load this world snapshot?\n\nIt REPLACES everything on your desktop, and can run code the snapshot carries."
      return unless (typeof window.confirm is "function") and window.confirm msg
    section = envelope.world or {}
    # 1. tear the current world down (product-safe) — one settle over the NoSettle core.
    @_settleLayoutsAfter => @_teardownForSnapshotLoadNoSettle()
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
    restoredRegistry.replayClassEdits()
    # 3. deserialize the object table (kind:"world" preserves each widget's iid).
    result = Deserializer.deserialize envelope
    shells = result.shells or []
    resolve = (refOrVal) ->
      return nil unless refOrVal?
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
    # 6. swap in the restored (self-contained, off-tree) basement so every $r pointer at it
    #    (the basement opener's target, ...) stays consistent, and re-bind the app-slot /
    #    templates windows (orphaned-but-revivable — NOT re-attached to the desktop here).
    restoredBasement = resolve section.basement
    @basementWdgt = restoredBasement if restoredBasement?
    @[slot] = resolve(refVal) for own slot, refVal of (section.appSlots or {})
    @simpleEditorTemplates = resolve(section.simpleEditorTemplates) if section.simpleEditorTemplates?
    # 7. attach the desktop children in ONE settle batch, via the base _addNoSettle so the
    #    grid mixin does NOT re-place them (their restored positions are preserved) — the
    #    sanctioned public-equivalent path (never a raw layout core; see DETERMINISM.md).
    #    Clear each child's parent first (deserialize pre-set it to {"$wk":"world"}) so the
    #    attach is a clean re-parent.
    @_settleLayoutsAfter =>
      for childRef in (section.children or [])
        child = resolve childRef
        if child?
          child.parent = nil
          @_addNoSettle child
    # 8. desktop colour + wallpaper (sequential self-settling public ops).
    restoredColor = resolve section.desktopColor
    @setColor restoredColor if restoredColor?
    @wallpaper.setPattern nil, nil, section.wallpaperPatternName if section.wallpaperPatternName? and @wallpaper?
    # 9. install the snapshot's source-edit registry (its class edits are already replayed;
    #    this makes the loaded world's edit history authoritative), then repaint now and again
    #    once any async image/canvas assets have decoded.
    @sourceEditsRegistry = restoredRegistry
    result.whenReady?.then? => @fullChanged()
    @fullChanged()
    return

  # NoSettle teardown core for a snapshot load (mirrors _resetWorldNoSettle but product-safe:
  # no @changed/scrollTop/setColor — the loader re-establishes those). fullDestroyChildren is
  # itself a NoSettle-level op that ALSO zeroes every per-class lastBuiltInstanceNumericID,
  # giving the clean id space the restored iids need. Called only inside loadWorldSnapshot's
  # settle wrap above.
  _teardownForSnapshotLoadNoSettle: ->
    @fullDestroyChildren()
    @basementWdgt?.empty()
    @[slot] = nil for slot in Serializer.WORLD_APP_SLOTS
    @simpleEditorTemplates = nil

  buildContextMenu: ->

    if @isIndexPage
      menu = new MenuWdgt @, false, @, true, true, "Desktop"
      menu.addMenuItem "wallpapers ➜", false, @wallpaper, "wallpapersMenu", "choose a wallpaper for the Desktop"
      menu.addMenuItem "new folder", true, @, "makeFolder"
      menu.addMenuItem "save world snapshot…", true, @, "saveWorldSnapshotToFile", "save the whole desktop\nto a *.fzw.json file"
      menu.addMenuItem "open from file…", true, @, "openFromFile", "load a widget or world\nfrom a *.fzw.json file"
      return menu

    if @isDevMode
      menu = new MenuWdgt(@, false,
        @, true, true, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    else
      menu = new MenuWdgt @, false, @, true, true, "Widgetic"

    # »>> this part is excluded from the fizzygum homepage build
    if @isDevMode
      menu.addMenuItem "demo ➜", false, @, "popUpDemoMenu", "sample widgets"
      menu.addLine()
      # TODO remove these two, they do nothing now
      menu.addMenuItem "show all", true, @, "noOperation"
      menu.addMenuItem "hide all", true, @, "noOperation"
      menu.addMenuItem "delete all", true, @, "closeChildren"
      menu.addMenuItem "move all inside", true, @, "keepAllSubwidgetsWithin", "keep all subwidgets\nwithin and visible"
      menu.addMenuItem "inspect", true, @, "inspect", "open a window on\nall properties"
      menu.addMenuItem "test menu ➜", false, menusHelper, "testMenu", "debugging and testing operations"
      menu.addLine()
      menu.addMenuItem "restore display", true, @, "changed", "redraw the\nscreen once"
      menu.addMenuItem "fit whole page", true, @, "stretchWorldToFillEntirePage", "let the World automatically\nadjust to browser resizings"
      menu.addMenuItem "color...", true, @, "popUpColorSetter", "choose the World's\nbackground color"
      menu.addMenuItem "wallpapers ➜", false, @wallpaper, "wallpapersMenu", "choose a wallpaper for the Desktop"

      if WorldWdgt.preferencesAndSettings.inputMode is PreferencesAndSettings.INPUT_MODE_MOUSE
        menu.addMenuItem "touch screen settings", true, WorldWdgt.preferencesAndSettings, "toggleInputMode", "bigger menu fonts\nand sliders"
      else
        menu.addMenuItem "standard settings", true, WorldWdgt.preferencesAndSettings, "toggleInputMode", "smaller menu fonts\nand sliders"
      menu.addLine()
    # this part is excluded from the fizzygum homepage build <<«
    
    if Automator?
      menu.addMenuItem "system tests ➜", false, @, "popUpSystemTestsMenu", ""

    if @isDevMode
      menu.addMenuItem "switch to user mode", true, @, "toggleDevMode", "disable developers'\ncontext menus"
    else
      menu.addMenuItem "switch to dev mode", true, @, "toggleDevMode"

    menu.addMenuItem "new folder", true, @, "makeFolder"
    menu.addMenuItem "about Fizzygum...", true, @, "about"
    menu



  # »>> this part is excluded from the fizzygum homepage build
  popUpSystemTestsMenu: ->
    menu = new MenuWdgt @, false, @, true, true, "system tests"

    menu.addMenuItem "run system tests (normal)", true, @automator.player, "runAllSystemTestsNormalSpeed", "runs all the system tests at the normal (slowest, watchable) speed level"
    menu.addMenuItem "run system tests (fast)", true, @automator.player, "runAllSystemTestsFastSpeed", "runs all the system tests at the fast (intermediate) speed level"
    menu.addMenuItem "run system tests (fastest)", true, @automator.player, "runAllSystemTestsFastestSpeed", "runs all the system tests at the fastest speed level"

    menu.addMenuItem "show test source", true, @automator, "showTestSource", "opens a window with the source of the latest test"
    menu.addMenuItem "save failed screenshots", true, @automator.player, "saveFailedScreenshots", "save failed screenshots"

    menu.popUpAtHand()
  # this part is excluded from the fizzygum homepage build <<«

  create: (aWdgt) ->
    aWdgt.pickUp()

  # Wrap a content widget in a window, size and place it, add it to the world --
  # the windowed sibling of `create`. Returns the window. The single home for the
  # "fresh window" wrap (windowed apps' buildWindow, menusHelper's window demos, the
  # inspector/console/prompt spawners). Titled / _applyExtent windows build directly.
  openWindowWith: (contentWidget, extent, position) ->
    wm = new WindowWdgt nil, nil, contentWidget
    wm.setExtent extent
    wm._applyMoveTo position
    wm._moveWithin @
    @add wm
    wm

  # »>> this part is excluded from the fizzygum homepage build
  popUpDemoMenu: (widgetOpeningThePopUp,b,c,d) ->
    if @isIndexPage
      menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "parts bin"
      menu.addMenuItem "rectangle", true, @widgetFactory, "createNewRectangleWdgt"
      menu.addMenuItem "box", true, @widgetFactory, "createNewBoxWdgt"
      menu.addMenuItem "circle box", true, @widgetFactory, "createNewCircleBoxWdgt"
      menu.addMenuItem "slider", true, @widgetFactory, "createNewSliderWdgt"
      menu.addMenuItem "speech bubble", true, @widgetFactory, "createNewSpeechBubbleWdgt"
      menu.addLine()
      menu.addMenuItem "gray scale palette", true, @widgetFactory, "createNewGrayPaletteWdgtInWindow"
      menu.addMenuItem "color palette", true, @widgetFactory, "createNewColorPaletteWdgtInWindow"
      menu.addLine()
      menu.addMenuItem "analog clock", true, menusHelper, "analogClock"
    else
      menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "make a widget"
      menu.addMenuItem "rectangle", true, @widgetFactory, "createNewRectangleWdgt"
      menu.addMenuItem "box", true, @widgetFactory, "createNewBoxWdgt"
      menu.addMenuItem "circle box", true, @widgetFactory, "createNewCircleBoxWdgt"
      menu.addLine()
      menu.addMenuItem "slider", true, @widgetFactory, "createNewSliderWdgt"
      menu.addMenuItem "panel", true, @widgetFactory, "createNewPanelWdgt"
      menu.addMenuItem "scrollable panel", true, @widgetFactory, "createNewScrollPanelWdgt"
      menu.addMenuItem "canvas", true, @widgetFactory, "createNewCanvas"
      menu.addMenuItem "handle", true, @widgetFactory, "createNewHandle"
      menu.addLine()
      menu.addMenuItem "string", true, @widgetFactory, "createNewString"
      menu.addMenuItem "text", true, @widgetFactory, "createNewText"
      menu.addMenuItem "tool tip", true, @widgetFactory, "createNewToolTipWdgt"
      menu.addMenuItem "speech bubble", true, @widgetFactory, "createNewSpeechBubbleWdgt"
      menu.addLine()
      menu.addMenuItem "gray scale palette", true, @widgetFactory, "createNewGrayPaletteWdgt"
      menu.addMenuItem "color palette", true, @widgetFactory, "createNewColorPaletteWdgt"
      menu.addMenuItem "color picker", true, @widgetFactory, "createNewColorPickerWdgt"
      menu.addLine()
      menu.addMenuItem "sensor demo", true, @widgetFactory, "createNewSensorDemo"
      menu.addMenuItem "animation demo", true, @widgetFactory, "createNewAnimationDemo"
      menu.addMenuItem "pen", true, @widgetFactory, "createNewPenWdgt"
        
      menu.addLine()
      menu.addMenuItem "layout tests ➜", false, @, "layoutTestsMenu", "sample widgets"
      menu.addLine()
      menu.addMenuItem "under the carpet", true, @widgetFactory, "underTheCarpet"

    menu.popUpAtHand()

  layoutTestsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Layout tests"
    menu.addMenuItem "adjuster widget", true, @widgetFactory, "createNewStackElementsSizeAdjustingWdgt"
    menu.addMenuItem "adder/droplet", true, @widgetFactory, "createNewLayoutElementAdderOrDropletWdgt"
    menu.addMenuItem "test screen 1", true, @widgetFactory, "setupTestScreen1"
    menu.popUpAtHand()
    
  
  toggleDevMode: ->
    @isDevMode = not @isDevMode
  # this part is excluded from the fizzygum homepage build <<«

  
  # edit self-settles via the public add / fullDestroy (EACH opens its own settle) exactly as it always has --
  # every event-time editing caller (inspectors, text fields) depends on that unchanged timing. _editNoSettle
  # shares the IDENTICAL caret-teardown-and-creation body via a strategy thunk (the _stopEditingTearingCaretDownWith
  # pattern below), but routes it through the NON-settling _fullDestroyNoSettle / _addNoSettle for a caller ALREADY
  # inside a layout flush/pass -- a dataflow connection sink delivering into a prompt slider's editable field
  # (PromptWdgt._takeSliderValueConnector -> StringWdgt._editNoSettle), where the public self-settling add /
  # fullDestroy would throw the flow-rule (Widget:824).
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
    # return nil  unless aStringWidgetOrTextWidget.isEditable

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
      @initVirtualKeyboard()
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
      @inputDOMElementForVirtualKeyboard = nil
    @worldCanvas.focus()

  anyReferenceToWdgt: (whichWdgt) ->
    # go through all the references and check whether they reference
    # the wanted widget. Note that the reference could be unreachable
    # in the basement, or even in the trash
    for eachReferencingWdgt from @widgetsReferencingOtherWidgets
      if eachReferencingWdgt.target == whichWdgt
        return true
    return false
