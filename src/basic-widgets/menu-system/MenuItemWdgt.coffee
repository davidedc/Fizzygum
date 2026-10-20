# I automatically determine my bounds

# A menu row. It extends LabelButtonWdgt (the flat label-bearing button base, on
# the modern ButtonWdgt family) and adds the menu-specific behaviour: a
# self-sizing multi-line TextWdgt label, its two drawn INDICATORS (the submenu
# chevron at its right, the tick in its leading column), list-row selection, the
# "represents a widget" hover-highlight, and the LOOK its context asks for (see the
# constructor): a menu row's, or a plain list row's. A member list's row is my subclass
# MemberRowWdgt.

class MenuItemWdgt extends LabelButtonWdgt

  # a menu row can be picked up and dropped as a standalone widget; the constructor
  # turns this on for every row
  actionableAsThumbnail: undefined

  # Does a hairline run along my TOP edge? My rows panel DERIVES it at arrange (the row above me
  # has to be another row) and tells me; I hold the answer and my appearance paints it. Paint
  # only, never layout: a separator takes no height, so two rows stay flush and no dead zone opens
  # between two touch targets (ruling G5). Only a plain LIST's rows panel tells its rows (the flat
  # look's rhythm mark); a pop-up's rows are told apart by their hover plate and grouped by
  # dividers, and a member list's rows by their selection plate alone, so their answer stays false.
  _separatorAbove: false

  # my MenuRowReflectionSpec when I am a VIEW of somebody else's value: whether I am TICKED is then
  # derived from that value, not fixed when I was built. undefined for an ordinary row.
  #   I SUBSCRIBE MYSELF to the source (see the constructor), because the reflection is mine and not
  # my panel's: all of reflecting is re-reading `@rowReflection.isTicked()` on ME, through MY
  # source and MY readerName. Subscribing the PANEL instead is the tempting shape and it is worse in
  # three ways — it wakes rows that reflect nothing, it needs its own dedup (several rows commonly
  # share one source: seven wallpapers, nine fonts), and it makes a row's liveness a property of
  # where the row currently SITS, so a row moved out of its menu freezes at whatever tick it was
  # carrying. One edge per reflecting row is at most nine, and wakes exactly the row whose value
  # moved.
  rowReflection: undefined

  # Do I OPEN A SUBMENU? My builder states it (addMenuItem's `opensSubmenu: true`, through
  # CommandSpec), because what my action does cannot be read off its name; I show it as a drawn
  # chevron at my right edge, never as text in my label. An own field only when true, so a row that
  # opens nothing carries no trace of it; a duplicated, lifted-out or saved row keeps it, and keeps
  # its chevron.
  opensSubmenu: false

  # MY TICK: undefined for a row that never ticks; true or false for one that does -- read from my
  # reflection when I am born and re-read whenever its source announces a change
  # (_applyRowReflectionNoSettle), or fixed by my builder (addMenuItem's `ticked:`). Shown as a
  # drawn tick in my leading tick column, never as text in my label, which stays my plain wording.
  ticked: undefined

  # Is my leading TICK COLUMN reserved -- does my label start after it, ticked or not? My rows panel
  # reserves it in every row of a menu holding any ticking row, so that menu's labels align, and
  # tells me at each arrange (CommandPanelWdgt._deriveTickColumn); I keep its last answer wherever I
  # go, like the rest of my look. A row that ticks reserves its own until a panel says otherwise.
  _tickColumnReserved: false

  # My two INDICATORS (MenuRowIndicatorWdgt): pointer-transparent children drawing the submenu
  # chevron at my right edge and the tick in my leading column. Each exists exactly while I show it,
  # built and placed by _placeMyParts.
  submenuIndicator: undefined
  tickIndicator: undefined

  # The widget I show at my left, inside a menuRowGlyphSize box; undefined when I am label-only,
  # which is every row that carries no picture (ruling G3: the glyph is INSET in the target, and
  # the target is the whole of me).
  #   It is a PICTURE and nothing else. A tap anywhere on me is MY click, so an icon derived from a
  # live thing — a copy of a tool, which is still a button — arrives already inert, wrapped in an
  # InertIconHolderWdgt by whoever built the spec.
  icon: undefined

  # THE HORIZONTAL RHYTHM of my contents, two dials: the inset I keep at each of my sides (whatever
  # I show first -- my tick column, my icon's glyph box, or my label -- starts this far in, and
  # whatever I show last -- my label, or my submenu chevron's ink -- ends this far short of my right
  # edge) and, where I carry an icon, the gap between the glyph box and the label. Two, because a
  # row's edge and the space after its picture are spaced differently. Both are my LOOK's (see the
  # constructor); my indicators' own sizes and gaps are the theme's (menuRowChevron* / menuRowTick*).
  sideInset: undefined
  iconGap: undefined

  # The SPEC is the identity — it is what this row IS: spec.label is the STRING I say and
  # spec.icon the optional widget I show. The rest is the menu-level CONTEXT the owning
  # panel supplies (font role / size / style, centring, the subject, and which look I wear),
  # which is the same for every row, so it rides `opts`.
  #
  # The spec's per-item fields are unpacked onto LabelButtonWdgt's options here; an absent
  # spec.label falls back to "Close".
  #
  # MY LOOK is my context's, chosen once, here (_lookFor): a plain LIST's rows panel builds me as a
  # list row (`listRow`), in the flat look -- 17 px, state fills over my whole box; every other
  # context, a menu's or a prompt's panel or a row built on its own, builds a MENU row -- the
  # draft's 15 px ink label, a paper box, and a rounded plate while hovered or pressed. (A MEMBER
  # list's rows panel builds a MemberRowWdgt, whose look is its own.) Every value lands in a field
  # of mine, so I keep the look I was built with wherever I go: lifted out of a pinned menu,
  # duplicated onto the desktop, saved in a snapshot and restored. A spec's own `color` still wins
  # for my label's ink (a list formats its entries by it), and an explicit `fontRole` for my font.
  #   WHAT I SAY is the spec's label -- or, when I reflect somebody's value, my reflection's, the
  # same plain wording -- and never carries a mark: whether I open a submenu, and whether I am
  # ticked, are facts of their own (opensSubmenu / ticked) that my indicators draw.
  #   ⚠ @rowReflection, @icon, my tick, my submenu flag and my two rhythm dials are set BEFORE
  # super: LabelButtonWdgt's constructor labels itself (_reLayoutSelf -> _createLabel, then
  # _placeMyParts) as its last act, so all of them are already needed by the time it runs.
  constructor: (commandSpec, opts = {}) ->
    look = @_lookFor opts
    @sideInset = look.sideInset
    @iconGap = look.iconGap
    @rowReflection = commandSpec.reflection
    @icon = commandSpec.icon
    @opensSubmenu = true  if commandSpec.opensSubmenu
    # a REFLECTING row is born showing the current value — no build-then-fix-up dance
    ticked = if @rowReflection? then @rowReflection.isTicked() else commandSpec.ticked
    if ticked?
      @ticked = ticked
      @_tickColumnReserved = true
    super commandSpec.target, commandSpec.action,
      closesUnpinnedPopUps: commandSpec.ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      labelString: (@rowReflection?.label ? commandSpec.label or "Close")
      fontRole: opts.fontRole ? look.font
      fontSize: opts.fontSize
      fontStyle: opts.fontStyle
      centered: opts.centered
      subject: opts.subject
      toolTip: commandSpec.toolTipMessage
      color: commandSpec.color ? look.ink
      fill: look.restFill
      highlightFill: look.highlightFill
      pressFill: look.pressFill
      plateRadius: look.plateRadius
      plateHeight: look.plateHeight
      bold: commandSpec.bold
      italic: commandSpec.italic
      doubleClickAction: commandSpec.doubleClickAction
      arg1: commandSpec.argumentToAction1
      arg2: commandSpec.argumentToAction2
      representsAWidget: commandSpec.representsAWidget
    @actionableAsThumbnail = true
    @_subscribeToMyReflectedSource()

  # MY LOOK, as one record my constructor reads before super: my label's font role and ink, my rest
  # fill, my two state fills and the plate they are painted as (its rounding -- absent: they cover
  # my whole box, square -- and its height -- absent: my whole height), and my horizontal rhythm
  # (sideInset, iconGap). A plain list row's when my context asks for one (`listRow`), a menu row's
  # otherwise; a row kind with a look of its own answers its own (MemberRowWdgt).
  _lookFor: (opts) ->
    theme = WorldWdgt.theme
    if opts.listRow
      font: theme.fonts.listRow
      ink: theme.listRowText
      restFill: theme.listRowFill
      highlightFill: theme.listRowHighlightFill
      pressFill: theme.listRowPressFill
      # no plate: a list row's state fills cover its whole box
      plateRadius: undefined
      sideInset: theme.listRowSideInset
      iconGap: theme.listRowIconGap
    else
      font: theme.fonts.menuRow
      ink: theme.menuRowText
      restFill: theme.menuRowFill
      highlightFill: theme.menuRowHoverFill
      pressFill: theme.menuRowPressFill
      plateRadius: theme.menuRowPlateRadius
      sideInset: theme.menuRowSideInset
      iconGap: theme.menuRowIconGap

  # One edge source -> me, waking me whenever the value I show changes by ANY route (a gesture, a
  # script, the loader, another menu). firesOnAnyChange because what I show is almost never the
  # source's VALUE — a text's font, its soft wrap, a wire's delivery policy are none of them their
  # owner's value — so markNonValueChange has to reach me too. I never read what is delivered; I
  # re-read my own source through my reflection's readerName.
  #   No dedup needed and none possible to need: I hold ONE reflection, so I make ONE edge. Several
  # rows sharing a source (the seven wallpapers, the nine fonts) are several DISTINCT consumers.
  #   Lifecycle needs nothing: Widget._destroyNoSettle calls removeAllEdgesOf, so a closed menu's
  # rows drop themselves from the producer's out-set as they are destroyed.
  #   ⚠ addEdge, NOT ensureWireEdges: that one MIRRORS a controller's wire list and drops any wire
  # edge the list does not account for — my subscription is not a wire and is in nobody's list.
  #   ⚠ And firesOnAnyChange is what keeps me SAFE as well as what wakes me: a re-wired controller
  # drops its old wire through _removeOutgoingWireEdgesOf, which spares firesOnAnyChange records —
  # a blunter removal there would silently unsubscribe every open menu showing that controller.
  _subscribeToMyReflectedSource: ->
    return unless @rowReflection?.source?
    world.dataflow.addEdge @rowReflection.source, @, action: "applyRowReflection", firesOnAnyChange: true

  # As a menu/list ROW I am the selectable UNIT (and I stretch FULL-WIDTH in a list), but a click lands on
  # my tight LABEL child. So the editor-focus selection frame must hug ME, not the label's text bounds
  # (owner: a tight-text highlight is visual noise). WorldWdgt._widgetBeingEdited resolves a selected
  # descendant (my label) up to me through this. Capability, not an `instanceof MenuItemWdgt` type-test
  # (type-test-elimination convention — the same reason my glass-box sizing uses a capability, above).
  # (A member list's rows panel frames none of its rows at all: they show their own selection.)
  absorbsDescendantEditorSelection: -> true

  # In a glass box I am sized to my (variable-width) text, not laid out as a square
  # thumbnail like other contents -- the glass-box layout in GlassBoxBottomWdgt
  # keys off this instead of `instanceof MenuItemWdgt`.
  # (type-test-elimination campaign)
  isTextSizedGlassBoxItem: ->
    true

  # THE SEPARATOR PAIR. My panel tells me whether a row sits directly above me; my appearance asks
  # me back when it paints. Both are capability-dispatched (`?()`), so the OTHER row kinds a panel
  # may hold -- a divider, a slider, a colour picker -- neither hear the statement nor draw a line,
  # and a menu row outside a panel simply never carries one. Its one teller is a plain LIST's rows
  # panel (CommandPanelWdgt._deriveRowSeparators).
  showSeparatorAbove: (aBoolean) ->
    return if @_separatorAbove is aBoolean
    @_separatorAbove = aBoolean
    @_changed()

  showsSeparatorAbove: ->
    @_separatorAbove

  # reset my selection highlight (called for every menu child by CommandPanelWdgt.unselectAllItems,
  # replacing its `if item instanceof MenuItemWdgt`). (type-test-elimination campaign)
  unselect: ->
    @state = @STATE_NORMAL

  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of menu item)"
    if @labelString
      textWithoutLocationOrInstanceNo = @labelString.replace /#\d*/, ""
      return textWithoutLocationOrInstanceNo + " (text in button)"
    else
      return super()

  # My re-layout: LabelButtonWdgt's (my label built when I have none, re-centred when I am
  # centred), then every part I show placed against my box as it now is. It runs after every
  # change of my box, so my submenu chevron, which rides my right edge, follows my width.
  _reLayoutSelf: ->
    super()
    @_placeMyParts()

  # MenuItemWdgt hugs its box to its (multi-line, modern TextWdgt) label -- the
  # opposite of LabelButtonWdgt's default single-line StringWdgt label, which
  # leaves the box alone. Building the label sizes me; _placeMyParts, which my _reLayoutSelf runs
  # right after, places it. The label renders my whole font: its family, size and weight, and the
  # italic a list's format can ask for.
  _createLabel: ->
    @label = new TextWdgt @labelString,
      fontSize: @fontSize
      fontName: @fontStyle
      bold: @labelBold
      italic: @labelItalic
    @label.setColor @labelColor

    # _addNoSettle (NOT add): _createLabel is driven by _reLayoutSelf (a layout pass), so a
    # self-settle here would re-enter the flush guard and throw.
    @_addNoSettle @label
    # the modern family does not self-size; make the label hug its text before
    # we read @label.extent() below to size this menu item around it. _createLabel is driven by
    # _reLayoutSelf (a layout pass), so use the NoSettle core -- the wrapper would throw mid-pass.
    @label._sizeToTextAndDisableFittingNoSettle()

    # menuRowHeight is a MINIMUM, not a height: a row is as tall as its label or as tall as the
    # dial, whichever is more, so a big label never gets clipped by a small dial and a small label
    # still offers the full target (G3/G5 -- a row is a tap target). The label then sits centred
    # in whatever height wins (_placeMyLabel).
    labelExtent = @label.extent()
    rowHeight = Math.max labelExtent.y, WorldWdgt.theme.menuRowHeight
    w = @width()
    @__commitExtent new Point (@_leadingWidth() + labelExtent.x + @_trailingWidth()), rowHeight
    @__commitWidth w

  # EVERYTHING I SHOW, placed against my box as it now is -- the one placement, run by my
  # _reLayoutSelf and again whenever my tick or my tick column moves. Left to right: my side inset,
  # my tick column (while reserved), my icon's glyph box (while I carry an icon), my label; and my
  # submenu chevron right-aligned on its ink. Every number rounds: a fractional placement fails the
  # suite even where the pixels match (Widget._assertBoundsWellFormed / NON_INTEGER_GEOMETRY).
  _placeMyParts: ->
    rowHeight = @height()
    @_placeMyLabel rowHeight
    @_placeMyIcon rowHeight
    @_placeMyTick rowHeight
    @_placeMySubmenuChevron rowHeight

  # WHAT STANDS LEFT OF MY LABEL -- the x my label starts at: my side inset, my tick column while
  # it is reserved, and my icon column while I carry an icon.
  _leadingWidth: ->
    @sideInset + @_tickColumnWidth() + @_iconColumnWidth()

  # WHAT STANDS RIGHT OF IT: my side inset, or, while I show my submenu chevron, the chevron gap,
  # the chevron's INK, then my side inset -- the ink, not its glyph square, is what keeps that
  # inset from my right edge (the square overhangs into it).
  _trailingWidth: ->
    return @sideInset  unless @_showsSubmenuChevron()
    [inkLeft, inkRight] = @_submenuChevronInkSpan()
    WorldWdgt.theme.menuRowChevronGap + (inkRight - inkLeft) + @sideInset

  # My label at its x, centred down my height. A CENTRED row's label is LabelButtonWdgt's to
  # place: its _reLayoutSelf centres it in my whole box.
  _placeMyLabel: (rowHeight) ->
    return if @centered
    labelTopInset = Math.round (rowHeight - @label.height()) / 2
    @label.__commitMoveTo @position().add new Point @_leadingWidth(), labelTopInset

  # WHAT MY ICON TAKES from my label: a menuRowGlyphSize glyph box and my icon gap after it, and
  # nothing whatever when I show no icon -- which is what keeps a label-only row exactly a
  # label-only row. Two dials, never one (ruling G3): my height is the TARGET (menuRowHeight), the
  # box is the GLYPH inset in it.
  _iconColumnWidth: ->
    return 0 unless @icon?
    WorldWdgt.theme.menuRowGlyphSize + @iconGap

  # Place the picture in its glyph box: the box sits after my side inset and my tick column, my
  # icon centres in it on both axes.
  #   I adopt the icon only while it is not already mine: my parts are placed again whenever my
  # label is rebuilt (LabelButtonWdgt._setLabelNoSettle destroys the label alone), and my icon
  # outlives that -- it belongs to the spec I was built from, not to the label of the moment.
  _placeMyIcon: (rowHeight) ->
    return unless @icon?
    glyphBox = WorldWdgt.theme.menuRowGlyphSize
    @_addNoSettle @icon  unless @icon.parent is @
    iconExtent = @icon.extent()
    iconLeftInset = @sideInset + @_tickColumnWidth() + Math.round (glyphBox - iconExtent.x) / 2
    iconTopInset = Math.round (rowHeight - iconExtent.y) / 2
    @icon.__commitMoveTo @position().add new Point iconLeftInset, iconTopInset

  # ── MY INDICATORS ────────────────────────────────────────────────────────────────────────────
  # Two drawn marks (MenuRowIndicatorWdgt), each a pointer-transparent child that exists exactly
  # while I show it: built and adopted the first time, destroyed when I stop showing it. Like my
  # icon, they outlive a rebuilt label. A LIST row shows neither and reserves no room for either:
  # lists wear no indicators.

  # Does a tick column run down my leading edge? My rows panel's answer while I sit in one (a pure
  # query, so a measure and the arrange that follows it agree), the answer it last gave me
  # anywhere else.
  _reservesTickColumn: ->
    @parent?.reservesTickColumn?() ? @_tickColumnReserved

  # THE TICK COLUMN: a menuRowTickSize glyph square at my side inset and the tick gap after it --
  # reserved, ticked or not, so a ticking menu's labels all start at one x; nothing when it is not.
  _tickColumnWidth: ->
    return 0 unless @_reservesTickColumn()
    WorldWdgt.theme.menuRowTickSize + WorldWdgt.theme.menuRowTickGap

  # My tick, in ink, at my side inset and centred down my height -- shown while I am ticked and my
  # column is reserved.
  _placeMyTick: (rowHeight) ->
    unless @isTicked() and @_reservesTickColumn()
      # written only when there IS one to drop, so a row that never ticks gains no own field
      @tickIndicator = @tickIndicator._fullDestroyNoSettle()  if @tickIndicator?
      return
    theme = WorldWdgt.theme
    side = theme.menuRowTickSize
    @tickIndicator ?= new MenuRowIndicatorWdgt TickIconAppearance, glyphSize: side, color: theme.menuRowTick
    # placed BEFORE it is adopted, so the add damages the spot it will be painted at
    @tickIndicator.__commitMoveTo @position().add new Point @sideInset, Math.round (rowHeight - side) / 2
    @_addNoSettle @tickIndicator  unless @tickIndicator.parent is @

  # Do I show my submenu chevron? Whenever I open a submenu, except as a list row.
  _showsSubmenuChevron: ->
    @opensSubmenu and not @isListItem()

  # My chevron's INK across its glyph square, [left, right) -- what my width reserves and what my
  # placement right-aligns, so the two read one measurement (ChevronRightIconAppearance.inkSpanX).
  _submenuChevronInkSpan: ->
    ChevronRightIconAppearance.inkSpanX WorldWdgt.theme.menuRowChevronSize

  # My chevron, in its muted ink, centred down my height and placed so that its INK ends my side
  # inset short of my right edge (the draft's right-aligned 16 px ›) -- it rides my right edge, so
  # my _reLayoutSelf re-places it whenever my width changes.
  _placeMySubmenuChevron: (rowHeight) ->
    unless @_showsSubmenuChevron()
      @submenuIndicator = @submenuIndicator._fullDestroyNoSettle()  if @submenuIndicator?
      return
    theme = WorldWdgt.theme
    side = theme.menuRowChevronSize
    @submenuIndicator ?= new MenuRowIndicatorWdgt ChevronRightIconAppearance, glyphSize: side, color: theme.menuRowSubmenuChevron
    inkRight = @_submenuChevronInkSpan()[1]
    # placed BEFORE it is adopted, as my tick is
    @submenuIndicator.__commitMoveTo @position().add new Point (@width() - @sideInset - inkRight), Math.round (rowHeight - side) / 2
    @_addNoSettle @submenuIndicator  unless @submenuIndicator.parent is @

  # THE TICK-COLUMN PAIR (the separator pair's shape): my rows panel tells me, at each arrange,
  # whether its rows reserve the tick column; I keep the answer, and re-place my parts when it
  # moves -- my label shifts by the column, and my tick appears or goes with it.
  reserveTickColumn: (aBoolean) ->
    return if @_tickColumnReserved is aBoolean
    @_tickColumnReserved = aBoolean
    @_placeMyParts()
    @_changed()

  # Do I TICK at all -- does my row carry a tick state, ticked or not? What makes my rows panel
  # reserve its tick column (CommandPanelWdgt.reservesTickColumn).
  ticks: ->
    @ticked?

  # Am I ticked? My tick STATE -- what I show -- never my label's text.
  isTicked: ->
    @ticked is true

  # THE REACTIVE LANE, and the only entrypoint: the drain reaches it by the computed name
  # `_#{action}Connector` from my edge's action, and it JOINS the pass's settle rather than opening
  # one (a sink must never open a settle mid-drain — dataflow rules; the engine has already opened
  # one for the pass). check-layering rule [P] sanctions _settleLayoutsAfterOrJoinEnclosingPass for
  # exactly this shape, which is why it is a `_<name>Connector` and not a "simpler" public method.
  #   There is deliberately no public twin: nothing calls one. A row is born showing the right value
  # (the constructor reads the reflection into its tick), so the only re-derive that ever has to
  # happen is the reactive one.
  _applyRowReflectionConnector: (ignored) ->
    @_settleLayoutsAfterOrJoinEnclosingPass => @_applyRowReflectionNoSettle()

  # Re-derive my tick from the value I reflect, and show or hide it to match. My label and my width
  # stay as they are: the tick column is reserved whether or not I am ticked. NoSettle: every
  # caller runs inside a settle — the connector lane above joins the drain's.
  _applyRowReflectionNoSettle: ->
    return unless @rowReflection?
    ticked = @rowReflection.isTicked()
    return if ticked is @ticked
    @ticked = ticked
    @_placeMyParts()
    @_changed()

  # As a menu entry, prefer the width of everything I show: my side insets, my tick column while it
  # is reserved, my icon column when I carry one, my (multi-line TextWdgt) label, and my submenu
  # chevron's gap and ink while I show it. CommandPanelWdgt.maxWidthOfMenuEntries calls this
  # polymorphically rather than type-checking the entry.
  #   Read by NAME. My parts are @label and @icon, and which CHILD each of them happens to be is an
  # order I would then have to keep true from two places at once; a row somehow built without a
  # label is a BUG -- let the read throw loudly here. (This guard is deliberately not a `debugger`
  # statement: that is dead in production and a stealth breakpoint under devtools.)
  menuEntryPreferredWidth: ->
    @_leadingWidth() + @label.width() + @_trailingWidth()

  # THE WIDGET I STAND FOR, when my builder says I name one (representsAWidget): the widget my
  # action is handed when I carry one (a chooser's pick, the widget a wire drives), else my target
  # (a hierarchy menu's row, a "new parent" row). undefined for every other row. The one answer to
  # "which widget is this row about": hovering me highlights it, and a test finds me by it
  # (MacroToolkit.rowOfMenuStandingFor), since my label is a human name that reads alike for two
  # widgets of one kind until the menu tells them apart.
  representedWidget: ->
    return undefined unless @representsAWidget
    @argumentToAction1 ? @target

  # What tells me from another row on a row that names ME (Widget.distinguishedRowName) — a chooser
  # listing a list's rows, a hierarchy menu over a lifted-out row: my wording, 'Menu item "Demo"'.
  _rowNameDistinction: ->
    @labelString

  # MenuItemWdgt events:
  hoverEntered: ->
    @representedWidget()?.turnOnHighlight()
    unless @isListItem()
      @state = @STATE_HIGHLIGHTED
      @_changed()
    if @toolTipMessage
      @startCountdownForBubbleHelp @toolTipMessage

  hoverExited: ->
    @representedWidget()?.turnOffHighlight()
    unless @isListItem()
      @state = @STATE_NORMAL
      @_changed()
    world.destroyToolTips()  if @toolTipMessage

  pressBegan: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "pressBegan", pos
    # LabelButtonWdgt.pressBegan sets STATE_PRESSED + bringToForeground + escalate
    super

  isListItem: ->
    # true when my container selects rows on click (a CommandPanelWdgt used as a
    # ListWdgt's contents) rather than triggering them (a MenuWdgt). Dispatched via
    # ?() so a plain menu, which does not answer it, reads falsy.
    return @parent.selectsItemsOnClick?()  if @parent
    false
