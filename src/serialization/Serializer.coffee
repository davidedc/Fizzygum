# Serializer — turns a widget subtree (or a whole world) into a versioned, self-contained
# JSON envelope. See docs/architecture/serialization-duplication-reference.md for the format spec (§3),
# the reference policy (§4), the transients/derived/function protocol (§5), the per-type
# handlers (§6), the whole-world snapshot (§11), and how it shares per-class knowledge with
# — but no mutable state with — the Duplicator duplication walker (src/duplication/, §1);
# the native-type detection the two share lives in NativeValueKinds.
#
# It is side-effect-free and deterministic: it builds records DIRECTLY from the live graph
# (it creates no shells, so it advances no ID counters and leaks no Class.instances entry),
# so two serializations of the same unchanged widget are byte-identical.
class Serializer

  # envelope identity (see the reference doc §3)
  @FORMAT: "fizzygum"
  @FORMAT_VERSION: 1

  # THE WORLD SETS A RECORD'S `memberships` NAME: marker -> the world field holding that Set. ONE
  # table, read by both directions -- the save writes a marker for each set holding the widget, and
  # the restore re-adds the shell to the set its marker names (Deserializer, pass 4(b)) -- so a set
  # cannot be saved and then dropped on load. A marker outside it makes the file unrestorable, said
  # up front (Deserializer._envelopeShapeProblem) rather than dropped in silence.
  # ⚠ Re-registration hands the shell to machinery that reads its fields, so every marker carries a
  # verdict against the transients a restore drops: STEPPING's loop re-seeds the dropped lastTime
  # itself (a restored throttled stepper NaN-stalls otherwise -- see _runChildrensStepFunction), and a
  # viewport saved mid-gesture, whose dropped scroll step was the one thing it stepped for, leaves the
  # set in its own hook, pass 4(c) (ViewportWdgt._afterDeserialization); the
  # KEYBOARD dispatch reads only the prototype method, and the one receiver with transient state (the
  # spreadsheet) rebuilds it in the per-class hook, pass 4(c), before any event can arrive; the
  # REFERENCE TRACKER's consumers read destroyed + referencedWidget, both serialized (ShortcutWdgt
  # declares no transients); the OPENPOPUPS consumers read isOrphan()/instanceNumericID (re-derived /
  # serialized), and the dropped closure mark restores false -- the correct state for a pinned pop-up
  # (a serialized pop-up is a PINNED one: transient pop-ups never reach a world snapshot, and the
  # membership must ride along or the restored world loses track of it -- mostRecentlyCreatedPopUp and
  # the lazy orphan pruning consult the set). A NEW marker must state its verdict here: what does the
  # re-registered machinery read, and is any of it transient-dropped?
  @WORLD_SET_MEMBERSHIPS:
    stepping:         "steppingWdgts"
    keyboardReceiver: "keyboardEventsReceivers"
    referenceTracker: "widgetsReferencingOtherWidgets"
    openPopUp:        "openPopUps"

  # The `@serializationTransients` declarations merged up a class's chain, as one Set of
  # property names the serializer must SKIP. A subclass's declaration ADDS to (never shadows)
  # its ancestors' -- the merge is boot's classStaticListMergedUpTheChain
  # (src/boot/globalFunctions.coffee), the one class-chain merge every class-level list
  # declaration shares, which also says why the walk follows `__super__` and reads each class by
  # hasOwnProperty. Pure function of its class argument, so it works for any serializable type
  # (Widget subclasses and the plain non-Widget data classes alike).
  @transientsForClass: (klass) ->
    new Set classStaticListMergedUpTheChain klass, "serializationTransients"

  # Can an instance of `klass` carry a {"$src"}, a method injected into it? Only a class whose
  # instances answer injectProperty (a widget's): the load compiles a {"$src"} with that very method.
  # The one test of it, asked by the save (encodeFunction), by the load's refusal
  # (Deserializer._functionSourceOnANonWidget), so a save cannot write one the load refuses, and by a copy,
  # which compiles afresh, on the same widgets, every injected method it holds (Duplicator._compileInjectedMethods).
  @classTakesInjectedMethods: (klass) ->
    klass?.prototype?.injectProperty?

  # The numbers JSON.stringify does not write as themselves -- it writes NaN and ±Infinity as null and
  # -0 as 0 -- each with the text a {"$num"} carries it by. The one list of them: numberRef writes by
  # it, Deserializer.numberFrom reads by it, and a text outside it is refused up front
  # (Deserializer._envelopeShapeProblem).
  @NUMBERS_JSON_CANNOT_WRITE: [["NaN", NaN], ["Infinity", Infinity], ["-Infinity", -Infinity], ["-0", -0]]

  # A NUMBER as a file carries it: itself, when JSON writes it as itself; otherwise its text in a
  # {"$num"}, so a save drops nothing in silence. Every number a record holds that can be any number
  # is written through here: a reference, a $Date's time, a Color's components. (The integers the
  # format keeps -- an iid, a $Canvas's size and pixel ratio -- are integers by construction.)
  # `n` is a number: every caller hands one (refFor asks typeof, a $Date's time is read through Date's own
  # getTime, and the Color branch refuses a colour whose component is not, _colorComponentsProblem).
  @numberRef: (n) ->
    for [text, value] in Serializer.NUMBERS_JSON_CANNOT_WRITE
      return {$num: text} if Object.is n, value
    n

  # What is wrong with a Color's components, as a clause, or undefined: each a number, as Color makes it
  # (Color._channel, Color._alpha). One that is not was written into the colour after it was made -- a
  # value class written after construction, by a run or by an edit of Color itself -- and the save would
  # write a file the load refuses. The clause names the component and the KIND of what it holds, never
  # the value (a cyclic object or a BigInt has no JSON).
  @_colorComponentsProblem: (color) ->
    for value, i in [color._r, color._g, color._b, color._a] when typeof value isnt "number"
      return "its " + "rgba".charAt(i) + " component is " + (if value? then typeof value else "absent") + ", not a number"
    undefined

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
    rootDescription = SerializationError.pathRoot root
    # the set of widgets that count as "in-structure" (O(1) membership); includes root — plus,
    # through the arrow contract's copy closure (Widget.allWidgetsInStructureForCopy, the ONE
    # closure fullCopy also consumes, so copy and save cannot disagree — reference-widgets plan
    # §4.4), the referent FIGURES of content-presenting icons: they ride the envelope as
    # embedded DETACHED second roots (parent cleared like the envelope root's; their restore
    # homing to the shelf is ShortcutWdgt._afterDeserialization). An ARROW'D shortcut's
    # referent stays external, so saving one still errors — Fizzygum has no cross-file
    # identity that would make a dangling-alias restore meaningful (BACKLOG follow-up).
    if root.allWidgetsInStructureForCopy?
      {structure, referentFigures} = root.allWidgetsInStructureForCopy()
    else
      structure = root.allChildrenBottomToTop()
      referentFigures = []
    # the one ill-posed shape: an icon saved from INSIDE the very container it presents — the
    # file would have to embed its own root's ancestor as a detached sibling, which no envelope
    # can restore coherently. (Duplication handles this same shape fine — a copy is one live
    # structure, not two envelope roots.)
    for figure in referentFigures
      if figure is root or figure.isAncestorOf root
        throw new SerializationError "this icon presents the contents of a container it sits inside",
          rootDescription: rootDescription
          path: rootDescription
          offender: figure.uniqueIDString() + " (a " + figure.constructor.name + ")"
          remediation: "Save the enclosing container itself instead of this icon."
    widgetSet = new Set structure
    detachRoots = new Set referentFigures
    detachRoots.add root
    table = @_buildObjectTable widgetSet, onExternal, rootDescription, detachRoots
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
  # would drag in dozens of transient fields (the render/measure canvases + contexts, seven
  # LRUCaches, the input-event queue, the hand, the caret, the damage-rect trackers, and the
  # browser-input bridge with its dozen event-listener CLOSURES) — the walker would crash on the
  # first one (a CanvasPattern on @appearance, exactly defect D8). Instead the genuine world state
  # is captured in an explicit, greppable `world` envelope section, and only the SNAPSHOT ROOTS —
  # the desktop children, the off-tree bin and shelf, the registered app windows (world.appWindows)
  # — are walked into the object table. A snapshot restores a SETTLED world (§1): the hand-held
  # widget and the caret are dropped by construction (they live outside the snapshot roots);
  # open UNPINNED menus/pop-ups ARE world children, so the filter below drops them explicitly.
  @serializeWorld: (theWorld, opts = {}) ->
    # EPHEMERAL overlays (live highlight / pinout / drag-affordance widgets) are reconciler-owned
    # transient world children — never part of the persisted desktop. TRANSIENT (unpinned)
    # POP-UPS are mid-gesture UI: the very menu whose item triggers "Save world snapshot…" is
    # still attached (and already marked for closure) while the save runs, so without this
    # filter it gets baked into the file and restores as a zombie. Pinned pop-ups are desktop
    # furniture and stay. Exclude both up front so they ride NEITHER the snapshot-roots walk NOR
    # the explicit `section.children` list below (with onExternal:"capture" a section.children
    # ref would otherwise pull an excluded child back into the object table). The reconciler
    # recreates ephemerals from live state after a restore.
    snapshotChildren = (child for child in (theWorld.children or []) when not (child.isEphemeral?() or child.isTransientPopUp?()))
    # snapshot roots (deduped by the widgetSet Set below); an app window may also be a desktop
    # child, an orphan in the bin or on the shelf, or off-tree — all are captured here.
    liveAppWindows = ([appName, appWindow] for [appName, appWindow] from theWorld.appWindows when not appWindow.destroyed)
    roots = []
    roots.push child for child in snapshotChildren
    roots.push theWorld.binWdgt if theWorld.binWdgt?
    roots.push theWorld.shelfWdgt if theWorld.shelfWdgt?
    roots.push appWindow for [appName, appWindow] in liveAppWindows
    widgetSet = new Set
    for aRoot in roots when aRoot?
      widgetSet.add w for w in aRoot.allChildrenBottomToTop()

    # a world snapshot CAPTURES everything reachable: a cross-root pointer resolves as {"$r"};
    # an off-tree widget reached only via a property (e.g. the widget a demo PointerWdgt stands in
    # for, its `target`) is pulled into the table as its own record, so "everything is in-structure"
    # (§4.9) holds and no world state is silently dropped. (A stray {"$ext"} same-world token
    # is still resolvable by iid on restore, but "capture" leaves none for a settled world.)
    onExternal = opts.onExternalPointer or "capture"
    table = @_buildObjectTable widgetSet, onExternal, SerializationError.WORLD_ROOT, undefined
    ref = table.refFor

    # --- the explicit world section (plain, greppable; outside the object table) ---
    section = {}
    # each slot's path in the refusals' one vocabulary, from the world snapshot's root
    worldPath = (name) -> SerializationError.WORLD_ROOT + SerializationError.intoProperty name
    section.children = (ref(c, worldPath("children") + SerializationError.intoItem(i)) for c, i in snapshotChildren)
    section.desktopColor = ref(theWorld.color, worldPath "color") if theWorld.color?
    section.alpha = theWorld.alpha if theWorld.alpha?
    section.isDevMode = theWorld.isDevMode
    section.wallpaperPatternName = theWorld.wallpaper?.patternName
    # info-doc "already created" flags: plain own booleans set on the world instance.
    infoDocFlags = {}
    for own name of theWorld when WorldWdgt.isInfoDocFlagName name
      infoDocFlags[name] = theWorld[name]
    section.infoDocFlags = infoDocFlags
    # untitled-naming counters (a plain delegated collaborator — capture its counters).
    uns = theWorld.untitledNamingService
    section.untitledNamingCounters =
      howManyUntitledShortcuts: uns?.howManyUntitledShortcuts or 0
      howManyUntitledFoldersShortcuts: uns?.howManyUntitledFoldersShortcuts or 0
    # the people at this world (User) — plain delegated collaborators like the naming service, so
    # their state is captured by NAME here rather than through the object table. The armed drawing
    # tool is a KEY, so it captures as itself; a restore applies it to the live users positionally.
    section.users = ({armedDrawingTool: eachUser.armedDrawingTool} for eachUser in (theWorld.users or []))
    # the app windows, by app class name (each may be orphaned-but-revivable).
    section.appWindows = {}
    for [appName, appWindow] in liveAppWindows
      section.appWindows[appName] = ref appWindow, worldPath("appWindows") + SerializationError.intoKey(appName)
    section.bin = ref(theWorld.binWdgt, worldPath "binWdgt") if theWorld.binWdgt?
    section.shelf = ref(theWorld.shelfWdgt, worldPath "shelfWdgt") if theWorld.shelfWdgt?
    # preferences: a FORCED data record. refFor would give {"$wk":"preferences"} (the
    # symbolic link that a widget-in-tree uses); here we need the actual values, restored
    # onto the static bag on load.
    if WorldWdgt.preferencesAndSettings?
      section.preferences = {$r: table.encodeToSlot WorldWdgt.preferencesAndSettings, worldPath "preferences"}
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

  # The per-class ID counters to restore. The SAME enumeration as
  # WorldWdgt.fullDestroyChildren's id-zeroing (allClassFunctions — the `instances`-Set
  # marker, never a name-suffix scan, which silently skipped any class whose name lacks
  # the Wdgt/Widget suffix: a restored FrameContentsPlaceholderText's id space collided).
  # Skips any counter still at 0 (the freshly-reset ID space is already 0 there, so recording it
  # would be redundant) — and skips WorldWdgt, which holds on BOTH ends of a snapshot: a snapshot is
  # loaded INTO the live world, which keeps the id it was issued, and fullDestroyChildren's id sweep
  # skips WorldWdgt for exactly that reason, so there is neither a counter worth recording nor
  # anything that would read one back. A world only ever gives its id up when it is REPLACED by a
  # successor, which is WorldWdgt._dissolveWorldNoSettle's business and involves no snapshot.
  @collectIdCounters: ->
    counters = {}
    for klass in allClassFunctions() when klass isnt WorldWdgt
      if (typeof klass.lastBuiltInstanceNumericID is "number") and klass.lastBuiltInstanceNumericID > 0
        counters[klass.name] = klass.lastBuiltInstanceNumericID
    counters

  # --- the shared object-table encoder -----------------------------------------------------
  # Builds `objects` (the versioned record table) for a set of in-structure widgets, and
  # returns the encoding primitives used by BOTH serializeWidget and serializeWorld so the
  # two share one walker and cannot drift. `detachRoots` is the set of detach-roots — the
  # envelope root plus any embedded referent figures the arrow-contract closure contributed
  # (each serializes `parent` as null; the caller/restore policy decides where each attaches)
  # — or undefined (world snapshot: top children keep parent = {"$wk":"world"}).
  @_buildObjectTable: (widgetSet, onExternal, rootDescription, detachRoots) ->
    objects = []
    slotOf = new Map          # live object -> table index (identity; cycle/sharing safe)

    describe = (v) ->
      return "undefined" unless v?
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
      return value if t is "string" or t is "boolean"
      return Serializer.numberRef value if t is "number"
      # a class, or a class's own prototype, belongs to the page: named by its class (the class keys,
      # WellKnownObjects' header), asked before the function and widget readings below, either of which
      # it would otherwise meet (a Widget-branch prototype is `instanceof Widget`)
      classKey = WellKnownObjects.classKeyFor value
      return {$wk: classKey} if classKey?
      return encodeFunction(value, owner, propName, path) if t is "function"
      # objects:
      if value instanceof Widget
        # a widget entered is named on the path, so a refusal met inside its record names the widget a person
        # has to find
        return {$r: encodeToSlot(value, path + SerializationError.enteringWidget(value))} if widgetSet.has value
        wk = WellKnownObjects.keyFor value
        return {$wk: wk} if wk?
        # external, non-well-known widget — the canonical rich-error case
        switch onExternal
          when "nullify" then return null
          when "record"  then return {$ext: value.uniqueIDString()}
          # "capture": pull the off-tree widget into the table as a full record. Used by the
          # world snapshot, where EVERYTHING reachable is genuine world state (e.g. the widget a
          # demo PointerWdgt stands in for, off the tree) and "everything is in-structure"
          # is the intent (§4.9). Self-policing: if it reaches a truly unserializable value it
          # throws the same rich error below.
          when "capture" then return {$r: encodeToSlot(value, path + SerializationError.enteringWidget(value))}
          else fail (value.uniqueIDString() + " is outside the serialized structure and is not a well-known object"),
                    path, describe(value),
                    "Serialize a common container that holds both widgets; or clear the connection; or register the target as a well-known object."
      # non-widget object: a world singleton re-bound by key, else a real table slot
      wk = WellKnownObjects.keyFor value
      return {$wk: wk} if wk?
      {$r: encodeToSlot(value, path)}

    encodeFunction = (fn, owner, propName, path) ->
      # a widget's INJECTED method is kept with its source (Widget.keptSourceOf), and that is the one
      # function the load restores, with the widget's own injectProperty: so a {"$src"} is written for
      # nothing else, and only from a widget's own field. The source is the function's, so it describes
      # the function the field holds now: one a run assigned has none.
      keptSource = Widget.keptSourceOf fn
      if owner? and propName? and Serializer.classTakesInjectedMethods(owner.constructor) and typeof keptSource is "string"
        return {$src: keptSource}
      # Any other function is refused, never dropped: no text restores it faithfully (a closure over
      # a run's locals, a native, a class member's body). The usual way a WIDGET comes to hold one is
      # a person's run (`@f = -> 42`, Widget.evaluateString), so the remedy names the person's
      # gestures first -- for a function held directly in a widget's field, an object inspector's
      # Remove, or its Save as CoffeeScript, which keeps the source; for one held deeper (in an
      # array, a Map, a Set or a plain object), the Remove of the field that follows the last widget
      # its path names -- and then the class's own, for a field its code sets. A function in a slot
      # has no property name: its path says where it is.
      held = if propName? then "the function-valued property ." + propName else "a function"
      if propName? and owner? and Serializer.classTakesInjectedMethods owner.constructor
        remediation = "Remove ." + propName + " with an inspector on " + owner.uniqueIDString() + ", or Save it there as CoffeeScript (an inspector's Save keeps a method's source). If " + owner.constructor.name + "'s own code sets it, declare it in that class's @serializationTransients and recompute it on restore."
        fail (held + " has no editable source and is not a serialization transient"), path, "a function (" + propName + ")", remediation
      fail (held + " has no editable source"), path, "a function",
           "Remove the field holding it -- on a widget, the field that follows the last widget the path names, with an inspector's Remove -- or, if a class's own code keeps it there, declare that field in the class's @serializationTransients and recompute it on restore."

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

    encodeOwnProps = (obj, path, isDetachRoot) ->
      transients = Serializer.transientsForClass obj.constructor
      props = {}
      for own name of obj
        continue if name is "instanceNumericID" or name is "className"
        continue if transients.has name
        continue if Widget.isDerivedStateField name     # derived state is re-derived, never written
        if isDetachRoot and name is "parent"
          # a detach-root restores DETACHED; the caller (envelope root) or the restore
          # policy (an embedded referent figure — homed to the shelf) decides where it goes.
          props.parent = null
          continue
        # a value DERIVED here (NativeValueKinds.isDerivedAt -- past the declared transients above, a
        # canvas context beside its canvas) is left out: after a load its holder rebuilds it, lazily,
        # as a fresh widget builds it
        continue if NativeValueKinds.isDerivedAt obj, name
        props[name] = refFor obj[name], (path + SerializationError.intoProperty name), obj, name
      props

    # the world sets holding the widget, by their markers (@WORLD_SET_MEMBERSHIPS, in its order)
    membershipsFor = (widget) ->
      return [] unless world?
      (marker for own marker, setField of Serializer.WORLD_SET_MEMBERSHIPS when world[setField]?.has widget)

    populateRecord = (record, obj, path) ->
      # a value its holder rebuilds (NativeValueKinds.rebuildsItself: a canvas context, a 3D pane's
      # runtime) reaching a record stands somewhere that holder does not rebuild it -- where it does, it
      # is derived and never written (NativeValueKinds.isDerivedAt, encodeOwnProps) -- and no file can
      # carry it: refused, whatever its type
      if NativeValueKinds.rebuildsItself obj
        fail ("a value its holder rebuilds (" + describe(obj) + ") cannot be serialized outside its holder's own field"),
             path, describe(obj),
             "A value its holder rebuilds -- a canvas context, a 3D pane's runtime -- is left out of a file, and rebuilt, only in its holder's own field: a canvas context beside the canvas it is drawn from (held as <name>Context next to that canvas <name>), anything else in a field its holder's class declares in @serializationTransients. Held anywhere else, no file can carry it: close what holds it (an inspector on it), or remove the field a run filled with it."
      # --- native / special types: $-tagged records (user class names can't collide) ---
      if NativeValueKinds.isArray obj
        record.class = "$Array"
        record.items = (refFor(obj[i], path + SerializationError.intoItem i) for i in [0...obj.length])
        return
      if NativeValueKinds.isDate obj
        record.class = "$Date"
        record.ms = Serializer.numberRef Date.prototype.getTime.call(obj)   # an invalid date's is NaN
        return
      if NativeValueKinds.isCanvasLike obj
        # HTMLCanvasElement or SWCanvasElement (see NativeValueKinds). Its pixels are PHYSICAL, made at
        # this page's pixel ratio, which rides along as `pr` so a page at another ratio can resample
        # them to its own (Deserializer's $Canvas builder)
        record.class = "$Canvas"
        record.w = obj.width
        record.h = obj.height
        record.pr = ceilPixelRatio
        record.data = obj.toDataURL "image/png"
        return
      if NativeValueKinds.isMap obj
        record.class = "$Map"
        entries = []
        obj.forEach (v, k) -> entries.push [refFor(k, path + SerializationError.INTO_MAP_KEY), refFor(v, path + SerializationError.intoMapValue k)]
        record.entries = entries
        return
      if NativeValueKinds.isSet obj
        record.class = "$Set"
        items = []
        obj.forEach (x) -> items.push refFor(x, path + SerializationError.INTO_SET_ITEM)
        record.items = items
        return
      if obj instanceof Color
        # restored through Color.create so immutable-color dedupe is preserved. Color makes its components
        # numbers (Color._channel, Color._alpha), which is what the load holds a file's Color to; one
        # written into after it was made is refused here, so a save never writes what the load refuses
        if (colorProblem = Serializer._colorComponentsProblem obj)?
          fail ("a Color (" + colorProblem + ") cannot be serialized"), path, describe(obj),
            "A Color is immutable and shared: Color.create hands every holder of one colour the same object, so one written into after it was made -- by a run, or by an edit of Color itself -- has changed every holder of that colour. Put its components back (or undo the edit of Color), then save."
        record.class = "Color"
        record.rgba = (Serializer.numberRef component for component in [obj._r, obj._g, obj._b, obj._a])
        return
      # --- a plain object literal ---
      if (not obj.constructor?) or obj.constructor is Object
        record.class = "$Object"
        record.props = encodeOwnProps obj, path, false
        return
      # --- a registered Fizzygum class instance (a Widget or a data class) ---
      # THE CLOSED SET, the same rule as Duplicator._copyFizzygumObject's: a plain object literal
      # (above), or an instance of the class classNamed answers for its constructor's name -- the test
      # Deserializer.instantiate builds a record by, so a save refuses exactly what a load could not
      # restore. An instance of a browser-native class the encoders above have no branch for (a
      # CanvasGradient, a DOMRect) is refused here, never written as a record that would restore as
      # an inert shell.
      #   An element the page loads (an image, a video) is refused here too, and deliberately has no
      # encoder: it is a PAGE FACT, derived from its holder's own path field, so the holder re-makes it
      # after a restore and after a copy, and no file carries it -- what a file would carry is where
      # the SAVING page found it, which is nowhere the loading page need be.
      className = obj.constructor.name
      if classNamed(className) isnt obj.constructor
        remediation = if NativeValueKinds.isImage(obj) or NativeValueKinds.isVideo(obj)
          "An element the page loads is derived from its holder's path: keep the path in a field, declare the property holding the element in @serializationTransients, and re-make the element from the path in _afterDeserialization and _reactToBeingCopied."
        else
          SerializationError.UNRECOGNIZED_TYPE_REMEDY
        fail ("a value of an unrecognized type (" + className + ") cannot be serialized"),
             path, describe(obj), remediation
      record.class = className
      record.iid = obj.instanceNumericID if obj.instanceNumericID?
      if obj instanceof Widget
        m = membershipsFor obj
        record.memberships = m if m.length
      record.props = encodeOwnProps obj, path, (detachRoots? and detachRoots.has obj)
      return

    {objects: objects, refFor: refFor, encodeToSlot: encodeToSlot}
