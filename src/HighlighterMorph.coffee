# HighlighterMorph /////////////////////////////////////////////////////////
#
# Used to temporarily highlight morphs e.g. when you hover over
# a morph entry in a menu, the corresponding morph is highlighted.
#
# Doesn't cast a shadow (that would be too much, this is simple
# highlighting, it's not anything material that the user is
# supposed to click/drag/interact with).
#
# These morphs are transparently/automatically added/removed by the
# addHighlightingMorphs function in doOneCycle
# just before the @updateBroken() call.
#
# That addHighlightingMorphs function tries to be smart so to just
# add/modify/remove the HighlighterMorphs that
# are new or that need to change position or that need to go away.
# (i.e. HighlighterMorph are not just blindly created anew each frame)
# (TODO is this optimisation needed/worth it? probably not?)
#
# These morphs are always at the top, so you can always see a morph being
# highlighted even if it's (partially) occluded by other morphs.

class HighlighterMorph extends RectangleMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

