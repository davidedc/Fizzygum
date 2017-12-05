# ShadowInfo /////////////////////////////////////////////////////////

# REQUIRES DeepCopierMixin

class ShadowInfo
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

  offset: nil
  alpha: 0

  # alpha should be between zero (transparent)
  # and one (fully opaque)
  constructor: (@offset = new Point(7, 7), @alpha = 0.2) ->
    @offset.debugIfFloats()

