# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions

UpperRightInternalHaloMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      # floatDragging and dropping:
      isLockingToPanels: false
      proportionOfParent: 4/8
      fixedSize: 0
      positionWithinParent: "topRight"

      parentHasReLayouted: ->
        @updateResizerPosition()
        @moveInFrontOfSiblings()
        super

      updateResizerPosition: ->
        if @parent
          @silentUpdateResizerPosition()
          @changed()

      silentUpdateResizerPosition: ->
        if @parent
          xDim = @parent.width()
          yDim = @parent.height()
          minDim = Math.min(xDim, yDim) * @proportionOfParent + @fixedSize

          @silentRawSetExtent new Point minDim, minDim
          if @positionWithinParent == "topLeft"
            @silentFullRawMoveTo new Point @parent.left(), @parent.top()
          else if @positionWithinParent == "topRight"
            @silentFullRawMoveTo new Point @parent.right() - minDim, @parent.top()
  
      makeSolidWithParentMorph: (ignored, ignored2, morphAttachedTo)->
        morphAttachedTo.add @
        @updateResizerPosition()
        @noticesTransparentClick = true

        
      # menu:
      attach: ->
        choices = world.plausibleTargetAndDestinationMorphs @
        menu = new MenuMorph @, false, @, true, true, "choose parent:"
        if choices.length > 0
          choices.forEach (each) =>
            menu.addMenuItem each.toString().slice(0, 50) + " ➜", true, @, 'makeSolidWithParentMorph', nil, nil, nil, nil, nil, each, nil, true
        else
          # the ideal would be to not show the
          # "attach" menu entry at all but for the
          # time being it's quite costly to
          # find the eligible morphs to attach
          # to, so for now let's just calculate
          # this list if the user invokes the
          # command, and if there are no good
          # morphs then show some kind of message.
          menu = new MenuMorph @, false, @, true, true, "no morphs to attach to"
        menu.popUpAtHand() if choices.length
