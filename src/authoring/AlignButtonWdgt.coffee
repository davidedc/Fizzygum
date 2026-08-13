# Shared behaviour of the three alignment buttons (left / center / right):
# align the last-clicked widget directly if it knows how, otherwise — if it is
# a vertical-stack element — set the alignment on its layout spec. Subclasses
# supply the two method names (and the icon + tooltip via the base).

class AlignButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  alignDirectMethod: undefined        # e.g. "alignLeft"
  layoutAlignSetterMethod: undefined  # e.g. "setAlignmentToLeft"

  mouseClickLeft: ->
    lastClicked = world.editorFocusWdgt
    if lastClicked?[@alignDirectMethod]?
      lastClicked[@alignDirectMethod]()
    else if lastClicked?
      root = lastClicked.findRootForGrab()
      if root?.layoutSpec?.isStackElementActive?()
        root.layoutSpec[@layoutAlignSetterMethod]()
