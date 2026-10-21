# The look of a resize / move / rotate HandleWdgt (a halo's five handles, a naked inspector's resizer,
# a demo handle): the design's button over my widget's WHOLE box (visual-design-system §4.3, "a
# bordered rounded rectangle means press me"), with the handle's glyph on it --
#   the PLATE  handlePlateFill inside a 1 px handlePlateStroke border at rest, handlePlateHoverFill
#              hovered, handlePlatePressFill inside handlePlatePressStroke pressed (HandleWdgt's
#              _plateFillForMyState / _plateStrokeForMyState), rounded at handlePlateRadius, painted
#              by the shared Appearance._paintPlate (the fill, then the 1 px outline inset half a px)
#   the GLYPH  by my widget's type, in handleGlyph, the same in every state, in its glyph square
#              centred on the plate (_glyphForMyType): the four-way arrow on the move handle and the
#              double arrows on the horizontal and vertical resizers at handleArrowGlyphSize, the
#              curled-arrows square on the rotate handle at handleRotateGlyphSize, and the frame
#              grip's strokes on the corner resizer at handleCornerGlyphSize
# Every value is my widget's state, its box or a Theme role or metric, read as I paint: I hold
# nothing of my own, and the glyph's appearance is built for the paint that wears it (it would be
# saved and copied with me, its ink with it, if I held one), so a saved or copied handle wears the
# look of the world it is shown in.
#
# My SHAPE is my widget's whole box, for every type (the base answer, Appearance.shapeContainsPoint):
# a handle is a target drawn as big as it is, so the plate's rounded corners are the handle's too.
# My SILHOUETTE is the plate: on my widget's OWN shadow pass I fill the rounded box in shadowColor and
# nothing else, so a handle casts its plate's shape (the shadow is its own, HandleWdgt._castMyShadow).
# An ancestor casting its subtree's shadow does not cast me: a handle is chrome over its target, not
# part of the target's shape, and it already casts its own -- under a target with see-through parts (a
# text) its plate would otherwise be shadowed twice.

class HandleAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # an ancestor's shadow pass hands down ITS shadow; my widget's own pass hands down my widget's
    # (Widget.fullPaintIntoAreaOrBlitFromBackBuffer)
    return undefined if appliedShadow? and appliedShadow isnt @widget.shadowInfo

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      theme = WorldWdgt.theme
      # the plate (Appearance._paintPlate) takes its geometry from my widget, never from the scope's
      # damage box (the law on Appearance._paintInLocalScope); the scope has clipped to the damage
      radius = theme.handlePlateRadius

      if appliedShadow?
        @_paintPlate ctx, radius, theme.shadowColor
        return

      @_paintPlate ctx, radius, @widget._plateFillForMyState(), @widget._plateStrokeForMyState()

    # the glyph over the plate, on the normal pass only: the plate is the whole silhouette
    return undefined if appliedShadow?
    [glyph, side] = @_glyphForMyType()
    glyph?.paintAsMarkInSquare aContext, clippingRectangle, side
    return undefined

  # MY WIDGET'S GLYPH, by its type: [the size-aware icon appearance that draws it, in handleGlyph,
  # and the side of its square], or [] for a type I draw no glyph for. Built for each paint.
  _glyphForMyType: ->
    theme = WorldWdgt.theme
    ink = theme.handleGlyph
    switch @widget.type
      when "moveHandle"
        [(new FourWayArrowIconAppearance @widget, ink), theme.handleArrowGlyphSize]
      when "resizeHorizontalHandle"
        [(new DoubleArrowIconAppearance @widget, ink), theme.handleArrowGlyphSize]
      when "resizeVerticalHandle"
        [(new VerticalDoubleArrowIconAppearance @widget, ink), theme.handleArrowGlyphSize]
      when "rotateHandle"
        [(new CurledArrowsSquareIconAppearance @widget, ink), theme.handleRotateGlyphSize]
      when "resizeBothDimensionsHandle"
        [(new GripIconAppearance @widget, ink), theme.handleCornerGlyphSize]
      else
        []
