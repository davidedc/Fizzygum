# The WorldMorph takes over the canvas on the page
class WorldMorph extends PanelWdgt

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

  # the string for the last serialised morph
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

  # these variables shouldn't be static to the WorldMorph, because
  # in pure theory you could have multiple worlds in the same
  # page with different settings
  # (but anyways, it was global before, so it's not any worse than before)
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
  @numberOfAddsAndRemoves: 0
  @numberOfVisibilityFlagsChanges: 0
  @numberOfCollapseFlagsChanges: 0
  @numberOfRawMovesAndResizes: 0

  broken: nil
  duplicatedBrokenRectsTracker: nil
  numberOfDuplicatedBrokenRects: 0
  numberOfMergedSourceAndDestination: 0

  morphsToBeHighlighted: new Set
  currentHighlightingMorphs: new Set
  morphsBeingHighlighted: new Set

  # »>> this part is excluded from the fizzygum homepage build
  morphsToBePinouted: new Set
  currentPinoutingMorphs: new Set
  morphsBeingPinouted: new Set
  # this part is excluded from the fizzygum homepage build <<«

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
  # there is no morph for it, we need to just clean up
  # the shadow area ad-hoc. We do that by just growing any
  # broken rectangle by the maximum shadow offset.
  # We could be more surgical and remember the offset of the
  # shadow (if any) in the start and end location of the
  # morph, just like we do with the position, but it
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

  # this one is so we can left/center/right align in
  # a document editor the last widget that the user "touched"
  # TODO this could be extended so we keep a "list" of
  # "selected" widgets (e.g. if the user ctrl-clicks on a widget
  # then it highlights in some manner and ends up in this list)
  # and then operations can be performed on the whole list
  # of widgets.
  lastNonTextPropertyChangerButtonClickedOrDropped: nil

  patternName: nil
  pattern1: "plain"
  pattern2: "circles"
  pattern3: "vert. stripes"
  pattern4: "oblique stripes"
  pattern5: "dots"
  pattern6: "zigzag"
  pattern7: "bricks"

  howManyUntitledShortcuts: 0
  howManyUntitledFoldersShortcuts: 0

  lastUsedConnectionsCalculationToken: 0

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

  morphsThatMaybeChangedGeometryOrPosition: []
  morphsThatMaybeChangedFullGeometryOrPosition: []
  morphsThatMaybeChangedLayout: []

  macroToolkit: nil

  constructor: (
      @worldCanvas,
      @automaticallyAdjustToFillEntireBrowserAlsoOnResize = true
      ) ->

    # The WorldMorph is the very first morph to
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

    WorldMorph.preferencesAndSettings = new PreferencesAndSettings

    super()
    @patternName = @pattern1
    @appearance = new DesktopAppearance @

    #console.log WorldMorph.preferencesAndSettings.menuFontName
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
    WorldMorph.preferencesAndSettings.menuFontSize = 14
    WorldMorph.preferencesAndSettings.menuHeaderFontSize = 13
    WorldMorph.preferencesAndSettings.menuHeaderColor = Color.create 125, 125, 125
    WorldMorph.preferencesAndSettings.menuHeaderBold = false
    WorldMorph.preferencesAndSettings.menuStrokeColor = Color.create 186, 186, 186
    WorldMorph.preferencesAndSettings.menuBackgroundColor = Color.create 250, 250, 250
    WorldMorph.preferencesAndSettings.menuButtonsLabelColor = Color.create 50, 50, 50

    WorldMorph.preferencesAndSettings.normalTextFontSize = 13
    WorldMorph.preferencesAndSettings.titleBarTextFontSize = 13
    WorldMorph.preferencesAndSettings.titleBarTextHeight = 16
    WorldMorph.preferencesAndSettings.titleBarBoldText = false
    WorldMorph.preferencesAndSettings.bubbleHelpFontSize = 12


    WorldMorph.preferencesAndSettings.iconDarkLineColor = Color.create 37, 37, 37


    WorldMorph.preferencesAndSettings.defaultPanelsBackgroundColor = Color.create 249, 249, 249
    WorldMorph.preferencesAndSettings.defaultPanelsStrokeColor = Color.create 198, 198, 198

    @setPattern nil, nil, "dots"

    @changed()

  getNextUntitledShortcutName: ->
    name = "Untitled"
    if @howManyUntitledShortcuts > 0
      name += " " + (@howManyUntitledShortcuts + 1)

    @howManyUntitledShortcuts++

    return name

  getNextUntitledFolderShortcutName: ->
    name = "new folder"
    if @howManyUntitledFoldersShortcuts > 0
      name += " " + (@howManyUntitledFoldersShortcuts + 1)

    @howManyUntitledFoldersShortcuts++

    return name


  wantsDropOf: (aWdgt) ->
    return @_acceptsDrops

  makeNewConnectionsCalculationToken: ->
    # not nice to read but this means:
    # first increment and then return the value
    # this is so the first token we use is 1
    # and we can initialise all input/node tokens to 0
    # so to make them receptive to the first token generated
    ++@lastUsedConnectionsCalculationToken

  createErrorConsole: ->
    errorsLogViewerMorph = new ErrorsLogViewerWdgt "Errors", @, "modifyCodeToBeInjected", ""
    wm = new WindowWdgt nil, nil, errorsLogViewerMorph
    wm.setExtent new Point 460, 400
    @add wm


    @errorConsole = wm
    @errorConsole.fullMoveTo new Point 190,10
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
    acm.rawSetExtent new Point 80, 80
    acm.fullRawMoveTo new Point @right()-80-@desktopSidesPadding, @top() + @desktopSidesPadding
    @add acm

    # TODO find a way to put this back
    # menusHelper.createWelcomeMessageWindowAndShortcut()
    menusHelper.createHowToSaveMessageOpener()
    menusHelper.basementIconAndText()
    menusHelper.createSimpleDocumentLauncher()
    menusHelper.createFizzyPaintLauncher()
    menusHelper.createSimpleSlideLauncher()
    menusHelper.createDashboardsLauncher()
    menusHelper.createPatchProgrammingLauncher()
    menusHelper.createGenericPanelLauncher()
    menusHelper.createToolbarsOpener()
    exampleDocsFolder = @makeFolder nil, nil, "examples"
    menusHelper.createDegreesConverterOpener exampleDocsFolder
    menusHelper.createSampleSlideOpener exampleDocsFolder
    menusHelper.createSampleDashboardOpener exampleDocsFolder
    menusHelper.createSampleDocOpener exampleDocsFolder

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

    if (!startupActions?) or (WorldMorph.ongoingUrlActionNumber == startupActions.actions.length)
      WorldMorph.ongoingUrlActionNumber = 0
      if Automator?
        if window.location.href.includes("worldWithSystemTestHarness")
          if @automator.atLeastOneTestHasBeenRun
            if @automator.allTestsPassedSoFar
              document.getElementById("background").style.background = Color.GREEN.toString()
      return

    if !@isIndexPage then console.log "nextStartupAction " + (WorldMorph.ongoingUrlActionNumber+1) + " / " + startupActions.actions.length

    currentAction = startupActions.actions[WorldMorph.ongoingUrlActionNumber]
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
    WorldMorph.ongoingUrlActionNumber++

  getMorphViaTextLabel: ([textDescription, occurrenceNumber, numberOfOccurrences]) ->
    allCandidateMorphsWithSameTextDescription =
      @allChildrenTopToBottomSuchThat (m) ->
        m.getTextDescription() == textDescription

    return allCandidateMorphsWithSameTextDescription[occurrenceNumber]
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
  alignIDsOfNextMorphsInSystemTests: ->
    if Automator? and Automator.state != Automator.IDLE
      # Check which objects end with the word Widget
      theWordMorph = "Morph"
      theWordWdgt = "Wdgt"
      theWordWidget = "Widget"
      listOfMorphsClasses = (Object.keys(window)).filter (i) ->
        i.includes(theWordMorph, i.length - theWordMorph.length) or
        i.includes(theWordWdgt, i.length - theWordWdgt.length) or
        i.includes(theWordWidget, i.length - theWordWidget.length)
      for eachMorphClass in listOfMorphsClasses
        #console.log "bumping up ID of class: " + eachMorphClass
        window[eachMorphClass].roundNumericIDsToNextThousand?()
  # this part is excluded from the fizzygum homepage build <<«

  # used to close temporary menus
  closePopUpsMarkedForClosure: ->
    @popUpsMarkedForClosure.forEach (eachMorph) =>
      eachMorph.close()
    @popUpsMarkedForClosure.clear()
  
  # »>> this part is excluded from the fizzygum homepage build
  # World Widget broken rects debugging
  # currently unused
  brokenFor: (aWdgt) ->
    # private
    fb = aWdgt.fullBounds()
    @broken.filter (rect) ->
      rect.isIntersecting fb
  # this part is excluded from the fizzygum homepage build <<«
  
  
  # fullPaintIntoAreaOrBlitFromBackBuffer results into actual painting of pieces of
  # morphs done
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
    # and it's not attached to the WorldMorph.
    @hand.fullPaintIntoAreaOrBlitFromBackBuffer aContext, aRect

  clippedThroughBounds: ->
    @checkClippedThroughBoundsCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
    @clippedThroughBoundsCache = @boundingBox()
    return @clippedThroughBoundsCache

  # using the code coverage tool from Chrome, it
  # doesn't seem that this is ever used
  # TODO investigate and see whether this is needed
  clipThrough: ->
    @checkClipThroughCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
    @clipThroughCache = @boundingBox()
    return @clipThroughCache

  pushBrokenRect: (brokenMorph, theRect, isSrc) ->
    if @duplicatedBrokenRectsTracker[theRect.toString()]?
      @numberOfDuplicatedBrokenRects++
    else
      if isSrc
        brokenMorph.srcBrokenRect = @broken.length
      else
        brokenMorph.dstBrokenRect = @broken.length
      if !theRect?
        debugger
      # if @broken.length == 0
      #  debugger
      @broken.push theRect
    @duplicatedBrokenRectsTracker[theRect.toString()] = true

  # using the code coverage tool from Chrome, it
  # doesn't seem that this is ever used
  # TODO investigate and see whether this is needed
  mergeBrokenRectsIfCloseOrPushBoth: (brokenMorph, sourceBroken, destinationBroken) ->
    mergedBrokenRect = sourceBroken.merge destinationBroken
    mergedBrokenRectArea = mergedBrokenRect.area()
    sumArea = sourceBroken.area() + destinationBroken.area()
    #console.log "mergedBrokenRectArea: " + mergedBrokenRectArea + " (sumArea + sumArea/10): " + (sumArea + sumArea/10)
    if mergedBrokenRectArea < sumArea + sumArea/10
      @pushBrokenRect brokenMorph, mergedBrokenRect, true
      @numberOfMergedSourceAndDestination++
    else
      @pushBrokenRect brokenMorph, sourceBroken, true
      @pushBrokenRect brokenMorph, destinationBroken, false


  checkARectWithHierarchy: (aRect, brokenMorph, isSrc) ->
    brokenMorphAncestor = brokenMorph

    #if brokenMorph instanceof SliderWdgt
    #  debugger

    while brokenMorphAncestor.parent?
      brokenMorphAncestor = brokenMorphAncestor.parent
      if brokenMorphAncestor.srcBrokenRect?
        if !@broken[brokenMorphAncestor.srcBrokenRect]?
          debugger
        if @broken[brokenMorphAncestor.srcBrokenRect].containsRectangle aRect
          if isSrc
            @broken[brokenMorph.srcBrokenRect] = nil
            brokenMorph.srcBrokenRect = nil
          else
            @broken[brokenMorph.dstBrokenRect] = nil
            brokenMorph.dstBrokenRect = nil
        else if aRect.containsRectangle @broken[brokenMorphAncestor.srcBrokenRect]
          @broken[brokenMorphAncestor.srcBrokenRect] = nil
          brokenMorphAncestor.srcBrokenRect = nil

      if brokenMorphAncestor.dstBrokenRect?
        if !@broken[brokenMorphAncestor.dstBrokenRect]?
          debugger
        if @broken[brokenMorphAncestor.dstBrokenRect].containsRectangle aRect
          if isSrc
            @broken[brokenMorph.srcBrokenRect] = nil
            brokenMorph.srcBrokenRect = nil
          else
            @broken[brokenMorph.dstBrokenRect] = nil
            brokenMorph.dstBrokenRect = nil
        else if aRect.containsRectangle @broken[brokenMorphAncestor.dstBrokenRect]
          @broken[brokenMorphAncestor.dstBrokenRect] = nil
          brokenMorphAncestor.dstBrokenRect = nil


  rectAlreadyIncludedInParentBrokenMorph: ->
    for brokenMorph in @morphsThatMaybeChangedGeometryOrPosition
        if brokenMorph.srcBrokenRect?
          aRect = @broken[brokenMorph.srcBrokenRect]
          @checkARectWithHierarchy aRect, brokenMorph, true
        if brokenMorph.dstBrokenRect?
          aRect = @broken[brokenMorph.dstBrokenRect]
          @checkARectWithHierarchy aRect, brokenMorph, false

    for brokenMorph in @morphsThatMaybeChangedFullGeometryOrPosition
        if brokenMorph.srcBrokenRect?
          aRect = @broken[brokenMorph.srcBrokenRect]
          @checkARectWithHierarchy aRect, brokenMorph
        if brokenMorph.dstBrokenRect?
          aRect = @broken[brokenMorph.dstBrokenRect]
          @checkARectWithHierarchy aRect, brokenMorph

  cleanupSrcAndDestRectsOfMorphs: ->
    for brokenMorph in @morphsThatMaybeChangedGeometryOrPosition
      brokenMorph.srcBrokenRect = nil
      brokenMorph.dstBrokenRect = nil
    for brokenMorph in @morphsThatMaybeChangedFullGeometryOrPosition
      brokenMorph.srcBrokenRect = nil
      brokenMorph.dstBrokenRect = nil


  fleshOutBroken: ->
    #if @morphsThatMaybeChangedGeometryOrPosition.length > 0
    #  debugger

    sourceBroken = nil
    destinationBroken = nil


    for brokenMorph in @morphsThatMaybeChangedGeometryOrPosition

      # let's see if this Widget that marked itself as broken
      # was actually painted in the past frame.
      # If it was then we have to clean up the "before" area
      # even if the Widget is not visible anymore
      if brokenMorph.clippedBoundsWhenLastPainted?
        if brokenMorph.clippedBoundsWhenLastPainted.isNotEmpty()
          sourceBroken = brokenMorph.clippedBoundsWhenLastPainted.expandBy(1).growBy @maxShadowSize

        #if brokenMorph!= world and (brokenMorph.clippedBoundsWhenLastPainted.containsPoint (new Point(10,10)))
        #  debugger

      # for the "destination" broken rectangle we can actually
      # check whether the Widget is still visible because we
      # can skip the destination rectangle in that case
      # (not the source one!)
      unless brokenMorph.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()
        # @clippedThroughBounds() should be smaller area
        # than bounds because it clips
        # the bounds based on the clipping morphs up the
        # hierarchy
        boundsToBeChanged = brokenMorph.clippedThroughBounds()

        if boundsToBeChanged.isNotEmpty()
          destinationBroken = boundsToBeChanged.spread().expandBy(1).growBy @maxShadowSize
          #if brokenMorph!= world and (boundsToBeChanged.spread().containsPoint new Point 10, 10)
          #  debugger


      if sourceBroken? and destinationBroken?
        @mergeBrokenRectsIfCloseOrPushBoth brokenMorph, sourceBroken, destinationBroken
      else if sourceBroken? or destinationBroken?
        if sourceBroken?
          @pushBrokenRect brokenMorph, sourceBroken, true
        else
          @pushBrokenRect brokenMorph, destinationBroken, true

      brokenMorph.geometryOrPositionPossiblyChanged = false
      brokenMorph.clippedBoundsWhenLastPainted = nil

    

  fleshOutFullBroken: ->
    #if @morphsThatMaybeChangedFullGeometryOrPosition.length > 0
    #  debugger

    sourceBroken = nil
    destinationBroken = nil

    for brokenMorph in @morphsThatMaybeChangedFullGeometryOrPosition

      #console.log "fleshOutFullBroken: " + brokenMorph

      if brokenMorph.fullClippedBoundsWhenLastPainted?
        if brokenMorph.fullClippedBoundsWhenLastPainted.isNotEmpty()
          sourceBroken = brokenMorph.fullClippedBoundsWhenLastPainted.expandBy(1).growBy @maxShadowSize

      # for the "destination" broken rectangle we can actually
      # check whether the Widget is still visible because we
      # can skip the destination rectangle in that case
      # (not the source one!)
      unless brokenMorph.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()

        boundsToBeChanged = brokenMorph.fullClippedBounds()

        if boundsToBeChanged.isNotEmpty()
          destinationBroken = boundsToBeChanged.spread().expandBy(1).growBy @maxShadowSize
          #if brokenMorph!= world and (boundsToBeChanged.spread().containsPoint (new Point(10,10)))
          #  debugger
      
   
      if sourceBroken? and destinationBroken?
        @mergeBrokenRectsIfCloseOrPushBoth brokenMorph, sourceBroken, destinationBroken
      else if sourceBroken? or destinationBroken?
        if sourceBroken?
          @pushBrokenRect brokenMorph, sourceBroken, true
        else
          @pushBrokenRect brokenMorph, destinationBroken, true

      brokenMorph.fullGeometryOrPositionPossiblyChanged = false
      brokenMorph.fullClippedBoundsWhenLastPainted = nil


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
  # that lives inside a floating morph, in which
  # case it's not re-layout.
  # So, a subtree might not be healed in one go,
  # rather we keep track of what's left to heal and
  # we apply the same process: we heal from the head node
  # and take out of the list what's healed in that step,
  # and we continue doing so until there is nothing else
  # to heal.
  recalculateLayouts: ->

    until @morphsThatMaybeChangedLayout.length == 0
      # starting from the last element,
      # find the first Widget which has a broken layout,
      # (and pop out of the queue all the Widgets we encounter
      # on the way that have a valid layout)
      loop
        tryThisMorph = @morphsThatMaybeChangedLayout[@morphsThatMaybeChangedLayout.length - 1]
        if tryThisMorph.layoutIsValid
          @morphsThatMaybeChangedLayout.pop()
          if @morphsThatMaybeChangedLayout.length == 0
            return
        else
          break

      # now that you have a Widget with a broken layout
      # go up the chain of broken layouts as much as
      # possible
      # TODO: it would be more correct to start from the
      # top-most invalid morph, i.e. on the way to the top,
      # stop at the last morph with an invalid layout
      # instead of stopping at the first morph with a
      # valid layout...
      # The reason is that a freefloating morph might
      # still need to be resized according to the size
      # of its parent, in which case you want the parent
      # to do its layout first, and then the freefloating
      # child to do its layout.
      # Otherwise what happens is that the freefloating
      # child will do its layout first according to the
      # wrong size of the parent, and then the
      # parent will have to re-layout it again, so the
      # doLayout of the freefloating child is called twice,
      # the first time wrongly.

      while tryThisMorph.parent?
        if tryThisMorph.layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING or tryThisMorph.parent.layoutIsValid
          break
        tryThisMorph = tryThisMorph.parent

      try
        # so now you have a "top" element up a chain
        # of morphs with broken layout. Go do a
        # doLayout on it, so it might fix a bunch of those
        # on the chain (but not all)
        tryThisMorph.doLayout()
      catch err
        @softResetWorld()
        if !@errorConsole? then @createErrorConsole()
        @errorConsole.contents.showUpWithError err


  clearGeometryOrPositionPossiblyChangedFlags: ->
    for m in @morphsThatMaybeChangedGeometryOrPosition
      m.geometryOrPositionPossiblyChanged = false

  clearFullGeometryOrPositionPossiblyChangedFlags: ->
    for m in @morphsThatMaybeChangedFullGeometryOrPosition
      m.fullGeometryOrPositionPossiblyChanged = false

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
    @rectAlreadyIncludedInParentBrokenMorph()
    @cleanupSrcAndDestRectsOfMorphs()

    @clearGeometryOrPositionPossiblyChangedFlags()
    @clearFullGeometryOrPositionPossiblyChangedFlags()

    @morphsThatMaybeChangedGeometryOrPosition = []
    @morphsThatMaybeChangedFullGeometryOrPosition = []
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
      @paintingWidget.silentHide()

  hideOffendingWidget: ->
    if !@widgetsGivingErrorWhileRepainting.includes @paintingWidget
      @widgetsGivingErrorWhileRepainting.push @paintingWidget
      @paintingWidget.silentHide()

  resetDataStructuresForBrokenRects: ->
    @broken = []
    @duplicatedBrokenRectsTracker = {}
    @numberOfDuplicatedBrokenRects = 0
    @numberOfMergedSourceAndDestination = 0

  # »>> this part is excluded from the fizzygum homepage build
  addPinoutingMorphs: ->
    @currentPinoutingMorphs.forEach (eachPinoutingMorph) =>
      if @morphsToBePinouted.has eachPinoutingMorph.wdgtThisWdgtIsPinouting
        if eachPinoutingMorph.wdgtThisWdgtIsPinouting.hasMaybeChangedGeometryOrPosition()
          # reposition the pinout morph if needed
          peekThroughBox = eachPinoutingMorph.wdgtThisWdgtIsPinouting.clippedThroughBounds()
          eachPinoutingMorph.fullRawMoveTo new Point(peekThroughBox.right() + 10,peekThroughBox.top())

      else
        @currentPinoutingMorphs.delete eachPinoutingMorph
        @morphsBeingPinouted.delete eachPinoutingMorph.wdgtThisWdgtIsPinouting
        eachPinoutingMorph.wdgtThisWdgtIsPinouting = nil
        eachPinoutingMorph.fullDestroy()

    @morphsToBePinouted.forEach (eachMorphNeedingPinout) =>
      unless @morphsBeingPinouted.has eachMorphNeedingPinout
        hM = new StringWdgt eachMorphNeedingPinout.toString()
        @add hM
        hM.wdgtThisWdgtIsPinouting = eachMorphNeedingPinout
        peekThroughBox = eachMorphNeedingPinout.clippedThroughBounds()
        hM.fullRawMoveTo new Point(peekThroughBox.right() + 10,peekThroughBox.top())
        hM.setColor Color.BLUE
        hM.setWidth 400
        @currentPinoutingMorphs.add hM
        @morphsBeingPinouted.add eachMorphNeedingPinout
  # this part is excluded from the fizzygum homepage build <<«
  
  addHighlightingMorphs: ->
    @currentHighlightingMorphs.forEach (eachHighlightingMorph) =>
      if @morphsToBeHighlighted.has eachHighlightingMorph.wdgtThisWdgtIsHighlighting
        if eachHighlightingMorph.wdgtThisWdgtIsHighlighting.hasMaybeChangedGeometryOrPosition()
          eachHighlightingMorph.rawSetBounds eachHighlightingMorph.wdgtThisWdgtIsHighlighting.clippedThroughBounds()
      else
        @currentHighlightingMorphs.delete eachHighlightingMorph
        @morphsBeingHighlighted.delete eachHighlightingMorph.wdgtThisWdgtIsHighlighting
        eachHighlightingMorph.wdgtThisWdgtIsHighlighting = nil
        eachHighlightingMorph.fullDestroy()

    @morphsToBeHighlighted.forEach (eachMorphNeedingHighlight) =>
      unless @morphsBeingHighlighted.has eachMorphNeedingHighlight
        hM = new HighlighterWdgt
        @add hM
        hM.wdgtThisWdgtIsHighlighting = eachMorphNeedingHighlight
        hM.rawSetBounds eachMorphNeedingHighlight.clippedThroughBounds()
        hM.setColor Color.BLUE
        hM.setAlphaScaled 50
        @currentHighlightingMorphs.add hM
        @morphsBeingHighlighted.add eachMorphNeedingHighlight


  # »>> this part is only needed for VideoPlayer
  draftRunVideoPlayer: ->
      videoPlayer = new WindowWdgt nil, nil, new VideoPlayerWithRecommendationsWdgt, true, true
      world.add videoPlayer
      videoPlayer.setExtent new Point 934, 896
      # it would be -28 instead of zero here below, but the system doesn't allow
      # to put windows outside of the screen
      videoPlayer.fullMoveTo new Point 174, 0

  # this part is only needed for VideoPlayer <<«


  playQueuedEvents: ->
    try

      timeOfCurrentCycleStart = WorldMorph.dateOfCurrentCycleStart.getTime()

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
        # WorldMorph.timeOfEventBeingProcessed): the hand's multi-click recognition
        # reads it to forget a stale double/triple-click candidate on an event-time
        # gap, deterministically — rather than depending on a wall-clock setTimeout.
        WorldMorph.timeOfEventBeingProcessed = event.time

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


  updateTimeReferences: ->
    WorldMorph.dateOfCurrentCycleStart = new Date
    if !WorldMorph.dateOfPreviousCycleStart?
      WorldMorph.dateOfPreviousCycleStart = new Date WorldMorph.dateOfCurrentCycleStart.getTime() - 30

    # »>> this part is only needed for Macros
    if !@macroToolkit.msSinceLastExecutedMacroStep?
      @macroToolkit.msSinceLastExecutedMacroStep = 0
    else
      @macroToolkit.msSinceLastExecutedMacroStep += WorldMorph.dateOfCurrentCycleStart.getTime() - WorldMorph.dateOfPreviousCycleStart.getTime()
    # this part is only needed for Macros <<«

  doOneCycle: ->
    @updateTimeReferences()

    @showErrorsHappenedInRepaintingStepInPreviousCycle()

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
    @hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()
    window.recalculatingLayouts = true
    @recalculateLayouts()
    window.recalculatingLayouts = false
    # »>> this part is excluded from the fizzygum homepage build
    @addPinoutingMorphs()
    # this part is excluded from the fizzygum homepage build <<«
    @addHighlightingMorphs()

    # here is where the repainting on screen happens
    @updateBroken()

    WorldMorph.frameCount++

    WorldMorph.dateOfPreviousCycleStart = WorldMorph.dateOfCurrentCycleStart
    WorldMorph.dateOfCurrentCycleStart = nil

  # Widget stepping:
  runChildrensStepFunction: ->


    # note that a widget can remove itself while stepping using the
    # Set.delete method. This is fine, because the forEach method
    # is not affected by the removal of elements while iterating.
    #
    # TODO all these set modifications should be immutable...
    @steppingWdgts.forEach (eachSteppingMorph) =>

      #if eachSteppingMorph.isBeingFloatDragged()
      #  continue

      # for objects where @fps is defined, check which ones are due to be stepped
      # and which ones want to wait.
      millisBetweenSteps = Math.round(1000 / eachSteppingMorph.fps)
      timeOfCurrentCycleStart = WorldMorph.dateOfCurrentCycleStart.getTime()

      if eachSteppingMorph.fps <= 0
        # if fps 0 or negative, then just run as fast as possible,
        # so 0 milliseconds remaining to the next invocation
        millisecondsRemainingToWaitedFrame = 0
      else
        if eachSteppingMorph.synchronisedStepping
          millisecondsRemainingToWaitedFrame = millisBetweenSteps - (timeOfCurrentCycleStart % millisBetweenSteps)
          if eachSteppingMorph.previousMillisecondsRemainingToWaitedFrame != 0 and millisecondsRemainingToWaitedFrame > eachSteppingMorph.previousMillisecondsRemainingToWaitedFrame
            millisecondsRemainingToWaitedFrame = 0
          eachSteppingMorph.previousMillisecondsRemainingToWaitedFrame = millisecondsRemainingToWaitedFrame
          #console.log millisBetweenSteps + " " + millisecondsRemainingToWaitedFrame
        else
          elapsedMilliseconds = timeOfCurrentCycleStart - eachSteppingMorph.lastTime
          millisecondsRemainingToWaitedFrame = millisBetweenSteps - elapsedMilliseconds
      
      # when the firing time comes (or as soon as it's past):
      if millisecondsRemainingToWaitedFrame <= 0
        @stepWidget eachSteppingMorph

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
        # while eachSteppingMorph.lastTime + millisBetweenSteps < timeOfCurrentCycleStart
        #   eachSteppingMorph.lastTime += millisBetweenSteps
        #
        # 3) and finally, here is the equivalent of the loop above, but done
        # in one shot using remainders.
        # Again: we are looking for the last "multiple" k such that
        #      lastTime + k * millisBetweenSteps
        # is less than timeOfCurrentCycleStart.

        eachSteppingMorph.lastTime = timeOfCurrentCycleStart - ((timeOfCurrentCycleStart - eachSteppingMorph.lastTime) % millisBetweenSteps)



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
      @rawSetExtent new Point clientWidth, clientHeight
      @desktopReLayout()
  

  desktopReLayout: ->
    basementOpenerWdgt = @firstChildSuchThat (w) ->
      w instanceof BasementOpenerWdgt
    if basementOpenerWdgt?
      if basementOpenerWdgt.userMovedThisFromComputedPosition
        basementOpenerWdgt.fullRawMoveInDesktopToFractionalPosition()
        if !basementOpenerWdgt.wasPositionedSlightlyOutsidePanel
          basementOpenerWdgt.fullRawMoveWithin @
      else
        basementOpenerWdgt.fullMoveTo @bottomRight().subtract (new Point 75, 75).add @desktopSidesPadding

    analogClockWdgt = @firstChildSuchThat (w) ->
      w instanceof AnalogClockWdgt
    if analogClockWdgt?
      if analogClockWdgt.userMovedThisFromComputedPosition
        analogClockWdgt.fullRawMoveInDesktopToFractionalPosition()
        if !analogClockWdgt.wasPositionedSlightlyOutsidePanel
          analogClockWdgt.fullRawMoveWithin @
      else
        analogClockWdgt.fullMoveTo new Point @right() - 80 - @desktopSidesPadding, @top() + @desktopSidesPadding

    @children.forEach (child) =>
      if child != basementOpenerWdgt and child != analogClockWdgt and  !(child instanceof WidgetHolderWithCaptionWdgt)
        if child.positionFractionalInHoldingPanel?
          child.fullRawMoveInDesktopToFractionalPosition()
        if !child.wasPositionedSlightlyOutsidePanel
          child.fullRawMoveWithin @
  
  # WorldMorph events:

  # »>> this part is excluded from the fizzygum homepage build
  initVirtualKeyboard: ->
    if @inputDOMElementForVirtualKeyboard
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = nil
    unless (WorldMorph.preferencesAndSettings.isTouchDevice and WorldMorph.preferencesAndSettings.useVirtualKeyboard)
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
    # button was released in the same morph
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
      # nothing here, although code for handling a "drop" is in the
      # comments
      event.preventDefault()
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
      
  # »>> this part is excluded from the fizzygum homepage build
  droppedImage: ->
    nil

  droppedSVG: ->
    nil
  # this part is excluded from the fizzygum homepage build <<«

  # WorldMorph text field tabbing:
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
  # dragging an invisible morph, etc.
  # So, try to clean-up things as much as possible.
  softResetWorld: ->
    @hand.drop()
    @hand.mouseOverList.clear()
    @hand.nonFloatDraggedWdgt = nil
    @wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.clear()
    @lastNonTextPropertyChangerButtonClickedOrDropped = nil

  # »>> this part is excluded from the fizzygum homepage build
  resetWorld: ->
    @softResetWorld()
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
  # how many morphs exist of each Widget class.
  # That counter is also used to determine the
  # unique ID of a Widget. So, destroying
  # all morphs from the world causes the
  # counts and IDs of all the subsequent
  # morphs to start from scratch again.
  fullDestroyChildren: ->
    # Check which objects end with the word Widget
    theWordMorph = "Morph"
    theWordWdgt = "Wdgt"
    theWordWidget = "Widget"
    ListOfMorphs = (Object.keys(window)).filter (i) ->
      i.includes(theWordMorph, i.length - theWordMorph.length) or
      i.includes(theWordWdgt, i.length - theWordWdgt.length) or
      i.includes(theWordWidget, i.length - theWordWidget.length)
    for eachMorphClass in ListOfMorphs
      if eachMorphClass != "WorldMorph"
        #console.log "resetting " + eachMorphClass + " from " + window[eachMorphClass].instancesCounter
        # the actual count is in another variable "instancesCounter"
        # but all labels are built using instanceNumericID
        # which is set based on lastBuiltInstanceNumericID
        window[eachMorphClass].lastBuiltInstanceNumericID = 0

    # »>> this part is excluded from the fizzygum homepage build
    if Automator?
      Automator.animationsPacingControl = false
      Automator.alignmentOfMorphIDsMechanism = false
      Automator.hidingOfMorphsContentExtractInLabels = false
      Automator.hidingOfMorphsNumberIDInLabels = false
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
  

  buildContextMenu: ->

    if @isIndexPage
      menu = new MenuMorph @, false, @, true, true, "Desktop"
      menu.addMenuItem "wallpapers ➜", false, @, "wallpapersMenu", "choose a wallpaper for the Desktop"
      menu.addMenuItem "new folder", true, @, "makeFolder"
      return menu

    if @isDevMode
      menu = new MenuMorph(@, false,
        @, true, true, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    else
      menu = new MenuMorph @, false, @, true, true, "Widgetic"

    # »>> this part is excluded from the fizzygum homepage build
    if @isDevMode
      menu.addMenuItem "demo ➜", false, @, "popUpDemoMenu", "sample morphs"
      menu.addLine()
      # TODO remove these two, they do nothing now
      menu.addMenuItem "show all", true, @, "noOperation"
      menu.addMenuItem "hide all", true, @, "noOperation"
      menu.addMenuItem "delete all", true, @, "closeChildren"
      menu.addMenuItem "move all inside", true, @, "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
      menu.addMenuItem "inspect", true, @, "inspect", "open a window on\nall properties"
      menu.addMenuItem "test menu ➜", false, @, "testMenu", "debugging and testing operations"
      menu.addLine()
      menu.addMenuItem "restore display", true, @, "changed", "redraw the\nscreen once"
      menu.addMenuItem "fit whole page", true, @, "stretchWorldToFillEntirePage", "let the World automatically\nadjust to browser resizings"
      menu.addMenuItem "color...", true, @, "popUpColorSetter", "choose the World's\nbackground color"
      menu.addMenuItem "wallpapers ➜", false, @, "wallpapersMenu", "choose a wallpaper for the Desktop"

      if WorldMorph.preferencesAndSettings.inputMode is PreferencesAndSettings.INPUT_MODE_MOUSE
        menu.addMenuItem "touch screen settings", true, WorldMorph.preferencesAndSettings, "toggleInputMode", "bigger menu fonts\nand sliders"
      else
        menu.addMenuItem "standard settings", true, WorldMorph.preferencesAndSettings, "toggleInputMode", "smaller menu fonts\nand sliders"
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

  wallpapersMenu: (a,targetMorph)->
    menu = new MenuMorph @, false, targetMorph, true, true, "Wallpapers"

    # we add the "untick" prefix to all entries
    # so we allocate the right amount of space for
    # the labels, we are going to put the
    # right ticks soon after
    menu.addMenuItem untick + @pattern1, true, @, "setPattern", nil, nil, nil, nil, nil, @pattern1
    menu.addMenuItem untick + @pattern2, true, @, "setPattern", nil, nil, nil, nil, nil, @pattern2
    menu.addMenuItem untick + @pattern3, true, @, "setPattern", nil, nil, nil, nil, nil, @pattern3
    menu.addMenuItem untick + @pattern4, true, @, "setPattern", nil, nil, nil, nil, nil, @pattern4
    menu.addMenuItem untick + @pattern5, true, @, "setPattern", nil, nil, nil, nil, nil, @pattern5
    menu.addMenuItem untick + @pattern6, true, @, "setPattern", nil, nil, nil, nil, nil, @pattern6
    menu.addMenuItem untick + @pattern7, true, @, "setPattern", nil, nil, nil, nil, nil, @pattern7

    @updatePatternsMenuEntriesTicks menu

    menu.popUpAtHand()

  setPattern: (menuItem, ignored2, thePatternName) ->
    if @patternName == thePatternName
      return

    @patternName = thePatternName
    @changed()

    if menuItem?.parent? and (menuItem.parent instanceof MenuMorph)
      @updatePatternsMenuEntriesTicks menuItem.parent


  # cheap way to keep menu consistency when pinned
  # note that there is no consistency in case
  # there are multiple copies of this menu changing
  # the wallpaper, since there is no real subscription
  # of a menu to react to wallpaper change coming
  # from other menus or other means (e.g. API)...
  updatePatternsMenuEntriesTicks: (menu) ->
    pattern1Tick = pattern2Tick = pattern3Tick =
    pattern4Tick = pattern5Tick = pattern6Tick =
    pattern7Tick = untick

    switch @patternName
      when @pattern1
        pattern1Tick = tick
      when @pattern2
        pattern2Tick = tick
      when @pattern3
        pattern3Tick = tick
      when @pattern4
        pattern4Tick = tick
      when @pattern5
        pattern5Tick = tick
      when @pattern6
        pattern6Tick = tick
      when @pattern7
        pattern7Tick = tick

    menu.children[1].label.setText pattern1Tick + @pattern1
    menu.children[2].label.setText pattern2Tick + @pattern2
    menu.children[3].label.setText pattern3Tick + @pattern3
    menu.children[4].label.setText pattern4Tick + @pattern4
    menu.children[5].label.setText pattern5Tick + @pattern5
    menu.children[6].label.setText pattern6Tick + @pattern6
    menu.children[7].label.setText pattern7Tick + @pattern7


  # »>> this part is excluded from the fizzygum homepage build
  popUpSystemTestsMenu: ->
    menu = new MenuMorph @, false, @, true, true, "system tests"

    menu.addMenuItem "run system tests (normal)", true, @automator.player, "runAllSystemTestsNormalSpeed", "runs all the system tests at the normal (slowest, watchable) speed level"
    menu.addMenuItem "run system tests (fast)", true, @automator.player, "runAllSystemTestsFastSpeed", "runs all the system tests at the fast (intermediate) speed level"
    menu.addMenuItem "run system tests (fastest)", true, @automator.player, "runAllSystemTestsFastestSpeed", "runs all the system tests at the fastest speed level"

    menu.addMenuItem "show test source", true, @automator, "showTestSource", "opens a window with the source of the latest test"
    menu.addMenuItem "save failed screenshots", true, @automator.player, "saveFailedScreenshots", "save failed screenshots"

    menu.popUpAtHand()
  # this part is excluded from the fizzygum homepage build <<«

  create: (aWdgt) ->
    aWdgt.pickUp()

  # »>> this part is excluded from the fizzygum homepage build
  createNewStackElementsSizeAdjustingMorph: ->
    @create new StackElementsSizeAdjustingWdgt

  createNewLayoutElementAdderOrDropletMorph: ->
    @create new LayoutElementAdderOrDropletWdgt

  createNewRectangleMorph: ->
    @create new RectangleWdgt
  createNewBoxMorph: ->
    @create new BoxWdgt
  createNewCircleBoxMorph: ->
    @create new CircleBoxWdgt
  createNewSliderMorph: ->
    @create new SliderWdgt
  createNewPanelWdgt: ->
    newWdgt = new PanelWdgt
    newWdgt.rawSetExtent new Point 350, 250
    @create newWdgt
  createNewScrollPanelWdgt: ->
    newWdgt = new ScrollPanelWdgt
    newWdgt.adjustContentsBounds()
    newWdgt.adjustScrollBars()
    newWdgt.rawSetExtent new Point 350, 250
    @create newWdgt
  createNewCanvas: ->
    newWdgt = new CanvasWdgt
    newWdgt.rawSetExtent new Point 350, 250
    @create newWdgt
  createNewHandle: ->
    @create new HandleWdgt
  createNewString: ->
    newWdgt = new StringWdgt "Hello, World!"
    newWdgt.isEditable = true
    @create newWdgt
  createNewText: ->
    newWdgt = new TextWdgt("Ich weiß nicht, was soll es bedeuten, dass ich so " +
      "traurig bin, ein Märchen aus uralten Zeiten, das " +
      "kommt mir nicht aus dem Sinn. Die Luft ist kühl " +
      "und es dunkelt, und ruhig fließt der Rhein; der " +
      "Gipfel des Berges funkelt im Abendsonnenschein. " +
      "Die schönste Jungfrau sitzet dort oben wunderbar, " +
      "ihr gold'nes Geschmeide blitzet, sie kämmt ihr " +
      "goldenes Haar, sie kämmt es mit goldenem Kamme, " +
      "und singt ein Lied dabei; das hat eine wundersame, " +
      "gewalt'ge Melodei. Den Schiffer im kleinen " +
      "Schiffe, ergreift es mit wildem Weh; er schaut " +
      "nicht die Felsenriffe, er schaut nur hinauf in " +
      "die Höh'. Ich glaube, die Wellen verschlingen " +
      "am Ende Schiffer und Kahn, und das hat mit ihrem " +
      "Singen, die Loreley getan.")
    newWdgt.isEditable = true
    # (maxTextWidth was an old-TextMorph-only knob; TextWdgt wraps to its own
    # width via softWrap, like the createNewTextWdgtWithBackground demo.)
    @create newWdgt
  createNewSpeechBubbleWdgt: ->
    newWdgt = new SpeechBubbleWdgt
    @create newWdgt
  createNewToolTipWdgt: ->
    newWdgt = new ToolTipWdgt
    @create newWdgt
  createNewGrayPaletteMorph: ->
    @create new GrayPaletteWdgt
  createNewColorPaletteMorph: ->
    @create new ColorPaletteWdgt
  createNewGrayPaletteMorphInWindow: ->
    gP = new GrayPaletteWdgt
    wm = new WindowWdgt nil, nil, gP
    @add wm
    wm.rawSetExtent new Point 130, 70
    wm.fullRawMoveTo @hand.position().subtract new Point 50, 100
  createNewColorPaletteMorphInWindow: ->
    cP = new ColorPaletteWdgt
    wm = new WindowWdgt nil, nil, cP
    @add wm
    wm.rawSetExtent new Point 130, 100
    wm.fullRawMoveTo @hand.position().subtract new Point 50, 100
  createNewColorPickerMorph: ->
    @create new ColorPickerWdgt
  createNewSensorDemo: ->
    newWdgt = new MouseSensorWdgt
    newWdgt.setColor Color.create 230, 200, 100
    newWdgt.cornerRadius = 35
    newWdgt.alpha = 0.2
    newWdgt.rawSetExtent new Point 100, 100
    @create newWdgt
  createNewAnimationDemo: ->
    foo = new BouncerMorph
    foo.fullRawMoveTo new Point 50, 20
    foo.rawSetExtent new Point 300, 200
    foo.alpha = 0.9
    foo.speed = 3
    bar = new BouncerMorph
    bar.setColor Color.create 50, 50, 50
    bar.fullRawMoveTo new Point 80, 80
    bar.rawSetExtent new Point 80, 250
    bar.type = "horizontal"
    bar.direction = "right"
    bar.alpha = 0.9
    bar.speed = 5
    baz = new BouncerMorph
    baz.setColor Color.create 20, 20, 20
    baz.fullRawMoveTo new Point 90, 140
    baz.rawSetExtent new Point 40, 30
    baz.type = "horizontal"
    baz.direction = "right"
    baz.speed = 3
    garply = new BouncerMorph
    garply.setColor Color.create 200, 20, 20
    garply.fullRawMoveTo new Point 90, 140
    garply.rawSetExtent new Point 20, 20
    garply.type = "vertical"
    garply.direction = "up"
    garply.speed = 8
    fred = new BouncerMorph
    fred.setColor Color.create 20, 200, 20
    fred.fullRawMoveTo new Point 120, 140
    fred.rawSetExtent new Point 20, 20
    fred.type = "vertical"
    fred.direction = "down"
    fred.speed = 4
    bar.add garply
    bar.add baz
    foo.add fred
    foo.add bar
    @create foo
  createNewPenMorph: ->
    @create new PenWdgt
  underTheCarpet: ->
    newWdgt = new BasementWdgt
    @create newWdgt


  popUpDemoMenu: (morphOpeningThePopUp,b,c,d) ->
    if @isIndexPage
      menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "parts bin"
      menu.addMenuItem "rectangle", true, @, "createNewRectangleMorph"
      menu.addMenuItem "box", true, @, "createNewBoxMorph"
      menu.addMenuItem "circle box", true, @, "createNewCircleBoxMorph"
      menu.addMenuItem "slider", true, @, "createNewSliderMorph"
      menu.addMenuItem "speech bubble", true, @, "createNewSpeechBubbleWdgt"
      menu.addLine()
      menu.addMenuItem "gray scale palette", true, @, "createNewGrayPaletteMorphInWindow"
      menu.addMenuItem "color palette", true, @, "createNewColorPaletteMorphInWindow"
      menu.addLine()
      menu.addMenuItem "analog clock", true, @, "analogClock"
    else
      menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "make a morph"
      menu.addMenuItem "rectangle", true, @, "createNewRectangleMorph"
      menu.addMenuItem "box", true, @, "createNewBoxMorph"
      menu.addMenuItem "circle box", true, @, "createNewCircleBoxMorph"
      menu.addLine()
      menu.addMenuItem "slider", true, @, "createNewSliderMorph"
      menu.addMenuItem "panel", true, @, "createNewPanelWdgt"
      menu.addMenuItem "scrollable panel", true, @, "createNewScrollPanelWdgt"
      menu.addMenuItem "canvas", true, @, "createNewCanvas"
      menu.addMenuItem "handle", true, @, "createNewHandle"
      menu.addLine()
      menu.addMenuItem "string", true, @, "createNewString"
      menu.addMenuItem "text", true, @, "createNewText"
      menu.addMenuItem "tool tip", true, @, "createNewToolTipWdgt"
      menu.addMenuItem "speech bubble", true, @, "createNewSpeechBubbleWdgt"
      menu.addLine()
      menu.addMenuItem "gray scale palette", true, @, "createNewGrayPaletteMorph"
      menu.addMenuItem "color palette", true, @, "createNewColorPaletteMorph"
      menu.addMenuItem "color picker", true, @, "createNewColorPickerMorph"
      menu.addLine()
      menu.addMenuItem "sensor demo", true, @, "createNewSensorDemo"
      menu.addMenuItem "animation demo", true, @, "createNewAnimationDemo"
      menu.addMenuItem "pen", true, @, "createNewPenMorph"
        
      menu.addLine()
      menu.addMenuItem "layout tests ➜", false, @, "layoutTestsMenu", "sample morphs"
      menu.addLine()
      menu.addMenuItem "under the carpet", true, @, "underTheCarpet"

    menu.popUpAtHand()

  layoutTestsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "Layout tests"
    menu.addMenuItem "adjuster morph", true, @, "createNewStackElementsSizeAdjustingMorph"
    menu.addMenuItem "adder/droplet", true, @, "createNewLayoutElementAdderOrDropletMorph"
    menu.addMenuItem "test screen 1", true, Widget, "setupTestScreen1"
    menu.popUpAtHand()
    
  
  toggleDevMode: ->
    @isDevMode = not @isDevMode
  # this part is excluded from the fizzygum homepage build <<«

  
  edit: (aStringMorphOrTextMorph) ->
    # first off, if the Widget is not editable
    # then there is nothing to do
    # return nil  unless aStringMorphOrTextMorph.isEditable

    # there is only one caret in the World, so destroy
    # the previous one if there was one.
    if @caret
      # empty the previously ongoing selection
      # if there was one.
      previouslyEditedText = @lastEditedText
      @lastEditedText = @caret.target
      if @lastEditedText != previouslyEditedText
        @lastEditedText.clearSelection()
      @caret = @caret.fullDestroy()

    # create the new Caret
    @caret = new CaretWdgt aStringMorphOrTextMorph
    aStringMorphOrTextMorph.parent.add @caret
    # the only place where the caret is added to the keyboardEventsReceivers
    @keyboardEventsReceivers.add @caret

    if WorldMorph.preferencesAndSettings.isTouchDevice and WorldMorph.preferencesAndSettings.useVirtualKeyboard
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
    #if WorldMorph.preferencesAndSettings.useSliderForInput
    #  if !aStringMorphOrTextMorph.parentThatIsA MenuMorph
    #    @slide aStringMorphOrTextMorph
  
  # Editing can stop because of three reasons:
  #   cancel (user hits ESC)
  #   accept (on stringmorph, user hits enter)
  #   user clicks/floatDrags another morph
  stopEditing: ->
    if @caret
      @lastEditedText = @caret.target
      @lastEditedText.clearSelection()
      @caret = @caret.fullDestroy()

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
