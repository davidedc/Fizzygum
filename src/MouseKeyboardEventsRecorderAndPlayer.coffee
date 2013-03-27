class MouseKeyboardEvent
  constructor: (@type, @mouseX, @mouseY, @time, @event) ->
    console.log @type + " " + @mouseX + " " + @mouseY + " " + @time

class MouseKeyboardEventsRecorderAndPlayer
  eventQueue: []
  recordingMouseAndKeyboardEvents = false
  replayingMouseAndKeyboardEvents = false
  recorderStartTime = null
  playerStartTime = null
  handMorph = null

  constructor: (@handMorph) ->

  startRecording: ->
    eventQueue = []
    @recorderStartTime = new Date().getTime()
    @recordingMouseAndKeyboardEvents = true
    @replayingMouseAndKeyboardEvents = false

  stopRecording: ->
    @recordingMouseAndKeyboardEvents = false

  startPlaying: ->
    @playerStartTime = null
    @recordingMouseAndKeyboardEvents = false
    @replayingMouseAndKeyboardEvents = true

  stopPlaying: ->
    @replayingMouseAndKeyboardEvents = false

  addMouseMoveEvent: (event) ->
    return if not @recordingMouseAndKeyboardEvents
    @eventQueue.push(
      new MouseKeyboardEvent(
        "mousemove",
        event.pageX,
        event.pageY,
        new Date().getTime() - @recorderStartTime,
        event
      )
    )

  replayEvents: () ->
    for queuedEvent in @eventQueue
      @replayEvent queuedEvent

  replayEvent: (queuedEvent) ->
    if @playerStartTime is null
      @playerStartTime = new Date().getTime()

    if queuedEvent.type == 'mousemove'
      setTimeout(@handMorph.processMouseMove(queuedEvent.e), queuedEvent.time)
