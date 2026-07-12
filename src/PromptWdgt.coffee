class PromptWdgt extends MenuWdgt

  # pattern: all the children should be declared here
  # the reason is that when you duplicate a widget
  # , the duplicated widget needs to have the handles
  # that will be duplicated. If you don't list them
  # here, then they need to be initialised in the
  # constructor. But actually they might not be
  # initialised in the constructor if a "lazy initialisation"
  # approach is taken. So it's good practice
  # to list them here so they can be duplicated either way.
  #feedback: nil
  #choice: nil
  #colorPalette: nil
  #grayPalette: nil

  tempPromptEntryField: nil

  # constructor-build-exempt: menu-family ctor (see MenuWdgt) — composes its entry field and
  # optional slider through the __add structural leaf alongside addMenuItem, then re-lays
  # itself (_reLayoutSelf) at the end; not the panel _buildAndConnectChildrenNoSettle
  # pattern. Recorded 2026-07-12 when the gate learned to see @__add.
  constructor: (widgetOpeningThePopUp, @msg, @target, @callback, @defaultContents, @intendedWidth, @floorNum,
    @ceilingNum, @isRounded) ->

    isNumeric = true  if @ceilingNum
    @tempPromptEntryField = new StringFieldWdgt(
      @defaultContents or "",
      @intendedWidth or 100,
      WorldWdgt.preferencesAndSettings.prompterFontSize,
      WorldWdgt.preferencesAndSettings.prompterFontName,
      false,
      false,
      isNumeric)

    super widgetOpeningThePopUp, false, @target, true, true, @msg or "", @tempPromptEntryField


    @__add @tempPromptEntryField
    if @ceilingNum or WorldWdgt.preferencesAndSettings.useSliderForInput
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
      @__add slider
    @addLine 2

    @addMenuItem "Ok", true, @target, @callback
    # we name the button "Close" instead of "Cancel"
    # because we are not undoing any change we made
    # that would be rather difficult in case of
    # multiple prompts being pinned down and changing
    # the property concurrently
    @addMenuItem "Close", true, @, "close"

    @_reLayoutSelf()

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
    @tempPromptEntryField.changed()
    # the field's inner text is a StringWdgt. Use _setTextNoSettle
    # -- which re-runs synchroniseTextAndActualText so textPossiblyCroppedToFit tracks the new
    # value -- instead of poking .text + _reLayoutSelf (StringWdgt has no _reLayoutSelf that refits).
    # Otherwise _editNoSettle below sees a stale cropped text and defers to the "edit:" prompt.
    @tempPromptEntryField.text._setTextNoSettle Math.round(num).toString()
    @tempPromptEntryField.text.changed()
    @tempPromptEntryField.text._editNoSettle()

  _reLayoutSelf: ->
    super()
    @buildSubwidgets()

  buildSubwidgets: ->

  _reactToBeingAdded: (whereTo, beingDropped) ->
  
