class SlidesMakerWdgt extends Widget

  stretchablePanel: nil
  scrollingTools: nil

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

  constructor: ->
    debugger
    super
    @buildAndConnectChildren()
    @invalidateLayout()

  colloquialName: ->   
    "Slides maker"

  representativeIcon: ->
    new PaintBucketIconWdgt()

  rawSetExtent: (aPoint) ->
    super
    @reLayout()

  closeFromContainerWindow: (containerWindow) ->
    if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()


  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    # stretchablePanel
    @createNewStretchablePanel()

    # tools -------------------------------
    @scrollingTools = new ScrollPanelWdgt new ToolPanelWdgt()
    @add @scrollingTools

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

    if @scrollingTools.parent == @
      @scrollingTools.fullRawMoveTo new Point @left() + @externalPadding, labelBottom
      @scrollingTools.rawSetExtent new Point 115, @height() - 2 * @externalPadding


    # stretchablePanel --------------------------
    stretchablePanelWidth = @width() - @scrollingTools.width() - 2*@externalPadding - @internalPadding
    b = @bottom() - (2 * @externalPadding)
    stretchablePanelHeight =  @height() - 2 * @externalPadding
    stretchablePanelBottom = labelBottom + stretchablePanelHeight
    stretchablePanelLeft = @scrollingTools.right() + @internalPadding

    if @stretchablePanel.parent == @
      @stretchablePanel.fullRawMoveTo new Point stretchablePanelLeft, labelBottom
      @stretchablePanel.setExtent new Point stretchablePanelWidth, stretchablePanelHeight

    # ----------------------------------------------


    trackChanges.pop()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

