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

  # MY ONE LIFETIME STATE, which every transient-vs-furniture branch below reads:
  #   'transient'  — mid-gesture UI. The next click outside me (or on a descendant that triggers)
  #                  dismisses me; a world snapshot drops me; dismissal destroys me outright.
  #   'persistent' — desktop furniture. Nothing outside me dismisses me, a snapshot saves me, and
  #                  closing me re-homes me to the bin like any widget.
  # It CHANGES mid-life — pinning is exactly that change — which is why it is a state on one class
  # rather than two classes. Set through setLifetime / _setLifetimeNoSettle, which is also where
  # every consequence of the change lives.
  lifetime: 'transient'
  isPopUpMarkedForClosure: false
  # the closure mark pairs with the world.popUpsMarkedForClosure set (never serialized), so it
  # must not persist — a triggering menu-item click marks its menu BEFORE running the action,
  # so e.g. a menu-driven save would otherwise bake the mark into the file. (__add also clears
  # it on attach, but the file should not carry it in the first place.)
  # A deep-copied true mark (the same menu action can duplicate its own menu) is inert on the
  # clone: it is never in the world's set (no aligner puts it there), and that same __add clear
  # wipes the field on the clone's first attach.
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
  # change absorber below work off it. It is the rows viewport's contents plane
  # (see _buildRowsViewportNoSettle), so it co-moves with me through the viewport.
  rowsPanel: undefined
  # the ViewportWdgt my rows live in — ALWAYS, not only when they overflow. See
  # _buildRowsViewportNoSettle for why it is unconditional.
  rowsViewport: undefined

  # freshlyCreatedPopUps is a fact about CONSTRUCTION (the hand skips a pop-up born under the very
  # click that is still being processed, and clears the set at mouse-up), so it is enrolled here;
  # membership of the open set rides the lifetime instead, and my citizens declare that in their
  # own constructors (see _setLifetimeNoSettle).
  constructor: (@widgetOpeningThePopUp) ->
    super()
    @isLockingToPanels = false
    world.freshlyCreatedPopUps.add @

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
  # one than the other. The viewport's own horizontal bar covers that case for free.
  #   The viewport is chrome I own and place from my own size, so this uses the
  # NON-notifying arrange twins (§4.2 structural arrange), exactly as ViewportWdgt
  # places its own bars. Shared by every pop-up that re-takes its size: the lay-out
  # above, PromptWdgt's inline build, and SaveShortcutPromptWdgt's widening.
  _refitRowsViewportNoSettle: ->
    @rowsViewport._applyMoveToBase @position()
    @rowsViewport._applyExtentBase new Point (Math.min @rowsPanel.width(), world.width()),
                                                (Math.min @rowsPanel.height(), world.height())
    @rowsViewport._reLayoutChildren()

  # My rows ALWAYS live in a viewport — there is no over-tall case and no
  # ordinary case, just the one structure that fits either. A conditional viewport
  # would buy a few widgets per menu at the price of a THRESHOLD, and a threshold
  # is a state transition somebody has to get right: a menu composed short and
  # grown later (addMenuItem on an open menu) would have to restructure itself
  # mid-life, in the middle of the very membership change that provoked it. With
  # the viewport always present there is nothing to cross — a menu that fits simply
  # has nothing to scroll, and ViewportWdgt hides a bar with nothing to show.
  #   The rows panel IS the viewport's contents plane, directly — no intermediate
  # pane. That is legal for this self-sizing panel because its hug is also a PURE
  # MEASURE the committer commits VERBATIM (MenuRowsPanelWdgt.scrolledContentMeasure
  # + scrolledContentMeasureIsMyFrame), so the panel's own arrange and the
  # viewport's frame commit write byte-the-same box in EVERY state and there is no
  # two-writer fight. Both halves are load-bearing: with the committer's default
  # window-floor/grow-to-fill adjustments live, or with a committed frame the hug
  # disagrees with, the pair oscillates (RECALC_NONCONVERGENCE) — measured through
  # three routes: the direct-contents shape without the measure redesign (twice,
  # the docs/BACKLOG.md §7.2 record), menu compose at the viewport's default build
  # extent, and the duplication path (menu-sandwich dissolution plan, Phase 0).
  #   EVERY FACT THE VIEWPORT NEEDS IS A PER-CLASS DECLARATION, which is why it is
  # a class (PopUpRowsViewportWdgt) rather than a configured ViewportWdgt: a plain
  # viewport's inherited answers are wrong on all of them — it claims to be an
  # editing surface, a drop target, a HIT TARGET, and a holder of loose scrollable
  # content someone may drag a row out of. Each wrong answer showed up as a
  # different visible defect; see that class.
  #   The one fact that stays MINE is the rows panel's, because the panel is a shared
  # class I am re-homing: dragging a pop-up by its header must move the POP-UP, and a
  # child of a panel detaches instead unless it locks to panels. ListWdgt does exactly
  # this to its own rows panel, for exactly this reason.
  _buildRowsViewportNoSettle: ->
    @rowsPanel.isLockingToPanels = true
    @rowsViewport = new PopUpRowsViewportWdgt @rowsPanel
    @_addNoSettle @rowsViewport
    # refit NOW, not first at popUp: a settle between build and popUp must find the
    # viewport already sized/placed to the panel (vp = min(hug, world)), never at its
    # meaningless default build extent.
    @_refitRowsViewportNoSettle()

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
    if @lifetime is 'transient'
      @getParentPopUp()?.propagateKillPopUps()
      @_markPopUpForClosure()

  _markPopUpForClosure: ->
    world.popUpsMarkedForClosure.add @
    @isPopUpMarkedForClosure = true

  # "Am I furniture?" — the persistent half of the lifetime state, under the name the rows
  # (MenuRowsPanelWdgt.wantsDetachOfChild), the shadow policy and the close policy ask by.
  isPopUpPinned: ->
    @lifetime is 'persistent'

  # Role query for the world snapshot (Serializer.serializeWorld): an UNPINNED pop-up is
  # mid-gesture UI — it auto-closes on the next outside click / item trigger (indeed the very
  # menu-item click that starts a "save world snapshot…" has already marked its menu for
  # closure) — so a snapshot drops it, exactly like the ephemeral overlays. A PINNED pop-up
  # is desktop furniture and is saved. Dispatched via ?() (nothing on Widget), like isMenu.
  isTransientPopUp: ->
    @lifetime is 'transient'

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

  # The public, self-settling half of the lifetime state (the core below does the work).
  setLifetime: (aLifetime) ->
    @_settleLayoutsAfter => @_setLifetimeNoSettle aLifetime

  # THE ONE PLACE MY LIFETIME CHANGES, so the one place every consequence of the change lives.
  #   Entering 'persistent' hands me to the user: the click-outside dismissal callback goes (nothing
  # outside me may dismiss me any more), my shadow re-derives for furniture, and my rows re-read the
  # grip fact (see _invalidateRowsAfterPinChange).
  #   Entering 'transient' makes me mid-gesture UI: I join the open set the world sweeps and arms the
  # click-outside dismissal that ends me.
  #   Nothing settles here — the drop path reaches this inside the drop's own settle (see pinPopUp's
  # no-arg branch), so the settling half is the setLifetime wrapper above.
  _setLifetimeNoSettle: (aLifetime) ->
    # public-call-sanctioned: onClickOutsideMeOrAnyOfMyChildren is pure REGISTRY bookkeeping (one
    # add/delete on world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren) — it settles nothing and
    # touches no geometry, so calling it from a NoSettle core is settle-neutral (the same sign-off
    # Widget._destroyNoSettle carries for the same call).
    @lifetime = aLifetime
    if aLifetime is 'persistent'
      @onClickOutsideMeOrAnyOfMyChildren undefined
      @_updatePopUpShadow()
      @_invalidateRowsAfterPinChange()
    else
      world.openPopUps.add @
      @onClickOutsideMeOrAnyOfMyChildren "close"
    return

  # The user-facing verb for "this pop-up stays" — the header tap, the "pin" row, and a drop into a
  # container all land here. The pin itself is the lifetime entry above; what belongs to THIS verb is
  # the sibling sweep: the pop-ups I was opened from are mid-gesture UI that the pin ends, so the
  # chain above me is marked for closure and drained. It is invoked on the pop-up to be pinned; the
  # triggering menu item is the first parameter.
  pinPopUp: (pinMenuItem)->
    @_setLifetimeNoSettle 'persistent'
    if pinMenuItem?
      pinMenuItem.firstParentThatIsAPopUp().propagateKillPopUps()
      world.closePopUpsMarkedForClosure()
    else
      # no-arg caller is _reactToBeingDropped (inside the drop's settle): mark + close the popups through
      # the non-settling core so they ride the drop's flush rather than re-entering the flush guard.
      @getParentPopUp()?.propagateKillPopUps()
      world._closePopUpsMarkedForClosureNoSettle()

  # Pinning changes what my ROWS draw: a command row in a pinned menu wears a grip, because
  # being pinned is what makes it liftable (ButtonWdgt.isDetachablePayloadOfMyParent →
  # MenuRowsPanelWdgt.wantsDetachOfChild). That is a fact about ME which they read, so nothing
  # marks them stale unless I do — and the shadow swap above cannot stand in for it: it marks
  # ME, which re-blits my buffer without re-rendering the rows inside it, and on a pop-up pinned
  # into a non-world parent it drops the shadow instead and may not mark anything at all.
  #   No self-marking twin on the row can replace this: a verb whose only job is "repaint
  # yourself" is the general-purpose public repaint verb the invalidation-privacy campaign
  # removed, and the row has no way to notice a state change on me.
  _invalidateRowsAfterPinChange: ->
    # cross-invalidation-sanctioned: own sub-parts — my rows' paint derives from the lifetime I just set
    row._changed() for row in (@rowsPanel?.children ? [])
    return


  # A duplicate is born furniture: nobody is mid-gesture with a copy, so it must not evaporate on
  # the next click (SystemTest_macroDuplicatedMenuAutoPinsOnDesktop asserts exactly that).
  # The state is written directly rather than through the lifetime entry: the copy is a fresh ORPHAN
  # carrying my own shadow verbatim, and the entry's shadow re-derive reads a parent it does not
  # have yet — the copy takes its shadow from wherever the copy gesture lands it.
  fullCopy: ->
    copiedWidget = super
    copiedWidget.onClickOutsideMeOrAnyOfMyChildren undefined
    copiedWidget.lifetime = 'persistent'
    return copiedWidget


  addWidgetSpecificMenuEntries: (unused_widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "pin", @, "pinPopUp", closesUnpinnedPopUps: false
 
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

