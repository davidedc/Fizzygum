# BasementOpenerMorph //////////////////////////////////////////////////////

class BasementOpenerMorph extends BoxMorph

  constructor: (target) ->
    super()

    @color = new Color 160, 160, 160
    @noticesTransparentClick = true

    lmContent1 = new BasementIconWdgt()
    lmContent2 = new TextMorph2 "Basement"

    @add lmContent1, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @add lmContent2, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    #lmContent1.setColor new Color 0, 255, 0
    #lmContent2.setColor new Color 0, 0, 255

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), 2* LayoutSpec.SPREADABILITY_MEDIUM

    @fullRawMoveTo new Point 10 + 60 * 0, 30 + 50 * 1
    if !world.basementWdgt?
      world.basementWdgt = new BasementWdgt()

    new HandleMorph @

  mouseDoubleClick: ->
    if !world.basementWdgt?
      world.basementWdgt = new BasementWdgt()

    if world.basementWdgt?.destroyed
      world.basementWdgt = new BasementWdgt()

    world.basementWdgt.spawnNextTo @


