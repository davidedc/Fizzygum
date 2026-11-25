# The ROW OF INSPECTORS a window holds: the first on the subject a person asked to inspect, each
# next one on a subject chosen in the one to its left (showChoice). I am the inspector as a tool:
# "Inspect" opens me (Widget.spawnInspector).
#   I have no layout of my own. My inspectors (InspectorWdgt) are the elements of a horizontal
# DIVISION row (StackLayoutEngine), a splitter between two of them (StackElementsSizeAdjustingWdgt),
# so they divide my width, a person drags a splitter -- or the split button standing right of it in
# the next inspector's header (SplitGripWdgt) -- to re-divide it, and my least width is theirs and my
# splitters' together (Widget.getRecursiveMinDim). I paint the body every inspector of mine stands
# on (inspectorBodyFill); they paint only their rules.
#   A CHOICE replaces whatever stands right of the inspector it was made in, in ONE settle: the
# subject that inspector's neighbour already shows is reloaded there, any other subject gets a new
# inspector, and no subject only removes what stands right of the chooser. A split a person moved
# stays where they put it while a view of the same kind takes the place right of it, and is undone
# when another kind takes that place or none does (_showNextToNoSettle: one rule, from what a drag on
# a split trades). A choice that leaves me narrower than my inspectors'
# least widths WIDENS my window when it stands on the desktop, as far as the desktop's right edge;
# past that, or in any other holder, my inspectors narrow. Nothing is ever dropped from my left.
#   My SPLITTERS are derived from my inspectors, never placed by hand: exactly one between two
# inspectors that stand side by side, none anywhere else (_reconcileSplittersNoSettle), re-derived
# at every choice and whenever a child of mine leaves me, however it leaves -- a choice's removal, a
# person's "Pick up" or "Destroy" of an inspector or of a splitter -- and each inspector then
# re-derives its split button from them, a button a person took out of its header (or put back after
# its title) included. A child a person attaches to me is no moment of its own: it waits for the next
# of those, an inspector attached to me standing with no splitter until then. My
# CELLS, the only children that reconcile reads or touches, are my inspectors
# (every child of mine that answers showsSubject) and my splitters (my division cells that answer the
# split's solve, maxDimsPuttingMyLeadingEdgeAt); any other child of mine (a halo's handle, an "Edit
# layout" slot, a widget attached to me that is neither) is left where it is. My name is my first
# inspector's, so when a reconcile finds another first inspector than the one my name was last taken
# from, the window whose content I am re-titles itself (FrameWdgt.noteContentsNameMayHaveChanged); a
# title something else gave that window (a shortcut's) stands until then.
class InspectorRowWdgt extends ClippingWdgt

  # I CLIP my children -- their paint and their pointer targeting -- to my rectangle, the house way
  # (a ClippingWdgt, as every panel, viewport and frame is): a control my width leaves no room for is
  # cut at my edge, where it shows nothing and catches no press, the same with no window as in one (a
  # target never extends beyond the widget that owns it, visual-design-system §4.2). Squeezed below my
  # least width, my division row shrinks my cells, but a member editor's footer band places its Save
  # at the button's own size, past the edge of an editor narrower than that: I am what cuts it. In a
  # window I lie flush against, it changes no pixel: the window clips its content at the box it gives
  # it, which is my box, and nothing of mine stands outside my box while I am at least my least
  # width. Opaque, my silhouette is my box, so my children add nothing to the shadow I cast with no
  # window.

  # am I being destroyed as a whole (_fullDestroyNoSettle)? Then a child of mine leaving me is my
  # teardown, and nothing of mine is reconciled or rebuilt on the way out (as FrameWdgt's flag)
  _beingFullDestroyed: undefined
  # is my reconcile running? Its own splitter removals tell me a child left, and must not reconcile
  # again inside it. True only inside one synchronous call, so no copy or save carries it true.
  _reconcilingSplitters: false
  # the inspector my name was last taken from (my first: colloquialName), so my reconcile has my window
  # re-title itself only when my first inspector is another one. Set by the reconcile my build runs,
  # which tells no one: I stand in no window yet, and a window reads my name itself as it opens me.
  _inspectorNamingMe: undefined

  # A row built with no window gives itself a usable extent, and Widget.spawnInspector opens my
  # window at this same extent: one place states it.
  constructor: (subject) ->
    super()
    @__commitExtent new Point 760, 480
    @color = WorldWdgt.theme.inspectorBodyFill
    @appearance = new RectangularAppearance @
    @_buildAndConnectChildren subject

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns
  # settled). The subject is handed to the build rather than read from a field of mine, where the
  # canonical pair reads one: it is my first inspector's subject, held by that inspector
  # (InspectorWdgt.inspectedObject), and a field of mine holding it would go on naming it after that
  # inspector is gone.
  _buildAndConnectChildren: (subject) ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle subject

  _buildAndConnectChildrenNoSettle: (subject) ->
    @_addInspectorNoSettle new InspectorWdgt subject

  # my inspectors, left to right: my children that are inspectors (my other children are splitters,
  # or not mine to arrange)
  inspectors: ->
    (child for child in @children when child.showsSubject?)

  # my window's title: my first inspector's
  colloquialName: ->
    @inspectors()[0]?.colloquialName() ? "Inspector"

  # WHERE A CHOICE GOES. `chooser` -- an inspector, or a view inside one -- chose `subject`: the
  # inspector right of the chooser's shows it (showNextTo). Chosen again, the subject already there
  # is RELOADED (a member's editor takes its saved text back, as one step of its undo history); any
  # other subject replaces it, and everything further right goes either way. No subject (undefined)
  # only removes what stands right of the chooser: what its view stood for has gone, or it chose a
  # row that names no member (MemberListWdgt.selectionFromList).
  #   A chooser in no row -- an inspector or a view a person picked out of its window -- opens the
  # subject in a window of its own, a row of its own.
  #   Every gesture asks me AFTER its own settle, never inside it: my row settles once per choice.
  @showChoice: (chooser, subject) ->
    inspector = chooser
    inspector = inspector.parent  until !inspector? or inspector.showsSubject?
    row = inspector?.parent
    if row?.showNextTo?
      row.showNextTo inspector, subject
    else if subject?
      fresh = new InspectorRowWdgt subject
      world.openFrameWith fresh, fresh.extent(), world.hand.position().subtract new Point 50, 100
    return

  # `subject` shown right of `inspector`, mine, as one settle (showChoice says what that means).
  showNextTo: (inspector, subject) ->
    @_settleLayoutsAfter => @_showNextToNoSettle inspector, subject

  # Every inspector right of `inspector` is destroyed but the next one, when that one already shows
  # the subject: it is reloaded instead. A new subject gets a new inspector at my end.
  #   THE SPLIT A PERSON SET follows from what a drag does. A drag on a split TRADES most width between
  # the two cells beside it, their sum unchanged (StackElementsSizeAdjustingWdgt's
  # maxDimsPuttingMyLeadingEdgeAt). So across the BOUNDARY a choice removes everything right of,
  # exactly ONE trade stands: what the cell left of it took from the cell right of it. The removed
  # cells may have traded among themselves too, but those trades cancel in their sum, so what they gave
  # away, summed (InspectorWdgt.mostWidthGivenAway: each one's default most width less its own), is
  # that one trade -- 0 where the split at the boundary was never dragged, negative where the cell left
  # of it gave width away. One HEIR settles it (_removeInspectorsNoSettle). A new inspector whose view
  # asks the weight the first removed one's asked (an editor where an editor stood, a list where a list
  # stood) takes its default less that trade: the split stands where the person put it, the cell left
  # of the boundary is untouched, and any trade the removed cell had made further right goes with the
  # cells it was made with. Otherwise -- another kind of view takes that place, or none does -- the
  # trade is UNDONE: the cell left of the boundary gives it back, the chooser, or, when the subject is
  # chosen again, the kept neighbour, the removed cells being the ones right of it. Its trade with its
  # own left neighbour is untouched, so this holds in a row of any length, and an inspector a choice
  # leaves alone is back at its default. A "Pick up" or a "Destroy" of an inspector is no choice, and
  # re-boxes nothing: my reconcile, which also runs inside layout passes, writes no box, so the
  # neighbour such a departure leaves keeps the box it had.
  #   Then my structure is reconciled, whatever the choice removed or added -- a reload or a choice of
  # no subject may do neither -- so a split button a person took out of a header of mine, or put back
  # after its title, leads that header again after every choice, and a child a person attached to me
  # is reconciled too (InspectorWdgt._reconcileSplitGripNoSettle; with nothing out of place it changes
  # nothing). Then my window is widened if my inspectors do not fit it, the header that button opens
  # counted: inside this same settle, never in a layout pass.
  _showNextToNoSettle: (inspector, subject) ->
    following = @_inspectorsAfter inspector
    if subject? and following[0]?.showsSubject subject
      @_removeInspectorsNoSettle following[1..], following[0]
      following[0]._reloadNoSettle()
    else
      fresh = new InspectorWdgt subject  if subject?
      sameKind = fresh? and fresh.view.rowSlackWeight() is following[0]?.view.rowSlackWeight()
      @_removeInspectorsNoSettle following, (if sameKind then fresh else inspector)
      @_addInspectorNoSettle fresh  if fresh?
    @_reconcileSplittersNoSettle()
    @_widenMyWindowToFitNoSettle()

  # my inspectors right of `inspector`, in order; none when it is no inspector of mine
  _inspectorsAfter: (inspector) ->
    mine = @inspectors()
    at = mine.indexOf inspector
    return [] if at < 0
    mine[at + 1..]

  # `inspector` added after my last inspector, as an element of my row, then my splitters reconciled:
  # a splitter between it and the inspector before it, and its split button.
  _addInspectorNoSettle: (inspector) ->
    last = @inspectors().pop()
    atIndex = if last? then @children.indexOf(last) + 1 else undefined
    @_addNoSettle inspector, atIndex: atIndex, layoutSpec: inspector.divisionBox()
    @_reconcileSplittersNoSettle()

  # `inspectors`, all of them right of one boundary of mine, destroyed, each telling me it left
  # (_reactToChildRemoved), which reconciles my splitters every time: the one before each goes with
  # it. First, while they still stand, the one trade across that boundary -- what they gave away,
  # summed -- is given up by `heir`, the cell that keeps it or gives it back (_showNextToNoSettle says
  # which, and why the sum is that trade). Nothing is written when there is nothing to settle.
  _removeInspectorsNoSettle: (inspectors, heir) ->
    trade = 0
    trade += each.mostWidthGivenAway() for each in inspectors
    heir._giveUpMostWidthNoSettle trade  unless trade is 0
    each._fullDestroyNoSettle() for each in inspectors
    return

  # MY CELLS: my children that are an inspector or one of my splitters, in order -- the only children
  # my reconcile reads or touches
  _myCells: ->
    (child for child in @children when child.showsSubject? or @_isMySplitter child)

  # Is `child` a SPLITTER of mine? Asked of the capability its users need, never of a type: a cell of
  # my division row that answers the split's solve (maxDimsPuttingMyLeadingEdgeAt), the one question
  # a split button asks of the splitter before its inspector (SplitGripWdgt). Another cell that takes a
  # drag in place (a palette or a slider's button dropped on an "Edit layout" slot of mine) answers no
  # such solve, so it is never destroyed as a stray splitter nor dragged as one; an "Edit layout" slot
  # is a cell that answers none either; a halo's handle and a widget attached to me stand free.
  _isMySplitter: (child) ->
    (child.layoutSpec?.isDivisionElement?() is true) and child.maxDimsPuttingMyLeadingEdgeAt?

  # The splitter standing before `inspector` among my cells, or undefined: what its split button drags
  # (InspectorWdgt.splitterBeforeMe asks). An "Edit layout" slot between the two is no cell of mine,
  # so it does not stand between them.
  splitterBefore: (inspector) ->
    cells = @_myCells()
    before = cells[cells.indexOf(inspector) - 1]
    before  if before? and @_isMySplitter before

  # THE ONE RULE of my splitters: exactly one between two of my inspectors that stand side by side,
  # none anywhere else -- then each inspector re-derives its split button from it. My name is my first
  # inspector's (colloquialName), and what changed my children may have changed which inspector is
  # first (a person's "Pick up" of it): when it is another than the one my name was last taken from
  # (_inspectorNamingMe), the window whose content I am re-derives its title from my name, through its
  # label's NoSettle cores, settling nothing; while it is the same, that window's title is left as it
  # stands. Run under a flag, in a try/finally: the splitters it destroys tell me they left, and that
  # must not reconcile again inside this run. Builds nothing when nothing is out of place, so a child
  # leaving me in the middle of a layout pass (an "Edit layout" slot the pass takes away) finds nothing
  # to do; a split button a person took out is out of place, and its inspector rebuilds it only outside
  # a pass (InspectorWdgt._reconcileSplitGripNoSettle).
  _reconcileSplittersNoSettle: ->
    @_reconcilingSplitters = true
    try
      @_dropStraySplittersNoSettle()
      @_addMissingSplittersNoSettle()
      mine = @inspectors()
      inspector._reconcileSplitGripNoSettle() for inspector in mine
      unless mine[0] is @_inspectorNamingMe
        @_inspectorNamingMe = mine[0]
        @parent.noteContentsNameMayHaveChanged()  if @parent?.isMyContents?(@) and @parent.noteContentsNameMayHaveChanged?
    finally
      @_reconcilingSplitters = false
    return

  # every splitter of mine that does not stand between two inspectors destroyed: one first among my
  # cells, one following another splitter, and one after my last inspector
  _dropStraySplittersNoSettle: ->
    kept = []
    for cell in @_myCells()
      if @_isMySplitter(cell) and !(kept[kept.length - 1]?.showsSubject?)
        cell._fullDestroyNoSettle()
      else
        kept.push cell
    last = kept[kept.length - 1]
    last._fullDestroyNoSettle()  if last? and @_isMySplitter last
    return

  # a splitter added between two of my inspectors that stand side by side among my cells
  _addMissingSplittersNoSettle: ->
    previous = undefined
    for cell in @_myCells()
      if cell.showsSubject? and previous?.showsSubject?
        splitter = new StackElementsSizeAdjustingWdgt()
        @_addNoSettle splitter, atIndex: @children.indexOf(cell), layoutSpec: splitter.divisionBox()
      previous = cell
    return

  # A CHILD OF MINE LEFT ME (destroyed, or re-homed: a "Pick up", an "Attach", a drop into another
  # widget -- or re-added to me elsewhere, which also tells me). Not while I am destroyed or being
  # destroyed as a whole, and not while my own reconcile is removing it. An inspector that LEFT -- not
  # destroyed, not back in me -- re-derives its split button where it stands; then my splitters
  # are reconciled.
  _reactToChildRemoved: (child) ->
    return if @destroyed or @_beingFullDestroyed or @_reconcilingSplitters
    child._reconcileSplitGripNoSettle?()  unless child.destroyed or child.parent is @
    @_reconcileSplittersNoSettle()

  # Destroyed as a whole: flagged at entry, so every child my teardown destroys finds me being torn
  # down (_reactToChildRemoved) and nothing is built into a dying row.
  _fullDestroyNoSettle: ->
    @_beingFullDestroyed = true
    super

  # A choice that leaves me narrower than my cells' least widths together widens my WINDOW by what is
  # missing -- but no further than the desktop's right edge: past that, my inspectors narrow (the
  # stack's first regimes). Only a window whose whole content I am, and which stands on the desktop
  # (its parent is the world), where its bounds are the desktop's own px; a window in any other holder
  # -- a panel, a document, a dock, a transform island -- is that holder's to place and size, and my
  # inspectors narrow in it. The frame's own core, inside my choice's settle: a public setExtent here
  # would be a second settle. My least width reads division boxes, which are fields, so it is current
  # inside the very settle that added an inspector; my width is the one I was given.
  _widenMyWindowToFitNoSettle: ->
    missing = @getRecursiveMinDim().x - @width()
    return unless missing > 0 and @parent?.isMyContents?(@) and @parent.parent is world
    room = Math.max 0, world.right() - @parent.screenBounds().right()
    widening = Math.min missing, room
    return unless widening > 0
    @parent._setExtentNoSettle @parent.extent().add new Point widening, 0
    return
