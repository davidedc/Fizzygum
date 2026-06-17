class CreatorButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name
  @augmentWith WidgetCreatorAndSmartPlacerOnClickMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.create 230, 230, 230

  actionableAsThumbnail: true
  editorContentPropertyChangerButton: true

  iconToolTipMessage: nil

  # subclasses supply createAppearance (the icon) + iconToolTipMessage (hover
  # text); the appearance is set here after super, as the original ctors did.
  constructor: ->
    super
    @appearance = @createAppearance()
    @toolTipMessage = @iconToolTipMessage

  grabbedWidgetSwitcheroo: ->
    return @createWidgetToBeHandled()

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

