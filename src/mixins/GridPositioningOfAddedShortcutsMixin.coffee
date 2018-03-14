# REQUIRES globalFunctions


GridPositioningOfAddedShortcutsMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      numberOfIconsOnDesktop: 0
      laysIconsHorizontallyInGrid: true
      iconsLayingInGridWrapCount: 3
      iconsPaddingFromContainerEdges: 5

      add: (aMorph, position, layoutSpec, beingDropped) ->
        # TODO can't handle default parameters in mixins
        if !position?
          position = nil
        if !layoutSpec?
          layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING

        super
        # If the user drops an icon, it's more natural to just position it
        # where it is. Conversely, if an icon is just "created" somewhere,
        # then automatic grid positioning is better.
        if !beingDropped and (aMorph instanceof WidgetHolderWithCaptionWdgt) and !(aMorph instanceof BasementOpenerWdgt)
          if @laysIconsHorizontallyInGrid
            xPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
            yPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
          else
            xPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
            yPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
          aMorph.fullRawMoveTo (@position().add new Point xPos * 85, yPos * 85).add @iconsPaddingFromContainerEdges
          @numberOfIconsOnDesktop++
