##########################################################################################
# REQUIRES SystemTestsReferenceImage
# REQUIRES SystemTestsSystemInfo
# REQUIRES globalFunctions

# How to load/play a test:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# world.systemTestsRecorderAndPlayer.loadAndRunSingleTestFromName("SystemTest_inspectorResizingOKEvenWhenTakenApart")

# How to inspect the screenshot differences:
# after having played a test with some failing screenshots
# comparisons:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# window.world.systemTestsRecorderAndPlayer.saveFailedScreenshots()
# it will save a zip file containing three files for each failure:
# 1) the png of the obtained screenshot (different from the expected)
# 2) the .js file containing the data for the obtained screenshot
# (in case it's OK and should be added to the "good screenshots")
# 3) a .png file highlighting the differences in red.

# How to record a test:
# window.world.systemTestsRecorderAndPlayer.startTestRecording('nameOfTheTest')
# ...do the test...
# window.world.systemTestsRecorderAndPlayer.stopTestRecording()
# if you want to verify the test on the spot:
# window.world.systemTestsRecorderAndPlayer.startTestPlayingWithSlideIntro()

# For recording screenshot data at any time -
# can be used for screenshot comparisons during the test:
# window.world.systemTestsRecorderAndPlayer.takeScreenshot()

# How to save the test:
# window.world.systemTestsRecorderAndPlayer.saveTest()
# The created zip will contain both the test and the
# related reference images.

# What to do with the saved zip file:
# These files inside the zip package need to be added
# to the
#   ./src/tests directory
# Then the project will need to be recompiled.
# At this point the
#   ./build/indexWithTests.html
# page will automatically load all the tests and
# images. See "how to load/play a test" above
# to read how to load and play a test.

