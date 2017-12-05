# EditableMarkMorph ////////////////////////////////////////////////////////

class EditableMarkMorph extends UpperRightTriangleAnnotation
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  editObject: nil
  editMethodAsString: ""

  constructor: (parent = nil, @editObject, @editMethodAsString) ->
    super parent

  mouseClickLeft: ->
    @editObject[@editMethodAsString].call @editObject
