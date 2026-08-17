# A prompt whose value is a number: a numeric StringFieldWdgt paired with a
# SliderWdgt that writes the rounded value back into the field. Widget.prompt
# routes here when a numeric ceiling (or the useSliderForInput preference) is set.

class NumberPromptWdgt extends PromptWdgt

  floorNum: undefined
  ceilingNum: undefined
  isRounded: undefined

  constructor: (widgetOpeningThePopUp, target, opts = {}) ->
    # read BEFORE the build below: _buildAndAddValueEditorInto reads all three.
    @floorNum = opts.floorNum
    @ceilingNum = opts.ceilingNum
    @isRounded = opts.isRounded
    super widgetOpeningThePopUp, target, opts
    @_buildAndConnectChildren()

  _buildAndAddValueEditorInto: (panel) ->
    @_buildAndAddEntryFieldInto panel, (@ceilingNum?)

    slider = new SliderWdgt(
      @floorNum or 0,
      @ceilingNum,
      parseFloat(@defaultContents),
      Math.floor((@ceilingNum - @floorNum) / 4))
    slider.alpha = 1
    slider.color = Color.create 225, 225, 225
    slider.button.setColorScheme Color.create 60, 60, 60
    slider.__commitHeight WorldWdgt.preferencesAndSettings.prompterSliderSize
    # A named wire verb — a controller owns a LIST of wire records (§P4), so there is no target/action
    # field pair to assign. The QUIET one, because the field and the slider are already consistent
    # here — I built the slider from @defaultContents — and firing would round that default away and
    # open an edit before the prompt is on screen.
    slider.declareWireTo @, "takeSliderValue"
    panel._addNoSettle slider

  takeSliderValue: (num) ->
    @_settleLayoutsAfter => @_takeSliderValueNoSettle num

  # The reactive-CONNECTOR entrypoint (check-layering [P]): the dataflow engine delivers the prompt slider's wire
  # HERE (its @action is "takeSliderValue", so _applyWireValue / _fireConnection resolve `_<action>Connector`
  # first). It JOINS the drain's enclosing settle instead of opening its own, so the mid-drain _editNoSettle in the
  # core below is legal (edit() is public/self-settling -- illegal mid-flush; see Widget._settleLayoutsAfter's
  # re-entrancy throw). Same NoSettle core as the public takeSliderValue above -- the setFontSize /
  # _setFontSizeConnector pattern. No cycle guard needed: this is a pure SINK (it never calls updateTarget),
  # so a circuit cannot cycle through it. The engine delivers ONE argument (_applyWireValue passes the pulled
  # value and nothing else), which is all this takes.
  _takeSliderValueConnector: (num) ->
    @_settleLayoutsAfterOrJoinEnclosingPass => @_takeSliderValueNoSettle num

  _takeSliderValueNoSettle: (num) ->
    # the field's inner text is a StringWdgt. Use _setTextNoSettle
    # -- which re-runs _synchroniseTextAndActualText so textPossiblyCroppedToFit tracks the new
    # value -- instead of poking .text + _reLayoutSelf (StringWdgt has no _reLayoutSelf that refits).
    # Otherwise _editNoSettle below sees a stale cropped text and defers to the "edit:" prompt.
    # No invalidation here: _setTextNoSettle self-marks the text on a real change (its core ends
    # with _changed()), and the entry field's own box pixels don't change on a value update.
    @tempPromptEntryField.text._setTextNoSettle Math.round(num).toString()
    @tempPromptEntryField.text._editNoSettle()
