# I can have an optionally rounded border

class BoxMorph extends Widget

  cornerRadius: nil

  constructor: (@cornerRadius = 4) ->
    super()
    @appearance = new BoxyAppearance @

  colloquialName: ->
    "box"

  # »>> this part is excluded from the fizzygum homepage build
  # there is another method almost equal to this
  # todo refactor
  choiceOfMorphToBePicked: (ignored, morphPickingUp) ->
    # this is what happens when "each" is
    # selected: we attach the selected morph
    if @ instanceof ScrollPanelWdgt
      @adjustContentsBounds()
      @adjustScrollBars()
  # this part is excluded from the fizzygum homepage build <<«


  setCornerRadius: (radiusOrMorphGivingRadius, morphGivingRadius) ->
    if morphGivingRadius?.getValue?
      radius = morphGivingRadius.getValue()
    else
      radius = radiusOrMorphGivingRadius

    if typeof radius is "number"
      @cornerRadius = Math.max radius, 0
    else
      newRadius = parseFloat radius
      if !isNaN newRadius
        @cornerRadius = Math.max newRadius, 0
    @changed()
