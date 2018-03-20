# this file is excluded from the fizzygum homepage build

# REQUIRES DeepCopierMixin
# REQUIRES PinType


class Pin

  @augmentWith DeepCopierMixin

  type: PinType.INPUT
  pinname: ""
  
  # A Pin usually has only ingoing links or
  # outgoing links, but "bridge" pins can have
  # both. Bridge Pins are pins that bridge
  # input/output pins from a container into
  # input/output (respectively) pins of content
  # inside it.
  ingoingLinks: []
  outgoingLinks: []
  
  # the order of output pins matters
  # as, when the node fires multiple outputs,
  # they fire right-to left.
  orderNumber: 0

  isBridge: false
  isTrigger: false
