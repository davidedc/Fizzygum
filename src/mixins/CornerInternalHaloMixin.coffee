CornerInternalHaloMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      # floatDragging and dropping:
      isLockingToPanels: false

      proportionOfParent: 4/8
      fixedSize: 0
