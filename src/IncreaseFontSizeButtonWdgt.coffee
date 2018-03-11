# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class IncreaseFontSizeButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new IncreaseFontSizeIconAppearance @
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @setColor new Color 0, 0, 0
    @hint = "increase font size"

  mouseClickLeft: ->
    debugger
    if world.caret?
      if world.caret.target.originallySetFontSize < 12
        world.caret.target.setFontSize world.caret.target.originallySetFontSize + 1
      else if world.caret.target.originallySetFontSize < 28
        world.caret.target.setFontSize world.caret.target.originallySetFontSize + 2
      else if world.caret.target.originallySetFontSize < 36
        world.caret.target.setFontSize 36
      else if world.caret.target.originallySetFontSize < 48
        world.caret.target.setFontSize 48
      else if world.caret.target.originallySetFontSize < 72
        world.caret.target.setFontSize 72
      else if world.caret.target.originallySetFontSize < 80
        world.caret.target.setFontSize 80
      else
        world.caret.target.setFontSize world.caret.target.originallySetFontSize + 10



