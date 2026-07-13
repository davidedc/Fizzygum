class IconicDesktopSystemFolderShortcutWdgt extends IconicDesktopSystemShortcutWdgt

  _acceptsDrops: true

  _reactToChildDropped: (droppedWidget) ->
    # a desktop icon (link) moves itself into the folder; anything else makes a reference.
    # The dropped widget decides via _reactToBeingDroppedIntoFolder instead of
    # `droppedWidget instanceof IconicDesktopSystemLinkWdgt`. (type-test-elimination campaign)
    if droppedWidget._reactToBeingDroppedIntoFolder?
      droppedWidget._reactToBeingDroppedIntoFolder @target.contents.contents
    else
      # runs inside the drop's single settle -> the non-settling core
      droppedWidget._createReferenceAndCloseNoSettle nil, @target.contents.contents

  constructor: (@target, @title) ->
    super @target, @title, new GenericShortcutIconWdgt new FolderIconWdgt

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    @bringUpTarget()

