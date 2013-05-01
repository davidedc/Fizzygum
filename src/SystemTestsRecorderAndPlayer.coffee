class SystemTestsRecorderAndPlayer
  eventQueue: []
  recordingASystemTest: false
  replayingASystemTest: false
  lastRecordedEventTime: null
  handMorph: null
  systemInfo: null

  constructor: (@worldMorph, @handMorph) ->

  initialiseSystemInfo: ->
    @systemInfo = {}
    @systemInfo.zombieKernelTestHarnessVersionMajor = 0
    @systemInfo.zombieKernelTestHarnessVersionMinor = 1
    @systemInfo.zombieKernelTestHarnessVersionRelease = 0
    @systemInfo.userAgent = navigator.userAgent
    @systemInfo.screenWidth = window.screen.width
    @systemInfo.screenHeight = window.screen.height
    @systemInfo.screenColorDepth = window.screen.colorDepth
    if window.devicePixelRatio?
      @systemInfo.screenPixelRatio = window.devicePixelRatio
    else
      @systemInfo.screenPixelRatio = window.devicePixelRatio
    @systemInfo.appCodeName = navigator.appCodeName
    @systemInfo.appName = navigator.appName
    @systemInfo.appVersion = navigator.appVersion
    @systemInfo.cookieEnabled = navigator.cookieEnabled
    @systemInfo.platform = navigator.platform
    @systemInfo.systemLanguage = navigator.systemLanguage

  startTestRecording: ->
    # clean up the world so we start from clean slate
    @worldMorph.destroyAll()
    @eventQueue = []
    @lastRecordedEventTime = new Date().getTime()
    @recordingASystemTest = true
    @replayingASystemTest = false

    @initialiseSystemInfo()
    systemTestEvent = {}
    systemTestEvent.type = "systemInfo"
    systemTestEvent.time = 0
    systemTestEvent.systemInfo = @systemInfo
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
    window.open("data:text/text;charset=utf-8," + encodeURIComponent(JSON.stringify( @eventQueue )))

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
    console.log "taking screenshot"
    if @systemInfo is null
      @initialiseSystemInfo()
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "takeScreenshot"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    systemTestEvent.screenShotImageData = []
    systemTestEvent.screenShotImageData.push [@systemInfo, @worldMorph.fullImageData()]
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime
    if not @recordingASystemTest
      return systemTestEvent

  compareScreenshots: (expected) ->
   i = 0
   console.log "expected length " + expected.length
   for a in expected
     console.log "trying to match screenshot: " + i
     i++
     if a[1] == @worldMorph.fullImageData()
      console.log "PASS - screenshot (" + i + ") matched"
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
      callback = => @compareScreenshots(queuedEvent.screenShotImageData)
    else return

    setTimeout callback, lastPlayedEventTime
    #console.log "scheduling " + queuedEvent.type + "event for " + lastPlayedEventTime
