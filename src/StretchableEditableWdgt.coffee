class StretchableEditableWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  toolsPanel: nil
  stretchableWidgetContainer: nil

  # the external padding is the space between the edges
  # of the container and all of its internals. The reason
  # you often set this to zero is because windows already put
  # contents inside themselves with a little padding, so this
  # external padding is not needed. Useful to keep it
  # separate and know that it's working though.
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
    widgetToBePlaced.rememberFractionalSituationInHoldingPanel()
    @stretchableWidgetContainer.bringToForeground()
    creator.bringToForeground()


  # empty base -- subclasses (PatchProgramming/Dashboards/SimpleSlide/ReconfigurablePaint) override the core.
  # A core (not a public wrapper): the only callers are cores (_enableDragsDropsAndEditingNoSettle,
  # _buildAndConnectChildrenNoSettle), so there is no public createToolsPanel to self-settle.
  _createToolsPanelNoSettle: ->

  createNewStretchablePanel: ->
    @stretchableWidgetContainer = new StretchableWidgetContainerWdgt
    @add @stretchableWidgetContainer


  _reLayoutSelf: ->
    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    labelBottom = @top() + @externalPadding


    # stretchableWidgetContainer --------------------------

    stretchableWidgetContainerWidth = @width() - 2*@externalPadding
    
    stretchableWidgetContainerHeight =  @height() - 2 * @externalPadding
    stretchableWidgetContainerLeft = @left() + @externalPadding

    if @stretchableWidgetContainer.parent == @
      @stretchableWidgetContainer._applyMoveTo new Point stretchableWidgetContainerLeft, labelBottom
      @stretchableWidgetContainer._applyExtent new Point stretchableWidgetContainerWidth, stretchableWidgetContainerHeight

    # ----------------------------------------------


    world.maybeEnableTrackChanges()
    @fullChanged()

    @markLayoutAsFixed()

  _applyExtent: (aPoint) ->
    super
    @_reLayoutSelf()

  hasStartingContentBeenChangedByUser: ->
    @stretchableWidgetContainer?.ratio?

  closeFromContainerWindow: (containerWindow) ->

    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceToWdgt containerWindow
      # there is no real contents to save
      containerWindow.fullDestroy()
    else if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()

  editButtonPressedFromWindowBar: ->
    if @dragsDropsAndEditingEnabled
      @disableDragsDropsAndEditing @
    else
      @enableDragsDropsAndEditing @

  constrainToRatio: ->
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
    @parent?.showEditModeInBar?()
    @dragsDropsAndEditingEnabled = true
    @_createToolsPanelNoSettle()
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


  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget

  _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()
    @dragsDropsAndEditingEnabled = false
    if @toolsPanel?
      # DETACH-then-teardown (mirror of the enable sibling-reorder). For ReconfigurablePaint's RadioButtonsHolder
      # toolsPanel, unselectAll?() fires a synthetic w.toggle() whose escalation reaches SwitchButtonWdgt's
      # SELF-SETTLING mouseClickLeft -- the SECOND transitive-settle blind spot (unselectAll's OWN body has no
      # @_settleLayoutsAfter, so an own-body grep passes it, but it settles via toggle -> mouseClickLeft, same shape
      # as stopEditing). removeFromTree FIRST orphans the toolsPanel subtree's root, so that settle DEFERS instead of
      # throwing in this flush; the un-inject still lands (it targets the overlayCanvas, which stays attached in the
      # stretchableWidgetContainer). Non-radio toolsPanels (ScrollPanel) have no unselectAll -- there the detach is
      # just settle-neutral structural-removal-before-destroy (removeFromTree repaints the vacated region).
      @toolsPanel.removeFromTree()
      @toolsPanel.unselectAll?()
      @toolsPanel._destroyNoSettle()
      @toolsPanel = nil
    @stretchableWidgetContainer._disableDragsDropsAndEditingNoSettle @
    @_invalidateLayout()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # createNewStretchablePanel does a public @add on the ORPHAN (defers in-flush) and _createToolsPanelNoSettle
  # is a non-settling core; both are flushed once here. createNewStretchablePanel stays self-settling when
  # called post-construction (from _reactToChildPickedUp on the attached widget).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @createNewStretchablePanel()
    @_createToolsPanelNoSettle()

    @_invalidateLayout()

  _reactToChildPickedUp: (_reactToChildPickedUp) ->
    if _reactToChildPickedUp == @stretchableWidgetContainer
      @createNewStretchablePanel()
      @_invalidateLayout()

  # same as simpledocumentscrollpanel, you can lock the contents.
  # worth factoring it out as a mixin?
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if !@dragsDropsAndEditingEnabled
        menu.addMenuItem "enable editing", true, @, "enableDragsDropsAndEditing", "lets you drag content in and out"
      else
        menu.addMenuItem "disable editing", true, @, "disableDragsDropsAndEditing", "prevents dragging content in and out"

    menu.removeConsecutiveLines()
