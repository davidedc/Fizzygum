# AN INSPECTOR: one subject (inspectedObject), and one VIEW of it. In a row of inspectors
# (InspectorRowWdgt) I am one column: my subject was chosen in the inspector to my left, and what is
# chosen in me goes to the one on my right (InspectorRowWdgt.showChoice).
#   Top to bottom, the elements of a vertical DIVISION stack (StackLayoutEngine), so I have no layout
# of my own: my HEADER band (BandWdgt) -- my subject's name, and a chip naming the class it is made
# by, whose press chooses that class -- and my VIEW, which takes the rest: a member's editor
# (MemberEditorWdgt) when my subject is one member of an object (it answers editsAsAMember: a
# MemberRef), the list of my subject's members (MemberListWdgt) for anything else. HOW a member is
# edited is never mine to know: my views ask the member's reference (MemberRef.of), so an object, a
# class's prototype and a value are each shown the one way.
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
#   I paint nothing: my bands paint their rules, and the row I stand in paints the body under all of
# us (inspectorBodyFill).
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
  # the widget showing my subject: a member editor or a member list
  view: undefined
  # the SPLIT BUTTON I built to lead my header (a SplitGripWdgt), or undefined while I have none. What
  # my header shows is read off my header, never remembered: my button shows exactly while it stands
  # in my header BEFORE my title (_showsMySplitGrip). One a person took out (picked up, destroyed) or
  # put back after my title is theirs: my reconcile lets go of it, leaving the widget where it stands,
  # and leads my header afresh.
  splitGrip: undefined
  # the PLACE my view left in me (my header says why): built once, as my view leaves me
  # (_reactToChildRemoved), and undefined while my view stands in me
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
  # controls and names need, as a list column beside a code pane does. My least and desired widths are
  # my cells' -- my header's and my view's, or my view's place's -- which the stack derives; my box's
  # own are no input while I have cells.
  #   The margin is also what lets the split beside me move: a division row moves a split by trading
  # the most widths of the cells on either side of it (StackElementsSizeAdjustingWdgt), so a person who
  # drags it changes the two most widths, and the row then keeps their spare in that proportion as its
  # window grows or shrinks, and across the choices that keep a view of the same kind on the far side
  # of that split (InspectorRowWdgt._showNextToNoSettle, which reads what I gave away,
  # mostWidthGivenAway, and has me give width up, _giveUpMostWidthNoSettle). My default box
  # (_defaultBox) is set once my view exists, before any row adds me.
  constructor: (@inspectedObject) ->
    super()
    @_buildAndConnectChildren()
    {least, desired, spreadability} = @_defaultBox()
    @setMinAndMaxBoundsAndSpreadability least, desired, spreadability

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
  # settled): my header, then my view.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_buildHeaderNoSettle()
    @view = if @inspectedObject?.editsAsAMember?() then new MemberEditorWdgt @inspectedObject else new MemberListWdgt @inspectedObject
    @_addNoSettle @view, layoutSpec: @view.divisionBox('y')

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
  # to show it. A view a person took out of me shows my subject elsewhere, and I am left a header over
  # its empty place: I show no subject then, so a choice of it replaces me with a fresh inspector, as
  # a choice of another subject does, rather than reloading a view I do not hold.
  showsSubject: (subject) ->
    return false unless @view?.parent is @
    subject is @inspectedObject or (@inspectedObject?.sameMemberAs? subject) is true

  # MY VIEW LEFT ME -- picked out, carried off by a drag, deleted into the bin, attached elsewhere,
  # destroyed: heard here, the one seat every door reaches, inside the settle of the verb that took
  # it. Its PLACE is kept (my header says why), once: a SPRING of my stack (BandSpaceWdgt), its
  # desired width the one my view desired as my stack read it (getDesiredDim), its desired height
  # 1 px and its spreadability a spacer's, so it takes my spare height; it stands where my view stood
  # -- right after my header, or first when my header has left me too. A view destroyed whole
  # answers after its own parts are gone, so a member list then desires only its own box's 1 px, and
  # my width falls to my header's. Only a view that LEFT: one re-added to me, or wrapped in place (a
  # transform island takes its slot and its spec), still stands for itself. Not once I am destroyed,
  # nor while I am torn down whole (the flag): nothing is built into a dying inspector. Cores only: a
  # space settles nothing as it is made, and the verb that took my view owns the settle.
  _reactToChildRemoved: (child) ->
    return if @destroyed or @_beingFullDestroyed
    return unless child is @view and !@viewsPlace? and !@isAncestorOf child
    @viewsPlace = new BandSpaceWdgt @view.getDesiredDim().x, 1, springs: true
    @_addNoSettle @viewsPlace, atIndex: @children.indexOf(@header) + 1, layoutSpec: @viewsPlace.divisionBox('y')
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
  splitterBeforeMe: ->
    @parent?.splitterBefore? @

  # Does my header show my split button? I hold one and it LEADS my header: it stands in my header
  # before my title, where my lead is (every piece before my title: BandWdgt._replacePiecesBeforeNoSettle).
  # Read off my header each time, as showsSubject reads my view, and by the two pieces' places, never
  # by "first": an "Edit layout" slot stands before my button while my band is edited.
  _showsMySplitGrip: ->
    return false unless @splitGrip?.parent is @header
    pieces = @header.children
    pieces.indexOf(@splitGrip) < pieces.indexOf(@headerTitle)

  # MY SPLIT BUTTON, derived: my header opens with one exactly while a splitter stands before me
  # (splitterBeforeMe). A header or a title a person took out of me is theirs, and my lead is what
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
    wanted = @splitterBeforeMe()?
    return unless lost or wanted isnt @splitGrip?
    theme = WorldWdgt.theme
    @splitGrip = if wanted then new SplitGripWdgt() else undefined
    lead = if wanted then [@splitGrip, theme.inspectorHeaderGap] else [theme.inspectorHeaderInset]
    @header._replacePiecesBeforeNoSettle @headerTitle, lead
    return

  # The two notifications a widget built without its constructor gets (Duplicator, Deserializer: both
  # ask them through ?(), and no class above me answers either): a copy of me, or a restore of me,
  # stands where it stands -- alone, it is in no row and sheds a split button it was copied or saved
  # with; inside a copied or restored row, its row's structure gives back what it had.
  _reactToBeingCopied: ->
    @_reconcileSplitGripNoSettle()
    return

  _afterDeserialization: ->
    @_reconcileSplitGripNoSettle()
    return
