class EditableMarkWdgt extends UpperRightTriangleIconicButtonWdgt

  editObject: undefined
  editMethodAsString: ""

  constructor: (parent, @editObject, @editMethodAsString) ->
    super parent
    @toolTipMessage = "edit code for the tool"

  mouseClickLeft: ->
    @editObject[@editMethodAsString].call @editObject
