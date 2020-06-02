class Grid3D

  @augmentWith DeepCopierMixin

  width: nil
  height: nil
  vertexIndexes: nil
   
  constructor: (@width, @height, @vertexIndexes = []) ->
