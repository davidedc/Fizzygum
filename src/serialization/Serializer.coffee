# Serializer — turns a widget subtree (or a whole world) into a versioned, self-contained
# JSON envelope. See docs/architecture/serialization-duplication-reference.md for the format spec (§3),
# the reference policy (§4), the transients/derived/function protocol (§5), the per-type
# handlers (§6), the whole-world snapshot (§11), and how it shares per-class knowledge with
# — but no mutable state with — the DeepCopierMixin duplication walker (§1).
#
# It is side-effect-free and deterministic: it builds records DIRECTLY from the live graph
# (it creates no shells, so it advances no ID counters and leaks no Class.instances entry),
# so two serializations of the same unchanged widget are byte-identical.
class Serializer

  # envelope identity (see the reference doc §3)
  @FORMAT: "fizzygum"
  @FORMAT_VERSION: 1

  # The world slots that each hold (at most) one singleton-app window. A slot may be nil, or
  # hold an ORPHANED-but-revivable window (the app's launch() checks parent?). See
  # IconicDesktopSystemWindowedApp and the world snapshot (§11).
  @WORLD_APP_SLOTS: [
    "degreesConverterWindow"
    "howToSaveDocWindow"
    "sampleDashboardWindow"
    "sampleSlideWindow"
    "sampleDocWindow"
  ]

  # Merge the `@serializationTransients` declarations up a class's chain into one Set of
  # property names the serializer must SKIP. A subclass's declaration ADDS to (never
  # shadows) its ancestors' — mirroring how the codebase's other class-body conventions
  # accumulate up the hierarchy. Pure function of its class argument, so it works for any
  # serializable type (Widget subclasses and the DeepCopier-augmented data classes alike).
  @transientsForClass: (klass) ->
    merged = new Set
    return merged unless klass?
    ctor = klass
    # walk the CONSTRUCTOR chain (class -> superclass -> ... ); Object.getPrototypeOf on a
    # class returns its superclass constructor, and eventually Function/Object.prototype
    # (for which hasOwnProperty below is false), then null — which ends the loop.
    while ctor?
      if Object::hasOwnProperty.call ctor, "serializationTransients"
        declared = ctor.serializationTransients
        if declared?
          merged.add name for name in declared
      ctor = Object.getPrototypeOf ctor
    merged

  # Serialize a widget subtree to a JSON envelope string.
  # opts:
  #   prettyPrint       — indent the JSON for humans/diffs (default false)
  #   savedAt           — ISO timestamp to stamp in (default omitted, so output stays
  #                       byte-deterministic; the file-save path passes one)
  #   onExternalPointer — "throw" (default) | "nullify" | "record"  (reference doc §4)
  #   kind              — envelope kind (default "widget")
  @serializeWidget: (root, opts = {}) ->
    envelope = @buildEnvelope root, opts
    if opts.prettyPrint then JSON.stringify(envelope, null, 2) else JSON.stringify(envelope)

  # Build the plain-object widget envelope (no stringify) — reused by callers that want the
  # object (e.g. the file-save path re-stringifies with a savedAt stamp).
  @buildEnvelope: (root, opts = {}) ->
    onExternal = opts.onExternalPointer or "throw"
    rootDescription = if root.uniqueIDString? then root.uniqueIDString() else root.constructor.name
    # the set of widgets that count as "in-structure" (O(1) membership); includes root.
    widgetSet = new Set root.allChildrenBottomToTop()
    table = @_buildObjectTable widgetSet, onExternal, rootDescription, root
    rootIndex = table.encodeToSlot root, rootDescription

    envelope =
      format: Serializer.FORMAT
      formatVersion: Serializer.FORMAT_VERSION
      kind: opts.kind or "widget"
      root: rootIndex
      objects: table.objects
    envelope.savedAt = opts.savedAt if opts.savedAt?
    envelope.build = window.FIZZYGUM_BUILD if window.FIZZYGUM_BUILD?
    envelope

  # --- whole-world snapshot (kind:"world"); see docs §11 and the plan §4.9 -----------------
  #
  # The world is DELIBERATELY NOT a table record. Serializing the world widget's own props
  # would drag in ~50 transient fields (the render/measure canvases + contexts, seven
  # LRUCaches, the input-event queue, the hand, the caret, the broken-rect trackers, and a
  # dozen event-listener CLOSURES) — the walker would crash on the first one (a CanvasPattern
  # on @appearance, exactly defect D8). Instead the genuine world state is captured in an
  # explicit, greppable `world` envelope section, and only the SNAPSHOT ROOTS — the desktop
  # children, the off-tree bin, the non-nil app-slot windows, the templates window — are
  # walked into the object table. A snapshot restores a SETTLED world (§1): the hand-held
  # widget and the caret are dropped by construction (they live outside the snapshot roots);
  # open UNPINNED menus/pop-ups ARE world children, so the filter below drops them explicitly.
  @serializeWorld: (theWorld, opts = {}) ->
    # EPHEMERAL overlays (live highlight / pinout / drag-affordance widgets) are reconciler-owned
    # transient world children — never part of the persisted desktop. TRANSIENT (unpinned)
    # POP-UPS are mid-gesture UI: the very menu whose item triggers "save world snapshot…" is
    # still attached (and already marked for closure) while the save runs, so without this
    # filter it gets baked into the file and restores as a zombie. Pinned pop-ups are desktop
    # furniture and stay. Exclude both up front so they ride NEITHER the snapshot-roots walk NOR
    # the explicit `section.children` list below (with onExternal:"capture" a section.children
    # ref would otherwise pull an excluded child back into the object table). The reconciler
    # recreates ephemerals from live state after a restore.
    snapshotChildren = (child for child in (theWorld.children or []) when not (child.isEphemeral?() or child.isTransientPopUp?()))
    # snapshot roots (deduped by the widgetSet Set below); an app-slot window may also be a
    # desktop child, an orphan in the bin, or off-tree — all are captured here.
    roots = []
    roots.push child for child in snapshotChildren
    roots.push theWorld.binWdgt if theWorld.binWdgt?
    roots.push theWorld.shelfWdgt if theWorld.shelfWdgt?
    for slot in Serializer.WORLD_APP_SLOTS
      slotWindow = theWorld[slot]
      roots.push slotWindow if slotWindow? and not slotWindow.destroyed
    roots.push theWorld.simpleEditorTemplates if theWorld.simpleEditorTemplates? and not theWorld.simpleEditorTemplates.destroyed
    widgetSet = new Set
    for aRoot in roots when aRoot?
      widgetSet.add w for w in aRoot.allChildrenBottomToTop()

    # a world snapshot CAPTURES everything reachable: a cross-root pointer resolves as {"$r"};
    # an off-tree widget reached only via a property (e.g. a folder window's `defaultContents`
    # placeholder) is pulled into the table as its own record, so "everything is in-structure"
    # (§4.9) holds and no world state is silently dropped. (A stray {"$ext"} same-world token
    # is still resolvable by iid on restore, but "capture" leaves none for a settled world.)
    onExternal = opts.onExternalPointer or "capture"
    table = @_buildObjectTable widgetSet, onExternal, "the world", nil
    ref = table.refFor

    # --- the explicit world section (plain, greppable; outside the object table) ---
    section = {}
    section.children = (ref(c, "the world → .children") for c in snapshotChildren)
    section.desktopColor = ref(theWorld.color, "the world → .color") if theWorld.color?
    section.alpha = theWorld.alpha if theWorld.alpha?
    section.isDevMode = theWorld.isDevMode
    section.wallpaperPatternName = theWorld.wallpaper?.patternName
    section.numberOfIconsOnDesktop = theWorld.numberOfIconsOnDesktop if theWorld.numberOfIconsOnDesktop?
    # info-doc "already created" flags: plain own booleans set on the world instance.
    infoDocFlags = {}
    for own name of theWorld when name.indexOf("infoDoc") is 0
      infoDocFlags[name] = theWorld[name]
    section.infoDocFlags = infoDocFlags
    # untitled-naming counters (a plain delegated collaborator — capture its counters).
    uns = theWorld.untitledNamingService
    section.untitledNamingCounters =
      howManyUntitledShortcuts: uns?.howManyUntitledShortcuts or 0
      howManyUntitledFoldersShortcuts: uns?.howManyUntitledFoldersShortcuts or 0
    # app-slot windows + the templates window (may be orphaned-but-revivable).
    appSlots = {}
    for slot in Serializer.WORLD_APP_SLOTS
      slotWindow = theWorld[slot]
      appSlots[slot] = ref(slotWindow, "the world → ." + slot) if slotWindow? and not slotWindow.destroyed
    section.appSlots = appSlots
    if theWorld.simpleEditorTemplates? and not theWorld.simpleEditorTemplates.destroyed
      section.simpleEditorTemplates = ref theWorld.simpleEditorTemplates, "the world → .simpleEditorTemplates"
    section.bin = ref(theWorld.binWdgt, "the world → .binWdgt") if theWorld.binWdgt?
    section.shelf = ref(theWorld.shelfWdgt, "the world → .shelfWdgt") if theWorld.shelfWdgt?
    # preferences: a FORCED data record. refFor would give {"$wk":"preferences"} (the
    # symbolic link that a widget-in-tree uses); here we need the actual values, restored
    # onto the static bag on load.
    if WorldWdgt.preferencesAndSettings?
      section.preferences = {$r: table.encodeToSlot WorldWdgt.preferencesAndSettings, "the world → .preferences"}
    # per-class ID counters (restored into the freshly-zeroed ID space — §4.4/§4.9).
    section.idCounters = Serializer.collectIdCounters()
    # source edits (Phase 6) — embedded verbatim if the registry exists.
    section.sourceEdits = theWorld.sourceEditsRegistry.serializableRecords() if theWorld.sourceEditsRegistry?.serializableRecords?

    envelope =
      format: Serializer.FORMAT
      formatVersion: Serializer.FORMAT_VERSION
      kind: "world"
      objects: table.objects
      world: section
    envelope.savedAt = opts.savedAt if opts.savedAt?
    envelope.build = window.FIZZYGUM_BUILD if window.FIZZYGUM_BUILD?
    if opts.prettyPrint then JSON.stringify(envelope, null, 2) else JSON.stringify(envelope)

  # The per-class ID counters to restore. Mirrors WorldWdgt.fullDestroyChildren's class
  # sweep (any global whose name ends in Wdgt/Widget), skipping WorldWdgt (the live world
  # keeps its own id — fullDestroyChildren never zeroes it) and any counter still at 0 (the
  # freshly-reset ID space is already 0 there, so recording it would be redundant).
  @collectIdCounters: ->
    counters = {}
    for name in Object.keys(window) when (name.endsWith("Wdgt") or name.endsWith("Widget")) and name isnt "WorldWdgt"
      klass = window[name]
      if klass? and (typeof klass.lastBuiltInstanceNumericID is "number") and klass.lastBuiltInstanceNumericID > 0
        counters[name] = klass.lastBuiltInstanceNumericID
    counters

  # --- the shared object-table encoder -----------------------------------------------------
  # Builds `objects` (the versioned record table) for a set of in-structure widgets, and
  # returns the encoding primitives used by BOTH serializeWidget and serializeWorld so the
  # two share one walker and cannot drift. `root` is the single detach-root (its `parent`
  # serializes as null) or nil (world snapshot: top children keep parent = {"$wk":"world"}).
  @_buildObjectTable: (widgetSet, onExternal, rootDescription, root) ->
    objects = []
    slotOf = new Map          # live object -> table index (identity; cycle/sharing safe)

    describe = (v) ->
      return "nil" unless v?
      if v instanceof Widget then return v.uniqueIDString() + " (a " + v.constructor.name + ")"
      if v.constructor?.name then return "a " + v.constructor.name
      typeof v

    fail = (message, path, offender, remediation) ->
      throw new SerializationError message,
        rootDescription: rootDescription
        path: path
        offender: offender
        remediation: remediation

    # --- encode a VALUE appearing at `path` into its reference form. owner/propName give
    #     the source-lookup context for a function-valued property. ---
    refFor = (value, path, owner, propName) ->
      return null unless value?
      t = typeof value
      return value if t is "string" or t is "number" or t is "boolean"
      return encodeFunction(value, owner, propName, path) if t is "function"
      # objects:
      if value instanceof Widget
        return {$r: encodeToSlot(value, path)} if widgetSet.has value
        wk = WellKnownObjects.keyFor value
        return {$wk: wk} if wk?
        # external, non-well-known widget — the canonical rich-error case
        switch onExternal
          when "nullify" then return null
          when "record"  then return {$ext: value.uniqueIDString()}
          # "capture": pull the off-tree widget into the table as a full record. Used by the
          # world snapshot, where EVERYTHING reachable is genuine world state (e.g. a folder
          # window's off-tree `defaultContents` placeholder) and "everything is in-structure"
          # is the intent (§4.9). Self-policing: if it reaches a truly unserializable value it
          # throws the same rich error below.
          when "capture" then return {$r: encodeToSlot(value, path)}
          else fail (value.uniqueIDString() + " is outside the serialized structure and is not a well-known object"),
                    path, describe(value),
                    "Serialize a common container that holds both widgets; or clear the connection; or register the target as a well-known object."
      # non-widget object: a world singleton re-bound by key, else a real table slot
      wk = WellKnownObjects.keyFor value
      return {$wk: wk} if wk?
      {$r: encodeToSlot(value, path)}

    encodeFunction = (fn, owner, propName, path) ->
      # a user-injected method carries its source in a sibling `<name>_source` string
      if owner? and propName? and owner[propName + "_source"]?
        return {$src: owner[propName + "_source"]}
      fail ("the function-valued property ." + propName + " has no editable source and is not a serialization transient"),
           path, "a function (" + propName + ")",
           "Declare " + propName + " in the owning class's @serializationTransients (it will be recomputed on restore), or set its source via injectProperty."

    # reserve a slot for `obj`, then populate its record; returns the slot index.
    encodeToSlot = (obj, path) ->
      existing = slotOf.get obj
      return existing if existing?
      idx = objects.length
      record = {}
      objects.push record        # reserve BEFORE populating so self-references resolve
      slotOf.set obj, idx
      populateRecord record, obj, path
      idx

    encodeOwnProps = (obj, path, isRoot) ->
      transients = Serializer.transientsForClass obj.constructor
      props = {}
      for own name of obj
        continue if name is "instanceNumericID" or name is "className"
        continue if transients.has name
        if isRoot and name is "parent"
          # the restored root is DETACHED; the caller decides where to attach it.
          props.parent = null
          continue
        value = obj[name]
        # derived value (a canvas 2D context): skip; the deserializer rebuilds it, exactly
        # as the duplication path does.
        continue if value? and typeof value is "object" and value.rebuildDerivedValue?
        props[name] = refFor value, (path + " → ." + name), obj, name
      props

    membershipsFor = (widget) ->
      m = []
      return m unless world?
      m.push "stepping"         if world.steppingWdgts?.has widget
      m.push "keyboardReceiver" if world.keyboardEventsReceivers?.has widget
      m.push "referenceTracker" if world.widgetsReferencingOtherWidgets?.has widget
      # a serialized pop-up is a PINNED one (transient pop-ups never reach a world snapshot);
      # its openPopUps membership must ride along or the restored world loses track of it
      # (mostRecentlyCreatedPopUp / the lazy orphan pruning consult this set).
      m.push "openPopUp"        if world.openPopUps?.has widget
      m

    populateRecord = (record, obj, path) ->
      # --- native / special types: $-tagged records (user class names can't collide) ---
      if Array.isArray obj
        record.class = "$Array"
        record.items = (refFor(obj[i], path + "[" + i + "]") for i in [0...obj.length])
        return
      if obj instanceof Date
        record.class = "$Date"
        record.ms = obj.getTime()
        return
      if obj instanceof HTMLImageElement
        record.class = "$Image"
        record.src = obj.src
        return
      if (typeof obj.getContext is "function") and (typeof obj.toDataURL is "function")
        # HTMLCanvasElement or SWCanvasElement — duck-typed so it catches BOTH backends
        # (SWCanvasElement has no stable global to instanceof against).
        record.class = "$Canvas"
        record.w = obj.width
        record.h = obj.height
        record.data = obj.toDataURL "image/png"
        return
      if (typeof HTMLVideoElement isnt "undefined") and obj instanceof HTMLVideoElement
        record.class = "$Video"
        record.src = obj.src
        record.autoplay = obj.autoplay
        record.currentTime = obj.currentTime
        return
      if obj instanceof Map
        record.class = "$Map"
        entries = []
        obj.forEach (v, k) -> entries.push [refFor(k, path + " (Map key)"), refFor(v, path + " (Map value)")]
        record.entries = entries
        return
      if obj instanceof Set
        record.class = "$Set"
        items = []
        obj.forEach (x) -> items.push refFor(x, path + " (Set item)")
        record.items = items
        return
      if obj instanceof Color
        # restored through Color.create so immutable-color dedupe is preserved
        record.class = "Color"
        record.rgba = [obj._r, obj._g, obj._b, obj._a]
        return
      # --- a plain object literal ---
      if (not obj.constructor?) or obj.constructor is Object
        record.class = "$Object"
        record.props = encodeOwnProps obj, path, false
        return
      # --- a registered Fizzygum class instance (a Widget or a data class) ---
      className = obj.constructor.name
      if window[className] isnt obj.constructor
        fail ("a value of an unrecognized type (" + className + ") cannot be serialized"),
             path, describe(obj),
             "Declare the property holding it in @serializationTransients, or add a per-type handler for it."
      record.class = className
      record.iid = obj.instanceNumericID if obj.instanceNumericID?
      if obj instanceof Widget
        m = membershipsFor obj
        record.memberships = m if m.length
      record.props = encodeOwnProps obj, path, (root? and obj is root)
      return

    {objects: objects, refFor: refFor, encodeToSlot: encodeToSlot}
