class CreatorButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name
  @augmentWith WidgetCreatorAndSmartPlacerOnClickMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.create 230, 230, 230

  constructor: ->
    super
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true

  grabbedWidgetSwitcheroo: ->
    return @createWidgetToBeHandled()

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

