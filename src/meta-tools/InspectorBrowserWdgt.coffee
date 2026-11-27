# THE BROWSER: the inspector as a TOOL. "Inspect" opens me (Widget.spawnInspector), in a window of my
# default extent (openInAWindowOn), and I stand with no window too (`world.add new InspectorBrowserWdgt
# target`), resized then by the halo, as any widget.
#   I hold a SEQUENCE of inspectors (InspectorWdgt; inspectors): the first on the subject a person asked
# to inspect, each next one on a subject chosen in the one before it (showChoice). A CHOICE replaces
# whatever follows the inspector it was made in, in ONE settle: the subject the next inspector already
# shows is reloaded there, any other subject gets a new inspector, and no subject only removes what
# follows the chooser (showNextTo). Nothing else of mine ever removes an inspector.
#   WHERE each inspector stands is mine to say, never the sequence's (_placeNoSettle). My LISTS stand in
# my SET (InspectorRowWdgt, my `row`), a row of columns, each new one at its end. My BODY -- the
# inspector of my sequence that shows one thing as text (InspectorWdgt.showsOneText: its subject a
# member), always its last -- stands where my SETTING says (bodyPlace, fixed as I am built): "below"
# puts it under my set, at my full width, a divider between them that a person drags; "beside" leaves
# it my set's last column. The set owns its structure, the splitters between its columns and each
# column's split button, and tells me when a reconcile of it may have changed my sequence
# (_noteMySequenceMayHaveChangedNoSettle); MY structure -- my trail, and, with my body below, my body's
# place -- is mine (_reconcileMyStructureNoSettle).
#   My set is the PLANE of its own viewport (InspectorRowViewportWdgt, my `viewport`), which scrolls it
# sideways: each column stands at its own width, the last one taking the room the others leave, and
# a set wider than its viewport overflows it rather than narrowing a column. After a choice the
# inspector it shows is brought into view when it is a column of my set; one my body shows moves
# nothing (showChoice). A choice that removes columns of my set leaves its scroll where the choice
# found it (_holdMyScrollNoSettle), so nothing slides under a person's second click; a choice that
# removes no column of it keeps that hold (a reload, another member shown in my body: nothing in the
# set changed), and the set's next scroll lets go of it -- the reveal of a column a choice adds, or of a
# step of my trail, when it moves the set; a stroke, as it comes to rest --, and the room it kept then
# closes, as it does once the set's viewport stands at another width than the hold was made at.
#   MY TRAIL, the where-you-are band, names my sequence: one plain button per step of it
# (SimpleButtonWdgt, in order), a drawn chevron between two (MenuRowIndicatorWdgt), each step named as
# the inspector before it names the choice made in it ("Class RectangleWdgt", "Child Rectangle 2":
# InspectorWdgt.nameOfMyChoice), else by its own subject, in sentence case where the words are ours and
# as it is where they are data ("Rectangle", "Point", "color", "RectangleWdgt":
# InspectorWdgt.trailNameOfMySubject), its name read as its header reads its title, so my trail is
# never what stops me opening. A press on a step's button brings the column that step was chosen in
# whole into view, and the row chosen in it into its list's view (revealTrailLevel); a press with Cmd
# held, or the button's "Open in a new inspector" row, opens that step in a new browser of its own
# instead, beside me (toOpenInANewInspectorBy, openInAWindowOn's opts.beside). It is DERIVED,
# never stored: whenever my sequence may have changed, its levels are derived again and, when the band
# standing first in me does not name them, a fresh band stands where it stood
# (_reconcileMyTrailNoSettle), so it holds no name a later change could leave stale. A trail longer
# than my width squeezes its pieces, as every band of the tool does where its window is too narrow for
# it.
#   Top to bottom, the cells of one vertical DIVISION stack (StackLayoutEngine), so I have no layout of
# my own, my trail first, at its band's height (a footer band's, footerBandHeight). With my body
# beside: my set's viewport, which takes the rest of my box, its division box's most unbounded
# (_stateMyViewportBesideNoSettle). With my body
# below: my set's viewport, the STRIP OF LISTS, at the height its division box states (its least, and a
# desired its most equals: natural as I am built, _stateMyStripNoSettle, then whatever a drag of my
# divider states), never below the least height a column of my set needs; my DIVIDER
# (InspectorDividerWdgt, down), which sizes the strip, its finger's tab leading my body's header; and
# my BODY, which takes every pixel the other cells leave. The strip's height is a person's: resizing me
# leaves it where they put it, and only a box too short for every cell's desired size takes some of it
# away, the engine's own way, giving it back as I grow again; a drag of my divider while I am no taller
# than my cells' least sizes states nothing, so the height they stated stands
# (InspectorDividerWdgt.sizeDraggedTo).
#   The body's place is NEVER EMPTY: while nothing shown as one text is chosen it holds an EMPTY BODY,
# an inspector on no subject ("(nothing chosen)", InspectorWdgt), no step of my sequence, which needs
# and desires the height a member's body does, so the strip keeps its height whether a member is chosen
# or not. Whenever my body leaves me I rebuild what is missing -- an empty body, exactly one divider
# right before it, and its tab -- in the reconcile of my structure (_reconcileMyStructureNoSettle): a
# choice that removes it runs that reconcile itself, once, at its end (_showNextToNoSettle), and a
# person's "Pick up" or "Destroy" of it runs it as the body leaves me (_reactToChildRemoved).
#   I paint the BODY every part of the tool in me stands on (inspectorBodyFill), and say so to my parts
# (laysTheInspectorBodyUnderItsParts); a part of the tool standing anywhere else paints a body of its
# own (InspectorBodyAppearance).
#   My NAME is my first inspector's (colloquialName), and the window whose content I am takes its
# title from it: when my first inspector is another one than the one my name was last taken from --
# my first column gone from my set, by a person's "Pick up", "Destroy" or "Attach" of it, which reaches
# only my set, or the body I was opened on gone (a choice never makes it: it removes only inspectors
# after the one it was made in) -- that window re-titles itself (FrameWdgt.noteContentsNameMayHaveChanged);
# a title something else gave that window (a shortcut's) stands until then.
class InspectorBrowserWdgt extends ClippingWdgt

  # I CLIP my children -- their paint and their pointer targeting -- to my rectangle, the house way
  # (a ClippingWdgt, as every panel, viewport and frame is), the same with no window as in one. My set's
  # viewport, a cell of mine, clips my set again at its own box: the set is never narrower than its
  # viewport, so no column of it is squeezed below what its controls need, and what of it does not fit
  # is scrolled out of view, never cut. In a window I lie flush against, my clip changes no pixel: the
  # window clips its content at the box it gives it, which is my box. Opaque, my silhouette is my box,
  # so my children add nothing to the shadow I cast with no window.

  # WHERE MY BODY STANDS (my header says what each means): "below", my default, or "beside". A SETTING,
  # given as I am built (opts.bodyPlace) and never written after, so a copy and a save carry what it was
  # built with (an own field only when given).
  bodyPlace: "below"
  # my SET, the row of columns my inspectors stand in (an InspectorRowWdgt): built once, with me, as
  # my viewport's plane
  row: undefined
  # my SET'S VIEWPORT (an InspectorRowViewportWdgt), which holds my set as its plane and scrolls it
  # sideways: built once, with me, around my set, as the cell after my trail (with my body below, the
  # strip of lists)
  viewport: undefined
  # my TRAIL band (a BandWdgt), my first cell: built afresh, where the one it replaces stood, whenever
  # the levels it names are not my sequence's (_reconcileMyTrailNoSettle). One a person took out
  # of me is theirs, and stays where they put it; the fresh one stands first in me, and this names it.
  trail: undefined
  # the inspector my name was last taken from (my first: colloquialName), so my window re-titles itself
  # only when my first inspector is another one (_noteMySequenceMayHaveChangedNoSettle). Set as my
  # build places my first inspector, which tells no one: I stand in no window yet, and a window reads my
  # name itself as it opens me.
  _inspectorNamingMe: undefined
  # am I being destroyed as a whole (_fullDestroyNoSettle)? Then a child of mine leaving me is my
  # teardown, and nothing of mine is rebuilt on the way out (as my set's flag, InspectorRowWdgt)
  _beingFullDestroyed: undefined
  # am I changing my own cells -- my build, a choice (_showNextToNoSettle), the reconcile of my structure
  # (_reconcileMyStructureNoSettle) or the rebuild of my trail (_rebuildMyTrailNoSettle)? Their own
  # removals tell me a child left, and must not rebuild anything inside them; nor is my trail reconciled
  # inside the first two, each of which ends with one reconcile of my structure, which reconciles it
  # once. True only inside one synchronous call, so no copy or save carries it true.
  _changingMyCells: false

  # THE DEFAULT EXTENT, its one statement: a browser built with no window gives itself this extent, and
  # a window opened on a fresh browser opens at it (openInAWindowOn, which hands it to the window).
  # 1000 x 808: in a window that tall, under my trail band and my strip of lists at its natural 312, my
  # body shows twelve lines of code; on a desktop 768 tall, where the clamp below makes the window 768,
  # still ten. CLAMPED to the desktop's extent (the world's), so a window never opens wider or taller
  # than the desktop it opens on: opening keeps a window's top-left inside the desktop and never
  # shrinks it (WorldWdgt.openFrameWith), so a window larger than the desktop would run past its edges.
  # A method, never a class-level Point: a class constant may not name another class.
  @defaultExtent: ->
    (new Point 1000, 808).min world.extent()

  # WHERE A WINDOW OPENED APART LANDS, this tool's own two numbers (_landingBeside): the gap between it
  # and the window it was opened apart from, and how far it cascades from that window's corner when no
  # side has room.
  @APART_GAP: 16
  @CASCADE_STEP: 48

  # WHERE A WINDOW OPENED APART FROM ANOTHER LANDS, its top-left, read from three values alone:
  # `original`, the box of the window it is opened apart from; `desktop`, the world's box; and `extent`,
  # the new window's (my default extent: defaultExtent). RIGHT of the original, else LEFT of it, their
  # tops level, else BELOW it, their lefts level, APART_GAP between the two -- the first of the three
  # where the whole window lies inside the desktop. Room is the desktop's alone: no other
  # window is read, so where a window lands never hangs on what else stands there. With room on no side,
  # CASCADED: CASCADE_STEP right of and below the original's top-left, a place that may run past the
  # desktop, since opening keeps a window inside it, moving it and never shrinking it
  # (WorldWdgt.openFrameWith). Whole numbers in, a whole point out.
  @_landingBeside: (original, desktop, extent) ->
    gap = InspectorBrowserWdgt.APART_GAP
    sides = [
      (new Point original.right() + gap, original.top())
      (new Point original.left() - gap - extent.x, original.top())
      (new Point original.left(), original.bottom() + gap)
    ]
    for place in sides
      return place  if desktop.containsRectangle place.extent extent
    original.topLeft().add InspectorBrowserWdgt.CASCADE_STEP

  # The subject is my identity, my one positional parameter: the subject of my first inspector.
  # opts.bodyPlace is my setting ("below" or "beside"), assigned only when given, so my class's default
  # stands otherwise (a parameter assigned unconditionally would write undefined over it).
  constructor: (subject, opts = {}) ->
    super()
    @bodyPlace = opts.bodyPlace  if opts.bodyPlace?
    @__commitExtent InspectorBrowserWdgt.defaultExtent()
    @color = WorldWdgt.theme.inspectorBodyFill
    @appearance = new RectangularAppearance @
    @_buildAndConnectChildren subject

  # I lay the inspector's body under my parts (my appearance paints it, under all of them), so a part
  # of the tool standing in me paints none of its own (InspectorBodyAppearance asks, as it paints).
  laysTheInspectorBodyUnderItsParts: -> true

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns
  # settled): my set, empty, then its viewport around it, a cell of mine (its division box stated
  # first, by my setting: with my body below, the strip's height, _stateMyStripNoSettle; beside, a box
  # whose most is unbounded, _stateMyViewportBesideNoSettle), then my first inspector, placed where I
  # place one, while I am changing my cells (the flag: my set's reconcile, which the placing runs,
  # builds no trail of mine yet), then my structure reconciled (_reconcileMyStructureNoSettle): with my body below, an empty
  # body when my first inspector is no body, and my divider before the body; and either way my trail,
  # built there once, my first cell. The subject is handed to the build rather than read from a field
  # of mine, where the canonical pair reads one: it is my first inspector's subject, held by that
  # inspector (InspectorWdgt.inspectedObject), and a field of mine holding it would go on naming it after
  # that inspector is gone.
  _buildAndConnectChildren: (subject) ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle subject

  _buildAndConnectChildrenNoSettle: (subject) ->
    @row = new InspectorRowWdgt()
    @viewport = new InspectorRowViewportWdgt @row
    if @bodyPlace is "below" then @_stateMyStripNoSettle() else @_stateMyViewportBesideNoSettle()
    @_addNoSettle @viewport, layoutSpec: @viewport.divisionBox('y')
    @_changingMyCells = true
    try
      @_placeNoSettle new InspectorWdgt subject
    finally
      @_changingMyCells = false
    @_reconcileMyStructureNoSettle()

  # MY STRIP OF LISTS, with my body below: my set's viewport's division box pins its HEIGHT -- its least,
  # and a desired its most equals (spreadability 0), so no spare room of mine goes to it and my body
  # takes all of it. Its width is no input: my division stack stretches every cell across me. A core on
  # my fresh viewport, before my build adds it (an orphan's box setter schedules nothing).
  #   LEAST, the box's: one whole member row under a member list's bands: header 44 + toggles 48 +
  # verbs 52 (the bands: inspectorHeaderHeight, toggleBandHeight, and footerBandHeight, the height of
  # the list's verbs band, ListVerbsBandWdgt), the rows' panel's padding 4 (memberRowsPanelPadding)
  # and one row 42 (memberRowHeight): 190. The strip's own least is never below the tallest least of
  # my set's columns (InspectorRowViewportWdgt.getMinDim): 236 while a member list stands under a
  # chooser (every widget's column, every class's: header 44, chooser 48, the list's toggles 48, its
  # rows' least 44, its verbs band 52). So my own least, my cells'
  # summed -- my trail's 52, the strip's, my divider's 12 and my body's 96 (header 44, an editor's least
  # 52) -- is 396 while such a column stands, 350 while none does; given less, my division stack
  # squeezes every cell (its first regime).
  #   NATURAL, the height I am built with: the bands' 144 and four rows' 168, 312, which the rows'
  # panel's padding cuts to THREE whole member rows and 38 px of a fourth; in a column with a chooser
  # (48 more) two whole rows and 32 px of a third.
  _stateMyStripNoSettle: ->
    theme = WorldWdgt.theme
    bands = theme.inspectorHeaderHeight + theme.toggleBandHeight + theme.footerBandHeight
    least = bands + theme.memberRowsPanelPadding + theme.memberRowHeight
    natural = bands + 4 * theme.memberRowHeight
    @viewport.setMinAndMaxBoundsAndSpreadability (new Point 0, least), (new Point 0, natural), 0

  # MY SET'S VIEWPORT, with my body beside: the rest of my box under my trail, every spare px of mine,
  # however tall I am. Its division box is the plain one every part of the tool wears -- least and
  # desired 1 x 1, with a spacer's spreadability (InspectorWdgt's, which my body wears below) -- so its
  # most is unbounded, and my division stack's third regime, which hands spare room out by the cells'
  # margins of most over desired, hands all of mine to it: my trail's box has no such margin. Its least
  # and desired heights are no input: the viewport's own answers are never below its set's least height
  # (InspectorRowViewportWdgt.getMinDim, getDesiredDim). A core on my fresh viewport, before my build
  # adds it, as the strip's twin above.
  _stateMyViewportBesideNoSettle: ->
    plain = new Point 1, 1
    @viewport.setMinAndMaxBoundsAndSpreadability plain, plain, DivisionStackLayoutSpec.SPREADABILITY_SPACERS

  # MY SEQUENCE, in order: the columns of my set, left to right (InspectorRowWdgt.columns), never an
  # inspector a person attached into a column or onto my set free-floating; then, with my body below,
  # my body while it shows a subject (an empty body is no step of it: nobody chose it). Derived from my
  # children each time, never stored. Whatever reads the sequence asks me, never my set: my rule of
  # choice, my name, my trail, the door on a member.
  inspectors: ->
    columns = @row.columns()
    body = @_bodyStanding()
    if body?.inspectedObject? then columns.concat [body] else columns

  # MY BODY STANDING BELOW MY SET: with my body below, my own child that is an inspector (it answers
  # showsSubject) and a cell of my division stack -- my set's columns are my set's children, never mine
  # -- or undefined; with my body beside, none ever. An inspector a person attached onto me free-floating
  # is none; of two cells that are inspectors, the first.
  _bodyStanding: ->
    return undefined  unless @bodyPlace is "below"
    (each for each in @_divisionCells() when each.showsSubject?)[0]

  # MY DIVISION CELLS, top to bottom: my children my division stack lays out (their spec a division
  # element's)
  _divisionCells: ->
    (child for child in @children when child.layoutSpec?.isDivisionElement?())

  # Is `child` a DIVIDER of mine? Asked of the capability its users need, never of a type, as my set
  # asks it (InspectorRowWdgt._isMySplitter): a cell of my division stack that answers a divider's solve
  # (sizeDraggedTo). A trading adjuster the halo's "Resize/move…" adds beside a cell of mine answers
  # none, and an "Edit layout" slot is a cell that answers none either.
  _isMySplitter: (child) ->
    (child.layoutSpec?.isDivisionElement?() is true) and child.sizeDraggedTo?

  # MY CELLS: my division cells that are my set's viewport, a divider of mine or an inspector, in order
  # -- the only cells my body's place reads, my trail none of them -- so an "Edit layout" slot between
  # two of them, or a widget a person attached to my stack, does not stand between them (as my set's
  # twin, InspectorRowWdgt._myCells)
  _myCells: ->
    (cell for cell in @_divisionCells() when cell is @viewport or @_isMySplitter(cell) or cell.showsSubject?)

  # THE CELL JUST BEFORE `cell` among my cells, or undefined (first, or no cell of mine)
  _cellBefore: (cell) ->
    cells = @_myCells()
    at = cells.indexOf cell
    cells[at - 1]  if at > 0

  # The divider standing just before `inspector` among my cells, or undefined: what its split button
  # drags (InspectorWdgt._splitterBeforeMe asks) -- my divider, before my body.
  splitterBefore: (inspector) ->
    before = @_cellBefore inspector
    before  if before? and @_isMySplitter before

  # THE CELL `divider` SIZES, splitterBefore's twin: my set's viewport, the strip of lists, while it is
  # the cell just before that divider, or undefined. Asked by the divider as a drag on it, or on its split
  # button, begins and goes on (InspectorDividerWdgt.dragAnchorAt, sizeDraggedTo).
  cellSizedBy: (divider) ->
    @viewport  if @viewport? and @_cellBefore(divider) is @viewport

  # THE MOST `cell` MAY TAKE down me, in whole px: my height less the desired heights of my other
  # division cells, so my stack still fits me at every cell's desired size (the division arrange's third
  # regime, where each of them lies at exactly its desired size), and a divider dragged as far as that
  # stays under the pointer: past it the strip's height would be more than I can give it, and the body
  # would be squeezed. No more than the strip's least, it says I am no taller than my cells' least sizes
  # summed (my other cells' least and desired are one), where my stack squeezes every cell (its first
  # regime) and my divider's solve states nothing. Read from fields and my own height, which no drag of
  # my divider changes. Asked by my divider's solve (InspectorDividerWdgt.sizeDraggedTo, dragAnchorAt).
  mostSizeOf: (cell) ->
    others = 0
    others += each.getDesiredDim().y  for each in @_divisionCells() when each isnt cell
    Math.floor @height() - others

  # THE PLANE MY SCROLL LEAVES STILL: my own -- nothing scrolls my cells -- so a drag on my divider is
  # measured in my plane, where a point mapped in stays put however my set is scrolled (a transform
  # island around me maps into it). Asked by my divider (InspectorDividerWdgt.dragPlane), as my set's twin
  # is (InspectorRowWdgt.planeItsScrollLeavesStill).
  planeItsScrollLeavesStill: -> @

  # my window's title: my first inspector's
  colloquialName: ->
    @inspectors()[0]?.colloquialName() ? "Inspector"

  # THE BROWSER `widget` STANDS IN: its nearest ancestor that answers showNextTo, or undefined (a
  # column, a view or a set a person picked out of me stands in none). From a column of mine the climb
  # passes my set and my set's viewport, which answer no such thing; my body's parent is me. Asked by
  # showChoice, from the chooser's inspector, and by my set, to tell me what its reconcile changed.
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
  # (openInAWindowOn): a sequence it is no step of has no inspector following it to show the choice. An
  # empty body is no step of any sequence, and offers no choice.
  #   Every gesture asks me AFTER its own settle, never inside it: a browser settles once per choice
  # (showNextTo, which answers the inspector the choice shows), and then that inspector, and only that,
  # is brought whole into view, the least way, by the set's viewport, in a settle of its own
  # (InspectorRowViewportWdgt.revealColumn: its scroll lands on the set that settle laid out, and it
  # returns with the set laid out again where it rests). It is the fresh inspector or the
  # reloaded one -- a column of the set, or the body below it, which is no column and moves nothing --
  # or, after a choice of no subject, the chooser itself. So a member chosen in a column partly in view
  # shows in the body and scrolls nothing, and the column stands still under the pointer for a second
  # click (a double-click opens the member's value: MemberListWdgt.inspectMemberValue).
  @showChoice: (chooser, subject) ->
    inspector = chooser
    inspector = inspector.parent  until !inspector? or inspector.showsSubject?
    browser = InspectorBrowserWdgt.holding inspector
    if browser? and inspector in browser.inspectors()
      shown = browser.showNextTo inspector, subject
      browser.viewport.revealColumn shown
    else if subject?
      InspectorBrowserWdgt.openInAWindowOn subject
    return

  # A BROWSER ON `subject` IN A WINDOW of its own, at my default extent (the browser states it, and its
  # window opens at it), its body where my class puts it (bodyPlace's default): the ONE statement of
  # that opening, for the door (Widget.spawnInspector) and for a choice made under no browser
  # (showChoice). It opens by the hand -- or, opened APART from what `opts.beside` (a widget) stands in,
  # beside the window holding it: the top widget on the desktop that holds it (rootForFocus), its box
  # read once, as the window opens, and nothing of it kept (_landingBeside says where). One that stands
  # on no desktop -- carried, held by nothing, gone -- leaves the window by the hand. Answers the browser.
  @openInAWindowOn: (subject, opts = {}) ->
    browser = new InspectorBrowserWdgt subject
    original = opts.beside?.rootForFocus()
    position =
      if original?.parent is world
        InspectorBrowserWdgt._landingBeside original.bounds, world.bounds, browser.extent()
      else
        world.hand.position().subtract new Point 50, 100
    world.openFrameWith browser, browser.extent(), position
    browser

  # THE MEMBER `name` CHOSEN IN MY FIRST INSPECTOR, as a person's click on its row chooses it: the
  # door that opens me ON a member (Widget.spawnInspector's opts.member). My first inspector's view
  # chooses it when it lists members (MemberListWdgt.chooseMember); an inspector on one member (a
  # MemberRef subject: a lone editor) lists none and chooses nothing. No settle of my own: each step
  # the choice takes settles itself, one after the other.
  chooseMember: (name) ->
    @inspectors()[0]?.view?.chooseMember? name
    return

  # `subject` shown after `inspector`, mine, as one settle (showChoice says what that means); answers
  # the inspector that shows it (the core's answer, which the settle hands back).
  showNextTo: (inspector, subject) ->
    @_settleLayoutsAfter => @_showNextToNoSettle inspector, subject

  # Every inspector following `inspector` is destroyed but the next one, when that one already shows
  # the subject: it is reloaded instead (my body among them: a member chosen again in the list before
  # it reloads its editor, as one step of its undo history). A new subject gets a new inspector, placed
  # where I place one (_placeNoSettle), on its first view. A column's width is its own
  # (InspectorWdgt.getDesiredDim), so a choice leaves every column it keeps at the width it had, but for
  # my set's spare room, which goes to whichever column is then my set's last
  # (InspectorRowWdgt.takesMySlack). Before anything goes, my set's scroll is held where the choice
  # found it when the choice removes a column of my set (_holdMyScrollNoSettle).
  #   Then my set's structure is reconciled, whatever the choice removed or added -- a reload or a
  # choice of no subject may do neither -- so a split button a person took out of a header, or put back
  # after its title, leads that header again after every choice, and a child a person attached to my
  # set is reconciled too (InspectorWdgt._reconcileSplitGripNoSettle; with nothing out of place it
  # changes nothing); its reconcile tells me, at its end, that my sequence may have changed.
  #   All of it while I am CHANGING MY CELLS (the flag): a body the choice removes builds no empty body
  # as it leaves, nor does an empty body a fresh body replaces, so no choice builds a body only to
  # destroy it a moment later; and the reconciles of my set the choice runs reconcile no trail of mine.
  # My structure is reconciled ONCE, after (_reconcileMyStructureNoSettle): the body the choice placed,
  # or an empty one where it left none, its divider and its tab, and my trail, reconciled there once.
  #   LAST, A WALK KEEPS ITS VIEW: the fresh inspector shows the view of the title `inspector` names for
  # the choice (InspectorWdgt.titleOfMyChoice: the title of a list of objects the choice was made in,
  # read as the choice finds it), when its subject offers that view
  # (InspectorWdgt._keepTheWalksViewNoSettle), through its switch: a view that cannot be built leaves its
  # first in its place, and the error goes on out of this choice, which by then has placed and
  # reconciled everything it changes.
  #   ANSWERS the inspector the choice shows: the reloaded one, the fresh one, or, for a choice of no
  # subject, `inspector` itself, the chooser.
  _showNextToNoSettle: (inspector, subject) ->
    @_changingMyCells = true
    try
      following = @_inspectorsAfter inspector
      reloaded = following[0]  if subject? and following[0]?.showsSubject subject
      if subject? and !reloaded?
        fresh = new InspectorWdgt subject
        walksView = inspector.titleOfMyChoice subject
      leaving = if reloaded? then following[1..] else following
      @_holdMyScrollNoSettle leaving
      @_removeInspectorsNoSettle leaving
      reloaded?._reloadNoSettle()
      @_placeNoSettle fresh  if fresh?
      @row._reconcileSplittersNoSettle()
    finally
      @_changingMyCells = false
    @_reconcileMyStructureNoSettle()
    fresh?._keepTheWalksViewNoSettle walksView
    reloaded ? fresh ? inspector

  # A CHOICE THAT REMOVES COLUMNS LEAVES MY SET'S SCROLL WHERE IT FOUND IT. Asked by every choice, once,
  # before `leaving` -- what that choice removes -- goes: when a column of my set is among them, my set
  # is told to hold its viewport's offset as the choice found it, at the width its viewport stands at
  # (InspectorRowWdgt._holdScrollAtNoSettle: at that width its measure keeps that offset in reach, its
  # last column taking the room the removed ones leave, so its viewport's clamp has nothing to slide).
  # Any other choice leaves a hold an earlier one left as it stands: one that removes no column -- a
  # reload (the second click of a double-click), another member shown in my body below my set --
  # changes nothing in the set, so nothing may slide under the person's pointer; one that adds a column
  # leaves the hold to that column's reveal, which lets go of it if it scrolls, in its own settle
  # (InspectorRowViewportWdgt.revealColumn), as every scroll lets go of it (a stroke as it comes to
  # rest: InspectorRowViewportWdgt._scrollX says when). The offset and the width are read before
  # anything goes, as the choice found them. A core, inside the choice's settle.
  _holdMyScrollNoSettle: (leaving) ->
    columns = @row.columns()
    return unless (each for each in leaving when each in columns).length > 0
    @row._holdScrollAtNoSettle @viewport.getScrollX(), @viewport.width()

  # my inspectors following `inspector`, in order; none when it is no inspector of mine
  _inspectorsAfter: (inspector) ->
    mine = @inspectors()
    at = mine.indexOf inspector
    return [] if at < 0
    mine[at + 1..]

  # WHERE `inspector`, a fresh one of my sequence, stands: with my body below, a BODY -- it shows one
  # thing as text (InspectorWdgt.showsOneText), asked of the inspector, never of its subject -- in my
  # body's place (_placeBodyNoSettle); anything else, and everything with my body beside, at my set's
  # end (InspectorRowWdgt._addColumnNoSettle, which reconciles my set's splitters: a splitter between it
  # and the column before it, and its split button). A core: my build and a choice place one inside
  # their own settle, each reconciling my body's place after it.
  _placeNoSettle: (inspector) ->
    if @bodyPlace is "below" and inspector.showsOneText()
      @_placeBodyNoSettle inspector
    else
      @row._addColumnNoSettle inspector

  # `inspector`, a body, put in my body's place as a cell of my division stack: where the body standing
  # there stands (an empty one: a choice has removed any other), which is destroyed only THEN, so its
  # departure finds a body standing and needs nothing built; with none standing, after my last cell.
  # Its divider and its tab are my structure's reconcile's, which my build and a choice run after.
  _placeBodyNoSettle: (inspector) ->
    standing = @_bodyStanding()
    at = if standing? then @children.indexOf(standing) else undefined
    @_addNoSettle inspector, atIndex: at, layoutSpec: inspector.divisionBox('y')
    standing?._fullDestroyNoSettle()
    return

  # `inspectors`, all of them following one boundary of my sequence, destroyed, each telling the one
  # that held it that it left: a column, my set (InspectorRowWdgt._reactToChildRemoved), which
  # reconciles its splitters every time, the one before each going with it; my body, me
  # (_reactToChildRemoved), inside a choice, which reconciles my structure once, after.
  _removeInspectorsNoSettle: (inspectors) ->
    each._fullDestroyNoSettle() for each in inspectors
    return

  # MY STRUCTURE, its one rule, in two parts. With my body below (with it beside, I have no body's
  # place), MY BODY'S PLACE: a body always stands, an EMPTY body built when none does; exactly one
  # divider stands, right before it -- every other divider of mine destroyed, one added there when none
  # stands there --; the body's header re-derives its split button from it, joined to it
  # (InspectorWdgt._reconcileSplitGripNoSettle). Run under my flag, in a try/finally: the dividers it
  # destroys tell me they left, and that must not reconcile again inside this run. Then, my body below
  # or beside, WHAT FOLLOWS FROM MY SEQUENCE, which may have changed (a body I was opened on may have
  # gone, a choice may have placed one), mine to judge (_noteMySequenceMayHaveChangedNoSettle): my
  # window's title, and my trail, once for my build and once for each choice. Builds nothing when
  # nothing is out of place. Cores only: my build, a choice and a child's departure run it inside their
  # own settle.
  _reconcileMyStructureNoSettle: ->
    if @bodyPlace is "below"
      @_changingMyCells = true
      try
        @_addEmptyBodyNoSettle()  unless @_bodyStanding()?
        body = @_bodyStanding()
        @_dropStrayDividersNoSettle body
        @_addDividerBeforeNoSettle body  unless @splitterBefore(body)?
        body._reconcileSplitGripNoSettle()
      finally
        @_changingMyCells = false
    @_noteMySequenceMayHaveChangedNoSettle()
    return

  # an EMPTY BODY, an inspector on no subject (InspectorWdgt's header says what it is), after my last cell
  _addEmptyBodyNoSettle: ->
    empty = new InspectorWdgt undefined
    @_addNoSettle empty, layoutSpec: empty.divisionBox('y')
    return

  # every divider of mine but the one right before `body` destroyed: a stray one before my set's
  # viewport, a second one before the body, one a person attached anywhere else in my stack
  _dropStrayDividersNoSettle: (body) ->
    kept = @splitterBefore body
    each._fullDestroyNoSettle()  for each in @_divisionCells() when @_isMySplitter(each) and each isnt kept
    return

  # a divider (InspectorDividerWdgt, down my stack) added right before `body`
  _addDividerBeforeNoSettle: (body) ->
    divider = new InspectorDividerWdgt()
    @_addNoSettle divider, atIndex: @children.indexOf(body), layoutSpec: divider.divisionBox('y')
    return

  # A CHILD OF MINE LEFT ME (destroyed, or re-homed: a "Pick up", an "Attach", a drop into another
  # widget -- or re-added to me elsewhere, which also tells me). A divider that left me, however it left
  # (my reconcile's own removals and my teardown included), is told so first, and parts from the split
  # button joined to it (StackElementsSizeAdjustingWdgt.noteLeftMyStack). The rest not while I am
  # destroyed or being destroyed as a whole, not while I am changing my own cells (my build, a choice,
  # my reconcile, my trail's rebuild: each rebuilds what it must itself), and not inside a layout pass
  # (an "Edit layout" slot the pass takes away tells me a child left, and what I would build there would
  # schedule layout mid-pass: my next reconcile outside a pass builds it): an inspector that left me,
  # not destroyed, re-derives its split button where it stands now (a body picked out sheds its tab);
  # then my structure is reconciled, which builds an empty body when my body left, and re-joins the
  # tab, and reconciles my trail (a fresh one first in me when it was my trail that left).
  _reactToChildRemoved: (child) ->
    child.noteLeftMyStack?()
    return if @destroyed or @_beingFullDestroyed or @_changingMyCells or world?._recalculatingLayouts
    child._reconcileSplitGripNoSettle?()  unless child.destroyed or child.parent is @
    @_reconcileMyStructureNoSettle()

  # Destroyed as a whole: flagged at entry, so every child my teardown destroys finds me being torn
  # down (_reactToChildRemoved) and nothing is built into a dying browser.
  _fullDestroyNoSettle: ->
    @_beingFullDestroyed = true
    super

  # MY SEQUENCE MAY HAVE CHANGED: the ONE seat of what follows from it, told by my set at the end of
  # every reconcile of it (a choice's, and a person's "Pick up" or "Destroy" of a column's, which reaches
  # only my set) and by the reconcile of my structure (my build's, a choice's, and a child's departure
  # from me). Two things follow:
  #   MY NAME: when my first inspector is another than the one my name was last taken from, the window
  # whose content I am re-derives its title from my name, through its label's NoSettle cores, settling
  # nothing; while it is the same, that window's title is left as it stands.
  #   MY TRAIL, reconciled (_reconcileMyTrailNoSettle) -- but not while I am changing my cells (my build
  # and a choice each reconcile it once, at their end, in the reconcile of my structure), not once I am
  # destroyed or while I am torn down whole (nothing is built into a dying browser), and not inside a
  # layout pass (an "Edit layout" slot the pass takes away tells my set a child left, and a band built
  # there would schedule layout mid-pass). There I change nothing, as an inspector's split button waits
  # (InspectorWdgt._reconcileSplitGripNoSettle): a skipped rebuild leaves my band as it stood until my
  # next reconcile outside a pass, naming the levels it was built for; a press on it derives my levels
  # again (revealTrailLevel), so its index meets a real level or reveals nothing.
  _noteMySequenceMayHaveChangedNoSettle: ->
    first = @inspectors()[0]
    unless first is @_inspectorNamingMe
      @_inspectorNamingMe = first
      @parent.noteContentsNameMayHaveChanged()  if @parent?.isMyContents?(@) and @parent.noteContentsNameMayHaveChanged?
    return if @_changingMyCells or @destroyed or @_beingFullDestroyed or world?._recalculatingLayouts
    @_reconcileMyTrailNoSettle()
    return

  # MY TRAIL, its one rule: the band standing first in me names my levels as they stand (_trailLevels).
  # Builds nothing when it does (_trailNames), as every reconcile of the tool builds nothing when
  # nothing is out of place; rebuilt otherwise (_rebuildMyTrailNoSettle). A core, run where my sequence's
  # note runs.
  _reconcileMyTrailNoSettle: ->
    levels = @_trailLevels()
    @_rebuildMyTrailNoSettle levels  unless @_trailNames levels
    return

  # DOES MY TRAIL, AS IT STANDS, NAME `levels`? It stands in me, and its BUTTONS -- its pieces that press
  # revealTrailLevel at me -- are one per level, in order, each with its face standing in it, the face's
  # text the level's name, and the button's argument the level's index. It reads FIELDS of the band's
  # pieces as they stand, never a laid-out size: each piece's target and action, a button's argument
  # (argumentToAction1), its face (faceWidget) and that face's text. The chevrons, gaps and spring
  # between the buttons are not read: they follow from the count, so one a person took out of the band
  # stays out until my levels change.
  _trailNames: (levels) ->
    return false  unless @trail?.parent is @
    buttons = (each for each in @trail.children when each.target is @ and each.action is "revealTrailLevel")
    return false  unless buttons.length is levels.length
    buttons.every (button, k) ->
      button.argumentToAction1 is k and button.faceWidget?.parent is button and button.faceWidget.text is levels[k].name

  # MY TRAIL BUILT AFRESH, naming `levels`: a fresh band; then the one it replaces, while it stands in
  # me, destroyed, and the fresh one added where it stood -- a trail a person took out of me is theirs,
  # and stays where they put it, and the fresh one stands first in me. Rebuilt whole rather than re-led:
  # nothing holds the band but me, and a band has one re-lead core, for a lead
  # (BandWdgt._replacePiecesBeforeNoSettle). Run under my flag, in a try/finally: the band it destroys
  # tells me it left, and that must rebuild nothing inside this run. A core: my trail's reconcile runs it
  # inside the settle of what told my sequence's note, and the fresh band, an orphan as it is made,
  # settles only itself (orphan-settledness: `new X()` returns settled), as my build's and a choice's
  # fresh parts do.
  _rebuildMyTrailNoSettle: (levels) ->
    fresh = new BandWdgt WorldWdgt.theme.footerBandHeight, (@_trailItems levels), rule: "bottom"
    @_changingMyCells = true
    try
      at = 0
      if @trail?.parent is @
        at = @children.indexOf @trail
        @trail._fullDestroyNoSettle()
      @trail = fresh
      @_addNoSettle @trail, atIndex: at, layoutSpec: @trail.divisionBox('y')
    finally
      @_changingMyCells = false
    return

  # MY TRAIL'S PIECES, a band of plain buttons at a footer band's metrics, the house's one statement of
  # such a band (footerInset in, footerGap between two buttons, footerInset after the spring; its height
  # footerBandHeight, its rule along its BOTTOM, the line between it and my set): one SimpleButtonWdgt
  # per level of `levels` (_trailLevels), its face the level's name, pressing revealTrailLevel with the
  # level's INDEX as its argument, never a widget; and between two buttons the menu row's submenu mark, drawn
  # (MenuRowIndicatorWdgt ChevronRightIconAppearance), in a square of inspectorTrailChevronSize, in its
  # own ink (inspectorTrailChevron), its INK footerGap clear of each button: the gaps beside it are
  # footerGap less the part of its square its ink leaves empty on that side
  # (ChevronRightIconAppearance.inkSpanX, as a menu row aligns its own chevron by its ink:
  # MenuItemWdgt._submenuChevronInkSpan). The band centres every piece down itself, and the chevron's
  # ink is centred in its square, so the ink stands on the buttons' centre line. With no step (a person
  # took my only column out, and my body shows nothing) the band holds its insets and its spring alone.
  _trailItems: (levels) ->
    theme = WorldWdgt.theme
    side = theme.inspectorTrailChevronSize
    [inkLeft, inkRight] = ChevronRightIconAppearance.inkSpanX side
    items = [theme.footerInset]
    for level, k in levels
      if k > 0
        chevron = new MenuRowIndicatorWdgt ChevronRightIconAppearance, glyphSize: side, color: theme.inspectorTrailChevron
        items.push theme.footerGap - inkLeft, chevron, theme.footerGap - (side - inkRight)
      items.push new SimpleButtonWdgt target: @, action: "revealTrailLevel", arg1: k, face: level.name
    items.concat [BandWdgt.SPRING, theme.footerInset]

  # MY TRAIL'S LEVELS, derived from my sequence each time they are asked, never stored: one per step of
  # it (inspectors), in order, each its NAME (_nameOfLevel) and the COLUMN a press on it brings into
  # view -- the step before it, where it was chosen (with my body below, the body's level is my set's
  # last column, the list it was chosen in), and, for my first step, which nobody chose, its own. An
  # empty body is no step, and names no level.
  _trailLevels: ->
    sequence = @inspectors()
    for inspector, k in sequence
      chooser = sequence[k - 1]
      {name: (@_nameOfLevel inspector, chooser), column: (chooser ? inspector)}

  # HOW MY TRAIL NAMES `inspector`, a step of my sequence, `chooser` the step before it (undefined for my
  # first): as `chooser` names the choice made in it (InspectorWdgt.nameOfMyChoice: "Class
  # RectangleWdgt", "Child Rectangle 2"), else as the step names itself (InspectorWdgt.trailNameOfMySubject:
  # its subject's name read as its header reads it, in sentence case where the words are ours,
  # "Rectangle", "Point", and as it is where they are data, "color", "RectangleWdgt"). Text either way,
  # and read so that naming a step throws nowhere its header's title did not: my trail is never what
  # stops me opening.
  _nameOfLevel: (inspector, chooser) ->
    chooser?.nameOfMyChoice(inspector.inspectedObject) ? inspector.trailNameOfMySubject()

  # A PRESS ON A LEVEL OF MY TRAIL. Slot 3 is the level's INDEX, my trail's button's argument -- never a
  # widget: a button holding a column would name a corpse once that column is gone --, and slots 1 and
  # 2, the button and its subject, carry nothing I need. The levels are derived again (_trailLevels, the
  # derivation my band is reconciled to: an index meets the level of that index as my sequence stands
  # now -- the very one my band names, unless a layout pass left my band standing over a sequence that
  # changed (_noteMySequenceMayHaveChangedNoSettle) -- and an index past them reveals nothing), and that
  # level's column is brought whole into view by my set's viewport, the least way
  # (InspectorRowViewportWdgt.revealColumn: a column not of my set, my body below among them, moves
  # nothing), then the row chosen in it into its list's view (InspectorWdgt.revealMyChosenRow): I never
  # reach into a column's list. No settle of my own: the reveal settles itself, letting go of a hold a
  # choice left on my set when it moves it, and the row's scroll is its list's, applied at once.
  revealTrailLevel: (ignored, ignored2, index) ->
    level = @_trailLevels()[index]
    return unless level?
    @viewport.revealColumn level.column
    level.column.revealMyChosenRow()
    return

  # WHAT A STEP OF MY TRAIL OPENS IN A NEW INSPECTOR (ButtonWdgt.toOpenInANewInspector asks me, the
  # button's target): the subject of the step its index names, as my sequence stands now -- the
  # sequence a press on it reveals in (revealTrailLevel) -- and a step showing one MEMBER (my body: its
  # inspector showsOneText) as the door on a member opens it, the member's holder with the member chosen
  # in it (its reference's holder and name: MemberRef), as a member row of a list opens one; named by
  # the words its button SHOWS, its face's text, read off the button rather than derived again
  # (_trailLevels): naming a step reads its subject's name, a person's code where the subject is their
  # widget (an injected colloquialName, which can throw), and a menu that offers the row is built on this
  # answer, so a menu build runs nothing of a person's. Any other button of mine, and an index past my
  # steps, opens nothing apart.
  toOpenInANewInspectorBy: (button) ->
    return undefined  unless button.action is "revealTrailLevel"
    step = @inspectors()[button.argumentToAction1]
    return undefined  unless step?
    name = button.faceWidget?.text
    shown = step.inspectedObject
    if step.showsOneText() then {subject: shown.holder, member: shown.name, name: name} else {subject: shown, name: name}
