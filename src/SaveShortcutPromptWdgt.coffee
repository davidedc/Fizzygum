# The "save as..." prompt: a text field for the shortcut name over a
# "Don't save" / "Cancel" / "Ok" button row. A member of the prompt family (it
# shares PromptWdgt's PopUpWdgt behaviour + composed titled rows-panel); it only
# swaps in its own three buttons (no leading divider) and edits the field at once.

class SaveShortcutPromptWdgt extends PromptWdgt

  # the trailing spaces pad the title so the prompt opens at a decent width.
  msg: " save as...         "

  wdgtWhereReferenceWillGo: undefined

  # No msg and no callback: the title is the class-level constant above, and there
  # is no caller action — Ok routes to my own createReferenceAndClose. Both are
  # simply absent from the options I forward, which is why the base reads msg
  # guarded (a bare assignment there would blank the constant).
  constructor: (widgetOpeningThePopUp, target, opts = {}) ->
    @wdgtWhereReferenceWillGo = opts.wdgtWhereReferenceWillGo
    defaultContents = opts.defaultContents
    if !defaultContents
      defaultContents = world.untitledNamingService.getNextUntitledShortcutName()
    super widgetOpeningThePopUp, target,
      defaultContents: defaultContents
      intendedWidth: opts.intendedWidth ? 100
    @_buildAndConnectChildren()
    @rowsPanel._applyWidth 150
    @_applyExtent @rowsPanel.extent()
    @tempPromptEntryField.text.edit()

  _buildAndAddValueEditorInto: (panel) ->
    @tempPromptEntryField = new StringFieldWdgt @defaultContents,
      minTextWidth: 150
      fontSize: WorldWdgt.preferencesAndSettings.prompterFontSize
      fontStyle: WorldWdgt.preferencesAndSettings.prompterFontName
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
