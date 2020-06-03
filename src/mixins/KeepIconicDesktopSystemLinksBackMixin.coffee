# keeps folders and shortcuts and scripts in
# the background in respect to other windows
# and widgets

KeepIconicDesktopSystemLinksBackMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      childAdded: (theWidget) ->
        if theWidget instanceof IconicDesktopSystemLinkWdgt
          theWidget.moveOnTopOfTopReference()

      childMovedInFrontOfOthers: (theWidget) ->
        if theWidget instanceof IconicDesktopSystemLinkWdgt
          theWidget.moveOnTopOfTopReference()
