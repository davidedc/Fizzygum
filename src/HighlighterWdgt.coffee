# Used to temporarily highlight widgets e.g. when you hover over
# a widget entry in a menu, the corresponding widget is highlighted.
#
# Doesn't cast a shadow (that would be too much, this is simple
# highlighting, it's not anything material that the user is
# supposed to click/drag/interact with).
#
# These widgets are transparently/automatically added/removed by the
# addHighlightingWidgets function in doOneCycle
# just before the @updateBroken() call.
#
# That addHighlightingWidgets function tries to be smart so to just
# add/modify/remove the HighlighterWdgts that
# are new or that need to change position or that need to go away.
# (i.e. HighlighterWdgt are not just blindly created anew each frame)
# (TODO is this optimisation needed/worth it? probably not?)
#
# These widgets are always at the top, so you can always see a widget being
# highlighted even if it's (partially) occluded by other widgets.

class HighlighterWdgt extends RectangleWdgt

  # I am an EPHEMERAL overlay (owner's term): reconciler-owned, hit-test-excluded, shadow-free and
  # snapshot-excluded — all derived from this one flag via the isEphemeral() capability on Widget
  # (was a dedicated `skipsAddShadowManagement -> true` plus two per-marker hit-test predicates;
  # type-test-elimination campaign). Prototype flag: EVERY HighlighterWdgt is an ephemeral.
  _ephemeralOverlay: true

  # I am LAYOUT-INERT chrome, exactly like HandleWdgt / CaretWdgt (the only other isLayoutInert
  # classes). Affine transforms rough edge R2 (§6): the reconciler now parents a highlight INTO its
  # target's enclosing island so it warps + clips with the target (§4.6 halo-handle model). Being
  # layout-inert excludes me from childrenNotHandlesNorCarets / subWidgetsMergedFullBounds, so I can
  # never disturb a size-tracking container's content bounds — in particular I never count as the
  # single content child of a sugar island (a highlighted rotated widget would otherwise fail the
  # TrackingTransformFrameWdgt single-child check, and a second setRotationDegrees while hovered would
  # nest a second island). Still PAINTED into the island buffer (painting iterates ALL children, not
  # just the non-inert ones), so the highlight stays visible. No effect on the world-child path (those
  # content-bounds enumerations run only on scroll / size-tracking containers, never the world).
  isLayoutInert: -> true

  # --- highlight style channel (drag-embed arc) ------------------------------------------------
  # A style descriptor is a plain record. Producers declare a target -> descriptor into
  # world.widgetsToBeHighlighted (a Map); the reconciler builds one HighlighterWdgt per target and
  # calls applyHighlightStyle. Two forms:
  #   {form:"fill",    color, alphaScaled}  — the legacy translucent wash (menu hover-highlight)
  #   {form:"outline", color, alpha}        — a coloured border (drag candidate/reluctant affordance)
  @fillStyle: (color, alphaScaled) -> {form: "fill", color: color, alphaScaled: alphaScaled}

  # Drag-embed candidate/reluctant outlines (spec §11). A receptive candidate gets the accent
  # (pencil-yellow family); a view-mode reluctant target gets a neutral gray. Outline (not a wash):
  # S1 found the whole-target fill far too loud for a drag affordance.
  @candidateOutlineStyle: -> {form: "outline", color: Color.create(248, 188, 58, 1), alpha: 1}
  @reluctantOutlineStyle: -> {form: "outline", color: Color.create(140, 140, 140, 1), alpha: 1}

  applyHighlightStyle: (style) ->
    if style.form is "outline"
      # transparent fill + a coloured stroke border (the built-in RectangularAppearance.paintStroke,
      # gated on @strokeColor). @alpha drives the stroke opacity.
      @setColor Color.create(0, 0, 0, 0)
      @strokeColor = style.color
      @alpha = style.alpha ? 1
    else
      # the translucent fill wash
      @strokeColor = nil
      @setColor style.color
      @setAlphaScaled style.alphaScaled

