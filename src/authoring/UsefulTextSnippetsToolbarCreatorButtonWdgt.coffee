class UsefulTextSnippetsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Useful text snippets"

  # my face is the Templates GLYPH, drawn for the whole tool cell with its own white space -- the face
  # the text toolbar's TemplatesButtonWdgt wears, at the same size -- not a picture for the mark box
  drawsFaceInToolMarkBox: false

  createAppearance: -> new TemplatesIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    return TemplatesWindowWdgt.create()
