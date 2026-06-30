# This simple-named widget is a user facing widget that
# provides viewing and editing capabilities for "documents"...
# where documents are stacks of items that must stay within
# a certain width, but can stretch for any height.

class SimpleDocumentWdgt extends Widget


  toolsPanel: nil
  defaultContents: nil
  textWidget: nil

  simpleDocumentScrollPanel: nil

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

  startingText: "Your text here."


  constructor: (@defaultContents = "") ->
    super new Point 368, 335
    @_buildAndConnectChildren()

  colloquialName: ->
    "Docs Maker"

  representativeIcon: ->
    new TypewriterIconWdgt

  # Smart-placement protocol (see WidgetCreatorAndSmartPlacerOnClickMixin): a
  # SimpleDocument appends the click-created widget to its scroll panel.
  acceptsSmartPlacedWidgets: ->
    @dragsDropsAndEditingEnabled

  smartPlace: (widgetToBePlaced, creator) ->
    @simpleDocumentScrollPanel.add widgetToBePlaced
    @simpleDocumentScrollPanel.scrollToBottom()
    @simpleDocumentScrollPanel.bringToForeground()
    creator.bringToForeground()

  hasStartingContentBeenChangedByUser: ->
    !(
      @simpleDocumentScrollPanel.contents.children.length == 1 and
      @simpleDocumentScrollPanel.contents.children[0] instanceof SimplePlainTextWdgt and
      @simpleDocumentScrollPanel.contents.children[0].text == @startingText
    )

  closeFromContainerWindow: (containerWindow) ->

    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceToWdgt containerWindow
      # there is no real contents to save
      containerWindow.fullDestroy()
    else if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()


  # PUBLIC self-settling wrapper: build the whole subtree settle-free, then settle ONCE at the end
  # (orphan-settledness -- `new SimpleDocumentWdgt()` returns settled). Crucially the single flush runs
  # AFTER @simpleDocumentScrollPanel is wired, so _reLayout never reads it while still nil -- which is
  # exactly the crash this fixes: under the orphan-settles change an early add()/setContents() settle ran
  # SimpleDocumentWdgt._reLayout with @simpleDocumentScrollPanel == nil (-> "reading 'parent'"). Every
  # nested build inside the core (createToolsPanel's adds, the SimpleDocumentScrollPanelWdgt construction's
  # setContents) runs INSIDE this settle and DEFERS as orphan-in-flush, so construction is O(1) flushes.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()


    @createToolsPanel()
    @simpleDocumentScrollPanel = new SimpleDocumentScrollPanelWdgt

    startingContent = new SimplePlainTextWdgt(
      @startingText,nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    @simpleDocumentScrollPanel.setContents startingContent, 5
    startingContent.isEditable = true
    startingContent.enableSelecting()

    @_addNoSettle @simpleDocumentScrollPanel

    @_invalidateLayout()

  createToolsPanel: ->
    @toolsPanel = new HorizontalMenuPanelWdgt
    @toolsPanel.strokeColor = nil
    @toolsPanel._applyExtentAndNotify new Point 300,10


    @toolsPanel.add new ChangeFontButtonWdgt @
    @toolsPanel.add new BoldButtonWdgt
    @toolsPanel.add new ItalicButtonWdgt
    @toolsPanel.add new FormatAsCodeButtonWdgt
    @toolsPanel.add new IncreaseFontSizeButtonWdgt
    @toolsPanel.add new DecreaseFontSizeButtonWdgt

    @toolsPanel.add new AlignLeftButtonWdgt
    @toolsPanel.add new AlignCenterButtonWdgt
    @toolsPanel.add new AlignRightButtonWdgt

    @toolsPanel.add new TemplatesButtonWdgt

    @add @toolsPanel
    @toolsPanel.disableDragsDropsAndEditing()

    @dragsDropsAndEditingEnabled = true
    @_invalidateLayout()

  editButtonPressedFromWindowBar: ->
    if @dragsDropsAndEditingEnabled
      @disableDragsDropsAndEditing @
    else
      @enableDragsDropsAndEditing @

  # I coordinate drags/drops/editing for my scroll panel, which delegates its
  # enable/disable up to me (replacing its `@parent instanceof SimpleDocumentWdgt`
  # test with this query). (type-test-elimination campaign)
  coordinatesDragsDropsAndEditingForChildren: ->
    true

  enableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.makePencilYellow?()
    @dragsDropsAndEditingEnabled = true
    @createToolsPanel()
    @simpleDocumentScrollPanel.enableDragsDropsAndEditing @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.makePencilClear?()
    @toolsPanel.destroy()
    @toolsPanel = nil
    @dragsDropsAndEditingEnabled = false
    @simpleDocumentScrollPanel.disableDragsDropsAndEditing @
    @_invalidateLayout()

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  _reLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    if @_handleCollapsedStateShouldWeReturn() then return

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

    availableHeight = @height() - 2 * @externalPadding
    simpleDocumentScrollPanelTop = @top() + @externalPadding
    toolsPanelHeight = 0

    if @dragsDropsAndEditingEnabled
      toolsPanelHeight = 35
      availableHeight -= @internalPadding
      simpleDocumentScrollPanelTop += toolsPanelHeight + @internalPadding

    simpleDocumentScrollPanelHeight = availableHeight - toolsPanelHeight


    if @toolsPanel?.parent == @
      @toolsPanel._applyMoveToAndNotify new Point @left() + @externalPadding, @top() + @externalPadding
      @toolsPanel._applyExtentAndNotify new Point @width() - 2 * @externalPadding, toolsPanelHeight

    if @simpleDocumentScrollPanel.parent == @
      @simpleDocumentScrollPanel._applyMoveToAndNotify new Point @left() + @externalPadding, simpleDocumentScrollPanelTop
      @simpleDocumentScrollPanel._applyExtentAndNotify new Point @width() - 2 * @externalPadding, simpleDocumentScrollPanelHeight


    world.maybeEnableTrackChanges()
    @fullChanged()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    super
    @markLayoutAsFixed()

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

