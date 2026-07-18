# The "save as..." prompt: a text field for the shortcut name over a
# "Don't save" / "Cancel" / "Ok" button row. A member of the prompt family (it
# shares PromptWdgt's PopUpWdgt behaviour + composed titled rows-panel); it only
# swaps in its own three buttons (no leading divider) and edits the field at once.

class SaveShortcutPromptWdgt extends PromptWdgt

  # the trailing spaces pad the title so the prompt opens at a decent width.
  msg: " save as...         "

  wdgtWhereReferenceWillGo: nil

  constructor: (widgetOpeningThePopUp, @target, @defaultContents, @intendedWidth = 100, @wdgtWhereReferenceWillGo) ->
    if !@defaultContents
      @defaultContents = world.untitledNamingService.getNextUntitledShortcutName()
    super widgetOpeningThePopUp, @msg, @target, nil, @defaultContents, @intendedWidth
    @_buildAndConnectChildren()
    @rowsPanel._applyWidth 150
    @_applyExtent @rowsPanel.extent()
    @tempPromptEntryField.text.edit()

  _buildAndAddValueEditorInto: (panel) ->
    @tempPromptEntryField = new StringFieldWdgt(
      @defaultContents,
      150,
      WorldWdgt.preferencesAndSettings.prompterFontSize,
      WorldWdgt.preferencesAndSettings.prompterFontName,
      false,
      false,
      false)
    panel.environment = @tempPromptEntryField
    panel._addNoSettle @tempPromptEntryField
    # _addNoSettle skips calculateAndUpdateExtent (which measures the text and
    # applies width >= minTextWidth); run it explicitly.
    @tempPromptEntryField.calculateAndUpdateExtent()

  # save-as has its own three buttons and no leading divider (unlike the base row).
  _addButtonsInto: (panel) ->
    panel.addMenuItem "Don't save", @target, "destroy"
    # "Cancel" here just dismisses this prompt, but the target wdgt remains open.
    panel.addMenuItem "Cancel", @, "close"
    panel.addMenuItem "Ok", @, "createReferenceAndClose"

  createReferenceAndClose: ->
    @target.createReferenceAndClose @tempPromptEntryField.text.text, @wdgtWhereReferenceWillGo
    @close()
