# Shared behaviour of the three alignment buttons (left / center / right):
# align the last-clicked widget directly if it knows how, otherwise — if it is
# a vertical-stack element — set the alignment on its layout spec. Subclasses
# supply the two method names and the alignment they set (and the icon + tooltip
# via the base). A button shows active while the text it aligns directly has its
# alignment (the family's mirror of the edited text); the layout-spec branch is
# not mirrored.

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
    lastClicked = world.editorFocusWdgt
    if subject?[@alignDirectMethod]?
      subject[@alignDirectMethod]()
    else if lastClicked?
      root = lastClicked.findRootForGrab()
      if root?.layoutSpec?.isStackElementActive?()
        root.layoutSpec[@layoutAlignSetterMethod]()
