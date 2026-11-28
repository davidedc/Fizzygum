# AN OBJECT LIST: an inspector's view of the OBJECTS its subject holds in one way, one row per object
# -- a widget's CHILDREN (the parts copies and saves carry), a class's INSTANCES (its subclasses'
# included, as its class's instances set holds them), or a class's direct SUBCLASSES (sorted by name).
# A row chosen is a CHOICE (InspectorBrowserWdgt.showChoice): the inspector after mine shows that
# object, on the view of my own title when the object offers one that lists something (a walk keeps
# its view: InspectorWdgt._keepTheWalksViewNoSettle), and its browser's trail names it by my relation
# and the row's label (chosenRowLabelFor, InspectorWdgt.nameOfMyChoice). I stand in an inspector
# (InspectorWdgt), whose chooser builds me; picked out of it, I still list and choose.
#   WHICH objects I list is my derivation, named as my inspector builds me (derivationName: one of my
# three methods below), so a copy or a restore of me knows it. A row READS by the house rule for rows
# that name widgets (CommandPanelWdgt.rowLabelsNaming: "Rectangle", "Rectangle 2"), and a class by its
# class's name, in a member row's look with its tag column empty (objectRowFactsOf). My list holds
# LABELS, strings, as every list does, and I hold the objects, in an array built with those labels in
# one derivation (_derivedRows); a pressed row is resolved by the PLACE it carries (its element's index
# in my list, which the list hands me with the label: ListWdgt.select), and honoured only while my
# label at that place is the one pressed (chooseRow says why both are asked).
#   The objects are DERIVED and never carried: neither a copy nor a file of me holds one (my `objects`
# is transient for both walkers), so no corpse is captured into a file, no save of a class's inspector
# that showed its instances is refused, and no copy shares them. A row is honoured only while it is true
# (chooseRow): a copy or a restore of me, holding no objects, derives them at its first press; and an
# object that is not in my subject's list as it stands is no choice. Nothing refreshes my list but my
# inspector's lit chooser toggle (_rereadNoSettle), a copy's first press that finds it stale, and my
# own verbs, each of which reads it again once it has acted.
#   MY VERBS are the widget menu's own, where that menu offers them: a CHILDREN list, in developer mode,
# offers DUPLICATE -- a copy of the chosen child beside it, in the same parent (Widget.duplicateBesideMe),
# so my list, read again, shows it, offered only where the parent has a place for that copy -- and
# REMOVE, the menu's Delete (Widget.close: into the bin, or onto the shelf when a shortcut or a wire
# points at the child -- the storage drain's rule, as for the menu's Delete --, from where a person
# takes it back), each on a child that menu acts on as itself (verbApplies). An INSTANCES list spans
# the whole world -- the hand, the bin and the shelf, menus, this tool's own parts -- and a SUBCLASSES
# list lists classes, which no widget verb acts on: neither offers a verb.
#   Top to bottom, the elements of a vertical DIVISION stack (StackLayoutEngine): my LIST, which takes
# the slack, dressed as every view's list is (MemberListWdgt.dressAsAViewsList), my CUT-NOTICE band
# when I list only the first MemberListWdgt.MOST_ITEMS_LISTED, and my VERBS band (ListVerbsBandWdgt: a
# drawn icon button per verb I offer) while I offer one. In an inspector I paint nothing; standing
# anywhere else I paint the inspector's body (InspectorBodyAppearance).
class ObjectListWdgt extends Widget

  # the object whose objects I list, and deliberately not called `target` (MemberListWdgt says why)
  inspectedObject: undefined
  # the name of my method that derives my objects: "_childrenOfMySubject", "_instancesOfMySubject" or
  # "_subclassesOfMySubject"
  derivationName: undefined
  # my list (a ListWdgt in member mode, holding my labels), built again whenever my list is read again
  list: undefined
  # my band saying I list only the first objects, built only when I do
  cutNoticeBand: undefined
  # my VERBS band (ListVerbsBandWdgt), my last cell, standing exactly while I offer a verb (verbsOffered):
  # built and taken away by its reconcile (_reconcileMyVerbsBandNoSettle), its buttons following my
  # chosen row's child (verbApplies) whenever I ask it to reflect them
  verbsBand: undefined
  # my objects, in my list's rows' order, parallel to my labels: transient for both walkers (below)
  objects: undefined
  # the labels my list was built from, in its rows' order (possibly none: my list then shows its
  # placeholder row, "(empty)"). Carried by copies and files: a copy's first press compares them
  labels: undefined

  # my objects, in the array parallel to my labels: derived, never carried (my header says why)
  @serializationTransients: ["objects"]
  @copyTransients: ["objects"]

  #: initialization

  # The subject and my derivation's name are my identity, my two positional parameters.
  #   A BUILD THAT THROWS LEAVES NOTHING OF ME -- a guard of this class's own, because a view switch
  # recovers from my build failing (InspectorWdgt._showViewNoSettle) and must not leak the view it gave
  # up on; not a pattern every constructor follows. My list is derived as I am built, and a derivation can
  # throw in a person's own code (a listed widget's injected colloquialName, which naming its row reads).
  # A half-built me would stay in my classes' `instances` sets -- alive, held by nothing, never destroyed
  # -- so I destroy what I built of myself and let the error go on. Through the core: I am an orphan, so
  # nothing outside me hears my death, and no settle of mine may run inside the switch that builds me
  # (InspectorWdgt._replaceViewNoSettle, a core).
  constructor: (@inspectedObject, @derivationName) ->
    super()
    @appearance = new InspectorBodyAppearance @
    @setMinAndMaxBoundsAndSpreadability (new Point 1, 1), (new Point 1, 1), DivisionStackLayoutSpec.SPREADABILITY_SPACERS
    try
      @_buildAndConnectChildren()
    catch error
      @_fullDestroyNoSettle()
      throw error

  #: drawing

  # MY SHADOW IS THE BODY'S BOX, my parts' silhouettes left out, while I paint the body
  # (InspectorBodyAppearance.castsOnlyTheBody says when, and its header why); otherwise my base's pass.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if @appearance.castsOnlyTheBody appliedShadow
      @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    else
      super

  #: initialization

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_rereadNoSettle()

  #: listing

  # MY LIST READ AGAIN from my subject as it stands, in this order: what it replaces goes FIRST -- my
  # list and my cut-notice band, each destroyed where it stands in me (one a person took out is theirs,
  # and stays where they put it), and the place my new list takes remembered: where my list stood, else
  # where my cut-notice band stood, else right before my verbs band, else my end --; THEN my objects and
  # labels derived; then my list built from them in that place, my cut-notice band after it, and my
  # verbs band reconciled, my last cell (_reconcileMyVerbsBandNoSettle). A list is derived only once
  # what it replaces is gone: a derivation that runs while they stand lists and counts them (a class's
  # instances include my old list's own rows and labels), though they are destroyed a moment later.
  # At my build, at my inspector's lit chooser toggle (InspectorWdgt._showViewNoSettle, which asks
  # every view this by this name), at a copy's first press that finds my list stale (chooseRow), and
  # after each of my verbs. A fresh list selects nothing.
  _rereadNoSettle: ->
    if @list?.parent is @
      at = @children.indexOf @list
      @list._fullDestroyNoSettle()
    else if @cutNoticeBand?.parent is @
      at = @children.indexOf @cutNoticeBand
    else
      at = @_indexOfMyVerbsBand()
    @cutNoticeBand._fullDestroyNoSettle()  if @cutNoticeBand?.parent is @
    {objects, labels, count} = @_derivedRows()
    @objects = objects
    @labels = labels
    @_buildListNoSettle at
    @_buildCutNoticeNoSettle objects.length, count
    @_reconcileMyVerbsBandNoSettle()
    @_invalidateLayout()

  #: verbs

  # where my verbs band stands among my children, or undefined while none of mine does: the place a
  # cell built after my list goes, so my band stays my last cell
  _indexOfMyVerbsBand: ->
    @children.indexOf @verbsBand  if @verbsBand?.parent is @

  # MY VERBS BAND, its one rule: it stands, my last cell, exactly while I offer a verb (verbsOffered) --
  # built when none stands, taken away when I offer none -- and its buttons then reflect my verbs
  # (ListVerbsBandWdgt.reflectVerbs). A band a person took out of me is theirs, and stays where they put
  # it: I let go of it, and build my own again while I offer a verb. Builds nothing when nothing is out
  # of place. At every read of my list (_rereadNoSettle), and when the developer mode switches
  # (_devModeChangedNoSettle). A core, inside the settle of whatever asks it.
  _reconcileMyVerbsBandNoSettle: ->
    @verbsBand = undefined  unless @verbsBand?.parent is @
    offers = (Object.keys @verbsOffered()).length > 0
    if offers and !@verbsBand?
      @verbsBand = new ListVerbsBandWdgt @
      @_addNoSettle @verbsBand, layoutSpec: @verbsBand.divisionBox('y')
      @_invalidateLayout()
    else if !offers and @verbsBand?
      @verbsBand._fullDestroyNoSettle()
      @verbsBand = undefined
      @_invalidateLayout()
    @verbsBand?.reflectVerbs()
    return

  #: notifications

  # THE DEVELOPER MODE SWITCHED (WorldWdgt.toggleDevMode tells every widget that answers this): the verbs I
  # offer are developer mode's (verbsOffered), so my verbs band follows it at once, built or taken away
  # (_reconcileMyVerbsBandNoSettle). A core, inside the world's one settle.
  _devModeChangedNoSettle: ->
    @_reconcileMyVerbsBandNoSettle()

  #: verbs

  # MY VERBS (my verbs band's protocol, ListVerbsBandWdgt): the TABLE of the verbs I offer, each the name
  # of my method that performs it and the words that say it. A CHILDREN list offers the widget menu's two
  # verbs, DUPLICATE and REMOVE (the menu's Delete), where that menu offers them: in developer mode,
  # since user mode builds no widget's menu (Widget.buildContextMenu). Any other list of mine offers
  # none, and then I have no band (my header says why). Neither verb asks anything, so neither's words
  # end in "…". Read as my band is reconciled, and as every verb is asked whether it applies.
  verbsOffered: ->
    return {}  unless @derivationName is "_childrenOfMySubject" and world.isDevMode
    {
      duplicate: {action: "duplicateChosenChild", words: "Duplicate"}
      remove: {action: "removeChosenChild", words: "Remove"}
    }

  # DOES `verb` APPLY NOW? Both act on the CHILD my chosen row stands for (_chosenObject), so they apply
  # only while I offer them (verbsOffered) and that row names a child of my subject still, one the
  # widget menu reaches and acts on as itself (Widget.developerMenuReachesMe: a right-click reaches its
  # own menu -- not a construct's internal structure, nor a widget whose container takes its menu over --
  # and the figure both its rows act on is the child, not a transform island it is the sole content of).
  # Then each verb asks its own row's guards:
  #   DUPLICATE, a child that does not refuse a copy, as the menu's Duplicate row asks (refusesDuplication:
  #   the bin's opener), and whose parent has a place for a copy beside it (Widget.copyPlaceBesideMe: the
  #   next cell of a stack, or free on a surface that places its children freely; none in a window's
  #   content slot, a docked band, a viewport's bars, where an add would land the copy elsewhere);
  #   REMOVE, a child the menu's Delete removes as itself, not a part of a window, whose Delete closes the
  #   window in its place (Widget.windowClosedInMyPlace).
  # My verbs band asks it at each seat I know of where that changes: every read of my list, whose fresh
  # list selects nothing (_rereadNoSettle); each choice of a row (chooseRow); my choice dropped
  # (clearChoice, and my reload: _reloadNoSettle); the developer mode switched. A change to the child
  # that none of them sees -- moved, closed or wrapped by another gesture -- shows at my next seat; my
  # actions ask again when pressed, so a button that shows a stale state never acts on a child the menu
  # would not act on.
  verbApplies: (verb) ->
    child = @_chosenObject()
    return false  unless @verbsOffered()[verb]? and child?.developerMenuReachesMe()
    if verb is "duplicate"
      !child.refusesDuplication?() and child.copyPlaceBesideMe()?
    else
      !child.windowClosedInMyPlace()?

  #: choosing

  # THE OBJECT MY CHOSEN ROW STANDS FOR, or undefined: my list's selected row (ListWdgt.selected),
  # honoured as a press on it is (_objectOfRow: my label at its place the row's own, the object there
  # still in my derivation), among the objects I hold -- none while I hold none (a copy or a restore of
  # me, before its first press), as what a row opens in a new inspector reads.
  _chosenObject: ->
    row = @list?.selected
    @_objectOfRow @objects, row.labelString, row.argumentToAction1  if row? and @objects?

  #: verbs

  # MY VERBS' ACTIONS, my verbs band's buttons' (each hands me its verb, which names nothing more I
  # need). Each acts only while its verb applies (verbApplies): a press on a disabled button, or a call
  # another caller makes, on a child the widget menu would not act on, does nothing. It acts through the
  # widget's own verb, as the menu's row does; then my list is read again from my subject as it stands,
  # in one settle (_rereadNoSettle: a fresh list selects nothing), and what followed my inspector for my
  # old list's choice goes (InspectorBrowserWdgt.showChoice, with no subject), after that settle.
  #   DUPLICATE: a copy of the chosen child beside it, in the same parent (Widget.duplicateBesideMe: the
  # next cell of a stack, or on top of what stands in a free surface, 10 px right of and below the
  # child, as the menu's copy stands on the desktop), so my list, read again, shows it.
  duplicateChosenChild: ->
    if @verbApplies "duplicate"
      @_chosenObject().duplicateBesideMe()
      @_settleLayoutsAfter => @_rereadNoSettle()
      InspectorBrowserWdgt.showChoice @, undefined
    return

  #   REMOVE: the widget menu's Delete, exactly (Widget.close: into the bin, or onto the shelf when a
  # shortcut or a wire points at the child, as the storage drain files what is closed; from either a
  # person takes it back), so my list, read again, holds it no more.
  removeChosenChild: ->
    if @verbApplies "remove"
      @_chosenObject().close()
      @_settleLayoutsAfter => @_rereadNoSettle()
      InspectorBrowserWdgt.showChoice @, undefined
    return

  #: listing

  # THE ONE DERIVATION, objects and labels together: every object my derivation answers, the first
  # MOST_ITEMS_LISTED of them kept, their labels, and how many there are in all.
  _derivedRows: ->
    all = @[@derivationName]()
    objects = all[...MemberListWdgt.MOST_ITEMS_LISTED]
    {objects, labels: (@_labelsOf objects), count: all.length}

  # How my rows read: a class's prototype by its class's name (data, unique to its class, and a
  # prototype is never asked a widget's question); a widget by the house rule for rows that name
  # widgets, all of them at once, since a row's wording depends on its neighbours.
  _labelsOf: (objects) ->
    if objects.every((each) -> isAClassPrototype each)
      (each.constructor.name for each in objects)
    else
      CommandPanelWdgt.rowLabelsNaming objects

  # MY THREE DERIVATIONS, each a FRESH array, never my subject's own (a children array is live, an
  # instances set is no array): the parts of my subject copies and saves carry; the instances of its
  # class, its subclasses' included; the prototypes of the classes whose superclass is my subject's
  # class, sorted by class name (the page's own order of its classes is the engine's).
  _childrenOfMySubject: ->
    @inspectedObject.childrenCarriedByCopiesAndSaves()

  _instancesOfMySubject: ->
    Array.from @inspectedObject.constructor.instances

  _subclassesOfMySubject: ->
    names = (each.name for each in allClassFunctions() when each.__super__ is @inspectedObject)
    (classNamed(name).prototype for name in names.sort())

  # MY LIST, built from my labels and added at `atIndex` among my children (_rereadNoSettle says where,
  # and has removed what it replaces). A member list's look, its tag column empty (objectRowFactsOf); a
  # click dispatches chooseRow; no double-click of its own (a click already opens the object); a row
  # asked what it opens in a new inspector asks objectToOpenInANewInspector. Dressed as a view's list.
  _buildListNoSettle: (atIndex) ->
    @list = new ListWdgt @labels.slice(),
      target: @
      action: "chooseRow"
      memberFactsQuery: "objectRowFactsOf"
      newInspectorQuery: "objectToOpenInANewInspector"
    MemberListWdgt.dressAsAViewsList @list
    @_addNoSettle @list, atIndex: atIndex, layoutSpec: @list.divisionBox('y')

  # my cut-notice band in step with my list (_rereadNoSettle has removed the one standing in me): a
  # fresh one after my list, before my verbs band (else at my end), when I list `listed` of `count`
  # objects (MemberListWdgt.cutNoticeBandFor), and none otherwise
  _buildCutNoticeNoSettle: (listed, count) ->
    @cutNoticeBand = MemberListWdgt.cutNoticeBandFor listed, count
    @_addNoSettle @cutNoticeBand, atIndex: @_indexOfMyVerbsBand(), layoutSpec: @cutNoticeBand.divisionBox('y')  if @cutNoticeBand?

  # WHAT MY LIST SHOWS BESIDE A ROW'S NAME (my list's memberFactsQuery): no kind tag, and not dimmed.
  objectRowFactsOf: (ignored) ->
    kindTag: ""
    dimmed: false

  #: choosing

  # A CLICK on a row: ListWdgt.select hands me the row's LABEL and the PLACE the row carries (its
  # element's index in the list that built it; undefined for a hand-made row). I ask BOTH: the place
  # makes two rows that read alike two (a label alone cannot say which was pressed), and the label makes
  # a row of a stale list no choice -- a row of a list a person took out of me, still dispatching here,
  # whose place in my labels now reads another label. A row keeps naming its own object when a row
  # above it left the list, since its place was fixed at the build. Three rules, so a row is honoured
  # only while it is true:
  #   holding NO objects (I am a copy or a restore), I derive them now: labels the same as my list's,
  #   in order, and I hold those objects and go on; otherwise my list is stale, so it is built again
  #   from the derivation and NOTHING is chosen;
  #   my label at the row's place must be the label pressed: then my object there is the row's; else --
  #   a hand-made row, the placeholder row (my labels are none), a stale list's row -- NO choice;
  #   the object must still be in my derivation as it stands now (a child of my subject still, still
  #   registered, still a subclass); one that is not is NO choice, as a member list's label that names
  #   no member is.
  # No choice removes what followed my inspector (InspectorBrowserWdgt.showChoice, with no subject), after any
  # settle of mine, as every gesture asks it. The second and third rules are a query (_objectOfRow), which
  # what a row opens in a new inspector asks too, of the objects I hold (objectToOpenInANewInspector);
  # the first rule's derivation, which labels every object again and so runs a person's code (a listed
  # widget's injected colloquialName), is the press's alone, as holding the objects and building my list
  # again are. My verbs follow the row chosen, once I hold my objects (a stale list read again reflects
  # them itself).
  chooseRow: (label, place) ->
    unless @objects?
      {objects, labels} = @_derivedRows()
      if labels.length is @labels.length and labels.every((each, i) => each is @labels[i])
        @objects = objects
      else
        @_settleLayoutsAfter => @_rereadNoSettle()
        InspectorBrowserWdgt.showChoice @, undefined
        return
    @verbsBand?.reflectVerbs()
    InspectorBrowserWdgt.showChoice @, @_objectOfRow(@objects, label, place)

  # THE OBJECT A PRESSED ROW STANDS FOR among `objects` (mine, parallel to my labels), or undefined:
  # the object at the row's `place` while my label there is the row's `label`, and only while it is
  # still in my derivation as it stands now (chooseRow's second and third rules). A query.
  _objectOfRow: (objects, label, place) ->
    object = objects[place]  if @labels[place] is label
    object  if object? and object in @[@derivationName]()

  # WHAT A ROW OF MINE OPENS IN A NEW INSPECTOR (my list's newInspectorQuery:
  # ListWdgt.toOpenInANewInspectorBy hands me the row's label and place): the object its press would
  # choose among the objects I HOLD, by chooseRow's second and third rules (_objectOfRow: my label at
  # the row's place the row's, the object still in my derivation), named by the row's label, the words
  # it shows; undefined where that press would choose nothing. Holding no objects -- a copy or a
  # restore of me, before its first press -- my rows name nothing yet: I derive no rows again for the
  # question. A menu that offers the row is built on its answer (Widget.buildContextMenu,
  # buildHierarchyMenu), and deriving my rows LABELS every listed object (_derivedRows), running a
  # person's code (a listed widget's injected colloquialName, which can throw), so the answer reads what
  # I hold -- the third rule reads my derivation's objects alone, labelling none -- and a menu build
  # runs nothing of a person's. A Cmd-click on such a row is a plain press, whose own derivation holds
  # the objects from then on (chooseRow's first rule). A query, as the press is not: it never builds my
  # list again, and holds no objects.
  objectToOpenInANewInspector: (label, place) ->
    object = @_objectOfRow @objects, label, place  if @objects?
    {subject: object, name: label}  if object?

  #: testing

  # DO I LIST NOTHING? My derivation answered no object as I last read it: my labels, parallel to my
  # objects and carried by copies and files, are none (my list then shows its placeholder row). Asked by
  # the inspector that shows me as the view a walk keeps (InspectorWdgt._keepTheWalksViewNoSettle: a
  # walk whose view lists nothing shows its first view instead).
  listsNothing: ->
    @labels.length is 0

  #: choosing

  # THE LABEL OF MY CHOSEN ROW, while that row chose `subject`, else undefined: my list's selected row
  # (ListWdgt.selected), honoured as chooseRow honours a press -- my label at the row's place is the
  # row's own -- and, while I hold my objects, only when my object there IS `subject`: the step after
  # my inspector in its browser may be another than the one my row chose (a person took the inspector
  # my row chose out of the browser, and the next one now follows mine), and that step names nothing of
  # mine. A copy or a restore of me holds no objects until its first press (my header says why), and
  # its row, true at its place, is taken for what it chose. Asked by my inspector, as it names the
  # choice made in me on its browser's trail and keeps a walk's view (InspectorWdgt.nameOfMyChoice,
  # titleOfMyChoice).
  chosenRowLabelFor: (subject) ->
    row = @list?.selected
    return undefined  unless row? and @labels[row.argumentToAction1] is row.labelString
    row.labelString  unless @objects? and @objects[row.argumentToAction1] isnt subject

  # NO ROW OF MINE IS CHOSEN any more (my inspector's class button pressed: InspectorWdgt.chooseMyClass;
  # or my subject chosen again: my inspector's reload). My list drops its selection, and my verbs follow;
  # nothing is derived again. Paint only, so a core both doors reach.
  clearChoice: ->
    @_reloadNoSettle()

  _reloadNoSettle: ->
    @list?.clearSelection()
    @verbsBand?.reflectVerbs()
    return
