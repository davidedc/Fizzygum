# A FRAME's resize GRIP: the corner resizer a window carries (FrameWdgt builds one; a frame whose
# manifestation offers no resizer, a pop-up, carries none). It is a corner HandleWdgt in every
# gesture -- it attaches, shows and hides, and resizes its frame exactly as the halo's corner resizer
# resizes its widget -- and differs only in how it looks, how big it is, where it sits and where it
# reacts:
#   - it wears the draft's grip glyph (GripIconAppearance: three diagonal strokes) in its own ink
#     role, frameGripInk, and has no hover look: the glyph ignores the highlight state HandleWdgt
#     keeps;
#   - it is frameGripSize square, and sits frameGripInset in from the corner of its frame's CONTENT
#     area, i.e. past the frame's border, whatever margin the frame's payload asks for;
#   - a press anywhere in its square takes it, because the glyph appearance answers its whole box
#     (Appearance.shapeContainsPoint). The grip is drawn large precisely because its hit area cannot
#     reach past the frame's border, so the square it is drawn in is the target.
# A halo's handles, a naked inspector's resizer and the demo handles stay plain HandleWdgts.

class FrameGripWdgt extends HandleWdgt

  # HOW FAR INTO ITS FRAME'S CORNER A GRIP REACHES along each axis, measured from the corner of the
  # frame's content area: its inset plus its side. A payload that keeps clear of the grip
  # (FrameWdgt._chromeHeight) and a viewport whose bars run out to that corner
  # (ViewportWdgt._cornerReserveFor, through cornerFootprint) both leave this much free. Asked of
  # the class, because a frame measures its chrome before its grip exists, and whether or not it
  # has one.
  @footprint: ->
    WorldWdgt.theme.frameGripInset + WorldWdgt.theme.frameGripSize

  constructor: ->
    super "resizeBothDimensionsHandle"
    @color = WorldWdgt.theme.frameGripInk

  createAppearance: -> new GripIconAppearance @

  _cornerSide: -> WorldWdgt.theme.frameGripSize

  # the frame's border, then the grip's own inset from the content area inside it -- read from the
  # theme, never from the frame's padding, which is its payload's business
  _cornerInsetFrom: ->
    inset = WorldWdgt.theme.frameBorderWidth + WorldWdgt.theme.frameGripInset
    new Point inset, inset

  # measured from the content area's corner, which is where a payload flush inside my frame's
  # border has its own
  cornerFootprint: -> FrameGripWdgt.footprint()
