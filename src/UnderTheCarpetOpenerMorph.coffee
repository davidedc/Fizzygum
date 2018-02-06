# UnderTheCarpetOpenerMorph //////////////////////////////////////////////////////

class UnderTheCarpetOpenerMorph extends BoxMorph

  constructor: (target) ->
    super()

    @color = new Color 160, 160, 160
    @noticesTransparentClick = true

    lmContent1 = new UnderCarpetIconMorph()
    lmContent2 = new TextMorph2 "under the carpet"

    @add lmContent1, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @add lmContent2, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    #lmContent1.setColor new Color 0, 255, 0
    #lmContent2.setColor new Color 0, 0, 255

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), 2* LayoutSpec.SPREADABILITY_MEDIUM

    @fullRawMoveTo new Point 10 + 60 * 0, 30 + 50 * 1
    if !world.underTheCarpetMorph?
      world.underTheCarpetMorph = new UnderTheCarpetMorph()

    new HandleMorph @

  mouseDoubleClick: ->
    if !world.underTheCarpetMorph?
      world.underTheCarpetMorph = new UnderTheCarpetMorph()

    if world.underTheCarpetMorph?.destroyed
      world.underTheCarpetMorph = new UnderTheCarpetMorph()

    world.underTheCarpetMorph.spawnNextTo @


