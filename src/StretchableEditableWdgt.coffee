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
    @buildAndConnectChildren()
    @invalidateLayout()

  colloquialName: ->
    "Generic panel"

  representativeIcon: ->
    new GenericPanelIconWdgt


  createToolsPanel: ->

  createNewStretchablePanel: ->
    @stretchableWidgetContainer = new StretchableWidgetContainerWdgt
    @add @stretchableWidgetContainer


  reLayout: ->
    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
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
      @stretchableWidgetContainer.fullRawMoveTo new Point stretchableWidgetContainerLeft, labelBottom
      @stretchableWidgetContainer.setExtent new Point stretchableWidgetContainerWidth, stretchableWidgetContainerHeight

    # ----------------------------------------------


    world.maybeEnableTrackChanges()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true

  rawSetExtent: (aPoint) ->
    super
    @reLayout()

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
      # "rawSetWidthSizeHeightAccordingly" will
      # calculate the height.
      if @stretchableWidgetContainer?.ratio?
        @rawSetExtent new Point @width(), 0

  enableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.makePencilYellow?()
    @dragsDropsAndEditingEnabled = true
    @createToolsPanel()
    @stretchableWidgetContainer.enableDragsDropsAndEditing @


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
  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    if @layoutSpecDetails?.canSetHeightFreely
     super
     return

    if !@stretchableWidgetContainer?
     super
     return

    if !@stretchableWidgetContainer.ratio?
     super
     return

    @rawSetExtent new Point newWidth, Math.round(newWidth / @stretchableWidgetContainer.ratio)


  disableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.makePencilClear?()
    @dragsDropsAndEditingEnabled = false
    if @toolsPanel?
      @toolsPanel.unselectAll?()
      @toolsPanel.destroy()
      @toolsPanel = nil
    @stretchableWidgetContainer.disableDragsDropsAndEditing @
    @invalidateLayout()

  buildAndConnectChildren: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @createNewStretchablePanel()
    @createToolsPanel()

    @invalidateLayout()

  childPickedUp: (childPickedUp) ->
    if childPickedUp == @stretchableWidgetContainer
      @createNewStretchablePanel()
      @invalidateLayout()

  # same as simpledocumentscrollpanel, you can lock the contents.
  # worth factoring it out as a mixin?
  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if !@dragsDropsAndEditingEnabled
        menu.addMenuItem "enable editing", true, @, "enableDragsDropsAndEditing", "lets you drag content in and out"
      else
        menu.addMenuItem "disable editing", true, @, "disableDragsDropsAndEditing", "prevents dragging content in and out"

    menu.removeConsecutiveLines()
