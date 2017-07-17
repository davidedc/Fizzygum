# HighlighterMorph /////////////////////////////////////////////////////////
# used to temporarily highlight morphs e.g. when you hover over
# a morph entry in a menu, the corresponding morph is highlighted.
# Doesn't cast a shadow (that would be too much, this is simple
# highlighting, it's not anything material that the user is
# supposed to interact with).

class HighlighterMorph extends RectangleMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

