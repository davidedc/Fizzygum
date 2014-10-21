# //////////////////////////////////////////////////////////
#      THIS MIXIN IS TEMPORARY. JUST STARTED IT.
# //////////////////////////////////////////////////////////

# these comments below needed to figure our dependencies between classes
# REQUIRES globalFunctions

#   1) a container has potentially a background and
#   2) some padding
#   3) it resizes itself so to *at least contain* all the morphs attached to it (i.e. it could be bigger).
# It doesn’t need to be rectangular.
# [TODO] Also it can draw a border of its own cause of the padding, you can add enough padding so the border is drawn correctly, maybe the padding can be automatically determined based on the border color.

ContainerMixin =
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
        choices = world.plausibleTargetAndDestinationMorphs(@)
        if choices.length > 0
          menu = new MenuMorph(@, "choose target:")
          #choices.push @world()
          choices.forEach (each) =>
            menu.addItem each.toString().slice(0, 50), =>
              @setTargetSetter(each)
        else
          menu = new MenuMorph(@, "no targets available")
        menu.popUpAtHand()

  submorphBounds: ->
    result = null
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        result = result.merge(child.boundsIncludingChildren())
    result
    
  adjustBounds: ->
    newBounds = @submorphBounds()
    if newBounds
      if @padding?
        newBounds = newBounds.expandBy(@padding)
    else
      newBounds = @bounds.copy()

    unless @bounds.eq(newBounds)
      @bounds = newBounds
      @changed()
      @updateRendering()
