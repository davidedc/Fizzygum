# AN OBJECT LIST: an inspector's view of the OBJECTS its subject holds in one way, one row per object
# -- a widget's CHILDREN (the parts copies and saves carry), a class's INSTANCES (its subclasses'
# included, as its class's instances set holds them), or a class's direct SUBCLASSES (sorted by name).
# A row chosen is a CHOICE (InspectorBrowserWdgt.showChoice): the inspector to my right shows that object.
# I stand in an inspector (InspectorWdgt), whose chooser builds me; picked out of it, I still list and
# choose.
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
# inspector's lit chooser toggle (_rereadNoSettle) and a copy's first press that finds it stale.
#   Top to bottom, the elements of a vertical DIVISION stack (StackLayoutEngine): my LIST, which takes
# the slack, dressed as every view's list is (MemberListWdgt.dressAsAViewsList), and my CUT-NOTICE band
# when I list only the first MemberListWdgt.MOST_ITEMS_LISTED. In an inspector I paint nothing;
# standing anywhere else I paint the inspector's body (InspectorBodyAppearance).
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
  # my objects, in my list's rows' order, parallel to my labels: transient for both walkers (below)
  objects: undefined
  # the labels my list was built from, in its rows' order (possibly none: my list then shows its
  # placeholder row, "(empty)"). Carried by copies and files: a copy's first press compares them
  labels: undefined

  # my objects, in the array parallel to my labels: derived, never carried (my header says why)
  @serializationTransients: ["objects"]
  @copyTransients: ["objects"]

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

  # MY SHADOW IS THE BODY'S BOX, my parts' silhouettes left out, while I paint the body
  # (InspectorBodyAppearance.castsOnlyTheBody says when, and its header why); otherwise my base's pass.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if @appearance.castsOnlyTheBody appliedShadow
      @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    else
      super

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_rereadNoSettle()

  # MY LIST READ AGAIN from my subject as it stands, in this order: what it replaces goes FIRST -- my
  # list and my cut-notice band, each destroyed where it stands in me (one a person took out is theirs,
  # and stays where they put it), and the place my new list takes remembered: where my list stood, else
  # where my band stood, else my end --; THEN my objects and labels derived; then my list built
  # from them in that place, and my cut-notice band after it. A list is derived only once what it
  # replaces is gone: a derivation that runs while they stand lists and counts them (a class's
  # instances include my old list's own rows and labels), though they are destroyed a moment later.
  # At my build, at my inspector's lit chooser toggle (InspectorWdgt._showViewNoSettle, which asks
  # every view this by this name), and at a copy's first press that finds my list stale (chooseRow). A
  # fresh list selects nothing.
  _rereadNoSettle: ->
    if @list?.parent is @
      at = @children.indexOf @list
      @list._fullDestroyNoSettle()
    else if @cutNoticeBand?.parent is @
      at = @children.indexOf @cutNoticeBand
    @cutNoticeBand._fullDestroyNoSettle()  if @cutNoticeBand?.parent is @
    {objects, labels, count} = @_derivedRows()
    @objects = objects
    @labels = labels
    @_buildListNoSettle at
    @_buildCutNoticeNoSettle objects.length, count
    @_invalidateLayout()

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
  # click dispatches chooseRow; no double-click of its own (a click already opens the object). Dressed
  # as a view's list.
  _buildListNoSettle: (atIndex) ->
    @list = new ListWdgt @labels.slice(),
      target: @
      action: "chooseRow"
      memberFactsQuery: "objectRowFactsOf"
    MemberListWdgt.dressAsAViewsList @list
    @_addNoSettle @list, atIndex: atIndex, layoutSpec: @list.divisionBox('y')

  # my cut-notice band in step with my list (_rereadNoSettle has removed the one standing in me): a
  # fresh one at my end, after my list, when I list `listed` of `count` objects
  # (MemberListWdgt.cutNoticeBandFor), and none otherwise
  _buildCutNoticeNoSettle: (listed, count) ->
    @cutNoticeBand = MemberListWdgt.cutNoticeBandFor listed, count
    @_addNoSettle @cutNoticeBand, layoutSpec: @cutNoticeBand.divisionBox('y')  if @cutNoticeBand?

  # WHAT MY LIST SHOWS BESIDE A ROW'S NAME (my list's memberFactsQuery): no kind tag, and not dimmed.
  objectRowFactsOf: (ignored) ->
    kindTag: ""
    dimmed: false

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
  # No choice removes what stood on my right (InspectorBrowserWdgt.showChoice, with no subject), after any
  # settle of mine, as every gesture asks it.
  chooseRow: (label, place) ->
    unless @objects?
      {objects, labels} = @_derivedRows()
      if labels.length is @labels.length and labels.every((each, i) => each is @labels[i])
        @objects = objects
      else
        @_settleLayoutsAfter => @_rereadNoSettle()
        InspectorBrowserWdgt.showChoice @, undefined
        return
    object = @objects[place]  if @labels[place] is label
    stillThere = object? and object in @[@derivationName]()
    InspectorBrowserWdgt.showChoice @, (if stillThere then object)

  # NO ROW OF MINE IS CHOSEN any more (my inspector's class chip pressed: InspectorWdgt.chooseMyClass;
  # or my subject chosen again: my inspector's reload). My list drops its selection; nothing is derived
  # again. Paint only, so a core both doors reach.
  clearChoice: ->
    @_reloadNoSettle()

  _reloadNoSettle: ->
    @list?.clearSelection()
    return