class AutomatorRecorderAndPlayer
  automatorCommandsSequence: []
  @RECORDING: 0
  @PLAYING: 1
  @IDLE: 2
  @state: 2
  playingAllSystemTests: false
  indexOfSystemTestBeingPlayed: 0
  timeOfPreviouslyRecordedCommand: null
  handMorph: null
  worldMorph: null
  collectedImages: [] # array of SystemTestsReferenceImage
  collectedFailureImages: [] # array of SystemTestsReferenceImage
  testName: ''
  testDescription: 'no description'
  testTags: ['noTags']
  @loadedImages: {}
  @loadedImagesToBeKeptForLaterDiff: {}
  ongoingTestPlayingTask: null
  timeOfPreviouslyPlayedCommand: 0
  indexOfTestCommandBeingPlayedFromSequence: 0

  @animationsPacingControl: false
  @alignmentOfMorphIDsMechanism: false
  @hidingOfMorphsGeometryInfoInLabels: false
  @hidingOfMorphsNumberIDInLabels: false
  @hidingOfMorphsContentExtractInLabels: false

  # this is a special place where the
  # "take pic" command places the image
  # data of a morph.
  # the test player will wait for this data
  # before doing the comparison.
  imageDataOfAParticularMorph: null
  lastMouseDownCommand: null
  lastMouseUpCommand: null
  selectedTestsBasedOnTags: []

  numberOfGroups: 1
  groupToBeRun: 0

  atLeastOneTestHasBeenRun: false
  allTestsPassedSoFar: true

  testDuration: 0
  allTestsDuration: 0
  millisOfTestSoFar: 0
  millisOfAllTestsSoFar: 0

  forceSlowTestPlaying: false
  forceTurbo: false
  forceSkippingInBetweenMouseMoves: false
  forceRunningInBetweenMouseMoves: false

  currentlyPlayingTestName: ""

  tagsCollectedWhileRecordingTest: []
  failedTests: []

  constructor: (@worldMorph, @handMorph) ->

  clearCommandSeqAndImagesRelatedToTest: (testName) ->
    # we assume that no-one is going to
    # write a tests with more than
    # 100 reference images/screenshots
    for imageNumber in [0...100]
      # each of these is an array that could contain
      # multiple screenshots for different browser/os
      # configuration, we are clearing the variable
      # containing the array
      console.log "deleting #{testName}_image_#{imageNumber}"
      delete AutomatorRecorderAndPlayer.loadedImages["#{testName}_image_#{imageNumber}"]
    console.log "deleting SystemTest_#{testName}"
    window["#{testName}" + "_automationCommands"] = null
    delete window["#{testName}" + "_automationCommands"]

  # clear any test with the same name
  # that might be loaded
  # and all the images related to it
  clearAnyDataRelatedToTest: (testName) ->
    # we assume that no-one is going to
    # write a tests with more than
    # 100 reference images/screenshots
    @clearCommandSeqAndImagesRelatedToTest testName
    delete window["#{testName}"]
  
  startTestRecording: (ignored, ingnored2, @testName, @testDescription, @testTags) ->
    # if test name not provided, then
    # prompt the user for it
    if not @testName?
      @testName = prompt("Please enter a test name", "test1")
    if not @testDescription?
      @testDescription = prompt("Please enter a test description", "no description")
    if not @testTags?
      @testTags = prompt("Please enter test tags separated by commas", "noTags")
      @testTags = @testTags.replace(/[ ]+/g, "")
      @testTags = @testTags.split(",");

    # if you choose the same name
    # of a previously loaded tests,
    # confusing things might happen such
    # as comparison with loaded screenshots
    # so we want to clear the data related
    # to the chosen name
    @clearAnyDataRelatedToTest @testName

    @automatorCommandsSequence = []
    @tagsCollectedWhileRecordingTest = []
    @timeOfPreviouslyRecordedCommand = new Date().getTime()
    AutomatorRecorderAndPlayer.state = AutomatorRecorderAndPlayer.RECORDING

  stopTestRecording: ->
    AutomatorRecorderAndPlayer.state = AutomatorRecorderAndPlayer.IDLE


  # gonna use this in a callback so need
  # to make this one a double-arrow
  stopTestPlaying: ->
    SystemTestsControlPanelUpdater.blinkLink(SystemTestsControlPanelUpdater.stopTestRec)
    console.log "wrapping up the playing of the test"
    
    # seems that if focus is on canvas
    # then updates to DOM get coalesced so
    # much that the highlights/flashed
    # on the test console are super-late
    # or completely lost. So we need to
    # temporarily remove the tab index at
    # the start of the test and then
    # put it back when the test playing is
    # complete
    world.worldCanvas.tabIndex = "1"

    fade('singleTestProgressIndicator', 1, 0, 10, new Date().getTime());
    fade('singleTestProgressBarWrap', 1, 0, 10, new Date().getTime());
    fade('allTestsProgressIndicator', 1, 0, 10, new Date().getTime());
    fade('allTestsProgressBarWrap', 1, 0, 10, new Date().getTime());
    fade('numberOfTestsDoneIndicator', 1, 0, 10, new Date().getTime());


    SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole "test complete"
    AutomatorRecorderAndPlayer.state = AutomatorRecorderAndPlayer.IDLE

    # hide indicator of mouse pointer
    mousePointerIndicator = document.getElementById('mousePointerIndicator')
    mousePointerIndicator.style.display = 'none'
    
    # There is a background interval that polls
    # to check whether it's time/condition to play
    # the next queued command. Remove it.
    indexOfTask = @worldMorph.otherTasksToBeRunOnStep.indexOf(@ongoingTestPlayingTask)
    @worldMorph.otherTasksToBeRunOnStep.splice(indexOfTask, 1)
    @worldMorph.initEventListeners()
    
    @indexOfTestCommandBeingPlayedFromSequence = 0
    @clearCommandSeqAndImagesRelatedToTest @testsList()[@indexOfSystemTestBeingPlayed]

    if @playingAllSystemTests
      @runNextSystemTest()

  showTestSource: ->
    window.open("data:text/text;charset=utf-8," + encodeURIComponent(JSON.stringify( @automatorCommandsSequence, null, 4 )))

  turnOnAnimationsPacingControl: ->
    @constructor.animationsPacingControl = true
    SystemTestsControlPanelUpdater.highlightOnLink SystemTestsControlPanelUpdater.tieAnimations
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOnAnimationsPacingControl @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()


  turnOffAnimationsPacingControl: ->
    @constructor.animationsPacingControl = false
    SystemTestsControlPanelUpdater.highlightOffLink SystemTestsControlPanelUpdater.tieAnimations
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOffAnimationsPacingControl @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()


  turnOnAlignmentOfMorphIDsMechanism: ->
    @constructor.alignmentOfMorphIDsMechanism = true
    SystemTestsControlPanelUpdater.highlightOnLink SystemTestsControlPanelUpdater.alignMorphIDs
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOnAlignmentOfMorphIDsMechanism @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffAlignmentOfMorphIDsMechanism: ->
    @constructor.alignmentOfMorphIDsMechanism = false
    SystemTestsControlPanelUpdater.highlightOffLink SystemTestsControlPanelUpdater.alignMorphIDs
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOffAlignmentOfMorphIDsMechanism @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOnHidingOfMorphsGeometryInfoInLabels: ->
    @constructor.hidingOfMorphsGeometryInfoInLabels = true
    SystemTestsControlPanelUpdater.highlightOnLink SystemTestsControlPanelUpdater.hideGeometry
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOnHidingOfMorphsGeometryInfoInLabels @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffHidingOfMorphsGeometryInfoInLabels: ->
    @constructor.hidingOfMorphsGeometryInfoInLabels = false
    SystemTestsControlPanelUpdater.highlightOffLink SystemTestsControlPanelUpdater.hideGeometry
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOffHidingOfMorphsGeometryInfoInLabels @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOnHidingOfMorphsContentExtractInLabels: ->
    @constructor.hidingOfMorphsContentExtractInLabels = true
    SystemTestsControlPanelUpdater.highlightOnLink SystemTestsControlPanelUpdater.hideMorphContentExtracts
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOnHidingOfMorphsContentExtractInLabels @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffHidingOfMorphsContentExtractInLabels: ->
    @constructor.hidingOfMorphsContentExtractInLabels = false
    SystemTestsControlPanelUpdater.highlightOffLink SystemTestsControlPanelUpdater.hideMorphContentExtracts
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOffHidingOfMorphsContentExtractInLabels @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOnHidingOfMorphsNumberIDInLabels: ->
    @constructor.hidingOfMorphsNumberIDInLabels = true
    SystemTestsControlPanelUpdater.highlightOnLink SystemTestsControlPanelUpdater.hideMorphIDs
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOnHidingOfMorphsNumberIDInLabels @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffHidingOfMorphsNumberIDInLabels: ->
    @constructor.hidingOfMorphsNumberIDInLabels = false
    SystemTestsControlPanelUpdater.highlightOffLink SystemTestsControlPanelUpdater.hideMorphIDs
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandTurnOffHidingOfMorphsNumberIDInLabels @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()


  addMouseMoveCommand: (pageX, pageY, floatDraggingSomething) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandMouseMove pageX, pageY, floatDraggingSomething, @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addMouseChangeCommand: (upOrDown, button, ctrlKey, morphUniqueIDString, morphPathRelativeToWorld, morphIdentifierViaTextLabel, absoluteBoundsOfMorphRelativeToWorld, pointerPositionFractionalInMorph, pointerPositionPixelsInMorph, pointerPositionPixelsInWorld, isPartOfListMorph) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandMouseButtonChange upOrDown, button, ctrlKey, morphUniqueIDString, morphPathRelativeToWorld, morphIdentifierViaTextLabel, absoluteBoundsOfMorphRelativeToWorld, pointerPositionFractionalInMorph, pointerPositionPixelsInMorph, pointerPositionPixelsInWorld, isPartOfListMorph, @
    @lastMouseDownCommand = systemTestCommand
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addMouseClickCommand: (button, ctrlKey, morphUniqueIDString, morphPathRelativeToWorld, morphIdentifierViaTextLabel, absoluteBoundsOfMorphRelativeToWorld, pointerPositionFractionalInMorph, pointerPositionPixelsInMorph, pointerPositionPixelsInWorld, isPartOfListMorph) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandMouseClick button, ctrlKey, morphUniqueIDString, morphPathRelativeToWorld, morphIdentifierViaTextLabel, absoluteBoundsOfMorphRelativeToWorld, pointerPositionFractionalInMorph, pointerPositionPixelsInMorph, pointerPositionPixelsInWorld, isPartOfListMorph, @
    @lastMouseDownCommand = systemTestCommand
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  # note that we give for granted that double click
  # is always on the left button
  addMouseDoubleClickCommand: (ctrlKey, morphUniqueIDString, morphPathRelativeToWorld, morphIdentifierViaTextLabel, absoluteBoundsOfMorphRelativeToWorld, pointerPositionFractionalInMorph, pointerPositionPixelsInMorph, pointerPositionPixelsInWorld, isPartOfListMorph) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandMouseDoubleClick ctrlKey, morphUniqueIDString, morphPathRelativeToWorld, morphIdentifierViaTextLabel, absoluteBoundsOfMorphRelativeToWorld, pointerPositionFractionalInMorph, pointerPositionPixelsInMorph, pointerPositionPixelsInWorld, isPartOfListMorph, @
    @lastMouseDownCommand = systemTestCommand
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()


  addOpenContextMenuCommand: (context) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    #@removeLastMouseUpAndMouseDownCommands()
    systemTestCommand = new AutomatorCommandOpenContextMenu context, @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addCommandLeftOrRightClickOnMenuItem: (mouseButton, labelString, occurrenceNumber) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    #@removeLastMouseUpAndMouseDownCommands()
    systemTestCommand = new AutomatorCommandLeftOrRightClickOnMenuItem mouseButton, labelString, occurrenceNumber, @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  # doesn't *actually* remove the command
  # because you do need to wait the time.
  # because for example the bubbles pop-up
  # after some time.
  # You could remove the commands and note down
  # how much was the wait on each and charge it to
  # the next command but that would be very messy.
  #removeLastMouseUpAndMouseDownCommands: ->
  #  @lastMouseDownCommand.transformIntoDoNothingCommand()
  #  @lastMouseUpCommand.transformIntoDoNothingCommand()

  addKeyPressCommand: (charCode, symbol, shiftKey, ctrlKey, altKey, metaKey) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandKeyPress charCode, symbol, shiftKey, ctrlKey, altKey, metaKey, @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addKeyDownCommand: (scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandKeyDown scanCode, shiftKey, ctrlKey, altKey, metaKey, @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addKeyUpCommand: (scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandKeyUp scanCode, shiftKey, ctrlKey, altKey, metaKey, @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addCopyCommand: () ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandCopy @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addPasteCommand: (clipboardText) ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandPaste clipboardText, @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addGrabCommand: ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandGrab @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addDropCommand: ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandDrop @
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  resetWorld: ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    systemTestCommand = new AutomatorCommandResetWorld @
    window[systemTestCommand.automatorCommandName].replayFunction @, null
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addTestComment: ->
    return if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
    # note how we take the time before we prompt the
    # user so we can show the message sooner when playing
    # the test - i.e. the message will appear at the time
    # the user got the prompt window rather than when she
    # actually wrote the message...
    # So we anticipate the message so the user can actually have
    # the time to read it before the test moves on with the
    # next steps.
    @timeOfPreviouslyRecordedCommand = new Date().getTime()
    comment = prompt("enter comment", "your comment here")
    systemTestCommand = new AutomatorCommandShowComment comment, @
    @automatorCommandsSequence.push systemTestCommand

  checkStringsOfItemsInMenuOrderImportant: (stringOfItemsInMenuInOriginalOrder) ->
    SystemTestsControlPanelUpdater.blinkLink(SystemTestsControlPanelUpdater.checkMenuEntriesInOrder)
    @checkStringsOfItemsInMenu(stringOfItemsInMenuInOriginalOrder, true)

  checkStringsOfItemsInMenuOrderUnimportant: (stringOfItemsInMenuInOriginalOrder) ->
    SystemTestsControlPanelUpdater.blinkLink(SystemTestsControlPanelUpdater.checkMenuEntriesNotInOrder)
    @checkStringsOfItemsInMenu(stringOfItemsInMenuInOriginalOrder, false)

  checkStringsOfItemsInMenu: (stringOfItemsInMenuInOriginalOrder, orderMatters) ->
    console.log "checkStringsOfItemsInMenu"
    menuAtPointer = @handMorph.menuAtPointer()
    console.log menuAtPointer

    stringOfItemsInCurrentMenuInOriginalOrder = []

    if menuAtPointer?
      for eachMenuItem in menuAtPointer.items
        stringOfItemsInCurrentMenuInOriginalOrder.push eachMenuItem[0]
    else
      errorMessage = "FAIL was expecting a menu under the pointer"
      console.log errorMessage
      testBeingPlayed = @testsList()[@indexOfSystemTestBeingPlayed]
      if @failedTests.indexOf(testBeingPlayed) < 0 then @failedTests.push(testBeingPlayed)
      document.getElementById('numberOfFailedTests').innerHTML = "- " + @failedTests.length + " failed"
      @allTestsPassedSoFar = false
      document.getElementById("background").style.background = "red"
      if SystemTestsControlPanelUpdater?
        SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole errorMessage
      @stopTestPlaying()

    if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
      if orderMatters
        systemTestCommand =
          new AutomatorCommandCheckStringsOfItemsInMenuOrderImportant stringOfItemsInCurrentMenuInOriginalOrder, @
      else
        systemTestCommand =
          new AutomatorCommandCheckStringsOfItemsInMenuOrderUnimportant stringOfItemsInCurrentMenuInOriginalOrder, @

      @automatorCommandsSequence.push systemTestCommand
      @timeOfPreviouslyRecordedCommand = new Date().getTime()
    else if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
      giveSuccess = =>
        if orderMatters
          message = "PASS Strings in menu are same and in same order"
        else
          message = "PASS Strings in menu are same (not considering order)"
        if SystemTestsControlPanelUpdater?
          SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole message
      giveError = =>
        if orderMatters
          @allTestsPassedSoFar = false
          document.getElementById("background").style.background = "red"
          errorMessage =
            "FAIL Strings in menu doesn't match or order is incorrect. Was expecting: " +
              stringOfItemsInMenuInOriginalOrder + " found: " + stringOfItemsInCurrentMenuInOriginalOrder
          testBeingPlayed = @testsList()[@indexOfSystemTestBeingPlayed]
          if @failedTests.indexOf(testBeingPlayed) < 0 then @failedTests.push(testBeingPlayed)
          document.getElementById('numberOfFailedTests').innerHTML = "- " + @failedTests.length + " failed"
        else
          @allTestsPassedSoFar = false
          document.getElementById("background").style.background = "red"
          errorMessage =
            "FAIL Strings in menu doesn't match (even not considering order). Was expecting: " +
              stringOfItemsInMenuInOriginalOrder + " found: " + stringOfItemsInCurrentMenuInOriginalOrder
          testBeingPlayed = @testsList()[@indexOfSystemTestBeingPlayed]
          if @failedTests.indexOf(testBeingPlayed) < 0 then @failedTests.push(testBeingPlayed)
          document.getElementById('numberOfFailedTests').innerHTML = "- " + @failedTests.length + " failed"
        if SystemTestsControlPanelUpdater?
          SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole errorMessage
        @stopTestPlaying()
      
      menuListIsSame = true

      # the reason why we make a copy here is the following:
      # if you kept the original array then this could happen:
      # you record a test and then you play it back and then you save it
      # the array is always the same and could get mutated during the play
      # (because it could be sorted). So when you save the test, you
      # save the ordered array instead of the original.
      copyOfstringOfItemsInMenuInOriginalOrder = arrayShallowCopy(stringOfItemsInMenuInOriginalOrder)

      # if the order doesn't matter then we need to
      # sort the strings first so we compare regardless
      # of the original order
      if !orderMatters
        stringOfItemsInCurrentMenuInOriginalOrder.sort()
        copyOfstringOfItemsInMenuInOriginalOrder.sort()

      if stringOfItemsInCurrentMenuInOriginalOrder.length == copyOfstringOfItemsInMenuInOriginalOrder.length
        for itemNumber in [0...copyOfstringOfItemsInMenuInOriginalOrder.length]
          if copyOfstringOfItemsInMenuInOriginalOrder[itemNumber] != stringOfItemsInCurrentMenuInOriginalOrder[itemNumber]
            menuListIsSame = false
            console.log copyOfstringOfItemsInMenuInOriginalOrder[itemNumber] + " != " + stringOfItemsInCurrentMenuInOriginalOrder[itemNumber] + " at " + itemNumber
      else
        menuListIsSame = false

      if menuListIsSame
        giveSuccess()
      else
        giveError()

  checkNumberOfItemsInMenu: (numberOfItems) ->
    SystemTestsControlPanelUpdater.blinkLink(SystemTestsControlPanelUpdater.checkNumnberOfItems)
    if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
      menuAtPointer = @handMorph.menuAtPointer()
      console.log menuAtPointer
      if menuAtPointer?
        numberOfItems = menuAtPointer.items.length
        console.log "found " + numberOfItems + " number of items "
      else
        console.log "was expecting a menu under the pointer"
        numberOfItems = 0
      systemTestCommand = new AutomatorCommandCheckNumberOfItemsInMenu numberOfItems, @
      @automatorCommandsSequence.push systemTestCommand
      @timeOfPreviouslyRecordedCommand = new Date().getTime()
    else if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
      menuAtPointer = @handMorph.menuAtPointer()
      giveSuccess = =>
        message = "PASS Number of items in menu matches. Note that count includes line separators. Found: " + menuAtPointer.items.length
        if SystemTestsControlPanelUpdater?
          SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole message
      giveError = =>
        @allTestsPassedSoFar = false
        document.getElementById("background").style.background = "red"
        errorMessage = "FAIL Number of items in menu doesn't match. Note that count includes line separators. Was expecting: " + numberOfItems + " found: " + menuAtPointer.items.length
        testBeingPlayed = @testsList()[@indexOfSystemTestBeingPlayed]
        if @failedTests.indexOf(testBeingPlayed) < 0 then @failedTests.push(testBeingPlayed)
        document.getElementById('numberOfFailedTests').innerHTML = "- " + @failedTests.length + " failed"
        if SystemTestsControlPanelUpdater?
          SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole errorMessage
        @stopTestPlaying()
      if menuAtPointer?
        if numberOfItems != menuAtPointer.items.length
          giveError()
        else
          giveSuccess()
      else
          giveError()

  takeScreenshot: (whichMorph = @worldMorph) ->
    console.log "taking screenshot"
    imageName = "SystemTest_"+@testName+"_image_" + (@collectedImages.length + 1)
    systemTestCommand = new AutomatorCommandScreenshot imageName, @, whichMorph != @worldMorph

    imageData = whichMorph.asItAppearsOnScreen()

    takenScreenshot = new SystemTestsReferenceImage(imageName,imageData, new SystemTestsSystemInfo())
    unless AutomatorRecorderAndPlayer.loadedImages["#{imageName}"]?
      AutomatorRecorderAndPlayer.loadedImages["#{imageName}"] = []
    AutomatorRecorderAndPlayer.loadedImages["#{imageName}"].push takenScreenshot
    @collectedImages.push takenScreenshot
    @automatorCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.RECORDING
      return systemTestCommand

  # a lenghty method because there
  # is a lot of API dancing, but the
  # concept is really easy: return
  # a new canvas with an image that is
  # red in all areas where the
  # "expected" and "obtained" images
  # are different.
  # So it neatly highlights where the differences
  # are.
  subtractScreenshots: (expected, obtained, diffNumber, andThen) ->
    console.log "subtractScreenshots"
    expectedCanvas = document.createElement "canvas"
    expectedImage = new Image
    # unfortunately the operation of loading
    # the base64 data into the image is asynchronous
    # (seems to work immediately in Chrome but it's
    # recommended to consider it asynchronous)
    # so here we need to chain two callbacks
    # to make it all work, as we need to load
    # two such images.
    expectedImage.onload = =>
      console.log "expectedCanvas.imageData: " + expectedCanvas.imageData
      expectedCanvas.width = expectedImage.width
      expectedCanvas.height = expectedImage.height
      expectedCanvasContext = expectedCanvas.getContext "2d"
      console.log "expectedCanvas.width: " + expectedCanvas.width
      console.log "expectedCanvas.height: " + expectedCanvas.height
      expectedCanvasContext.drawImage(expectedImage,0,0)
      expectedImageData = expectedCanvasContext.getImageData(0, 0, expectedCanvas.width, expectedCanvas.height)

      obtainedCanvas = document.createElement "canvas"
      obtainedImage = new Image
      obtainedImage.onload = =>
        obtainedCanvas.width = obtainedImage.width
        obtainedCanvas.height = obtainedImage.height

        if (obtainedImage.width != expectedImage.width) or
        (obtainedImage.height != expectedImage.height)
          # this happens when comparing screenshots
          # coming from screens with different
          # pixelRatios. The resulting diff image
          # would be very glitchy and strange and
          # just maningless so skip the process
          return

        obtainedCanvasContext = obtainedCanvas.getContext "2d"
        obtainedCanvasContext.drawImage(obtainedImage,0,0)
        obtainedImageData = obtainedCanvasContext.getImageData(0, 0, obtainedCanvas.width, obtainedCanvas.height)

        subtractionCanvas = document.createElement "canvas"
        subtractionCanvas.width = obtainedImage.width
        subtractionCanvas.height = obtainedImage.height
        subtractionCanvasContext = subtractionCanvas.getContext("2d")
        subtractionCanvasContext.drawImage(obtainedImage,0,0)
        subtractionImageData = subtractionCanvasContext.getImageData(0, 0, subtractionCanvas.width, subtractionCanvas.height)

        i = 0
        equalPixels = 0
        differentPixels = 0

        while i < subtractionImageData.data.length
          if obtainedImageData.data[i] != expectedImageData.data[i] or
             obtainedImageData.data[i+1] != expectedImageData.data[i+1] or
             obtainedImageData.data[i+2] != expectedImageData.data[i+2]
            subtractionImageData.data[i] = 255
            subtractionImageData.data[i+1] = 0
            subtractionImageData.data[i+2] = 0
            differentPixels++
          else
            equalPixels++
          i += 4
        console.log "equalPixels: " + equalPixels
        console.log "differentPixels: " + differentPixels
        subtractionCanvasContext.putImageData subtractionImageData, 0, 0
        #errorRatio = Math.ceil((differentPixels/(equalPixels+differentPixels))*1000)
        errorRatio = differentPixels
        andThen subtractionCanvas, expected, errorRatio, diffNumber

      obtainedImage.src = obtained.imageData

    expectedImage.src = expected.imageData

  compareScreenshots: (testNameWithImageNumber, screenshotTakenOfAParticularMorph = false) ->
   SystemTestsControlPanelUpdater.blinkLink(SystemTestsControlPanelUpdater.takeScreenshot)

   if screenshotTakenOfAParticularMorph
     console.log "comparing pic of a particular morph"
     # todo this seems broken, this image data is not
     # actually fetched anywhere?
     screenshotObtained = @imageDataOfAParticularMorph
     @imageDataOfAParticularMorph = null
   else
     console.log "comparing pic of whole desktop"
     screenshotObtained = @worldMorph.asItAppearsOnScreen()
   
   console.log "trying to match screenshot: " + testNameWithImageNumber
   console.log "length of obtained: " + screenshotObtained.length

   # There can be multiple files for the same image, since
   # the images vary according to OS and Browser, so for
   # each image of each test there is an array of candidates
   # to be checked. If any of them matches in terms of pixel data,
   # then fine, otherwise complain...
   #
   # in "loadedImagesToBeKeptForLaterDiff" we keep the images
   # related to the failed tests. If we don't keep those
   # in this reference, they are disposed of and garbage collected
   # since they are quite big and they accumulate.
   AutomatorRecorderAndPlayer.loadedImagesToBeKeptForLaterDiff["#{testNameWithImageNumber}"] = AutomatorRecorderAndPlayer.loadedImages["#{testNameWithImageNumber}"]
   for eachImage in AutomatorRecorderAndPlayer.loadedImages["#{testNameWithImageNumber}"]
     console.log "length of obtained: " + eachImage.imageData.length
     if eachImage.imageData == screenshotObtained
      message = "PASS - screenshot " + eachImage.fileName + " matched"
      AutomatorRecorderAndPlayer.loadedImagesToBeKeptForLaterDiff["#{testNameWithImageNumber}"] = null
      delete AutomatorRecorderAndPlayer.loadedImagesToBeKeptForLaterDiff["#{testNameWithImageNumber}"]
      console.log message
      if SystemTestsControlPanelUpdater?
        SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole message
      return
   # OK none of the images we loaded matches the one we
   # just took. Hence create a SystemTestsReferenceImage
   # that we can let the user download - it will contain
   # the image actually obtained (rather than the one
   # we should have seen)
   message = "FAIL - no screenshots like this one"
   console.log message
   @allTestsPassedSoFar = false
   document.getElementById("background").style.background = "red"
   if SystemTestsControlPanelUpdater?
     SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole message
   obtainedImageName = "obtained-" + eachImage.imageName
   obtainedImage = new SystemTestsReferenceImage(obtainedImageName,screenshotObtained, new SystemTestsSystemInfo())
   @collectedFailureImages.push obtainedImage
   testBeingPlayed = @testsList()[@indexOfSystemTestBeingPlayed]
   if @failedTests.indexOf(testBeingPlayed) < 0 then @failedTests.push(testBeingPlayed)
   document.getElementById('numberOfFailedTests').innerHTML = "- " + @failedTests.length + " failed"

  replayTestCommands: ->
   commandToBePlayed = @automatorCommandsSequence[@indexOfTestCommandBeingPlayedFromSequence]
   # console.log "examining command: " + commandToBePlayed.automatorCommandName + " at: " + commandToBePlayed.millisecondsSincePreviousCommand +
   #   " time now: " + timeNow + " we are at: " + (timeNow - @timeOfPreviouslyPlayedCommand)



   # for the screenshot, the replay is going
   # to consist in comparing the image data.
   # in case the screenshot is made of the entire world
   # then the comparison can happen now.
   # in case the screenshot is made of a particular
   # morph then we want to wait that the world
   # has taken that screenshot image data and put
   # it in here.
   # search for imageDataOfAParticularMorph everywhere
   # to see where the image data is created and
   # put there.
   if commandToBePlayed.automatorCommandName == "AutomatorCommandScreenshot" and commandToBePlayed.screenshotTakenOfAParticularMorph
     if not @imageDataOfAParticularMorph?
       # no image data of morph, so just wait
       return

   #if commandToBePlayed.automatorCommandName == "AutomatorCommandScreenshot"
   # @automatorCommandsSequence[@indexOfTestCommandBeingPlayedFromSequence + 1].millisecondsSincePreviousCommand = 0
   # debugger

   runCurrentCommandImmediately = false
   if ((window["#{@currentlyPlayingTestName}"]?.supportsTurboPlayback) and (!@forceSlowTestPlaying)) or @forceTurbo
     if (@indexOfTestCommandBeingPlayedFromSequence >= 1) and
      (@indexOfTestCommandBeingPlayedFromSequence < (@automatorCommandsSequence.length - 1))
        consecutiveMouseMoves = 0
        while true
          previousCommand1 = @automatorCommandsSequence[@indexOfTestCommandBeingPlayedFromSequence - 1]
          commandToBePlayed = @automatorCommandsSequence[@indexOfTestCommandBeingPlayedFromSequence]
          nextCommand1 = @automatorCommandsSequence[@indexOfTestCommandBeingPlayedFromSequence + 1]
          if previousCommand1.automatorCommandName == "AutomatorCommandMouseMove" and
           nextCommand1.automatorCommandName == "AutomatorCommandMouseMove" and
           commandToBePlayed.automatorCommandName == "AutomatorCommandMouseMove"
            consecutiveMouseMoves++
            #if (consecutiveMouseMoves % 6) != 0
            if (consecutiveMouseMoves % 10000) != 0
              if (!window["#{@currentlyPlayingTestName}"]?.skipInbetweenMouseMoves and (!@forceSkippingInBetweenMouseMoves)) or @forceRunningInBetweenMouseMoves
                window[commandToBePlayed.automatorCommandName].replayFunction.call @,@,commandToBePlayed
              timeUntilNextCommand = commandToBePlayed.millisecondsSincePreviousCommand or 0
              @millisOfTestSoFar += timeUntilNextCommand
              @millisOfAllTestsSoFar += timeUntilNextCommand
              console.log ">>>>>> skipping mousemove"
              @indexOfTestCommandBeingPlayedFromSequence++
            else
              runCurrentCommandImmediately = true
              break
          else
            runCurrentCommandImmediately = true
            break


   timeNow = (new Date()).getTime()
   timeUntilNextCommand = commandToBePlayed.millisecondsSincePreviousCommand or 0
   
   if runCurrentCommandImmediately or (timeNow - @timeOfPreviouslyPlayedCommand >= timeUntilNextCommand)

     console.log ">>>>>> doing "  + commandToBePlayed.automatorCommandName

     @millisOfTestSoFar += timeUntilNextCommand
     @millisOfAllTestsSoFar += timeUntilNextCommand

     #console.log "running command: " + commandToBePlayed.automatorCommandName + " " + @indexOfTestCommandBeingPlayedFromSequence + " / " + @automatorCommandsSequence.length + " ms: " + @millisOfTestSoFar + " / " + @testDuration
     window[commandToBePlayed.automatorCommandName].replayFunction.call @,@,commandToBePlayed

     document.getElementById('singleTestProgressIndicator').innerHTML = "test: " + Math.floor((@millisOfTestSoFar / @testDuration)*100) + "%" + " done"
     document.getElementById('singleTestProgressBar').style.left =  (Math.floor((@millisOfTestSoFar / @testDuration)*100)) + "%"

     document.getElementById('allTestsProgressIndicator').innerHTML = "all: " + Math.floor((@millisOfAllTestsSoFar / @allTestsDuration)*100) + "%" + " done"
     document.getElementById('allTestsProgressBar').style.left =  (Math.floor((@millisOfAllTestsSoFar / @allTestsDuration)*100)) + "%"

     @timeOfPreviouslyPlayedCommand = timeNow
     @indexOfTestCommandBeingPlayedFromSequence++
     if @indexOfTestCommandBeingPlayedFromSequence == @automatorCommandsSequence.length
       console.log "stopping the test player"
       @stopTestPlaying()

  calculateTotalTimeOfThisTest: ->
    testDuration = 0
    for eachCommand in @automatorCommandsSequence
      if eachCommand.millisecondsSincePreviousCommand?
        testDuration += eachCommand.millisecondsSincePreviousCommand
    @testDuration = testDuration

  startTestPlayingSlow: ->
    @forceSlowTestPlaying = true
    @startTestPlaying()

  startTestPlayingFastSkipInbetweenMouseMoves: ->
    @forceTurbo = true
    @forceSkippingInBetweenMouseMoves = true
    @startTestPlaying()

  startTestPlayingFastRunInbetweenMouseMoves: ->
    @forceTurbo = true
    @forceRunningInBetweenMouseMoves = true
    @startTestPlaying()

  startTestPlaying: ->

    # seems that if focus is on canvas
    # then updates to DOM get coalesced so
    # much that the highlights/flashed
    # on the test console are super-late
    # or completely lost. So we need to
    # temporarily remove the tab index at
    # the start of the test and then
    # put it back when the test playing is
    # complete
    world.worldCanvas.tabIndex = "-1"

    AutomatorRecorderAndPlayer.state = AutomatorRecorderAndPlayer.PLAYING
    @atLeastOneTestHasBeenRun = true
    @constructor.animationsPacingControl = true
    @worldMorph.removeEventListeners()

    @currentlyPlayingTestName = @testsList()[@indexOfSystemTestBeingPlayed]
    if window["#{@currentlyPlayingTestName}"]?
      @testDuration = window["#{@currentlyPlayingTestName}"].testDuration

    @millisOfTestSoFar = 0
    @ongoingTestPlayingTask = (=> @replayTestCommands())
    @worldMorph.otherTasksToBeRunOnStep.push @ongoingTestPlayingTask

    document.getElementById('numberOfTestsDoneIndicator').innerHTML = "test " + (@indexOfSystemTestBeingPlayed + 1) + " of " + @testsList().length


  startTestPlayingWithSlideIntro: ->
    @startTestPlaying()
    @setUpIntroSlide()

  setUpIntroSlide: ->
    fade('singleTestProgressIndicator', 0, 1, 10, new Date().getTime());
    fade('singleTestProgressBarWrap', 0, 1, 10, new Date().getTime());
    fade('allTestsProgressIndicator', 0, 1, 10, new Date().getTime());
    fade('allTestsProgressBarWrap', 0, 1, 10, new Date().getTime());
    fade('numberOfTestsDoneIndicator', 0, 1, 10, new Date().getTime());

    fade('testTitleAndDescription', 0, 1, 10, new Date().getTime());

    presentableTestName = @currentlyPlayingTestName.replace(/SystemTest_/g, "")
    presentableTestName = decamelize presentableTestName, " "
    presentableTestName = presentableTestName.charAt(0).toUpperCase() + presentableTestName.slice(1)
    presentableTestName = '"' + presentableTestName + '"'
    testTitleAndDescription.innerHTML =  presentableTestName
    testTitleAndDescription.innerHTML = testTitleAndDescription.innerHTML + "<br><br><small>(#{@currentlyPlayingTestName})</small>"
    testTitleAndDescription.innerHTML = testTitleAndDescription.innerHTML + "<br><br><small>" + window["#{@currentlyPlayingTestName}"].description + "</small>"
    setTimeout \
      =>
        fade('testTitleAndDescription', 1, 0, 2000, new Date().getTime());        
      , 4000


  testMetadataFileContentCreator: ->
    # these here below is just one string
    # spanning multiple lines, which
    # includes the testName and commands
    # in the right places.

    testToBeSerialized = {}
    testToBeSerialized.timeRecorded = new Date()
    testToBeSerialized.description = @testDescription
    testToBeSerialized.tags = @testTags.concat @tagsCollectedWhileRecordingTest
    testToBeSerialized.systemInfo = new SystemTestsSystemInfo()
    @calculateTotalTimeOfThisTest()
    testToBeSerialized.testDuration = @testDuration
    testToBeSerialized.supportsTurboPlayback = true
    testToBeSerialized.skipInbetweenMouseMoves = true

    """
  // This Automator file is automatically
  // created.
  // If this is a test,
  // this file (and related reference images)
  // can be copied in the /src/tests folder
  // to make them available in the testing
  // environment.
  var SystemTest_#{@testName};

  SystemTest_#{@testName} = #{JSON.stringify(testToBeSerialized, null, 4)};
    """

  automatorCommandsFileContentCreator: (commands) ->
    # these here below is just one string
    # spanning multiple lines, which
    # includes the testName and commands
    # in the right places.

    testToBeSerialized = {}
    testToBeSerialized.automatorCommandsSequence = commands
    testNameExtended = @testName + "_automationCommands"

    """
  // This Automator file is automatically
  // created.
  // It this is a test,
  // this file (and related reference images)
  // can be copied in the /src/tests folder
  // to make them available in the testing
  // environment.
  var SystemTest_#{testNameExtended};

  SystemTest_#{testNameExtended} = #{JSON.stringify(testToBeSerialized, null, 4)};
    """

  saveFailedScreenshots: ->
    zip = new JSZip()
    
    AutomatorRecorderAndPlayer.loadedImages = AutomatorRecorderAndPlayer.loadedImagesToBeKeptForLaterDiff

    # debugger
    # save all the images, each as a .png and .js file
    # the png is for quick browsing, while the js contains
    # the pixel data and the metadata of which configuration
    # the picture was recorded with.
    # (we expect the screenshots to be different across
    # browsers and OSs)
    # Note that the .js files are saved so the content
    # doesn't contain "obtained-" anywhere in metadata
    # (as it should, in theory) so that, if the
    # screenshot is good, the file can just be
    # renamed and moved together with the "good"
    # screenshots.
    for image in @collectedFailureImages
      image.addToZipAsJSIgnoringItsAnObtained zip
      
      # let's also save the png file so it's easier to browse the data
      # note that these png files are not copied over into the
      # build directory.
      image.addToZipAsPNG zip

    # create and save all diff .png images
    # the diff images just highlight in red
    # the parts that differ from any one
    # of the "good" screenshots
    # (remember, there can be more than one
    # good screenshot, we pick the first one
    # we find)
    renamerScript = ""
    systemInfo = new SystemTestsSystemInfo()
    pixelRatioString = (""+pixelRatio).replace(/\.+/g, "_")

    for i in [0...@collectedFailureImages.length]
      failedImage = @collectedFailureImages[i]

      aGoodImageName = (failedImage).imageName.replace("obtained-", "")
      filenameForScript = aGoodImageName.replace(/_image_.*/g, "")
      renamerScript += "rm " + "../Zombie-Kernel-tests/tests/" + filenameForScript + "/automation-assets/" +
              systemInfo.os.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.osVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browser.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browserVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              "devicePixelRatio_" + pixelRatioString + "/" +
              aGoodImageName + "*\n"
      # someone could get rid of the pixelRatio directories
      # that don't apply to him/her (say, to save space)
      # so make sure you create it if it doesn't exist.
      renamerScript += "mkdir -p " + "../Zombie-Kernel-tests/tests/" + filenameForScript + "/automation-assets/" +
              systemInfo.os.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.osVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browser.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browserVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              "devicePixelRatio_" + pixelRatioString + "\n"
      renamerScript += "cp " + (failedImage).imageName + "* ../Zombie-Kernel-tests/tests/" + filenameForScript + "/automation-assets/" +
              systemInfo.os.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.osVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browser.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browserVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              "devicePixelRatio_" + pixelRatioString + "/\n\n"


      setOfGoodImages = AutomatorRecorderAndPlayer.loadedImages[aGoodImageName]
      diffNumber = 0
      for eachGoodImage in setOfGoodImages
        diffNumber++
        # note the asynchronous operation here - this is because
        # the subtractScreenshots needs to create some Images and
        # load them with data from base64 string. The operation
        # of loading the data is asynchronous...
        @subtractScreenshots failedImage, eachGoodImage, diffNumber, (subtractionCanvas, failedImage, errorRatio, diffNumber) ->
          console.log "zipping diff file:" + "diff-"+failedImage.imageName+".png"
          zip.file(
            "diff-"+
            failedImage.imageName +
            "-error-" +
            errorRatio+
            "-diffNumber-"+
            diffNumber+
            ".png"
          , subtractionCanvas.toDataURL().replace(/^data:image\/png;base64,/, ""), {base64: true});

    renamerScript += "# take away all the 'obtained' prefixes in all the files" + "\n"
    renamerScript += "find ../Zombie-Kernel-tests/tests/ -name 'obtained-*' -type f -exec bash -c 'mv \"$1\" \"${1/\\/obtained-//}\"' -- {} \\;" + "\n"

    zip.file("replace_all_images.sh", renamerScript);

    # OK the images are all put in the zip
    # asynchronously. So, in theory what we should do is to
    # check that we have all the image packed
    # and then save the zip. In practice we just wait
    # some time (200ms for each image)
    # and then save the zip.
    setTimeout \
      =>
        console.log "saving failed screenshots"
        if navigator.userAgent.search("Safari") >= 0 and navigator.userAgent.search("Chrome") < 0
          # Safari can't save blobs nicely with a nice
          # file name, see
          # http://stuk.github.io/jszip/documentation/howto/write_zip.html
          # so what this does is it saves a file "Unknown". User
          # then has to rename it and open it.
          location.href="data:application/zip;base64," + zip.generate({type:"base64"})
        else
          console.log "not safari"
          content = zip.generate({type:"blob"})
          saveAs(content, "SystemTest_#{@testName}_failedScreenshots.zip")        
      , (@collectedFailureImages.length+1) * 200 



  saveTest: ->
    zip = new JSZip()

    blob = @testMetadataFileContentCreator()
    zip.file("SystemTest_#{@testName}.js", blob);

    blob = @automatorCommandsFileContentCreator window.world.systemTestsRecorderAndPlayer.automatorCommandsSequence
    testNameExtended = @testName + "_automationCommands"
    zip.file("SystemTest_#{testNameExtended}.js", blob);
    
    # save all the images, each as a .png and .js file
    # the png is for quick browsing, while the js contains
    # the pixel data and the metadata of which configuration
    # the picture was recorded with.
    # (we expect the screenshots to be different across
    # browsers and OSs)
    for image in @collectedImages
      image.addToZipAsJS zip
      
      # let's also save the png file so it's easier to browse the data
      # note that these png files are not copied over into the
      # build directory.
      image.addToZipAsPNG zip
    

    if navigator.userAgent.search("Safari") >= 0 and navigator.userAgent.search("Chrome") < 0
      # Safari can't save blobs nicely with a nice
      # file name, see
      # http://stuk.github.io/jszip/documentation/howto/write_zip.html
      # so what this does is it saves a file "Unknown". User
      # then has to rename it and open it.
      console.log "safari"
      location.href="data:application/zip;base64," + zip.generate({type:"base64"})
    else
      console.log "not safari"
      content = zip.generate({type:"blob"})
      saveAs(content, "SystemTest_#{@testName}.zip")    

  loadTest: (testNumber, andThenDoThis)->
    script = document.createElement('script')
    script.src = "js/tests/"+@testsList()[testNumber] + "_automationCommands.js"

    script.onload = =>
      @loadImagesOfTest testNumber, andThenDoThis

    document.head.appendChild script

  loadImagesOfTest: (testNumber, andThenDoThis)->

    for eachCommand in window[(@testsList()[testNumber])+ "_automationCommands"].automatorCommandsSequence
      if eachCommand.screenShotImageName?
        pureImageName = eachCommand.screenShotImageName
        for eachAssetInManifest in AutomatorRecorderAndPlayer.testsAssetsManifest
          if eachAssetInManifest.indexOf(pureImageName) != -1
            script = document.createElement('script')
            ###
            systemInfo = new SystemTestsSystemInfo()
            # some devices have non-integer pixel ratios so
            # let's handle the dot there.
            pixelRatioString = (""+pixelRatio).replace(/\.+/g, "_")
            alert "js/tests/assets/" +
              systemInfo.os.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.osVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browser.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browserVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              "devicePixelRatio_" + pixelRatioString + "/" +
              eachAssetInManifest +
              ".js"
            ###
            script.src = "js/tests/assets/"+ eachAssetInManifest + ".js"
            document.head.appendChild script

    setTimeout \
      =>
        andThenDoThis()
      , 1000


  testsList: ->
    preselectionBeforeSplittingGroups = null
    if @selectedTestsBasedOnTags.length != 0
      preselectionBeforeSplittingGroups = @selectedTestsBasedOnTags
    else
      preselectionBeforeSplittingGroups = AutomatorRecorderAndPlayer.testsManifest

    console.log "tests list before partitioning and picking: " + preselectionBeforeSplittingGroups

    console.log "tests list after partitioning and picking: " + preselectionBeforeSplittingGroups.chunk(Math.ceil(preselectionBeforeSplittingGroups.length / @numberOfGroups))[@groupToBeRun]

    actualTestList = preselectionBeforeSplittingGroups.chunk(Math.ceil(preselectionBeforeSplittingGroups.length / @numberOfGroups))[@groupToBeRun]

    return actualTestList


  loadTestMetadata: (testNumber, andThen)->

    if testNumber >= AutomatorRecorderAndPlayer.testsManifest.length
      andThen()
      return

    script = document.createElement('script')
    script.src = "js/tests/" + AutomatorRecorderAndPlayer.testsManifest[testNumber] + ".js"

    script.onload = =>
      @loadTestMetadata(testNumber+1, andThen)

    document.head.appendChild script


  loadTestsMetadata: (andThen) ->
    @loadTestMetadata 0, andThen

  loadAndRunSingleTestFromName: (testName) ->
    testNumber = AutomatorRecorderAndPlayer.testsManifest.indexOf("SystemTest_inspectorResizingOKEvenWhenTakenApart")
    debugger
    @loadTestMetadata testNumber, =>
      debugger
      @loadTest testNumber, =>
        debugger
        SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole "playing test: " + testName
        @automatorCommandsSequence = window[(testName)+ "_automationCommands"].automatorCommandsSequence
        @startTestPlaying()


  runNextSystemTest: ->
    @indexOfSystemTestBeingPlayed++
    if @indexOfSystemTestBeingPlayed >= @testsList().length
      SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole "finished all tests"
      world.nextStartupAction()
      return
    # Here we load the test dynamically,
    # by injecting a script that loads the js files
    # with the data. Better this than loading
    # all the tests data at once, we might only
    # need a few tests rather than all of them.
    @loadTest @indexOfSystemTestBeingPlayed, =>
      SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole "playing test: " + @testsList()[@indexOfSystemTestBeingPlayed]
      @automatorCommandsSequence = window[(@testsList()[@indexOfSystemTestBeingPlayed])+ "_automationCommands"].automatorCommandsSequence
      @startTestPlayingWithSlideIntro()

  # Select tests based on test names, or tags, or special
  # tag "all" to select them all.
  #
  # Examples to try from cosole:
  # world.systemTestsRecorderAndPlayer.selectTestsFromTagsOrTestNames(["shadow"]);
  # world.systemTestsRecorderAndPlayer.selectTestsFromTagsOrTestNames(["bubble"]);
  # world.systemTestsRecorderAndPlayer.selectTestsFromTagsOrTestNames(["shadow", "bubble"]);
  # world.systemTestsRecorderAndPlayer.selectTestsFromTagsOrTestNames(["all"]);
  # world.systemTestsRecorderAndPlayer.selectTestsFromTagsOrTestNames(["SystemTest_buildAllMorphs", "SystemTest_compositeMorphsHaveCorrectShadow"]);
  # world.systemTestsRecorderAndPlayer.selectTestsFromTagsOrTestNames(["bubble", "SystemTest_buildAllMorphs", "SystemTest_compositeMorphsHaveCorrectShadow"]);

  selectTestsFromTagsOrTestNames: (wantedTagsOrNamesArray) ->
    console.log "selectTestsFromTagsOrTestNames"
    # we proceed here to FIRST load all the
    # metadata of all the tests, then
    # we check the tags.

    # First name the callback that doest the
    # tags/names checks after the metadata
    # of all the tests is loaded.
    selectTheTestsBasedOnTags = \
      =>
        @selectedTestsBasedOnTags = []
        for eachTest in AutomatorRecorderAndPlayer.testsManifest
          for eachWantedTagOrName in wantedTagsOrNamesArray
            # special tag/name "all" matches all the tests
            if eachWantedTagOrName == "all"
              if (@selectedTestsBasedOnTags.indexOf eachTest) < 0
                @selectedTestsBasedOnTags.push eachTest
              continue
            if eachWantedTagOrName == eachTest
              if (@selectedTestsBasedOnTags.indexOf eachTest) < 0
                @selectedTestsBasedOnTags.push eachTest
              continue
            if (window[eachTest].tags.indexOf eachWantedTagOrName) >= 0
              if (@selectedTestsBasedOnTags.indexOf eachTest) < 0
                @selectedTestsBasedOnTags.push eachTest
              continue

        console.log @selectedTestsBasedOnTags

    # load the metadata of all the tests
    # and pass the callback to be run
    # when all the metadata is loaded.
    @loadTestsMetadata(selectTheTestsBasedOnTags)


  runAllSystemTestsForceSlow: ->
    @forceSlowTestPlaying = true
    @runAllSystemTests()

  runAllSystemTestsForceFastSkipInbetweenMouseMoves: ->
    @forceTurbo = true
    @forceSkippingInBetweenMouseMoves = true
    @runAllSystemTests()

  runAllSystemTestsForceFastRunInbetweenMouseMoves: ->
    @forceTurbo = true
    @forceRunningInBetweenMouseMoves = true
    @runAllSystemTests()


  runAllSystemTests: ->
    @failedTests = []
    console.log "runAllSystemTests"
    @millisOfAllTestsSoFar = 0

    # we proceed here to FIRST load all the
    # metadata of all the tests, then
    # one by one as needed we need the automatorCommands
    # and the assets.

    # First name the callback that starts the
    # running of the tests after the metadata
    # of all the tests is loaded.
    actuallyRunTheTests = \
      =>
        actualTestList = @testsList()
        @allTestsDuration = 0
        #debugger
        for eachTest in actualTestList
          @allTestsDuration += window["#{eachTest}"].testDuration

        @playingAllSystemTests = true
        @indexOfSystemTestBeingPlayed = -1
        @runNextSystemTest()

    # load the metadata of all the tests
    # and pass the callback to be run
    # when all the metadata is loaded.
    @loadTestsMetadata(actuallyRunTheTests)
    console.log "Running system tests: " + @testsList()

