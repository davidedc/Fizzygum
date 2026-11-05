# Opens / re-focuses the editor's "useful snippets" templates window -- the one window of
# TemplatesApp, which keeps it in world.appWindows (see there).
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class TemplatesButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "useful snippets"

  createAppearance: -> new TemplatesIconAppearance @, WorldWdgt.theme.toolbarGlyph

  activated: ->
    (new TemplatesApp).launch()
