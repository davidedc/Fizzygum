# A prompt whose value is a colour: a ColorPickerWdgt above the "Ok"/"Close"
# rows. This is the folded Widget.pickColor: the ad-hoc inline MenuWdgt that
# colour picking hand-rolls becomes a first-class member of the prompt family.
# Widget.pickColor routes here.

class ColorPromptWdgt extends PromptWdgt

  # the picker is this prompt's value editor (color has no text field, so the
  # base's tempPromptEntryField stays undefined); declared for duplicate remapping.
  colorPicker: undefined

  constructor: (widgetOpeningThePopUp, target, opts = {}) ->
    super widgetOpeningThePopUp, target, opts
    @_buildPromptRows()

  _buildAndAddValueEditorInto: (panel) ->
    @colorPicker = new ColorPickerWdgt @defaultValue
    panel._addNoSettle @colorPicker
    # _addNoSettle skips the child's calculateAndUpdateExtent (which the old bare
    # @__add ran to size the picker into the panel's width); run it explicitly.
    @colorPicker.calculateAndUpdateExtent?()

  # my value is the picker's colour, not an entry field's string.
  _promptValue: ->
    @colorPicker.getColor()
