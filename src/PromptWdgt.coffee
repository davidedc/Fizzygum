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


    @silentAdd @tempPromptEntryField
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
      slider.action = "reactToSliderAction"
      @silentAdd slider
    @addLine 2

    @addMenuItem "Ok", true, @target, @callback
    # we name the button "Close" instead of "Cancel"
    # because we are not undoing any change we made
    # that would be rather difficult in case of
    # multiple prompts being pinned down and changing
    # the property concurrently
    @addMenuItem "Close", true, @, "close"

    @_reLayoutSelf()

  reactToSliderAction: (num) ->
    @tempPromptEntryField.changed()
    # the field's inner text is a StringWdgt. Use setText
    # -- which re-runs synchroniseTextAndActualText so textPossiblyCroppedToFit tracks the new
    # value -- instead of poking .text + _reLayoutSelf (StringWdgt has no _reLayoutSelf that refits).
    # Otherwise edit() below sees a stale cropped text and defers to the "edit:" prompt.
    @tempPromptEntryField.text.setText Math.round(num).toString()
    @tempPromptEntryField.text.changed()
    @tempPromptEntryField.text.edit()

  _reLayoutSelf: ->
    super()
    @buildSubwidgets()

  buildSubwidgets: ->

  _reactToBeingAdded: (whereTo, beingDropped) ->
  
