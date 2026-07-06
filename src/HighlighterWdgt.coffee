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

  # --- highlight style channel (Phase 1 of the drag-embed arc) ---------------------------------
  # A style descriptor is a plain record {form, color, alphaScaled}. Producers declare a target ->
  # descriptor into world.widgetsToBeHighlighted (a Map); the reconciler builds one HighlighterWdgt
  # per target and calls applyHighlightStyle. Today only the legacy translucent-blue FILL exists
  # (menu hover-highlight); the drag arc adds OUTLINE styles (eager/willing/reluctant) in Phase 2.
  @fillStyle: (color, alphaScaled) -> {form: "fill", color: color, alphaScaled: alphaScaled}

  applyHighlightStyle: (style) ->
    # form "fill" = the translucent wash (the only style today); "outline" arrives in Phase 2.
    @setColor style.color
    @setAlphaScaled style.alphaScaled

