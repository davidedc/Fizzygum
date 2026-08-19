# THE ASPECT CONTRACT (D6, sizing-model unification U4 — docs/archive/sizing-model-unification-plan.md §9.8):
# aspect/fixed content participates in vertical sizing through exactly two ingredients —
#   1. a PURE width→height measure (preferredExtentForWidth; this mixin's is the ratio one,
#      the clock/spreadsheet/holder/composite-icon have their own square/grid twins), and
#   2. a grow POLICY chosen by placement role:
#      - as CONTENT that should stay size-stable: an EXPLICIT grow 0 declared in the
#        content's initialiseDefaultFrameContentLayoutSpec override (the clock and
#        IconWdgt; the spreadsheet is a grow-1 fill since F6) — the capture's oversize
#        trample (wider-than-column ⇒ grow 1, column-tracking) is the one designed
#        exception and survives the pin;
#      - as WINDOW CONTENT that should fill: grow 1 is CORRECT — the window's height follows
#        the ratio through the measure (the plots ship this way).
# No cycle is possible either way since the ordered down-walk + pure measures + the §9.7-Q
# width rule: a vertical stack never derives its width from child heights, and a
# container-owned window never self-resizes to its content. The U4 firing profile
# (suite-wide capture census) confirmed every in-tree grow≠0-with-aspect-measure capture is
# one of the two sanctioned shapes above, so the once-planned lint is consciously NOT built
# (a gate that can only flag by-design states is noise).
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
      @height()  # Path B: hand the resulting height back — omitting it NaN-crashes a ratio-locked
      # container's uncollapse (Widget._setWidthSizeHeightAccordingly; docs/archive/sizing-model-unification-plan.md).

    # §4.1 pure measure: ratio-locked, so preferred height = round(width * current ratio)
    # (mirrors _setWidthSizeHeightAccordingly above). No mutation, no seam.
    preferredExtentForWidth: (availW) ->
      new Point availW, Math.round availW * (@height()/@width())

    _reactToHolderFrameGrabbed: (whereFrom) ->
      # capability query replaces `whereFrom instanceof VerticalStackPanelWdgt`
      # (type-test-elimination campaign)
      if whereFrom?.releasesRatioConstraintOnGrabbedChildren?()
        @_freeFromRatioConstraints()

    _freeFromRatioConstraints: ->
      if @_contentStackSpec?
        @_contentStackSpec.canSetHeightFreely = true

        availableHeight = world.height() - 20
        if @parent.height() > availableHeight
          @parent._applyExtent (new Point Math.min((@width()/@height()) * availableHeight, world.width()), availableHeight).round()
          @parent._applyMoveTo world.hand.position().subtract @parent.extent().floorDivideBy 2
          @parent._moveWithin world

    _reactToHolderFrameDropped: (whereIn) ->
      # capability query replaces `(whereIn instanceof VerticalStackPanelWdgt) and
      # !(whereIn instanceof FrameWdgt)` (type-test-elimination campaign)
      if whereIn?.imposesRatioConstraintOnDroppedChildren?()
        @_constrainToRatio()

    _constrainToRatio: ->
      if @_contentStackSpec?
        @_contentStackSpec.canSetHeightFreely = false
        # force a resize, so widget
        # will take the right ratio --
        # "_setWidthSizeHeightAccordingly"
        # recalculates the height from
        # the new width.
        @_setWidthSizeHeightAccordingly @width()
