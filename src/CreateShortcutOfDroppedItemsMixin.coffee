# REQUIRES globalFunctions


CreateShortcutOfDroppedItemsMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      reactToDropOf: (droppedWidget) ->
        super
        debugger
        if !(droppedWidget instanceof IconicDesktopSystemShortcutWdgt)
          droppedWidget.createReferenceAndClose nil, nil, @
