# This is an icon, with a caption below, AND it has some logic
# to be shown "in its own layer" together with the
# other desktop system links. I.e. you never see a desktop system link
# on top of a window (unless during a drag), so in that sense
# the desktop system links live in their own "layer"

class IconicDesktopSystemLinkWdgt extends WidgetHolderWithCaptionWdgt

  moveOnTopOfTopReference: ->
    # find the topmost OTHER desktop icon to layer myself just above it
    # (was `c instanceof WidgetHolderWithCaptionWdgt`). (type-test-elimination campaign)
    topMostReference = @parent.topmostChildSuchThat (c) =>
      c != @ and c.isDesktopIcon?()
    if topMostReference?
      @parent.children.remove @
      index = @parent.children.indexOf topMostReference
      @parent.children.splice (index + 1), 0, @
    else
      @parent.children.remove @
      @parent.children.unshift @

  # When dropped into a folder I move directly into its contents (I am a desktop icon),
  # rather than the default "create a reference". IconicDesktopSystemFolderShortcutWdgt
  # keys its drop off this instead of `instanceof IconicDesktopSystemLinkWdgt`.
  # (type-test-elimination campaign)
  # Only called from IconicDesktopSystemFolderShortcutWdgt._reactToChildDropped, inside the drop's single
  # settle, so add through the non-settling core.
  addSelfWhenDroppedIntoFolder: (folderContents) ->
    folderContents._addNoSettle @

