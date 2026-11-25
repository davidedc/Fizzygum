# AN INSPECTOR: one subject (inspectedObject), and one VIEW of it at a time. In a row of inspectors
# (InspectorRowWdgt) I am one column: my subject was chosen in the inspector to my left, and what is
# chosen in me goes to the one on my right (InspectorRowWdgt.showChoice).
#   Top to bottom, the elements of a vertical DIVISION stack (StackLayoutEngine), so I have no layout
# of my own: my HEADER band (BandWdgt) -- my subject's name, and a chip naming the class it is made
# by, whose press chooses that class --, my CHOOSER band when my subject offers more than one view,
# and my VIEW, which takes the rest. The views my subject offers are _views(), by what it holds or
# answers, never by its type: a member's editor (MemberEditorWdgt) when my subject is one member of an
# object (it answers editsAsAMember: a MemberRef), and nothing else; for anything else its MEMBERS
# (MemberListWdgt), first, then the objects it holds (ObjectListWdgt): a widget's CHILDREN; a class's
# INSTANCES, where instances register, and its SUBCLASSES. HOW a member is edited is never mine to
# know: my views ask the member's reference (MemberRef.of), so an object, a class's prototype and a
# value are each shown the one way.
#   My CHOOSER is a band of toggles (LabelledToggleWdgt), one per view, the shown one ON: a press on
# another shows that view in place of mine, a press on the lit one has my view read its list again,
# and either then closes what stands on my right (showViewNamed). A switch keeps my WIDTH: the view it
# builds states the least and desired width I had (_showViewNoSettle), so the splits beside me do not
# move because of it.
#   A view a person takes OUT of me leaves its PLACE in me (viewsPlace): a spring of my stack that
# paints nothing (BandSpaceWdgt), desiring the width my view desired. A division stack hands ALL its
# spare room to its cells, by their margins of most over desired, and by their desired sizes when
# no cell has a margin (StackLayoutEngine, its third regime), and its least and desired widths are
# the largest of its cells': with my pinned header my only cell, my header would stretch down my
# whole height, and my row would lay me out at my header's width. The place takes my spare height as
# my view did and keeps the width my view desired, so a row at least as wide as its inspectors desire
# lays me out as it did while my view stood in me, my share of its spare unchanged (my own box keeps
# the weight my view gave it). The place claims no LEAST width: a hole has nothing a narrow row could
# cut, so my least width is my header's, and a narrower row gives up the hole's room before it
# squeezes a control.
#   My header opens with a SPLIT BUTTON (SplitGripWdgt) exactly while a splitter stands before me in
# my row: the touch-sized way to move that split. The button is DERIVED from where I stand, never
# told: my row reconciles it at every choice (an inspector a choice adds among them) and whenever a
# child leaves the row (_reconcileSplitGripNoSettle) -- a widget a person attaches is no moment of
# its own, and waits for the next of those -- and so do a copy of me and a restore of me, which can
# stand in no row. A button a person took out of my header comes back at my row's next reconcile.
#   In a row I paint nothing: my bands paint their rules, and the row paints the body under all of us
# (inspectorBodyFill). Picked out of my row I paint that body myself, and my views stand on it either
# way (InspectorBodyAppearance, laysTheInspectorBodyUnderItsParts).
class InspectorWdgt extends Widget

  # the object I am a view OF, and deliberately not called `target`: `@target` elsewhere means
  # information flow (a dataflow consumer, a dispatch receiver) or a tracked reference edge, and
  # reading one as the other is the hazard this name exists to remove. My FIRST own field, assigned
  # before my base constructor writes any other, so every walk of me meets it first (a save's
  # refusal names the path it took: `(InspectorWdgt#N) → .inspectedObject`).
  inspectedObject: undefined

  # a file holding me needs the class member maps before I am restored, as my views do
  # (Deserializer._needsTheReflectiveLayer, which both file doors consult)
  readsClassMemberMaps: true

  # my header band, its title (my subject's name) and its class chip (undefined while my subject
  # stands below no class of its own: _classAbove), each built once, with me
  header: undefined
  headerTitle: undefined
  classChip: undefined
  # the widget showing my subject: a member editor, a member list or an object list
  view: undefined
  # my CHOOSER band and its toggles, in the order of _views(), each pressing showViewNamed with its
  # view's title as its argument; undefined while my subject offers one view only
  chooser: undefined
  viewToggles: undefined
  # the title of the view I show (a title of _views()): my chooser shows it ON
  shownViewTitle: undefined
  # the SPLIT BUTTON I built to lead my header (a SplitGripWdgt), or undefined while I have none. What
  # my header shows is read off my header, never remembered: my button shows exactly while it stands
  # in my header BEFORE my title (_showsMySplitGrip). One a person took out (picked up, destroyed) or
  # put back after my title is theirs: my reconcile lets go of it, leaving the widget where it stands,
  # and leads my header afresh.
  splitGrip: undefined
  # the PLACE my view left in me (my header says why): built once, as my view leaves me
  # (_reactToChildRemoved), and gone at the next switch, which ends with a view standing in me
  # (_removeMyPlaceNoSettle); undefined while my view has not left me since
  viewsPlace: undefined
  # am I being destroyed as a whole (_fullDestroyNoSettle)? Then my view leaving me is my teardown,
  # and no place is kept for it (as my row's flag, InspectorRowWdgt)
  _beingFullDestroyed: undefined

  # The subject is my identity, my one positional parameter.
  #   MY OWN DIVISION BOX says how much of my row's SPARE width I take, and my VIEW decides it
  # (rowSlackWeight): the weight times a spacer's spreadability, over a desired width of 1, is my most
  # width, and a division row hands out its spare width in proportion to its cells' margins of most
  # over desired (StackLayoutEngine, its third regime). Code is what wants width: a member editor asks
  # a large weight and takes the spare, while a member list asks a small one and keeps the width its
  # controls and names need, as a list column beside a code pane does. Every view a chooser of mine
  # offers asks one weight, so a switch leaves my box as it is. My least and desired widths are my
  # cells' -- my header's, my chooser's, and my view's or my view's place's -- which the stack derives;
  # my box's own are no input while I have cells.
  #   The margin is also what lets the split beside me move: a division row moves a split by trading
  # the most widths of the cells on either side of it (StackElementsSizeAdjustingWdgt), so a person who
  # drags it changes the two most widths, and the row then keeps their spare in that proportion as its
  # window grows or shrinks, and across the choices that keep a view of the same kind on the far side
  # of that split (InspectorRowWdgt._showNextToNoSettle, which reads what I gave away,
  # mostWidthGivenAway, and has me give width up, _giveUpMostWidthNoSettle). My default box
  # (_defaultBox) is set once my view exists, before any row adds me.
  constructor: (@inspectedObject) ->
    super()
    @appearance = new InspectorBodyAppearance @
    @_buildAndConnectChildren()
    {least, desired, spreadability} = @_defaultBox()
    @setMinAndMaxBoundsAndSpreadability least, desired, spreadability

  # I lay the inspector's body under my views: the row I stand in paints it under me, and with no row
  # I paint it myself (InspectorBodyAppearance), so a view of mine paints none of its own.
  laysTheInspectorBodyUnderItsParts: -> true

  # MY SHADOW IS THE BODY'S BOX, my parts' silhouettes left out (my views' with them), while I paint the
  # body (InspectorBodyAppearance.castsOnlyTheBody says when, and its header why); otherwise my base's
  # pass.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if @appearance.castsOnlyTheBody appliedShadow
      @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    else
      super

  # MY DEFAULT BOX, its one statement: least and desired 1 px each way, so my cells' sizes are what my
  # row reads, and my view's weight times a spacer's spreadability (my constructor says why).
  _defaultBox: ->
    one = new Point 1, 1
    {least: one, desired: one, spreadability: @view.rowSlackWeight() * DivisionStackLayoutSpec.SPREADABILITY_SPACERS}

  # THE MOST WIDTH I GAVE AWAY across the splits beside me: the most width my default box gives me
  # less the one my own box holds. A drag on a split trades most width between the two cells beside it
  # (StackElementsSizeAdjustingWdgt.maxDimsPuttingMyLeadingEdgeAt), so this is my trades' sum, 0 when
  # no split beside me was dragged, negative when I gained. The default is read through the box's own
  # arithmetic (DivisionStackLayoutSpec.maxFor), never a second copy of it.
  mostWidthGivenAway: ->
    {desired, spreadability} = @_defaultBox()
    (DivisionStackLayoutSpec.maxFor desired.x, spreadability) - @_divisionBoxOrDefaults().maxWidth

  # MY MOST WIDTH LESS `width`: what I give up to the cell across a split from me, as a drag on it
  # trades (InspectorRowWdgt._removeInspectorsNoSettle says which split and why). Only my width: a row
  # divides its width, so my most height stays what my box holds, my default box's. A core: my row
  # calls it inside its choice's settle.
  _giveUpMostWidthNoSettle: (width) ->
    box = @_divisionBoxOrDefaults()
    @_setMaxDimNoSettle new Point (box.maxWidth - width), box.maxHeight

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns
  # settled): my header, my chooser when my subject offers more than one view, then my first view, put
  # in me as a switch puts a view (_replaceViewNoSettle: nothing shows a view in me yet, so it goes
  # after my bands).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_buildHeaderNoSettle()
    views = @_views()
    @_buildChooserNoSettle views  if views.length > 1
    @_replaceViewNoSettle views[0]
    @_reflectViewOnToggles()

  # THE VIEWS MY SUBJECT OFFERS: a hand-kept TABLE, in my chooser's order, one row per view: its TITLE
  # (the face of its toggle, and the name a switch asks for), the name of my method that BUILDS it,
  # and, for a list of objects, the name of the DERIVATION that list lists (one of ObjectListWdgt's).
  # Which rows my subject gets is asked of what it holds or answers, never of its type.
  #   A member (editsAsAMember) offers its SOURCE alone, in a member's editor. Anything else offers its
  #   MEMBERS first, then:
  #     CHILDREN -- a widget: it holds a children array and answers the parts copies and saves carry
  #       (childrenCarriedByCopiesAndSaves); a class's prototype reads no array there, and a plain object
  #       holding one answers no such parts;
  #     INSTANCES -- a class's prototype (isAClassPrototype) whose instances register
  #       (registerThisInstance): only a widget class's do, so no other class offers a list that could
  #       only stay empty;
  #     SUBCLASSES -- any class's prototype.
  #   The table's names are strings, held true both ways: the dead-method gate (check-dead-methods.js)
  # reads a string that is a whole method name as a reference to that method, so a builder or a
  # derivation no row names reads dead and fails the build; and a row naming a method that is not
  # there throws at the press of its toggle (the tests that press each toggle are named on its row).
  _views: ->
    s = @inspectedObject
    return [["Source", "_newMemberEditor"]]  if s?.editsAsAMember?()
    views = [["Members", "_newMemberList"]]
    # hand-list-sanctioned: a view's title, its builder and its derivation; a stale name throws at this
    # toggle's press (SystemTest_macroInspectorChildrenViewWalksTheWidgetTree), an unnamed method reads
    # dead (check-dead-methods.js)
    views.push ["Children", "_newObjectList", "_childrenOfMySubject"]  if Array.isArray(s?.children) and s.childrenCarriedByCopiesAndSaves?
    if isAClassPrototype s
      # hand-list-sanctioned: a view's title, its builder and its derivation; a stale name throws at
      # this toggle's press (SystemTest_macroInspectorClassViewsListInstancesAndSubclasses), an unnamed
      # method reads dead (check-dead-methods.js)
      views.push ["Instances", "_newObjectList", "_instancesOfMySubject"]  if s.registerThisInstance?
      # hand-list-sanctioned: a view's title, its builder and its derivation; a stale name throws at
      # this toggle's press (SystemTest_macroInspectorClassViewsListInstancesAndSubclasses), an unnamed
      # method reads dead (check-dead-methods.js)
      views.push ["Subclasses", "_newObjectList", "_subclassesOfMySubject"]
    views

  # MY VIEWS' BUILDERS, named by my views' table (_views) and each handed a row's derivation name and
  # `kept`, the widths I had (B4: my least and desired width as my row read them just before a switch,
  # _showViewNoSettle). An object list states those widths, so a switch leaves my width as it was; a
  # member list and a member editor take neither, and state their own.
  _newMemberEditor: ->
    new MemberEditorWdgt @inspectedObject

  _newMemberList: ->
    new MemberListWdgt @inspectedObject

  # a LIST OF OBJECTS my subject holds in one way: the ones `derivationName` (an ObjectListWdgt method,
  # named by a row of my views' table) lists
  _newObjectList: (derivationName, kept) ->
    new ObjectListWdgt @inspectedObject, derivationName, leastWidth: kept?.least, desiredWidth: kept?.desired

  # MY CHOOSER BAND, written as a member list's toggles band is: toggleBandInset in, one toggle per view
  # (its face and its argument the view's title, its action showViewNamed), toggleBandGap between them,
  # a spring, toggleBandInset again; its rule along its bottom. The toggles are shown my view
  # (_reflectViewOnToggles) once it exists.
  _buildChooserNoSettle: (views) ->
    theme = WorldWdgt.theme
    @viewToggles = for view in views
      new LabelledToggleWdgt target: @, action: "showViewNamed", arg1: view[0], face: view[0]
    items = [theme.toggleBandInset]
    for toggle, i in @viewToggles
      items.push theme.toggleBandGap  if i > 0
      items.push toggle
    items.push BandWdgt.SPRING, theme.toggleBandInset
    @chooser = new BandWdgt theme.toggleBandHeight, items, rule: "bottom"
    @_addNoSettle @chooser, layoutSpec: @chooser.divisionBox('y')

  # My chooser shows my view: the toggle of the view I show ON, every other OFF. My build and every
  # switch end here, and nothing else sets a toggle of mine, so a toggle and my view cannot disagree.
  _reflectViewOnToggles: ->
    toggle.setOn (toggle.argumentToAction1 is @shownViewTitle) for toggle in (@viewToggles ? [])
    return

  # A TOGGLE OF MY CHOOSER PRESSED (slot 3 is its argument, the view's title; slots 1 and 2, the toggle
  # and its subject, carry nothing I need): the view of that title in place of mine, or, the lit one
  # pressed, my view's list read again, in ONE settle (_showViewNoSettle); then, after that settle, what
  # stood on my right goes, as after any choice of no subject in me (InspectorRowWdgt.showChoice) --
  # after a switch that threw too, which leaves me showing my first view (_showViewNoSettle says how):
  # the row's settle then lays that out before the error goes on.
  showViewNamed: (ignored, ignored2, title) ->
    try
      @_settleLayoutsAfter => @_showViewNoSettle title
    finally
      InspectorRowWdgt.showChoice @, undefined

  # DOES MY VIEW STAND IN ME? It does while a child of mine holds it: my view itself, or a transform
  # island that wraps it in place, having taken its slot and its spec (_childHoldingMyView). The one
  # question the switch, the departure of a child (_reactToChildRemoved) and showsSubject ask.
  _myViewStandsInMe: ->
    @_childHoldingMyView()?

  # THE CHILD OF MINE THAT HOLDS MY VIEW -- my view, or the island wrapping it in place -- or undefined
  # while my view stands in no child of mine (a person took it out) or I have none (inside a switch).
  _childHoldingMyView: ->
    return undefined unless @view?
    (each for each in @children when each.isAncestorOf @view)[0]

  # WHERE A VIEW OR ITS PLACE GOES when nothing shows my view in me: right after my chooser, else right
  # after my header, else first -- the last of my bands that is still mine.
  _indexAfterMyBands: ->
    after = if @chooser?.parent is @ then @chooser else @header
    @children.indexOf(after) + 1

  # THE SWITCH, cores only, in this order and for these reasons:
  #   the LIT toggle, while my view stands in me: a place left standing beside it (my view came back to
  #   me) goes first, then my view reads its list again (_rereadNoSettle: a member list re-filters,
  #   keeping its filters; an object list derives its list again);
  #   any other toggle, or the lit one while my view stands in no child of mine: my WIDTH, read off me
  #   FIRST, while what I show still stands in me -- my least and desired width as my row reads them (my
  #   header's, my chooser's, my view's or its place's), handed to the view I build, which states them,
  #   so my widths stay what they were and the splits beside me do not move because of the switch;
  #   then the view put in me afresh (_replaceViewNoSettle): what shows my view in me goes first, my
  #   view let go of BEFORE it goes, and the fresh view is built only THEN;
  #   and my chooser shown the view.
  #   A VIEW THAT CANNOT BE BUILT LEAVES ME WHOLE. Building or re-reading a view can throw (a derivation
  #   meeting a listed widget whose injected colloquialName answers no string), and by then what it
  #   replaces is gone. So on a throw I show my FIRST view (_views' first row), put in me the same way,
  #   my title and my toggles naming it, and the error goes on, to be told as any thrown gesture is (the
  #   world's input catch: the console's INPUT_ERROR line, the error log opened on it). If the view that
  #   threw IS my first, nothing more is tried, and the error goes on as it is.
  #   My box is not written: every view a chooser offers asks one weight (rowSlackWeight), so my default
  #   box, and every trade of most width a split made with me, stand as they were.
  _showViewNoSettle: (title) ->
    rereads = title is @shownViewTitle and @_myViewStandsInMe()
    row = (each for each in @_views() when each[0] is title)[0]
    return unless rereads or row?
    try
      if rereads
        @_removeMyPlaceNoSettle()
        @view._rereadNoSettle()
      else
        kept = least: @getMinDim().x, desired: @getDesiredDim().x
        @_replaceViewNoSettle row, kept
    catch error
      first = @_views()[0]
      throw error  if title is first[0]
      @_replaceViewNoSettle first
      @_reflectViewOnToggles()
      throw error
    @_reflectViewOnToggles()

  # A VIEW PUT IN ME, the view of `row` (a row of my views' table), handed `kept` when a switch read my
  # widths: what shows my view in me goes first (_removeWhatShowsMyViewNoSettle, which answers where
  # it stood), and only THEN is the fresh view built, and added there: a view derives its list as it is
  # built (ObjectListWdgt), and a list derived while what it replaces stands lists that too (a class's
  # instances include the old view's own parts), though it is destroyed a moment later. The fresh view
  # is my view, and its title the one I show.
  _replaceViewNoSettle: (row, kept) ->
    [title, builder, derivationName] = row
    at = @_removeWhatShowsMyViewNoSettle()
    @view = @[builder] derivationName, kept
    @shownViewTitle = title
    @_addNoSettle @view, atIndex: at, layoutSpec: @view.divisionBox('y')
    return

  # WHAT SHOWS MY VIEW IN ME GOES, and where it stood is answered: the child of mine that holds my view
  # (_childHoldingMyView) and my place, whichever of them stand in me, each destroyed -- a view a person
  # took out of me is theirs, and stays where they put it, and so does anything of theirs that stands
  # anywhere else -- and the place answered is where the first of them stood in me, else right after my
  # bands (_indexAfterMyBands). I let go of my view and of my place BEFORE either goes, so neither
  # departure, heard in _reactToChildRemoved, is my view's: neither builds a place.
  _removeWhatShowsMyViewNoSettle: ->
    holder = @_childHoldingMyView()
    first = (each for each in @children when each is holder or each is @viewsPlace)[0]
    at = if first? then @children.indexOf(first) else @_indexAfterMyBands()
    @view = undefined
    @_removeMyPlaceNoSettle()
    holder?._fullDestroyNoSettle()
    at

  # MY PLACE GOES: destroyed while it stands in me, and forgotten either way (a person may have taken it
  # out or destroyed it). Asked whenever my view comes to stand in me, which a place stands for the lack of.
  _removeMyPlaceNoSettle: ->
    place = @viewsPlace
    @viewsPlace = undefined
    place._fullDestroyNoSettle()  if place?.parent is @
    return

  # MY HEADER BAND: inspectorHeaderInset in, my title, my class chip when my subject has a class
  # above it (current, as the one chip of its row; its action asks _classAbove when it is pressed, so
  # it holds no class), and inspectorHeaderInset again; its rule along its bottom. It opens with no
  # split button: my row's reconcile gives me one where a splitter stands before me.
  #   My TITLE is my subject's name, one line of fonts.buttonLabel in inspectorHeaderTitle, a text
  # that GIVES WAY (BandWdgt's `gives` item): it is my header's spring, so its box takes all the width
  # my header's other pieces leave, running up to my chip, and my chip stands at my header's right. Its
  # text is cropped with "…" where that box is narrower than it, and stands at the box's start where
  # the box is wider. My header's least and desired widths are its other pieces' and the few px the
  # title's box can shrink to, the same whatever the name: a long name widens no window, and holds no
  # split beside me where it stands.
  _buildHeaderNoSettle: ->
    theme = WorldWdgt.theme
    @headerTitle = new StringWdgt (String @_subjectName()), fontRole: theme.fonts.buttonLabel, color: theme.inspectorHeaderTitle
    items = [theme.inspectorHeaderInset, {gives: @headerTitle}]
    if (classLink = @_classAbove())?
      @classChip = new ChipWdgt target: @, action: "chooseMyClass", face: classLink.constructor.name, current: true
      items.push @classChip
    items.push theme.inspectorHeaderInset
    @header = new BandWdgt theme.inspectorHeaderHeight, items, rule: "bottom"
    @_addNoSettle @header, layoutSpec: @header.divisionBox('y')

  # Do I show `subject`? It is my subject, or -- a member chosen again, made again as a new
  # reference -- it names the same member as mine (MemberRef.sameMemberAs); and my view stands in me
  # to show it (_myViewStandsInMe: itself, or wrapped in place). A view a person took out of me shows
  # my subject elsewhere, and I am left a header over its empty place: I show no subject then, so a
  # choice of it replaces me with a fresh inspector, as a choice of another subject does, rather than
  # reloading a view I do not hold.
  showsSubject: (subject) ->
    return false unless @_myViewStandsInMe()
    subject is @inspectedObject or (@inspectedObject?.sameMemberAs? subject) is true

  # MY VIEW LEFT ME -- picked out, carried off by a drag, deleted into the bin, attached elsewhere,
  # destroyed, itself or the island that wrapped it in place: heard here, the one seat every door
  # reaches, inside the settle of the verb that took it. Its PLACE is kept (my header says why), once:
  # a SPRING of my stack (BandSpaceWdgt), its desired width the one my view desired as my stack read it
  # (getDesiredDim), its desired height 1 px and its spreadability a spacer's, so it takes my spare
  # height; it stands where my view stood -- right after the last of my bands that is still mine
  # (_indexAfterMyBands). A view destroyed whole answers after its own parts are gone, so a member list
  # then desires only its own box's 1 px, and my width falls to my header's. Only a view that LEFT: one
  # that still stands in me (_myViewStandsInMe: re-added to me, or wrapped in place by a transform
  # island that takes its slot and its spec) still stands for itself; while a place stands nothing more
  # is kept; and a switch lets go of my view before it goes (_removeWhatShowsMyViewNoSettle), so I have
  # none then. Not once I am destroyed, nor while I am torn down whole (the flag): nothing is built
  # into a dying inspector. Cores only: a space settles nothing as it is made, and the verb that took my
  # view owns the settle.
  _reactToChildRemoved: (child) ->
    return if @destroyed or @_beingFullDestroyed
    return if !@view? or @viewsPlace? or @_myViewStandsInMe()
    return unless child.isAncestorOf @view
    @viewsPlace = new BandSpaceWdgt @view.getDesiredDim().x, 1, springs: true
    @_addNoSettle @viewsPlace, atIndex: @_indexAfterMyBands(), layoutSpec: @viewsPlace.divisionBox('y')
    return

  # Destroyed as a whole: flagged at entry, so my view, destroyed with me, finds me being torn down
  # (_reactToChildRemoved) and no place is built into a dying inspector.
  _fullDestroyNoSettle: ->
    @_beingFullDestroyed = true
    super

  # MY SUBJECT CHOSEN AGAIN (InspectorRowWdgt.showChoice, which asks only while I show it, my view
  # standing in me): my view takes it back -- a member editor puts its member's text back over what is
  # typed, as one step of its undo history; a member list chooses no row of its own any more, since
  # what stood on its right for its choice has gone. A core: the row calls it inside its one settle.
  _reloadNoSettle: ->
    @view._reloadNoSettle()
    return

  # my window's title, and how a row names me: "Inspector — " and my subject's name, as it is
  colloquialName: ->
    "Inspector — " + @_subjectName()

  # My subject's name: a class's PROTOTYPE by its class's name, as DATA ("AnalogClockWdgt": my subject
  # IS that class, and the name is how a person finds it); anything else through the service, never by
  # asking it -- an inspector is handed whatever the user asked to inspect, a number, a string, a Point
  # among it, and the service names those from their class (Utils.colloquialNameOf). A member names
  # itself (MemberRef.colloquialName).
  _subjectName: ->
    if isAClassPrototype @inspectedObject then @inspectedObject.constructor.name else Utils.colloquialNameOf @inspectedObject

  # The class my subject is made by: the first link ABOVE it on its prototype chain that is a
  # class's own prototype (it owns a `constructor` that is a function), unless that is Object. An
  # object's is its class; a class's prototype's is its superclass; a number's is Number. A member
  # has none: its holder's class is the inspector to my left's. undefined when there is none.
  _classAbove: ->
    return undefined  if @inspectedObject?.editsAsAMember?()
    link = Object.getPrototypeOf Object @inspectedObject
    until !link? or ((Object::hasOwnProperty.call link, "constructor") and Utils.isFunction link.constructor)
      link = Object.getPrototypeOf link
    link  if link? and link.constructor.name isnt "Object"

  # MY CHIP's action: the class above my subject is my choice, and what stands on my right shows it.
  # So my view drops its own choice first, if it shows one: that choice stands on my right no more.
  chooseMyClass: ->
    @view?.clearChoice?()
    InspectorRowWdgt.showChoice @, @_classAbove()

  # The splitter that stands before me in my row, or undefined: read off my row's children each time
  # I am asked (InspectorRowWdgt.splitterBefore), never stored, so a split button never drags the
  # splitter of a row I am not in. Only a row answers: anywhere else (a copy of me, standing alone; a
  # transform island turning me) none stands before me.
  _splitterBeforeMe: ->
    @parent?.splitterBefore? @

  # THE SPLITTER `button` MOVES, asked by a split button as it is dragged (SplitGripWdgt): the splitter
  # before me, exactly while `button` is my own split button and LEADS my header (_showsMySplitGrip).
  # Any other button moves none -- a stray a person put after my title, before my next reconcile lets
  # go of it, or one standing in another inspector's header -- so a drag on it moves nothing.
  splitterMovedBy: (button) ->
    @_splitterBeforeMe()  if button is @splitGrip and @_showsMySplitGrip()

  # Does my header show my split button? I hold one and it LEADS my header: it stands in my header
  # before my title, where my lead is (every piece before my title: BandWdgt._replacePiecesBeforeNoSettle).
  # Read off my header each time, as showsSubject reads my view, and by the two pieces' places, never
  # by "first": an "Edit layout" slot stands before my button while my band is edited.
  _showsMySplitGrip: ->
    return false unless @splitGrip?.parent is @header
    pieces = @header.children
    pieces.indexOf(@splitGrip) < pieces.indexOf(@headerTitle)

  # MY SPLIT BUTTON, derived: my header opens with one exactly while a splitter stands before me
  # (_splitterBeforeMe). A header or a title a person took out of me is theirs, and my lead is what
  # stands before my title, so while either stands anywhere else I judge nothing and change nothing.
  # Otherwise what my header shows is read off it (_showsMySplitGrip), never remembered: a button I
  # built that does not lead -- a person picked it up, destroyed it, or put it back after my title --
  # is let go of (my field cleared, the widget left where it stands: it is the person's), so a copy or
  # a file of me made from then on carries no widget that left me, and my lead, which lost it, is
  # rebuilt whole. Nothing to do when my header shows what is wanted; else my header is RE-LED in
  # place -- every piece of it before my title (BandWdgt._replacePiecesBeforeNoSettle), the gap a lost
  # button left included -- with a fresh split button and inspectorHeaderGap, or with
  # inspectorHeaderInset alone. Only that lead changes: my title, my chip and my band stay the same
  # widgets, and nothing made here settles as it is made, so my copy and restore hooks may run it as
  # my row's reconcile does. Inside a layout pass (an "Edit layout" slot the pass takes away tells my
  # row a child left) I change nothing: a lead rebuilt there would schedule layout mid-pass, so my
  # row's next reconcile outside a pass rebuilds it.
  _reconcileSplitGripNoSettle: ->
    return if world?._recalculatingLayouts
    return unless @header?.parent is @ and @headerTitle?.parent is @header
    lost = @splitGrip? and !@_showsMySplitGrip()
    @splitGrip = undefined  if lost
    wanted = @_splitterBeforeMe()?
    return unless lost or wanted isnt @splitGrip?
    theme = WorldWdgt.theme
    @splitGrip = if wanted then new SplitGripWdgt() else undefined
    lead = if wanted then [@splitGrip, theme.inspectorHeaderGap] else [theme.inspectorHeaderInset]
    @header._replacePiecesBeforeNoSettle @headerTitle, lead
    return

  # The two notifications a widget built without its constructor gets (Duplicator, Deserializer: both
  # ask them through ?(), and no class above me answers either): a copy of me, or a restore of me,
  # stands where it stands -- alone, it is in no row and sheds a split button it was copied or saved
  # with; inside a copied or restored row, its row's structure gives back what it had. My view is
  # rebuilt by neither: it shows what it was copied or saved showing, and an object list, which carries
  # no object, derives its objects at its first press (ObjectListWdgt.chooseRow).
  _reactToBeingCopied: ->
    @_reconcileSplitGripNoSettle()
    return

  _afterDeserialization: ->
    @_reconcileSplitGripNoSettle()
    return
