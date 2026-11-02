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
#     shadow, so the add's shadow management (Widget._addNoSettle) is all it gets;
#   - on a COLLAPSED frame there is no strip, and it stands on the frame's title bar instead, at the same
#     place relative to the corner, while the bar has room for it beside its pieces
#     (FrameWdgt.offersAResizeHandle). There it wears the bar's glyph inks and sizes the bar's own width
#     (FrameWdgt.barsOwnWidth), leaving the width the window comes back at alone, and stops at the
#     narrowest bar that keeps it (FrameWdgt.shortestBarKeepingMyGrip). A press that does not travel is
#     a tap on the bar, which expands the frame (ruling C17), so the grip takes nothing from the bar's tap.
# A halo's handles, a naked inspector's resizer and the demo handles stay plain HandleWdgts, on a plate
# that casts the desktop shadow (HandleAppearance, HandleWdgt._castMyShadow).

class FrameGripWdgt extends HandleWdgt

  # is my active look up? (see _showActiveLook.) Derived from my pointer state, which does not survive
  # a save or a copy either, so a restored grip starts at rest.
  @serializationTransients: ["_activeLookShowing", "_tapPressOrigin"]
  _activeLookShowing: false

  # where a press on me began while my frame was collapsed, for as long as that press can still be a
  # tap on the bar: pressBegan sets it, and travelling the grab threshold clears it (nonFloatDragging).
  _tapPressOrigin: undefined

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

  # how far along my frame's bottom edge I reach from its corner: my inset, then my side
  reachFromMyFramesCorner: ->
    @_cornerInsetFrom().x + @_cornerSide()

  _standsOnACollapsedBar: ->
    !!@target?.contents?.collapsed

  # my strokes' ink, which my appearance reads as it paints. On a collapsed bar it is the ink of the
  # bar's own glyphs, because the bar's fill follows focus and the grip strip's does not. A focus flip
  # repaints the bar's background, and so whatever stands on it, me included.
  _gripInk: ->
    if @_standsOnACollapsedBar()
      bar = @target.bar
      return if @_activeLookShowing then bar.activeGlyphInk else bar.glyphInk
    if @_activeLookShowing then WorldWdgt.theme.frameGripActiveInk else WorldWdgt.theme.frameGripInk

  # A press on a collapsed bar's grip might still be the bar's tap (see activated), so note where it began
  pressBegan: (pos) ->
    @_tapPressOrigin = if @_standsOnACollapsedBar() then pos else undefined
    super

  # On a collapsed bar the press takes hold of me only once it travels as far as a press on the bar must
  # to take hold of the bar, the same threshold, so a trembling tap neither resizes the bar nor stops
  # being a tap. After that I track the pointer: the grab offset the drag measures from was taken
  # before I started following it, so I catch up with it at once. An expanded frame's grip tracks from
  # the first pixel, as every handle does.
  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->
    if @_tapPressOrigin?
      travelled = (@screenPointToMyPlane pos).distanceTo @_tapPressOrigin
      return if travelled < WorldWdgt.preferencesAndSettings.grabDragThreshold
      @_tapPressOrigin = undefined
    super

  # On a collapsed bar a drag stops at the narrowest width that keeps me on it. The pointer can overshoot
  # that and come back: the drag re-derives from the pointer each time, so I rejoin it where it rejoins
  # me. (The height is the frame's to refuse: FrameWdgt._noteAWidthAskedOfMyBar.) An expanded frame takes
  # what the pointer asks.
  _extentMyDragAsksOfMyTarget: (anExtent) ->
    return anExtent unless @_standsOnACollapsedBar()
    new Point (Math.max anExtent.x, @target.shortestBarKeepingMyGrip()), anExtent.y

  # A collapsed bar expands on a tap anywhere on it (ruling C17), and I am on it. Reached only by a press
  # that began on me and released on me, and the hand sends that here after a drag as well, which is
  # why it asks whether the press is still a tap.
  activated: ->
    return unless @_tapPressOrigin?
    @_tapPressOrigin = undefined
    @target.bar.expandFromATapOnMyStrip()

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
  # resize cursor (a collapsed bar sizes across only, and the cursor says so), and the outline around
  # the frame that would resize (the highlight channel: the world's reconciler keeps it on the frame as
  # the frame's box changes under the drag).
  _showActiveLook: (active) ->
    return if active is @_activeLookShowing
    @_activeLookShowing = active
    world.worldCanvas.style.cursor = if !active then '' else if @_standsOnACollapsedBar() then 'ew-resize' else 'nwse-resize'
    if active and @target?
      world.widgetsToBeHighlighted.set @target, HighlighterWdgt.resizeTargetOutlineStyle()
    else if @target?
      world.widgetsToBeHighlighted.delete @target
    @_changed()

  # the outline and the cursor are world state that names me, and neither may outlive me
  _destroyNoSettle: ->
    @_showActiveLook false
    super
