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
#     rather than falling back to the empty-window placeholder, and keeps its bands, its own
#     toolbar's among them;
#   - it holds an EDIT MODE, which its strip's toggle switches between the pencil and the eye
#     (providesAmenitiesForEditing, below).
#   A subclass states: _makeStartingPayload, colloquialName, buildToolbar,
# hasStartingContentBeenChangedByUser (whether the user has put anything in it) and the picture its
# icons show, representativeIcon (its own, or its payload's through FrameWdgt's).
#   A document opened by an Examples door or as an info page sets closeFromFrameBarPolicy to 'close'
# or 'destroy', which bypasses the save offer (FrameWdgt.closeFromFrameBar).

class MakerDocumentWdgt extends FrameWdgt

  # Every Maker's document is made in edit mode and used in view mode, so every one offers the
  # toggle (FrameWdgt.offersEditToggle reads this) and, being the window that holds the mode, makes
  # its own chrome answer to it (Widget.sitsInViewModeContent). Declared here, on the frame, because
  # a framed citizen provides the amenities itself, whatever its payload is; the mode's FLAG is the
  # payload's (FrameWdgt.isInEditMode), and the payload's own cores do what a flip means for its
  # kind (a document's items melt into the page, a panel's lock, a sheet puts its headers away).
  providesAmenitiesForEditing: true

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
  #   MY BANDS stay, my own toolbar's among them: my KIND declares that toolbar (buildToolbar), not the
  # payload that left, and the fresh payload is of my kind. So that band keeps its side, its place in
  # its side's list and its collapse, and I keep my tool (no palette arrives to make me adopt what the
  # hand holds). The rebuild docks a fresh one only where no band my content brought is docked: my own
  # band floated away, or emptied of its toolbar, which clears its record
  # (FrameWdgt._buildAndConnectChildrenNoSettle asks for the bands my content brought).
  #   NOT during my own teardown (the flag): constructing a fresh child inside the destroy-until-empty
  # iteration never terminates (§5.B B3 case law).
  _resetToDefaultContents: ->
    return if @_beingFullDestroyed
    wasInEditMode = @isInEditMode()
    @contents = @_makeStartingPayload()
    @_buildAndConnectChildrenNoSettle()
    @_disableDragsDropsAndEditingNoSettle() unless wasInEditMode
    @contents.contentStackSpec().captureInitialPlacement @contents, @
