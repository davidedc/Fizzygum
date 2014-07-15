# REQUIRES SystemTestsReferenceImage
# REQUIRES SystemTest_SystemInfo

# How to load/play a test:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# window.world.systemTestsRecorderAndPlayer.eventQueue = SystemTestsRepo_NAMEOFTHETEST.testData
# window.world.systemTestsRecorderAndPlayer.startTestPlaying()

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
    systemTestEvent.SystemTestsInfo = new SystemTest_SystemInfo()
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
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseMove"
    systemTestEvent.mouseX = pageX
    systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    #systemTestEvent.screenShotImageName
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  addMouseDownEvent: (button, ctrlKey) ->
    return if not @recordingASystemTest
    systemTestEvent = new SystemTestsEventMouseDown button, ctrlKey, @
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = new Date().getTime()

  addMouseUpEvent: () ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseUp"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    #systemTestEvent.screenShotImageName
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  takeScreenshot: () ->
    console.log "taking screenshot"
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "takeScreenshot"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    imageName = "SystemTest_"+@testName+"_image_" + (@collectedImages.length + 1)
    systemTestEvent.screenShotImageName = imageName
    imageData = @worldMorph.fullImageData()
    SystemTestsRecorderAndPlayer.loadedImages["#{imageName}"] = imageData
    @collectedImages.push new SystemTestsReferenceImage(imageName,imageData)
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime
    if not @recordingASystemTest
      return systemTestEvent

  compareScreenshots: (expected) ->
   console.log "trying to match screenshot: " + expected
   console.log "length1: " + SystemTestsRecorderAndPlayer.loadedImages["#{expected}"].length
   console.log "length2: " + @worldMorph.fullImageData().length
   if SystemTestsRecorderAndPlayer.loadedImages["#{expected}"] == @worldMorph.fullImageData()
    console.log "PASS - screenshot " + expected + " matched"
    return
   console.log "FAIL - no screenshots like this one"

  replayEvents: () ->
   lastPlayedEventTime = 0
   console.log "events: " + @eventQueue
   for queuedEvent in @eventQueue
      lastPlayedEventTime += queuedEvent.time
      @scheduleEvent(queuedEvent, lastPlayedEventTime)

  scheduleEvent: (queuedEvent, lastPlayedEventTime) ->
    if queuedEvent.type == 'mouseMove'
      callback = => @handMorph.processMouseMove(queuedEvent.mouseX, queuedEvent.mouseY)
    else if queuedEvent.type == 'mouseDown'
      callback = => @handMorph.processMouseDown(queuedEvent.button, queuedEvent.ctrlKey)
    else if queuedEvent.type == 'mouseUp'
      callback = => @handMorph.processMouseUp()
    else if queuedEvent.type == 'takeScreenshot'
      callback = => @compareScreenshots(queuedEvent.screenShotImageName)
    else return

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

  saveTest: ->
    blob = @testFileContentCreator(JSON.stringify( window.world.systemTestsRecorderAndPlayer.eventQueue, null, 4))
    zip = new JSZip()
    zip.file("SystemTest_#{@testName}Test.js", blob);
    for image in @collectedImages
      zip.file(image.imageName + ".js", "SystemTestsRecorderAndPlayer.loadedImages." + image.imageName + ' = "' + image.imageData + '";')
      
      # let's also save the png file so it's easier to browse the data
      # note that these png files are not copied over into the
      # build directory.
      # the image.imageData string contains a little bit of string
      # that we need to strip out before the base64-encoded png data
      zip.file(image.imageName + ".png", image.imageData.replace(/^data:image\/png;base64,/, ""), {base64: true})
    
    content = zip.generate({type:"blob"})
    saveAs(content, "SystemTest_#{@testName}Test.zip")    
