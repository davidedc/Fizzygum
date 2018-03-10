class StretchableEditableWdgt extends Widget

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
    @parent?.makePencilYellow?()
    @dragsDropsAndEditingEnabled = true
    @createToolsPanel()
    @stretchableWidgetContainer.enableDragsDropsAndEditing @

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
    @toolsPanel.unselectAll?()
    @toolsPanel.destroy()
    @toolsPanel = nil
    @stretchableWidgetContainer.disableDragsDropsAndEditing @
    @invalidateLayout()

    if @layoutSpecDetails?
      @layoutSpecDetails.canSetHeightFreely = false
      # force a resize, so the slide and the window
      # it's in will take the right ratio, and hence
      # the content will take the whole window it's in.
      # Note that the height of 0 here is ignored since
      # "rawSetWidthSizeHeightAccordingly" will
      # calculate the height.
      if @stretchableWidgetContainer?.ratio?
        # try to keep the current width and just adjust the height.
        # HOWEVER it often happens that just doing that is not OK
        # because the end result is taller than the screen
        # which is *very* annoying because the window becomes difficult
        # to handle and resize, SO calculate a width such that the
        # height doesn't become problematic
        if @parent? and (@parent instanceof WindowWdgt) and @parent.parent? and @parent.parent == world
          newWidth = @parent.width()
          # TODO magic number here
          extraHeightOfWindowChrome = 20
          if newWidth / @stretchableWidgetContainer.ratio + extraHeightOfWindowChrome > world.height()
            newWidth = (world.height() - extraHeightOfWindowChrome) * @stretchableWidgetContainer.ratio
            newWidth = Math.round(Math.min newWidth, world.width())
          @parent.rawSetExtent new Point newWidth, 0
        else
          @rawSetExtent new Point @width(), 0

  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
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
