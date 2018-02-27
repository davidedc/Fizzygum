# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class AlignCenterButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: (@color) ->
    super
    @appearance = new AlignCenterIconAppearance @
    @actionableAsThumbnail = true
    @textPropertyChangerButton = true

  mouseClickLeft: ->
    debugger
    if world.caret?
      world.caret.target.alignCenter?()


