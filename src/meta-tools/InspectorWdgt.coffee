# The OBJECT INSPECTOR: a view of one object's members -- which ones it has, what each one holds
# or does -- and, for a subject that can service an edit, the place to edit them. Windowed by default
# (Widget.spawnInspector wraps me in a FrameWdgt), and also a first-class NAKED widget with a resizer
# of its own.
#
# I paint my own BODY in both modes, the `panel` fill (inspectorBodyFill), and my SEAMS over it
# (_seamRects, visual-design-system §4.1): my two panes are borderless and fill-less, and where
# they or my bands meet I leave a 1 px gap that my appearance rules, so every line inside me is
# mine. My box, top to bottom (_bandsIn):
#   - the BREADCRUMB band (_breadcrumbIn): the "Class" caption, then a chip per class of my
#     subject's chain, base class first, a drawn › between two chips, the last chip -- my subject's
#     own class, or a class inspector's own class -- the CURRENT one, then, while a mixin-donated
#     member is selected, the donor label; the pieces wrap to more rows where my width is less than
#     they need, and the band's last row is its rule;
#   - the TOGGLES band, toggleBandHeight tall, its rule included: my toggles at their own size,
#     toggleBandInset in and toggleBandGap apart, centred down the band;
#   - the BODY: the member list, inspectorListColumnWidth wide but never more than half my width,
#     then a 1 px seam, then the code pane out to my right edge;
#   - the FOOTER band (FooterBandLayout): Add… Rename… Remove at its left, Save -- the primary
#     action -- at its right. A read-only inspector (a subject that cannot service an edit) has no
#     footer band, and its body runs to my bottom.
# A band keeps its controls at their own size: where my width is less than a band's controls need,
# they run past my right edge -- the breadcrumb wraps instead, and only a piece wider than a whole
# row runs past it -- and I clip them there, naked or windowed alike.
#
# My TOGGLES (LabelledToggleWdgt) show my member FILTER -- Methods, Fields, Inherited, Own props
# only -- whose one truth is my showing* fields. A click on a toggle runs its action
# (toggleShowing*), which flips that field and RE-FILTERS me (_refilterMembers): my member list is
# rebuilt from the filter as it now stands, every other child of mine stays the same widget, and
# every toggle is shown its field. Adding, renaming or removing a member re-filters me the same way.
class InspectorWdgt extends Widget

  # I CLIP my children -- their paint and their pointer targeting -- to my rectangle, the house way
  # (the mixin every panel, viewport and frame wears): a control my width leaves no room for is cut
  # at my right edge, where it shows nothing and catches no press, the same naked as in a window (a
  # target never extends beyond the widget that owns it, visual-design-system §4.2). In a window I lie
  # flush against, it changes no pixel: the window clips at its own box already, and the one column
  # of that box right of me is its border, which it strokes over its children. Opaque, my
  # silhouette is my box, so my children add nothing to the shadow a naked inspector casts.
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  # the object I am a view OF, and deliberately not called `target`: `@target` elsewhere means
  # information flow (a dataflow consumer, a dispatch receiver) or a tracked reference edge, and
  # reading one as the other is the hazard this name exists to remove
  inspectedObject: undefined
  currentProperty: undefined
  # the parsed Mixin whose source the currently-selected member's view came from
  # (undefined when the source came from the instance or the class chain). Set by
  # selectionFromList, cleared with the selection by a re-filter; consulted by
  # ClassInspectorWdgt.applyPropertyEdit to route a save to the DONOR mixin.
  currentPropertySourceMixin: undefined
  # true when the mixin-attributed selection is a CLASS-SIDE (static) member --
  # the save then routes to Mixin.applyStaticEdit instead of applyMemberEdit
  currentPropertySourceIsStatic: false
  # panes:
  list: undefined
  detail: undefined
  # the detail pane's text widget, adopted from @detail once it is built
  textWidget: undefined
  # the free-floating resize handle. Stays undefined for the duration of its own add
  # (see the note at its assignment), so it must declare undefined, not a value.
  resizer: undefined

  # my BREADCRUMB's pieces (_buildAndConnectBreadcrumb), each built once, with me: the "Class"
  # caption; a ChipWdgt per class of my subject's chain, base class first, the last one current;
  # and a BreadcrumbSeparatorWdgt after each chip but the last -- classSeparators[i] stands between
  # classChips[i] and classChips[i + 1]
  classCaption: undefined
  classChips: undefined
  classSeparators: undefined

  # my filter's TOGGLES (LabelledToggleWdgt), each ON exactly while the showing* field it stands for
  # is true (_reflectFiltersOnToggles). A class inspector builds no own-props toggle, so that field
  # stays undefined there.
  showMethodsToggle: undefined
  showFieldsToggle: undefined
  showInheritedToggle: undefined
  showOwnPropsOnlyToggle: undefined

  # "from <Name>Mixin" after my class chips, in my breadcrumb band, while a mixin-donated member is
  # selected (the donor is provenance, like the class chain); empty otherwise, when it takes no room
  # in the band
  mixinDonorLabel: undefined

  # my member FILTER (_filteredMemberNames), and the one place its state lives: my toggles show it,
  # and a toggle's action flips it here (toggleShowing*).
  showingFields: true
  showingMethods: true
  showingInherited: false
  showingOwnPropsOnly: false

  # my footer band's buttons (the edit row, _buildAndConnectEditRow). Rename and remove act on the
  # selected member and are enabled exactly while one is selected; save is enabled exactly while
  # the code pane holds an edit to save. A disabled button still catches a press and does nothing.
  addPropertyButton: undefined
  renamePropertyButton: undefined
  removePropertyButton: undefined
  saveButton: undefined

  padding: undefined

  # ⚠ Through the SERVICE, never `@inspectedObject.colloquialName()`: an inspector is handed
  # whatever the user asked to inspect, and that is not always a widget — the evaluation menu's
  # "Inspect selection" hands it the VALUE of a snippet, so it can be a number, a string, a Point.
  # Asking a number for a method is a category error; the service names it from its class instead.
  # The subject's name follows the dash AS IT IS ("Object Inspector — analog clock", "Object
  # Inspector — Docs Maker"): my window title's display case touches only its first character.
  colloquialName: ->
    "Object Inspector — " + Utils.colloquialNameOf @inspectedObject

  # My toggles' ACTIONS, one per toggle (a toggle hands itself in slot 1; none of them needs it).
  # Each flips the filter field its toggle stands for and re-filters me, in ONE settle: the field is
  # the filter's truth, and the re-filter shows every toggle its field (_reflectFiltersOnToggles).
  toggleShowingMethods: ->
    @_settleLayoutsAfter =>
      @showingMethods = !@showingMethods
      @_refilterMembersNoSettle()

  toggleShowingFields: ->
    @_settleLayoutsAfter =>
      @showingFields = !@showingFields
      @_refilterMembersNoSettle()

  toggleShowingInherited: ->
    @_settleLayoutsAfter =>
      @showingInherited = !@showingInherited
      @_refilterMembersNoSettle()

  toggleShowingOwnPropsOnly: ->
    @_settleLayoutsAfter =>
      @showingOwnPropsOnly = !@showingOwnPropsOnly
      @_refilterMembersNoSettle()

  constructor: (@inspectedObject) ->
    @classChips = []
    @classSeparators = []
    super()

    # A naked (chrome-less) inspector must establish its OWN usable extent.
    # Without a FrameWdgt to size it, _reLayout would divide the Widget-default
    # ~50x40 across three panes and collapse them. The windowed path
    # (Widget::spawnInspector) overrides this via the window's setExtent, so
    # setting it here is windowed-pixel-neutral.
    @__commitExtent new Point 560, 410

    # My body, the same naked and windowed: the panel fill, and my seams over it (_seamRects) --
    # inside a window, the window's own paper never shows through me.
    @color = WorldWdgt.theme.inspectorBodyFill
    @appearance = new RectangularAppearance @

    @_buildAndConnectChildren()

  # Which of my children run out to my bottom-right corner, where my own resizer sits while I am naked
  # and my window's grip while I am its payload. While I end in my footer band, none: the band keeps
  # that corner clear for the grip (footerGripClearance) and holds no viewport there, so the corner
  # chain stops at me (ViewportWdgt._resizerOverMyCorner). A read-only inspector has no footer band,
  # and its code pane runs out to the corner, so the pane's bars keep the corner free; the resizer
  # overlaps only the pane's lowest rows, and the pane keeps the whole reserve: the safe way to be
  # wrong. The same query the footer band's build and layout ask (_subjectIsEditable).
  bottomRightCornerReachedBy: (child) ->
    child is @detail and !@_subjectIsEditable()

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns
  # settled). Built once, at construction: a filter change or a member add / rename / remove rebuilds
  # only my member list (_refilterMembers), and every other child stays.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @_buildAndConnectBreadcrumb()

    # my filter's toggles, each with its fixed label and the one action that flips its field; the
    # state each shows is set from my filter once they all exist (_reflectFiltersOnToggles, below)
    @showMethodsToggle = new LabelledToggleWdgt @, "toggleShowingMethods", face: "Methods"
    @_addNoSettle @showMethodsToggle
    @showFieldsToggle = new LabelledToggleWdgt @, "toggleShowingFields", face: "Fields"
    @_addNoSettle @showFieldsToggle
    @showInheritedToggle = new LabelledToggleWdgt @, "toggleShowingInherited", face: "Inherited"
    @_addNoSettle @showInheritedToggle
    @_buildAndConnectOwnPropsOnlyToggle()
    @_reflectFiltersOnToggles()

    @_buildAndConnectEditRow() if @_subjectIsEditable()

    @_buildAndConnectMemberList()

    # my CODE PANE: a TextAreaWdgt in the code role, its text born in fonts.code and the codeText
    # ink, codePanePadding in from its edges -- so the code starts that far right of my list | code
    # seam and that far below my body's top
    theme = WorldWdgt.theme
    @detail = new TextAreaWdgt "", false, theme.codePanePadding, fontRole: theme.fonts.code, textColor: theme.codeText
    @detail.disableDrops()
    @detail.contents.disableDrops()
    @_clearPaneLook @detail
    # The pane opens EMPTY and UNMODIFIED: its empty text is the text it compares against until a
    # selection loads a member's source (selectionFromList), so its modified-content indicator starts
    # hidden and the content check below leaves save disabled.
    @detail.textWdgt.considerCurrentTextAsReferenceText()
    @detail.addModifiedContentIndicator()

    # register this wdgt as one to be notified when the text
    # changes/unchanges from "reference" content
    # so we can enable/disable the "Save" button
    @detail.widgetToBeNotifiedOfTextModificationChange = @

    @textWidget = @detail.textWdgt
    @textWidget.backgroundColor = theme.inspectorPaneFill
    @textWidget.isEditable = false

    @_addNoSettle @detail

    # The inspector's own resize handle. It is shown ONLY when the inspector
    # is free-floating (naked on the desktop) and hidden when it is FrameWdgt
    # content (HandleWdgt::updateVisibility, driven by Widget::_setLayoutSpec),
    # so a naked inspector is self-resizable while a windowed one defers to the
    # window's resizer. Covered by
    # SystemTest_macroNakedInspectorRendersResizesAndEdits.
    # Attach the resizer, then record it -- @resizer stays undefined during its own add (byte-identical to the old
    # `@resizer = new HandleWdgt @`, whose in-constructor add ran while @resizer was still undefined; see FrameWdgt).
    resizer = new HandleWdgt
    @_addNoSettle resizer, layoutSpec: resizer.defaultLayoutSpecWhenAddedTo(@)
    @resizer = resizer

    # my footer buttons' enabled states, from what my panes hold now: save from the code pane's text
    # (its content check: unmodified, so disabled), rename and remove from the list's selection (a
    # fresh list selects nothing, so disabled)
    @detail.checkIfTextContentWasModifiedFromTextAtStart()
    @_reflectMemberSelection()

    # update layout
    @_invalidateLayout()

  # My BREADCRUMB's pieces, added in my paint and hit order, left to right: the "Class" caption,
  # then a chip per class of my subject's chain (_classChainNames), base class first, each but the
  # last followed by its separator, then the mixin-donor label, blank until a donated member is
  # selected (selectionFromList). The last chip is the CURRENT one. Every chip, the current one
  # included, opens its class's ClassInspector: its action is openClassInspector, its class name in
  # slot 3. The two labels hug their text, one line of fonts.buttonLabel tall (StringWdgt's box
  # hug, which re-hugs a label whose text changes and then asks me to re-lay, so a donor label that
  # appears or goes re-flows my band). Where each piece goes is _breadcrumbIn's.
  _buildAndConnectBreadcrumb: ->
    theme = WorldWdgt.theme
    @classCaption = new StringWdgt "Class", fontRole: theme.fonts.buttonLabel, color: theme.inspectorBreadcrumbCaption
    @classCaption._sizeToTextAndDisableFittingNoSettle()
    @_addNoSettle @classCaption

    @classChips = []
    @classSeparators = []
    names = @_classChainNames()
    for name, i in names
      chip = new ChipWdgt @, "openClassInspector", face: name, arg1: name, current: i is names.length - 1
      @classChips.push chip
      @_addNoSettle chip
      if i < names.length - 1
        separator = new BreadcrumbSeparatorWdgt
        @classSeparators.push separator
        @_addNoSettle separator

    @mixinDonorLabel = new StringWdgt "", fontRole: theme.fonts.buttonLabel, color: theme.inspectorDonorText
    @mixinDonorLabel._sizeToTextAndDisableFittingNoSettle()
    @_addNoSettle @mixinDonorLabel

  # The names of the classes my subject is made of, base class first: every object on its
  # prototype chain, my subject itself included, that is a class's OWN prototype (it owns its
  # constructor), up to Object. So an object inspector's chain ends in its subject's own class, a
  # class inspector's -- whose subject IS a class's prototype -- in that class itself, and a value
  # (a number, a string) names its built-in class. An own "constructor" member that holds no
  # function (a property added to my subject under that name) names nothing.
  _classChainNames: ->
    names = []
    link = @inspectedObject
    while link? and link.constructor?.name isnt "Object"
      if (Object::hasOwnProperty.call link, "constructor") and Utils.isFunction link.constructor
        names.unshift link.constructor.name
      link = link.__proto__
    names

  # My code pane tells me when its text comes to differ from the text last loaded or saved, and when
  # it agrees with it again: save is enabled exactly while there is an edit to save. A read-only
  # inspector has no save button.
  textContentModified: ->
    @saveButton?.setEnabled true

  textContentUnmodified: ->
    @saveButton?.setEnabled false

  # Rename and remove act on the SELECTED member, so they are enabled exactly while my list has a
  # selection: disabled as built, enabled by the first selection (selectionFromList), which lasts
  # until my next re-filter, whose fresh list selects nothing. Their "select a property first"
  # guards stay in the actions, which other callers reach directly. A read-only inspector has
  # neither button.
  _reflectMemberSelection: ->
    selected = @list.selected?
    @renamePropertyButton?.setEnabled selected
    @removePropertyButton?.setEnabled selected

  # My toggles show my filter: each is ON exactly while the showing* field it stands for is true.
  # The build and every re-filter end here, and nothing else sets a toggle of mine, so a toggle and
  # its field cannot disagree; a toggle taken out of me still stands for my field and follows it.
  _reflectFiltersOnToggles: ->
    @showMethodsToggle.setOn @showingMethods
    @showFieldsToggle.setOn @showingFields
    @showInheritedToggle.setOn @showingInherited
    @showOwnPropsOnlyToggle?.setOn @showingOwnPropsOnly

  # A RE-FILTER: my member set may have changed -- a toggle flipped my filter, or a member was added,
  # renamed or removed -- so my member LIST is built again from my filter as it stands
  # (_buildAndConnectMemberList), and nothing else is: my toggles, my breadcrumb, my code pane and
  # my footer buttons stay the same widgets. What showed the old list's selection now shows none, as
  # at my construction: no member is selected, my code pane is empty and read-only, the donor label
  # is blank (and my breadcrumb band re-flows without it), and my footer's member buttons are
  # disabled (_reflectMemberSelection). My toggles are then shown my filter.
  _refilterMembers: ->
    @_settleLayoutsAfter => @_refilterMembersNoSettle()

  _refilterMembersNoSettle: ->
    @_buildAndConnectMemberList()

    @currentProperty = undefined
    @currentPropertySourceMixin = undefined
    @currentPropertySourceIsStatic = false
    @mixinDonorLabel?._setTextNoSettle ""

    # my code pane back to empty and read-only, its empty text the text it compares against, so its
    # modified-content indicator hides and save disables. An edit in progress in it ends first, as
    # it would if the pane were destroyed (Widget._destroyNoSettle).
    world._stopEditingNoSettle() if world.caret? and @detail.isAncestorOf world.caret.target
    @textWidget.isEditable = false
    @textWidget._setTextNoSettle ""
    @textWidget.considerCurrentTextAsReferenceText()
    @detail.checkIfTextContentWasModifiedFromTextAtStart()

    @_reflectMemberSelection()
    @_reflectFiltersOnToggles()
    @_invalidateLayout()

  # The names of the members my filter lets through, in the order my list shows them. It starts
  # from every enumerable property of my subject and of its whole prototype chain (a Fizzygum
  # class's members are enumerable, its methods included) and keeps:
  #   methods      only while showingMethods
  #   fields       only while showingFields
  #   inherited    while showingInherited; otherwise only the members my subject's own class
  #                declares, and those stitched onto my subject that no class of its chain has
  #   own props    while showingOwnPropsOnly, only my subject's own properties
  # sorted, unless my subject is an Array (whose order is its meaning).
  _filteredMemberNames: ->
    attribs = []
    for property of @inspectedObject
      # dummy condition, to be refined
      attribs.push property  if property

    if !@showingMethods
      attribs = attribs.filter (prop) => !Utils.isFunction @inspectedObject[prop]

    if !@showingFields
      attribs = attribs.filter (prop) => Utils.isFunction @inspectedObject[prop]

    # if we don't show inherited props, then we let through two types of props (each side of the "or"
    # takes care of one type):
    #   1) the ones that are defined in the immediate class of the object (i.e. are own properties of the prototype)
    #   2) the ones that are just stitched to the object but are in none of the classes upwards i.e.
    #      are not a reachable property from the prototype
    if !@showingInherited
      attribs = attribs.filter (prop) => @inspectedObject.constructor.prototype.hasOwnProperty(prop) or (prop not of @inspectedObject.constructor.prototype)

    if @showingOwnPropsOnly
      attribs = attribs.filter (prop) => @inspectedObject.hasOwnProperty(prop)

    if @inspectedObject instanceof Array then attribs else attribs.sort()

  # My member LIST, built from the names my filter lets through (_filteredMemberNames) and added to
  # me, where my layout places it in my body (_reLayout). The build makes the first one; a re-filter
  # makes it again: the list it replaces, while still mine, is destroyed, and the new one takes its
  # place among my children (my paint and hit order). A list taken out of me is not mine to
  # replace, so it stays where it is and the new one is added to me. A fresh list selects nothing
  # and shows its first rows.
  #   A MEMBER list: each row a kind tag and the member's name, as wide as the list (MemberRowWdgt),
  # told what each member is by my memberFactsOf. Everything the list reaches me through is a method
  # NAME -- a click selects a member (selectionFromList), a double-click opens one
  # (inspectMemberValue) -- so a copy of me is reached by its own list, and the list holds no
  # closure.
  _buildAndConnectMemberList: ->
    if @list?.parent is @
      atIndex = @children.indexOf @list
      @list._fullDestroyNoSettle()

    @list = new ListWdgt @_filteredMemberNames(),
      target: @
      action: "selectionFromList"
      doubleClickAction: "inspectMemberValue"
      memberFactsQuery: "memberFactsOf"
    @list.disableDrops()
    @_clearPaneLook @list

    # @list.listContents (the CommandPanelWdgt holding this list's items) never animates, so it's
    # dropped from world.steppingWdgts here. ListWdgt itself still steps (its scrollbars need it).
    world.steppingWdgts.delete @list.listContents
    @_addNoSettle @list, atIndex: atIndex

  # WHAT MY LIST SHOWS OF A MEMBER beside its name (my list's memberFactsQuery, asked once per row
  # as the list is built): its KIND TAG -- "fn" for a function, "var" for anything else, the split my
  # methods and fields toggles filter by -- and whether its name is DIMMED: dimmed unless my subject's
  # own class declares it, so a member inherited from a superclass, or stitched onto my subject with
  # no class declaring it, reads muted, and a member of my subject's own class reads in ink.
  #
  # TODO show the static methods and variables in yet another color.
  memberFactsOf: (memberName) ->
    kindTag: if Utils.isFunction @inspectedObject[memberName] then "fn" else "var"
    dimmed: !@inspectedObject.constructor.prototype.hasOwnProperty memberName

  # A DOUBLE-CLICK on a member row (ListWdgt.openRow hands me its member's name, after the click that
  # selected it): when the member's value is an object -- the only kind of value with members to show
  # -- a NAKED inspector of my own class on it, at the pointer, so its fields can be viewed and
  # changed; any other value opens nothing.
  inspectMemberValue: (memberName) ->
    value = @inspectedObject[memberName]
    return unless Utils.isObject value
    inspector = new @constructor value
    inspector._applyMoveTo world.hand.position()
    inspector._moveWithin world
    world.add inspector


  # Can this subject SERVICE an edit? An inspector is handed whatever the user asked to inspect,
  # and only some of those implement the edit protocol — `injectProperty` / `removeOwnProperty` /
  # `renameOwnProperty` / `sourceChanged`, which arrive together on Widget. A number, a string, a
  # Point cannot: you cannot inject a property into 42. ⚠ A CAPABILITY query, never `instanceof
  # Widget` — the question is "does it service the protocol", so a future non-widget that
  # implements the four should get an editable inspector. The four always co-occur, so one probe
  # answers for the row.
  _subjectIsEditable: ->
    @inspectedObject.injectProperty?

  # The EDIT ROW -- my footer band's buttons -- as ONE unit: built, laid out and reached into
  # together, so it exists or it does not, and my footer band with it. An inspector on a subject
  # that cannot service an edit is a READ-ONLY inspector, which is the honest presentation rather
  # than a degraded one; offering controls that could only refuse is worse than offering none (the
  # same reasoning `createDesktop` uses to skip an app icon a profile cannot provide). Its layout
  # twin is the guarded footer band in `_reLayout`. Save is the primary action; the build sets the
  # enabled states (see the field declarations).
  _buildAndConnectEditRow: ->
    @addPropertyButton = new SimpleButtonWdgt @, "addPropertyPopout", face: "Add…"
    @_addNoSettle @addPropertyButton
    @renamePropertyButton = new SimpleButtonWdgt @, "renamePropertyPopout", face: "Rename…"
    @_addNoSettle @renamePropertyButton
    @removePropertyButton = new SimpleButtonWdgt @, "removeProperty", face: "Remove"
    @_addNoSettle @removePropertyButton

    @saveButton = new SimpleButtonWdgt @, "save", face: "Save", primary: true
    @_addNoSettle @saveButton

  # my last toggle, which a class inspector does not build (ClassInspectorWdgt)
  _buildAndConnectOwnPropsOnlyToggle: ->
    @showOwnPropsOnlyToggle = new LabelledToggleWdgt @, "toggleShowingOwnPropsOnly", face: "Own props only"
    @_addNoSettle @showOwnPropsOnlyToggle

  openClassInspector: (ignored,ignored2,className) ->
    classInspector = new ClassInspectorWdgt window[className].prototype
    world.openFrameWith classInspector, (new Point 560, 410), world.hand.position().subtract(new Point 50, 100)

  # The parsed Mixin that injects member `selected` into `theClass` (undefined when no
  # augmentedWith mixin carries it). `augmentedWith` holds the mixin GLOBAL names
  # ("ControllerMixin"); a parsed Mixin's @name is that minus the "Mixin" suffix
  # ("Controller"), so match either form. Mixin.allMixines is the list of parsed Mixins
  # (each carrying nonStaticPropertiesSources), populated at boot by Mixin's create
  # pass. This powers BOTH the view (a mixin method shows real source instead of
  # compiled JS -- the mixin leg the class-chain walk in selectionFromList lacked) and
  # the edit routing (ClassInspectorWdgt saves a mixin-donated member to the donor).
  _mixinProvidingMember: (theClass, selected) ->
    return undefined unless theClass.augmentedWith?
    for mixinName in theClass.augmentedWith
      for theMixin in Mixin.allMixines
        if (theMixin.name == mixinName or theMixin.name + "Mixin" == mixinName) and
           theMixin.nonStaticPropertiesSources[selected]?
          return theMixin
    undefined

  # the recorded SOURCE of a non-function member, or undefined to show its VALUE. The
  # class inspector overrides this with the prototype-level truth (live override /
  # class body / mixin donor, setting the donor attribution); an OBJECT inspector
  # keeps showing the instance's VALUE -- per-instance state is its own truth.
  _sourceForFieldMember: (selected) ->
    undefined

  # the static twin of _mixinProvidingMember: the parsed Mixin donating class-side
  # member `selected` to `theClass` (undefined when none does)
  _mixinProvidingStaticMember: (theClass, selected) ->
    return undefined unless theClass?.augmentedWith?
    for mixinName in theClass.augmentedWith
      for theMixin in Mixin.allMixines
        if (theMixin.name == mixinName or theMixin.name + "Mixin" == mixinName) and
           theMixin.staticPropertiesSources[selected]?
          return theMixin
    undefined

  selectionFromList: (selected) ->
    if selected == undefined then return

    val = @inspectedObject[selected]
    @currentProperty = val
    @currentPropertySourceMixin = undefined
    @currentPropertySourceIsStatic = false

    # functions should have a source somewhere
    # either in the object or in a superclass,
    # try to find it.
    if Utils.isFunction(val)
      if @inspectedObject[selected + "_source"]?
          val = @inspectedObject[selected + "_source"]
      else
        # Walk the Fizzygum class chain looking for the selected method's recorded source. Guard on
        # `.constructor?.class?` (a Fizzygum Class object) rather than the old `!= Object`: __proto__ yields
        # PROTOTYPES, never the Object CONSTRUCTOR, so `!= Object` never matched and the walk ran off the end to
        # Object.prototype (whose `.constructor.class` is undefined) and THREW when the source was not found in
        # any class. Not-found is legitimate: a mixin-injected method (e.g. ControllerMixin._fireConnection) is
        # not recorded in any class's nonStaticPropertiesSources, so its source is not on the class chain -- fall
        # through to val.toString() below instead of crashing. (V8 masked this; JSC surfaced it.)
        goingUpTargetProtChain = @inspectedObject
        while goingUpTargetProtChain?.constructor?.class?
          theClass = goingUpTargetProtChain.constructor.class
          if theClass.nonStaticPropertiesSources[selected]?
            val = theClass.nonStaticPropertiesSources[selected]
            break
          # The method may be MIXIN-injected (e.g. ControllerMixin._fireConnection) -- not recorded on any
          # class's nonStaticPropertiesSources, but on the parsed Mixin. Consult each mixin this class
          # augmentsWith so the inspector shows real CoffeeScript instead of the compiled-JS toString()
          # below; remember the donor so a class-inspector save routes the edit to it.
          theMixinProvidingIt = @_mixinProvidingMember theClass, selected
          if theMixinProvidingIt?
            val = theMixinProvidingIt.nonStaticPropertiesSources[selected]
            @currentPropertySourceMixin = theMixinProvidingIt
            break
          goingUpTargetProtChain = goingUpTargetProtChain.__proto__
      txt = val.toString()
    else
      # this is for finding the static variables
      if val is undefined
        val = @inspectedObject.constructor[selected]
        # a static may be MIXIN-donated (augmentWith copies the literal's class-side
        # keys onto each consumer constructor at boot): show the donor's recorded
        # source and remember the attribution so a class-inspector save routes to it
        theMixinProvidingIt = @_mixinProvidingStaticMember @inspectedObject.constructor.class, selected
        if theMixinProvidingIt?
          @currentPropertySourceMixin = theMixinProvidingIt
          @currentPropertySourceIsStatic = true
          mixinStaticSource = theMixinProvidingIt.staticPropertiesSources[selected]

      if mixinStaticSource?
        txt = mixinStaticSource
      else if (fieldSource = @_sourceForFieldMember selected)?
        txt = fieldSource
      else if !val?
        txt = "undefined"
      else if Utils.isString val
        txt = '"'+val+'"'
      else
        txt = val.toString()

    # the donor label hugs its new text and asks me to re-lay: my breadcrumb band re-flows, so the
    # label can take a row of its own, or give one back, and my bands below follow
    @mixinDonorLabel?.setText (if @currentPropertySourceMixin? then "from " + @currentPropertySourceMixin.name + "Mixin" else "")

    cnts = @detail.textWdgt
    cnts.setText txt
    cnts.setReceiver @inspectedObject
    cnts.isEditable = true
    cnts.enableSelecting()
    cnts.considerCurrentTextAsReferenceText()
    @detail.checkIfTextContentWasModifiedFromTextAtStart()
    @_reflectMemberSelection()

  _reLayout: (newBoundsForThisLayout) ->

    if @_handleCollapsedStateShouldWeReturn() then return

    # Establish THIS layout pass's final bounds on OURSELVES first, before positioning the
    # children below. The base Widget::_reLayout (our `super` at the end) is what normally
    # applies newBoundsForThisLayout to @bounds — but we lay the children out manually from
    # @left()/@width()/@bottom() BEFORE calling super, so without this they'd be sized to the
    # PREVIOUS pass's extent and lag the inspector by one layout. During a resize that lag
    # equals the last drag STEP, whose size depends on how many frames the drag spanned — so
    # under variable cycle cadence (dpr2 + parallel test load) the bands' controls + the
    # detail scrollbar settle to a nondeterministic 1px offset (the macroNakedInspector dpr2
    # flake). Applying the bounds here makes the child layout read the FINAL extent, so the
    # render is identical regardless of cadence. `super` re-applies the same bounds (idempotent).
    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout
    @_applyBounds newBoundsForThisLayout.origin, newBoundsForThisLayout.extent()

    @_repaintAsOneUnit =>
      bands = @_bandsIn @bounds

      @_layOutBreadcrumb bands.breadcrumb
      @_layOutTogglesIn bands.toggles

      # the body's two panes, each one only while it is still mine: a pane taken out of me is not
      # mine to place
      if @list.parent == @
        @list._applyBounds bands.list.origin, bands.list.extent()
      if @detail.parent == @
        @detail._applyBounds bands.code.origin, bands.code.extent()

      # The EDIT ROW's layout twin, my footer band: laid out exactly when it was built
      # (`_subjectIsEditable`, the SAME query as the build and as _bandsIn — a second spelling would
      # be a fact stated twice, and two facts will disagree). FooterBandLayout places every footer
      # button that is my child, shown or not: visibility is not a layout input, so a hidden button
      # (a class inspector's override) keeps its slot, and showing it moves nothing.
      if @_subjectIsEditable()
        FooterBandLayout.arrange @, @_footerLeftButtons(), @_footerRightButtons()

    super
    @_markLayoutAsFixed()

  # My BANDS in `box` -- my own box, in whatever coordinates the caller works in: my bounds for my
  # layout, my local box (origin 0,0) for my seams -- as ONE pure answer, so where my layout places
  # a pane and where my seams draw a line can never disagree. Answers:
  #   breadcrumb                   my breadcrumb's pieces' places and the band's height
  #                                (_breadcrumbIn): as many rows as its chips take at the box's width
  #   toggles                      the toggles band above its rule
  #   breadcrumbRule, togglesRule  each band's last row: its rule
  #   list, code                   the body's two panes, the list column then the code pane
  #   seam                         the line between them, the body's whole height
  #   footerRule                   the footer band's rule (FooterBandLayout.ruleIn), or undefined for
  #                                a read-only inspector, whose body runs to the box's bottom
  # Where the box is too short for every band, the body is empty (zero tall) and the footer band
  # overlaps the bands above it. Integer by construction: the box is, every metric is, and the list
  # column is floored.
  _bandsIn: (box) ->
    theme = WorldWdgt.theme
    rule = theme.inspectorRuleWidth
    left = box.left()
    right = box.right()
    breadcrumb = @_breadcrumbIn box
    breadcrumbRuleTop = box.top() + breadcrumb.height - rule
    togglesTop = breadcrumbRuleTop + rule
    togglesRuleTop = togglesTop + theme.toggleBandHeight - rule
    bodyTop = togglesRuleTop + rule
    hasFooter = @_subjectIsEditable()
    bodyBottom = Math.max bodyTop, (if hasFooter then (FooterBandLayout.topIn box) else box.bottom())
    listRight = left + Math.min theme.inspectorListColumnWidth, Math.floor(box.width() / 2)
    codeLeft = Math.min right, listRight + rule

    breadcrumb: breadcrumb
    breadcrumbRule: new Rectangle left, breadcrumbRuleTop, right, togglesTop
    toggles: new Rectangle left, togglesTop, right, togglesRuleTop
    togglesRule: new Rectangle left, togglesRuleTop, right, bodyTop
    list: new Rectangle left, bodyTop, listRight, bodyBottom
    seam: new Rectangle listRight, bodyTop, codeLeft, bodyBottom
    code: new Rectangle codeLeft, bodyTop, right, bodyBottom
    footerRule: if hasFooter then (FooterBandLayout.ruleIn box) else undefined

  # My seams, top to bottom: the breadcrumb band's rule, the toggles band's, the line between my
  # list and my code pane, and my footer band's rule when I have one -- all from the one geometry my
  # layout places my children by (_bandsIn), so each lies in a gap between them.
  _seamRects: ->
    bands = @_bandsIn new Rectangle 0, 0, @width(), @height()
    seams = [bands.breadcrumbRule, bands.togglesRule, bands.seam]
    seams.push bands.footerRule  if bands.footerRule?
    seams

  # My BREADCRUMB in `box` (my own box, in whatever coordinates the caller works in), as ONE pure
  # answer: a function of the box's left, right and top and of my pieces' own sizes, so laying it
  # out again moves nothing, and asking again at another width answers that width afresh.
  #   ROWS: my pieces flow left to right in rows chipHeight tall. The first row is centred down the
  # band's first breadcrumbBandHeight less its rule; each next row lies a chip's height and
  # breadcrumbGap lower.
  #   ACROSS A ROW: the caption starts breadcrumbInset in and the first chip breadcrumbCaptionGap
  # after it; a later row starts where the first chip does, so the caption heads the whole chain. A
  # chip and the separator after it travel together: the separator's INK, not its square, starts
  # breadcrumbGap after the chip (ChevronRightIconAppearance.inkSpanX), and the next chip starts
  # breadcrumbGap after the ink. The donor label, while it has text, follows the last chip
  # breadcrumbDonorGap after it.
  #   WRAPPING: a chip with its separator, or the donor label, that would end past breadcrumbInset
  # short of the box's right edge starts the next row instead -- unless it is the first piece of
  # its row, which then runs on past that edge (where I clip it). A blank donor label takes no room
  # and opens no row: it stands right after the last chip.
  #   A chip takes its own size (preferredExtent), a label its own one-line box, each centred down
  # its row; a separator its glyph square, centred the same way. Only a piece still my child takes
  # part, and a separator only while a later chip of mine follows it. Answers:
  #   caption, donor     Rectangles, or undefined for a piece not placed
  #   chips, separators  Rectangles indexed as my classChips / classSeparators, undefined for a
  #                      piece not placed
  #   height             the band's height, its rule included: breadcrumbBandHeight, plus a chip's
  #                      height and breadcrumbGap per row past the first
  # Integer by construction: the box is, every metric is, every size is a whole number of px.
  _breadcrumbIn: (box) ->
    theme = WorldWdgt.theme
    side = theme.breadcrumbSeparatorSize
    [inkLeft, inkRight] = ChevronRightIconAppearance.inkSpanX side
    rowHeight = theme.chipHeight
    rowPitch = rowHeight + theme.breadcrumbGap
    firstRowTop = box.top() + Math.floor (theme.breadcrumbBandHeight - theme.inspectorRuleWidth - rowHeight) / 2
    limit = box.right() - theme.breadcrumbInset
    row = 0
    centredInRow = (extent, left) ->
      top = firstRowTop + row * rowPitch + Math.floor (rowHeight - extent.y) / 2
      new Rectangle left, top, left + extent.x, top + extent.y

    caption = undefined
    chips = []
    separators = []
    donor = undefined

    x = box.left() + theme.breadcrumbInset
    if @classCaption?.parent is @
      caption = centredInRow @classCaption.preferredExtent(), x
      x = caption.right() + theme.breadcrumbCaptionGap
    rowStart = x

    myChips = (chip for chip in @classChips when chip.parent is @)
    for chip in myChips
      i = @classChips.indexOf chip
      trails = chip isnt myChips[myChips.length - 1] and @classSeparators[i]?.parent is @
      extent = chip.preferredExtent()
      reach = extent.x + (if trails then theme.breadcrumbGap + inkRight - inkLeft else 0)
      if x > rowStart and x + reach > limit
        row++
        x = rowStart
      chips[i] = centredInRow extent, x
      x += extent.x
      if trails
        separators[i] = centredInRow (new Point side, side), x + theme.breadcrumbGap - inkLeft
        x += theme.breadcrumbGap + inkRight - inkLeft + theme.breadcrumbGap

    if @mixinDonorLabel?.parent is @
      extent = @mixinDonorLabel.preferredExtent()
      donorLeft = x
      if @mixinDonorLabel.text isnt ""
        donorLeft += theme.breadcrumbDonorGap  if x > rowStart
        if x > rowStart and donorLeft + extent.x > limit
          row++
          donorLeft = rowStart
      donor = centredInRow extent, donorLeft

    caption: caption
    chips: chips
    separators: separators
    donor: donor
    height: theme.breadcrumbBandHeight + row * rowPitch

  # My BREADCRUMB's pieces where `crumbs` places them (_breadcrumbIn, in my bounds' coordinates): each
  # chip at its own size, the caption, the separators and the donor label in their own boxes. A
  # piece crumbs does not place -- one taken out of me -- is not mine to move.
  _layOutBreadcrumb: (crumbs) ->
    @classCaption._applyBounds crumbs.caption  if crumbs.caption?
    for chip, i in @classChips when crumbs.chips[i]?
      chip._reLayout crumbs.chips[i]
    for separator, i in @classSeparators when crumbs.separators[i]?
      separator._applyBounds crumbs.separators[i]
    @mixinDonorLabel._applyBounds crumbs.donor  if crumbs.donor?
    return

  # My TOGGLES in `band` (the toggles band above its rule, in my bounds' coordinates): each at its
  # own size (its preferredExtent: a fixed label, so the same on and off), the first
  # toggleBandInset in and each next one toggleBandGap after the one before, centred down the band,
  # floored. Only a toggle that is still my child takes part: one taken out of me is not mine to
  # place, and the others close up.
  _layOutTogglesIn: (band) ->
    theme = WorldWdgt.theme
    x = band.left() + theme.toggleBandInset
    for toggle in @_toggles() when toggle?.parent is @
      extent = toggle.preferredExtent()
      y = band.top() + Math.floor (band.height() - extent.y) / 2
      toggle._reLayout new Rectangle x, y, x + extent.x, y + extent.y
      x += extent.x + theme.toggleBandGap
    return

  # My toggles, in order, left to right. A class inspector builds no own-props toggle
  # (_buildAndConnectOwnPropsOnlyToggle), so that field stays undefined and its band holds three.
  _toggles: ->
    [@showMethodsToggle, @showFieldsToggle, @showInheritedToggle, @showOwnPropsOnlyToggle]

  # My footer band's two groups of buttons, each in order, left to right (FooterBandLayout): add,
  # rename and remove at its left, save -- the primary action -- at its right. A read-only inspector
  # has none of them.
  _footerLeftButtons: ->
    [@addPropertyButton, @renamePropertyButton, @removePropertyButton]

  _footerRightButtons: ->
    [@saveButton]

  # A pane of mine paints nothing of its own -- neither the viewport nor the plane it scrolls has a
  # fill or a border -- so my body and my seams show through it (visual-design-system §4.1): each is
  # dressed in the inspector pane's roles (ViewportWdgt.wearPaneRoles; its plane wears them too),
  # read as it paints and kept by name, so a pane taken out of me keeps them. Dressed on MY two panes
  # as they are built: a ListWdgt or a TextAreaWdgt anywhere else keeps its own look.
  _clearPaneLook: (pane) ->
    pane.wearPaneRoles fill: "inspectorPaneFill", stroke: "inspectorPaneStroke"
    return

  notifyInstancesOfSourceChange: (propertiesArray)->
    @inspectedObject.sourceChanged()
  
  #InspectorWdgt editing ops:
  # Shared save scaffolding: object inspectors inject the property, class
  # inspectors evaluate an assignment — the only differing step is isolated in
  # the overridable applyPropertyEdit hook (ClassInspectorWdgt overrides it).
  save: ->
    if !@list.selected? then return
    txt = @detail.contents.children[0].text.toString()
    propertyName = @list.selected.labelString
    @applyPropertyEdit propertyName, txt

    @detail.textWdgt.considerCurrentTextAsReferenceText()
    @detail.checkIfTextContentWasModifiedFromTextAtStart()

    # it's possible that the user might have fixed
    # a "painting" error, so give another chance to all
    # "banned" widgets (banned from repainting)
    for eachWidget in world.widgetsGivingErrorWhileRepainting
      eachWidget.show()
    world.widgetsGivingErrorWhileRepainting = []

  # the one differing step between object- and class-inspector save: an object
  # inspector injects the property onto the instance (ClassInspectorWdgt
  # overrides this to evaluate an assignment against the class prototype).
  applyPropertyEdit: (propertyName, txt) ->
    # inject code will also break the layout and the widget
    @inspectedObject.injectProperty propertyName, txt


  addProperty: (prop) ->
    if prop?
      @_addNamedProperty prop

  # the add core, past the prompt: the popout flow (addProperty) and the class
  # inspector's destination menu both land here. Adding a member changes my member set and
  # nothing else, so it re-filters me (_refilterMembers).
  _addNamedProperty: (prop) ->
    @inspectedObject[prop] = undefined
    # nosettle-sanctioned: gesture tail shared by two PUBLIC add actions (the popout
    # OK and the class inspector's destination menu), event-time only -- the re-filter
    # is that gesture's single settle
    @_refilterMembers()
    @notifyInstancesOfSourceChange([prop])
  
  addPropertyPopout: ->
    # Chrome cannot handle empty strings (others do), hence the "property" default
    @prompt "new property name:", @, "addProperty", defaultContents: "property"

  # the one differing step between object- and class-inspector rename
  # (mirroring applyPropertyEdit above): the object inspector delegates to the
  # Widget-level renameOwnProperty twin, which moves the <name>_source
  # companion with the member -- otherwise a snapshot restore re-injects the
  # method under the OLD name. ClassInspectorWdgt overrides this with its raw
  # prototype re-keying.
  _applyPropertyRename: (oldName, newName) ->
    @inspectedObject.renameOwnProperty oldName, newName

  # A rename, like a removal below, changes my member set and nothing else, so it re-filters me
  # (_refilterMembers).
  renameProperty: (prop) ->
    propertyName = @list.selected.labelString
    @_applyPropertyRename propertyName, prop

    @_refilterMembers()
    @notifyInstancesOfSourceChange([prop, propertyName])
  
  renamePropertyPopout: ->
    # nothing selected = nothing to rename: a fresh inspector has NO default selection
    unless @list?.selected?
      world.inform "select a\nproperty first"
      return
    propertyName = @list.selected.labelString
    @prompt "property name:", @, "renameProperty", defaultContents: propertyName
  
  # removal's differing step, same seam as _applyPropertyRename: the object
  # inspector delegates to the Widget-level removeOwnProperty twin, which also
  # drops the <name>_source companion -- otherwise the {"$src"} serialization
  # ride re-injects the removed member on snapshot restore.
  _applyPropertyRemoval: (propertyName) ->
    @inspectedObject.removeOwnProperty propertyName

  removeProperty: ->
    # nothing selected = nothing to remove (see renamePropertyPopout)
    unless @list?.selected?
      world.inform "select a\nproperty first"
      return
    propertyName = @list.selected.labelString

    @_applyPropertyRemoval propertyName

    @_refilterMembers()
    @notifyInstancesOfSourceChange([propertyName])
