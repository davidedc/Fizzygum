# We need this because we need a panel that keeps its content
# all in the same relative positions and sizes when its
# resized, so you can drag and drop it inside stacks
# and resizable windows and it doesn't mangle the contents
# when it's resized. The way to achieve that is to
# have a container and a type of panel that works together
# to "crystallize" a specific width/height ratio as soon
# as there is one element dropped/added in the panel.
# So when the panel is empty, you can give it any shape you
# want, but as soon as there is one element, it sticks
# to the ratio it has.

class StretchableWidgetContainerWdgt extends Widget

  @augmentWith BubblesEditModeToCoordinatorMixin, @name

  ratio: nil
  contents: nil

  constructor: (@contents) ->
    super new Point 300, 300
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if !@contents?
      @contents = new StretchablePanelWdgt

    @_addNoSettle @contents

    @_applyExtent new Point 300, 300
    @contents._applyExtent new Point @width(), @height()
    @_invalidateLayout()

  # actually
  # ends up in the Panel inside it
  add: (aWdgt, position = nil, layoutSpec = nil, beingDropped) ->
    # annotation + handle both attach to the scroll frame directly (was their two instanceof)
    # (type-test-elimination campaign)
    if !@contents? or aWdgt.attachesToScrollFrameDirectly?()
      super
    else
      @contents.add aWdgt, position, layoutSpec, beingDropped

  # Crystallizing a ratio pins canSetHeightFreely ONLY on a STACK spec (§5.B):
  # as a framed CITIZEN's direct content my FrameContentLayoutSpec stays FREE
  # (the window keeps its user-dragged size, content letterboxes) exactly as
  # the retired editor era behaved -- the ratio-LOCK of the holding frame
  # arrives only through the holder-frame stack-drop hook (_constrainToRatio
  # below), never from mere content crystallization. (Pre-§5.B these writes
  # hit a nil/stack spec anyway -- the editor's own spec governed the window.)
  setRatio: (@ratio) ->
    unless @_contentStackSpec?.isFrameContentSpec?()
      @_contentStackSpec?.canSetHeightFreely = false

  resetRatio: ->
    if @ratio?
      @ratio = nil
      @_contentStackSpec?.canSetHeightFreely = true
      @_invalidateLayout()


  colloquialName: ->
    "stretchable panel"

  # paintingOverlay() capability chain (§5.D): delegate to my content -- for an
  # ImageWdgt's payload that is the paintable canvas, which answers its glass.
  paintingOverlay: ->
    @contents?.paintingOverlay?()

  # ===== holder-frame ratio hooks (§5.B) =====
  # Were KeepsRatioWhenInVerticalStackMixin's, applied to the retired editor
  # middle layer -- which only RELAYED my own ratio machinery. As a framed
  # citizen's direct content I answer the frame's dropped/grabbed
  # notifications myself. (Hand-written, NOT the mixin -- deliberately: my sizing
  # pair is the PINNED @ratio variant (content-aware, super-fallback), not the
  # mixin's current-aspect one, so augmenting would inject six members only to
  # have four immediately shadowed by my class body -- legal under the boot-order
  # rule (class body wins over injections), but a misleading "augments-yet-
  # overrides-most-of-it" read. Only these two 3-line relays would survive;
  # not worth it.)
  _reactToHolderFrameDropped: (whereIn) ->
    if whereIn?.imposesRatioConstraintOnDroppedChildren?()
      @_constrainToRatio()

  _reactToHolderFrameGrabbed: (whereFrom) ->
    if whereFrom?.releasesRatioConstraintOnGrabbedChildren?()
      @_freeFromRatioConstraints()

  _constrainToRatio: ->
    if @_contentStackSpec?
      @_contentStackSpec.canSetHeightFreely = false
      # force a resize, so the holder frame takes the right ratio. The height
      # of 0 is ignored -- _setWidthSizeHeightAccordingly calculates it.
      if @ratio?
        @_applyExtent new Point @width(), 0

  _freeFromRatioConstraints: ->
    if @_contentStackSpec?
      @_contentStackSpec.canSetHeightFreely = true

      availableHeight = world.height() - 20
      if @parent.height() > availableHeight
        @parent._applyExtent (new Point Math.min((@width()/@height()) * availableHeight, world.width()), availableHeight).round()
        @parent._applyMoveTo world.hand.position().subtract @parent.extent().floorDivideBy 2
        @parent._moveWithin world

  # Smart-placement protocol (WidgetCreatorAndSmartPlacerOnClickMixin routes a
  # creator-button click to a frame's CONTENT -- for the §5.B container
  # citizens that content is me; the retired editor's version centred in me
  # anyway).
  acceptsSmartPlacedWidgets: ->
    @dragsDropsAndEditingEnabled

  smartPlace: (widgetToBePlaced, creator) ->
    widgetToBePlaced._applyMoveTo @center().round().subtract widgetToBePlaced.extent().floorDivideBy 2
    @add widgetToBePlaced
    @bringToForeground()
    creator.bringToForeground()

  # (§5.B) NO initialiseDefaultFrameContentLayoutSpec override: as a framed
  # citizen's content the spec keeps the base default canSetHeightFreely=true
  # -- free window sizing, like the retired editor's un-overridden spec. The
  # old `= !@ratio?` pin here dated from the ANCIENT direct-content era and
  # encoded the ratio-locked-window behaviour the editor era replaced.


  widthWithoutSpacing: ->
    height = @height()
    width = @width()

    if @ratio?
      widthBasedOnHeight = height * @ratio
      heightBasedOnWidth = width / @ratio

      if widthBasedOnHeight <= width
        return widthBasedOnHeight

      else if heightBasedOnWidth <= height
        return width

    else
        return width

  _resizeToWithoutSpacing: ->
    if @ratio?
      @_applyExtent new Point @widthWithoutSpacing(), Math.round(@widthWithoutSpacing()/@ratio)

  # (§5.B) The retired editor's early-out, one level down: a FREE frame-content
  # spec (canSetHeightFreely -- the base default; false only after a
  # holder-frame stack-drop constrains it) sizes width-only via super, so a
  # desktop citizen window keeps its dragged height and letterboxes. A stack
  # spec / nil spec answers undefined here and falls to the ratio body --
  # bare-container-in-a-stack behaviour unchanged.
  _setWidthSizeHeightAccordingly: (newWidth) ->
    if @_contentStackSpec?.canSetHeightFreely
      return super  # Path B: propagate the resulting height. See Widget._setWidthSizeHeightAccordingly.

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    if childrenNotHandlesNorCarets.length != 0
      if !@ratio?
        @ratio = @width() / @height()
        unless @_contentStackSpec?.isFrameContentSpec?()
          @_contentStackSpec?.canSetHeightFreely = false
      @_applyExtent new Point newWidth, Math.round(newWidth/@ratio)
    else
      @_applyExtent new Point newWidth, @height()
    @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.

  # §4.1 pure measure (sizing-model unification U3-B): mirrors _setWidthSizeHeightAccordingly
  # above -- the free-spec early-out, then ratio-locked while holding content,
  # width-invariant when empty. When the sizing hasn't lazily initialised @ratio yet, the
  # SAME value is DERIVED locally with NO write -- a measure must not take the mutation's
  # lazy-init side effect (@ratio + canSetHeightFreely).
  preferredExtentForWidth: (availW) ->
    if @_contentStackSpec?.canSetHeightFreely then return super
    if (@childrenNotHandlesNorCarets @contents).length != 0
      ratio = @ratio ? (@width() / @height())
      new Point availW, Math.round(availW / ratio)
    else
      new Point availW, @height()



  _reLayout: (newBoundsForThisLayout) ->



    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return


    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout


    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this widget are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    height = @height()
    width = @width()

    if @ratio?
      widthBasedOnHeight = height * @ratio
      heightBasedOnWidth = width / @ratio

       # p0 is the origin, the origin being in the top-left corner
      p0 = @topLeft()

      if widthBasedOnHeight <= width
        p0 = p0.add new Point (width - widthBasedOnHeight) / 2 , 0
        newExtent = new Point widthBasedOnHeight, height

      else if heightBasedOnWidth <= height
        p0 = p0.add new Point 0 , (height - heightBasedOnWidth) / 2
        newExtent = new Point width, heightBasedOnWidth

      newBounds = (new Rectangle p0).setBoundsWidthAndHeight newExtent
      @contents._reLayout newBounds.round()

    else
      @contents._reLayout @bounds



    world.maybeEnableTrackChanges()
    @_fullChanged()

    super
    @_markLayoutAsFixed()


  # same as simpledocumentscrollpanel, you can lock the contents.
  # worth factoring it out as a mixin?
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addEditingLockMenuEntries menu, @childrenNotHandlesNorCarets()

  # I coordinate drags/drops/editing for my StretchablePanelWdgt child, which delegates
  # its enable/disable up to me (it replaced `@parent instanceof
  # StretchableWidgetContainerWdgt` with this query). I am in turn an editable child of
  # a slide, so I bubble my own enable/disable up the same way. (type-test-elimination campaign)
  coordinatesDragsDropsAndEditingForChildren: ->
    true

  # canonical settle-wraps; the bubbling cores they dispatch to are injected by
  # BubblesEditModeToCoordinatorMixin
  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget
