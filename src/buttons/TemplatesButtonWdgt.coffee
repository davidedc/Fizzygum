class TemplatesButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new TemplatesIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor

    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "useful snippets"

  bringTemplatesWindowIntoView: ->
    world.simpleEditorTemplates.bringToForeground()
    world.simpleEditorTemplates.fullRawMoveTo world.hand.position().subtract new Point 50, 50
    world.simpleEditorTemplates.fullRawMoveWithin world

  mouseClickLeft: ->
    if world.simpleEditorTemplates?
      if world.simpleEditorTemplates.destroyed or !world.simpleEditorTemplates.parent?
        templatesWindow = menusHelper.createNewTemplatesWindow()
        @positionTemplatesWindowAndRegisterIt templatesWindow
      else if world.simpleEditorTemplates.parent? and world.simpleEditorTemplates.parent == world.basementWdgt.scrollPanel.contents
        world.add world.simpleEditorTemplates
        @bringTemplatesWindowIntoView()
      else if !world.simpleEditorTemplates.destroyed and world.simpleEditorTemplates.parent == world
        @bringTemplatesWindowIntoView()
    else
      templatesWindow = menusHelper.createNewTemplatesWindow()
      @positionTemplatesWindowAndRegisterIt templatesWindow

  positionTemplatesWindowAndRegisterIt: (templatesWindow) ->
    templatesWindow.fullRawMoveTo world.hand.position().subtract new Point 50, 50
    templatesWindow.fullRawMoveWithin world
    world.add templatesWindow
    world.simpleEditorTemplates = templatesWindow


