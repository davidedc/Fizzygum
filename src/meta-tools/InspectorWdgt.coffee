# AN INSPECTOR: one subject (inspectedObject), and one VIEW of it at a time. In an inspector browser
# (InspectorBrowserWdgt) I am one of its sequence, a column of its set (InspectorRowWdgt): my subject
# was chosen in the inspector to my left, and what is chosen in me goes to the one on my right
# (InspectorBrowserWdgt.showChoice).
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
# and either then closes what stands on my right (showViewNamed). A switch writes no width of mine:
# a width a person stated stands as it is, and with none I take my natural width, my new view in it.
#   A view a person takes OUT of me leaves its PLACE in me (viewsPlace): a spring of my stack that
# paints nothing (BandSpaceWdgt), 1 px each way, as a band's spring is. A division stack hands ALL
# its spare room to its cells, by their margins of most over desired, and by their desired sizes
# when no cell has a margin (StackLayoutEngine, its third regime): with my pinned header my only
# cell, my header would stretch down my whole height. The place takes my spare height as my view
# did, and claims none of my width, so my natural width is then my bands'.
#   MY WIDTH IN A SET is my own answer (getDesiredDim, getMaxDim), never my division box's: my
# NATURAL width, what my cells desire (my header's, my chooser's, my view's), or the width a person
# STATED (statedWidth) by dragging the column divider on my right, never below my least; and as my
# most width that same width, unless my set says I take its spare room (InspectorRowWdgt.takesMySlack:
# its last column does).
#   My header opens with a SPLIT BUTTON (SplitGripWdgt) exactly while a column divider stands before
# me in my set (InspectorColumnDividerWdgt, which sizes the column on MY left): the touch-sized control
# of that divider, a tab joined to it, the two of them painted as one piece, a drag on either sizing
# that column. The button is DERIVED from where I stand, never told: my row reconciles it at
# every choice (an inspector a choice adds among them) and whenever a child leaves the row
# (_reconcileSplitGripNoSettle, which also introduces the button to that splitter) -- a widget a
# person attaches is no moment of its own, and waits for the next of those -- and so do a copy of me
# and a restore of me, which can stand in no row. A button a person took out of my header comes back
# at my row's next reconcile.
#   In a row I paint nothing: my bands paint their rules, and the browser my row stands in paints the
# body under all of us (inspectorBodyFill). Picked out of my row I paint that body myself, and my views
# stand on it either way (InspectorBodyAppearance, laysTheInspectorBodyUnderItsParts).
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
  # THE WIDTH A PERSON STATED for me, in whole px, or undefined: my natural width then, what my cells
  # desire (getDesiredDim). Written only by a drag of the column divider on my right, or of its split
  # button (_setColumnWidthDeferredSettle). Mine for my whole life, a person's choice nothing derives, so
  # a copy and a save carry it, and a switch of my view, a reload and a "Pick up" out of my set leave it
  # as it is.
  statedWidth: undefined

  # The subject is my identity, my one positional parameter.
  #   MY OWN DIVISION BOX, which my set adds me by, is no input to my width in a set (my header says
  # what is), and its least and desired sizes are no input while I have cells: it is the plain box
  # every part of the tool wears, least and desired 1 x 1, with a spacer's spreadability, because
  # out of a set only a division stack a person puts me in (an "Edit layout" slot) reads my most
  # width -- on the desktop, where a "Pick up" puts me, none does -- and there I take that stack's
  # spare room as each view of mine takes the spare room of my own stack.
  constructor: (@inspectedObject) ->
    super()
    @appearance = new InspectorBodyAppearance @
    @_buildAndConnectChildren()
    @setMinAndMaxBoundsAndSpreadability (new Point 1, 1), (new Point 1, 1), DivisionStackLayoutSpec.SPREADABILITY_SPACERS

  # I lay the inspector's body under my views: the browser of the row I stand in paints it under me,
  # and with no row I paint it myself (InspectorBodyAppearance), so a view of mine paints none of its own.
  laysTheInspectorBodyUnderItsParts: -> true

  # MY SHADOW IS THE BODY'S BOX, my parts' silhouettes left out (my views' with them), while I paint the
  # body (InspectorBodyAppearance.castsOnlyTheBody says when, and its header why); otherwise my base's
  # pass.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if @appearance.castsOnlyTheBody appliedShadow
      @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    else
      super

  # MY DESIRED SIZE: my natural one, what my cells desire (my base's, which the stack derives), but
  # across, while a person stated my width (statedWidth), that width, never below my least. Read by
  # the division arrange of whatever holds me and by my set's measure
  # (InspectorRowWdgt.scrolledContentMeasure). Collapsed, I desire nothing, stated or not (my base's
  # answer).
  getDesiredDim: ->
    natural = super()
    return natural  unless @statedWidth? and !@isInCollapsedSubtree()
    new Point (Math.max @getMinDim().x, @statedWidth), natural.y

  # MY MOST SIZE. Across: my desired width, unless my holder says I take its spare room
  # (InspectorRowWdgt.takesMySlack: my set's last column does), and then a spacer's most over that
  # width (DivisionStackLayoutSpec.maxFor, the house's spreadability arithmetic), so my set's division
  # arrange hands me all the room beyond its cells' own widths. My holder is asked each time, never
  # remembered: a choice or a "Pick up" that leaves another column last moves the spare room to it.
  # Standing in a holder that answers no such question, my base's answer (my box's most width, at
  # least my desired: my constructor says where that is read). Down: always my base's.
  getMaxDim: ->
    most = super()
    takesTheSlack = @parent?.takesMySlack? @
    return most  unless takesTheSlack?
    desiredWidth = @getDesiredDim().x
    width = if takesTheSlack then DivisionStackLayoutSpec.maxFor desiredWidth, DivisionStackLayoutSpec.SPREADABILITY_SPACERS else desiredWidth
    new Point width, most.y

  # MY WIDTH STATED, by a drag-move STREAM: the column divider on my right being dragged, or its split
  # button (InspectorColumnDividerWdgt.nonFloatDragging, SplitGripWdgt.nonFloatDragging: the stream
  # handlers check-layering [O] lets call a *DeferredSettle entrypoint). An entrypoint of the private
  # deferred-settle family Widget._setMaxDimDeferredSettle heads: my core's effect, its layout flush
  # riding the one end-of-cycle settle (world.deferredSettlingEnabled off: settled at each call), both
  # branches reaching the core directly.
  _setColumnWidthDeferredSettle: (width) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setColumnWidthNoSettle width
    else
      @_settleLayoutsAfter => @_setColumnWidthNoSettle width

  # My stated width written (statedWidth), and my layout invalidated, which climbs to my set, whose
  # measure reads my desired width. Settles nothing. Nothing to do when that width is stated already.
  _setColumnWidthNoSettle: (width) ->
    return if width is @statedWidth
    @statedWidth = width
    @_invalidateLayout()

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

  # MY VIEWS' BUILDERS, named by my views' table (_views) and each handed a row's derivation name,
  # which only a list of objects takes.
  _newMemberEditor: ->
    new MemberEditorWdgt @inspectedObject

  _newMemberList: ->
    new MemberListWdgt @inspectedObject

  # a LIST OF OBJECTS my subject holds in one way: the ones `derivationName` (an ObjectListWdgt method,
  # named by a row of my views' table) lists
  _newObjectList: (derivationName) ->
    new ObjectListWdgt @inspectedObject, derivationName

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
  # stood on my right goes, as after any choice of no subject in me (InspectorBrowserWdgt.showChoice)
  # -- after a switch that threw too, which leaves me showing my first view (_showViewNoSettle says
  # how): the browser's settle then lays that out before the error goes on.
  showViewNamed: (ignored, ignored2, title) ->
    try
      @_settleLayoutsAfter => @_showViewNoSettle title
    finally
      InspectorBrowserWdgt.showChoice @, undefined

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
  #   any other toggle, or the lit one while my view stands in no child of mine: the view put in me
  #   afresh (_replaceViewNoSettle): what shows my view in me goes first, my view let go of BEFORE it
  #   goes, and the fresh view is built only THEN;
  #   and my chooser shown the view.
  #   A VIEW THAT CANNOT BE BUILT LEAVES ME WHOLE. Building or re-reading a view can throw (a derivation
  #   meeting a listed widget whose injected colloquialName answers no string), and by then what it
  #   replaces is gone. So on a throw I show my FIRST view (_views' first row), put in me the same way,
  #   my title and my toggles naming it, and the error goes on, to be told as any thrown gesture is (the
  #   world's input catch: the console's INPUT_ERROR line, the error log opened on it). If the view that
  #   threw IS my first, nothing more is tried, and the error goes on as it is.
  #   No width of mine is written: a width a person stated (statedWidth) stands, and with none I take
  #   my natural width, the fresh view in it.
  _showViewNoSettle: (title) ->
    rereads = title is @shownViewTitle and @_myViewStandsInMe()
    row = (each for each in @_views() when each[0] is title)[0]
    return unless rereads or row?
    try
      if rereads
        @_removeMyPlaceNoSettle()
        @view._rereadNoSettle()
      else
        @_replaceViewNoSettle row
    catch error
      first = @_views()[0]
      throw error  if title is first[0]
      @_replaceViewNoSettle first
      @_reflectViewOnToggles()
      throw error
    @_reflectViewOnToggles()

  # A VIEW PUT IN ME, the view of `row` (a row of my views' table): what shows my view in me goes first
  # (_removeWhatShowsMyViewNoSettle, which answers where it stood), and only THEN is the fresh view
  # built, and added there: a view derives its list as it is built (ObjectListWdgt), and a list
  # derived while what it replaces stands lists that too (a class's instances include the old view's
  # own parts), though it is destroyed a moment later. The fresh view is my view, and its title the
  # one I show.
  _replaceViewNoSettle: (row) ->
    [title, builder, derivationName] = row
    at = @_removeWhatShowsMyViewNoSettle()
    @view = @[builder] derivationName
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
  # a SPRING of my stack (BandSpaceWdgt), desiring 1 px each way, as a band's spring does, with a
  # spacer's spreadability, so it takes my spare height and claims none of my width; it stands where
  # my view stood -- right after the last of my bands that is still mine (_indexAfterMyBands). Only a
  # view that LEFT: one that still stands in me (_myViewStandsInMe: re-added to me, or wrapped in place
  # by a transform island that takes its slot and its spec) still stands for itself; while a place
  # stands nothing more is kept; and a switch lets go of my view before it goes
  # (_removeWhatShowsMyViewNoSettle), so I have none then. Not once I am destroyed, nor while I am torn
  # down whole (the flag): nothing is built into a dying inspector. Cores only: a space settles nothing
  # as it is made, and the verb that took my view owns the settle.
  _reactToChildRemoved: (child) ->
    return if @destroyed or @_beingFullDestroyed
    return if !@view? or @viewsPlace? or @_myViewStandsInMe()
    return unless child.isAncestorOf @view
    @viewsPlace = new BandSpaceWdgt 1, 1, springs: true
    @_addNoSettle @viewsPlace, atIndex: @_indexAfterMyBands(), layoutSpec: @viewsPlace.divisionBox('y')
    return

  # Destroyed as a whole: flagged at entry, so my view, destroyed with me, finds me being torn down
  # (_reactToChildRemoved) and no place is built into a dying inspector.
  _fullDestroyNoSettle: ->
    @_beingFullDestroyed = true
    super

  # MY SUBJECT CHOSEN AGAIN (InspectorBrowserWdgt.showChoice, which asks only while I show it, my view
  # standing in me): my view takes it back -- a member editor puts its member's text back over what is
  # typed, as one step of its undo history; a member list chooses no row of its own any more, since
  # what stood on its right for its choice has gone. A core: the browser calls it inside its one
  # settle.
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
    InspectorBrowserWdgt.showChoice @, @_classAbove()

  # The column divider that stands before me in my set, or undefined: read off my row's children each
  # time I am asked (InspectorRowWdgt.splitterBefore), never stored, so a split button never drags the
  # divider of a set I am not in. Only a row answers: anywhere else (a copy of me, standing alone; a
  # transform island turning me) none stands before me.
  _splitterBeforeMe: ->
    @parent?.splitterBefore? @

  # THE DIVIDER `button` DRAGS, asked by a split button as it is dragged and as it is painted
  # (SplitGripWdgt): the column divider before me, which sizes the column on my left, exactly while
  # `button` is my own split button and LEADS my header (_showsMySplitGrip). Any other button drags none
  # -- a stray a person put after my title, before my next reconcile lets go of it, or one standing in
  # another inspector's header -- so a drag on it moves nothing.
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
  #   Here my button and the splitter before me are INTRODUCED: a button leading my header is joined
  # to that splitter (LayoutChromeWdgt.noteJoinedBy, a no-op while they are joined already, and the
  # one place a join is made: LayoutChromeWdgt.joinedPiece's rule), which also joins them again in a
  # copy or a restore of me, whose parts hold nothing (joinedPiece is never copied nor saved), joins my
  # button to a splitter that replaced the one before me, and parts the splitter from a button I let
  # go of, which a fresh button replaces.
  _reconcileSplitGripNoSettle: ->
    return if world?._recalculatingLayouts
    return unless @header?.parent is @ and @headerTitle?.parent is @header
    splitter = @_splitterBeforeMe()
    lost = @splitGrip? and !@_showsMySplitGrip()
    @splitGrip = undefined  if lost
    wanted = splitter?
    if lost or wanted isnt @splitGrip?
      theme = WorldWdgt.theme
      @splitGrip = if wanted then new SplitGripWdgt() else undefined
      lead = if wanted then [@splitGrip, theme.inspectorHeaderGap] else [theme.inspectorHeaderInset]
      @header._replacePiecesBeforeNoSettle @headerTitle, lead
    splitter.noteJoinedBy @splitGrip  if wanted
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
