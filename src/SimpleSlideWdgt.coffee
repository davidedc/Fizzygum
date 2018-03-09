class SimpleSlideWdgt extends Widget

  stretchablePanel: nil
  toolsPanel: nil

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
    debugger
    super
    @buildAndConnectChildren()
    @invalidateLayout()

  colloquialName: ->   
    "Simple slide"

  representativeIcon: ->
    new SimpleSlideIconWdgt()

  rawSetExtent: (aPoint) ->
    super
    @reLayout()

  closeFromContainerWindow: (containerWindow) ->
    if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()

  editButtonPressedFromWindowBar: ->
    if @dragsDropsAndEditingEnabled
      @disableDragsDropsAndEditing @
    else
      @enableDragsDropsAndEditing @

  enableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @dragsDropsAndEditingEnabled = true
    @createToolsPanel()
    @stretchablePanel.enableDragsDropsAndEditing @

    if @layoutSpecDetails?
      @layoutSpecDetails.canSetHeightFreely = true

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

    if !@stretchablePanel?
     super
     return

    if !@stretchablePanel.ratio?
     super
     return

    @rawSetExtent new Point newWidth, newWidth / @stretchablePanel.ratio


  disableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @dragsDropsAndEditingEnabled = false
    @toolsPanel.destroy()
    @toolsPanel = nil
    @stretchablePanel.disableDragsDropsAndEditing @
    @invalidateLayout()

    if @layoutSpecDetails?
      @layoutSpecDetails.canSetHeightFreely = false
      # force a resize, so the slide and the window
      # it's in will take the right ratio, and hence
      # the content will take the whole window it's in.
      # Note that the height of 0 here is ignored since
      # "rawSetWidthSizeHeightAccordingly" will
      # calculate the height.
      if @stretchablePanel?.ratio?
        @rawSetExtent new Point @width(), 0


  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @createToolsPanel()
    @createNewStretchablePanel()


    @invalidateLayout()

  createToolsPanel: ->
    # tools -------------------------------
    @toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt()

    @toolsPanel.add new TextBoxCreatorButtonWdgt()
    @toolsPanel.add new ExternalLinkCreatorButtonWdgt()
    @toolsPanel.add new VideoPlayCreatorButtonWdgt()

    @toolsPanel.add new WorldMapCreatorButtonWdgt()
    @toolsPanel.add new USAMapCreatorButtonWdgt()

    @toolsPanel.add new RectangleMorph()

    @toolsPanel.add new MapPinIconWdgt()

    @toolsPanel.add new DestroyIconMorph()
    @toolsPanel.add new ScratchAreaIconMorph()
    @toolsPanel.add new FloraIconMorph()
    @toolsPanel.add new ScooterIconMorph()
    @toolsPanel.add new HeartIconMorph()

    @toolsPanel.add new FizzygumLogoIconWdgt()
    @toolsPanel.add new FizzygumLogoWithTextIconWdgt()
    @toolsPanel.add new VaporwaveBackgroundIconWdgt()
    @toolsPanel.add new VaporwaveSunIconWdgt()

    @toolsPanel.add new ArrowNIconWdgt()
    @toolsPanel.add new ArrowSIconWdgt()
    @toolsPanel.add new ArrowWIconWdgt()
    @toolsPanel.add new ArrowEIconWdgt()
    @toolsPanel.add new ArrowNWIconWdgt()
    @toolsPanel.add new ArrowNEIconWdgt()
    @toolsPanel.add new ArrowSWIconWdgt()
    @toolsPanel.add new ArrowSEIconWdgt()

    @toolsPanel.disableDragsDropsAndEditing()
    @add @toolsPanel
    @dragsDropsAndEditingEnabled = true
    @invalidateLayout()

  createNewStretchablePanel: ->
    @stretchablePanel = new StretchablePanelContainerWdgt()
    @add @stretchablePanel

  childPickedUp: (childPickedUp) ->
    if childPickedUp == @stretchablePanel
      @createNewStretchablePanel()
      @invalidateLayout()

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
    trackChanges.push false

    # label
    labelLeft = @left() + @externalPadding
    labelTop = @top() + @externalPadding
    labelRight = @right() - @externalPadding
    labelWidth = labelRight - labelLeft
    labelBottom = @top() + @externalPadding

    # tools -------------------------------

    b = @bottom() - (2 * @externalPadding)

    if @toolsPanel?.parent == @
      @toolsPanel.fullRawMoveTo new Point @left() + @externalPadding, labelBottom
      @toolsPanel.rawSetExtent new Point 95, @height() - 2 * @externalPadding


    # stretchablePanel --------------------------

    stretchablePanelWidth = @width() - 2*@externalPadding
    
    if @dragsDropsAndEditingEnabled
      stretchablePanelWidth -= @toolsPanel.width() + @internalPadding

    b = @bottom() - (2 * @externalPadding)
    stretchablePanelHeight =  @height() - 2 * @externalPadding
    stretchablePanelBottom = labelBottom + stretchablePanelHeight
    if @dragsDropsAndEditingEnabled
      stretchablePanelLeft = @toolsPanel.right() + @internalPadding
    else
      stretchablePanelLeft = @left() + @externalPadding

    if @stretchablePanel.parent == @
      @stretchablePanel.fullRawMoveTo new Point stretchablePanelLeft, labelBottom
      @stretchablePanel.setExtent new Point stretchablePanelWidth, stretchablePanelHeight

    # ----------------------------------------------


    trackChanges.pop()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

  # same as simpledocumentscrollpanel, you can lock the contents.
  # worth factoring it out as a mixin?
  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    debugger
    super

    childrenNotHandlesNorCarets = @children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if !@dragsDropsAndEditingEnabled
        menu.addMenuItem "enable editing", true, @, "enableDragsDropsAndEditing", "lets you drag content in and out"
      else
        menu.addMenuItem "disable editing", true, @, "disableDragsDropsAndEditing", "prevents dragging content in and out"

    menu.removeConsecutiveLines()

