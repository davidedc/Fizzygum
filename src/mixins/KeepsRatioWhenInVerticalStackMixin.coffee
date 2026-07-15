KeepsRatioWhenInVerticalStackMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

    _setWidthSizeHeightAccordingly: (newWidth) ->
      @_resizeToWithoutSpacing?()
      ratio = @height()/@width()
      @_applyExtent new Point newWidth, Math.round newWidth * ratio
      @height()  # Path B: hand the resulting height back (see Widget._setWidthSizeHeightAccordingly -- "EVERY
      # override must return its resulting height"). Without this the method returned @_applyExtent's value,
      # which is UNDEFINED when the extent is unchanged (a no-op re-fit -- exactly the UN-COLLAPSE case, where
      # the content is restored to its old extent BEFORE the container re-fits it). A ratio-locked container
      # (canSetHeightFreely=false) does not recompute desiredHeight, so `stackHeight += undefined` went NaN ->
      # NaN window height -> a NaN dirty rect -> SWCanvas's clip() throws "must be a finite number" (native
      # canvas silently tolerated it). The 3D plot's own override already returns @height(), so it was immune --
      # which is why every plot EXCEPT the 3D one crashed on uncollapse.

    # §4.1 pure measure: ratio-locked, so preferred height = round(width * current ratio)
    # (mirrors _setWidthSizeHeightAccordingly above). No mutation, no seam.
    preferredExtentForWidth: (availW) ->
      new Point availW, Math.round availW * (@height()/@width())

    _reactToHolderWindowGrabbed: (whereFrom) ->
      # capability query replaces `whereFrom instanceof SimpleVerticalStackPanelWdgt`
      # (type-test-elimination campaign)
      if whereFrom?.releasesRatioConstraintOnGrabbedChildren?()
        @_freeFromRatioConstraints()

    _freeFromRatioConstraints: ->
      if @layoutSpecDetails?
        @layoutSpecDetails.canSetHeightFreely = true

        availableHeight = world.height() - 20
        if @parent.height() > availableHeight
          @parent._applyExtent (new Point Math.min((@width()/@height()) * availableHeight, world.width()), availableHeight).round()
          @parent._applyMoveTo world.hand.position().subtract @parent.extent().floorDivideBy 2
          @parent._moveWithin world

    _reactToHolderWindowDropped: (whereIn) ->
      # capability query replaces `(whereIn instanceof SimpleVerticalStackPanelWdgt) and
      # !(whereIn instanceof WindowWdgt)` (type-test-elimination campaign)
      if whereIn?.imposesRatioConstraintOnDroppedChildren?()
        @_constrainToRatio()

    _constrainToRatio: ->
      if @layoutSpecDetails?
        @layoutSpecDetails.canSetHeightFreely = false
        # force a resize, so widget
        # will take the right ratio
        # Note that the height of 0 here is ignored since
        # "_setWidthSizeHeightAccordingly" will
        # calculate the height.
        @_setWidthSizeHeightAccordingly @width()
