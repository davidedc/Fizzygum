# A prompt whose value is free text: a single StringFieldWdgt editor above the
# "Ok"/"Close" rows. Widget.prompt routes here when no numeric ceiling is given.

class TextPromptWdgt extends PromptWdgt

  constructor: (widgetOpeningThePopUp, msg, target, callback, defaultContents, intendedWidth) ->
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
      false)
    panel.environment = @tempPromptEntryField
    panel._addNoSettle @tempPromptEntryField
    # _addNoSettle skips the child's calculateAndUpdateExtent (which measures the
    # text and applies width >= minTextWidth, feeding the panel's width via
    # menuEntryPreferredWidth); run it explicitly.
    @tempPromptEntryField.calculateAndUpdateExtent()
