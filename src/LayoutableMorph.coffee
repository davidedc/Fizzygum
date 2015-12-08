# LayoutableMorph //////////////////////////////////////////////////////

# This is gonna trampoline a second version of the layout system.

# this comment below is needed to figure out dependencies between classes
# REQUIRES LayoutSpec


class LayoutableMorph extends Morph

  add: (aMorph, position = null, layoutSpec = LayoutSpec.FREEFLOATING ) ->
    
    if layoutSpec == LayoutSpec.FREEFLOATING
      return super
    else
      super
      aMorph.layoutSpec = layoutSpec
