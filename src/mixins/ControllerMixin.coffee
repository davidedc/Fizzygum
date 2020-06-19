# //////////////////////////////////////////////////////////

# some morphs (for example ColorPaletteMorph
# or SliderMorph) can control a target
# and they have the same function to attach
# targets. Not worth having this in the
# whole Widget hierarchy, so... ideal use
# of mixins here.

ControllerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,
      openTargetSelector: ->
        choices = world.plausibleTargetAndDestinationMorphs @
        if choices.length > 0
          menu = new MenuMorph @, false, @, true, true, "choose target:"
          #choices.push @world()
          choices.forEach (each) =>
            if !(each instanceof FanoutPinWdgt)
              menu.addMenuItem (each.toString().replace "Wdgt", "").slice(0, 50) + " ➜", false, @, "openTargetPropertySelector", nil, nil, nil, nil, nil, each, nil, true
        else
          menu = new MenuMorph @, false, @, true, true, "no targets available"
        menu.popUpAtHand()

      setTargetAndActionWithOnesPickedFromMenu: (ignored, ignored2, theTarget, each) ->
        @target = theTarget
        @action = each
        if @target[@action + "IsConnected"]?
          @target[@action + "IsConnected"] = true
        @connectionsCalculationToken = world.makeNewConnectionsCalculationToken()
        @reactToTargetConnection?()

