# Shared behaviour of the three alignment buttons (left / center / right):
# align the last-clicked widget directly if it knows how, otherwise — if it is
# a vertical-stack element — set the alignment on its layout spec. Subclasses
# supply the two method names (and the icon + tooltip via the base).

class AlignButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  alignDirectMethod: nil        # e.g. "alignLeft"
  layoutAlignSetterMethod: nil  # e.g. "setAlignmentToLeft"

  mouseClickLeft: ->
    lastClicked = world.lastNonTextPropertyChangerButtonClickedOrDropped
    if lastClicked?[@alignDirectMethod]?
      lastClicked[@alignDirectMethod]()
    else if lastClicked?
      root = lastClicked.findRootForGrab()
      if root?.layoutSpec? and root.layoutSpec == LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT
        root.layoutSpecDetails[@layoutAlignSetterMethod]()
