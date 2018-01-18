# WorldMorph //////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions
# REQUIRES PreferencesAndSettings
# REQUIRES Color
# REQUIRES ProfilingDataCollector
# REQUIRES SystemTestsControlPanelUpdater

# The WorldMorph takes over the canvas on the page
class WorldMorph extends FrameMorph

  # We need to add and remove
  # the event listeners so we are
  # going to put them all in properties
  # here.
  # dblclickEventListener: nil
  mousedownEventListener: nil
  touchstartEventListener: nil
  mouseupEventListener: nil
  touchendEventListener: nil
  mousemoveEventListener: nil
  touchmoveEventListener: nil
  gesturestartEventListener: nil
  gesturechangeEventListener: nil
  contextmenuEventListener: nil
  # Note how there can be two handlers for
  # keyboard events.
  # This one is attached
  # to the canvas and reaches the currently
  # blinking caret if there is one.
  # See below for the other potential
  # handler. See "initVirtualKeyboard"
  # method to see where and when this input and
  # these handlers are set up.
  keydownEventListener: nil
  keyupEventListener: nil
  keypressEventListener: nil
  mousewheelEventListener: nil
  DOMMouseScrollEventListener: nil
  copyEventListener: nil
  pasteEventListener: nil
  clipboardTextIfTestRunning: nil
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
  inputDOMElementForVirtualKeyboardKeydownEventListener: nil
  inputDOMElementForVirtualKeyboardKeyupEventListener: nil
  inputDOMElementForVirtualKeyboardKeypressEventListener: nil

  keyComboResetWorldEventListener: nil
  keyComboTurnOnAnimationsPacingControl: nil
  keyComboTurnOffAnimationsPacingControl: nil
  keyComboTakeScreenshotEventListener: nil
  keyComboStopTestRecordingEventListener: nil
  keyComboTakeScreenshotEventListener: nil
  keyComboCheckStringsOfItemsInMenuOrderImportant: nil
  keyComboCheckStringsOfItemsInMenuOrderUnimportant: nil
  keyComboAddTestCommentEventListener: nil
  keyComboCheckNumberOfMenuItemsEventListener: nil

  dragoverEventListener: nil
  dropEventListener: nil
  resizeEventListener: nil
  otherTasksToBeRunOnStep: []

  # these variables shouldn't be static to the WorldMorph, because
  # in pure theory you could have multiple worlds in the same
  # page with different settings
  # (but anyways, it was global before, so it's not any worse than before)
  @preferencesAndSettings: nil
  @currentTime: nil
  showRedraws: false
  doubleCheckCachedMethodsResults: false
  automatorRecorderAndPlayer: nil

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

  morphsDetectingClickOutsideMeOrAnyOfMeChildren: []
  hierarchyOfClickedMorphs: []
  hierarchyOfClickedMenus: []
  markedForDestruction: []
  freshlyCreatedMenus: []
  openMenus: []

  # boot-up state machine
  @BOOT_COMPLETE: 2
  @EXECUTING_URL_ACTIONS: 1
  @JUST_STARTED: 0
  @bootState: 0
  @ongoingUrlActionNumber: 0

  @frameCount: 0
  @numberOfAddsAndRemoves: 0
  @numberOfVisibilityFlagsChanges: 0
  @numberOfCollapseFlagsChanges: 0
  @numberOfRawMovesAndResizes: 0

  broken: nil
  duplicatedBrokenRectsTracker: nil
  numberOfDuplicatedBrokenRects: 0
  numberOfMergedSourceAndDestination: 0

  morphsToBeHighlighted: []
  currentHighlightingMorphs: []
  morphsBeingHighlighted: []

  morphsToBePinouted: []
  currentPinoutingMorphs: []
  morphsBeingPinouted: []

  steppingMorphs: []

  underTheCarpetMorph: nil

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

  events: []

  # Some operations are triggered by a callback
  # actioned via a timeout
  # e.g. see the cut and paste callbacks.
  # In such cases, we count how many outstanding
  # callbacks there are of this kind
  # (by adding elements to this stack when the
  # callback is scheduled, and popping them when
  # the callback is executed), so that
  # we can tell the automator player to PAUSE
  # execution of actions until the scheduled
  # callbacks are called. This is so turbo-mode macros
  # can be still run at maximum speed.
  # The alternative is to run at normal speed the
  # macros containing such cases, which
  # indeed would also take care of the problem
  # (as the callbacks are likely satisfied at running
  # time in the same span of time as when the macro
  # was recorded), but the "slow-play"
  # solution is more ad-hoc and is much much slower.
  outstandingTimerTriggeredOperationsCounter: []

  constructor: (
      @worldCanvas,
      @automaticallyAdjustToFillEntireBrowserAlsoOnResize = true
      ) ->

    # The WorldMorph is the very first morph to
    # be created.

    super()
    WorldMorph.preferencesAndSettings = new PreferencesAndSettings()
    #console.log WorldMorph.preferencesAndSettings.menuFontName
    @color = new Color 205, 205, 205 # (130, 130, 130)
    @strokeColor = nil

    @alpha = 1

    # additional properties:
    @stamp = Date.now() # reference in multi-world setups
    @isDevMode = false
    @hand = new HandMorph @
    @keyboardEventsReceiver = nil
    @lastEditedText = nil
    @caret = nil
    @temporaryHandlesAndLayoutAdjusters = []
    @inputDOMElementForVirtualKeyboard = nil

    if @automaticallyAdjustToFillEntireBrowserAlsoOnResize and !window.location.href.contains "worldWithSystemTestHarness"
      @stretchWorldToFillEntirePage()
    else
      @sizeCanvasToTestScreenResolution()

    # @worldCanvas.width and height here are in phisical pixels
    # so we want to bring them back to logical pixels
    @setBounds new Rectangle 0, 0, @worldCanvas.width / pixelRatio, @worldCanvas.height / pixelRatio

    @initEventListeners()
    @automatorRecorderAndPlayer = new AutomatorRecorderAndPlayer @, @hand

    @worldCanvasContext = @worldCanvas.getContext "2d"

    @canvasForTextMeasurements = newCanvas()
    @canvasContextForTextMeasurements = @canvasForTextMeasurements.getContext "2d"
    @canvasContextForTextMeasurements.scale pixelRatio, pixelRatio
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


    @changed()

  boot: ->

    if !window.location.href.contains "worldWithSystemTestHarness"
      @buildContextMenu= ->
        if @isDevMode
          menu = new MenuMorph @, false, @, true, true, "Fizzygum"
        else
          menu = new MenuMorph @, false, @, true, true, "Morphic"
        if @isDevMode
          menu.addMenuItem "parts bin ➜", false, @, "popUpDemoMenu", "sample morphs"
          menu.addMenuItem "delete all", true, @, "fullDestroy"
        menu
      @setColor new Color 244,243,244


    # boot-up state machine
    console.log "booting"
    @underTheCarpetMorph = new UnderTheCarpetMorph()
    WorldMorph.bootState = WorldMorph.JUST_STARTED

    ProfilingDataCollector.enableProfiling()
    ProfilingDataCollector.enableBrokenRectsProfiling()

    WorldMorph.ongoingUrlActionNumber= 0

    if !window.location.href.contains "worldWithSystemTestHarness"
      @errorConsole = new ErrorsLogViewerMorph "Errors", @, "modifyCodeToBeInjected", "no errors yet, phewww!"
      @add @errorConsole
      @errorConsole.fullMoveTo new Point 190,10
      @errorConsole.setExtent new Point 550,415
      @errorConsole.hide()

      welcomeTitle = new StringMorph2 "Welcome to Fizzygum!"
      welcomeTitle.isEditable = true
      @add welcomeTitle
      welcomeTitle.togglefittingSpecWhenBoundsTooLarge()
      welcomeTitle.fullMoveTo new Point 40, 15
      welcomeTitle.setExtent new Point 271, 35

      version = new StringMorph2 "version 2017-05-26"
      version.isEditable = true
      @add version
      version.togglefittingSpecWhenBoundsTooLarge()
      version.fullMoveTo new Point 41, 47
      version.setExtent new Point 134, 15

      welcomeMessage = """
      ...a small dynamic web desktop environment for experimenting with live programming, prototyping and mashups.

      Right-click on the desktop to try more widgets!
      """

      welcomeBody = new TextMorph2 welcomeMessage,nil,nil,nil,nil,nil,nil,nil
      welcomeBody.isEditable = true
      @add welcomeBody
      welcomeBody.fullMoveTo new Point 37, 80
      welcomeBody.setExtent new Point 340, 175

      reconfPaint = new ReconfigurablePaintMorph()
      @add reconfPaint
      reconfPaint.fullMoveTo new Point 35, 275
      reconfPaint.setExtent new Point 460, 400

      fmm = new FridgeMagnetsMorph()
      @add fmm
      fmm.fullMoveTo new Point 505, 275
      fmm.setExtent new Point 570, 400

      acm = new AnalogClockMorph()
      @add acm
      acm.fullMoveTo new Point 860, 40
      acm.setExtent new Point 200, 200

  # some test urls:

  # this one contains two actions, two tests each, but only
  # the second test is run for the second group.
  # file:///Users/daviddellacasa/Fizzygum/Fizzygum-builds/latest/worldWithSystemTestHarness.html?startupActions=%7B%0D%0A++%22paramsVersion%22%3A+0.1%2C%0D%0A++%22actions%22%3A+%5B%0D%0A++++%7B%0D%0A++++++%22name%22%3A+%22runTests%22%2C%0D%0A++++++%22testsToRun%22%3A+%5B%22bubble%22%5D%0D%0A++++%7D%2C%0D%0A++++%7B%0D%0A++++++%22name%22%3A+%22runTests%22%2C%0D%0A++++++%22testsToRun%22%3A+%5B%22shadow%22%2C+%22SystemTest_basicResize%22%5D%2C%0D%0A++++++%22numberOfGroups%22%3A+2%2C%0D%0A++++++%22groupToBeRun%22%3A+1%0D%0A++++%7D++%5D%0D%0A%7D
  #
  # just one simple quick test about shadows
  #file:///Users/daviddellacasa/Fizzygum/Fizzygum-builds/latest/worldWithSystemTestHarness.html?startupActions=%7B%0A%20%20%22paramsVersion%22%3A%200.1%2C%0A%20%20%22actions%22%3A%20%5B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22name%22%3A%20%22runTests%22%2C%0A%20%20%20%20%20%20%22testsToRun%22%3A%20%5B%22shadow%22%5D%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D

  nextStartupAction: ->
    startupActions = JSON.parse getParameterByName "startupActions"

    if (!startupActions?) or (WorldMorph.ongoingUrlActionNumber == startupActions.actions.length)
      WorldMorph.bootState = WorldMorph.BOOT_COMPLETE
      WorldMorph.ongoingUrlActionNumber = 0
      if window.location.href.indexOf("worldWithSystemTestHarness") != -1
        if @automatorRecorderAndPlayer.atLeastOneTestHasBeenRun
          if @automatorRecorderAndPlayer.allTestsPassedSoFar
            document.getElementById("background").style.background = "green"

    if WorldMorph.bootState == WorldMorph.BOOT_COMPLETE
      return

    console.log "nextStartupAction " + (WorldMorph.ongoingUrlActionNumber+1) + " / " + startupActions.actions.length

    currentAction = startupActions.actions[WorldMorph.ongoingUrlActionNumber]
    if currentAction.name == "runTests"
      @automatorRecorderAndPlayer.selectTestsFromTagsOrTestNames(currentAction.testsToRun)

      if currentAction.numberOfGroups?
        @automatorRecorderAndPlayer.numberOfGroups = currentAction.numberOfGroups
      else
        @automatorRecorderAndPlayer.numberOfGroups = 1
      if currentAction.groupToBeRun?
        @automatorRecorderAndPlayer.groupToBeRun = currentAction.groupToBeRun
      else
        @automatorRecorderAndPlayer.groupToBeRun = 0

      if currentAction.forceSlowTestPlaying?
        @automatorRecorderAndPlayer.forceSlowTestPlaying = true
      if currentAction.forceTurbo?
        @automatorRecorderAndPlayer.forceTurbo = true
      if currentAction.forceSkippingInBetweenMouseMoves?
        @automatorRecorderAndPlayer.forceSkippingInBetweenMouseMoves = true
      if currentAction.forceRunningInBetweenMouseMoves?
        @automatorRecorderAndPlayer.forceRunningInBetweenMouseMoves = true

      @automatorRecorderAndPlayer.runAllSystemTests()
    WorldMorph.ongoingUrlActionNumber++

  getMorphViaTextLabel: ([textDescription, occurrenceNumber, numberOfOccurrences]) ->
    allCandidateMorphsWithSameTextDescription = 
      @allChildrenTopToBottomSuchThat (m) ->
        m.getTextDescription() == textDescription

    return allCandidateMorphsWithSameTextDescription[occurrenceNumber]

  mostRecentlyCreatedMenu: ->
    mostRecentMenu = nil
    mostRecentMenuID = -1

    # we have to check which menus
    # are actually open, because
    # the destroy() function used
    # everywhere is not recursive and
    # that's where we update the @openMenus
    # array so we have to doublecheck here
    # note how we examine the array in reverse order
    # because we might delete its elements
    for i in [(@openMenus.length-1).. 0] by -1
      if @openMenus[i].isOrphan()
        @openMenus.splice i, 1

    for eachMenu in @openMenus
      if eachMenu.instanceNumericID >= mostRecentMenuID
        mostRecentMenu = eachMenu
    return mostRecentMenu

  # see roundNumericIDsToNextThousand method in
  # Morph for an explanation of why we need this
  # method.
  alignIDsOfNextMorphsInSystemTests: ->
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE
      # Check which objects end with the word Morph
      theWordMorph = "Morph"
      listOfMorphsClasses = (Object.keys(window)).filter (i) ->
        i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
      for eachMorphClass in listOfMorphsClasses
        #console.log "bumping up ID of class: " + eachMorphClass
        window[eachMorphClass].roundNumericIDsToNextThousand?()

  destroyMorphsMarkedForDestruction: ->
    for eachMorph in @markedForDestruction
      eachMorph.destroy()
    @markedForDestruction = []
  
  # World Morph broken rects debugging
  # not using it anywhere
  brokenFor: (aMorph) ->
    # private
    fb = aMorph.fullBounds()
    @broken.filter (rect) ->
      rect.isIntersecting fb
  
  
  # fullPaintIntoAreaOrBlitFromBackBuffer results into actual painting of pieces of
  # morphs done
  # by the paintIntoAreaOrBlitFromBackBuffer function.
  # The paintIntoAreaOrBlitFromBackBuffer function is defined in Morph.
  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, aRect) ->
    # invokes the Morph's fullPaintIntoAreaOrBlitFromBackBuffer, which has only three implementations:
    #  * the default one by Morph which just invokes the paintIntoAreaOrBlitFromBackBuffer of all children
    #  * the interesting one in FrameMorph which a) narrows the dirty
    #    rectangle (intersecting it with its border
    #    since the FrameMorph clips at its border) and b) stops recursion on all
    #    the children that are outside such intersection.
    #  * this implementation which just takes into account that the hand
    #    (which could contain a Morph being floatDragged)
    #    is painted on top of everything.
    super aContext, aRect

    # the mouse cursor is always drawn on top of everything
    # and it's not attached to the WorldMorph.
    @hand.fullPaintIntoAreaOrBlitFromBackBuffer aContext, aRect

  clippedThroughBounds: ->
    @checkClippedThroughBoundsCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
    @clippedThroughBoundsCache = @boundingBox()
    return @clippedThroughBoundsCache

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

    #if brokenMorph instanceof SliderMorph
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
    for brokenMorph in window.morphsThatMaybeChangedGeometryOrPosition
        if brokenMorph.srcBrokenRect?
          aRect = @broken[brokenMorph.srcBrokenRect]
          @checkARectWithHierarchy aRect, brokenMorph, true
        if brokenMorph.dstBrokenRect?
          aRect = @broken[brokenMorph.dstBrokenRect]
          @checkARectWithHierarchy aRect, brokenMorph, false

    for brokenMorph in window.morphsThatMaybeChangedFullGeometryOrPosition
        if brokenMorph.srcBrokenRect?
          aRect = @broken[brokenMorph.srcBrokenRect]
          @checkARectWithHierarchy aRect, brokenMorph
        if brokenMorph.dstBrokenRect?
          aRect = @broken[brokenMorph.dstBrokenRect]
          @checkARectWithHierarchy aRect, brokenMorph

  cleanupSrcAndDestRectsOfMorphs: ->
    for brokenMorph in window.morphsThatMaybeChangedGeometryOrPosition
      brokenMorph.srcBrokenRect = nil
      brokenMorph.dstBrokenRect = nil
    for brokenMorph in window.morphsThatMaybeChangedFullGeometryOrPosition
      brokenMorph.srcBrokenRect = nil
      brokenMorph.dstBrokenRect = nil


  fleshOutBroken: ->
    #if window.morphsThatMaybeChangedGeometryOrPosition.length > 0
    #  debugger

    sourceBroken = nil
    destinationBroken = nil


    for brokenMorph in window.morphsThatMaybeChangedGeometryOrPosition

      # let's see if this Morph that marked itself as broken
      # was actually painted in the past frame.
      # If it was then we have to clean up the "before" area
      # even if the Morph is not visible anymore
      if brokenMorph.clippedBoundsWhenLastPainted?
        if brokenMorph.clippedBoundsWhenLastPainted.isNotEmpty()
          sourceBroken = brokenMorph.clippedBoundsWhenLastPainted.growBy @maxShadowSize

        #if brokenMorph!= world and (brokenMorph.clippedBoundsWhenLastPainted.containsPoint (new Point(10,10)))
        #  debugger

      # for the "destination" broken rectangle we can actually
      # check whether the Morph is still visible because we
      # can skip the destination rectangle in that case
      # (not the source one!)
      unless brokenMorph.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()
        # @clippedThroughBounds() should be smaller area
        # than bounds because it clips
        # the bounds based on the clipping morphs up the
        # hierarchy
        boundsToBeChanged = brokenMorph.clippedThroughBounds()

        if boundsToBeChanged.isNotEmpty()
          destinationBroken = boundsToBeChanged.spread().growBy @maxShadowSize
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
    #if window.morphsThatMaybeChangedFullGeometryOrPosition.length > 0
    #  debugger

    sourceBroken = nil
    destinationBroken = nil

    for brokenMorph in window.morphsThatMaybeChangedFullGeometryOrPosition

      #console.log "fleshOutFullBroken: " + brokenMorph

      if brokenMorph.fullClippedBoundsWhenLastPainted?
        if brokenMorph.fullClippedBoundsWhenLastPainted.isNotEmpty()
          sourceBroken = brokenMorph.fullClippedBoundsWhenLastPainted.growBy @maxShadowSize

      # for the "destination" broken rectangle we can actually
      # check whether the Morph is still visible because we
      # can skip the destination rectangle in that case
      # (not the source one!)
      unless brokenMorph.surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage()

        boundsToBeChanged = brokenMorph.fullClippedBounds()

        if boundsToBeChanged.isNotEmpty()
          destinationBroken = boundsToBeChanged.spread().growBy @maxShadowSize
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


  showBrokenRects: (aContext) ->
    aContext.save()
    aContext.globalAlpha = 0.5
    aContext.scale pixelRatio, pixelRatio
 
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

    until morphsThatMaybeChangedLayout.length == 0

      # find the first Morph which has a broken layout,
      # take out of queue all the others
      loop
        tryThisMorph = morphsThatMaybeChangedLayout[morphsThatMaybeChangedLayout.length - 1]
        if tryThisMorph.layoutIsValid
          morphsThatMaybeChangedLayout.pop()
          if morphsThatMaybeChangedLayout.length == 0
            return
        else
          break

      # now that you have a Morph with a broken layout
      # go up the chain of broken layouts as much as
      # possible
      # QUESTION: would it be safer instead to start from the
      # very top invalid morph, i.e. on the way to the top,
      # stop at the last morph with an invalid layout
      # instead of stopping at the first morph with a
      # valid layout...
      while tryThisMorph.parent?
        if tryThisMorph.layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING or tryThisMorph.parent.layoutIsValid
          break
        tryThisMorph = tryThisMorph.parent

      # so now you have a "top" element up a chain
      # of morphs with broken layout. Go do a
      # doLayout on it, so it might fix a bunch of those
      # on the chain (but not all)
      tryThisMorph.doLayout()

  clearGeometryOrPositionPossiblyChangedFlags: ->
    for m in window.morphsThatMaybeChangedGeometryOrPosition
      m.geometryOrPositionPossiblyChanged = false

  clearFullGeometryOrPositionPossiblyChangedFlags: ->
    for m in window.morphsThatMaybeChangedFullGeometryOrPosition
      m.fullGeometryOrPositionPossiblyChanged = false

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

    window.morphsThatMaybeChangedGeometryOrPosition = []
    window.morphsThatMaybeChangedFullGeometryOrPosition = []
    #ProfilingDataCollector.profileBrokenRects @broken, @numberOfDuplicatedBrokenRects, @numberOfMergedSourceAndDestination

    # each broken rectangle requires traversing the scenegraph to
    # redraw what's overlapping it. Not all Morphs are traversed
    # in particular the following can stop the recursion:
    #  - invisible Morphs
    #  - FrameMorphs that don't overlap the broken rectangle
    # Since potentially there is a lot of traversal ongoin for
    # each broken rectangle, one might want to consolidate overlapping
    # and nearby rectangles.

    window.healingRectanglesPhase = true

    @broken.forEach (rect) =>
      if !rect?
        return
      if rect.isNotEmpty()
        @fullPaintIntoAreaOrBlitFromBackBuffer @worldCanvasContext, rect
    if world.showRedraws
      @showBrokenRects @worldCanvasContext

    @broken = []
    @duplicatedBrokenRectsTracker = {}
    @numberOfDuplicatedBrokenRects = 0
    @numberOfMergedSourceAndDestination = 0

    window.healingRectanglesPhase = false
    if trackChanges.length != 1 and trackChanges[0] != true
      alert "trackChanges array should have only one element (true)"

  addPinoutingMorphs: ->
    for eachPinoutingMorph in @currentPinoutingMorphs.slice()
      if eachPinoutingMorph.morphThisMorphIsPinouting in @morphsToBePinouted
        if eachPinoutingMorph.morphThisMorphIsPinouting.hasMaybeChangedGeometryOrPosition()
          # reposition the pinout morph if needed
          peekThroughBox = eachPinoutingMorph.morphThisMorphIsPinouting.clippedThroughBounds()
          eachPinoutingMorph.fullRawMoveTo new Point(peekThroughBox.right() + 10,peekThroughBox.top())

      else
        @currentPinoutingMorphs.remove eachPinoutingMorph
        @morphsBeingPinouted.remove eachPinoutingMorph.morphThisMorphIsPinouting
        eachPinoutingMorph.morphThisMorphIsPinouting = nil
        eachPinoutingMorph.destroy()

    for eachMorphNeedingPinout in @morphsToBePinouted.slice()
      if eachMorphNeedingPinout not in @morphsBeingPinouted
        hM = new StringMorph2 eachMorphNeedingPinout.toString()
        world.add hM
        hM.morphThisMorphIsPinouting = eachMorphNeedingPinout
        peekThroughBox = eachMorphNeedingPinout.clippedThroughBounds()
        hM.fullRawMoveTo new Point(peekThroughBox.right() + 10,peekThroughBox.top())
        hM.setColor new Color 0, 0, 255
        hM.setWidth 400
        @currentPinoutingMorphs.push hM
        @morphsBeingPinouted.push eachMorphNeedingPinout
  
  addHighlightingMorphs: ->
    for eachHighlightingMorph in @currentHighlightingMorphs.slice()
      if eachHighlightingMorph.morphThisMorphIsHighlighting in @morphsToBeHighlighted
        if eachHighlightingMorph.morphThisMorphIsHighlighting.hasMaybeChangedGeometryOrPosition()
          eachHighlightingMorph.rawSetBounds eachHighlightingMorph.morphThisMorphIsHighlighting.clippedThroughBounds()
      else
        @currentHighlightingMorphs.remove eachHighlightingMorph
        @morphsBeingHighlighted.remove eachHighlightingMorph.morphThisMorphIsHighlighting
        eachHighlightingMorph.morphThisMorphIsHighlighting = nil
        eachHighlightingMorph.destroy()

    for eachMorphNeedingHighlight in @morphsToBeHighlighted.slice()
      if eachMorphNeedingHighlight not in @morphsBeingHighlighted
        hM = new HighlighterMorph()
        world.add hM
        hM.morphThisMorphIsHighlighting = eachMorphNeedingHighlight
        hM.rawSetBounds eachMorphNeedingHighlight.clippedThroughBounds()
        hM.setColor new Color 0, 0, 255
        hM.setAlphaScaled 50
        @currentHighlightingMorphs.push hM
        @morphsBeingHighlighted.push eachMorphNeedingHighlight


  playQueuedEvents: ->
    for i in [0...@events.length] by 2
      eventType = @events[i]
      # note that these events are actually strings
      # in the case of clipboard events. Since
      # for security reasons clipboard access is not
      # allowed outside of the event listener, we
      # have to work with text here.
      event = @events[i+1]

      switch eventType

        when "inputDOMElementForVirtualKeyboardKeydownEventListener"
          @keyboardEventsReceiver.processKeyDown event  if @keyboardEventsReceiver

          if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
            @keyboardEventsReceiver.processKeyPress event  if @keyboardEventsReceiver

        when "inputDOMElementForVirtualKeyboardKeyupEventListener"
          # dispatch to keyboard receiver
          if @keyboardEventsReceiver
            # so far the caret is the only keyboard
            # event handler and it has no keyup
            # handler
            if @keyboardEventsReceiver.processKeyUp
              @keyboardEventsReceiver.processKeyUp event  

        when "inputDOMElementForVirtualKeyboardKeypressEventListener"
          @keyboardEventsReceiver.processKeyPress event  if @keyboardEventsReceiver

        when "mousedownEventListener"
          @processMouseDown event.button, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey

        when "touchstartEventListener"
          @hand.processTouchStart event

        when "mouseupEventListener"
          @processMouseUp  event.button, event.ctrlKey, event.buttons, event.shiftKey, event.altKey, event.metaKey

        when "touchendEventListener"
          @hand.processTouchEnd event

        when "mousemoveEventListener"
          posInDocument = getDocumentPositionOf @worldCanvas
          # events from JS arrive in page coordinates,
          # we turn those into world coordinates
          # instead.
          worldX = event.pageX - posInDocument.x
          worldY = event.pageY - posInDocument.y
          @processMouseMove worldX, worldY, event.button, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey

        when "touchmoveEventListener"
          @hand.processTouchMove event

        when "keydownEventListener"
          @processKeydown event, event.keyCode, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey

        when "keyupEventListener"
          @processKeyup event, event.keyCode, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey

        when "keypressEventListener"
          @processKeypress event, event.keyCode, @getChar(event), event.shiftKey, event.ctrlKey, event.altKey, event.metaKey

        when "mousewheelEventListener"
          @hand.processMouseScroll event

        when "DOMMouseScrollEventListener"
          @hand.processMouseScroll event

        when "cutEventListener"
          # note that "event" here is actually a string,
          # for security reasons clipboard access is not
          # allowed outside of the event listener, we
          # have to work with text here.
          @processCut event

        when "copyEventListener"
          # note that "event" here is actually a string,
          # for security reasons clipboard access is not
          # allowed outside of the event listener, we
          # have to work with text here.
          @processCopy event

        when "pasteEventListener"
          # note that "event" here is actually a string,
          # for security reasons clipboard access is not
          # allowed outside of the event listener, we
          # have to work with text here.
          @processPaste event

        when "dropEventListener"
          @hand.processDrop event

        when "resizeEventListener"
          @stretchWorldToFillEntirePage()  if @automaticallyAdjustToFillEntireBrowserAlsoOnResize

    @events = []

  # we keep the "pacing" promises in this
  # srcLoadsSteps array, (or, more precisely,
  # we keep their resolving functions) and each frame
  # we resolve one, so we don't cause gitter.
  loadAPartOfFizzyGumSourceIfNeeded: ->
    if window.srcLoadsSteps.length > 0
      resolvingFunction = window.srcLoadsSteps.shift()
      resolvingFunction.call()

  doOneCycle: ->
    WorldMorph.currentTime = Date.now()
    # console.log TextMorph.instancesCounter + " " + StringMorph.instancesCounter

    @playQueuedEvents()

    # most notably replays test actions at the right time
    @runOtherTasksStepFunction()
    @loadAPartOfFizzyGumSourceIfNeeded()
    
    @runChildrensStepFunction()
    @hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()
    window.recalculatingLayouts = true
    @recalculateLayouts()
    window.recalculatingLayouts = false
    @addPinoutingMorphs()
    @addHighlightingMorphs()
    @updateBroken()
    WorldMorph.frameCount++

  addSteppingMorph: (theMorph) ->
    if @steppingMorphs.indexOf(theMorph) == -1
      @steppingMorphs.push theMorph

  removeSteppingMorph: (theMorph) ->
    if @steppingMorphs.indexOf(theMorph) != -1
      @steppingMorphs.remove theMorph

  # Morph stepping:
  runChildrensStepFunction: ->

    # make a shallow copy of the array before iterating over
    # it in the case some morph destroyes itself and takes itself
    # out of the array thus changing it in place and mangling the
    # stepping.
    # TODO all these array modifications should be immutable...
    steppingMorphs = arrayShallowCopy @steppingMorphs

    for eachSteppingMorph in steppingMorphs
      if eachSteppingMorph.isBeingFloatDragged()
        continue
      # for objects where @fps is defined, check which ones are due to be stepped
      # and which ones want to wait.
      elapsedMilliseconds = WorldMorph.currentTime - eachSteppingMorph.lastTime
      if eachSteppingMorph.fps > 0
        millisecondsRemainingToWaitedFrame = (1000 / eachSteppingMorph.fps) - elapsedMilliseconds
      else
        # if fps 0 or negative, then just run as fast as possible,
        # so 0 milliseconds remaining to the next invokation
        millisecondsRemainingToWaitedFrame = 0
      
      # We could fire at the exact due time or when the time is past by
      # firing when remaining ms is <= 0
      # Or like in this case we can fire slightly earlier so to compensate
      # for when we come to fire late for one reason or the other.
      # There is no excat science in choosing to fire
      # a ms earlier here, it's quite random.
      # This whole mechanism will need to be remade anyways.
      if millisecondsRemainingToWaitedFrame <= 1
        eachSteppingMorph.lastTime = WorldMorph.currentTime
        if eachSteppingMorph.onNextStep
          nxt = eachSteppingMorph.onNextStep
          eachSteppingMorph.onNextStep = nil
          nxt.call eachSteppingMorph
        if !eachSteppingMorph.step?
          debugger
        try
          eachSteppingMorph.step()
        catch err
          @errorConsole.popUpWithError err


  
  runOtherTasksStepFunction : ->
    for task in @otherTasksToBeRunOnStep
      #console.log "running a task: " + task
      task()

  sizeCanvasToTestScreenResolution: ->
    @worldCanvas.width = Math.round(960 * pixelRatio)
    @worldCanvas.height = Math.round(440 * pixelRatio)
    @worldCanvas.style.width = "960px"
    @worldCanvas.style.height = "440px"

    bkground = document.getElementById("background")
    bkground.style.width = "960px"
    bkground.style.height = "720px"
    bkground.style.backgroundColor = "gb(245, 245, 245)"

  stretchWorldToFillEntirePage: ->
    pos = getDocumentPositionOf @worldCanvas
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
    if @worldCanvas.width isnt clientWidth
      @worldCanvas.width = (clientWidth * pixelRatio)
      @worldCanvas.style.width = clientWidth + "px"
      @rawSetWidth clientWidth
    if @worldCanvas.height isnt clientHeight
      @worldCanvas.height = (clientHeight * pixelRatio)
      @worldCanvas.style.height = clientHeight + "px"
      @rawSetHeight clientHeight
    @children.forEach (child) =>
      child.reactToWorldResize? @boundingBox()
  
    
  
  # WorldMorph events:
  initVirtualKeyboard: ->
    if @inputDOMElementForVirtualKeyboard
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = nil
    unless (WorldMorph.preferencesAndSettings.isTouchDevice and WorldMorph.preferencesAndSettings.useVirtualKeyboard)
      return
    @inputDOMElementForVirtualKeyboard = document.createElement "input"
    @inputDOMElementForVirtualKeyboard.type = "text"
    @inputDOMElementForVirtualKeyboard.style.color = "transparent"
    @inputDOMElementForVirtualKeyboard.style.backgroundColor = "transparent"
    @inputDOMElementForVirtualKeyboard.style.border = "none"
    @inputDOMElementForVirtualKeyboard.style.outline = "none"
    @inputDOMElementForVirtualKeyboard.style.position = "absolute"
    @inputDOMElementForVirtualKeyboard.style.top = "0px"
    @inputDOMElementForVirtualKeyboard.style.left = "0px"
    @inputDOMElementForVirtualKeyboard.style.width = "0px"
    @inputDOMElementForVirtualKeyboard.style.height = "0px"
    @inputDOMElementForVirtualKeyboard.autocapitalize = "none" # iOS specific
    document.body.appendChild @inputDOMElementForVirtualKeyboard

    @inputDOMElementForVirtualKeyboardKeydownEventListener = (event) =>
      @events.push "inputDOMElementForVirtualKeyboardKeydownEventListener"
      @events.push event
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
      @inputDOMElementForVirtualKeyboardKeydownEventListener, false

    @inputDOMElementForVirtualKeyboardKeyupEventListener = (event) =>
      @events.push "inputDOMElementForVirtualKeyboardKeyupEventListener"
      @events.push event
      event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keyup",
      @inputDOMElementForVirtualKeyboardKeyupEventListener, false

    @inputDOMElementForVirtualKeyboardKeypressEventListener = (event) =>
      @events.push "inputDOMElementForVirtualKeyboardKeypressEventListener"
      @events.push event
      event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keypress",
      @inputDOMElementForVirtualKeyboardKeypressEventListener, false

  getPointerAndMorphInfo:  (topMorphUnderPointer = @hand.topMorphUnderPointer()) ->
    # we might eliminate this command afterwards if
    # we find out user is clicking on a menu item
    # or right-clicking on a morph
    absoluteBoundsOfMorphRelativeToWorld = topMorphUnderPointer.boundingBox().asArray_xywh()
    morphIdentifierViaTextLabel = topMorphUnderPointer.identifyViaTextLabel()
    morphPathRelativeToWorld = topMorphUnderPointer.pathOfChildrenPositionsRelativeToWorld()
    pointerPositionFractionalInMorph = @hand.pointerPositionFractionalInMorph topMorphUnderPointer
    pointerPositionPixelsInMorph = @hand.pointerPositionPixelsInMorph topMorphUnderPointer
    # note that this pointer position is in world
    # coordinates not in page coordinates
    pointerPositionPixelsInWorld = @hand.position()
    isPartOfListMorph = (topMorphUnderPointer.parentThatIsA ListMorph)?
    return [ topMorphUnderPointer.uniqueIDString(), morphPathRelativeToWorld, morphIdentifierViaTextLabel, absoluteBoundsOfMorphRelativeToWorld, pointerPositionFractionalInMorph, pointerPositionPixelsInMorph, pointerPositionPixelsInWorld, isPartOfListMorph]


  addMouseChangeCommand: (upOrDown, button, buttons, ctrlKey, shiftKey, altKey, metaKey) ->
    pointerAndMorphInfo = @getPointerAndMorphInfo()
    @automatorRecorderAndPlayer.addMouseChangeCommand upOrDown, button, buttons, ctrlKey, shiftKey, altKey, metaKey, pointerAndMorphInfo...


  processMouseDown: (button, buttons, ctrlKey, shiftKey, altKey, metaKey) ->
    # the recording of the test command (in case we are
    # recording a test) is handled inside the function
    # here below.
    # This is different from the other methods similar
    # to this one but there is a little bit of
    # logic we apply in case there is a right-click,
    # or user left or right-clicks on a menu,
    # in which case we record a more specific test
    # commands.
    @addMouseChangeCommand "down", button, buttons, ctrlKey, shiftKey, altKey, metaKey
    @hand.processMouseDown button, buttons, ctrlKey, shiftKey, altKey, metaKey

  processMouseUp: (button, buttons, ctrlKey, shiftKey, altKey, metaKey) ->
    # event.preventDefault()

    @addMouseChangeCommand "up", button, buttons, ctrlKey, shiftKey, altKey, metaKey
    @hand.processMouseUp button, buttons, ctrlKey, shiftKey, altKey, metaKey

  processMouseMove: (pageX, pageY, button, buttons, ctrlKey, shiftKey, altKey, metaKey) ->
    @hand.processMouseMove pageX, pageY, button, buttons, ctrlKey, shiftKey, altKey, metaKey
    # "@hand.processMouseMove" could cause a Grab
    # command to be issued, so we want to
    # add the mouse move command here *after* the
    # potential grab command.

    if @hand.floatDraggingSomething()
      if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
        action = "floatDrag"
        arr = window.world.automatorRecorderAndPlayer.tagsCollectedWhileRecordingTest
        if action not in arr
          arr.push action
    
    @automatorRecorderAndPlayer.addMouseMoveCommand(pageX, pageY, @hand.floatDraggingSomething(), button, buttons, ctrlKey, shiftKey, altKey, metaKey)

  # event.type must be keypress
  getChar: (event) ->
    unless event.which?
      String.fromCharCode event.keyCode # IE
    else if event.which isnt 0 and event.charCode isnt 0
      String.fromCharCode event.which # the rest
    else
      nil # special key

  processKeydown: (event, scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    @automatorRecorderAndPlayer.addKeyDownCommand scanCode, shiftKey, ctrlKey, altKey, metaKey
    if @keyboardEventsReceiver
      @keyboardEventsReceiver.processKeyDown scanCode, shiftKey, ctrlKey, altKey, metaKey

    # suppress backspace override
    if event? and scanCode is 8
      event.preventDefault()

    # suppress tab override and make sure tab gets
    # received by all browsers
    if event? and scanCode is 9
      if @keyboardEventsReceiver
        @keyboardEventsReceiver.processKeyPress scanCode, "\t", shiftKey, ctrlKey, altKey, metaKey
      event.preventDefault()

  processKeyup: (event, scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    @automatorRecorderAndPlayer.addKeyUpCommand scanCode, shiftKey, ctrlKey, altKey, metaKey
    # dispatch to keyboard receiver
    if @keyboardEventsReceiver
      # so far the caret is the only keyboard
      # event handler and it has no keyup
      # handler
      if @keyboardEventsReceiver.processKeyUp
        @keyboardEventsReceiver.processKeyUp scanCode, shiftKey, ctrlKey, altKey, metaKey    
    if event?
      event.preventDefault()

  processKeypress: (event, charCode, symbol, shiftKey, ctrlKey, altKey, metaKey) ->
    @automatorRecorderAndPlayer.addKeyPressCommand charCode, symbol, shiftKey, ctrlKey, altKey, metaKey
    # This if block adapted from:
    # http://stackoverflow.com/a/16033129
    # it rejects the
    # characters from the special
    # test-command-triggering external
    # keypad. Also there is a "00" key
    # in such keypads which is implemented
    # buy just a double-press of the zero.
    # We manage that case - if that key is
    # pressed twice we understand that it's
    # that particular key. Managing this
    # special case within Fizzygum
    # is not best, but there aren't any
    # good alternatives.
    if event?
      # don't manage external keypad if we are playing back
      # the tests (i.e. when event is nil)
      if symbol == @constructor.KEYPAD_0_mappedToThaiKeyboard_Q
        unless @doublePressOfZeroKeypadKey?
          @doublePressOfZeroKeypadKey = 1
          setTimeout (=>
            if @doublePressOfZeroKeypadKey is 1
              console.log "single keypress"
            @doublePressOfZeroKeypadKey = nil
            event.keyCode = 0
            return false
          ), 300
        else
          @doublePressOfZeroKeypadKey = nil
          console.log "double keypress"
          event.keyCode = 0
        return false

    if @keyboardEventsReceiver
      @keyboardEventsReceiver.processKeyPress charCode, symbol, shiftKey, ctrlKey, altKey, metaKey
    if event?
      event.preventDefault()

  # -----------------------------------------------------
  # clipboard events processing
  # -----------------------------------------------------
  # clipboard events take a text instead of the event,
  # the reason is that you can't access the clipboard
  # outside of the EventListener, I presume for
  # security reasons. So, since these process* methods
  # are executed outside of the listeners, we really can't use
  # the event and the clipboard object in the event, so
  # we have to work with text. The clipboard IS handled, but
  # it's handled in the listeners

  processCut: (selectedText) ->
    console.log "processing cut"
    if @caret
      # see comment on outstandingTimerTriggeredOperationsCounter
      # above where the property is declared and initialised.
      @outstandingTimerTriggeredOperationsCounter.push true
      window.setTimeout ( =>
       @caret.deleteLeft()
       @outstandingTimerTriggeredOperationsCounter.pop()
      ), 50, true

    @automatorRecorderAndPlayer.addCutCommand selectedText

  processCopy: (selectedText) ->
    console.log "processing copy"
    @automatorRecorderAndPlayer.addCopyCommand selectedText

  processPaste: (clipboardText) ->
    if @caret
      # Needs a few msec to execute paste
      console.log "about to insert text: " + clipboardText
      @automatorRecorderAndPlayer.addPasteCommand clipboardText

      # see comment on outstandingTimerTriggeredOperationsCounter
      # above where the property is declared and initialised.
      @outstandingTimerTriggeredOperationsCounter.push true
      window.setTimeout ( =>
       @caret.insert clipboardText
       @outstandingTimerTriggeredOperationsCounter.pop()
      ), 50, true


  # note that we don't register the normal click,
  # we figure that out independently.
  initEventListeners: ->
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

    @mousedownEventListener = (event) =>
      @events.push "mousedownEventListener"
      @events.push event

    canvas.addEventListener "mousedown", @mousedownEventListener, false

    @touchstartEventListener = (event) =>
      @events.push "touchstartEventListener"
      @events.push event

    canvas.addEventListener "touchstart", @touchstartEventListener , false
    
    @mouseupEventListener = (event) =>
      @events.push "mouseupEventListener"
      @events.push event

    canvas.addEventListener "mouseup", @mouseupEventListener, false
    
    @touchendEventListener = (event) =>
      @events.push "touchendEventListener"
      @events.push event

    canvas.addEventListener "touchend", @touchendEventListener, false
    
    @mousemoveEventListener = (event) =>
      @events.push "mousemoveEventListener"
      @events.push event

    canvas.addEventListener "mousemove", @mousemoveEventListener, false
    
    @touchmoveEventListener = (event) =>
      @events.push "touchmoveEventListener"
      @events.push event

    canvas.addEventListener "touchmove", @touchmoveEventListener, false
    
    @gesturestartEventListener = (event) =>
      # Disable browser zoom
      event.preventDefault()
    canvas.addEventListener "gesturestart", @gesturestartEventListener, false
    
    @gesturechangeEventListener = (event) =>
      # Disable browser zoom
      event.preventDefault()
    canvas.addEventListener "gesturechange", @gesturechangeEventListener, false
    
    @contextmenuEventListener = (event) ->
      # suppress context menu for Mac-Firefox
      event.preventDefault()
    canvas.addEventListener "contextmenu", @contextmenuEventListener, false
    
    @keydownEventListener = (event) =>
      @events.push "keydownEventListener"
      @events.push event

      # this paragraph is to prevent the browser going
      # "back button" when the user presses delete backspace.
      # taken from http://stackoverflow.com/a/2768256
      doPrevent = false
      if event.keyCode == 8
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
      if doPrevent
        event.preventDefault()

    canvas.addEventListener "keydown", @keydownEventListener, false

    @keyupEventListener = (event) =>
      @events.push "keyupEventListener"
      @events.push event

    canvas.addEventListener "keyup", @keyupEventListener, false

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
    
    @keypressEventListener = (event) =>
      @events.push "keypressEventListener"
      @events.push event

    canvas.addEventListener "keypress", @keypressEventListener, false

    # Safari, Chrome
    
    @mousewheelEventListener = (event) =>
      @events.push "mousewheelEventListener"
      @events.push event
      event.preventDefault()

    canvas.addEventListener "mousewheel", @mousewheelEventListener, false
    # Firefox
    
    @DOMMouseScrollEventListener = (event) =>
      @events.push "DOMMouseScrollEventListener"
      @events.push event
      event.preventDefault()

    canvas.addEventListener "DOMMouseScroll", @DOMMouseScrollEventListener, false

    # in theory there should be no scroll event on the page
    # window.addEventListener "scroll", ((event) =>
    #  nop # nothing to do, I just need this to set an interrupt point.
    # ), false

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

    @cutEventListener = (event) =>
      selectedText = ""
      if @caret
        selectedText = @caret.target.selection()
        if event?.clipboardData
          event.preventDefault()
          setStatus = event.clipboardData.setData "text/plain", selectedText

        if window.clipboardData
          event.returnValue = false
          setStatus = window.clipboardData.setData "Text", selectedText

      @events.push "cutEventListener"
      @events.push selectedText

    document.body.addEventListener "cut", @cutEventListener, false
    
    @copyEventListener = (event) =>
      selectedText = ""
      if @caret
        if clipboardTextIfTestRunning?
          selectedText = clipboardTextIfTestRunning
        else
          selectedText = @caret.target.selection()
        if event?.clipboardData
          event.preventDefault()
          setStatus = event.clipboardData.setData "text/plain", selectedText

        if window.clipboardData
          event.returnValue = false
          setStatus = window.clipboardData.setData "Text", selectedText

      @events.push "copyEventListener"
      @events.push selectedText

    document.body.addEventListener "copy", @copyEventListener, false

    @pasteEventListener = (event) =>
      if @caret
        if event?
          if event.clipboardData
            # Look for access to data if types array is missing
            text = event.clipboardData.getData "text/plain"
            #url = event.clipboardData.getData("text/uri-list")
            #html = event.clipboardData.getData("text/html")
            #custom = event.clipboardData.getData("text/xcustom")
          # IE event is attached to the window object
          if window.clipboardData
            # The schema is fixed
            text = window.clipboardData.getData "Text"
            #url = window.clipboardData.getData "URL"

      @events.push "pasteEventListener"
      @events.push text

    document.body.addEventListener "paste", @pasteEventListener, false

    #console.log "binding via mousetrap"

    @keyComboResetWorldEventListener = (event) =>
      @automatorRecorderAndPlayer.resetWorld()
      false
    Mousetrap.bind ["alt+d"], @keyComboResetWorldEventListener

    @keyComboTurnOnAnimationsPacingControl = (event) =>
      @automatorRecorderAndPlayer.turnOnAnimationsPacingControl()
      false
    Mousetrap.bind ["alt+e"], @keyComboTurnOnAnimationsPacingControl

    @keyComboTurnOffAnimationsPacingControl = (event) =>
      @automatorRecorderAndPlayer.turnOffAnimationsPacingControl()
      false
    Mousetrap.bind ["alt+u"], @keyComboTurnOffAnimationsPacingControl

    @keyComboTakeScreenshotEventListener = (event) =>
      @automatorRecorderAndPlayer.takeScreenshot()
      false
    Mousetrap.bind ["alt+c"], @keyComboTakeScreenshotEventListener

    @keyComboStopTestRecordingEventListener = (event) =>
      @automatorRecorderAndPlayer.stopTestRecording()
      false
    Mousetrap.bind ["alt+t"], @keyComboStopTestRecordingEventListener

    @keyComboAddTestCommentEventListener = (event) =>
      @automatorRecorderAndPlayer.addTestComment()
      false
    Mousetrap.bind ["alt+m"], @keyComboAddTestCommentEventListener

    @keyComboCheckNumberOfMenuItemsEventListener = (event) =>
      @automatorRecorderAndPlayer.checkNumberOfItemsInMenu()
      false
    Mousetrap.bind ["alt+k"], @keyComboCheckNumberOfMenuItemsEventListener

    @keyComboCheckStringsOfItemsInMenuOrderImportant = (event) =>
      @automatorRecorderAndPlayer.checkStringsOfItemsInMenuOrderImportant()
      false
    Mousetrap.bind ["alt+a"], @keyComboCheckStringsOfItemsInMenuOrderImportant

    @keyComboCheckStringsOfItemsInMenuOrderUnimportant = (event) =>
      @automatorRecorderAndPlayer.checkStringsOfItemsInMenuOrderUnimportant()
      false
    Mousetrap.bind ["alt+z"], @keyComboCheckStringsOfItemsInMenuOrderUnimportant

    @dragoverEventListener = (event) ->
      event.preventDefault()
    window.addEventListener "dragover", @dragoverEventListener, false
    
    @dropEventListener = (event) =>
      @events.push "dropEventListener"
      @events.push event
      event.preventDefault()
    window.addEventListener "drop", @dropEventListener, false
    
    @resizeEventListener = =>
      @events.push "resizeEventListener"
      @events.push nil

    # this is a DOM thing, little to do with other r e s i z e methods
    window.addEventListener "resize", @resizeEventListener, false
    
  
  removeEventListeners: ->
    canvas = @worldCanvas
    # canvas.removeEventListener 'dblclick', @dblclickEventListener
    canvas.removeEventListener 'mousedown', @mousedownEventListener
    canvas.removeEventListener 'touchstart', @touchstartEventListener
    canvas.removeEventListener 'mouseup', @mouseupEventListener
    canvas.removeEventListener 'touchend', @touchendEventListener
    canvas.removeEventListener 'mousemove', @mousemoveEventListener
    canvas.removeEventListener 'touchmove', @touchmoveEventListener
    canvas.removeEventListener 'gesturestart', @gesturestartEventListener
    canvas.removeEventListener 'gesturechange', @gesturechangeEventListener
    canvas.removeEventListener 'contextmenu', @contextmenuEventListener
    canvas.removeEventListener 'keydown', @keydownEventListener
    canvas.removeEventListener 'keyup', @keyupEventListener
    canvas.removeEventListener 'keypress', @keypressEventListener
    canvas.removeEventListener 'mousewheel', @mousewheelEventListener
    canvas.removeEventListener 'DOMMouseScroll', @DOMMouseScrollEventListener
    canvas.removeEventListener 'cut', @cutEventListener
    canvas.removeEventListener 'copy', @copyEventListener
    canvas.removeEventListener 'paste', @pasteEventListener
    Mousetrap.reset()
    canvas.removeEventListener 'dragover', @dragoverEventListener
    canvas.removeEventListener 'drop', @dropEventListener
    canvas.removeEventListener 'resize', @resizeEventListener
  
  mouseDownLeft: ->
    noOperation
  
  mouseClickLeft: ->
    noOperation
  
  mouseDownRight: ->
    noOperation
      
  droppedImage: ->
    nil

  droppedSVG: ->
    nil  

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
    next.bringToForegroud()
    next.selectAll()
    next.edit()


  resetWorld: ->
    @hand.drop()
    @changed() # redraw the whole screen
    @hand.mouseOverList = []
    @hand.nonFloatDraggedMorph = nil
    @fullDestroyChildren()
    # some tests might change the background
    # color of the world so let's reset it.
    @setColor new Color 205, 205, 205
    SystemTestsControlPanelUpdater.blinkLink SystemTestsControlPanelUpdater.resetWorldLink
    # make sure thw window is scrolled to top
    # so we can see the test results while tests
    # are running.
    document.body.scrollTop = document.documentElement.scrollTop = 0    
  
  # There is something special about the
  # "world" version of fullDestroyChildren:
  # it resets the counter used to count
  # how many morphs exist of each Morph class.
  # That counter is also used to determine the
  # unique ID of a Morph. So, destroying
  # all morphs from the world causes the
  # counts and IDs of all the subsequent
  # morphs to start from scratch again.
  fullDestroyChildren: ->
    # Check which objects end with the word Morph
    theWordMorph = "Morph"
    ListOfMorphs = (Object.keys(window)).filter (i) ->
      i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
    for eachMorphClass in ListOfMorphs
      if eachMorphClass != "WorldMorph"
        #console.log "resetting " + eachMorphClass + " from " + window[eachMorphClass].instancesCounter
        # the actual count is in another variable "instancesCounter"
        # but all labels are built using instanceNumericID
        # which is set based on lastBuiltInstanceNumericID
        window[eachMorphClass].lastBuiltInstanceNumericID = 0

    window.world.automatorRecorderAndPlayer.turnOffAnimationsPacingControl()
    window.world.automatorRecorderAndPlayer.turnOffAlignmentOfMorphIDsMechanism()
    window.world.automatorRecorderAndPlayer.turnOffHidingOfMorphsContentExtractInLabels()
    window.world.automatorRecorderAndPlayer.turnOffHidingOfMorphsNumberIDInLabels()

    super()

  buildContextMenu: ->
    if @isDevMode
      menu = new MenuMorph(@, false, 
        @, true, true, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    else
      menu = new MenuMorph @, false, @, true, true, "Morphic"
    if @isDevMode
      menu.addMenuItem "demo ➜", false, @, "popUpDemoMenu", "sample morphs"
      menu.addLine()
      menu.addMenuItem "show all", true, @, "showAllMinimised"
      menu.addMenuItem "hide all", true, @, "minimiseAll"
      menu.addMenuItem "delete all", true, @, "fullDestroy"
      menu.addMenuItem "move all inside", true, @, "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
      menu.addMenuItem "inspect", true, @, "inspect", "open a window on\nall properties"
      menu.addMenuItem "test menu ➜", false, @, "testMenu", "debugging and testing operations"
      menu.addLine()
      menu.addMenuItem "restore display", true, @, "changed", "redraw the\nscreen once"
      menu.addMenuItem "fit whole page", true, @, "stretchWorldToFillEntirePage", "let the World automatically\nadjust to browser resizings"
      menu.addMenuItem "color...", true, @, "popUpColorSetter", "choose the World's\nbackground color"
      if WorldMorph.preferencesAndSettings.inputMode is PreferencesAndSettings.INPUT_MODE_MOUSE
        menu.addMenuItem "touch screen settings", true, WorldMorph.preferencesAndSettings, "toggleInputMode", "bigger menu fonts\nand sliders"
      else
        menu.addMenuItem "standard settings", true, WorldMorph.preferencesAndSettings, "toggleInputMode", "smaller menu fonts\nand sliders"
      menu.addLine()
    
    if window.location.href.contains "worldWithSystemTestHarness"
      menu.addMenuItem "system tests ➜", false, @, "popUpSystemTestsMenu", ""
    if @isDevMode
      menu.addMenuItem "switch to user mode", true, @, "toggleDevMode", "disable developers'\ncontext menus"
    else
      menu.addMenuItem "switch to dev mode", true, @, "toggleDevMode"
    menu.addMenuItem "about Fizzygum...", true, @, "about"
    menu

  popUpSystemTestsMenu: ->
    menu = new MenuMorph @, false, @, true, true, "system tests"

    menu.addMenuItem "run system tests", true, @automatorRecorderAndPlayer, "runAllSystemTests", "runs all the system tests"
    menu.addMenuItem "run system tests force slow", true, @automatorRecorderAndPlayer, "runAllSystemTestsForceSlow", "runs all the system tests"
    menu.addMenuItem "run system tests force fast skip in-between mouse moves", true, @automatorRecorderAndPlayer, "runAllSystemTestsForceFastSkipInbetweenMouseMoves", "runs all the system tests"
    menu.addMenuItem "run system tests force fast run in-between mouse moves", true, @automatorRecorderAndPlayer, "runAllSystemTestsForceFastRunInbetweenMouseMoves", "runs all the system tests"

    menu.addMenuItem "start test recording", true, @automatorRecorderAndPlayer, "startTestRecording", "start recording a test"
    menu.addMenuItem "stop test recording", true, @automatorRecorderAndPlayer, "stopTestRecording", "stop recording the test"

    menu.addMenuItem "(re)play recorded test slow", true, @automatorRecorderAndPlayer, "startTestPlayingSlow", "start playing the test"
    menu.addMenuItem "(re)play recorded test fast skip in-between mouse moves", true, @automatorRecorderAndPlayer, "startTestPlayingFastSkipInbetweenMouseMoves", "start playing the test"
    menu.addMenuItem "(re)play recorded test  fast run in-between mouse moves", true, @automatorRecorderAndPlayer, "startTestPlayingFastRunInbetweenMouseMoves", "start playing the test"

    menu.addMenuItem "show test source", true, @automatorRecorderAndPlayer, "showTestSource", "opens a window with the source of the latest test"
    menu.addMenuItem "save recorded test", true, @automatorRecorderAndPlayer, "saveTest", "save the recorded test"
    menu.addMenuItem "save failed screenshots", true, @automatorRecorderAndPlayer, "saveFailedScreenshots", "save failed screenshots"

    menu.popUpAtHand()

  create: (aMorph) ->
    aMorph.pickUp()

  createNewStackElementsSizeAdjustingMorph: ->
    @create new StackElementsSizeAdjustingMorph()

  createNewLayoutElementAdderOrDropletMorph: ->
    @create new LayoutElementAdderOrDropletMorph()

  createNewRectangleMorph: ->
    @create new RectangleMorph()
  createNewBoxMorph: ->
    @create new BoxMorph()
  createNewCircleBoxMorph: ->
    @create new CircleBoxMorph()
  createNewSliderMorph: ->
    @create new SliderMorph()
  createNewFrameMorph: ->
    newMorph = new FrameMorph()
    newMorph.rawSetExtent new Point 350, 250
    @create newMorph
  createNewScrollPanel: ->
    newMorph = new ScrollPanel()
    newMorph.adjustContentsBounds()
    newMorph.adjustScrollBars()
    newMorph.rawSetExtent new Point 350, 250
    @create newMorph
  createNewCanvas: ->
    newMorph = new CanvasMorph()
    newMorph.rawSetExtent new Point 350, 250
    @create newMorph
  createNewHandle: ->
    @create new HandleMorph()
  createNewString: ->
    newMorph = new StringMorph "Hello, World!"
    newMorph.isEditable = true
    @create newMorph
  createNewText: ->
    newMorph = new TextMorph("Ich weiß nicht, was soll es bedeuten, dass ich so " +
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
    newMorph.isEditable = true
    newMorph.maxTextWidth = 300
    @create newMorph
  createNewSpeechBubbleMorph: ->
    newMorph = new SpeechBubbleMorph "Hello, World!"
    @create newMorph
  createNewGrayPaletteMorph: ->
    @create new GrayPaletteMorph()
  createNewColorPaletteMorph: ->
    @create new ColorPaletteMorph()
  createNewColorPickerMorph: ->
    @create new ColorPickerMorph()
  createNewSensorDemo: ->
    newMorph = new MouseSensorMorph()
    newMorph.setColor new Color 230, 200, 100
    newMorph.cornerRadius = 35
    newMorph.alpha = 0.2
    newMorph.rawSetExtent new Point 100, 100
    @create newMorph
  createNewAnimationDemo: ->
    foo = new BouncerMorph()
    foo.fullRawMoveTo new Point 50, 20
    foo.rawSetExtent new Point 300, 200
    foo.alpha = 0.9
    foo.speed = 3
    bar = new BouncerMorph()
    bar.setColor new Color 50, 50, 50
    bar.fullRawMoveTo new Point 80, 80
    bar.rawSetExtent new Point 80, 250
    bar.type = "horizontal"
    bar.direction = "right"
    bar.alpha = 0.9
    bar.speed = 5
    baz = new BouncerMorph()
    baz.setColor new Color 20, 20, 20
    baz.fullRawMoveTo new Point 90, 140
    baz.rawSetExtent new Point 40, 30
    baz.type = "horizontal"
    baz.direction = "right"
    baz.speed = 3
    garply = new BouncerMorph()
    garply.setColor new Color 200, 20, 20
    garply.fullRawMoveTo new Point 90, 140
    garply.rawSetExtent new Point 20, 20
    garply.type = "vertical"
    garply.direction = "up"
    garply.speed = 8
    fred = new BouncerMorph()
    fred.setColor new Color 20, 200, 20
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
    @create new PenMorph()
  underTheCarpet: ->
    #newMorph = new MorphsListMorph()
    newMorph = new UnderTheCarpetMorph()
    @create newMorph
  closingWindow: ->


  popUpDemoMenu: (morphOpeningTheMenu,b,c,d) ->
    if window.location.href.contains "worldWithSystemTestHarness"
      menu = new MenuMorph morphOpeningTheMenu,  false, @, true, true, "make a morph"
      menu.addMenuItem "rectangle", true, @, "createNewRectangleMorph"
      menu.addMenuItem "box", true, @, "createNewBoxMorph"
      menu.addMenuItem "circle box", true, @, "createNewCircleBoxMorph"
      menu.addLine()
      menu.addMenuItem "slider", true, @, "createNewSliderMorph"
      menu.addMenuItem "frame", true, @, "createNewFrameMorph"
      menu.addMenuItem "scrollable panel", true, @, "createNewScrollPanel"
      menu.addMenuItem "canvas", true, @, "createNewCanvas"
      menu.addMenuItem "handle", true, @, "createNewHandle"
      menu.addLine()
      menu.addMenuItem "string", true, @, "createNewString"
      menu.addMenuItem "text", true, @, "createNewText"
      menu.addMenuItem "speech bubble", true, @, "createNewSpeechBubbleMorph"
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
      menu.addMenuItem "closing window", true, @, "closingWindow"
    else
      menu = new MenuMorph morphOpeningTheMenu,  false, @, true, true, "parts bin"
      menu.addMenuItem "rectangle", true, @, "createNewRectangleMorph"
      menu.addMenuItem "box", true, @, "createNewBoxMorph"
      menu.addMenuItem "circle box", true, @, "createNewCircleBoxMorph"
      menu.addMenuItem "slider", true, @, "createNewSliderMorph"
      menu.addMenuItem "frame", true, @, "createNewFrameMorph"
      menu.addMenuItem "scrollable panel", true, @, "createNewScrollPanel"
      menu.addMenuItem "canvas", true, @, "createNewCanvas"
      menu.addLine()
      menu.addMenuItem "string", true, @, "createNewStringMorph2WithoutBackground"
      menu.addMenuItem "text", true, @, "createNewTextMorph2WithBackground"
      menu.addMenuItem "speech bubble", true, @, "createNewSpeechBubbleMorph"
      menu.addLine()
      menu.addMenuItem "gray scale palette", true, @, "createNewGrayPaletteMorph"
      menu.addMenuItem "color palette", true, @, "createNewColorPaletteMorph"
      menu.addMenuItem "color picker", true, @, "createNewColorPickerMorph"
      menu.addLine()
      menu.addMenuItem "analog clock", true, @, "analogClock"
      menu.addMenuItem "fizzytiles", true, menusHelper, "createFridgeMagnets"
      menu.addMenuItem "fizzypaint", true, menusHelper, "createReconfigurablePaint"

    menu.popUpAtHand()

  layoutTestsMenu: (morphOpeningTheMenu) ->
    menu = new MenuMorph morphOpeningTheMenu,  false, @, true, true, "Layout tests"
    menu.addMenuItem "adjuster morph", true, @, "createNewStackElementsSizeAdjustingMorph"
    menu.addMenuItem "adder/droplet", true, @, "createNewLayoutElementAdderOrDropletMorph"
    menu.addMenuItem "test screen 1", true, Morph, "setupTestScreen1"
    menu.popUpAtHand()
    
  
  toggleDevMode: ->
    @isDevMode = not @isDevMode
  
  # This method is obsolete. It assumes a different meaning
  # for "minimise" than what we have now.
  #minimiseAll: ->
  #  @children.forEach (child) ->
  #    child.minimise()
  
  # This method is obsolete. It assumes a different meaning
  # for "minimise" than what we have now.
  #showAllMinimised: ->
  #  @forAllChildrenBottomToTop (child) ->
  #    if !child.visibleBasedOnIsVisibleProperty() or
  #    child.isCollapsed()
  #      child.unminimise()
  
  edit: (aStringMorphOrTextMorph) ->
    # first off, if the Morph is not editable
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
      @caret = @caret.destroy()

    # create the new Caret
    @caret = new CaretMorph aStringMorphOrTextMorph
    aStringMorphOrTextMorph.parent.add @caret
    # this is the only place where the @keyboardEventsReceiver is set
    @keyboardEventsReceiver = @caret

    if WorldMorph.preferencesAndSettings.isTouchDevice and WorldMorph.preferencesAndSettings.useVirtualKeyboard
      @initVirtualKeyboard()
      # For touch devices, giving focus on the textbox causes
      # the keyboard to slide up, and since the page viewport
      # shrinks, the page is scrolled to where the texbox is.
      # So, it is important to position the textbox around
      # where the caret is, so that the changed text is going to
      # be visible rather than out of the viewport.
      pos = getDocumentPositionOf @worldCanvas
      @inputDOMElementForVirtualKeyboard.style.top = @caret.top() + pos.y + "px"
      @inputDOMElementForVirtualKeyboard.style.left = @caret.left() + pos.x + "px"
      @inputDOMElementForVirtualKeyboard.focus()
    
    # Morphic.js provides the "slide" method but I must have lost it
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
      @lastEditedText.escalateEvent "reactToEdit", @lastEditedText
      @caret = @caret.destroy()

    # the only place where the @keyboardEventsReceiver is unset
    # (and the hidden input is removed)
    @keyboardEventsReceiver = nil
    if @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard.blur()
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = nil
    @worldCanvas.focus()
    
