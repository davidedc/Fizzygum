# The look of a one-line text-entry field (StringFieldWdgt, a prompt's entry field):
#   the WELL  my widget's fill -- its own colour, or, while it holds none, the textFieldFill role it
#             answers (_surfaceFill) -- over its whole box, rounded at textFieldCornerRadius, with no
#             border, painted by the shared Appearance._paintPlate
# Every value is my widget's or a Theme role or metric, read as I paint, so a saved or copied field
# wears the look of the world it is shown in.
#
# My SHAPE is my widget's whole box (the base answer), as a rectangular panel's is: a press in a
# rounded corner still reaches the field. My SILHOUETTE is the well: on a shadow pass I fill it in
# shadowColor. I claim no opaque cover (the base answer): the corners outside the well show what
# lies behind the field.
#   The field clips its text to its RECTANGLE, not to the well, so the corners stay clear only
# because nothing it holds paints there: its text has no background of its own and stands 5 px in
# from the field's left edge and 2 px below its top (StringFieldWdgt._reLayoutChildren), past the
# rounding; only a text's ink or caret that reaches the field's right end can cross the right-hand
# corners.

class StringFieldAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      theme = WorldWdgt.theme
      fill = if appliedShadow? then theme.shadowColor else @widget.color ? @widget._surfaceFill?()
      @_paintPlate ctx, theme.textFieldCornerRadius, fill
    return undefined
