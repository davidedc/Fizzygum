# EditableMarkMorph ////////////////////////////////////////////////////////

class EditableMarkMorph extends UpperRightTriangleAnnotation

  editObject: nil
  editMethodAsString: ""

  constructor: (parent = nil, @editObject, @editMethodAsString) ->
    super parent

  mouseClickLeft: ->
    @editObject[@editMethodAsString].call @editObject
