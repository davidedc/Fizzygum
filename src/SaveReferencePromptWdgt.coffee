class SaveReferencePromptWdgt extends MenuMorph

  # bad hack to set the prompt to a
  # decent width
  # TODO this widget has to be re-made using
  # vertical stack layout anyways
  msg: " save as...         "

  tempPromptEntryField: nil

  constructor: (morphOpeningThePopUp, @target, @defaultContents = "untitled", @intendedWidth = 100, @wdgtWhereReferenceWillGo) ->

    @tempPromptEntryField = new StringFieldWdgt2(
      @defaultContents,
      150,
      WorldMorph.preferencesAndSettings.prompterFontSize,
      WorldMorph.preferencesAndSettings.prompterFontName,
      false,
      false,
      false
    )

    super morphOpeningThePopUp, false, @target, true, true, @msg, @tempPromptEntryField


    @silentAdd @tempPromptEntryField

    @addMenuItem "Don't save", true, @target, "moveToTrash"
    # "Cancel" here just dismisses this prompt, but the target
    # wdgt remains open
    @addMenuItem "Cancel", true, @, "close"
    @addMenuItem "Ok", true, @target, "createReferenceAndClose", nil, nil,nil,nil,nil

    @reLayout()
    @rawSetWidth 150
    @tempPromptEntryField.text.edit()

  reLayout: ->
    super()
    @buildSubmorphs()
    @notifyChildrenThatParentHasReLayouted()

  buildSubmorphs: ->

  iHaveBeenAddedTo: (whereTo, beingDropped) ->
  
