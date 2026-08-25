# A PICTURE of a widget, taken once and kept as pixels. I show what a command's tool looks like --
# a menu row places me as its glyph (MenuItemWdgt._placeMyIcon) -- and I am a picture in the
# literal sense: I hold a raster, not the widget it was taken from, and I have no children at all.
#
# WHY A RASTER AND NOT THE WIDGET: an icon derived from a live thing IS that thing. A copy of a
# tool is a button, and a button under a pointer behaves like a button -- it highlights, it
# presses, it triggers -- so a row showing one would carry a second, smaller target inside itself.
# Holding the widget and declaring myself pointer-transparent does NOT fix that, and the reason is
# structural: TreeNode.topWdgtSuchThat descends into CHILDREN FIRST and returns the first widget
# that answers, consulting a parent only after its whole subtree has declined. Every conjunct of
# Widget.isPointerTargetAt is a per-widget read except isInCollapsedSubtree. So a held child is
# always asked, whatever its holder says, and it was measured being asked -- it took the tap
# instead of the row (probe: Fizzygum-tests/.scratch/p2-inert-holder-neutralization-probe.js).
# With no child there is nothing left to ask, and the row wins its own taps by construction.
#
# My own `catchesPointerAt: -> false` states the remaining half as a ROLE: I am something to look
# at, never something to press, so the hit falls through me to the row that carries me. That is a
# widget's business rather than its shape's -- the same declaration PopUpRowsViewportWdgt makes,
# and its comment is worth reading beside this one, because it spells out the half that bites: its
# rows panel still takes its own clicks THROUGH it. A parent's answer covers the parent only.

class InertIconHolderWdgt extends Widget

  # my picture: an HTMLCanvasElement at device resolution, taken at construction and never redrawn.
  # It rides serialization as a $Canvas (a PNG data URL) and duplication through
  # Duplicator._copyCanvas, so it needs no transient declaration and no rebuild hook -- a snapshot
  # of a pinned menu comes back with its icons still on it.
  raster: undefined

  # POSITIONAL for the identity -- the widget I am a picture OF -- and `fitInto` (a Point, the box
  # to fit that widget into) rides opts. I take the picture and let the widget go: I keep no
  # reference to it, and disposing of it is the caller's business, not mine.
  constructor: (widgetToPicture, opts = {}) ->
    super()
    @appearance = @createAppearance()
    @_takePictureOf widgetToPicture, opts.fitInto  if widgetToPicture?

  createAppearance: -> new InertIconAppearance @

  colloquialName: ->
    "icon"

  # THE ROLE (see the header): something to look at, never a pointer target.
  catchesPointerAt: (aPoint) ->
    false

  # I am a picture, not an editing surface. The editor SELECTION walk
  # (WorldWdgt._widgetBeingEdited) climbs to the first ancestor with an OPINION, and mine is none:
  # `undefined` lets the walk pass through me to whoever is really being edited.
  providesAmenitiesForEditing: undefined

  # THE ONE-TIME SHOT. Fit the widget into the glyph box the way a toolbar cell fits a tool into
  # its thumbnail, then photograph it and keep the pixels.
  #   Sizing FIRST and shooting after is what makes this deterministic: the raster comes out at
  # exactly my extent x ceilPixelRatio, so it blits one device pixel to one. Shooting at the
  # tool's cell size and scaling the raster down would RESAMPLE, and a resample is the one thing
  # the two rendering backends are not obliged to agree about pixel for pixel.
  _takePictureOf: (aWdgt, fitInto) ->
    extent = @_extentFitting aWdgt, fitInto
    # the APPLY tier, not the public setter: the widget I am shooting is a throwaway orphan, and
    # what I need before the shot is exactly what this does -- re-lay its own contents at the new
    # size. There is no world state to settle around it.
    aWdgt._applyExtent extent
    # `bounds:` rather than fullImage's default fullBounds: my picture is the widget's OWN box,
    # which is what a strip shows of a tool anyway, so my extent is known BEFORE the shot instead
    # of being read back off it. noShadow: a picture on a menu row is not a thing lying on a desk.
    @raster = aWdgt.fullImage bounds: aWdgt.bounds, noShadow: true
    @__commitExtent extent

  # The glyph box, or as much of it as the widget's own proportions want: a widget declaring an
  # idealRatioWidthToHeight keeps that ratio inside the box, one that declares none fills it
  # square. The same fit GlassBoxBottomWdgt._reLayoutSelf applies in a toolbar cell, at glyph
  # scale instead of thumbnail scale -- and rounded, because a widget is sized in whole pixels.
  _extentFitting: (aWdgt, fitInto) ->
    glyphBox = WorldWdgt.preferencesAndSettings.barGlyphSize
    box = fitInto ? new Point glyphBox, glyphBox
    ratio = aWdgt.idealRatioWidthToHeight
    return box.round()  unless ratio?
    fitted = if ratio > 1 then new Point box.x, (box.y / ratio) else new Point (box.x * ratio), box.y
    fitted.round()
