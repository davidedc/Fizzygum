# Deserializer — rebuilds a widget graph from a Serializer envelope. See
# docs/serialization-duplication-reference.md §9. Returns { widget, whenReady }: the widget
# is DETACHED (the caller attaches it — a menu action, drop handler, or snapshot loader);
# whenReady is a promise that resolves once async assets (images, and canvases under the
# SWCanvas backend, which decode via <img> onload) have finished decoding.
#
# Five passes over the envelope:
#   1. instantiate  — a shell per record (constructor NOT run), or the native-type factory
#   2. populate     — resolve $r/$wk/$ext refs at any depth and assign props/items/entries
#   3. register     — identity (fresh id for kind:"widget", restored iid for kind:"world")
#                     + registerThisInstance so Class.instances / GC / class-edit see it
#   4. fixups       — compile $src functions, rebuild derived contexts, re-register world-set
#                     memberships, run the per-class _afterDeserialization hook
#   5. deliver      — return { widget, whenReady }
class Deserializer

  # Restore from an envelope string (or an already-parsed envelope object).
  @deserialize: (envelopeOrString, opts = {}) ->
    envelope = if typeof envelopeOrString is "string" then JSON.parse(envelopeOrString) else envelopeOrString
    unless envelope? and envelope.format is Serializer.FORMAT
      throw new SerializationError "not a Fizzygum serialization envelope",
        offender: "format=" + envelope?.format
    if envelope.formatVersion > Serializer.FORMAT_VERSION
      throw new SerializationError ("this file is format version " + envelope.formatVersion +
        ", newer than this build understands (" + Serializer.FORMAT_VERSION + "). Update Fizzygum and retry.")

    records = envelope.objects
    kind = envelope.kind or "widget"
    shells = new Array records.length
    asyncPromises = []
    srcJobs = []          # deferred function compiles: {shell, name, source}
    # uniqueIDString ("Class#iid") -> shell, so a {"$ext"} same-world re-link token (the
    # world snapshot's tolerant pass) resolves against the SHELLS being built rather than
    # the live world (the restored widgets are not attached yet). Populated after pass 1.
    shellByUniqueId = new Map

    # resolve a reference form to a live value (used at any nesting depth).
    resolveRef = (ref) =>
      return nil unless ref?
      t = typeof ref
      return ref if t is "string" or t is "number" or t is "boolean"
      return shells[ref.$r] if ref.$r?              # $r may legitimately be 0
      return @resolveWellKnown ref.$wk if ref.$wk?
      if ref.$ext?
        # prefer a shell being restored (world snapshot); fall back to the live world.
        return shellByUniqueId.get(ref.$ext) ? @resolveExternal ref.$ext
      # a $src at a non-property position (e.g. inside an array/Map) — rare; compile eagerly.
      return @compileFunction(ref.$src) if ref.$src?
      nil

    assignProps = (shell, props) ->
      return unless props?
      for own name, ref of props
        if ref? and typeof ref is "object" and ref.$src?
          srcJobs.push {shell: shell, name: name, source: ref.$src}
        else
          shell[name] = resolveRef ref

    # ---- Pass 1: instantiate shells ----
    for record, i in records
      shells[i] = @instantiate record, asyncPromises
    # index widget shells by their (about-to-be-restored) uniqueIDString so a {"$ext"}
    # token can resolve to a shell in pass 2 (world snapshot only emits these).
    for record, i in records when record.iid? and record.class? and record.class.charAt(0) isnt "$"
      shellByUniqueId.set record.class + "#" + record.iid, shells[i]

    # ---- Pass 2: populate & link ----
    for record, i in records
      shell = shells[i]
      builder = Deserializer.TAG_BUILDERS[record.class]
      if builder?.populate?
        # a native-container tag whose populate links its items ($Array/$Set/$Map), or a
        # tag fully built in pass 1 whose populate is an explicit no-op ($Date/$Image/
        # $Canvas/$Video/Color)
        builder.populate shell, record, resolveRef
      else
        # $Object tags and every user class: resolve & assign the recorded props
        assignProps shell, record.props

    # ---- Pass 3: identity & registration ----
    for record, i in records
      shell = shells[i]
      if shell instanceof Widget
        if kind is "world" and record.iid?
          shell.instanceNumericID = record.iid
        else
          shell.assignUniqueID?()        # fresh id (like duplication) for kind:"widget"
        shell.registerThisInstance?()

    # ---- Pass 4: fixups ----
    # (a) compile user-injected methods via the existing injectProperty machinery
    for job in srcJobs
      if job.shell.injectProperty?
        job.shell.injectProperty job.name, job.source
      else
        job.shell[job.name] = @compileFunction job.source
    # (b) rebuild any recorded derived contexts from their sibling canvases (naming
    #     convention: "<name>Context" <- canvas "<name>"; cf. CanvasRenderingContext2D)
    for record, i in records
      if record.derived?
        for name in record.derived
          canvas = shells[i][name.replace "Context", ""]
          shells[i][name] = canvas.getContext "2d" if canvas?.getContext?
    # (c) re-register world-set memberships recorded at serialize time
    if world?
      for record, i in records when record.memberships?
        shell = shells[i]
        for m in record.memberships
          switch m
            when "stepping"         then world.steppingWdgts?.add shell
            when "keyboardReceiver" then world.keyboardEventsReceivers?.add shell
            when "referenceTracker" then world.widgetsReferencingOtherWidgets?.add shell
    # (d) per-class post-restore hook (absorbs ad-hoc deserialization guards)
    for shell in shells
      shell._afterDeserialization?() if shell instanceof Widget

    # ---- Pass 5: deliver ----
    # `shells` is exposed so the world-snapshot loader can resolve its `world` section's
    # {"$r"} references (children, basement, app slots, preferences) against the same table.
    whenReady = if asyncPromises.length then Promise.all(asyncPromises) else Promise.resolve()
    { widget: shells[envelope.root], whenReady: whenReady, shells: shells }

  # --- native-type tag registry ---
  # One entry per serialization tag, consulted by BOTH passes: the pass-1 factory
  # (@instantiate, via .build) and the pass-2 linker (@deserialize, via .populate). Having
  # ONE table keeps the two passes from drifting apart on the tag set. Tags NOT listed here
  # (user classes) fall to the generic branch in each pass. A tag with a `build` but no
  # `populate` ($Object) links via the generic assignProps, exactly like a user class.
  # Kept a simple literal for the fragment-compile gate: build fns take (record,
  # asyncPromises), populate fns take (shell, record, resolveRef); neither uses `this`.
  @TAG_BUILDERS:
    "$Array":
      build:    (record, asyncPromises) -> []
      populate: (shell, record, resolveRef) -> shell[j] = resolveRef(item) for item, j in record.items
    "$Object":
      build:    (record, asyncPromises) -> {}
    "$Map":
      build:    (record, asyncPromises) -> new Map
      populate: (shell, record, resolveRef) -> shell.set resolveRef(pair[0]), resolveRef(pair[1]) for pair in record.entries
    "$Set":
      build:    (record, asyncPromises) -> new Set
      populate: (shell, record, resolveRef) -> shell.add resolveRef(item) for item in record.items
    "$Date":
      build:    (record, asyncPromises) -> new Date record.ms
      populate: -> # fully built in pass 1 — nothing to populate
    "$Image":
      build: (record, asyncPromises) ->
        img = new Image
        asyncPromises.push new Promise (resolve) ->
          img.onload = -> resolve()
          img.onerror = -> resolve()
        img.src = record.src
        img
      populate: -> # fully built in pass 1 — nothing to populate
    "$Canvas":
      build: (record, asyncPromises) ->
        canvas = HTMLCanvasElement.createOfPhysicalDimensions new Point record.w, record.h
        ctx = canvas.getContext "2d"
        img = new Image
        # decode via onload for BOTH backends (SWCanvas REQUIRES the <img> decoded before
        # drawImage; native is fine to defer too). whenReady gates any pixel read.
        asyncPromises.push new Promise (resolve) ->
          img.onload = ->
            try ctx.drawImage img, 0, 0
            resolve()
          img.onerror = -> resolve()
        img.src = record.data
        canvas
      populate: -> # fully built in pass 1 — nothing to populate
    "$Video":
      build: (record, asyncPromises) ->
        v = document.createElement "video"
        v.src = record.src
        v.autoplay = record.autoplay
        v.currentTime = record.currentTime if record.currentTime?
        v
      populate: -> # fully built in pass 1 — nothing to populate
    "Color":
      build:    (record, asyncPromises) -> Color.create record.rgba[0], record.rgba[1], record.rgba[2], record.rgba[3]
      populate: -> # fully built in pass 1 — nothing to populate

  # --- pass-1 factory: shell (or fully-built native value) for one record ---
  @instantiate: (record, asyncPromises) ->
    builder = Deserializer.TAG_BUILDERS[record.class]
    return builder.build record, asyncPromises if builder?
    # a user class: bare shell, constructor NOT run — the established, SliderWdgt-guarded convention
    klass = window[record.class]
    unless klass?
      throw new SerializationError ("this file references the class '" + record.class +
        "', which does not exist in this build")
    Object.create klass.prototype

  @resolveWellKnown: (key) ->
    resolved = WellKnownObjects.resolve key
    # An unresolved well-known (e.g. an app singleton not present in this world) is left as
    # nil rather than aborting the whole restore; the widget simply loses that link.
    resolved

  # A same-world re-link token ({"$ext": uniqueID}) — used by the world snapshot's tolerant
  # pass. Resolve against the live world by unique-id string; nil if absent.
  @resolveExternal: (uniqueID) ->
    return nil unless world?
    world.topWdgtSuchThat? (w) -> w.uniqueIDString?() is uniqueID

  @compileFunction: (source) ->
    # compile a bare "(args) -> body" CoffeeScript function source to a live function
    # (rare fallback; the common path is injectProperty on the owning widget). Uses the
    # live world's evaluateString (a Widget method) as the CoffeeScript entry point.
    try
      world?.evaluateString? "(" + source + ")"
    catch e
      nil
