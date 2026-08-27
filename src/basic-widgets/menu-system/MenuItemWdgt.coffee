# I automatically determine my bounds

# A menu row. It extends LabelButtonWdgt (the flat label-bearing button base, on
# the modern ButtonWdgt family) and adds the menu-specific behaviour: a
# self-sizing multi-line TextWdgt label, tick toggling, list-row selection, and
# the "represents a widget" hover-highlight.

class MenuItemWdgt extends LabelButtonWdgt

  # a menu row can be picked up and dropped as a standalone widget; the constructor
  # turns this on for every row
  actionableAsThumbnail: undefined

  # Does a hairline run along my TOP edge? My rows panel DERIVES it at arrange (the row above me
  # has to be another row) and tells me; I hold the answer and my appearance paints it. Paint
  # only, never layout: a separator takes no height, so two rows stay flush and no dead zone opens
  # between two touch targets (ruling G5).
  _separatorAbove: false

  # my MenuRowReflectionSpec when I am a VIEW of somebody else's value (a tick, a wording swap):
  # what my label SAYS is then derived from that value, not fixed when I was built. undefined for an
  # ordinary row.
  #   I SUBSCRIBE MYSELF to the source (see the constructor), because the reflection is mine and not
  # my panel's: all of reflecting is `@label._setTextNoSettle @rowReflection.currentLabel()` on ME,
  # reading MY source through MY readerName. Subscribing the PANEL instead is the tempting shape and
  # it is worse in three ways — it wakes rows that reflect nothing, it needs its own dedup (several
  # rows commonly share one source: seven wallpapers, nine fonts), and it makes a row's liveness a
  # property of where the row currently SITS, so a row moved out of its menu freezes at whatever
  # label it was carrying. One edge per reflecting row is at most nine, and wakes exactly the row
  # whose value moved.
  rowReflection: undefined

  # The widget I show at my left, inside a barGlyphSize box; undefined when I am label-only, which
  # is every row that carries no picture (ruling G3: the glyph is INSET in the target, and the
  # target is the whole of me).
  #   It is a PICTURE and nothing else. A tap anywhere on me is MY click, so an icon derived from a
  # live thing — a copy of a tool, which is still a button — arrives already inert, wrapped in an
  # InertIconHolderWdgt by whoever built the spec.
  icon: undefined

  # THE HORIZONTAL RHYTHM of my contents: the inset I keep at each of my edges and, where I carry
  # an icon, the gap between the glyph box and the label. One dial, because what a reader sees
  # across a row — edge, picture, sentence, edge — is one rhythm.
  CONTENT_INSET: 4

  # The SPEC is the identity — it is what this row IS: spec.label is the STRING I say and
  # spec.icon the optional widget I show. The rest is the menu-level CONTEXT the owning
  # MenuWdgt supplies (font size / style, centring, and the subject), which is the
  # same for every row, so it rides `opts`.
  #
  # The spec's per-item fields are unpacked onto LabelButtonWdgt's options here; an absent
  # spec.label falls back to "close".
  #   ⚠ @rowReflection and @icon are read BEFORE super: LabelButtonWdgt's constructor labels itself
  # (_reLayoutSelf -> _createLabel) as its last act, so both are already needed by the time it runs.
  constructor: (commandSpec, opts = {}) ->
    @rowReflection = commandSpec.reflection
    @icon = commandSpec.icon
    super commandSpec.target, commandSpec.action,
      closesUnpinnedPopUps: commandSpec.ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      # a REFLECTING row is born showing the current value — no build-then-fix-up dance, and no
      # placeholder-prefix pass to reserve the label width
      labelString: (@rowReflection?.currentLabel() ? commandSpec.label or "close")
      fontSize: opts.fontSize
      fontStyle: opts.fontStyle
      centered: opts.centered
      subject: opts.subject
      toolTip: commandSpec.toolTipMessage
      color: commandSpec.color
      bold: commandSpec.bold
      italic: commandSpec.italic
      doubleClickAction: commandSpec.doubleClickAction
      arg1: commandSpec.argumentToAction1
      arg2: commandSpec.argumentToAction2
      representsAWidget: commandSpec.representsAWidget
    @actionableAsThumbnail = true
    @_subscribeToMyReflectedSource()

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
  # and a menu row outside a panel simply never carries one.
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

  # in theory this would be the right thing to do
  # but a bunch of tests break and it's not worth it
  # as we are going to remake the whole layout system anyways
  #_reLayoutSelf: ->
  #  @label.setExtent @extent().subtract (@label.bounds.origin.subtract @.bounds.origin)

  # MenuItemWdgt hugs its box to its (multi-line, modern TextWdgt) label -- the
  # opposite of LabelButtonWdgt's default single-line StringWdgt label, which
  # leaves the box alone.
  _createLabel: ->
    @label = new TextWdgt @labelString,
      fontSize: @fontSize
      fontName: @fontStyle
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
    # still offers the full target (G3/G5 -- a row is a tap target, and the prompt's Ok/Close
    # buttons are menu rows too). The label then sits centred in whatever height wins, rounded
    # because every widget is placed in integer pixels.
    labelExtent = @label.extent()
    rowHeight = Math.max labelExtent.y, WorldWdgt.preferencesAndSettings.menuRowHeight
    w = @width()
    @__commitExtent new Point (labelExtent.x + 2 * @CONTENT_INSET + @_iconColumnWidth()), rowHeight
    @__commitWidth w
    labelTopInset = Math.round (rowHeight - labelExtent.y) / 2
    np = @position().add new Point (@CONTENT_INSET + @_iconColumnWidth()), labelTopInset
    @label.__commitMoveTo np
    @_placeMyIcon rowHeight

  # WHAT MY ICON TAKES from my label: a barGlyphSize glyph box and the gap after it, and nothing
  # whatever when I show no icon -- which is what keeps a label-only row exactly a label-only row.
  # Two dials, never one (ruling G3): my height is the TARGET (menuRowHeight), the box is the
  # GLYPH inset in it.
  _iconColumnWidth: ->
    return 0 unless @icon?
    WorldWdgt.preferencesAndSettings.barGlyphSize + @CONTENT_INSET

  # Place the picture in its glyph box: the box sits at my left inset, my icon centres in it on
  # both axes, and every number rounds -- a fractional placement fails the suite even where the
  # pixels match (Widget._assertBoundsWellFormed / NON_INTEGER_GEOMETRY).
  #   I adopt the icon only while it is not already mine: _createLabel runs again whenever my label
  # is rebuilt (LabelButtonWdgt._setLabelNoSettle destroys the label alone), and my icon outlives
  # that -- it belongs to the spec I was built from, not to the label of the moment.
  _placeMyIcon: (rowHeight) ->
    return unless @icon?
    glyphBox = WorldWdgt.preferencesAndSettings.barGlyphSize
    @_addNoSettle @icon  unless @icon.parent is @
    iconExtent = @icon.extent()
    iconLeftInset = @CONTENT_INSET + Math.round (glyphBox - iconExtent.x) / 2
    iconTopInset = Math.round (rowHeight - iconExtent.y) / 2
    @icon.__commitMoveTo @position().add new Point iconLeftInset, iconTopInset

  # THE REACTIVE LANE, and the only entrypoint: the drain reaches it by the computed name
  # `_#{action}Connector` from my edge's action, and it JOINS the pass's settle rather than opening
  # one (a sink must never open a settle mid-drain — dataflow rules; the engine has already opened
  # one for the pass). check-layering rule [P] sanctions _settleLayoutsAfterOrJoinEnclosingPass for
  # exactly this shape, which is why it is a `_<name>Connector` and not a "simpler" public method.
  #   There is deliberately no public twin: nothing calls one. A row is born showing the right value
  # (the constructor reads the reflection into its labelString), so the only re-derive that ever has
  # to happen is the reactive one.
  _applyRowReflectionConnector: (ignored) ->
    @_settleLayoutsAfterOrJoinEnclosingPass => @_applyRowReflectionNoSettle()

  # Re-derive my label from the value I reflect. NoSettle: every caller runs inside a settle — the
  # connector lane above joins the drain's.
  _applyRowReflectionNoSettle: ->
    return unless @rowReflection?
    @label._setTextNoSettle @rowReflection.currentLabel()

  isTicked: ->
    @label.text.isTicked()

  toggleTick: ->
    if @label.text.isTicked()
      @label.text = @label.text.toggleTick()
      # _reLayoutSelf is a base no-op on the modern TextWdgt, so it would leave the
      # ticked/unticked label at a stale width; re-measure and re-size instead.
      @label.sizeToTextAndDisableFitting()
      # cross-invalidation-sanctioned: own sub-part — the label's text was poked directly above
      @label._changed()
    else if @label.text.isUnticked()
      @label.text = @label.text.toggleTick()
      @label.sizeToTextAndDisableFitting()
      # cross-invalidation-sanctioned: own sub-part — the label's text was poked directly above
      @label._changed()

  # As a menu entry, prefer the width of everything I show: my (multi-line TextWdgt) label, my
  # edge insets, and my icon column when I carry one. CommandPanelWdgt.maxWidthOfMenuEntries calls
  # this polymorphically rather than type-checking the entry.
  #   Read by NAME. My parts are @label and @icon, and which CHILD each of them happens to be is an
  # order I would then have to keep true from two places at once; a row somehow built without a
  # label is a BUG -- let the read throw loudly here. (This guard is deliberately not a `debugger`
  # statement: that is dead in production and a stealth breakpoint under devtools.)
  menuEntryPreferredWidth: ->
    @label.width() + 2 * @CONTENT_INSET + @_iconColumnWidth()

  # MenuItemWdgt events:
  hoverEntered: ->

    if @representsAWidget
      if @argumentToAction1?
        # this first case handles when you pick a widget
        # as a target
        widgetToBeHighlighted = @argumentToAction1
      else
        # this second case handles when you attach to a widget
        widgetToBeHighlighted = @target
      widgetToBeHighlighted.turnOnHighlight()
    unless @isListItem()
      @state = @STATE_HIGHLIGHTED
      @_changed()
    if @toolTipMessage
      @startCountdownForBubbleHelp @toolTipMessage

  hoverExited: ->
    if @representsAWidget
      if @argumentToAction1?
        # this first case handles when you pick a widget
        # as a target
        widgetToBeHighlighted = @argumentToAction1
      else
        # this second case handles when you attach to a widget
        widgetToBeHighlighted = @target
      widgetToBeHighlighted.turnOffHighlight()
    unless @isListItem()
      @state = @STATE_NORMAL
      @_changed()
    world.destroyToolTips()  if @toolTipMessage

  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    # LabelButtonWdgt.mouseDownLeft sets STATE_PRESSED + bringToForeground + escalate
    super

  isListItem: ->
    # true when my container selects rows on click (a CommandPanelWdgt used as a
    # ListWdgt's contents) rather than triggering them (a MenuWdgt). Dispatched via
    # ?() so a plain menu, which does not answer it, reads falsy.
    return @parent.selectsItemsOnClick?()  if @parent
    false
