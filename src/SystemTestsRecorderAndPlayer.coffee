# REQUIRES SystemTestsReferenceImage
# REQUIRES SystemTestsSystemInfo

# How to load/play a test:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# window.world.systemTestsRecorderAndPlayer.testCommandsSequence = NAMEOFTHETEST.testCommandsSequence
# (e.g. window.world.systemTestsRecorderAndPlayer.testCommandsSequence = SystemTest_attachRectangleToPartsOfInspector.testCommandsSequence )
# window.world.systemTestsRecorderAndPlayer.startTestPlaying()

# How to inspect the screenshot differences:
# after having playes a test with some failing screenshots
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
# window.world.systemTestsRecorderAndPlayer.startTestPlaying()

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

class SystemTestsRecorderAndPlayer
  testCommandsSequence: []
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
  @loadedImages: {}
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


  constructor: (@worldMorph, @handMorph) ->

  # clear any test with the same name
  # that might be loaded
  # and all the images related to it
  clearAnyDataRelatedToTest: (testName) ->
    # we assume that no-one is going to
    # write a tests with more than
    # 100 reference images/screenshots
    for imageNumber in [0...100]
      # each of these is an array that could contain
      # multiple screenshots for different browser/os
      # configuration, we are clearing the variable
      # containing the array
      console.log "deleting SystemTest_#{@testName}_image_#{imageNumber}"
      delete SystemTestsRecorderAndPlayer.loadedImages["SystemTest_#{@testName}_image_#{imageNumber}"]
    console.log "deleting SystemTest_#{@testName}"
    delete window["SystemTest_#{@testName}"]
  
  startTestRecording: (ignored, ingnored2, @testName, @testDescription) ->

    # if test name not provided, then
    # prompt the user for it
    if not @testName?
      @testName = prompt("Please enter a test name", "test1")
    if not @testDescription?
      @testDescription = prompt("Please enter a test description", "no description")

    # if you choose the same name
    # of a previously loaded tests,
    # confusing things might happen such
    # as comparison with loaded screenshots
    # so we want to clear the data related
    # to the chosen name
    @clearAnyDataRelatedToTest @testName

    @testCommandsSequence = []
    @timeOfPreviouslyRecordedCommand = new Date().getTime()
    SystemTestsRecorderAndPlayer.state = SystemTestsRecorderAndPlayer.RECORDING

  stopTestRecording: ->
    SystemTestsRecorderAndPlayer.state = SystemTestsRecorderAndPlayer.IDLE


  # gonna use this in a callback so need
  # to make this one a double-arrow
  stopTestPlaying: ->
    console.log "wrapping up the playing of the test"
    SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole "test complete"
    SystemTestsRecorderAndPlayer.state = SystemTestsRecorderAndPlayer.IDLE
    
    # There is a background interval that polls
    # to check whether it's time/condition to play
    # the next queued command. Remove it.
    indexOfTask = @worldMorph.otherTasksToBeRunOnStep.indexOf(@ongoingTestPlayingTask)
    @worldMorph.otherTasksToBeRunOnStep.splice(indexOfTask, 1)
    @worldMorph.initEventListeners()
    
    @indexOfTestCommandBeingPlayedFromSequence = 0

    if @playingAllSystemTests
      @runNextSystemTest()

  showTestSource: ->
    window.open("data:text/text;charset=utf-8," + encodeURIComponent(JSON.stringify( @testCommandsSequence, null, 4 )))

  turnOnAnimationsPacingControl: ->
    @constructor.animationsPacingControl = true
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOnAnimationsPacingControl @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffAnimationsPacingControl: ->
    @constructor.animationsPacingControl = false
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOffAnimationsPacingControl @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOnAlignmentOfMorphIDsMechanism: ->
    @constructor.alignmentOfMorphIDsMechanism = true
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOnAlignmentOfMorphIDsMechanism @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffAlignmentOfMorphIDsMechanism: ->
    @constructor.alignmentOfMorphIDsMechanism = false
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOffAlignmentOfMorphIDsMechanism @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOnHidingOfMorphsGeometryInfoInLabels: ->
    @constructor.hidingOfMorphsGeometryInfoInLabels = true
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOnHidingOfMorphsGeometryInfoInLabels @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffHidingOfMorphsGeometryInfoInLabels: ->
    @constructor.hidingOfMorphsGeometryInfoInLabels = false
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOffHidingOfMorphsGeometryInfoInLabels @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOnHidingOfMorphsContentExtractInLabels: ->
    @constructor.hidingOfMorphsContentExtractInLabels = true
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOnHidingOfMorphsContentExtractInLabels @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffHidingOfMorphsContentExtractInLabels: ->
    @constructor.hidingOfMorphsContentExtractInLabels = false
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOffHidingOfMorphsContentExtractInLabels @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOnHidingOfMorphsNumberIDInLabels: ->
    @constructor.hidingOfMorphsNumberIDInLabels = true
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOnHidingOfMorphsNumberIDInLabels @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  turnOffHidingOfMorphsNumberIDInLabels: ->
    @constructor.hidingOfMorphsNumberIDInLabels = false
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandTurnOffHidingOfMorphsNumberIDInLabels @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()


  addMouseMoveCommand: (pageX, pageY) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandMouseMove pageX, pageY, @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addMouseDownCommand: (button, ctrlKey) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandMouseDown button, ctrlKey, @
    @lastMouseDownCommand = systemTestCommand
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addOpenContextMenuCommand: (context) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    @removeLastMouseUpAndMouseDownCommands()
    systemTestCommand = new SystemTestsCommandOpenContextMenu context, @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addCommandLeftOrRightClickOnMenuItem: (mouseButton, labelString, occurrenceNumber) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    @removeLastMouseUpAndMouseDownCommands()
    systemTestCommand = new SystemTestsCommandLeftOrRightClickOnMenuItem mouseButton, labelString, occurrenceNumber, @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addMouseUpCommand: ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandMouseUp @
    @lastMouseUpCommand = systemTestCommand
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()
  
  # doesn't *actually* remove the command
  # because you do need to wait the time.
  # because for example the bubbles pop-up
  # after some time.
  # You could remove the commands and note down
  # how much was the wait on each and charge it to
  # the next command but that would be very messy.
  removeLastMouseUpAndMouseDownCommands: ->
    @lastMouseDownCommand.transformIntoDoNothingCommand()
    @lastMouseUpCommand.transformIntoDoNothingCommand()

  addKeyPressCommand: (charCode, symbol, shiftKey, ctrlKey, altKey, metaKey) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandKeyPress charCode, symbol, shiftKey, ctrlKey, altKey, metaKey, @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addKeyDownCommand: (scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandKeyDown scanCode, shiftKey, ctrlKey, altKey, metaKey, @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addKeyUpCommand: (scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandKeyUp scanCode, shiftKey, ctrlKey, altKey, metaKey, @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addCopyCommand: () ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandCopy @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addPasteCommand: (clipboardText) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandPaste clipboardText, @
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()


  resetWorld: ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestCommand = new SystemTestsCommandResetWorld @
    window[systemTestCommand.testCommandName].replayFunction @, null
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()

  addTestComment: ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
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
    systemTestCommand = new SystemTestsCommandShowComment comment, @
    @testCommandsSequence.push systemTestCommand

  checkStringsOfItemsInMenuOrderImportant: (stringOfItemsInMenuInOriginalOrder) ->
    @checkStringsOfItemsInMenu(stringOfItemsInMenuInOriginalOrder, true)

  checkStringsOfItemsInMenuOrderUnimportant: (stringOfItemsInMenuInOriginalOrder) ->
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
      console.log "FAIL was expecting a menu under the pointer"
      if SystemTestsControlPanelUpdater?
        SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole errorMessage
      @stopTestPlaying()

    if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.RECORDING
      if orderMatters
        systemTestCommand = new SystemTestsCommandCheckStringsOfItemsInMenuOrderImportant stringOfItemsInCurrentMenuInOriginalOrder, @
      else
        systemTestCommand = new SystemTestsCommandCheckStringsOfItemsInMenuOrderUnimportant stringOfItemsInCurrentMenuInOriginalOrder, @

      @testCommandsSequence.push systemTestCommand
      @timeOfPreviouslyRecordedCommand = new Date().getTime()
    else if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.PLAYING
      giveSuccess = =>
        if orderMatters
          message = "PASS Strings in menu are same and in same order"
        else
          message = "PASS Strings in menu are same (not considering order)"
        if SystemTestsControlPanelUpdater?
          SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole message
      giveError = =>
        if orderMatters
          errorMessage = "FAIL Strings in menu doesn't match or order is incorrect. Was expecting: " + stringOfItemsInMenuInOriginalOrder + " found: " + stringOfItemsInCurrentMenuInOriginalOrder
        else
          errorMessage = "FAIL Strings in menu doesn't match (even not considering order). Was expecting: " + stringOfItemsInMenuInOriginalOrder + " found: " + stringOfItemsInCurrentMenuInOriginalOrder
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
    if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.RECORDING
      menuAtPointer = @handMorph.menuAtPointer()
      console.log menuAtPointer
      if menuAtPointer?
        numberOfItems = menuAtPointer.items.length
        console.log "found " + numberOfItems + " number of items "
      else
        console.log "was expecting a menu under the pointer"
        numberOfItems = 0
      systemTestCommand = new SystemTestsCommandCheckNumberOfItemsInMenu numberOfItems, @
      @testCommandsSequence.push systemTestCommand
      @timeOfPreviouslyRecordedCommand = new Date().getTime()
    else if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.PLAYING
      menuAtPointer = @handMorph.menuAtPointer()
      giveSuccess = =>
        message = "PASS Number of items in menu matches. Note that count includes line separators. Found: " + menuAtPointer.items.length
        if SystemTestsControlPanelUpdater?
          SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole message
      giveError = =>
        errorMessage = "FAIL Number of items in menu doesn't match. Note that count includes line separators. Was expecting: " + numberOfItems + " found: " + menuAtPointer.items.length
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
    systemTestCommand = new SystemTestsCommandScreenshot imageName, @, whichMorph != @worldMorph

    imageData = whichMorph.asItAppearsOnScreen()

    takenScreenshot = new SystemTestsReferenceImage(imageName,imageData, new SystemTestsSystemInfo())
    unless SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"]?
      SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"] = []
    SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"].push takenScreenshot
    @collectedImages.push takenScreenshot
    @testCommandsSequence.push systemTestCommand
    @timeOfPreviouslyRecordedCommand = new Date().getTime()
    if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
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
   for eachImage in SystemTestsRecorderAndPlayer.loadedImages["#{testNameWithImageNumber}"]
     console.log "length of obtained: " + eachImage.imageData.length
     if eachImage.imageData == screenshotObtained
      message = "PASS - screenshot " + eachImage.fileName + " matched"
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
   if SystemTestsControlPanelUpdater?
     SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole message
   obtainedImageName = "obtained-" + eachImage.imageName
   obtainedImage = new SystemTestsReferenceImage(obtainedImageName,screenshotObtained, new SystemTestsSystemInfo())
   @collectedFailureImages.push obtainedImage

  replayTestCommands: ->
   timeNow = (new Date()).getTime()
   commandToBePlayed = @testCommandsSequence[@indexOfTestCommandBeingPlayedFromSequence]
   # console.log "examining command: " + commandToBePlayed.testCommandName + " at: " + commandToBePlayed.millisecondsSincePreviousCommand +
   #   " time now: " + timeNow + " we are at: " + (timeNow - @timeOfPreviouslyPlayedCommand)
   timeUntilNextCommand = commandToBePlayed.millisecondsSincePreviousCommand or 0
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
   if commandToBePlayed.testCommandName == "SystemTestsCommandScreenshot" and commandToBePlayed.screenshotTakenOfAParticularMorph
     if not @imageDataOfAParticularMorph?
       # no image data of morph, so just wait
       return
   if timeNow - @timeOfPreviouslyPlayedCommand >= timeUntilNextCommand
     console.log "running command: " + commandToBePlayed.testCommandName + " " + @indexOfTestCommandBeingPlayedFromSequence + " / " + @testCommandsSequence.length
     window[commandToBePlayed.testCommandName].replayFunction.call @,@,commandToBePlayed
     @timeOfPreviouslyPlayedCommand = timeNow
     @indexOfTestCommandBeingPlayedFromSequence++
     if @indexOfTestCommandBeingPlayedFromSequence == @testCommandsSequence.length
       console.log "stopping the test player"
       @stopTestPlaying()

  startTestPlaying: ->
    SystemTestsRecorderAndPlayer.state = SystemTestsRecorderAndPlayer.PLAYING
    @constructor.animationsPacingControl = true
    @worldMorph.removeEventListeners()
    @ongoingTestPlayingTask = (=> @replayTestCommands())
    @worldMorph.otherTasksToBeRunOnStep.push @ongoingTestPlayingTask


  testMetadataFileContentCreator: ->
    # these here below is just one string
    # spanning multiple lines, which
    # includes the testName and commands
    # in the right places.

    testToBeSerialized = {}
    testToBeSerialized.timeRecorded = new Date()
    testToBeSerialized.description = @testDescription
    # A string that can be used to group
    # tests together, imagine for example they
    # could be visualised in a tree structure of
    # some sort.
    # to begin with, it will be sorted
    # alphabetically so at the top we put the
    # "topical" tests that we just want run
    # quickly cause they are about stuff
    # we are working on right now.
    testToBeSerialized.testGroup = "00: current tests / 00: unused / 00: unused"
    testToBeSerialized.systemInfo = new SystemTestsSystemInfo()

    """
  // This system test is automatically
  // created.
  // This test (and related reference images)
  // can be copied in the /src/tests folder
  // to make them available in the testing
  // environment.
  var SystemTest_#{@testName};

  SystemTest_#{@testName} = #{JSON.stringify(testToBeSerialized, null, 4)};
    """

  testCommandsFileContentCreator: (commands) ->
    # these here below is just one string
    # spanning multiple lines, which
    # includes the testName and commands
    # in the right places.

    testToBeSerialized = {}
    testToBeSerialized.testCommandsSequence = commands
    testNameExtended = @testName + "_testCommands"

    """
  // This system test is automatically
  // created.
  // This test (and related reference images)
  // can be copied in the /src/tests folder
  // to make them available in the testing
  // environment.
  var SystemTest_#{testNameExtended};

  SystemTest_#{testNameExtended} = #{JSON.stringify(testToBeSerialized, null, 4)};
    """

  saveFailedScreenshots: ->
    zip = new JSZip()
    
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
      renamerScript += "rm " + "../Zombie-Kernel-tests/tests/" + filenameForScript + "/" +
              systemInfo.os.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.osVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browser.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browserVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              "devicePixelRatio_" + pixelRatioString + "/" +
              aGoodImageName + "*\n"
      renamerScript += "cp " + (failedImage).imageName + "* ../Zombie-Kernel-tests/tests/" + filenameForScript + "/" +
              systemInfo.os.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.osVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browser.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              systemInfo.browserVersion.replace(/\s+/g, "-").replace(/\.+/g, "_") + "/" +
              "devicePixelRatio_" + pixelRatioString + "/\n\n"

      setOfGoodImages = SystemTestsRecorderAndPlayer.loadedImages[aGoodImageName]
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

    blob = @testCommandsFileContentCreator window.world.systemTestsRecorderAndPlayer.testCommandsSequence
    testNameExtended = @testName + "_testCommands"
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
    script.src = "js/tests/"+@testsList()[testNumber] + "_testCommands.js"

    script.onload = =>
      @loadImagesOfTest andThenDoThis

    document.head.appendChild script

  loadImagesOfTest: (andThenDoThis)->

    for eachCommand in window[(@testsList()[@indexOfSystemTestBeingPlayed])+ "_testCommands"].testCommandsSequence
      if eachCommand.screenShotImageName?
        pureImageName = eachCommand.screenShotImageName
        for eachAssetInManifest in SystemTestsRecorderAndPlayer.testsAssetsManifest
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
    return SystemTestsRecorderAndPlayer.testsManifest

  loadTestMetadata: (testNumber, andThen)->

    if testNumber >= @testsList().length
      andThen()
      return

    script = document.createElement('script')
    script.src = "js/tests/"+@testsList()[testNumber] + ".js"

    script.onload = =>
      @loadTestMetadata(testNumber+1, andThen)

    document.head.appendChild script


  loadTestsMetadata: (andThen) ->
    @loadTestMetadata 0, andThen

  runNextSystemTest: ->
    @indexOfSystemTestBeingPlayed++
    if @indexOfSystemTestBeingPlayed >= @testsList().length
      SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole "finished all tests"
      return
    # Here we load the test dynamically,
    # by injecting a script that loads the js files
    # with the data. Better this than loading
    # all the tests data at once, we might only
    # need a few tests rather than all of them.
    @loadTest @indexOfSystemTestBeingPlayed, =>
      SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole "playing test: " + @testsList()[@indexOfSystemTestBeingPlayed]
      @testCommandsSequence = window[(@testsList()[@indexOfSystemTestBeingPlayed])+ "_testCommands"].testCommandsSequence
      @startTestPlaying()

  runAllSystemTests: ->
    # we proceed here to FIRST load all the
    # metadata of all the tests, then
    # one by one as needed we need the testCommands
    # and the assets.

    # First name the callback that starts the
    # running of the tests after the metadata
    # of all the tests is loaded.
    actuallyRunTheTests = \
      =>
        @playingAllSystemTests = true
        @indexOfSystemTestBeingPlayed = -1
        @runNextSystemTest()

    # load the metadata of all the tests
    # and pass the callback to be run
    # when all the metadata is loaded.
    @loadTestsMetadata(actuallyRunTheTests)
    console.log "System tests: " + @testsList()

