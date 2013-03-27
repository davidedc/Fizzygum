class MouseKeyboardEvent
  constructor: (@type, @mouseX, @mouseY, @time, @button, @ctrlKey) ->
    console.log @type + " " + @mouseX + " " + @mouseY + " " + @time + " " + @button + " " + @ctrlKey

class MouseKeyboardEventsRecorderAndPlayer
  eventQueue: []
  recordingMouseAndKeyboardEvents = false
  replayingMouseAndKeyboardEvents = false
  recorderStartTime = null
  playerStartTime = null
  handMorph = null

  constructor: (@handMorph) ->

  startRecording: ->
    @eventQueue = []
    @recorderStartTime = new Date().getTime()
    @recordingMouseAndKeyboardEvents = true
    @replayingMouseAndKeyboardEvents = false

  stopRecording: ->
    @recordingMouseAndKeyboardEvents = false

  startPlaying: ->
    @playerStartTime = null
    @recordingMouseAndKeyboardEvents = false
    @replayingMouseAndKeyboardEvents = true
    @replayEvents()

  stopPlaying: ->
    @replayingMouseAndKeyboardEvents = false

  addMouseMoveEvent: (pageX, pageY) ->
    return if not @recordingMouseAndKeyboardEvents
    @eventQueue.push(
      new MouseKeyboardEvent(
        "mouseMove",
        pageX,
        pageY,
        new Date().getTime() - @recorderStartTime,
        null,
        null
      )
    )

  addMouseDownEvent: (pageX, pageY, button, ctrlKey) ->
    return if not @recordingMouseAndKeyboardEvents
    @eventQueue.push(
      new MouseKeyboardEvent(
        "mouseDown",
        pageX,
        pageY,
        new Date().getTime() - @recorderStartTime,
        button,
        ctrlKey
      )
    )

  addMouseUpEvent: () ->
    return if not @recordingMouseAndKeyboardEvents
    @eventQueue.push(
      new MouseKeyboardEvent(
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
