# The framed DOCUMENT citizen (Frame-model plan §5.B, owner decision D2): a
# text document IS its window. One of the Makers' documents (MakerDocumentWdgt,
# which owns the title, the save-or-destroy close and the payload rebuild every
# such document shares): this class builds its naked payload (a
# DocumentViewportWdgt seeded with one editable starting paragraph) and states
# only the per-kind knowledge: the text toolbar variant, the "Docs Maker"
# identity, and what counts as the user having changed it. The frame does ALL
# the chrome work, and the PAYLOAD's own enable/disable cores own the edit mode
# (the frame reads @contents.dragsDropsAndEditingEnabled and is notified via
# showEdit/ViewModeInBar) -- deliberately NO mode state and NO layout code
# here. Replaces the fused SimpleDocumentWdgt, whose coordination relays
# dissolved into the frame<->payload protocols (§5.B B-iii).

class DocumentWdgt extends MakerDocumentWdgt

  providesAmenitiesForEditing: true

  startingText: "Your text here."

  # The naked document payload. The viewport class stays generic/UNSEEDED
  # (bare-panel fixtures depend on that), so the CITIZEN seeds the starting
  # paragraph -- one of the viewport's own paragraphs (getNormalParagraph), set in
  # at the page's item spacing.
  _makeStartingPayload: ->
    viewport = new DocumentViewportWdgt
    viewport.setContents viewport.getNormalParagraph @startingText
    viewport

  colloquialName: ->
    "Docs Maker"

  representativeIcon: ->
    new TypewriterIconWdgt

  # the frame docks this variant in its toolbar-slot (§5.C)
  buildToolbar: ->
    new TextToolbarWdgt

  # changed = anything but the one starting paragraph, still reading the starting text
  hasStartingContentBeenChangedByUser: ->
    !(
      @contents.contents.children.length == 1 and
      @contents.contents.children[0] instanceof SimpleTextWdgt and
      @contents.contents.children[0].text == @startingText
    )
