# REQUIRES SystemTestsReferenceImage
# REQUIRES SystemTestsSystemInfo

# How to load/play a test:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# window.world.systemTestsRecorderAndPlayer.eventQueue = SystemTestsRepo_NAMEOFTHETEST.testData
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
  recordingASystemTest: false
  replayingASystemTest: false
  lastRecordedEventTime: null
  handMorph: null
  collectedImages: [] # array of SystemTestsReferenceImage
  collectedFailureImages: [] # array of SystemTestsReferenceImage
  testName: ''
  @loadedImages: {}

  constructor: (@worldMorph, @handMorph) ->

  startTestRecording: (@testName) ->
    # clean up the world so we start from clean slate
    @worldMorph.destroyAll()
    @eventQueue = []
    @lastRecordedEventTime = new Date().getTime()
    @recordingASystemTest = true
    @replayingASystemTest = false

    systemTestEvent = {}
    systemTestEvent.type = "systemInfo"
    systemTestEvent.time = 0
    systemTestEvent.SystemTestsInfo = new SystemTestsSystemInfo()
    @eventQueue.push systemTestEvent

  stopTestRecording: ->
    @recordingASystemTest = false

  startTestPlaying: ->
    @recordingASystemTest = false
    @replayingASystemTest = true
    @replayEvents()

  stopPlaying: ->
    @replayingASystemTest = false

  showTestSource: ->
    window.open("data:text/text;charset=utf-8," + encodeURIComponent(JSON.stringify( @eventQueue, null, 4 )))

  addMouseMoveEvent: (pageX, pageY) ->
    return if not @recordingASystemTest
    systemTestEvent = new SystemTestsEventMouseMove pageX, pageY, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = systemTestEvent.timeOfCreation


  addMouseDownEvent: (button, ctrlKey) ->
    return if not @recordingASystemTest
    systemTestEvent = new SystemTestsEventMouseDown button, ctrlKey, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = systemTestEvent.timeOfCreation

  addMouseUpEvent: () ->
    return if not @recordingASystemTest
    systemTestEvent = new SystemTestsEventMouseUp @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = systemTestEvent.timeOfCreation

  takeScreenshot: () ->
    console.log "taking screenshot"
    imageName = "SystemTest_"+@testName+"_image_" + (@collectedImages.length + 1)
    systemTestEvent = new SystemTestsEventScreenshot imageName, @
    imageData = @worldMorph.fullImageData()
    takenScreenshot = new SystemTestsReferenceImage(imageName,imageData, new SystemTestsSystemInfo())
    unless SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"]?
      SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"] = []
    SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"].push takenScreenshot
    @collectedImages.push takenScreenshot
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = systemTestEvent.timeOfCreation
    if not @recordingASystemTest
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
  subtractScreenshots: (expected, obtained) ->
    console.log "subtractScreenshots"
    expectedCanvas = document.createElement "canvas"
    expectedImage = new Image
    expectedImage.src = expected.imageData
    expectedCanvas.width = expectedImage.width
    expectedCanvas.height = expectedImage.height
    expectedCanvasContext = expectedCanvas.getContext "2d"
    expectedCanvasContext.drawImage(expectedImage,0,0)
    expectedImageData = expectedCanvasContext.getImageData(0, 0, expectedCanvas.width, expectedCanvas.height)

    obtainedCanvas = document.createElement "canvas"
    obtainedImage = new Image
    obtainedImage.src = obtained.imageData
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
    return subtractionCanvas


  compareScreenshots: (testNameWithImageNumber) ->
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
        SystemTestsControlPanelUpdater.addMessageToConsole message
      return
   # OK none of the images we loaded matches the one we
   # just takes. Hence create a SystemTestsReferenceImage
   # that we can let the user download - it will contain
   # the image actually obtained (rather than the one
   # we should have seen)
   message = "FAIL - no screenshots like this one"
   console.log message
   if SystemTestsControlPanelUpdater?
     SystemTestsControlPanelUpdater.addMessageToConsole message
   obtainedImageName = "obtained-" + eachImage.imageName
   obtainedImage = new SystemTestsReferenceImage(obtainedImageName,screenshotObtained, new SystemTestsSystemInfo())
   @collectedFailureImages.push obtainedImage

  replayEvents: () ->
   lastPlayedEventTime = 0
   console.log "events: " + @eventQueue
   for queuedEvent in @eventQueue
      lastPlayedEventTime += queuedEvent.time
      @scheduleEvent(queuedEvent, lastPlayedEventTime)

  scheduleEvent: (queuedEvent, lastPlayedEventTime) ->
    if window[queuedEvent.type]?
      if window[queuedEvent.type].replayFunction?
        callback = =>  window[queuedEvent.type].replayFunction.call @,@,queuedEvent
        setTimeout callback, lastPlayedEventTime
        #console.log "scheduling " + queuedEvent.type + "event for " + lastPlayedEventTime

  testFileContentCreator: (data) ->
    # these here below is just one string
    # spanning multiple lines, which
    # includes the testName and data variables
    # in the right places.
    # This is the equivalent of the following
    # coffeescript content:
    ###
      class SystemTest_SimpleMenuTest
        @testData = [
          type: "systemInfo"
          ... all the remaining test data...
    ###
    "
  var SystemTest_#{@testName}Test;

  SystemTest_#{@testName}Test = (function() {
    function SystemTest_#{@testName}Test() {}

    SystemTest_#{@testName}Test.testData = #{data};

    return SystemTest_#{@testName}Test;

  })();
    "

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
      subtractionCanvas = @subtractScreenshots failedImage, aGoodImage
      zip.file("diff-"+failedImage.imageName+".png", subtractionCanvas.toDataURL().replace(/^data:image\/png;base64,/, ""), {base64: true});

    content = zip.generate({type:"blob"})
    saveAs(content, "SystemTest_#{@testName}TestFailedScreenshots.zip")    

  saveTest: ->
    blob = @testFileContentCreator(JSON.stringify( window.world.systemTestsRecorderAndPlayer.eventQueue, null, 4))
    zip = new JSZip()
    zip.file("SystemTest_#{@testName}Test.js", blob);
    
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
    
    content = zip.generate({type:"blob"})
    saveAs(content, "SystemTest_#{@testName}Test.zip")    
