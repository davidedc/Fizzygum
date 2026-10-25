class ListWdgt extends ViewportWdgt

  # what a person calls me; without it the chain answers my base's "viewport" (my contents panel
  # has no name of its own to lend, ViewportWdgt.colloquialName)
  colloquialName: ->
    "list"

  # my pane's fill, mine and my plane's (which my rows panel stands on), read as we paint while no
  # builder dresses me otherwise (ViewportWdgt._paneFill)
  _defaultPaneFill: ->
    WorldWdgt.theme.listFill

  # The label a row shows for an element. A STATIC, asked at every row build, never stored on an
  # instance: a function-valued field has no source to serialize, so a list holding one would make
  # every world it stands in unsaveable.
  @labelOf: (element) ->
    return element  if Utils.isString element
    return element.toSource()  if element.toSource
    element.toString()

  # a list IS its scrolling — cropping an inspector's property pane would hide
  # entries with no cue (see ViewportWdgt.offersScrollPolicyToggle)
  offersScrollPolicyToggle: false

  # my pane holds the list's own rows machinery (@listContents), not loose scrollable
  # content — so the loose-content policies (drag-scroll-vs-detach, caret follow, the
  # soft-wrap menu row, container re-fit climbs) must not treat my innards as content
  # (the exclusion Widget._amIDirectlyInsideViewport consults; scroll-frame role
  # plan P3).
  contentsPanelHoldsLooseContent: ->
    false

  elements: undefined
  format: undefined
  listContents: undefined # a CommandPanelWdgt with the contents of the list
  # the selected ROW: the MenuItemWdgt `select` was dispatched with (slot 1); its labelString is the
  # element's label. The ONE record of my selection: my rows show it by reading it as they paint
  # (MenuItemWdgt._shownState), never by keeping a copy of it.
  selected: undefined
  # my target's methods I dispatch BY NAME, each handed an element's label: `action` when a row is
  # selected (select), `doubleClickAction` when a row is double-clicked (openRow) -- strings, so a
  # copy of me dispatches at its own target and I hold no closure
  action: undefined
  target: undefined
  doubleClickAction: undefined
  # MEMBER ROWS: the name of my target's query that tells me what each element is as a MEMBER, or
  # undefined for a plain list. Handed an element, it answers {kindTag, dimmed} (a MemberRowWdgt's
  # kind tag, and whether its name is dimmed), and my rows are then member rows, in a member list's
  # look: each a kind tag and the element's name cropped to the row, as wide as I am
  # (_positionAndResizeChildren). Asked once per element, as my rows are built.
  memberFactsQuery: undefined

  # The rows are the operand: every caller supplies them, while only the inspector
  # supplies target/action — which as leading positionals made the other six sites
  # open with `undefined, undefined` just to reach the rows (R3).
  constructor: (@elements = [], opts = {}) ->
    @target = opts.target
    @action = opts.action
    @format = opts.format ? []
    @doubleClickAction = opts.doubleClickAction
    @memberFactsQuery = opts.memberFactsQuery  if opts.memberFactsQuery?
    #
    #    passing a format is optional. If the format parameter is specified
    #    it has to be of the following pattern:
    #
    #        [
    #            [<color>, <single-argument predicate>],
    #            ['bold', <single-argument predicate>],
    #            ['italic', <single-argument predicate>],
    #            ...
    #        ]
    #
    #    multiple conditions can be passed in such a format list, the
    #    last predicate to evaluate true when given the list element sets
    #    the given format category (color, bold, italic) of that element's
    #    row. If no condition is met, the row keeps its look's own (its ink,
    #    non-bold, non-italic).
    #
    #    A format's predicates are functions, which a snapshot cannot save;
    #    a member list says what its rows show through memberFactsQuery, a
    #    method name, instead.
    #
    super()
    @contents.disableDrops()
    @_buildAndConnectChildren() # builds the list contents
    # it's important to leave the step as the default noOperation
    # instead of undefined because the scrollbars (inherited from Viewport)
    # need the step function to react to mouse floatDrag.
  
  # builds the list contents, via the _buildAndConnectChildren wrapper + NoSettle-core pattern. ListWdgt extends
  # ViewportWdgt, whose `add` is a CUSTOM override that redirects a non-frame child into @contents; the
  # non-settling twin of that redirect is `@contents._addNoSettle` (NOT the base `@_addNoSettle`, which would
  # wrongly attach @listContents to the viewport itself and break every InspectorWdgt's property pane --
  # the reason the orphan-settledness sweep left this unconverted). The core builds via @contents._addNoSettle
  # with the same default free-floating attachment the public redirect passes, so behaviour is byte-
  # identical and the wrapper settles once -- `new ListWdgt` still returns settled.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    # a CommandPanelWdgt: the pure row-stack, NOT a pop-up menu -- a List holds
    # rows, not a (crippled) menu. No pop-up lifetime (not a pop-up: nothing
    # dismisses these rows on a click outside them), no title (a plain square
    # body), and selectsItemsOnClick so a click SELECTS a row rather than
    # triggering it -- and so the panel builds its rows as LIST rows, in the list
    # look (MenuItemWdgt's constructor), not as menu rows; as MEMBER rows
    # (MemberRowWdgt), in the member look, when I have a memberFactsQuery.
    @listContents = new CommandPanelWdgt target: @, selectsItemsOnClick: true, memberRows: @memberFactsQuery?
    @listContents.isLockingToPanels = true
    # with no elements at all I show one placeholder row -- my own words, not an element of my
    # target's, so my target is never asked about it
    placeholder = !@elements.length
    @elements = ["(empty)"]  if placeholder
    @_repaintAsOneUnit =>
      @elements.forEach (element) =>
        color = undefined
        bold = false
        italic = false
        @format.forEach (pair) ->
          if pair[1].call undefined, element
            switch pair[0]
              when 'bold'
                bold = true
              when 'italic'
                italic = true
              else # assume it's a color
                color = pair[0]

        # what a member row shows of its element beside the name, from my target
        memberFacts = if @memberFactsQuery? and !placeholder then @target[@memberFactsQuery] element else {}

        # a row's double-click reaches me (openRow, slot 1 the row), and I forward it to my target
        @listContents.addMenuItem (ListWdgt.labelOf element), @, "select",
          color: color
          bold: bold
          italic: italic
          kindTag: memberFacts.kindTag
          dimmed: memberFacts.dimmed
          doubleClickAction: (if @doubleClickAction? then "openRow")

    @listContents.__commitMoveTo @contents.position()
    @listContents._reLayoutChildren()   # §5.2e: the rows-panel is now a stack; its re-fit chokepoint lays the rows out + self-sizes

    @contents._addNoSettle @listContents

  # A ListWdgt is excluded from the "viewport re-fits its contained stack
  # panel" notification (the old amIPanelOfScrollPanelWdgt returned false for
  # lists): opt OUT so a contained panel re-lays out itself, as before. This
  # opt-out is NARROW -- a list still re-fits on its own drops/grabs/attaches
  # (_reactToChildDropped/_reactToChildGrabbed and the inherited _reLayoutChildrenAndScrollbars),
  # which is exactly why those are kept separate from this notification.
  _reLayOutAfterContainedPanelChange: ->
    undefined

  # A row's click dispatches here with the row itself in slot 1 (ButtonWdgt.trigger); slot 2, the
  # row's subject, is always this list, so it carries nothing and is not taken. My rows read the
  # selection as they paint (CommandPanelWdgt.showsAsItsSelection), so my rows panel is told it moved.
  select: (row) ->
    @selected = row
    @listContents.noteShownSelectionChanged()
    if @action? and @action != ""
      @target[@action].call @target, row.labelString
    return

  # A row's DOUBLE-click dispatches here, the row again in slot 1 (ButtonWdgt.triggerDoubleClick), and
  # follows the click that selected it: my target's doubleClickAction is run on the row's label.
  openRow: (row) ->
    @target[@doubleClickAction].call @target, row.labelString
    return

  # MY MEMBER ROWS ARE AS WIDE AS I AM. At every arrange of mine -- the settle of my build, a resize,
  # a re-fit -- and before my viewport's arrange measures my plane, my rows panel takes my width and
  # lays its rows out at it: it keeps that width (CommandPanelWdgt._myArrangedWidth), so each member
  # row is my width less the panel's padding, a long name is cropped in its row, and I never scroll
  # sideways. A plain list's panel hugs its widest row instead and may run past me (my horizontal
  # bar). My rows panel does not exist yet while my viewport base builds its own chrome.
  _positionAndResizeChildren: ->
    if @memberFactsQuery? and @listContents? and @listContents.width() isnt @width()
      @listContents._applyExtentBase new Point @width(), @listContents.height()
      @listContents._reLayoutChildren()
    super

  
  _applyExtent: (aPoint) ->
    unless aPoint.equals @extent()
      lb = @listContents.boundingBox()
      # anti-vacant-space on growth: if my grown window would reach past the rows' far edge
      # (and the rows are still bigger than the window), drag the rows' edge to the window's.
      # The rows live on my PLANE, so the comparison runs in plane coordinates — the window's
      # plane rect is frame origin + offset + my new extent (paint-time scroll model).
      windowRight = @contents.left() + @scrollOffsetX + aPoint.x
      windowBottom = @contents.top() + @scrollOffsetY + aPoint.y
      if windowRight > lb.right() and aPoint.x <= lb.width()
        @listContents._moveRightSideTo windowRight
      if windowBottom > lb.bottom() and aPoint.y <= lb.height()
        @listContents._moveBottomSideTo windowBottom
      super aPoint
