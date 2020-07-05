class AlignLeftButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.create 230, 230, 230

  constructor: (@color) ->
    super
    @appearance = new AlignLeftIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "align left"

  mouseClickLeft: ->
    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.alignLeft?
      world.lastNonTextPropertyChangerButtonClickedOrDropped.alignLeft()
    else if world.lastNonTextPropertyChangerButtonClickedOrDropped?
      lastNonTextPropertyChangerButtonClickedOrDropped = world.lastNonTextPropertyChangerButtonClickedOrDropped.findRootForGrab()
      if lastNonTextPropertyChangerButtonClickedOrDropped?.layoutSpec? and
       lastNonTextPropertyChangerButtonClickedOrDropped.layoutSpec == LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT
        lastNonTextPropertyChangerButtonClickedOrDropped.layoutSpecDetails.setAlignmentToLeft()


