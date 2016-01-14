# Pin //////////////////////////////////////////////////////////

# REQUIRES DeepCopierMixin
# REQUIRES PinType


class Pin
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

  type: PinType.INPUT
  pinname: ""
  inLinks: []
  outgoingLinks: []
  orderNumber: 0
