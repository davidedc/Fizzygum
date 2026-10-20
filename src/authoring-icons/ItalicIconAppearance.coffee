# The ITALIC FACE: an "I" typed in the theme's italicToolFace role (Times New Roman italic, 20 in a
# tool cell). Worn by the text toolbar's italic tool (ItalicButtonWdgt) and its demo icon
# (ItalicIconWdgt). How a typed face sizes, centres and paints: TypedFaceIconAppearance.

class ItalicIconAppearance extends TypedFaceIconAppearance

  faceText: "I"

  _faceFontRole: ->
    WorldWdgt.theme.fonts.italicToolFace
