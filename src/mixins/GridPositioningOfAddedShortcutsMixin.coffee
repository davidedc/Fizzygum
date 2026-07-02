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

      add: (aWdgt, position, layoutSpec, beingDropped) ->
        # TODO can't handle default parameters in mixins
        if !position?
          position = nil
        if !layoutSpec?
          layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING

        super
        # If the user drops an icon, it's more natural to just position it
        # where it is. Conversely, if an icon is just "created" somewhere,
        # then automatic grid positioning is better.
        # a freshly-created (not dropped) desktop icon that takes part in the grid is auto-placed;
        # was `(aWdgt instanceof WidgetHolderWithCaptionWdgt) and !(aWdgt instanceof BasementOpenerWdgt)`
        # (type-test-elimination campaign)
        if !beingDropped and aWdgt.participatesInIconGrid?()
          if @laysIconsHorizontallyInGrid
            xPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
            yPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
          else
            xPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
            yPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
          aWdgt._applyMoveTo (@position().add new Point xPos * 85, yPos * 85).add @iconsPaddingFromContainerEdges
          @numberOfIconsOnDesktop++
