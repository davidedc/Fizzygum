class VideoDurationLabelWdgt extends HhmmssLabelWdgt

  videoPlayerCanvas: nil

  colloquialName: ->
    "Video duration"

  constructor: (@videoPlayerCanvas) ->
    super "n/a", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @alignLeft()

    # the label of the is updated via the stepping
    # mechanism, but you could do that via the connectors mechanism
    # instead, ideally you should have the canvas widget to only fire when
    # the time changes at the seconds level, and only
    # within a step.
    @fps = 5
    world.steppingWdgts.add @

  step: ->
    @_updateDurationTimeLabel()
  
  _updateDurationTimeLabel: ->
    if @videoPlayerCanvas?
      # per-frame label update via the NON-settling core -- the frame loop settles it; a settling
      # setText every frame would be needless churn (and throws if step ever runs mid-pass).
      @_setTextNoSettle @_formatTime @videoPlayerCanvas.video.duration
