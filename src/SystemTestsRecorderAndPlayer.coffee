# REQUIRES SystemTestsReferenceImage
# REQUIRES SystemTestsSystemInfo

# How to load/play a test:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# window.world.systemTestsRecorderAndPlayer.eventQueue = SystemTestsRepo_NAMEOFTHETEST.testCommandsSequence
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
  eventQueue: []
  @RECORDING: 0
  @PLAYING: 1
  @IDLE: 2
  @state: 2
  lastRecordedEventTime: null
  handMorph: null
  worldMorph: null
  collectedImages: [] # array of SystemTestsReferenceImage
  collectedFailureImages: [] # array of SystemTestsReferenceImage
  testName: ''
  testDescription: 'no description'
  @loadedImages: {}
  ongoingTestPlayingTask: null
  lastPlayedEventTime: 0
  indexOfQueuedEventBeingPlayed: 0
  animationsTiedToTestCommandNumber: false
  # this is a special place where the
  # "pic..." command places the image
  # data of a morph.
  # the test player will wait for this data
  # before doing the comparison.
  imageDataOfAParticularMorph: null


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
  
  startTestRecording: (@testName, @testDescription) ->

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

    @eventQueue = []
    @lastRecordedEventTime = new Date().getTime()
    SystemTestsRecorderAndPlayer.state = SystemTestsRecorderAndPlayer.RECORDING

  stopTestRecording: ->
    SystemTestsRecorderAndPlayer.state = SystemTestsRecorderAndPlayer.IDLE


  # gonna use this in a callback so need
  # to make this one a double-arrow
  stopTestPlaying: ->
    console.log "wrapping up the playing of the test"
    SystemTestsRecorderAndPlayer.state = SystemTestsRecorderAndPlayer.IDLE
    
    # There is a background interval that polls
    # to check whether it's time/condition to play
    # the next queued event. Remove it.
    indexOfTask = @worldMorph.otherTasksToBeRunOnStep.indexOf(@ongoingTestPlayingTask)
    @worldMorph.otherTasksToBeRunOnStep.splice(indexOfTask, 1)
    @worldMorph.initEventListeners()
    
    @indexOfQueuedEventBeingPlayed = 0

  showTestSource: ->
    window.open("data:text/text;charset=utf-8," + encodeURIComponent(JSON.stringify( @eventQueue, null, 4 )))

  untieAnimationsFromTestCommandNumber: ->
    @animationsTiedToTestCommandNumber = false
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventUntieAnimationsFromTestCommandNumber @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  tieAnimationsToTestCommandNumber: ->
    @animationsTiedToTestCommandNumber = true
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventTieAnimationsToTestCommandNumber @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addMouseMoveEvent: (pageX, pageY) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventMouseMove pageX, pageY, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addMouseDownEvent: (button, ctrlKey) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventMouseDown button, ctrlKey, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addMouseUpEvent: ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventMouseUp @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addKeyPressEvent: (charCode, symbol, shiftKey, ctrlKey, altKey, metaKey) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventKeyPress charCode, symbol, shiftKey, ctrlKey, altKey, metaKey, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addKeyDownEvent: (scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventKeyDown scanCode, shiftKey, ctrlKey, altKey, metaKey, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addKeyUpEvent: (scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventKeyUp scanCode, shiftKey, ctrlKey, altKey, metaKey, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addCopyEvent: () ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventCopy @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addPasteEvent: (clipboardText) ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventPaste clipboardText, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()


  deleteAllMorphs: ->
    return if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
    systemTestEvent = new SystemTestsEventDeleteAllMorphs @
    window[systemTestEvent.testCommand].replayFunction @, null
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

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
    @lastRecordedEventTime = new Date().getTime()
    comment = prompt("enter comment", "your comment here")
    systemTestEvent = new SystemTestsShowComment comment, @
    @eventQueue.push systemTestEvent

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
      systemTestEvent = new SystemTestsEventCheckNumberOfItemsInMenu numberOfItems, @
      @eventQueue.push systemTestEvent
      @lastRecordedEventTime = new Date().getTime()
    else if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.PLAYING
      menuAtPointer = @handMorph.menuAtPointer()
      giveSuccess = =>
        message = "number of items in menu matches. Note that count includes line separators. Found: " + menuAtPointer.items.length
        if SystemTestsControlPanelUpdater?
          SystemTestsControlPanelUpdater.addMessageToVisualComparisonsConsole message
      giveError = =>
        errorMessage = "Number of items in menu doesn't match. Note that count includes line separators. Was expecting: " + numberOfItems + " found: " + menuAtPointer.items.length
        if SystemTestsControlPanelUpdater?
          SystemTestsControlPanelUpdater.addMessageToVisualComparisonsConsole errorMessage
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
    systemTestEvent = new SystemTestsEventScreenshot imageName, @, whichMorph != @worldMorph
    imageData = whichMorph.fullImageData()
    takenScreenshot = new SystemTestsReferenceImage(imageName,imageData, new SystemTestsSystemInfo())
    unless SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"]?
      SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"] = []
    SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"].push takenScreenshot
    @collectedImages.push takenScreenshot
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()
    if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.RECORDING
      return systemTestEvent

  # a lenghty method because there
  # is a lot of API dancing, but the
  # concept is really easy: return
  # a new canvas with an image that is
  # red in all areas where the
  # "expected" and "obtained" images
  # are different.
  # So it neatly highlights where the differences
  # are.
  subtractScreenshots: (expected, obtained, andThen) ->
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
        andThen subtractionCanvas

      obtainedImage.src = obtained.imageData

    expectedImage.src = expected.imageData

  compareScreenshots: (testNameWithImageNumber, screenshotTakenOfAParticularMorph = false) ->
   if screenshotTakenOfAParticularMorph
     console.log "comparing pic of a particular morph"
     screenshotObtained = @imageDataOfAParticularMorph
     @imageDataOfAParticularMorph = null
   else
     console.log "comparing pic of whole desktop"
     screenshotObtained = @worldMorph.fullImageData()
   
   console.log "trying to match screenshot: " + testNameWithImageNumber
   console.log "length of obtained: " + screenshotObtained.length

   # There can be multiple files for the same image, since
   # the images vary according to OS and Browser, so for
   # each image of each test there is an array of candidates
   # to be checked. If any of them mathes in terms of pixel data,
   # then fine, otherwise complain...
   for eachImage in SystemTestsRecorderAndPlayer.loadedImages["#{testNameWithImageNumber}"]
     console.log "length of obtained: " + eachImage.imageData.length
     if eachImage.imageData == screenshotObtained
      message = "PASS - screenshot " + eachImage.fileName + " matched"
      console.log message
      if SystemTestsControlPanelUpdater?
        SystemTestsControlPanelUpdater.addMessageToVisualComparisonsConsole message
      return
   # OK none of the images we loaded matches the one we
   # just takes. Hence create a SystemTestsReferenceImage
   # that we can let the user download - it will contain
   # the image actually obtained (rather than the one
   # we should have seen)
   message = "FAIL - no screenshots like this one"
   console.log message
   if SystemTestsControlPanelUpdater?
     SystemTestsControlPanelUpdater.addMessageToVisualComparisonsConsole message
   obtainedImageName = "obtained-" + eachImage.imageName
   obtainedImage = new SystemTestsReferenceImage(obtainedImageName,screenshotObtained, new SystemTestsSystemInfo())
   @collectedFailureImages.push obtainedImage

  replayEvents: ->
   timeNow = (new Date()).getTime()
   queuedEvent = @eventQueue[@indexOfQueuedEventBeingPlayed]
   # console.log "examining event: " + queuedEvent.testCommand + " at: " + queuedEvent.millisecondsSinceLastCommand +
   #   " time now: " + timeNow + " we are at: " + (timeNow - @lastPlayedEventTime)
   timeOfNextItem = queuedEvent.millisecondsSinceLastCommand or 0
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
   if queuedEvent.testCommand == "SystemTestsEventScreenshot" and queuedEvent.screenshotTakenOfAParticularMorph
     if not @imageDataOfAParticularMorph?
       # no image data of morph, so just wait
       return
   if timeNow - @lastPlayedEventTime >= timeOfNextItem
     console.log "running event: " + queuedEvent.testCommand + " " + @indexOfQueuedEventBeingPlayed + " / " + @eventQueue.length
     window[queuedEvent.testCommand].replayFunction.call @,@,queuedEvent
     @lastPlayedEventTime = timeNow
     @indexOfQueuedEventBeingPlayed++
     if @indexOfQueuedEventBeingPlayed == @eventQueue.length
       console.log "stopping the test player"
       @stopTestPlaying()

  startTestPlaying: ->
    SystemTestsRecorderAndPlayer.state = SystemTestsRecorderAndPlayer.PLAYING
    @worldMorph.removeEventListeners()
    @ongoingTestPlayingTask = (=> @replayEvents())
    @worldMorph.otherTasksToBeRunOnStep.push @ongoingTestPlayingTask


  testFileContentCreator: (commands) ->
    # these here below is just one string
    # spanning multiple lines, which
    # includes the testName and commands
    # in the right places.

    testToBeSerialised = {}
    testToBeSerialised.timeRecorded = new Date()
    testToBeSerialised.description = @testDescription
    testToBeSerialised.systemInfo = new SystemTestsSystemInfo()
    testToBeSerialised.testCommandsSequence = commands

    """
  // This system test is automatically
  // created.
  // This test (and related reference images)
  // can be copied in the /src/tests folder
  // to make them available in the testing
  // environment.
  var SystemTest_#{@testName};

  SystemTest_#{@testName} = #{JSON.stringify(testToBeSerialised, null, 4)};
    """

  saveFailedScreenshots: ->
    zip = new JSZip()
    
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
    for i in [0...@collectedFailureImages.length]
      failedImage = @collectedFailureImages[i]
      aGoodImageName = (failedImage).imageName.replace("obtained-", "")
      setOfGoodImages = SystemTestsRecorderAndPlayer.loadedImages[aGoodImageName]
      aGoodImage = setOfGoodImages[0]
      # note the asynchronous operation here - this is because
      # the subtractScreenshots needs to create some Images and
      # load them with data from base64 string. The operation
      # of loading the data is asynchronous...
      @subtractScreenshots failedImage, aGoodImage, (subtractionCanvas) ->
        zip.file("diff-"+failedImage.imageName+".png", subtractionCanvas.toDataURL().replace(/^data:image\/png;base64,/, ""), {base64: true});

    # OK the images are all put in the zip
    # asynchronously. So, in theory what we should do is to
    # check that we have all the image packed
    # and then save the zip. In practice we just wait
    # a second (which is well beyond what we
    # expect all the images to take to be packed)
    # and then save it.
    setTimeout \
      =>
        console.log "saving failed screenshots"
        if navigator.userAgent.search("Safari") >= 0 and navigator.userAgent.search("Chrome") < 0
          console.log "safari"
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
      , 1000 



  saveTest: ->
    blob = @testFileContentCreator window.world.systemTestsRecorderAndPlayer.eventQueue
    zip = new JSZip()
    zip.file("SystemTest_#{@testName}.js", blob);
    
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

  testsList: ->
    # Check which objects have the right name start
    console.log Object.keys(window)
    (Object.keys(window)).filter (i) ->
      console.log i.indexOf("SystemTest_")
      i.indexOf("SystemTest_") == 0

  runSystemTests: ->
    console.log "System tests: " + @testsList()
    for i in @testsList()
      #console.log window[i]
      @eventQueue = (window[i]).testCommandsSequence
      # the Zombie kernel safari pop-up is painted weird, needs a refresh
      # for some unknown reason
      #@changed()
      # start from clean slate
      #@destroyAll()
      @startTestPlaying()
