class SystemTestsEvent
  constructor: (@type, @mouseX, @mouseY, @time, @button, @ctrlKey, @screenShotImageData = '') ->
    console.log @type + " " + @mouseX + " " + @mouseY + " " + @time + " " + @button + " " + @ctrlKey + " " + hashCode(@screenShotImageData)

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
    @eventQueue.push(
      new SystemTestsEvent(
        "mouseMove",
        pageX,
        pageY,
        currentTime - @lastRecordedEventTime,
        null,
        null
      )
    )
    @lastRecordedEventTime = currentTime

  addMouseDownEvent: (button, ctrlKey) ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    @eventQueue.push(
      new SystemTestsEvent(
        "mouseDown",
        null,
        null,
        currentTime - @lastRecordedEventTime,
        button,
        ctrlKey,
        null
      )
    )
    @lastRecordedEventTime = currentTime

  addMouseUpEvent: () ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    @eventQueue.push(
      new SystemTestsEvent(
        "mouseUp",
        null,
        null,
        currentTime - @lastRecordedEventTime,
        null,
        null,
        null
      )
    )
    @lastRecordedEventTime = currentTime

  takeScreenshot: () ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    @eventQueue.push(
      new SystemTestsEvent(
        "takeScreenshot",
        null,
        null,
        currentTime - @lastRecordedEventTime,
        null,
        null,
        @worldMorph.fullImageData()
      )
    )
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
