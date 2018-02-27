# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class BoldButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new BoldIconAppearance @
    @actionableAsThumbnail = true
    @textPropertyChangerButton = true
    @setColor new Color 0, 0, 0

  mouseClickLeft: ->
    debugger
    if world.caret?
      world.caret.target.toggleWeight?()
