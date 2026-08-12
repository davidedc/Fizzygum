# A prompt whose value is free text: a single StringFieldWdgt editor above the
# "Ok"/"Close" rows. Widget.prompt routes here when no numeric ceiling is given.

class TextPromptWdgt extends PromptWdgt

  constructor: (widgetOpeningThePopUp, msg, target, callback, defaultContents, intendedWidth) ->
    super widgetOpeningThePopUp, msg, target, callback, defaultContents, intendedWidth
    @_buildAndConnectChildren()

  _buildAndAddValueEditorInto: (panel) ->
    @_buildAndAddEntryFieldInto panel, false
