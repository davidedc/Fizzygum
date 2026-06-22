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

  # I am a transient highlight overlay (see above: I deliberately cast no shadow), so I am
  # skipped by the add-time drop-shadow management in Widget.add (was `instanceof HighlighterWdgt`
  # there). (type-test-elimination campaign)
  skipsAddShadowManagement: -> true

