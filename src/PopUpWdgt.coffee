# PopUp widgets are special Widgets that have quite complex logic for
# opening themselves, closing themselves when users click outside,
# popping up, opening sub-widgets, and pinning them down.
# They don't specify their own "look" (apart from shadows, see below),
# nor the contents or the look of the contents.
#
# PopUps have 3 different shadows: "normal", "when dragged" and
# "pinned on desktop", plus no shadow when pinned on anything
# else other than the desktop.

class PopUpWdgt extends Widget

  killThisPopUpIfClickOnDescendantsTriggers: true
  killThisPopUpIfClickOutsideDescendants: true
  isPopUpMarkedForClosure: false
  # the closure mark pairs with the world.popUpsMarkedForClosure set (never serialized), so it
  # must not persist — a triggering menu-item click marks its menu BEFORE running the action,
  # so e.g. a menu-driven save would otherwise bake the mark into the file. (__add also clears
  # it on attach, but the file should not carry it in the first place.)
  @serializationTransients: ["isPopUpMarkedForClosure"]
  # the widgetOpeningThePopUp is only useful to get the "parent" pop-up.
  # the "parent" pop-up is the menu that this menu is attached to,
  # but we need this extra property because it's not the
  # actual parent. The reason is that menus are actually attached
  # to the world widget. This is for a couple of reasons:
  # 1) they can still appear at the top even if the "parent menu"
  #    or the parent object are not in the foreground. This is
  #    what happens for example in OSX, you can right-click on a
  #    widget that is not in the background but the menu that comes up
  #    will be in the foreground.
  # 2) they can appear unoccluded if the "parent widget" or "parent object"
  #    are in a widget that clips at its boundaries.
  widgetOpeningThePopUp: undefined
  # the MenuRowsPanelWdgt that is this pop-up's whole visible body (box, optional
  # title header, and the rows) — both subclasses (MenuWdgt / PromptWdgt) build
  # one and delegate/compose against it; the shared lay-and-hug + membership-
  # change absorber below work off it. Free-floating, so it co-moves with me.
  rowsPanel: undefined
  # the ViewportWdgt my rows live in — ALWAYS, not only when they overflow. See
  # _buildRowsViewportNoSettle for why it is unconditional.
  rowsViewport: undefined

  constructor: (@widgetOpeningThePopUp, @killThisPopUpIfClickOutsideDescendants = true, @killThisPopUpIfClickOnDescendantsTriggers = true) ->
    super()
    @isLockingToPanels = false
    world.freshlyCreatedPopUps.add @
    world.openPopUps.add @

  # ── LAY OUT THE ROWS, AND NEVER GROW PAST THE WORLD ──────────────────────────
  # Lay my rows-panel out and take its size, bounded by the world. The
  # panel is a vertical stack (§5.2e): its re-fit chokepoint _reLayoutChildren
  # lays the rows out and self-sizes it via immediate mutators (FLOWRULE-safe); I
  # then take that extent — bounded — via the non-notifying _applyExtentBase twin.
  # MenuWdgt drives this at popUp (_reactToBeingAdded); PromptWdgt lays inline at
  # build; popUp itself drives it once more so both kinds pass through the cap.
  #   The cap is what keeps me REACHABLE, and position alone cannot deliver that:
  # popUp's `_moveWithin world` clamps a POSITION, so for a pop-up taller than the
  # world it can only pin my top-left, leaving every row past the bottom edge
  # drawn where nothing can click it. The margins are thin enough for that to be
  # an everyday case rather than a pathological one — against the 440px test world
  # a plain TextWdgt's own context menu wants 498px (three rows over) and a
  # StringWdgt's 462px, while the menus that do fit clear it by a handful of pixels.
  # Bounded here, the overflow becomes scrollable instead of lost.
  _layOutAndHugRowsPanel: ->
    return unless @rowsPanel?
    @rowsPanel._reLayoutChildren()
    @_refitRowsViewportNoSettle()
    @_applyExtentBase @rowsViewport.extent()

  # THE ONE PLACE MY SIZE IS DECIDED: my rows' natural extent, bounded by the world on
  # BOTH axes. That bound is the whole mechanism — whatever does not fit becomes
  # scrollable instead of unreachable — and it is both axes because the defect is not
  # about height: a pop-up wider than the world loses its right-hand columns exactly
  # as one taller than it loses its bottom rows, and `_moveWithin` can no more fix the
  # one than the other. The frame's own horizontal bar covers that case for free.
  #   The frame is chrome I own and place from my own size, so this uses the
  # NON-notifying arrange twins (§4.2 structural arrange), exactly as ViewportWdgt
  # places its own bars. Shared by every pop-up that re-takes its size: the lay-out
  # above, PromptWdgt's inline build, and SaveShortcutPromptWdgt's widening.
  _refitRowsViewportNoSettle: ->
    @rowsViewport._applyMoveToBase @position()
    @rowsViewport._applyExtentBase new Point (Math.min @rowsPanel.width(), world.width()),
                                                (Math.min @rowsPanel.height(), world.height())
    @rowsViewport._reLayoutChildren()

  # My rows ALWAYS live in a scroll frame — there is no over-tall case and no
  # ordinary case, just the one structure that fits either. A conditional frame
  # would buy a few widgets per menu at the price of a THRESHOLD, and a threshold
  # is a state transition somebody has to get right: a menu composed short and
  # grown later (addMenuItem on an open menu) would have to restructure itself
  # mid-life, in the middle of the very membership change that provoked it. With
  # the frame always present there is nothing to cross — a menu that fits simply
  # has nothing to scroll, and ViewportWdgt hides a bar with nothing to show.
  #   The composition is the one ListWdgt uses: a ViewportWdgt keeping its own content
  # pane (mine is a PopUpRowsPaneWdgt), with the rows panel placed INSIDE that.
  #   ⛔ Do NOT "simplify" this by making the rows panel BE the frame's contents.
  # That shape does not terminate, EVEN WITH the scrolled-content contract fully
  # declared (width-ownership, content-sizing, the absorb forward): the viewport is
  # its plane's sole frame committer and writes the pure measure, while
  # MenuRowsPanelWdgt is a SELF-frame-writing plane — its arrange re-applies its hug
  # (widest row + 2*padding, tight height) — so the two writers disagree by a constant
  # and oscillate forever (RECALC_NONCONVERGENCE). A menu OWNS its frame, so it can
  # never be the committed contents of anything, which is why ListWdgt is built this
  # way too. Falsification record + probe: the §7.2 line in docs/BACKLOG.md.
  #   ⚠ EVERY FACT THE TWO ADDED WIDGETS NEED IS A PER-CLASS DECLARATION, which is why
  # they are classes (PopUpRowsViewportWdgt / PopUpRowsPaneWdgt) rather than a
  # configured ViewportWdgt: a plain panel's inherited answers are wrong on all of
  # them — it claims to be an editing surface, a drop target, a thing you can drag a
  # child out of, and a HIT TARGET. Each wrong answer showed up as a different visible
  # defect; see those two classes.
  #   The one fact that stays MINE is the rows panel's, because the panel is a shared
  # class I am re-homing: dragging a pop-up by its header must move the POP-UP, and a
  # child of a panel detaches instead unless it locks to panels. ListWdgt does exactly
  # this to its own rows panel, for exactly this reason.
  _buildRowsViewportNoSettle: ->
    @rowsViewport = new PopUpRowsViewportWdgt()
    @rowsPanel.isLockingToPanels = true
    @_addNoSettle @rowsViewport
    @rowsViewport.contents._addNoSettle @rowsPanel

  # ALWAYS-ON invariant, in the family of Widget._assertBoundsWellFormed: a pop-up bigger
  # than the world is a pop-up with rows nothing can click. It needs a guard of its own
  # because NO screenshot test reliably catches one — a reference disagrees only if a macro
  # happens to click the row that went missing, which is why menus were shipping rows off
  # the bottom edge unnoticed. The headless runners fail-gate on this token (like
  # NON_INTEGER_GEOMETRY), so the invariant is checked by every test that opens any pop-up
  # rather than by remembering to look.
  _assertFitsInTheWorld: ->
    return unless world?
    return unless @width() > world.width() or @height() > world.height()
    console.error "POPUP_LARGER_THAN_WORLD -- #{@constructor.name} is #{@width()}x#{@height()} in a #{world.width()}x#{world.height()} world, so part of it cannot be reached"
    return

  # The designed membership-change seam (see the stack's _reactToChildRemoved /
  # _reactToChildDropped): when my rows-panel's membership changes (e.g.
  # removeMenuItem on an open menu), absorb it by re-laying the panel and
  # re-hugging its extent NOW — I am not a size-tracking container, so without
  # this the panel would re-fit itself at settle and leave my own frame (and
  # shadow) stale at the old size.
  _reLayOutAfterContainedPanelChange: ->
    @_layOutAndHugRowsPanel()
    true

  hierarchyOfPopUps: ->
    ascendingWdgts = @
    hierarchy = new Set [ascendingWdgts]
    while ascendingWdgts?.getParentPopUp?
      ascendingWdgts = ascendingWdgts.getParentPopUp()
      if ascendingWdgts?
        hierarchy.add ascendingWdgts
    return hierarchy

  # for pop ups, the propagation happens through the getParentPopUp method
  # rather than the parent property, but for other normal widgets it goes
  # up the parent property
  propagateKillPopUps: ->
    if @killThisPopUpIfClickOnDescendantsTriggers
      @getParentPopUp()?.propagateKillPopUps()
      @_markPopUpForClosure()

  _markPopUpForClosure: ->
    world.popUpsMarkedForClosure.add @
    @isPopUpMarkedForClosure = true

  # why introduce a new flag when you can calculate
  # from existing flags?
  isPopUpPinned: ->
    return !(@killThisPopUpIfClickOnDescendantsTriggers or @killThisPopUpIfClickOutsideDescendants)

  # Role query for the world snapshot (Serializer.serializeWorld): an UNPINNED pop-up is
  # mid-gesture UI — it auto-closes on the next outside click / item trigger (indeed the very
  # menu-item click that starts a "save world snapshot…" has already marked its menu for
  # closure) — so a snapshot drops it, exactly like the ephemeral overlays. A PINNED pop-up
  # is desktop furniture and is saved. Dispatched via ?() (nothing on Widget), like isMenu.
  isTransientPopUp: ->
    not @isPopUpPinned()

  getParentPopUp: ->
    if @isPopUpPinned()
      return @parent
    else
      if @widgetOpeningThePopUp?
        return @widgetOpeningThePopUp.firstParentThatIsAPopUp()
    return undefined

  firstParentThatIsAPopUp: ->
    if !@isPopUpMarkedForClosure or !@parent? then return @
    return @parent.firstParentThatIsAPopUp()

  # this is invoked on the menu widget to be
  # pinned. The triggering menu item is the first
  # parameter.
  pinPopUp: (pinMenuItem)->
    @killThisPopUpIfClickOnDescendantsTriggers = false
    @killThisPopUpIfClickOutsideDescendants = false
    @onClickOutsideMeOrAnyOfMyChildren undefined
    if pinMenuItem?
      pinMenuItem.firstParentThatIsAPopUp().propagateKillPopUps()
      world.closePopUpsMarkedForClosure()
    else
      # no-arg caller is _reactToBeingDropped (inside the drop's settle): mark + close the popups through
      # the non-settling core so they ride the drop's flush rather than re-entering the flush guard.
      @getParentPopUp()?.propagateKillPopUps()
      world._closePopUpsMarkedForClosureNoSettle()

    # leave the menu attached to whatever it's attached,
    # just change the shadow.
    @_updatePopUpShadow()
    @_invalidateRowsAfterPinChange()

  # Pinning changes what my ROWS draw: a command row in a pinned menu wears a grip, because
  # being pinned is what makes it liftable (ButtonWdgt.isDetachablePayloadOfMyParent →
  # MenuRowsPanelWdgt.wantsDetachOfChild). That is a fact about ME which they read, so nothing
  # marks them stale unless I do — and the shadow swap above cannot stand in for it: it marks
  # ME, which re-blits my buffer without re-rendering the rows inside it, and on a pop-up pinned
  # into a non-world parent it drops the shadow instead and may not mark anything at all.
  #   No self-marking twin on the row can replace this: a verb whose only job is "repaint
  # yourself" is the general-purpose public repaint verb the invalidation-privacy campaign
  # removed, and the row has no way to notice a flag flipped on me.
  _invalidateRowsAfterPinChange: ->
    # cross-invalidation-sanctioned: own sub-parts — my rows' paint derives from the pinned flags I just flipped
    row._changed() for row in (@rowsPanel?.children ? [])
    return


  fullCopy: ->
    copiedWidget = super
    copiedWidget.onClickOutsideMeOrAnyOfMyChildren undefined
    copiedWidget.killThisPopUpIfClickOnDescendantsTriggers = false
    copiedWidget.killThisPopUpIfClickOutsideDescendants = false
    return copiedWidget


  addWidgetSpecificMenuEntries: (unused_widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "pin", @, "pin", closesUnpinnedPopUps: false
 
  _reactToBeingDropped: (whereIn) ->
    super
    if whereIn != world
      # public-call-sanctioned: pinPopUp is BUILT for this caller — its no-arg branch exists
      # precisely because this hook runs inside the drop's settle, and takes the NoSettle path
      # (_closePopUpsMarkedForClosureNoSettle) so the closures ride the drop's flush instead of
      # re-entering the flush guard. See the comment on that branch.
      @pinPopUp()

    @_updatePopUpShadow()

  _updatePopUpShadow: ->
    # public-call-sanctioned: addShadow/removeShadow are the public shadow API (also driven
    # externally, e.g. by the grab gesture) — consciously reused by this shadow-policy core.
    if @isPopUpPinned()
      if @parent == world
        @addShadow()
      else
        @removeShadow()
    else
      @addShadow()

  # shadow is added to a widget by
  # the ActivePointerWdgt while floatDragging
  addShadow: (offset = new Point(5, 5), alpha = 0.2) ->

    if @isPopUpPinned() and @parent == world
      super new Point(3, 3), 0.3
      return

    super offset, alpha
  
  popUpCenteredAtHand: (world) ->
    @popUp (world.hand.position().subtract @extent().floorDivideBy 2), world
  

  popUpAtHand: ->
    @popUp world.hand.position(), world

  popUp: (pos, widgetToAttachTo) ->
    @__commitMoveTo pos
    widgetToAttachTo.add @
    # Cap-then-clamp, and in that order: laying out decides how TALL I may be (bounded
    # by the world), clamping decides WHERE that fits. Doing it here as well as in
    # _reactToBeingAdded covers the pop-ups that lay themselves out inline at build
    # (PromptWdgt) alongside the ones that lay out at add (MenuWdgt) — this is the one
    # moment every pop-up passes through. Idempotent, so the menu path pays a re-fit.
    @_layOutAndHugRowsPanel()
    # the @_moveWithin method
    # needs to know the extent of the widget
    # so it must be called after the widgetToAttachTo.add
    # method. If you call before, there is
    # nopainting happening and the widget doesn't
    # know its extent.
    @_moveWithin world
    @_assertFitsInTheWorld()
    # shadow must be added after the widget
    # has been placed somewhere because
    # otherwise there is no visible image
    # to base the shadow on
    # P.S. this is the thing that causes the MenuWdgt buffer
    # to be painted after the creation.
    # (addShadow's own _fullChanged closes the invalidation — the add dispatcher
    # already set the dedup flag, so no trailing repaint call is needed here.)
    @addShadow()

  # Leaving the open set belongs in the CORE, beside the _closeNoSettle half below: bulk teardown
  # recurses core-to-core (fullDestroyChildren / _fullDestroyNoSettle) and never calls the public
  # destroy(), so an override there misses every pop-up destroyed as part of a subtree. WorldWdgt's
  # per-cycle openPopUps sweep already covers the gap, which is why this is a tier correction rather
  # than a visible-leak fix.
  _destroyNoSettle: ->
    super
    world.openPopUps.delete @

  # Dismissal policy: a PINNED pop-up is desktop furniture -- closing it is the ordinary
  # widget close (re-homed to the bin, revivable like any widget). An UNPINNED
  # pop-up is mid-gesture UI (menus, prompts, informs): dismissal destroys it outright,
  # like tooltips -- it is rebuilt fresh by its opener every time, so warehousing it
  # would only grow the bin and every world snapshot.
  # Either way I leave the open set here, in the core: the public close() is the
  # inherited canonical wrap, and the NoSettle drain reaches me directly.
  # Idempotent (return if @destroyed): a stale widgetOpeningThePopUp chain can re-mark
  # an already-dismissed pop-up; the destroy branch explicitly no-ops on it.
  _closeNoSettle: ->
    return if @destroyed
    world.openPopUps.delete @
    if @isPopUpPinned()
      super
    else
      @_fullDestroyNoSettle()

