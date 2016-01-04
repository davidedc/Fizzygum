# //////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions

# some morphs (for example ColorPaletteMorph
# or SliderMorph) can control a target
# and they have the same function to attach
# targets. Not worth having this in the
# whole Morph hierarchy, so... ideal use
# of mixins here.

ControllerMixin =
  # klass properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: ->
    @addInstanceProperties
      setTarget: ->
        choices = world.plausibleTargetAndDestinationMorphs @
        if choices.length > 0
          menu = new MenuMorph false, @, true, true, "choose target:"
          #choices.push @world()
          choices.forEach (each) =>
            menu.addItem each.toString().slice(0, 50) + " ➜", false, @, "setTargetSetter", null, null, null, null, null,each
        else
          menu = new MenuMorph false, @, true, true, "no targets available"
        menu.popUpAtHand @firstContainerMenu()
