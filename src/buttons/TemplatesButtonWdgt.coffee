# Opens / re-focuses the editor's "useful snippets" templates window.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class TemplatesButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  iconToolTipMessage: "useful snippets"

  createAppearance: -> new TemplatesIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  bringTemplatesWindowIntoView: ->
    world.simpleEditorTemplates.bringToForeground()
    world.simpleEditorTemplates._applyMoveTo world.hand.position().subtract new Point 50, 50
    world.simpleEditorTemplates._moveWithin world

  mouseClickLeft: ->
    if world.simpleEditorTemplates?
      if world.simpleEditorTemplates.destroyed or !world.simpleEditorTemplates.parent?
        templatesWindow = TemplatesWindowWdgt.create()
        @positionTemplatesWindowAndRegisterIt templatesWindow
      else if world.binWdgt.holds world.simpleEditorTemplates
        # the bin view shows LOST items only, so a parked (reachable)
        # resident like this window is hidden -- un-hide on the way out
        world.simpleEditorTemplates.show()
        world.add world.simpleEditorTemplates
        @bringTemplatesWindowIntoView()
      else if !world.simpleEditorTemplates.destroyed and world.simpleEditorTemplates.parent == world
        @bringTemplatesWindowIntoView()
    else
      templatesWindow = TemplatesWindowWdgt.create()
      @positionTemplatesWindowAndRegisterIt templatesWindow

  positionTemplatesWindowAndRegisterIt: (templatesWindow) ->
    templatesWindow._applyMoveTo world.hand.position().subtract new Point 50, 50
    templatesWindow._moveWithin world
    world.add templatesWindow
    world.simpleEditorTemplates = templatesWindow
