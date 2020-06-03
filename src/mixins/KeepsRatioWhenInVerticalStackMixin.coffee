KeepsRatioWhenInVerticalStackMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

    rawSetWidthSizeHeightAccordingly: (newWidth) ->
      @rawResizeToWithoutSpacing?()
      ratio = @height()/@width()
      @rawSetExtent new Point newWidth, Math.round newWidth * ratio

    holderWindowJustBeenGrabbed: (whereFrom) ->
      if whereFrom instanceof SimpleVerticalStackPanelWdgt
        @freeFromRatioConstraints()

    holderWindowMadeIntoExternal: ->
      @freeFromRatioConstraints()

    freeFromRatioConstraints: ->
      if @layoutSpecDetails?
        @layoutSpecDetails.canSetHeightFreely = true

        availableHeight = world.height() - 20
        if @parent.height() > availableHeight
          @parent.rawSetExtent (new Point Math.min((@width()/@height()) * availableHeight, world.width()), availableHeight).round()
          @parent.fullRawMoveTo world.hand.position().subtract @parent.extent().floorDivideBy 2
          @parent.fullRawMoveWithin world

    holderWindowJustDropped: (whereIn) ->
      if (whereIn instanceof SimpleVerticalStackPanelWdgt) and !(whereIn instanceof WindowWdgt)
        @constrainToRatio()

    constrainToRatio: ->
      if @layoutSpecDetails?
        @layoutSpecDetails.canSetHeightFreely = false
        # force a resize, so widget
        # will take the right ratio
        # Note that the height of 0 here is ignored since
        # "rawSetWidthSizeHeightAccordingly" will
        # calculate the height.
        @rawSetWidthSizeHeightAccordingly @width()
