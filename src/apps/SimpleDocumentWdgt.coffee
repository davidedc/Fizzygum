# This simple-named widget is a user facing widget that
# provides viewing and editing capabilities for "documents"...
# where documents are stacks of items that must stay within
# a certain width, but can stretch for any height.

class SimpleDocumentWdgt extends Widget


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

  # Shared builder for the one-shot "*InfoWdgt" info documents (Docs / Dashboards / Slides / Generic-panel /
  # Patch-programming / Drawings / Super-toolbar / Windows). It lays out the common frame — the icon +
  # centred title + divider header, then the per-subclass body via the `buildBody sdspw` callback, then the
  # window footer (place centred, set the window title, lock editing, set the once-only `world[flagName]`,
  # monkey-patch close-to-destroy, position next to nextToThisWidget) — and RETURNS the FrameWdgt
  # (WindowsToolbarInfoWdgt's caller captures it; the other callers discard it). Each subclass's thin
  # @createNextTo keeps its own once-only guard FIRST (so nothing is built on a repeat call) and constructs
  # `simpleDocument` + `iconWidget` itself (so every `new X` literal stays in the subclass file for the
  # dependency finder), then passes them in.
  @_buildInfoDocNextTo: (nextToThisWidget, flagName, simpleDocument, iconWidget, title, windowTitle, buildBody) ->
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw._applyMoveTo new Point 114, 10
    sdspw._applyExtent new Point 365, 405

    iconWidget._applyExtent new Point 85, 85
    sdspw.setContents iconWidget, 5
    iconWidget.layoutSpecDetails.setGrow 0
    iconWidget.layoutSpecDetails.setAlignmentToCenter()

    titleWidget = new SimplePlainTextWdgt(
      title,nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    titleWidget.alignCenter()
    titleWidget.setFontSize 22
    titleWidget.isEditable = true
    titleWidget.enableSelecting()
    sdspw.add titleWidget

    sdspw.addDivider()

    buildBody sdspw

    wm = new FrameWdgt simpleDocument
    wm._applyExtent new Point 365, 405
    wm._moveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName windowTitle

    simpleDocument.disableDragsDropsAndEditing()
    world[flagName] = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerFrame = (containerWindow) ->
      containerWindow.destroy()

    wm._moveToSideOf nextToThisWidget
    wm._rememberFractionalSituationInHoldingPanel()

    return wm

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

  closeFromContainerFrame: (containerWindow) ->

    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceToWdgt containerWindow
      # there is no real contents to save
      containerWindow.fullDestroy()
    else if !world.anyReferenceToWdgt containerWindow
      prompt = new SaveShortcutPromptWdgt @, containerWindow
      prompt.popUpAtHand()
    else
      containerWindow.close()


  # The text-editing toolbar is FRAME-owned (Frame-model plan §5.C): the
  # enclosing FrameWdgt builds this variant into its toolbar-slot and
  # shows/hides it as this document's edit mode flips (via
  # showEditModeInBar/showViewModeInBar, which this document already drives).
  buildToolbar: ->
    new TextToolbarWdgt

  # PUBLIC self-settling wrapper: build the whole subtree settle-free, then settle ONCE at the end
  # (orphan-settledness -- `new SimpleDocumentWdgt()` returns settled). Crucially the single flush runs
  # AFTER @simpleDocumentScrollPanel is wired, so _reLayout never reads it while still nil -- which is
  # exactly the crash this fixes: under the orphan-settles change an early add()/setContents() settle ran
  # SimpleDocumentWdgt._reLayout with @simpleDocumentScrollPanel == nil (-> "reading 'parent'"). The
  # nested build inside the core (the SimpleDocumentScrollPanelWdgt construction's setContents) runs
  # INSIDE this settle and DEFERS as orphan-in-flush, so construction is O(1) flushes.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @simpleDocumentScrollPanel = new SimpleDocumentScrollPanelWdgt

    startingContent = new SimplePlainTextWdgt(
      @startingText,nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    @simpleDocumentScrollPanel.setContents startingContent, 5
    startingContent.isEditable = true
    startingContent.enableSelecting()

    @_addNoSettle @simpleDocumentScrollPanel

    @_invalidateLayout()

  # I coordinate drags/drops/editing for my scroll panel, which delegates its
  # enable/disable up to me (replacing its `@parent instanceof SimpleDocumentWdgt`
  # test with this query). (type-test-elimination campaign)
  coordinatesDragsDropsAndEditingForChildren: ->
    true

  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    # the frame shows the docked toolbar (and the pencil glyph) on this call
    @parent?.showEditModeInBar?()
    @dragsDropsAndEditingEnabled = true
    @simpleDocumentScrollPanel._enableDragsDropsAndEditingNoSettle @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget

  _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()
    @dragsDropsAndEditingEnabled = false
    @simpleDocumentScrollPanel._disableDragsDropsAndEditingNoSettle @
    @_invalidateLayout()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyBounds newBoundsForThisLayout

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

    # the scroll panel takes the whole padded body -- the text toolbar lives in
    # the enclosing frame's toolbar-slot (§5.C), not in this document
    if @simpleDocumentScrollPanel.parent == @
      @simpleDocumentScrollPanel._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @simpleDocumentScrollPanel._applyExtent new Point @width() - 2 * @externalPadding, @height() - 2 * @externalPadding


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()

  # same as simpledocumentscrollpanel, you can lock the contents.
  # worth factoring it out as a mixin?
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addEditingLockMenuEntries menu, @childrenNotHandlesNorCarets()

