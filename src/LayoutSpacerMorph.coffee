# LayoutSpacerMorph //////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES LayoutSpec


class LayoutSpacerMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  constructor: (spacerWeight = 1) ->
    super()
    @setColor new Color(0, 0, 0)
    @setMinAndMaxBoundsAndSpreadability (new Point 0,0) , (new Point 1,1), spacerWeight * LayoutSpec.SPREADABILITY_SPACERS

