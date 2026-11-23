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
#   - losing its payload, by any door, builds a fresh one of its kind, in its mode and at its extent,
#     rather than falling back to the empty-window placeholder.
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
    # the close-from-bar press (a top-level bar-button event handler), at event time and outside any
    # settle: each branch that ends me is ONE settle round my own core, as Widget.fullDestroy and
    # Widget.close are, so the world is settled after the press
    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceOrWireIntoWdgt @
      @_settleLayoutsAfter => @_fullDestroyNoSettle()
    else if !world.anyReferenceOrWireIntoWdgt @
      prompt = new SaveShortcutPromptWdgt @, @
      prompt.popUpAtHand()
    else
      @_settleLayoutsAfter => @_closeNoSettle()

  # Losing the payload rebuilds a FRESH one of my kind, in MY mode and in MY box: drops stay disabled
  # (the frame is occupied again), my mode and my extent stay put, and my title is my kind's name
  # (_titleForContents, which the rebuild's fresh title piece asks), as at my birth.
  #   MY MODE is my payload's (FrameWdgt.isInEditMode), so it is read off the one that left, before I
  # let go of it, and put back through my own mode core once the fresh one is mounted: that core takes
  # the payload to view mode by the payload's own core, and my strip's toggle and my docked bands
  # follow. A fresh payload is born in edit mode, which needs nothing.
  #   MY EXTENT: I am no newborn window taking its first content's size (the first placement a
  # free-floating frame hugs) -- I have my size, so the fresh payload's placement is captured here, at
  # its mount, and my arrange fits IT to ME, as at every later re-fit.
  #   NOT during my own teardown (the flag): constructing a fresh child inside the destroy-until-empty
  # iteration never terminates (§5.B B3 case law).
  _resetToDefaultContents: ->
    return if @_beingFullDestroyed
    wasInEditMode = @isInEditMode()
    @_retireDockedFramesNoSettle()
    @contents = @_makeStartingPayload()
    @_buildAndConnectChildrenNoSettle()
    @_disableDragsDropsAndEditingNoSettle() unless wasInEditMode
    @contents.contentStackSpec().captureInitialPlacement @contents, @
