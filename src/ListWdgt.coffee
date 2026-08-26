class ListWdgt extends ViewportWdgt

  # The label rule when a caller supplies none. A STATIC, so every list shares the
  # one function object rather than each instance carrying its own closure.
  @defaultLabelGetter: (element) ->
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
  labelGetter: undefined
  format: undefined
  listContents: undefined # a CommandPanelWdgt with the contents of the list
  selected: undefined # actual element currently selected
  active: undefined # menu item representing the selected element
  action: undefined
  target: undefined
  doubleClickAction: undefined

  # The rows are the operand: every caller supplies them, while only the inspector
  # supplies target/action — which as leading positionals made the other six sites
  # open with `undefined, undefined` just to reach the rows (R3).
  constructor: (@elements = [], opts = {}) ->
    @target = opts.target
    @action = opts.action
    @labelGetter = opts.labelGetter ? ListWdgt.defaultLabelGetter
    @format = opts.format ? []
    @doubleClickAction = opts.doubleClickAction
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
    #    the given format category (color, bold, italic).
    #    If no condition is met, the default format (color black, non-bold,
    #    non-italic) will be assigned.
    #
    #    An example of how to use formats can be found in the InspectorWdgt's
    #    "_filterProperties" mechanism.
    #
    super()
    @contents.disableDrops()
    @color = Color.WHITE
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
    # triggering it.
    @listContents = new CommandPanelWdgt target: @, selectsItemsOnClick: true
    @listContents.isLockingToPanels = true
    @elements = ["(empty)"]  if !@elements.length
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

        @listContents.addMenuItem @labelGetter(element), @, "select",
          color: color
          bold: bold
          italic: italic
          doubleClickAction: @doubleClickAction

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

  select: (item, trigger) ->
    @selected = item
    @active = trigger
    if @action? and @action != ""
      @target[@action].call @target, item.labelString
    return

  
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
