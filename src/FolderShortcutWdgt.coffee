class FolderShortcutWdgt extends ShortcutWdgt

  _acceptsDrops: true

  _reactToChildDropped: (droppedWidget) ->
    # a desktop icon (link) moves itself into the folder; anything else makes a reference there
    # (a filing). Either way the icon takes the folder's next free slot: a drop onto me brings no
    # place inside the folder.
    # The dropped widget decides via _reactToBeingDroppedIntoFolder instead of
    # `droppedWidget instanceof DesktopLinkWdgt`. (type-test-elimination campaign)
    if droppedWidget._reactToBeingDroppedIntoFolder?
      droppedWidget._reactToBeingDroppedIntoFolder @referencedWidget.contents.contents
    else
      # runs inside the drop's single settle -> the non-settling core
      droppedWidget._createReferenceAndCloseNoSettle @referencedWidget.contents.contents

  # my inner art (bare on the primary folder icon a makeFolder leaves behind, arrow'd on a
  # deliberate "create shortcut" alias -- the assembly lives in ShortcutWdgt's constructor)
  _defaultInnerIcon: ->
    new FolderIconWdgt

  # what a press on my tile does: open my folder (WidgetHolderWithCaptionWdgt.activated decides tile
  # or plate, and hands a tile press here)
  _activateMyTile: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    @bringUpReferencedWidget()

