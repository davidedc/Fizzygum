# PromptMorph ///////////////////////////////////////////////////

class PromptMorph extends MenuMorph

  # pattern: all the children should be declared here
  # the reason is that when you duplicate a morph
  # , the duplicated morph needs to have the handles
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

  constructor: (morphOpeningThePopUp, @msg, @target, @callback, @defaultContents, @intendedWidth, @floorNum,
    @ceilingNum, @isRounded) ->

    isNumeric = true  if @ceilingNum
    @tempPromptEntryField = new StringFieldMorph(
      @defaultContents or "",
      @intendedWidth or 100,
      WorldMorph.preferencesAndSettings.prompterFontSize,
      WorldMorph.preferencesAndSettings.prompterFontName,
      false,
      false,
      isNumeric)

    super morphOpeningThePopUp, false, @target, true, true, @msg or "", @tempPromptEntryField


    @silentAdd @tempPromptEntryField
    if @ceilingNum or WorldMorph.preferencesAndSettings.useSliderForInput
      slider = new SliderMorph(
        @floorNum or 0,
        @ceilingNum,
        parseFloat(@defaultContents),
        Math.floor((@ceilingNum - @floorNum) / 4))
      slider.alpha = 1
      slider.color = new Color 225, 225, 225
      slider.button.color = new Color 60,60,60
      slider.button.highlightColor = slider.button.color.copy()
      slider.button.highlightColor.b += 100
      slider.button.pressColor = slider.button.color.copy()
      slider.button.pressColor.b += 150
      slider.silentRawSetHeight WorldMorph.preferencesAndSettings.prompterSliderSize
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

    @reLayout()

  reactToSliderAction: (num) ->
    @tempPromptEntryField.changed()
    @tempPromptEntryField.text.text = Math.round(num).toString()
    @tempPromptEntryField.text.reLayout()
    
    @tempPromptEntryField.text.changed()
    @tempPromptEntryField.text.edit()

  reLayout: ->
    super()
    @buildSubmorphs()
    @notifyChildrenThatParentHasReLayouted()

  buildSubmorphs: ->

  imBeingAddedTo: (newParentMorph) ->
  
