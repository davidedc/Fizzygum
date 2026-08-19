# The world's storage sorter -- the eager keeper of the STANDING STORAGE
# INVARIANT: everything on the shelf (world.shelfWdgt) is REACHABLE, everything
# in the bin (world.binWdgt) is LOST, at all times.
# (docs/archive/bin-shelf-eager-sorting-plan.md -- the owner-directed successor
# to the bin's lazy sort-at-open view.)
#
# HOW: reachability changes only at a small set of events, all funnelled
# through chokepoints (the reference tracker's three mutation sites, wire
# add / un-wire / wire-holder death — liveness follows wires too, graph-edges
# plan §4.3 — close filing, arrivals into / departures from an open bin
# window, the app-slot writes, snapshot restore). Each chokepoint calls the mark-only
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
    # early-return-sanctioned: this runs from doOneCycle on EVERY cycle, and staying dark-cheap when
    # nothing is pending is the guard's entire job. Pushed into the core it would open a settle every
    # cycle just to discover there is nothing to drain.
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
      for w in world.binWdgt.viewport.contents.children.slice()
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

  # The reachability classifier -- the STANDING STORAGE INVARIANT computed over
  # the full widget graph: containment ∪ flow (wires) ∪ reference, enumerated
  # per-widget by the graphEdgesOut protocol (graph-edges plan §4.3; it
  # supersedes the tracker-only classifier the bin's old doGC became). It marks
  # everything reachable with a fresh gc session id; placement is then read
  # per-resident via isInStorageButReachable. Internal to the drain: placement
  # queries outside it use the containers' holds().
  #
  # WHICH edge kinds confer: containment is the walk itself; a declared wire
  # (flow) and a reference confer -- the serialized truth (decision G5 there);
  # a COMMAND edge (a button's @target) is enumerated but confers NOTHING --
  # button chrome is ephemeral (G8's ruling), and an open menu on a bin
  # resident must not shelf it. A firesOnAnyChange subscription lives only in
  # the engine index and is never enumerated at all.
  _runClassifier: ->
    world.incrementalGcSessionId++
    newGcSessionId = world.incrementalGcSessionId

    # phase A -- the attached forest: every liveness edge held anywhere in the
    # world tree or on the hand seeds reachability at its target. An orphan
    # subtree is never walked, so its edges confer nothing -- the old
    # registry-scan's explicit orphan discard, now structural.
    @_seedFromSubtreeEdges world, newGcSessionId
    @_seedFromSubtreeEdges world.hand, newGcSessionId if world.hand?

    # phase B -- system furniture parked in storage is reachable through WORLD
    # FIELDS: the app singletons (world[slot], revived by their launchers) and
    # the editor templates window (revived by TemplatesButtonWdgt). Marked
    # before the fixpoint so edges held INSIDE them relay like any other
    # reachable resident's.
    for slot in Serializer.WORLD_APP_SLOTS
      world[slot]?.markItAndItsParentsAsReachable newGcSessionId
    world.simpleEditorTemplates?.markItAndItsParentsAsReachable newGcSessionId

    # phase C fixpoint: a storage resident whose chain became reachable relays
    # its subtree's edges to ITS targets; chains resolve progressively until no
    # new resident activates.
    relayedResidents = new Set()
    newReachableResidentsUncovered = true
    while newReachableResidentsUncovered
      newReachableResidentsUncovered = false
      for eachResident in @_storageResidents()
        continue if relayedResidents.has eachResident
        continue if eachResident.destroyed
        if eachResident.isInStorageButReachable newGcSessionId
          relayedResidents.add eachResident
          @_seedFromSubtreeEdges eachResident, newGcSessionId
          newReachableResidentsUncovered = true

    return newGcSessionId

  # Follow every LIVENESS edge (flow + reference) held anywhere in this
  # subtree, seeding reachability at each target (markItAndItsParentsAsReachable
  # -- marks UP the chain, stopping at the storage boundary, so an edge INTO a
  # nested widget shelves the whole containing resident). Never descends into
  # the storage containers themselves: their residents confer only once the
  # fixpoint proves them reachable -- the same boundary the marking climb holds
  # from the other side, and what keeps a LOST bin resident's own edges from
  # shelving its targets while the open bin window has the container on-tree.
  # A destroyed or unset target confers nothing (a dangling referencedWidget is
  # the referent-death model until the reference plan's trash arc severs
  # inbound references).
  _seedFromSubtreeEdges: (subtreeRoot, newGcSessionId) ->
    return if subtreeRoot == world.binWdgt or subtreeRoot == world.shelfWdgt
    for edge in subtreeRoot.graphEdgesOut()
      continue unless edge.kind == 'flow' or edge.kind == 'reference'
      continue unless edge.to? and !edge.to.destroyed
      edge.to.markItAndItsParentsAsReachable newGcSessionId
    for child in subtreeRoot.children
      @_seedFromSubtreeEdges child, newGcSessionId
    return

  # The top-level storage residents of both containers -- what the fixpoint
  # iterates and the drain re-files.
  _storageResidents: ->
    residents = []
    binContents = world.binWdgt?.viewport?.contents
    residents.push binContents.children... if binContents?
    residents.push world.shelfWdgt.children... if world.shelfWdgt?
    residents

  # ---- Tier A: the always-on storage-invariant guard ----
  # Runs at drain exit (with the drain's fresh session id) and at the
  # test-teardown seam (resetWorld's end, no session id -> structural checks
  # only). O(residents + tracker). Each violation console.errors ONE greppable
  # STORAGE_INVARIANT token line; both headless runners gate on the token, so
  # every suite leg enforces the invariant for free (the NON_INTEGER_GEOMETRY
  # precedent). Quiet during teardown BY CONSTRUCTION (mirroring the bounds
  # guard): it is only ever called from the drain station -- which never runs
  # mid-teardown -- and from resetWorld's end, after the world is consistent.
  _auditStorageNoSettle: (justComputedGcSessionId) ->
    binContents = world.binWdgt?.viewport?.contents
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
