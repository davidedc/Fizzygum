# BackBufferValidityChecker //////////////////////////////////////////////////////////////

# REQUIRES DeepCopierMixin

class BackBufferValidityChecker
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

  extent: null
  font: null
  textAlign: null
  backgroundColor: null
  color: null
  textHash: null
  startMark: null
  endMark: null
  markedBackgoundColor: null

  isPassword: null
  isShowingBlanks: null

  fullBounds: null
