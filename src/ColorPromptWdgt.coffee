# A prompt whose value is a colour: a ColorPickerWdgt above the "Ok"/"Close"
# rows. This is the folded Widget.pickColor: the ad-hoc inline MenuWdgt that
# colour picking hand-rolls becomes a first-class member of the prompt family.
# Widget.pickColor routes here.

class ColorPromptWdgt extends PromptWdgt

  # the picker is this prompt's value editor (color has no text field, so the
  # base's tempPromptEntryField stays nil); declared for duplicate remapping.
  colorPicker: nil

  constructor: (widgetOpeningThePopUp, msg, target, callback, defaultContents) ->
    super widgetOpeningThePopUp, msg, target, callback, defaultContents
    @_buildAndConnectChildren()

  _buildAndAddValueEditorInto: (panel) ->
    @colorPicker = new ColorPickerWdgt @defaultContents
    panel.environment = @colorPicker
    panel._addNoSettle @colorPicker
    # _addNoSettle skips the child's calculateAndUpdateExtent (which the old bare
    # @__add ran to size the picker into the panel's width); run it explicitly.
    @colorPicker.calculateAndUpdateExtent?()
