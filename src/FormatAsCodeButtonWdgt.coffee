# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class FormatAsCodeButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new FormatAsCodeIconAppearance @
    @actionableAsThumbnail = true
    @textPropertyChangerButton = true
    @setColor new Color 0, 0, 0

  mouseClickLeft: ->
    debugger
    if world.caret?
      if world.caret.target.fontName != world.caret.target.monoFontStack
        world.caret.target.setFontName nil, nil, world.caret.target.monoFontStack
      else
        world.caret.target.setFontName nil, nil, world.caret.target.justArialFontStack

