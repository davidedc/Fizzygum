# WorldInventory -- the in-band live-object accounting instrument (Arc A of the
# object-lifetime program; the plan and report vocabulary live in
# docs/archive/world-inventory-instruments-plan.md, the doctrine in
# docs/architecture/world-lifetime-and-inventory.md).
#
# Answers, at any moment and on BOTH engines: what is reachable, how much of it, and --
# for widgets -- WHICH ones, by identity. Its gate use (the harness's teardown audit,
# WorldTestSupport._auditWorldInventoryNoSettle) diffs a report against the
# first-teardown baseline: everything alive after a teardown must be (a) part of that
# baseline, (b) a declared page-lifetime store below, or (c) a bug.
#
# A plain collaborator (no widget), instantiated only by the harness audit seam; nothing
# in the product constructs it, and a build without the dev-tools part simply has no
# inventory.
#
# THE WALK IS READ-ONLY AND SIDE-EFFECT-FREE: it never calls methods on visited objects
# (the named accessor portholes and SourceVault.names() are the deliberate exceptions --
# all pure reads), skips accessor properties (a getter may compute), and reads widget
# identity passively (@instanceNumericID, assigned at construction). Typed arrays are
# LEAVES: Object.keys on one yields every INDEX as a key (the world canvas's pixel
# buffer alone is 1.69M keys, ~40x the whole rest of the walk), so they are counted by
# byteLength and never enumerated.
class WorldInventory

  baselineReport: undefined

  # ---- the page-lifetime stores -------------------------------------------------
  # Every store ALLOWED to differ from the first-teardown baseline, each with its
  # reason and the growth policy the diff enforces:
  #   "bounded"      -- may move freely; exceeding `cap` (when stated) is a violation.
  #                     A store that enforces its own cap (LRUCache evicts at capacity)
  #                     states no cap here -- the store itself is the enforcement.
  #   "monotonic-ok" -- free-running by design (lifetime counters, append-only vaults);
  #                     never gated.
  # Everything NOT declared must be STABLE across teardowns.
  @pageLifetimeStores: [
    {match: /^world\.cacheFor/, policy: "bounded", reason: "the text/paint LRUs (LRUCache evicts at its own capacity); entries legitimately accumulate across teardowns"}
    {match: /^world\.widgetsWithMaybeChanged\w*PaintBounds$/, policy: "bounded", reason: "per-cycle damage queues, drained by the next repaint; the teardown filters dead entries, so a live entry at the seam is legitimate pending damage -- and zombie-reporting THROUGH the queues stays live"}
    {match: /^statics\.Color\._cache$/, policy: "bounded", cap: 300, reason: "the Color intern LRU"}
    {match: /^hashCode\.stringHashCache$/, policy: "bounded", cap: 16384, reason: "the Object::hashCode memo; self-clears at cap"}
    {match: /^swCanvasText\.(atlasRequested|missingAtlases)$/, policy: "monotonic-ok", reason: "one entry per atlas id, requested/warned once per page"}
    {match: /^swCanvasText\.(coldGlyphWidgets|poisonedCacheKeys)$/, policy: "bounded", reason: "per-refresh transients: recorded at cold glyph draws, drained wholesale at the atlas-warm refresh (whose consumer skips destroyed/detached entries); the world teardown additionally drops destroyed entries at its seam"}
    {match: /\.instancesCounter$/, policy: "monotonic-ok", reason: "lifetime allocation counter, never reset by design"}
    {match: /\.lastBuiltInstanceNumericID$/, policy: "monotonic-ok", reason: "zeroed by fullDestroyChildren's sweep, re-advanced by teardown-time re-construction"}
    {match: /^statics\.WorldWdgt\.(frameCount|geometryVersion|structureVersion|visibilityVersion|immutableBackBufferGeneration)$/, policy: "monotonic-ok", reason: "world cycle/version/generation counters"}
    {match: /^sourceVault\.entries$/, policy: "monotonic-ok", reason: "grows only when a lazy part loads"}
    {match: /^dom\.headScripts$/, policy: "monotonic-ok", reason: "the test loader appends per-test script tags; spent tags are page-lifetime residue by current design"}
  ]
  # (harness-owned stores -- the runner's own state machine -- are declared by the harness
  # audit seam pushing onto this table: the instrument must not name harness classes)

  # Cache-shaped property names are DERIVED state, skipped exactly as the Duplicator
  # skips them when field-copying (Duplicator._cloneContentInto).
  @_derivedCacheName: (name) ->
    /^cached[A-Z]/.test(name) or /^check[A-Z].*Cache$/.test(name) or
      name is "childrenBoundsUpdatedAt" or /^_islandBufferSource/.test(name)

  # own-static names that are meta-machinery, not state (`instances` is reported
  # through its own instances.<Class> dimension)
  @_skippedStaticNames: new Set ["prototype", "__super__", "name", "length", "caller", "arguments", "instances"]

  # The gate's teeth. Bulk aggregates (objects.*, strings.*, canvases.*, containers.*,
  # typedArrays.*) are REPORT-ONLY diagnostics: every bounded-cache admission moves
  # them, so gating them would fire on legitimate churn (the ratchet's own first-cut
  # lesson: 1469 hits on a green suite).
  @_gatedKey: (key) ->
    /^(instances|statics|world|dom|swCanvasText|hashCode|sourceVault|classes)\./.test key

  @_policyFor: (key) ->
    for declaration in WorldInventory.pageLifetimeStores
      return declaration if declaration.match.test key
    undefined

  @_hintFor: (key) ->
    if /^instances\./.test key
      "live-instance count changed across resetWorld -- the ESCAPED/ZOMBIE lines name the individuals"
    else if /^statics\./.test key
      "a class-level store changed size -- reset it in the teardown, or declare it in WorldInventory.pageLifetimeStores with its reason"
    else if /^world\./.test key
      "a world container field changed size -- reset it in the teardown, or declare it in WorldInventory.pageLifetimeStores with its reason"
    else if /^dom\./.test key
      "the page DOM changed -- something appends elements per test"
    else
      "undeclared store changed -- declare it in WorldInventory.pageLifetimeStores with its reason, or fix the leak"

  # a Set/Map/Array/LRU-like store's element count, else undefined
  @_containerSize: (value) ->
    return undefined unless value? and typeof value is "object"
    return value.size if NativeValueKinds.isSet(value) or NativeValueKinds.isMap(value)
    return value.length if Array.isArray value
    # LRU-like (the world caches, Color._cache): self-capping stores expose both numbers
    return value.size if typeof value.size is "number" and typeof value.capacity is "number"
    undefined

  # ---- the walk -------------------------------------------------------------------
  # Returns {report, escapedWidgets, retainedZombies}:
  #   report          -- flat {dimensionKey: number}
  #   escapedWidgets  -- live widgets the containment walk cannot reach: ["Class#id", ...]
  #   retainedZombies -- destroyed widgets still held somewhere, each with the path
  #                      that names the retainer: [{id, path}, ...]
  takeInventory: ->
    report = {}
    escaped = []
    zombies = []
    visited = new Set
    provenance = new Map   # object -> {parent, key}, only to name a zombie's retainer
    stack = []
    transientsCache = new Map

    add = (key, n) -> report[key] = (report[key] ? 0) + n

    passiveId = (aWidget) ->
      (aWidget.constructor?.name ? "?") + "#" + (aWidget.instanceNumericID ? "?")

    pathOf = (value) ->
      parts = []
      cursor = value
      guard = 0
      while cursor? and guard++ < 300
        entry = provenance.get cursor
        if !entry?
          parts.unshift "<?>"
          break
        parts.unshift entry.key
        break unless entry.parent?
        cursor = entry.parent
      parts.join "."

    # the serializer's per-class transient declarations, merged up the chain -- those
    # fields are recomputed on restore, so retention through them is by design
    transientsOf = (ctor, ctorName) ->
      return undefined unless ctor?
      return transientsCache.get ctor if transientsCache.has ctor
      found = undefined
      if Serializer? and NativeValueKinds.isSet(ctor.instances) and window[ctorName] is ctor
        try
          found = Serializer.transientsForClass ctor
      transientsCache.set ctor, found
      found

    enqueue = (value, key, parent) ->
      return unless value?
      type = typeof value
      if type is "string"
        add "strings.count", 1
        add "strings.chars", value.length
        return
      return if type is "number" or type is "boolean" or type is "symbol" or type is "bigint"
      if type is "function"
        add "objects.Function", 1
        return
      return if visited.has value
      visited.add value
      if ArrayBuffer.isView(value) or value instanceof ArrayBuffer
        add "typedArrays.count", 1
        add "typedArrays.bytes", value.byteLength
        return
      provenance.set value, {parent: parent, key: key}
      stack.push value
      return

    processValue = (value) ->
      try
        if value is window
          add "objects.Window", 1
          return
        if value is document
          add "objects.Document", 1
          return
        isCanvasLike = false
        try
          isCanvasLike = typeof value.getContext is "function" and typeof value.toDataURL is "function"
        if isCanvasLike
          add "canvases.count", 1
          add "canvases.pixels", (value.width ? 0) * (value.height ? 0)
          return
        if window.Node? and value instanceof Node
          add "dom.nodes", 1
          return
        if NativeValueKinds.isMap value
          add "objects.Map", 1
          add "containers.mapEntries", value.size
          value.forEach (eachValue, eachKey) ->
            enqueue eachKey, "<mapKey>", value
            enqueue eachValue, "<mapValue>", value
          return
        if NativeValueKinds.isSet value
          add "objects.Set", 1
          add "containers.setEntries", value.size
          value.forEach (eachValue) -> enqueue eachValue, "<setEntry>", value
          return
        if Array.isArray value
          add "objects.Array", 1
          add "containers.arrayElements", value.length
          for eachElement, i in value
            enqueue eachElement, "[" + i + "]", value
          return
        ctor = undefined
        ctorName = "NoConstructor"
        try
          ctor = value.constructor
          ctorName = ctor.name if ctor?.name
        add "objects." + ctorName, 1
        if Widget? and value instanceof Widget and value.destroyed
          zombies.push {id: passiveId(value), path: pathOf(value)}
        transients = transientsOf ctor, ctorName
        for own name of value
          continue if WorldInventory._derivedCacheName name
          continue if transients?.has name
          descriptor = undefined
          try
            descriptor = Object.getOwnPropertyDescriptor value, name
          continue unless descriptor?
          continue if descriptor.get? or descriptor.set?
          enqueue descriptor.value, name, value
      catch error
        add "walker.errors", 1
      return

    # ---- roots ---------------------------------------------------------------------
    enqueue world, "world"
    enqueue window.menusHelper, "menusHelper"
    enqueue window.demoMenus, "demoMenus"

    # every class, via THE shared marker enumeration (boot's allClassFunctions --
    # the same one the teardown's id-zeroing and the serializer's counter
    # collection consume, so the three cannot disagree about what a class is)
    classFunctions = allClassFunctions()
    report["classes.count"] = classFunctions.length
    for ctor in classFunctions
      className = ctor.name
      instanceCount = ctor.instances.size
      report["instances." + className] = instanceCount if instanceCount > 0
      for staticName in Object.getOwnPropertyNames ctor
        continue if WorldInventory._skippedStaticNames.has staticName
        descriptor = undefined
        try
          descriptor = Object.getOwnPropertyDescriptor ctor, staticName
        continue unless descriptor? and !descriptor.get? and !descriptor.set?
        staticValue = descriptor.value
        sized = WorldInventory._containerSize staticValue
        if sized?
          report["statics." + className + "." + staticName] = sized
        else if typeof staticValue is "number"
          report["statics." + className + "." + staticName] = staticValue
        enqueue staticValue, className + "." + staticName, ctor

    # the world's own container fields (incl. the cacheFor* LRUs) get their own size
    # rows so a declared growth policy has a row to check
    if world?
      for own fieldName of world
        continue if WorldInventory._derivedCacheName fieldName
        descriptor = undefined
        try
          descriptor = Object.getOwnPropertyDescriptor world, fieldName
        continue unless descriptor? and !descriptor.get? and !descriptor.set?
        sized = WorldInventory._containerSize descriptor.value
        report["world." + fieldName] = sized if sized?

    # the module-state portholes (read-only accessors; absent builds are a no-op)
    textState = window.swCanvasTextStateForAudit?()
    if textState?
      report["swCanvasText.atlasRequested"] = Object.keys(textState.atlasRequested).length
      report["swCanvasText.missingAtlases"] = Object.keys(textState.missingAtlases).length
      # counted but NOT walked: the cold-glyph list transiently holds widgets a teardown may
      # just have destroyed (drained at the atlas-warm refresh, whose consumer skips them) --
      # walking it would zombie-report a race that is benign by design
      report["swCanvasText.coldGlyphWidgets"] = textState.coldGlyphWidgets.length
      report["swCanvasText.poisonedCacheKeys"] = textState.poisonedCacheKeys.length
    hashCache = window.stringHashCacheForAudit?()
    report["hashCode.stringHashCache"] = hashCache.size if hashCache?

    # counted, never walked: the vault holds every class's source text
    report["sourceVault.entries"] = SourceVault.names().length if SourceVault?
    report["dom.headScripts"] = document.head.querySelectorAll("script").length
    report["dom.bodyChildren"] = document.body.children.length

    processValue stack.pop() while stack.length > 0

    # ---- identity: the registry vs the containment walk ----------------------------
    # containment roots = the ONE liveness enumeration, plus the bin/shelf containers
    # themselves: their chrome is accounted-for citizenry even though residency in them
    # confers no liveness (see graphLivenessRoots).
    if world? and Widget?
      reached = new Set
      containmentStack = world.graphLivenessRoots()
      containmentStack.push world.binWdgt if world.binWdgt?
      containmentStack.push world.shelfWdgt if world.shelfWdgt?
      while containmentStack.length > 0
        cursor = containmentStack.pop()
        continue if !cursor? or reached.has cursor
        reached.add cursor
        if cursor.children?
          containmentStack.push eachChild for eachChild in cursor.children
      Widget.instances.forEach (eachInstance) ->
        if eachInstance.destroyed
          # still registered after destruction: unregisterThisInstance was skipped
          zombies.push {id: passiveId(eachInstance), path: "<registry>"}
        else if !reached.has eachInstance
          # when the property walk visited it, its provenance names the RETAINER --
          # the single most actionable fact about an escape
          escaped.push {
            id: passiveId(eachInstance)
            path: if provenance.has eachInstance then pathOf eachInstance else "<unreached-by-property-walk>"
          }

    {report: report, escapedWidgets: escaped, retainedZombies: zombies}

  # stores the current report as the baseline (the harness calls this at the FIRST teardown)
  snapshotBaseline: ->
    @baselineReport = @takeInventory().report
    return

  # diffs a fresh report against the baseline after the declared policies. Returns
  # {rows: [{key, baseline, now, hint}], escapedWidgets, retainedZombies} -- the
  # identity lists ride the fresh report and are absolute (expected empty ALWAYS),
  # not baseline-relative.
  diffAgainstBaseline: ->
    fresh = @takeInventory()
    rows = []
    if @baselineReport?
      keys = new Set
      keys.add key for own key of @baselineReport
      keys.add key for own key of fresh.report
      keys.forEach (key) =>
        return unless WorldInventory._gatedKey key
        baselineValue = @baselineReport[key] ? 0
        nowValue = fresh.report[key] ? 0
        return if nowValue is baselineValue
        declaration = WorldInventory._policyFor key
        if declaration?
          return if declaration.policy is "monotonic-ok"
          if declaration.policy is "bounded"
            return if !declaration.cap? or nowValue <= declaration.cap
        rows.push {key: key, baseline: baselineValue, now: nowValue, hint: WorldInventory._hintFor key}
    {rows: rows, escapedWidgets: fresh.escapedWidgets, retainedZombies: fresh.retainedZombies}
