# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class USAMapCreatorButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new LittleUSAIconAppearance @
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @setColor new Color 0, 0, 0
    @toolTipMessage = "USA map"

  grabbedWidgetSwitcheroo: ->
    switcheroo = new SimpleUSAMapIconWdgt()
    switcheroo.rawSetExtent new Point 230, 145
    switcheroo.setColor new Color 183, 183, 183
    return switcheroo

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

