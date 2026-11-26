# A MEMBER LIST: an inspector's view of one object's members -- which ones it has, as a list of
# rows, each a kind tag and the member's name -- and, for a subject whose members are edited
# (MemberRef.canEdit), the gestures that change WHICH members it has: Add… Duplicate… Rename…
# Remove. A row chosen is a CHOICE (InspectorBrowserWdgt.showChoice): the inspector to my right shows
# that member (a click: its editor, MemberEditorWdgt) or that member's value (a double-click, when
# the value has members to show: an object, or a class), so I show no member's code myself. I stand
# in an inspector (InspectorWdgt) whose subject is my inspectedObject, its first view; picked out of
# it, I still list and edit it.
#   Top to bottom, the elements of a vertical DIVISION stack (StackLayoutEngine), each a band of mine
# or my list: my TOGGLES band (BandWdgt), my member LIST, which takes the slack, my CUT-NOTICE band
# when my list cuts an indexed subject's items, and my FOOTER band of buttons when my subject's
# members are edited. I have no layout of my own. In an inspector I paint nothing -- my bands paint
# their rules, and the browser paints the body under all of us -- and standing anywhere else I paint
# that body myself (InspectorBodyAppearance): one body under my bands, one shadow.
#   My TOGGLES (LabelledToggleWdgt) show my member FILTER -- Methods, Fields, Inherited, Own props
# only (none for a class's prototype, whose every member is its class's) -- whose one truth is my
# showing* fields. A click on a toggle runs its action (toggleShowing*), which flips that field and
# RE-FILTERS me (_refilterMembers): my member list is rebuilt from the filter as it stands,
# every other child of mine stays the same widget, and every toggle is shown its field. Adding,
# duplicating, renaming or removing a member re-filters me the same way. A re-filter's fresh list
# selects nothing, so what stood on my right for its selection goes (InspectorBrowserWdgt.showChoice,
# with no subject): every gesture of mine asks the browser AFTER its own settle, never inside it.
#   Each edit is ONE step of the member's reference (MemberRef.of: an object's member through the
# instance edit protocol, a class's through its meta-object, recorded), which makes the edit, tells
# once, and answers whether it made it: a step that refuses (a class's member with no source to
# copy, a paint tool's member under a name its surface owns) changes nothing, so the gesture neither
# re-filters nor drops the selection.
#   A NEW member's name -- the one an Add…, a Duplicate… or a Rename… gives -- is one my subject does
# not already answer, its own or inherited (_refusesAsAnAnsweredName refuses an answered one, in one
# sentence): no gesture of mine overwrites a member or stands an own one over an inherited one. My
# subject's own version of an inherited member is made by choosing that member and pressing Save.
class MemberListWdgt extends Widget

  # I show what the class MEMBER MAPS record and edit a class through them (my gestures' class steps
  # read a member's recorded source), and they exist only once the reflective layer has arrived, which
  # on a `sources: "lazy"` build it has not until someone asks. Opening an inspector asks first
  # (Widget.spawnInspector); restoring me from a file asks because of this declaration
  # (Deserializer._needsTheReflectiveLayer, which both file doors consult).
  readsClassMemberMaps: true

  # the object whose members I list, and deliberately not called `target`: `@target` elsewhere means
  # information flow (a dataflow consumer, a dispatch receiver) or a tracked reference edge, and
  # reading one as the other is the hazard this name exists to remove
  inspectedObject: undefined
  # my member list (a ListWdgt in member mode), built again at every re-filter
  list: undefined
  # my band saying my list cuts an indexed subject's items, built only when it does
  cutNoticeBand: undefined
  # my footer band, built only while my subject's members are edited
  footerBand: undefined

  # my filter's TOGGLES (LabelledToggleWdgt), each ON exactly while the showing* field it stands for
  # is true (_reflectFiltersOnToggles). A class's prototype gets no own-props toggle, so that field
  # stays undefined there.
  showMethodsToggle: undefined
  showFieldsToggle: undefined
  showInheritedToggle: undefined
  showOwnPropsOnlyToggle: undefined

  # my member FILTER (_filteredMemberNames), and the one place its state lives: my toggles show it,
  # and a toggle's action flips it here (toggleShowing*).
  showingFields: true
  showingMethods: true
  showingInherited: false
  showingOwnPropsOnly: false

  # my footer band's buttons. Duplicate, rename and remove act on the selected member and are enabled
  # exactly while one is selected that they can act on. A disabled button still catches a press and
  # does nothing.
  addPropertyButton: undefined
  duplicatePropertyButton: undefined
  renamePropertyButton: undefined
  removePropertyButton: undefined

  # At most this many ITEMS of an indexed subject are listed, and at most this many objects in an
  # object list (ObjectListWdgt): a person scrolls a list, and no list of a million rows is one -- a
  # surface's pixel buffer, reached by drilling into a canvas, holds millions, and every row is a
  # widget. A cut list is said in a cut-notice band (cutNoticeBandFor).
  @MOST_ITEMS_LISTED: 1000

  # THE CUT-NOTICE BAND of a list that shows `listed` of `count` things, or undefined when it shows
  # them all: the one statement of the band both list views build (mine and ObjectListWdgt's). Its text
  # gives way as an inspector's title does (BandWdgt's `gives` item): the band's spring, cropped with
  # "…" where the band is narrower than it, so its length is in none of the list's widths. As tall as an
  # inspector's header, its rule along its top.
  @cutNoticeBandFor: (listed, count) ->
    return undefined unless count > listed
    theme = WorldWdgt.theme
    noticeText = new StringWdgt ("The first " + listed + " of " + count + " items are listed."), fontRole: theme.fonts.buttonLabel
    new BandWdgt theme.inspectorHeaderHeight, [theme.inspectorHeaderInset, {gives: noticeText}, theme.inspectorHeaderInset], rule: "top"

  # A LIST DRESSED AS A VIEW'S: it takes no drops; it wears the inspector's pane roles
  # (ViewportWdgt.wearPaneRoles; its plane wears them too), read as it paints and kept by name, so the
  # body and the bands' rules show through it; and its division box is a chrome target's side square,
  # least and desired, and grows to any size, so the slack of the view's stack is the list's. The one
  # statement both list views dress their list by (mine and ObjectListWdgt's).
  @dressAsAViewsList: (list) ->
    list.disableDrops()
    list.wearPaneRoles fill: "inspectorPaneFill", stroke: "inspectorPaneStroke"
    side = WorldWdgt.theme.minimumTargetSize
    square = new Point side, side
    list.setMinAndMaxBoundsAndSpreadability square, square, DivisionStackLayoutSpec.SPREADABILITY_SPACERS

  # The subject is my identity, my one positional parameter. My own division box takes my
  # inspector's slack: its most size is large, while my least and desired sizes are my bands' and my
  # list's, which the stack derives.
  constructor: (@inspectedObject) ->
    super()
    @appearance = new InspectorBodyAppearance @
    @setMinAndMaxBoundsAndSpreadability (new Point 1, 1), (new Point 1, 1), DivisionStackLayoutSpec.SPREADABILITY_SPACERS
    @_buildAndConnectChildren()

  # MY SHADOW IS THE BODY'S BOX, my parts' silhouettes left out, while I paint the body
  # (InspectorBodyAppearance.castsOnlyTheBody says when, and its header why); otherwise my base's pass.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if @appearance.castsOnlyTheBody appliedShadow
      @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    else
      super

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns
  # settled). Built once, at construction: a filter change or a member add / duplicate / rename /
  # remove rebuilds only my member list (_refilterMembers), and every other child stays.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    theme = WorldWdgt.theme

    # my filter's toggles, each with its fixed label and the one action that flips its field, between
    # toggleBandInset at each end of their band (after its spring at the right end); the state each
    # shows is set from my filter once they all exist (_reflectFiltersOnToggles, below)
    @showMethodsToggle = new LabelledToggleWdgt target: @, action: "toggleShowingMethods", face: "Methods"
    @showFieldsToggle = new LabelledToggleWdgt target: @, action: "toggleShowingFields", face: "Fields"
    @showInheritedToggle = new LabelledToggleWdgt target: @, action: "toggleShowingInherited", face: "Inherited"
    toggles = [theme.toggleBandInset, @showMethodsToggle, theme.toggleBandGap, @showFieldsToggle, theme.toggleBandGap, @showInheritedToggle]
    # a class's prototype gets no own-props toggle: every member it lists is its class's
    unless isAClassPrototype @inspectedObject
      @showOwnPropsOnlyToggle = new LabelledToggleWdgt target: @, action: "toggleShowingOwnPropsOnly", face: "Own props only"
      toggles.push theme.toggleBandGap, @showOwnPropsOnlyToggle
    toggles.push BandWdgt.SPRING, theme.toggleBandInset
    @_addCellNoSettle new BandWdgt theme.toggleBandHeight, toggles, rule: "bottom"
    @_reflectFiltersOnToggles()

    @_buildAndConnectMemberList()

    # my cut notice, when my list cuts an indexed subject's items, so the list never reads as the whole
    # collection
    {items, itemCount} = @_subjectsItemsAndNames()
    @cutNoticeBand = MemberListWdgt.cutNoticeBandFor items.length, itemCount
    @_addCellNoSettle @cutNoticeBand  if @cutNoticeBand?

    @_buildAndConnectEditRow() if MemberRef.canEdit @inspectedObject

    # my member buttons' enabled states: a fresh list selects nothing, so disabled
    @_reflectMemberSelection()
    @_invalidateLayout()

  # a child of mine added as the next element of my vertical division stack
  _addCellNoSettle: (cell) ->
    @_addNoSettle cell, layoutSpec: cell.divisionBox('y')

  # The EDIT ROW -- my footer band and its buttons -- as ONE unit: built together, so it exists or it
  # does not. A subject whose members no step edits gets a READ-ONLY list, which is the honest
  # presentation rather than a degraded one; offering controls that could only refuse is worse than
  # offering none (the same reasoning `createDesktop` uses to skip an app icon a profile cannot
  # provide). Add… Duplicate… Rename… Remove at the band's left, footerInset in and footerGap apart,
  # and footerInset again after the band's spring: every band of mine ends with its inset, so its
  # least width keeps that inset clear on the right of its last control too.
  _buildAndConnectEditRow: ->
    theme = WorldWdgt.theme
    @addPropertyButton = new SimpleButtonWdgt target: @, action: "addPropertyPopout", face: "Add…"
    @duplicatePropertyButton = new SimpleButtonWdgt target: @, action: "duplicatePropertyPopout", face: "Duplicate…"
    @renamePropertyButton = new SimpleButtonWdgt target: @, action: "renamePropertyPopout", face: "Rename…"
    @removePropertyButton = new SimpleButtonWdgt target: @, action: "removeProperty", face: "Remove"
    buttons = [theme.footerInset, @addPropertyButton, theme.footerGap, @duplicatePropertyButton, theme.footerGap, @renamePropertyButton, theme.footerGap, @removePropertyButton, BandWdgt.SPRING, theme.footerInset]
    @footerBand = new BandWdgt theme.footerBandHeight, buttons, rule: "top"
    @_addCellNoSettle @footerBand

  # My toggles' ACTIONS, one per toggle (a toggle hands itself in slot 1; none of them needs it).
  # Each flips the filter field its toggle stands for and re-filters me, in ONE settle: the field is
  # the filter's truth, and the re-filter shows every toggle its field (_reflectFiltersOnToggles).
  # Then, after that settle, what stood on my right for my old list's selection goes: my fresh list
  # selects nothing.
  toggleShowingMethods: ->
    @_settleLayoutsAfter =>
      @showingMethods = !@showingMethods
      @_refilterMembersNoSettle()
    InspectorBrowserWdgt.showChoice @, undefined

  toggleShowingFields: ->
    @_settleLayoutsAfter =>
      @showingFields = !@showingFields
      @_refilterMembersNoSettle()
    InspectorBrowserWdgt.showChoice @, undefined

  toggleShowingInherited: ->
    @_settleLayoutsAfter =>
      @showingInherited = !@showingInherited
      @_refilterMembersNoSettle()
    InspectorBrowserWdgt.showChoice @, undefined

  toggleShowingOwnPropsOnly: ->
    @_settleLayoutsAfter =>
      @showingOwnPropsOnly = !@showingOwnPropsOnly
      @_refilterMembersNoSettle()
    InspectorBrowserWdgt.showChoice @, undefined

  # My subject's ITEMS -- an INDEXED subject's: an Array's (a subclass's too), a typed array's (a buffer
  # view with a length; a DataView has none), a string's -- the first MOST_ITEMS_LISTED of them in index
  # order, `itemCount` how many it holds; and the names of its other enumerable members, own and
  # inherited (`named`). Any other subject has no items: every name is a member's.
  #   A typed array's or a string's items are its indices below its length, and they are all its own
  # names, so only its chain is walked for the others: a walk of its own names costs a key per item
  # (a surface's pixels: millions, every time the list is built). An Array's items are the indices it
  # HOLDS, read off the one walk of its names -- a sparse Array holds fewer than its length.
  _subjectsItemsAndNames: ->
    o = @inspectedObject
    most = MemberListWdgt.MOST_ITEMS_LISTED
    if typeof o is "string" or (NativeValueKinds.isBufferView(o) and typeof o.length is "number")
      named = (property for property of Object.getPrototypeOf o)
      return {items: (String i for i in [0...Math.min o.length, most]), itemCount: o.length, named}
    items = []
    named = []
    itemCount = 0
    holdsItems = o instanceof Array
    for property of o
      if holdsItems and MemberListWdgt._isAnIndex property
        itemCount++
        items.push property if items.length < most
      else
        named.push property
    {items, itemCount, named}

  # Is `name` an array index ("0", "1", ... below 2^32 - 1), as an indexed subject's items are named?
  @_isAnIndex: (name) ->
    /^(0|[1-9]\d*)$/.test(name) and Number(name) < 4294967295

  # Duplicate, rename and remove act on the SELECTED member, so they are enabled exactly while my
  # list has a selection they can act on (_selectedMemberCanBeRenamedOrRemoved): disabled as built,
  # then following each selection (selectionFromList, a row that names no member included) until my
  # next re-filter, whose fresh list selects nothing, or until my choice is dropped (clearChoice, and
  # my reload: _reloadNoSettle). The actions ask the same question, since other callers reach them
  # directly. A read-only list has none of the three.
  _reflectMemberSelection: ->
    offered = @_selectedMemberCanBeRenamedOrRemoved()
    @duplicatePropertyButton?.setEnabled offered
    @renamePropertyButton?.setEnabled offered
    @removePropertyButton?.setEnabled offered

  # Duplicate, rename and remove act only on a member my member reference can act on: one my subject
  # OWNS, and never `constructor` (MemberRef.canBeRenamedOrRemoved says why). Nor on anything, while
  # my subject's members are edited by no step (MemberRef.canEdit).
  _selectedMemberCanBeRenamedOrRemoved: ->
    name = @_selectedMemberName()
    name? and (MemberRef.canEdit @inspectedObject) and MemberRef.of(@inspectedObject, name).canBeRenamedOrRemoved()

  # THE MEMBER A LABEL OF MY LIST NAMES, or undefined: a label that names no member of my subject is
  # no member, and nothing of mine chooses it or acts on it. My list's rows are my subject's members
  # but for one: a list built from no names shows one placeholder row, "(empty)", in its own words
  # (ListWdgt), and holds that label as its one element, so its elements cannot tell the placeholder
  # from a member of that name; my subject can, for every name my list is built from is one of its
  # properties (_subjectsItemsAndNames), and the placeholder is none -- unless my subject has a member
  # of that very name, one my filter hides, which the placeholder then names. Asked as an object, so a
  # string's items are found. Every reader of a label of mine asks here: a choice (selectionFromList,
  # inspectMemberValue) and my member buttons, through my selection (_selectedMemberName).
  _memberNamedBy: (label) ->
    label  if label? and label of Object @inspectedObject

  # the member my list's selected row names, or undefined: none selected, or the placeholder
  _selectedMemberName: ->
    @_memberNamedBy @list?.selected?.labelString

  # My toggles show my filter: each is ON exactly while the showing* field it stands for is true.
  # The build and every re-filter end here, and nothing else sets a toggle of mine, so a toggle and
  # its field cannot disagree; a toggle taken out of me still stands for my field and follows it.
  _reflectFiltersOnToggles: ->
    @showMethodsToggle.setOn @showingMethods
    @showFieldsToggle.setOn @showingFields
    @showInheritedToggle.setOn @showingInherited
    @showOwnPropsOnlyToggle?.setOn @showingOwnPropsOnly

  # A RE-FILTER: my member set may have changed -- a toggle flipped my filter, or a member was added,
  # duplicated, renamed or removed -- so my member LIST is built again from my filter as it stands
  # (_buildAndConnectMemberList), and nothing else is: my toggles and my bands stay the same widgets.
  # What showed the old list's selection shows none, as at my construction: no member is
  # selected, and my member buttons are disabled (_reflectMemberSelection). My toggles are then shown
  # my filter.
  _refilterMembers: ->
    @_settleLayoutsAfter => @_refilterMembersNoSettle()

  _refilterMembersNoSettle: ->
    @_buildAndConnectMemberList()
    @_reflectMemberSelection()
    @_reflectFiltersOnToggles()
    @_invalidateLayout()

  # MY LIST READ AGAIN, as my inspector asks when its chooser's lit toggle, mine, is pressed
  # (InspectorWdgt._showViewNoSettle): a re-filter, keeping my filter as it stands. The name every view
  # a chooser offers answers (ObjectListWdgt's derives its list again). A core: my inspector calls it
  # inside its switch's settle.
  _rereadNoSettle: ->
    @_refilterMembersNoSettle()

  # The names of the members my filter lets through, in the order my list shows them. It starts
  # from every enumerable property of my subject and of its whole prototype chain (a Fizzygum
  # class's members are enumerable, its methods included) and keeps:
  #   methods      only while showingMethods
  #   fields       only while showingFields
  #   inherited    while showingInherited; otherwise only the members my subject's own class
  #                declares, and those stitched onto my subject that no class of its chain has
  #   own props    while showingOwnPropsOnly, only my subject's own properties
  # sorted -- after an INDEXED subject's items (an Array's, a typed array's), which come first in index
  # order, whose order is their meaning, and at most MOST_ITEMS_LISTED of them.
  _filteredMemberNames: ->
    {items, named} = @_subjectsItemsAndNames()
    attribs = (property for property in named when property)

    if !@showingMethods
      attribs = attribs.filter (prop) => !Utils.isFunction @inspectedObject[prop]

    if !@showingFields
      attribs = attribs.filter (prop) => Utils.isFunction @inspectedObject[prop]

    # if we don't show inherited props, then we let through two types of props (each side of the "or"
    # takes care of one type):
    #   1) the ones that are defined in the immediate class of the object (i.e. are own properties of the prototype)
    #   2) the ones that are just stitched to the object but are in none of the classes upwards i.e.
    #      are not a reachable property from the prototype
    if !@showingInherited and (classPrototype = @_subjectsClassPrototype())?
      attribs = attribs.filter (prop) => Object::hasOwnProperty.call(classPrototype, prop) or (prop not of classPrototype)

    if @showingOwnPropsOnly
      attribs = attribs.filter (prop) => Object::hasOwnProperty.call @inspectedObject, prop

    attribs.sort()
    # an indexed subject's ITEMS first, in their order (each its own, so the inherited and own-props
    # filters keep them all; an Array may hold functions, so the methods and fields toggles hold for
    # them too)
    items = items.filter((i) => !Utils.isFunction @inspectedObject[i]) if !@showingMethods
    items = items.filter((i) => Utils.isFunction @inspectedObject[i]) if !@showingFields
    items.concat attribs

  # My member LIST, built from the names my filter lets through (_filteredMemberNames) and added to
  # me as the element after my toggles band. The build makes the first one; a re-filter makes it again:
  # the list it replaces, while still mine, is destroyed, and the new one takes its place among my
  # children; a list taken out of me is not mine to replace, so it stays where it is and the new one
  # stands before my cut-notice and footer bands. A fresh list selects nothing and shows its first rows.
  #   A MEMBER list: each row a kind tag and the member's name, as wide as the list (MemberRowWdgt),
  # told what each member is by my memberFactsOf. Everything the list reaches me through is a method
  # NAME -- a click selects a member (selectionFromList), a double-click opens its value
  # (inspectMemberValue) -- so a copy of me is reached by its own list, and the list holds no
  # closure. It is dressed as a view's list (dressAsAViewsList): no drops, the inspector's pane roles,
  # kept by name, so the body and my bands' rules show through it and a list taken out of me keeps
  # them, and a division box a chrome target's side square at least, growing to any size: the slack of
  # my stack is its, while my bands state my width.
  _buildAndConnectMemberList: ->
    if @list?.parent is @
      atIndex = @children.indexOf @list
      @list._fullDestroyNoSettle()
    else
      atIndex = (@children.indexOf band for band in [@cutNoticeBand, @footerBand] when band?.parent is @)[0]

    @list = new ListWdgt @_filteredMemberNames(),
      target: @
      action: "selectionFromList"
      doubleClickAction: "inspectMemberValue"
      memberFactsQuery: "memberFactsOf"
    MemberListWdgt.dressAsAViewsList @list
    @_addNoSettle @list, atIndex: atIndex, layoutSpec: @list.divisionBox('y')

  # WHAT MY LIST SHOWS OF A MEMBER beside its name (my list's memberFactsQuery, asked once per row
  # as the list is built): its KIND TAG -- "fn" for a function, "var" for anything else, the split my
  # methods and fields toggles filter by -- and whether its name is DIMMED: dimmed unless my subject's
  # own class declares it, so a member inherited from a superclass, or stitched onto my subject with
  # no class declaring it, reads muted, and a member of my subject's own class reads in ink.
  #
  # TODO show the static methods and variables in yet another color.
  memberFactsOf: (memberName) ->
    kindTag: if Utils.isFunction @inspectedObject[memberName] then "fn" else "var"
    dimmed: !((classPrototype = @_subjectsClassPrototype())? and Object::hasOwnProperty.call classPrototype, memberName)

  # The prototype my subject's class gives its instances, or undefined for a subject made with NO prototype
  # (Object.create null -- a meta-object's record store, a run's own): no class declares any member of such a
  # subject, so every one is its own, and its members are read with Object's methods, never its own.
  _subjectsClassPrototype: ->
    classPrototype = @inspectedObject?.constructor?.prototype
    classPrototype if classPrototype? and typeof classPrototype is "object"

  # A CLICK on a member row (ListWdgt.select hands me its member's name, my list's selection already
  # moved to that row): my member buttons follow the selection, and the member is my CHOICE -- the
  # inspector on my right shows it (InspectorBrowserWdgt.showChoice; the member's reference, MemberRef.of,
  # says how it is edited). The same member chosen again is reloaded there: its saved text put back
  # over unsaved typing, as one step of its undo history. A label that names no member (my list's
  # placeholder, a row whose member has gone since my list was built: _memberNamedBy) is NO choice,
  # and said as one: my buttons show no member to act on, and what stood on my right for the row
  # chosen before goes. With nothing on my right, that changes nothing a person sees.
  selectionFromList: (selected) ->
    @_reflectMemberSelection()
    name = @_memberNamedBy selected
    InspectorBrowserWdgt.showChoice @, (if name? then MemberRef.of(@inspectedObject, name))

  # A CHOICE MADE FOR THE PERSON, as their own clicks would make it (InspectorBrowserWdgt.chooseMember):
  # the member `name` of my subject. Hidden by my filter -- a member a superclass declares, an own
  # version of one included, while my Inherited toggle is off -- my Inherited toggle is turned on
  # first, as its click turns it on (toggleShowingInherited). Then its row is clicked (my list's
  # select, which hands me the row: selectionFromList), so my buttons follow it and its editor stands
  # right of me, and last the row is scrolled WHOLE into my list's view (ListWdgt.scrollRowIntoView),
  # read off the geometry that choice's settle left. A name my subject does not answer
  # (_memberNamedBy) chooses nothing, and says nothing: the window stands with nothing chosen. So does
  # a member my filter hides some other way (Fields, Methods or Own props only, a person's re-filter):
  # only Inherited is turned on for it.
  chooseMember: (name) ->
    return unless @_memberNamedBy(name)?
    @toggleShowingInherited()  unless @showingInherited or @list.rowLabelled(name)?
    row = @list.rowLabelled name
    return unless row?
    @list.select row
    @list.scrollRowIntoView row
    return

  # A DOUBLE-CLICK on a member row (ListWdgt.openRow hands me its member's name, after the click that
  # chose the member): when the member's VALUE has members of its own to show -- an object, or a
  # Fizzygum CLASS (a function carrying the class marker, as classNamed tells it: a widget's
  # `constructor` row) -- that value is my choice, in place of the member, so the inspector on my right
  # shows it (a class function's `__super__` its superclass's prototype, edited as that class,
  # MemberRef.of). Any other value -- a method, a number, a string -- opens nothing more: the click
  # already chose the row, and its editor stands. So does a label that names no member (_memberNamedBy).
  inspectMemberValue: (memberName) ->
    return unless (name = @_memberNamedBy memberName)?
    value = @inspectedObject[name]
    hasMembersToShow = value? and (typeof value is "object" or (Utils.isFunction(value) and classNamed(value.name) is value))
    return unless hasMembersToShow
    InspectorBrowserWdgt.showChoice @, value

  # NO ROW OF MINE IS CHOSEN any more: what stands on my right shows something other than my choice,
  # or nothing, so my list drops its selection (ListWdgt.clearSelection) and my member buttons follow.
  # One act, two doors: my inspector's class chip pressed (InspectorWdgt.chooseMyClass, at the press,
  # before my browser settles the choice), and my subject chosen again (my inspector's reload, inside
  # my browser's settle, which removes what stood right of it): a list holds no text to put back, so
  # this is its reload. Paint only -- my selected row's look and my buttons' -- so a core both doors
  # reach.
  clearChoice: ->
    @_reloadNoSettle()

  _reloadNoSettle: ->
    @list?.clearSelection()
    @_reflectMemberSelection()
    return

  # MY EDITS. Each of my four edit gestures -- Add…, Duplicate…, Rename…, Remove -- is one STEP of my
  # member's reference (MemberRef.of: its add, duplicate, rename and remove), which makes the edit,
  # records it where a world snapshot needs it, tells ONCE, and answers whether it made it. My member
  # set changed, so I re-filter (_refilterMembers), and what stood on my right for my selection goes
  # (InspectorBrowserWdgt.showChoice, with no subject), after my settle. A step that refused changed
  # nothing, so I keep my list and my choice as they are.

  # The add, past the prompt (addPropertyPopout). Refused: the name `constructor`
  # (_refusesAsANewMemberName), and a name my subject already ANSWERS, its own or one it inherits
  # (_refusesAsAnAnsweredName) -- an add never overwrites a member nor stands over one my subject
  # inherits, so I say so, as a duplicate and a rename do. My subject's own version of an inherited
  # member is made by choosing that member and pressing Save.
  addProperty: (prop) ->
    return unless prop? and (MemberRef.canEdit @inspectedObject)
    return if @_refusesAsANewMemberName(prop) or @_refusesAsAnAnsweredName(prop, "a new member")
    return unless MemberRef.of(@inspectedObject, prop).add()
    @_refilterMembers()
    InspectorBrowserWdgt.showChoice @, undefined

  # `constructor` is no name a member can take: a widget's or a prototype's `constructor` is its
  # class, what every `.constructor` read answers (Class.refuseTheConstructor), so Add…, Duplicate…
  # and Rename… refuse it, saying why, its name quoted as a message that starts with a member's name
  # quotes it (_refusesAsAnAnsweredName says why). Answers whether it refused.
  _refusesAsANewMemberName: (name) ->
    return false unless name is "constructor"
    @inform '"constructor" is the class\nitself: no member can\ntake its name'
    true

  # A NAME MY SUBJECT ALREADY ANSWERS is no name a NEW member can take: its own member's, or one it
  # inherits. Add…, Duplicate… and Rename… each make a member under a new name, and under a name
  # answered already that member would overwrite an own one, or stand over an inherited one and change
  # what my subject answers (an Add… of `color` on a rectangle: an own member holding nothing, so the
  # rectangle paints no fill). So each refuses such a name, saying so in one sentence that names the
  # gesture's member (`noun`: "a new member", "a duplicate", "a rename"). An own version of an inherited
  # member -- one object's, or one class's over its superclass's -- is made the one way that stays:
  # choose that member (the Inherited filter lists it) and press Save.
  #   The test is the `of` test on my subject. Every caller asks it of a subject my edits reach
  # (MemberRef.canEdit: a widget, a Fizzygum class's prototype), and on those it never throws and runs
  # no getter: on a WIDGET it answers its own members, its class's, every superclass's and Object's
  # (`toString`); on a class's PROTOTYPE, the members the class defines, every superclass's and
  # Object's. Asked after the refusal of `constructor` (_refusesAsANewMemberName), which every subject
  # answers and which has words of its own. The one statement of the rule and of its words. Answers
  # whether it refused.
  #   A MESSAGE THAT STARTS WITH A MEMBER'S NAME QUOTES IT ("color" is a member…): a pop-up shows its
  # message with its first character a capital (FrameWdgt._titleDisplayCase, "sentence"), and a
  # member's name is case-sensitive -- `Color` would name another member. Quoted, the first character
  # is the quote mark and the name keeps its case. The same rule quotes `constructor`'s refusal
  # (_refusesAsANewMemberName) and a class member's copy refused for want of a source
  # (ClassMemberRef._editCopyUnder).
  _refusesAsAnAnsweredName: (name, noun) ->
    return false unless name of @inspectedObject
    @inform '"' + name + '" is a member\nalready: ' + noun + "\nreplaces no member"
    true

  addPropertyPopout: ->
    # Chrome cannot handle empty strings (others do), hence the "property" default
    @prompt "new property name:", @, "addProperty", defaultContents: "property"

  # A duplicate, past the prompt (duplicatePropertyPopout): the selected member, kept, and a copy of it
  # under the name given. A duplicate of a member I do not offer to duplicate does nothing
  # (_selectedMemberCanBeRenamedOrRemoved), as a click on my disabled button does. Refused: the name
  # `constructor` (_refusesAsANewMemberName), and a name my subject already ANSWERS, its own or one it
  # inherits, the selected member's own included (_refusesAsAnAnsweredName) -- a copy never overwrites
  # a member nor stands over one my subject inherits, so I say so.
  duplicateProperty: (newName) ->
    return unless newName? and @_selectedMemberCanBeRenamedOrRemoved()
    propertyName = @_selectedMemberName()
    return if @_refusesAsANewMemberName(newName) or @_refusesAsAnAnsweredName(newName, "a duplicate")
    return unless MemberRef.of(@inspectedObject, propertyName).duplicate newName
    @_refilterMembers()
    InspectorBrowserWdgt.showChoice @, undefined

  duplicatePropertyPopout: ->
    # no member selected = nothing to duplicate: a fresh list has NO default selection, and its
    # placeholder row names no member (_selectedMemberName)
    unless @_selectedMemberName()?
      world.inform "select a\nproperty first"
      return
    return unless @_selectedMemberCanBeRenamedOrRemoved()
    propertyName = @_selectedMemberName()
    @prompt "name of the copy:", @, "duplicateProperty", defaultContents: propertyName

  # A rename to the name the member already has changes nothing, so it does nothing, and says
  # nothing, before any refusal is asked (each step's move would otherwise drop the member it moves
  # onto itself); so does a rename handed no name (a prompt cancelled), as an add and a duplicate do,
  # and a rename of a member I do not offer to rename (_selectedMemberCanBeRenamedOrRemoved), as a
  # click on my disabled button does. Refused: the name
  # `constructor` (_refusesAsANewMemberName), and any other name my subject already ANSWERS, its own or
  # one it inherits (_refusesAsAnAnsweredName) -- a rename never overwrites another member nor stands
  # over one my subject inherits, so I say so.
  renameProperty: (prop) ->
    return unless prop? and @_selectedMemberCanBeRenamedOrRemoved()
    propertyName = @_selectedMemberName()
    return if prop is propertyName
    return if @_refusesAsANewMemberName(prop) or @_refusesAsAnAnsweredName(prop, "a rename")
    return unless MemberRef.of(@inspectedObject, propertyName).rename prop
    @_refilterMembers()
    InspectorBrowserWdgt.showChoice @, undefined

  renamePropertyPopout: ->
    # no member selected = nothing to rename (see duplicatePropertyPopout)
    unless @_selectedMemberName()?
      world.inform "select a\nproperty first"
      return
    return unless @_selectedMemberCanBeRenamedOrRemoved()
    propertyName = @_selectedMemberName()
    @prompt "property name:", @, "renameProperty", defaultContents: propertyName

  removeProperty: ->
    # no member selected = nothing to remove (see duplicatePropertyPopout), and a member I do not
    # offer to remove stays (_selectedMemberCanBeRenamedOrRemoved)
    unless @_selectedMemberName()?
      world.inform "select a\nproperty first"
      return
    return unless @_selectedMemberCanBeRenamedOrRemoved()
    propertyName = @_selectedMemberName()
    return unless MemberRef.of(@inspectedObject, propertyName).remove()
    @_refilterMembers()
    InspectorBrowserWdgt.showChoice @, undefined
