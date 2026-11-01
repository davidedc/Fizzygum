# A FRAME's resize GRIP: the corner resizer a window carries (FrameWdgt builds one; a frame whose
# manifestation offers no resizer, a pop-up, carries none). It is a corner HandleWdgt in every
# gesture -- it attaches, shows and hides, and resizes its frame exactly as the halo's corner resizer
# resizes its widget -- and differs only in how it looks, how big it is, where it sits, where it
# reacts and the shadow it casts:
#   - it wears the draft's grip glyph (GripIconAppearance: three diagonal strokes) in its own ink, and
#     shows what it is about to do: while the pointer rests on it or a press on it stands, its strokes
#     darken, the cursor is the resize cursor and the frame it would resize is outlined. A finger
#     never rests, so a finger is shown this while its press stands and not on its way past;
#   - it is frameGripSize square, and sits frameGripInset in from the corner of its frame's CONTENT
#     area, i.e. past the frame's border, inside the GRIP STRIP the frame keeps for it
#     (FrameWdgt._gripStripThickness). The strip is why no grip lies over its frame's content, or over
#     the grip of a window nested in that frame: each grip is pressed on its own window's strip;
#   - a press anywhere in its square takes it, because the glyph appearance answers its whole box
#     (Appearance.shapeContainsPoint). The grip is drawn large precisely because its hit area cannot
#     reach past the frame's border, so the square it is drawn in is the target;
#   - it casts no shadow of its own: its strokes stand on its frame's body, inside the frame's own
#     shadow, so the add's shadow management (Widget._addNoSettle) is all it gets.
# A halo's handles, a naked inspector's resizer and the demo handles stay plain HandleWdgts, on a plate
# that casts the desktop shadow (HandleAppearance, HandleWdgt._castMyShadow).

class FrameGripWdgt extends HandleWdgt

  # is my active look up? (see _showActiveLook.) Derived from my pointer state, which does not survive
  # a save or a copy either, so a restored grip starts at rest.
  @serializationTransients: ["_activeLookShowing"]
  _activeLookShowing: false

  constructor: ->
    super "resizeBothDimensionsHandle"

  createAppearance: -> new GripIconAppearance @

  # no shadow of my own (see above): a plain handle's plate casts one, my strokes do not
  _castMyShadow: ->

  _cornerSide: -> WorldWdgt.theme.frameGripSize

  # the frame's border, then the grip's own inset from the content area inside it -- read from the
  # theme, never from the frame's padding, which is its payload's business
  _cornerInsetFrom: ->
    inset = WorldWdgt.theme.frameBorderWidth + WorldWdgt.theme.frameGripInset
    new Point inset, inset

  # my strokes' ink, which my appearance reads as it paints
  _gripInk: ->
    if @_activeLookShowing then WorldWdgt.theme.frameGripActiveInk else WorldWdgt.theme.frameGripInk

  # Beyond what any handle does as it comes or goes: my frame's body gives up or takes back the strip I
  # lie in (it answers the same question I do, HandleWdgt.wouldShow), and a grip that is gone shows
  # nobody what it would do.
  updateVisibility: ->
    showedBefore = @isVisible
    super
    return if @isVisible is showedBefore
    @_setPointerState false, false unless @isVisible
    @parent?.noteMyGripCameOrWent?()

  _setPointerState: (hovered, pressed) ->
    super
    @_showActiveLook @_isPressed or (@_isHovered and world.hand.pointerCanRest())

  # Everything I show while the pointer is on me or a press on me stands, as one change: my ink, the
  # resize cursor, and the outline around the frame that would resize (the highlight channel: the
  # world's reconciler keeps it on the frame as the frame's box changes under the drag).
  _showActiveLook: (active) ->
    return if active is @_activeLookShowing
    @_activeLookShowing = active
    world.worldCanvas.style.cursor = if active then 'nwse-resize' else ''
    if active and @target?
      world.widgetsToBeHighlighted.set @target, HighlighterWdgt.resizeTargetOutlineStyle()
    else if @target?
      world.widgetsToBeHighlighted.delete @target
    @_changed()

  # the outline and the cursor are world state that names me, and neither may outlive me
  _destroyNoSettle: ->
    @_showActiveLook false
    super
