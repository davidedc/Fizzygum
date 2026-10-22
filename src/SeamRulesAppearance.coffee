# Paints a CONTAINER that has no look of its own but owns the seams between its panes
# (visual-design-system §4.1): exactly its seam rules (Widget._seamRects, filled in seamRule by
# Appearance._paintSeamRules) and nothing else -- no fill, no stroke, nothing on the shadow pass.
# Everywhere else whatever lies under the container shows (a window's body, for a window's
# content), as it does under a widget with no appearance at all; a seam is part of the
# container's look, not of its silhouette.
#   Every other answer is the base Appearance's, which is also what a widget with no appearance
# answers: the whole box as my shape (shapeContainsPoint), and no opaque cover (opaqueCoveredRect),
# so the occlusion culler keeps painting what lies under me.
class SeamRulesAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    return if appliedShadow?
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localDamageBox) =>
      @_paintSeamRules ctx, localDamageBox
