# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class ToolbarCreatorButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true

  mouseClickLeft: ->
    windowToBePlaced = @grabbedWidgetSwitcheroo()
    windowToBePlaced.fullRawMoveTo @topRight().add new Point 20,-40
    world.add windowToBePlaced

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

