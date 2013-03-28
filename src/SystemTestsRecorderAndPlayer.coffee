class SystemTestsRecorderAndPlayer
  eventQueue: []
  recordingASystemTest: false
  replayingASystemTest: false
  lastRecordedEventTime: null
  handMorph: null

  constructor: (@worldMorph, @handMorph) ->

  startRecording: ->
    @eventQueue = []
    @lastRecordedEventTime = new Date().getTime()
    @recordingASystemTest = true
    @replayingASystemTest = false

    systemTestEvent = {}
    systemTestEvent.type = "systemInfo"
    systemTestEvent.zombieKernelTestHarnessVersionMajor = 0
    systemTestEvent.zombieKernelTestHarnessVersionMinor = 1
    systemTestEvent.zombieKernelTestHarnessVersionRelease = 0
    systemTestEvent.time = 0
    systemTestEvent.userAgent = navigator.userAgent
    systemTestEvent.screenWidth = window.screen.width
    systemTestEvent.screenHeight = window.screen.height
    systemTestEvent.screenColorDepth = window.screen.colorDepth
    if window.devicePixelRatio?
      systemTestEvent.screenPixelRatio = window.devicePixelRatio
    else
      systemTestEvent.screenPixelRatio = window.devicePixelRatio
    systemTestEvent.appCodeName = navigator.appCodeName
    systemTestEvent.appName = navigator.appName
    systemTestEvent.appVersion = navigator.appVersion
    systemTestEvent.cookieEnabled = navigator.cookieEnabled
    systemTestEvent.platform = navigator.platform
    systemTestEvent.systemLanguage = navigator.systemLanguage
    @eventQueue.push systemTestEvent

  stopRecording: ->
    @recordingASystemTest = false

  startPlaying: ->
    @recordingASystemTest = false
    @replayingASystemTest = true
    @replayEvents()

  stopPlaying: ->
    @replayingASystemTest = false

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
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  addMouseDownEvent: (button, ctrlKey) ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseDown"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    systemTestEvent.button = button
    systemTestEvent.ctrlKey = ctrlKey
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

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
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  takeScreenshot: () ->
    return if not @recordingASystemTest
    console.log "taking screenshot"
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "takeScreenshot"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    systemTestEvent.screenShotImageData = @worldMorph.fullImageData()
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  compareScreenshots: (expected) ->
   if expected == @worldMorph.fullImageData()
    console.log "PASS - screenshot as expected"
   else
    console.log "FAIL - screenshot is different from expected"

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
      callback = => @compareScreenshots(queuedEvent.screenShotImageData)
    else return

    setTimeout callback, lastPlayedEventTime
    #console.log "scheduling " + queuedEvent.type + "event for " + lastPlayedEventTime
