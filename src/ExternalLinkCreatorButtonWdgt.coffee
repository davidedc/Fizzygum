# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class ExternalLinkCreatorButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new ExternalLinkIconAppearance @
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @setColor new Color 0, 0, 0
    @toolTipMessage = "link"

  grabbedWidgetSwitcheroo: ->
    switcheroo = new SimpleLinkWdgt()
    switcheroo.fullRawMoveTo @position()
    switcheroo.rawSetExtent new Point 330, 65
    return switcheroo

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

