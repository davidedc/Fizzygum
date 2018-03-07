# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class TemplatesButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new TemplatesIconAppearance @

    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @setColor new Color 0, 0, 0

  createNewTemplatesWindow: ->
    sdspw = new SimpleDocumentScrollPanelWdgt()
    wm = new WindowWdgt nil, nil, sdspw
    wm.setExtent new Point 365, 335
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 50
    wm.fullRawMoveWithin world
    world.add wm
    wm.setTitleWithoutPrependedContentName "templates"
    wm.changed()

    world.simpleEditorTemplates = wm

  bringTemplatesWindowIntoView: ->
    world.simpleEditorTemplates.bringToForeground()
    world.simpleEditorTemplates.fullRawMoveTo world.hand.position().subtract new Point 50, 50
    world.simpleEditorTemplates.fullRawMoveWithin world

  mouseClickLeft: ->
    if world.simpleEditorTemplates?
      if world.simpleEditorTemplates.destroyed or !world.simpleEditorTemplates.parent?
        @createNewTemplatesWindow()
      else if world.simpleEditorTemplates.parent? and world.simpleEditorTemplates.parent == world.basementWdgt.scrollPanel.contents
        world.add world.simpleEditorTemplates
        @bringTemplatesWindowIntoView()
      else if !world.simpleEditorTemplates.destroyed and world.simpleEditorTemplates.parent == world
        @bringTemplatesWindowIntoView()
    else
      @createNewTemplatesWindow()


