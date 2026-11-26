# THE EDIT MARK: the triangle a widget wears in its top-right corner (UpperRightTriangleIconicButtonWdgt:
# its look), which opens the inspector on the code the widget I mark says a person edits of it
# (_memberToEdit, asked at my press, never stored). My press is the widget's "Edit code" menu row
# (Widget.inspectMemberToEdit): one action, two ways to it, so a finger has the row and a mouse the mark.
# I mark my parent: the widget I stand in the corner of (UpperRightTriangleWdgt adds me there).
class EditableMarkWdgt extends UpperRightTriangleIconicButtonWdgt

  constructor: (parent) ->
    super parent
    @toolTipMessage = "edit this code\nin an inspector"

  activated: ->
    @parent?.inspectMemberToEdit()
