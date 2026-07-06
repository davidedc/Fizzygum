# Tells the window's contents that the edit button was pressed.
# See IconButtonWdgt for the shared icon-button family contract.

class EditIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "edit contents"

  createAppearance: -> new PencilIconAppearance @

  actOnClick: ->
    # Notify the containing window its edit button was pressed (the window forwards
    # to its contents); only a window answers editButtonInBarPressed, so this fires
    # for exactly the old `instanceof WindowWdgt` set. (type-test-elimination campaign)
    @parent?.editButtonInBarPressed?()

  # STATE-semantics glyph swap (docs/pencil-eye-edit-mode-toggle-plan.md §1):
  # pencil = content is in edit mode NOW; eye = content is in view mode NOW.
  # The tooltip always states the ACTION a click performs. The window's
  # showEditModeInBar / showViewModeInBar drive these alongside the recolor;
  # iconToolTipMessage stays the constructor-time default (the view/eye case).
  showPencilGlyph: ->
    @appearance = new PencilIconAppearance @
    @toolTipMessage = "switch to view mode"
    @changed()

  showEyeGlyph: ->
    @appearance = new EyeIconAppearance @
    @toolTipMessage = "edit contents"
    @changed()
