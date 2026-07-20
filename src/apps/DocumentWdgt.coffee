# The framed DOCUMENT citizen (Frame-model plan §5.B, owner decision D2): a
# text document IS its window. This FrameWdgt subclass builds its naked
# payload (a SimpleDocumentScrollPanelWdgt seeded with one editable starting
# paragraph) and declares only the per-kind knowledge: the text toolbar
# variant, the "Docs Maker" identity, and the save-or-destroy close policy.
# The frame does ALL the chrome work, and the PAYLOAD's own enable/disable
# cores own the edit mode (the frame reads @contents.dragsDropsAndEditingEnabled
# and is notified via showEdit/ViewModeInBar) -- deliberately NO mode state and
# NO layout code here. Replaces the fused SimpleDocumentWdgt, whose
# coordination relays dissolved into the frame<->payload protocols (§5.B B-iii).

class DocumentWdgt extends FrameWdgt

  providesAmenitiesForEditing: true

  startingText: "Your text here."

  constructor: ->
    super @_makeStartingPayload()

  # The naked document payload. The scroll-panel class stays generic/UNSEEDED
  # (bare-panel fixtures depend on that), so the CITIZEN seeds the starting
  # paragraph -- exactly what the fused class's build core did.
  _makeStartingPayload: ->
    scrollPanel = new SimpleDocumentScrollPanelWdgt
    startingContent = new SimpleTextWdgt(
      @startingText,nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    scrollPanel.setContents startingContent, 5
    startingContent.isEditable = true
    startingContent.enableSelecting()
    scrollPanel

  colloquialName: ->
    "Docs Maker"

  # the kind names the window -- the base hook would title from the payload's
  # colloquialName ("document")
  _titleForContents: (aWdgt) ->
    @colloquialName()

  representativeIcon: ->
    new TypewriterIconWdgt

  # the frame docks this variant in its toolbar-slot (§5.C)
  buildToolbar: ->
    new TextToolbarWdgt

  hasStartingContentBeenChangedByUser: ->
    !(
      @contents.contents.children.length == 1 and
      @contents.contents.children[0] instanceof SimpleTextWdgt and
      @contents.contents.children[0].text == @startingText
    )

  # The save-or-destroy close policy (§5.E E2: the shared body lives on
  # FrameWdgt now; this is the citizen's 'saveOrAsk' hook). The citizen IS the
  # window, so the save prompt takes it in both roles -- the FolderWindowWdgt shape.
  _closeFromFrameBarWhenSaveOrAsk: ->
    @_saveOrAskThenCloseCitizen()

  # A citizen never falls back to the empty-window placeholder: losing the
  # payload (picked up / destroyed / closed) rebuilds a FRESH one of my kind.
  # Drops stay disabled (the frame is occupied again) and the title/extent
  # stay put. NOT during my own teardown (the flag): constructing a fresh
  # child inside the destroy-until-empty iteration never terminates.
  _resetToDefaultContents: ->
    return if @_beingFullDestroyed
    @_destroyToolbarNoSettle()
    @contents = @_makeStartingPayload()
    @_buildAndConnectChildrenNoSettle()
