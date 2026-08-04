# IMMUTABLE — fields are set at construction and never written again; the index
# array is built BEFORE construction (see docs/architecture/immutable-value-classes.md).

class Grid3D

  width: nil
  height: nil
  vertexIndexes: nil
   
  constructor: (@width, @height, @vertexIndexes = []) ->
