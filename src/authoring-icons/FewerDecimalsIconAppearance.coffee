# The FEWER-DECIMALS FACE: ".0" typed in the theme's decimalsToolFace role. Worn by the sheet toolbar's
# fewer-decimals tool (FewerDecimalsButtonWdgt). How a typed face sizes, centres and paints:
# TypedFaceIconAppearance.

class FewerDecimalsIconAppearance extends TypedFaceIconAppearance

  faceText: ".0"

  _faceFontRole: ->
    WorldWdgt.theme.fonts.decimalsToolFace
