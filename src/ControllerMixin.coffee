# //////////////////////////////////////////////////////////

# these comments below needed to figure our dependencies between classes
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
        # get rid of any previous temporary
        # active menu because it's meant to be
        # out of view anyways, otherwise we show
        # its submorphs in the setTarget options
        # which is most probably not wanted.
        if world.activeMenu
          world.activeMenu = world.activeMenu.destroy()
        choices = @plausibleTargetAndDestinationMorphs()
        if choices.length > 0
          menu = new MenuMorph(@, "choose target:")
          #choices.push @world()
          choices.forEach (each) =>
            menu.addItem each.toString().slice(0, 50), =>
              @setTargetSetter(each)
        else
          menu = new MenuMorph(@, "no targets available")
        menu.popUpAtHand()
