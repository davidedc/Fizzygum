# UnderTheCarpetOpenerMorph //////////////////////////////////////////////////////

class UnderTheCarpetOpenerMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # panes:
  scrollFrame: null
  buttonClose: null
  resizer: null
  underTheCarpetMorph: null

  constructor: (target) ->
    super()

    @noticesTransparentClick = true

    lmContent1 = new UnderCarpetIconMorph()
    lmContent2 = new TextMorph2("under the carpet")

    @add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    #lmContent1.setColor new Color(0, 255, 0)
    #lmContent2.setColor new Color(0, 0, 255)

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), 2* LayoutSpec.SPREADABILITY_MEDIUM

    @fullRawMoveTo new Point(10 + 60 * 0, 30 + 50 * 1)

    new HandleMorph @

  mouseClickLeft: ->
    if @underTheCarpetMorph?.destroyed
      @underTheCarpetMorph = null

    if @underTheCarpetMorph?
      @underTheCarpetMorph.pickUp()
      return

    @underTheCarpetMorph = new UnderTheCarpetMorph()
    world.create @underTheCarpetMorph
