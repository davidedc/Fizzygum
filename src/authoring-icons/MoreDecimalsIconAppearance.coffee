# The MORE-DECIMALS FACE: ".00" typed in the theme's decimalsToolFace role. Worn by the sheet toolbar's
# more-decimals tool (MoreDecimalsButtonWdgt). How a typed face sizes, centres and paints:
# TypedFaceIconAppearance.

class MoreDecimalsIconAppearance extends TypedFaceIconAppearance

  faceText: ".00"

  _faceFontRole: ->
    WorldWdgt.theme.fonts.decimalsToolFace
