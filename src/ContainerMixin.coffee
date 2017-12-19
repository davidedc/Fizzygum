# //////////////////////////////////////////////////////////
#      THIS MIXIN IS TEMPORARY. JUST STARTED IT.
# //////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions

#   1) a container has potentially a background and
#   2) some padding
#   3) it resizes itself so to *at least contain* all the morphs attached to it (i.e. it could be bigger).
# It doesn’t need to be rectangular.
# [TODO] Also it can draw a border of its own cause of the padding, you can add enough padding so the border is drawn correctly, maybe the padding can be automatically determined based on the border color.

ContainerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,
      setTarget: ->
        choices = world.plausibleTargetAndDestinationMorphs @
        if choices.length > 0
          menu = new MenuMorph @, false, @, true, true, "choose target:"
          #choices.push @world()
          choices.forEach (each) =>
            menu.addMenuItem each.toString().slice(0, 50) + " ➜", false, @, "setTargetSetter", nil, nil, nil, nil, nil,each
        else
          menu = new MenuMorph @, false, @, true, true, "no targets available"
        menu.popUpAtHand()

      adjustBounds: ->
        newBounds = @subMorphsMergedFullBounds()
        if newBounds
          if @padding?
            newBounds = newBounds.expandBy @padding
        else
          newBounds = @boundingBox()

        unless @boundingBox().eq newBounds
          @silentRawSetBounds newBounds
          @changed()
          @reLayout()
          
