# The world's storage sorter -- the eager keeper of the STANDING STORAGE
# INVARIANT: everything on the shelf (world.shelfWdgt) is REACHABLE, everything
# in the bin (world.binWdgt) is LOST, at all times.
# (docs/archive/bin-shelf-eager-sorting-plan.md -- the owner-directed successor
# to the bin's lazy sort-at-open view.)
#
# HOW: reachability changes only at a small set of events, all funnelled
# through chokepoints (the reference tracker's three mutation sites, close
# filing, arrivals into / departures from an open bin window, the app-slot
# writes, snapshot restore). Each chokepoint calls the mark-only
# world.noteStorageMembershipMayHaveChanged() -- O(1), safe inside bulk destroy
# storms -- and the pending sort DRAINS once per world cycle in doOneCycle,
# between the dataflow drain and the layout flush (the dataflow-station
# precedent: the drain may dirty real layout -- moving residents while a bin
# window is open -- so it must precede recalculateLayouts; one-way coupling).
#
# WHY a cycle-drain and not per-event sorting: a shortcut REGISTERS into the
# tracker in its constructor, while still an orphan (its attach follows in the
# same gesture) -- classifying at that instant would misread its target; and a
# bulk teardown fires the destroy hook once per shortcut. The end-of-cycle
# drain absorbs both in one mechanism.
class StorageSorter

  constructor: ->
    @sortPending = false
    @_draining = false

  noteMembershipMayHaveChanged: ->
    # marks fired DURING the drain are the drain's OWN moves echoing back
    # through the containers' child-add/removed relays (the drain is
    # synchronous, so nothing else can interleave); its placements are correct
    # by construction, so re-pending would only schedule a pointless re-sort --
    # and trip the audit's flag-clear-at-exit check. Mirrors the dataflow
    # drain's no-re-entry rule.
    return if @_draining
    @sortPending = true

  # the doOneCycle station: dark-cheap when nothing is pending.
  drainPendingSort: ->
    return unless @sortPending
    world._settleLayoutsAfter => @_drainNoSettle()

  _drainNoSettle: ->
    @sortPending = false
    @_draining = true
    try
      newGcSessionId = @_runClassifier()
      # Move misplaced residents. They are all FIGURES and all siblings, so a
      # move never changes another resident's classification (the containers
      # themselves are never marked -- markItAndItsParentsAsReachable stops at
      # the storage boundary). Destroyed residents are skipped defensively (the
      # audit below screams about them; the drain must not resurrect them).
      for w in world.binWdgt.scrollPanel.contents.children.slice()
        continue if w.destroyed
        if w.isInStorageButReachable newGcSessionId
          world.shelfWdgt._addRestingWidgetNoSettle w
      for w in world.shelfWdgt.children.slice()
        continue if w.destroyed
        if !w.isInStorageButReachable newGcSessionId
          world.binWdgt._addRestingWidgetNoSettle w
      @_auditStorageNoSettle newGcSessionId
    finally
      @_draining = false

  # The reachability classifier -- the bin's old doGC re-derived STORAGE-AWARE
  # (plan Phase 0, spike-proven equivalent to the open-bin classification), so
  # it is correct with every storage container off-tree. It marks everything
  # reachable with a fresh gc session id; placement is then read per-resident
  # via isInStorageButReachable. Internal to the drain: placement queries
  # outside it use the containers' holds().
  _runClassifier: ->
    world.incrementalGcSessionId++
    newGcSessionId = world.incrementalGcSessionId

    # pass 1: an orphan reference NOT resting in storage is unreachable by
    # definition and cannot make its target reachable -- discard. An orphan
    # reference IN storage is a potential RELAY through a chain, resolved by
    # the pass-3 fixpoint. (The old classifier discarded ALL orphans, which is
    # why it carried the "bin must be on-screen" precondition: with the bin
    # off-tree its residents are orphans, and chains through them broke.)
    for eachReferencingWdgt from world.widgetsReferencingOtherWidgets
      if eachReferencingWdgt.isOrphan() and !eachReferencingWdgt.isInStorage()
        eachReferencingWdgt.markReferenceAsVisited newGcSessionId

    # pass 2: the remaining not-in-storage references are reachable from the
    # desktop or the hand -- seed reachability from their targets (which MIGHT
    # rest in storage).
    for eachReferencingWdgt from world.widgetsReferencingOtherWidgets
      if !eachReferencingWdgt.wasReferenceVisited newGcSessionId
        if !eachReferencingWdgt.isInStorage()
          eachReferencingWdgt.target.markItAndItsParentsAsReachable newGcSessionId
          eachReferencingWdgt.markReferenceAsVisited newGcSessionId

    # system furniture parked in storage is reachable through WORLD FIELDS, not
    # the tracker: the app singletons (world[slot], revived by their launchers)
    # and the editor templates window (revived by TemplatesButtonWdgt). Marked
    # before the fixpoint so references held INSIDE them relay like any other
    # reachable resident.
    for slot in Serializer.WORLD_APP_SLOTS
      world[slot]?.markItAndItsParentsAsReachable newGcSessionId
    world.simpleEditorTemplates?.markItAndItsParentsAsReachable newGcSessionId

    # pass 3 fixpoint: a storage-resting reference whose ancestors became
    # reachable relays reachability to its own target; chains resolve
    # progressively until no new reference is uncovered.
    newReachableReferencesUncovered = true
    while newReachableReferencesUncovered
      newReachableReferencesUncovered = false
      for eachReferencingWdgt from world.widgetsReferencingOtherWidgets
        if !eachReferencingWdgt.wasReferenceVisited newGcSessionId
          if eachReferencingWdgt.isInStorageButReachable newGcSessionId
            newReachableReferencesUncovered = true
            eachReferencingWdgt.target.markItAndItsParentsAsReachable newGcSessionId
            eachReferencingWdgt.markReferenceAsVisited newGcSessionId

    return newGcSessionId

  # ---- Tier A: the always-on storage-invariant guard ----
  # Runs at drain exit (with the drain's fresh session id) and at the
  # test-teardown seam (resetWorld's end, no session id -> structural checks
  # only). O(residents + tracker). Each violation console.errors ONE greppable
  # STORAGE_INVARIANT token line; both headless runners gate on the token, so
  # every suite leg enforces the invariant for free (the NON_INTEGER_GEOMETRY
  # precedent). Quiet during teardown BY CONSTRUCTION (mirroring the bounds
  # guard): it is only ever called from the drain station -- which never runs
  # mid-teardown -- and from resetWorld's end, after the world is consistent.
  _auditStorageNoSettle: (justComputedGcSessionId = nil) ->
    binContents = world.binWdgt?.scrollPanel?.contents
    if binContents?
      for w in binContents.children
        if w.destroyed
          console.error "STORAGE_INVARIANT destroyed-resident-in-bin " + w.constructor.name
        else if justComputedGcSessionId? and w.isInStorageButReachable justComputedGcSessionId
          console.error "STORAGE_INVARIANT reachable-in-bin " + w.constructor.name
        if w.parent != binContents
          console.error "STORAGE_INVARIANT parent-desync-in-bin " + w.constructor.name
    if world.shelfWdgt?
      for w in world.shelfWdgt.children
        if w.destroyed
          console.error "STORAGE_INVARIANT destroyed-resident-on-shelf " + w.constructor.name
        else if justComputedGcSessionId? and !w.isInStorageButReachable justComputedGcSessionId
          console.error "STORAGE_INVARIANT lost-on-shelf " + w.constructor.name
        if w.parent != world.shelfWdgt
          console.error "STORAGE_INVARIANT parent-desync-on-shelf " + w.constructor.name
    for eachReferencingWdgt from world.widgetsReferencingOtherWidgets
      if eachReferencingWdgt.destroyed
        console.error "STORAGE_INVARIANT destroyed-tracker-member " + eachReferencingWdgt.constructor.name
    if justComputedGcSessionId? and @sortPending
      console.error "STORAGE_INVARIANT pending-flag-set-at-drain-exit StorageSorter"
    return
