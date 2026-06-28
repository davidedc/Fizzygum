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

    # §4.1 pure measure: ratio-locked, so preferred height = round(width * current ratio)
    # (mirrors rawSetWidthSizeHeightAccordingly above). No mutation, no seam.
    preferredExtentForWidth: (availW) ->
      new Point availW, Math.round availW * (@height()/@width())

    holderWindowJustBeenGrabbed: (whereFrom) ->
      # capability query replaces `whereFrom instanceof SimpleVerticalStackPanelWdgt`
      # (type-test-elimination campaign)
      if whereFrom?.releasesRatioConstraintOnGrabbedChildren?()
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
      # capability query replaces `(whereIn instanceof SimpleVerticalStackPanelWdgt) and
      # !(whereIn instanceof WindowWdgt)` (type-test-elimination campaign)
      if whereIn?.imposesRatioConstraintOnDroppedChildren?()
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
