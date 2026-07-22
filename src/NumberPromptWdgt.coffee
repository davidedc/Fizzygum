# A prompt whose value is a number: a numeric StringFieldWdgt paired with a
# SliderWdgt that writes the rounded value back into the field. Widget.prompt
# routes here when a numeric ceiling (or the useSliderForInput preference) is set.

class NumberPromptWdgt extends PromptWdgt

  floorNum: nil
  ceilingNum: nil
  isRounded: nil

  constructor: (widgetOpeningThePopUp, msg, target, callback, defaultContents, intendedWidth, @floorNum, @ceilingNum, @isRounded) ->
    super widgetOpeningThePopUp, msg, target, callback, defaultContents, intendedWidth
    @_buildAndConnectChildren()

  _buildAndAddValueEditorInto: (panel) ->
    @tempPromptEntryField = new StringFieldWdgt(
      @defaultContents or "",
      @intendedWidth or 100,
      WorldWdgt.preferencesAndSettings.prompterFontSize,
      WorldWdgt.preferencesAndSettings.prompterFontName,
      false,
      false,
      (@ceilingNum?))
    panel.environment = @tempPromptEntryField
    panel._addNoSettle @tempPromptEntryField
    # _addNoSettle skips calculateAndUpdateExtent (which measures the text and
    # applies width >= minTextWidth, feeding the panel width); run it explicitly.
    @tempPromptEntryField.calculateAndUpdateExtent()

    slider = new SliderWdgt(
      @floorNum or 0,
      @ceilingNum,
      parseFloat(@defaultContents),
      Math.floor((@ceilingNum - @floorNum) / 4))
    slider.alpha = 1
    slider.color = Color.create 225, 225, 225
    slider.button.setColorScheme Color.create 60, 60, 60
    slider.__commitHeight WorldWdgt.preferencesAndSettings.prompterSliderSize
    slider.target = @
    slider.argumentToAction = @
    slider.action = "takeSliderValue"
    panel._addNoSettle slider

  takeSliderValue: (num) ->
    @_settleLayoutsAfter => @_takeSliderValueNoSettle num

  # The reactive-CONNECTOR entrypoint (check-layering [P]): the dataflow engine delivers the prompt slider's wire
  # HERE (its @action is "takeSliderValue", so _applyWireValue / _fireConnection resolve `_<action>Connector`
  # first). It JOINS the drain's enclosing settle instead of opening its own, so the mid-drain _editNoSettle in the
  # core below is legal (edit() is public/self-settling -- illegal mid-flush, Widget:824). Same NoSettle core as the
  # public takeSliderValue above -- the setFontSize / _setFontSizeConnector pattern. NO connectionsCalculation
  # Token guard: this is a pure SINK (it never calls updateTarget), so a circuit cannot cycle through it; the
  # dispatch's extra (argumentToAction, token) arguments are simply ignored, exactly as the public entry ignores them.
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
