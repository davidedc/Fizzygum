# This is an icon, with a caption below, AND it has some logic
# to be shown "in its own layer" together with the
# other desktop system links. I.e. you never see a desktop system link
# on top of a window (unless during a drag), so in that sense
# the desktop system links live in their own "layer"

class DesktopLinkWdgt extends WidgetHolderWithCaptionWdgt

  @augmentWith HighlightableMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.BLACK

  # the link's caption text. Declared HERE rather than on ShortcutWdgt
  # because AppLauncherWdgt is a sibling of that class, not a
  # subclass — this is the tightest base that covers all five writers.
  title: undefined

  moveOnTopOfTopReference: ->
    # find the topmost OTHER desktop icon to layer myself just above it
    # (instead of `c instanceof WidgetHolderWithCaptionWdgt`; type-test-elimination campaign)
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
  # rather than the default "create a reference". FolderShortcutWdgt
  # keys its drop off this instead of `instanceof DesktopLinkWdgt`.
  # (type-test-elimination campaign)
  # Only called from FolderShortcutWdgt._reactToChildDropped, inside the drop's single
  # settle, so add through the non-settling core.
  _reactToBeingDroppedIntoFolder: (folderContents) ->
    folderContents._addNoSettle @

