# A TYPED FACE: an icon whose art is a short string -- a letter, a few characters -- typed from the
# glyph atlases in a theme font role, centred in its widget's box the way the design centres a line
# of text in a taller box. The text tools' B, I and </> are three of them (BoldIconAppearance,
# ItalicIconAppearance, FormatAsCodeIconAppearance): each subclass names its face, its text and its
# font role, and draws nothing of its own.
#
# HOW IT PAINTS -- in my widget's LOGICAL coordinates inside the standard scope
# (Appearance._paintInLocalScope), with no design-space scale and no device-pixel body: SWCanvas types
# a glyph crisply only under a uniform scale equal to its atlas density with an integer translate,
# which is exactly that scope (a widget's position is whole pixels). Under the legacy icon transform
# the glyph would be resampled, and in a size-aware device-pixel body a density-2 glyph would come out
# half size.
#   SIZE: the role states its size in a tool cell (the theme's toolThumbnailSize); in a box `side` px
# square the face is that size scaled with the box, snapped to the half-pixel steps the atlases come
# in and kept within the sizes they carry, so the two backends type the same size (_faceFontSizeIn).
#   CENTRING: across, by ADVANCE -- textAlign "center" at the middle of my widget's box; down, the
# design's "line centred in a taller box" rule, baseline = round((boxHeight - (A + D)) / 2) + A, A and
# D the font box's ascent and descent rounded to whole pixels (StringWdgt.fontBoxAscentAndDescentOf,
# the one measure and cache the line box uses too).
#   INK: my own colour if I was given one (a toolbar's glyph role), else my widget's colour, read at
# every paint like every icon's (IconAppearance._iconColorString).
#   THE SHADOW PASS paints the same text in the shadow colour at the shadow's alpha: the face is ONE
# fill, so its silhouette is its ink.
#   MY SHAPE is my widget's whole box (the base answer): a press between the strokes of a letter still
# lands on my widget, so a face never punches a hole in the cell it stands in. I claim no opaque cover.
#   A COLD ATLAS: until a face's atlas has loaded, SWCanvas types placeholder boxes. The paint loop
# names the widget being painted (world.paintingWidget), the fillText seam records it as a cold
# drawer, and once the atlas arrives the world repaints exactly that widget (noteColdGlyphRegionsWarm),
# while world.anyTextDirty() holds every screenshot gate shut (SWCanvasElement-extensions). My widget
# is that painting widget, so my face is retyped when its atlas lands.

class TypedFaceIconAppearance extends IconAppearance

  # the string my face types (a subclass names it)
  faceText: ""

  # the theme font role my face is typed in, {family, size, bold, italic}, its size stated at a tool
  # cell's side. Read at every paint, so a world restored from a snapshot wears the look of the page
  # that loads it. (subclass responsibility)
  _faceFontRole: ->

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      role = @_faceFontRole()
      font = @_faceFont role, (@_faceFontSizeIn @_faceSide(), role)
      [ascent, descent] = StringWdgt.fontBoxAscentAndDescentOf font
      ctx.font = font
      ctx.textAlign = "center"
      ctx.textBaseline = "alphabetic"
      ctx.fillStyle = if appliedShadow? then WorldWdgt.theme.shadowColor.toString() else @_iconColorString()
      # art geometry from my widget's box (origin 0, 0), never from the damage box: the scope clips
      baseline = Math.round((@widget.height() - (ascent + descent)) / 2) + ascent
      ctx.fillText @faceText, @widget.width() / 2, baseline
      return
    return undefined

  # The side of the square my face is sized by: my widget's box, or the glyph square it names where
  # that is smaller (the rule IconAppearance.calculateRectangleOfIcon fits a legacy glyph by).
  _faceSide: ->
    side = Math.min @widget.width(), @widget.height()
    side = Math.min side, @widget.glyphSize if @widget.glyphSize?
    side

  # The size my face is typed at in a box `side` px square: the role's size scaled from a tool cell's
  # side to `side`, snapped to the atlases' half-pixel steps and clamped to the sizes they carry.
  # SWCanvas would snap and clamp it itself; the native canvas would not, and the two backends must
  # type the same face.
  _faceFontSizeIn: (side, role) ->
    size = Math.round(role.size * side / WorldWdgt.theme.toolThumbnailSize * 2) / 2
    Math.min window.SWCANVAS_MAX_FONT_SIZE, Math.max window.SWCANVAS_MIN_FONT_SIZE, size

  # the canvas font string for `role` at `fontSize`, in the shape StringWdgt.buildCanvasFontProperty
  # spells ("bold italic 20px <family>"), which SWCanvas's font mapper parses
  _faceFont: (role, fontSize) ->
    font = ""
    font += "bold " if role.bold
    font += "italic " if role.italic
    font + fontSize + "px " + role.family

  # A PICTURE OF MY FACE THAT STAYS LIVE, for a widget that shows what my widget looks like
  # (InertIconHolderWdgt: a toolbar overflow menu's row picture): my own kind of face, worn by that
  # widget, in my ink. A raster taken once cannot be that picture: a face typed while its atlas is
  # still loading is typed in placeholder boxes, and only a face that is typed again when the atlas
  # lands -- the holder's own, recorded as the holder's cold draw -- shows the glyph.
  livePictureOn: (aWidget) ->
    new @constructor aWidget, (@ownColorInsteadOfWidgetColor ? @widget.color)
