# BoxMorph ////////////////////////////////////////////////////////////

# I can have an optionally rounded border

class BoxMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  cornerRadius: null

  constructor: (@cornerRadius = 4) ->
    super()
    @appearance = new BoxyAppearance @

  insetPosition: ->
    return @position().add(@cornerRadius - Math.round(@cornerRadius/Math.sqrt(2)))

  insetSpaceExtent: ->
    return @extent().subtract(2*(@cornerRadius - Math.round(@cornerRadius/Math.sqrt(2))))

  extentBasedOnInsetExtent: (insetMorph) ->
    return insetMorph.extent().add(2*(@cornerRadius - Math.round(@cornerRadius/Math.sqrt(2))))

  # there is another method almost equal to this
  # todo refactor
  choiceOfMorphToBePicked: (ignored, morphPickingUp) ->
    # this is what happens when "each" is
    # selected: we attach the selected morph
    morphPickingUp.addInset @
    if @ instanceof ScrollFrameMorph
      @adjustContentsBounds()
      @adjustScrollBars()


  setCornerRadius: (radiusOrMorphGivingRadius, morphGivingRadius) ->
    if morphGivingRadius?.getValue?
      radius = morphGivingRadius.getValue()
    else
      radius = radiusOrMorphGivingRadius

    # for context menu demo purposes
    if typeof radius is "number"
      @cornerRadius = Math.max radius, 0
    else
      newRadius = parseFloat radius
      if !isNaN newRadius
        @cornerRadius = Math.max newRadius, 0
    @layoutInset()
    @changed()

  
  # there is another method almost equal to this
  # todo refactor
  pickInset: ->
    choices = world.plausibleTargetAndDestinationMorphs @

    # my direct parent might be in the
    # options which is silly, leave that one out
    choicesExcludingParent = []
    choices.forEach (each) =>
      if each != @parent
        choicesExcludingParent.push each

    if choicesExcludingParent.length > 0
      menu = new MenuMorph false, @, true, true, "choose Morph to put as inset:"
      choicesExcludingParent.forEach (each) =>
        menu.addMenuItem each.toString().slice(0, 50), true, each, "choiceOfMorphToBePicked"
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible morphs to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # morphs then show some kind of message.
      menu = new MenuMorph false, @, true, true, "no morphs to pick"
    menu.popUpAtHand @firstContainerMenu()

