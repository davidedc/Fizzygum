class EditableMarkMorph extends UpperRightTriangleIconicButton

  editObject: nil
  editMethodAsString: ""

  constructor: (parent = nil, @editObject, @editMethodAsString) ->
    super parent
    @toolTipMessage = "edit code for the tool"

  mouseClickLeft: ->
    @editObject[@editMethodAsString].call @editObject
