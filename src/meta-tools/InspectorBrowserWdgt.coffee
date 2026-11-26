# THE BROWSER: the inspector as a TOOL. "Inspect" opens me (Widget.spawnInspector), in a window of my
# default extent (openInAWindowOn), and I stand with no window too (`world.add new InspectorBrowserWdgt
# target`), resized then by the halo, as any widget.
#   I hold a SEQUENCE of inspectors (InspectorWdgt; inspectors): the first on the subject a person asked
# to inspect, each next one on a subject chosen in the one before it (showChoice). A CHOICE replaces
# whatever follows the inspector it was made in, in ONE settle: the subject the next inspector already
# shows is reloaded there, any other subject gets a new inspector, and no subject only removes what
# follows the chooser (showNextTo). Nothing else of mine ever removes an inspector.
#   WHERE each inspector stands is mine to say, never the sequence's: every one of them stands in my SET
# (InspectorRowWdgt, my `row`), a row of columns, each new one at its end (_placeNoSettle). The set owns
# its structure, the splitters between its columns and each column's split button, and tells me when a
# reconcile of it may have changed my first inspector (_noteFirstInspectorMayHaveChangedNoSettle).
#   My set is the PLANE of its own viewport (InspectorRowViewportWdgt, my `viewport`), which scrolls it
# sideways: each column stands at its own width, the last one taking the room the others leave, and
# a set wider than its viewport overflows it rather than narrowing a column. After a choice the
# column it shows is brought into view (revealLastColumn).
#   Top to bottom, the cells of one vertical DIVISION stack (StackLayoutEngine), so I have no layout of
# my own: my set's viewport, my one cell, which takes my whole box.
#   I paint the BODY every part of the tool in me stands on (inspectorBodyFill), and say so to my parts
# (laysTheInspectorBodyUnderItsParts); a part of the tool standing anywhere else paints a body of its
# own (InspectorBodyAppearance).
#   My NAME is my first inspector's (colloquialName), and the window whose content I am takes its
# title from it: when my first inspector is another one than the one my name was last taken from --
# my first column gone from my set, by a person's "Pick up", "Destroy" or "Attach" of it, which reaches
# only my set (a choice never makes it: it removes only inspectors after the one it was made in) --
# that window re-titles itself (FrameWdgt.noteContentsNameMayHaveChanged); a title something else gave
# that window (a shortcut's) stands until then.
class InspectorBrowserWdgt extends ClippingWdgt

  # I CLIP my children -- their paint and their pointer targeting -- to my rectangle, the house way
  # (a ClippingWdgt, as every panel, viewport and frame is), the same with no window as in one. My one
  # cell, my set's viewport, takes my whole box and clips my set there again: the set is never
  # narrower than its viewport, so no column of it is squeezed below what its controls need, and what
  # of it does not fit is scrolled out of view, never cut. In a window I lie flush against, my clip
  # changes no pixel: the window clips its content at the box it gives it, which is my box. Opaque, my
  # silhouette is my box, so my children add nothing to the shadow I cast with no window.

  # my SET, the row of columns my inspectors stand in (an InspectorRowWdgt): built once, with me, as
  # my viewport's plane
  row: undefined
  # my SET'S VIEWPORT (an InspectorRowViewportWdgt), which holds my set as its plane and scrolls it
  # sideways: built once, with me, around my set, as my one cell
  viewport: undefined
  # the inspector my name was last taken from (my first: colloquialName), so my window re-titles itself
  # only when my first inspector is another one (_noteFirstInspectorMayHaveChangedNoSettle). Set as my
  # build places my first inspector, which tells no one: I stand in no window yet, and a window reads my
  # name itself as it opens me.
  _inspectorNamingMe: undefined

  # THE DEFAULT EXTENT, its one statement: a browser built with no window gives itself this extent, and
  # a window opened on a fresh browser opens at it (openInAWindowOn). Tall enough that a widget's or a
  # class's member list, under a header, a chooser, its toggles and its footer, shows five whole rows. A
  # method, never a class-level Point: a class constant may not name another class.
  @defaultExtent: ->
    new Point 760, 528

  # The subject is my identity, my one positional parameter: the subject of my first inspector.
  constructor: (subject) ->
    super()
    @__commitExtent InspectorBrowserWdgt.defaultExtent()
    @color = WorldWdgt.theme.inspectorBodyFill
    @appearance = new RectangularAppearance @
    @_buildAndConnectChildren subject

  # I lay the inspector's body under my parts (my appearance paints it, under all of them), so a part
  # of the tool standing in me paints none of its own (InspectorBodyAppearance asks, as it paints).
  laysTheInspectorBodyUnderItsParts: -> true

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns
  # settled): my set, empty, then its viewport around it, my one cell, then my first inspector,
  # placed in my set. The subject is handed to the build rather than read from a field of mine, where
  # the canonical pair reads one: it is my first inspector's subject, held by that inspector
  # (InspectorWdgt.inspectedObject), and a field of mine holding it would go on naming it after that
  # inspector is gone.
  _buildAndConnectChildren: (subject) ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle subject

  _buildAndConnectChildrenNoSettle: (subject) ->
    @row = new InspectorRowWdgt()
    @viewport = new InspectorRowViewportWdgt @row
    @_addNoSettle @viewport, layoutSpec: @viewport.divisionBox('y')
    @_placeNoSettle new InspectorWdgt subject

  # MY SEQUENCE, in order: the columns of my set, left to right (InspectorRowWdgt.columns), never an
  # inspector a person attached into a column or onto my set free-floating. Whatever reads the
  # sequence asks me, never my set: my rule of choice, my name, the door on a member.
  inspectors: ->
    @row.columns()

  # my window's title: my first inspector's
  colloquialName: ->
    @inspectors()[0]?.colloquialName() ? "Inspector"

  # THE BROWSER `widget` STANDS IN: its nearest ancestor that answers showNextTo, or undefined (a
  # column, a view or a set a person picked out of me stands in none). From a column of mine the climb
  # passes my set and my set's viewport, which answer no such thing. Asked by showChoice, from the
  # chooser's inspector, and by my set, to tell me what its reconcile changed.
  @holding: (widget) ->
    holder = widget?.parent
    holder = holder.parent  until !holder? or holder.showNextTo?
    holder

  # WHERE A CHOICE GOES. `chooser` -- an inspector, or a view inside one -- chose `subject`: the
  # inspector following the chooser's in its browser's sequence shows it (showNextTo). Chosen again,
  # the subject already there is RELOADED (a member's editor takes its saved text back, as one step of
  # its undo history); any other subject replaces it, and everything following it goes either way. No
  # subject (undefined) only removes what follows the chooser: what its view stood for has gone, or it
  # chose a row that names no member (MemberListWdgt.selectionFromList).
  #   Two climbs: from the chooser to the nearest ancestor that answers showsSubject (its inspector,
  # itself included), then from that inspector to the browser it stands in (holding). A chooser whose
  # inspector is in no browser's SEQUENCE (inspectors) stands under no browser, whatever holds it -- an
  # inspector or a view a person picked out of its window, an inspector a person attached into a
  # column or onto a set free-floating -- and opens the subject in a browser of its own, in a window
  # (openInAWindowOn): a sequence it is no step of has no inspector following it to show the choice.
  #   Every gesture asks me AFTER its own settle, never inside it: a browser settles once per choice,
  # and then brings the column that shows the choice into view (revealLastColumn).
  @showChoice: (chooser, subject) ->
    inspector = chooser
    inspector = inspector.parent  until !inspector? or inspector.showsSubject?
    browser = InspectorBrowserWdgt.holding inspector
    if browser? and inspector in browser.inspectors()
      browser.showNextTo inspector, subject
      browser.revealLastColumn()
    else if subject?
      InspectorBrowserWdgt.openInAWindowOn subject
    return

  # A BROWSER ON `subject` IN A WINDOW of its own, at my default extent (the browser states it, and its
  # window opens at it), by the hand: the ONE statement of that opening, for the door
  # (Widget.spawnInspector) and for a choice made under no browser (showChoice). Answers the browser.
  @openInAWindowOn: (subject) ->
    browser = new InspectorBrowserWdgt subject
    world.openFrameWith browser, browser.extent(), world.hand.position().subtract new Point 50, 100
    browser

  # THE MEMBER `name` CHOSEN IN MY FIRST INSPECTOR, as a person's click on its row chooses it: the
  # door that opens me ON a member (Widget.spawnInspector's opts.member). My first inspector's view
  # chooses it when it lists members (MemberListWdgt.chooseMember); an inspector on one member (a
  # MemberRef subject: a lone editor) lists none and chooses nothing. No settle of my own: each step
  # the choice takes settles itself, one after the other.
  chooseMember: (name) ->
    @inspectors()[0]?.view?.chooseMember? name
    return

  # `subject` shown after `inspector`, mine, as one settle (showChoice says what that means).
  showNextTo: (inspector, subject) ->
    @_settleLayoutsAfter => @_showNextToNoSettle inspector, subject

  # MY SET'S LAST COLUMN brought whole into view (InspectorRowViewportWdgt.revealColumn): asked by
  # showChoice once a choice's settle (showNextTo) has returned, never inside it, since the scroll
  # lands on the set that settle laid out. After any choice the last column is the one the choice
  # shows, or the chooser itself after a choice of no subject. A choice that removed columns needs
  # nothing more: the columns it keeps stand where they stood, and my set's viewport ends its arrange
  # on its clamp, which brings an offset past the new end of its scroll back to that end, a rest point.
  revealLastColumn: ->
    last = @inspectors().pop()
    @viewport.revealColumn last  if last?
    return

  # Every inspector following `inspector` is destroyed but the next one, when that one already shows
  # the subject: it is reloaded instead. A new subject gets a new inspector, placed where I place one
  # (_placeNoSettle). A column's width is its own (InspectorWdgt.getDesiredDim), so a choice leaves
  # every column it keeps at the width it had, but for my set's spare room, which goes to whichever
  # column is then my set's last (InspectorRowWdgt.takesMySlack).
  #   Then my set's structure is reconciled, whatever the choice removed or added -- a reload or a
  # choice of no subject may do neither -- so a split button a person took out of a header, or put back
  # after its title, leads that header again after every choice, and a child a person attached to my
  # set is reconciled too (InspectorWdgt._reconcileSplitGripNoSettle; with nothing out of place it
  # changes nothing); its reconcile tells me, at its end, that my first inspector may be another one.
  _showNextToNoSettle: (inspector, subject) ->
    following = @_inspectorsAfter inspector
    if subject? and following[0]?.showsSubject subject
      @_removeInspectorsNoSettle following[1..]
      following[0]._reloadNoSettle()
    else
      fresh = new InspectorWdgt subject  if subject?
      @_removeInspectorsNoSettle following
      @_placeNoSettle fresh  if fresh?
    @row._reconcileSplittersNoSettle()

  # my inspectors following `inspector`, in order; none when it is no inspector of mine
  _inspectorsAfter: (inspector) ->
    mine = @inspectors()
    at = mine.indexOf inspector
    return [] if at < 0
    mine[at + 1..]

  # WHERE `inspector`, a fresh one of my sequence, stands: at my set's end
  # (InspectorRowWdgt._addColumnNoSettle, which reconciles my set's splitters: a splitter between it and
  # the column before it, and its split button). A core: my build and a choice place one inside their
  # own settle.
  _placeNoSettle: (inspector) ->
    @row._addColumnNoSettle inspector

  # `inspectors`, all of them following one boundary of my sequence, destroyed, each telling my set it
  # left (InspectorRowWdgt._reactToChildRemoved), which reconciles its splitters every time: the one
  # before each goes with it.
  _removeInspectorsNoSettle: (inspectors) ->
    each._fullDestroyNoSettle() for each in inspectors
    return

  # MY FIRST INSPECTOR MAY BE ANOTHER ONE, told by my set at the end of every reconcile of it (a
  # choice's, and a person's "Pick up" or "Destroy" of a column's, which reaches only my set): when it
  # is another than the one my name was last taken from, the window whose content I am re-derives its
  # title from my name, through its label's NoSettle cores, settling nothing; while it is the same,
  # that window's title is left as it stands.
  _noteFirstInspectorMayHaveChangedNoSettle: ->
    first = @inspectors()[0]
    return if first is @_inspectorNamingMe
    @_inspectorNamingMe = first
    @parent.noteContentsNameMayHaveChanged()  if @parent?.isMyContents?(@) and @parent.noteContentsNameMayHaveChanged?
    return
