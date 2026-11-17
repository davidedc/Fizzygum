# Shared behaviour of the three alignment buttons (left / center / right):
# align the last-clicked widget directly if it knows how, otherwise — if it is
# a vertical-stack element — set the alignment on its layout spec. Subclasses
# supply the two method names and the alignment they set (and the icon + tooltip
# via the base). A button shows active while the text it aligns directly has its
# alignment (the family's mirror of the edited text); the layout-spec branch is
# not mirrored. Both branches take the widget from the world's editable focus
# within the window the button works for (WorldWdgt.editableEditorFocus, asked
# with ToolbarWdgt.hostWindowOf): content in view mode is aligned by neither,
# and neither is a widget outside the window the button's toolbar is docked on
# -- a button pressed there does nothing and shows inactive. A floating toolbar
# works for the person, so its buttons align the focus wherever it is.

class AlignButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  alignDirectMethod: undefined        # e.g. "alignLeft"
  layoutAlignSetterMethod: undefined  # e.g. "setAlignmentToLeft"
  horizontalAlignmentName: undefined  # e.g. "LEFT": the AlignmentSpecHorizontal my direct method sets

  # ACTIVE while the text I would align directly already has my alignment
  isActiveTool: ->
    subject = @_styleSubject()
    subject?[@alignDirectMethod]? and subject.horizontalAlignment is AlignmentSpecHorizontal[@horizontalAlignmentName]

  activated: ->
    subject = @_styleSubject()
    lastClicked = world.editableEditorFocus ToolbarWdgt.hostWindowOf @
    if subject?[@alignDirectMethod]?
      subject[@alignDirectMethod]()
    else if lastClicked?
      root = lastClicked.findRootForGrab()
      if root?.layoutSpec?.isStackElementActive?()
        root.layoutSpec[@layoutAlignSetterMethod]()
