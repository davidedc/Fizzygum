# keeps folders and shortcuts and scripts in
# the background in respect to other windows
# and widgets

KeepIconicDesktopSystemLinksBackMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      # only a desktop link knows how to layer itself above the other references; non-links
      # have no moveOnTopOfTopReference, so `?()` fires for exactly the old
      # `instanceof IconicDesktopSystemLinkWdgt`. (type-test-elimination campaign)
      _reactToChildAdded: (theWidget) ->
        theWidget.moveOnTopOfTopReference?()

      _reactToChildMovedToFront: (theWidget) ->
        theWidget.moveOnTopOfTopReference?()
