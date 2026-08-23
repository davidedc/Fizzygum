# A prompt whose value is free text: a single StringFieldWdgt editor above the
# "Ok"/"Close" rows. Widget.prompt routes here when no numeric ceiling is given.

class TextPromptWdgt extends PromptWdgt

  constructor: (widgetOpeningThePopUp, target, opts = {}) ->
    super widgetOpeningThePopUp, target, opts
    @_buildPromptRows()

  _buildAndAddValueEditorInto: (panel) ->
    @_buildAndAddEntryFieldInto panel, false
