# Opens / re-focuses the editor's "useful snippets" templates window.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class TemplatesButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  iconToolTipMessage: "useful snippets"

  createAppearance: -> new TemplatesIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

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
