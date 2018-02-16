# EditableMarkMorph ////////////////////////////////////////////////////////

class EditableMarkMorph extends UpperRightTriangleIconicButton

  editObject: nil
  editMethodAsString: ""

  constructor: (parent = nil, @editObject, @editMethodAsString) ->
    super parent

  mouseClickLeft: ->
    @editObject[@editMethodAsString].call @editObject
