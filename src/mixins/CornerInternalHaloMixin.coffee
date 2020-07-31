CornerInternalHaloMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      # floatDragging and dropping:
      isLockingToPanels: false

      layoutSpec_cornerInternal_proportionOfParent: 4/8
      layoutSpec_cornerInternal_fixedSize: 0
