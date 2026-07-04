# Serializer — turns a widget subtree into a versioned, self-contained JSON envelope. See
# docs/serialization-duplication-reference.md for the format spec (§3), the reference
# policy (§4), the transients/derived/function protocol (§5), the per-type handlers (§6),
# and how it shares per-class knowledge with — but no mutable state with — the
# DeepCopierMixin duplication walker (§1).
#
# It is side-effect-free and deterministic: it builds records DIRECTLY from the live graph
# (it creates no shells, so it advances no ID counters and leaks no Class.instances entry),
# so two serializations of the same unchanged widget are byte-identical.
class Serializer

  # envelope identity (see the reference doc §3)
  @FORMAT: "fizzygum"
  @FORMAT_VERSION: 1

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

  # Build the plain-object envelope (no stringify) — reused by the world snapshot (Phase 5).
  @buildEnvelope: (root, opts = {}) ->
    onExternal = opts.onExternalPointer or "throw"
    # the set of widgets that count as "in-structure" (O(1) membership); includes root.
    widgetSet = new Set root.allChildrenBottomToTop()
    objects = []
    slotOf = new Map          # live object -> table index (identity; cycle/sharing safe)
    rootDescription = if root.uniqueIDString? then root.uniqueIDString() else root.constructor.name

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
      record.props = encodeOwnProps obj, path, (obj is root)
      return

    rootIndex = encodeToSlot root, rootDescription

    envelope =
      format: Serializer.FORMAT
      formatVersion: Serializer.FORMAT_VERSION
      kind: opts.kind or "widget"
      root: rootIndex
      objects: objects
    envelope.savedAt = opts.savedAt if opts.savedAt?
    envelope.build = window.FIZZYGUM_BUILD if window.FIZZYGUM_BUILD?
    envelope
