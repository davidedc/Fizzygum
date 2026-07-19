class StretchableEditableWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  stretchableWidgetContainer: nil

  # space between the container's edges and its internals. Often set to 0 since windows
  # already add their own padding around contents.
  externalPadding: 0
  # the internal padding is the space between the internal
  # components. It doesn't necessarily need to be equal to the
  # external padding
  internalPadding: 5

  providesAmenitiesForEditing: true

  constructor: ->
    super
    @_buildAndConnectChildren()

  colloquialName: ->
    "Generic panel"

  representativeIcon: ->
    new GenericPanelIconWdgt

  # Smart-placement protocol, called polymorphically by
  # WidgetCreatorAndSmartPlacerOnClickMixin (replacing an instanceof chain that
  # used to live in the mixin). A content widget that accepts a click-created
  # widget answers acceptsSmartPlacedWidgets and implements smartPlace.
  # Inherited by PatchProgrammingWdgt / SimpleSlideWdgt.
  acceptsSmartPlacedWidgets: ->
    @dragsDropsAndEditingEnabled

  smartPlace: (widgetToBePlaced, creator) ->
    widgetToBePlaced._applyMoveTo @stretchableWidgetContainer.center().round().subtract widgetToBePlaced.extent().floorDivideBy 2
    @stretchableWidgetContainer.add widgetToBePlaced
    widgetToBePlaced._rememberFractionalSituationInHoldingPanel()
    @stretchableWidgetContainer.bringToForeground()
    creator.bringToForeground()


  # NON-settling core: both callers are settle-neutral private code, so a public self-settling
  # wrapper here would open a second flush. History: docs/archive/public-private-call-separation-plan.md (T2).
  _createNewStretchablePanelNoSettle: ->
    @stretchableWidgetContainer = new StretchableWidgetContainerWdgt
    @_addNoSettle @stretchableWidgetContainer


  # Lays out the stretchable container over the full padded bounds -- the
  # editing toolbar lives in the enclosing frame's toolbar-slot (Frame-model
  # plan §5.C), not in this panel. (ReconfigurablePaintWdgt keeps its own,
  # genuinely different _reLayoutSelf -- its overlay-bound tool column stays
  # local until phase D rebinds paint to the focus model.)
  _reLayoutSelf: ->
    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this panel are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    if @stretchableWidgetContainer.parent == @
      @stretchableWidgetContainer._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @stretchableWidgetContainer._applyExtent new Point @width() - 2 * @externalPadding, @height() - 2 * @externalPadding

    world.maybeEnableTrackChanges()
    @fullChanged()

    @_markLayoutAsFixed()

  _applyExtent: (aPoint) ->
    super
    @_reLayoutSelf()

  hasStartingContentBeenChangedByUser: ->
    @stretchableWidgetContainer?.ratio?

  closeFromContainerFrame: (containerWindow) ->

    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceToWdgt containerWindow
      # there is no real contents to save
      containerWindow.fullDestroy()
    else if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()

  _constrainToRatio: ->
    if @layoutSpecDetails?
      @layoutSpecDetails.canSetHeightFreely = false
      # force a resize, so the slide and the window
      # it's in will take the right ratio, and hence
      # the content will take the whole window it's in.
      # Note that the height of 0 here is ignored since
      # "_setWidthSizeHeightAccordingly" will
      # calculate the height.
      if @stretchableWidgetContainer?.ratio?
        @_applyExtent new Point @width(), 0

  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    # the frame shows the docked toolbar (and the pencil glyph) on this call
    @parent?.showEditModeInBar?()
    @dragsDropsAndEditingEnabled = true
    @stretchableWidgetContainer._enableDragsDropsAndEditingNoSettle @


  # while in editing mode, the slide can take any dimension
  # and if the content has already a decided ratio then
  # the container will adjust the content within the given
  # space so that the content will keep ratio.
  #
  # However, when NOT in editing mode, then we
  # want the content to force the ratio of the window
  # it might be in, so that
  # 1) it takes the whole window rather than a
  #    a letterboxed part, so it looks neat
  # 2) if we drop the slide in
  #    a document then it will take a height proportional
  #    to the given width, which is what looks natural.
  _setWidthSizeHeightAccordingly: (newWidth) ->
    if @layoutSpecDetails?.canSetHeightFreely
     return super  # Path B: propagate the resulting height. See Widget._setWidthSizeHeightAccordingly.

    if !@stretchableWidgetContainer?
     return super

    if !@stretchableWidgetContainer.ratio?
     return super

    @_applyExtent new Point newWidth, Math.round(newWidth / @stretchableWidgetContainer.ratio)
    @height()

  # §4.1 pure measure (sizing-model unification U3-B): mirrors _setWidthSizeHeightAccordingly
  # above -- the slide is ratio-locked to its container's ratio when NOT freely-editable,
  # base width-invariant otherwise. No mutation, no seam.
  preferredExtentForWidth: (availW) ->
    if @layoutSpecDetails?.canSetHeightFreely then return super
    if !@stretchableWidgetContainer? then return super
    if !@stretchableWidgetContainer.ratio? then return super
    new Point availW, Math.round(availW / @stretchableWidgetContainer.ratio)


  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget

  _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()
    @dragsDropsAndEditingEnabled = false
    @stretchableWidgetContainer._disableDragsDropsAndEditingNoSettle @
    @_invalidateLayout()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @_createNewStretchablePanelNoSettle()

    @_invalidateLayout()

  _reactToChildPickedUp: (_reactToChildPickedUp) ->
    if _reactToChildPickedUp == @stretchableWidgetContainer
      @_createNewStretchablePanelNoSettle()
      @_invalidateLayout()

  # same as simpledocumentscrollpanel, you can lock the contents.
  # worth factoring it out as a mixin?
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addEditingLockMenuEntries menu, @childrenNotHandlesNorCarets()
