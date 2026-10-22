# The CODE FACE: "</>" typed in the theme's codeToolFace role (Courier New, 15 in a tool cell). Worn
# by the text toolbar's format-as-code tool (FormatAsCodeButtonWdgt) and its demo icon
# (FormatAsCodeIconWdgt). How a typed face sizes, centres and paints: TypedFaceIconAppearance.

class FormatAsCodeIconAppearance extends TypedFaceIconAppearance

  faceText: "</>"

  _faceFontRole: ->
    WorldWdgt.theme.fonts.codeToolFace
