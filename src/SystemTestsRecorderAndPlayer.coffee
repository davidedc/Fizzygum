class SystemTestsEvent
  constructor: (@type, @mouseX, @mouseY, @time, @button, @ctrlKey) ->
    console.log @type + " " + @mouseX + " " + @mouseY + " " + @time + " " + @button + " " + @ctrlKey

class SystemTestsRecorderAndPlayer
  eventQueue: []
  recordingASystemTest = false
  replayingASystemTest = false
  recorderStartTime = null
  playerStartTime = null
  handMorph = null

  constructor: (@handMorph) ->

  startRecording: ->
    @eventQueue = []
    @recorderStartTime = new Date().getTime()
    @recordingASystemTest = true
    @replayingASystemTest = false

  stopRecording: ->
    @recordingASystemTest = false

  startPlaying: ->
    @playerStartTime = null
    @recordingASystemTest = false
    @replayingASystemTest = true
    @replayEvents()

  stopPlaying: ->
    @replayingASystemTest = false

  addMouseMoveEvent: (pageX, pageY) ->
    return if not @recordingASystemTest
    @eventQueue.push(
      new SystemTestsEvent(
        "mouseMove",
        pageX,
        pageY,
        new Date().getTime() - @recorderStartTime,
        null,
        null
      )
    )

  addMouseDownEvent: (pageX, pageY, button, ctrlKey) ->
    return if not @recordingASystemTest
    @eventQueue.push(
      new SystemTestsEvent(
        "mouseDown",
        pageX,
        pageY,
        new Date().getTime() - @recorderStartTime,
        button,
        ctrlKey
      )
    )

  addMouseUpEvent: () ->
    return if not @recordingASystemTest
    @eventQueue.push(
      new SystemTestsEvent(
        "mouseUp",
        null,
        null,
        new Date().getTime() - @recorderStartTime,
        null,
        null
      )
    )

  replayEvents: () ->
    for queuedEvent in @eventQueue
      @replayEvent queuedEvent

  replayEvent: (queuedEvent) ->
    if @playerStartTime is null
      @playerStartTime = new Date().getTime()

    if queuedEvent.type == 'mouseMove'
      callback = => @handMorph.processMouseMove(queuedEvent.mouseX, queuedEvent.mouseY)
    else if queuedEvent.type == 'mouseDown'
      callback = => @handMorph.processMouseDown(queuedEvent.button, queuedEvent.ctrlKey)
    else if queuedEvent.type == 'mouseUp'
      callback = => @handMorph.processMouseUp()
    else return

    setTimeout callback, queuedEvent.time
