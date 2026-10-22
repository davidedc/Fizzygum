# The BOLD FACE: a "B" typed in the theme's boldToolFace role (Times New Roman bold, 20 in a tool
# cell). Worn by the text toolbar's bold tool (BoldButtonWdgt) and its demo icon (BoldIconWdgt). How
# a typed face sizes, centres and paints: TypedFaceIconAppearance.

class BoldIconAppearance extends TypedFaceIconAppearance

  faceText: "B"

  _faceFontRole: ->
    WorldWdgt.theme.fonts.boldToolFace
