# MakerDocumentWdgt — the shared base of the DOCUMENTS the desktop's Makers make: a text document
# (DocumentWdgt), a panel and its kinds (GenericPanelWdgt, and through it SlideWdgt, DashboardWdgt,
# PatchProgrammingWdgt and ImageWdgt) and a spreadsheet (SpreadsheetWdgt). Each one IS its window, a
# framed citizen (Frame-model plan §5.B, owner decision D2): the frame does the chrome, and the
# subclass builds its payload and states its kind.
#   What every such document does the same way lives HERE, so a kind cannot be left without it:
#   - its window is titled with its kind's name (colloquialName), not its payload's;
#   - closed from its bar, it offers to be SAVED as an icon when the user has put something in it,
#     is destroyed when they have not, and simply closes when a reference or a wire reaches into it
#     (_closeFromFrameBarWhenSaveOrAsk below);
#   - losing its payload (picked up, destroyed or closed) builds a fresh one of its kind rather
#     than falling back to the empty-window placeholder.
#   A subclass states: _makeStartingPayload, colloquialName, buildToolbar,
# hasStartingContentBeenChangedByUser (whether the user has put anything in it) and the picture its
# icons show, representativeIcon (its own, or its payload's through FrameWdgt's).
#   A document opened by an Examples door or as an info page sets closeFromFrameBarPolicy to 'close'
# or 'destroy', which bypasses the save offer (FrameWdgt.closeFromFrameBar).

class MakerDocumentWdgt extends FrameWdgt

  constructor: ->
    super @_makeStartingPayload()

  # the kind names the window -- the base hook would title it from the payload's colloquialName
  # ("document", "stretchable panel", ...)
  _titleForContents: (aWdgt) ->
    @colloquialName()

  # The 'saveOrAsk' close (FrameWdgt.closeFromFrameBar). Nothing put in it and nothing reaching in:
  # destroy it. Something put in it and nothing reaching in: offer to save it, the save prompt
  # taking me in both roles (I am the window and the thing saved). Something reaching in: just close
  # it, since what references or wires into it keeps it reachable already.
  _closeFromFrameBarWhenSaveOrAsk: ->
    # public-call-sanctioned + nosettle-sanctioned: this IS the close-from-bar action (a top-level
    # bar-button event handler), so fullDestroy and close are the public self-settling close verbs
    # it means to trigger. Reaching the NoSettle cores would leave the world unsettled after a
    # top-level bar press.
    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceOrWireIntoWdgt @
      @fullDestroy()
    else if !world.anyReferenceOrWireIntoWdgt @
      prompt = new SaveShortcutPromptWdgt @, @
      prompt.popUpAtHand()
    else
      @close()

  # Losing the payload rebuilds a FRESH one of my kind: drops stay disabled (the frame is occupied
  # again) and the title and extent stay put. NOT during my own teardown (the flag): constructing a
  # fresh child inside the destroy-until-empty iteration never terminates (§5.B B3 case law).
  _resetToDefaultContents: ->
    return if @_beingFullDestroyed
    @_retireDockedFramesNoSettle()
    @contents = @_makeStartingPayload()
    @_buildAndConnectChildrenNoSettle()
