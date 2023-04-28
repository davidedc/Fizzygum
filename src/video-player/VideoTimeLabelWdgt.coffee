class VideoTimeLabelWdgt extends HhmmssLabelWdgt

  videoPlayerCanvas: nil

  colloquialName: ->
    "Video time"

  constructor: (@videoPlayerCanvas) ->
    super "n/a", WorldMorph.preferencesAndSettings.textInButtonsFontSize
    @alignLeft()

    # the label of the current time is updated via the stepping
    # mechanism, but you could do that via the connectors mechanism
    # instead, ideally you should have the canvas widget to only fire when
    # the time changes at the seconds level, and only
    # within a step.
    @fps = 5
    world.steppingWdgts.add @

  step: ->
    @_updatePlayHeadTimeLabel()

  _updatePlayHeadTimeLabel: ->
    if @videoPlayerCanvas?
      @setText @_formatTime @videoPlayerCanvas.video.currentTime
