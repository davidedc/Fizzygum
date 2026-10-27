# Deserializer — rebuilds a widget graph from a Serializer envelope. See
# docs/architecture/serialization-duplication-reference.md §9. Returns { widget, whenReady }: the widget
# is DETACHED (the caller attaches it — a menu action, drop handler, or snapshot loader);
# whenReady is a promise that resolves once the async work the restore started has landed: every
# canvas's decode (via <img> onload, on both backends), and every load a restored widget's
# _afterDeserialization started for an element it re-makes from its own path.
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
        direction: "load"
    # the same envelope-level verdict the world loader asks for BEFORE its teardown (through
    # whyItCanNeverBeRestored), so a file it lets through cannot fail one of these after it
    shapeProblem = @_envelopeShapeProblem envelope
    throw new SerializationError shapeProblem, direction: "load" if shapeProblem?

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
      return undefined unless ref?
      t = typeof ref
      return ref if t is "string" or t is "number" or t is "boolean"
      return shells[ref.$r] if ref.$r?              # $r may legitimately be 0
      return @resolveWellKnown ref.$wk if ref.$wk?
      if ref.$ext?
        # prefer a shell being restored (world snapshot); fall back to the live world.
        return shellByUniqueId.get(ref.$ext) ? @resolveExternal ref.$ext
      # a $src at a non-property position (e.g. inside an array/Map) — rare; compile eagerly.
      return @compileFunction(ref.$src) if ref.$src?
      undefined

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
      builder = @_tagBuilderFor record.class
      if builder?.populate?
        # a native-container tag whose populate links its items ($Array/$Set/$Map), or a
        # tag fully built in pass 1 whose populate is an explicit no-op ($Date/$Canvas/Color)
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
    # (c) re-register world-set memberships recorded at serialize time.
    # ⚠ Re-registration hands the shell to machinery that reads its fields, so every marker
    # carries a verdict against the transients this restore just dropped: STEPPING's loop
    # re-seeds the dropped lastTime itself (a restored throttled stepper NaN-stalled until it
    # did — see _runChildrensStepFunction); the KEYBOARD dispatch reads only the prototype
    # method, and the one receiver with transient state (the spreadsheet) rebuilds it in the
    # per-class hook, pass (d) below, before any event can arrive; the REFERENCE TRACKER's
    # consumers read destroyed + referencedWidget, both serialized (ShortcutWdgt declares no
    # transients); the OPENPOPUPS consumers read isOrphan()/instanceNumericID (re-derived /
    # serialized), and the dropped closure mark restores false — the correct state for a
    # pinned pop-up. A NEW marker must state its verdict here: what does the re-registered
    # machinery read, and is any of it transient-dropped?
    if world?
      for record, i in records when record.memberships?
        shell = shells[i]
        for m in record.memberships
          switch m
            when "stepping"         then world.steppingWdgts?.add shell
            when "keyboardReceiver" then world.keyboardEventsReceivers?.add shell
            when "referenceTracker" then world.widgetsReferencingOtherWidgets?.add shell
            when "openPopUp"        then world.openPopUps?.add shell
    # (d) per-class post-restore hook (absorbs ad-hoc deserialization guards). A hook that re-makes
    # an element the page loads from its holder's path (an image) answers that load's promise, and
    # whenReady waits for it: the restore is ready when what it re-made has arrived, not merely when
    # its own records have decoded. Any other answer is ignored -- so a hook that is NOT reporting a
    # load must not end on an expression that yields a thenable (CoffeeScript returns the last one).
    for shell in shells when shell instanceof Widget
      reloading = shell._afterDeserialization?()
      asyncPromises.push reloading if typeof reloading?.then is "function"

    # ---- Pass 5: deliver ----
    # `shells` is exposed so the world-snapshot loader can resolve its `world` section's
    # {"$r"} references (children, bin, app slots, preferences) against the same table.
    whenReady = if asyncPromises.length then Promise.all(asyncPromises) else Promise.resolve()
    { widget: shells[envelope.root], whenReady: whenReady, shells: shells }

  # WHY THIS BUILD CAN NEVER RESTORE THIS ENVELOPE, as a clause to follow "cannot be loaded here: "
  # (no closing full stop), or undefined when it can. PURE — it only reads the envelope — which is
  # what lets WorldWdgt.loadWorldSnapshot ask it before its teardown destroys the desktop. It
  # predicts exactly the throws a restore would hit and no others: the envelope-level ones
  # @deserialize raises up front (one helper answers both, so the two cannot drift), and
  # @instantiate's per-record one — a record class with no tag builder that can never arrive. Its
  # first two tests ARE @instantiate's, made the same way (@_tagBuilderFor, then classNamed), so a
  # record class either passes them, and @instantiate builds it, or must be one that can still arrive.
  # WHAT can still arrive is the caller's to say: the world passes PartsRegistry.canEverProvideClass,
  # so a class a LAZY part provides is not a reason (that file loads the part first). An
  # app-singleton {"$wk"} key is not checked, because an unresolved one is left undefined rather
  # than thrown (@resolveWellKnown). The format check stays with each caller (the loader's also
  # wants kind:"world"), so the envelope is taken to be a Fizzygum one.
  @whyItCanNeverBeRestored: (envelope, canStillArrive) ->
    shapeProblem = @_envelopeShapeProblem envelope
    return shapeProblem if shapeProblem?
    unbuildable = []
    for record in envelope.objects
      continue if @_tagBuilderFor(record.class)?
      continue if classNamed(record.class)?
      continue if canStillArrive record.class
      unbuildable.push record.class unless record.class in unbuildable
    return undefined unless unbuildable.length
    "it uses " + unbuildable.join(", ") + ", which this build does not have"

  # What makes an envelope unrestorable WHOEVER restores it and whatever this build contains — a
  # clause in whyItCanNeverBeRestored's form, or undefined. Every record the Serializer writes
  # carries a string `class` (a class name or a $-tag), and @instantiate resolves nothing else, so
  # a record without one is a malformed table, not an unknown class.
  @_envelopeShapeProblem: (envelope) ->
    if envelope.formatVersion > Serializer.FORMAT_VERSION
      return "it is format version " + envelope.formatVersion + ", newer than this build understands (" +
        Serializer.FORMAT_VERSION + "). Update Fizzygum and retry"
    return "its object table is missing" unless Array.isArray envelope.objects
    for record, i in envelope.objects
      unless record? and typeof record.class is "string"
        return "its object table is malformed (entry " + i + " names no class)"
    undefined

  # --- native-type tag registry ---
  # One entry per serialization tag, consulted by BOTH passes: the pass-1 factory
  # (@instantiate, via .build) and the pass-2 linker (@deserialize, via .populate). Having
  # ONE table keeps the two passes from drifting apart on the tag set. Tags NOT listed here
  # (user classes) fall to the generic branch in each pass. A tag with a `build` but no
  # `populate` ($Object) links via the generic assignProps, exactly like a user class.
  # Kept a simple literal for the fragment-compile gate: build fns take (record,
  # asyncPromises), populate fns take (shell, record, resolveRef); neither uses `this`.
  # Read ONLY through @_tagBuilderFor below, never indexed directly.
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
    "$Canvas":
      build: (record, asyncPromises) ->
        # The record is PHYSICAL pixels made at the saving page's pixel ratio `pr`, and every canvas
        # that rides a save is a raster of its widget's LOGICAL size x that ratio (a drawn canvas, a
        # painting, a pinned menu's icon). At another ratio it is resampled to the size it has on this
        # page -- here, at the decode, never by the widget that adopts it: the canvas exists at its
        # final size before its pixels arrive, so a widget that takes it before the decode lands (the
        # file door attaches first) holds the very object the pixels land in. A record without `pr` is
        # taken to be at this page's ratio, and is drawn as it was saved.
        scale = if record.pr? then ceilPixelRatio / record.pr else 1
        w = Math.round record.w * scale
        h = Math.round record.h * scale
        canvas = HTMLCanvasElement.createOfPhysicalDimensions new Point w, h
        ctx = canvas.getContext "2d"
        # page-element-not-held: the decoder of the record's own data: URL, dropped once its pixels
        # are in the canvas -- no widget field ever holds it
        img = new Image
        # decode via onload for BOTH backends (SWCanvas REQUIRES the <img> decoded before
        # drawImage; native is fine to defer too). whenReady gates any pixel read.
        #   The decode lands AFTER the restore has handed the canvas to its widget, and a canvas
        # has ONE context: a widget that has already laid its pixel-ratio scaling on it (its
        # _afterDeserialization, its first paint) would have the saved pixels drawn through that
        # scaling. The record is physical pixels, so they go down at the identity, and the
        # widget's transform is put back -- with the smoothing setting below, which the save/restore
        # keeps off the widget's context too.
        asyncPromises.push new Promise (resolve) ->
          img.onload = ->
            ctx.save()
            try
              ctx.setTransform 1, 0, 0, 1, 0, 0
              if scale is 1
                ctx.drawImage img, 0, 0
              else
                # shrinking averages (smoothing on: at 2 -> 1 a box of four pixels); enlarging
                # replicates pixels (smoothing off), so a 1 -> 2 -> 1 round trip gives back the very
                # pixels it started from
                ctx.imageSmoothingEnabled = scale < 1
                ctx.drawImage img, 0, 0, w, h
            catch
            finally
              ctx.restore()
            resolve()
          img.onerror = -> resolve()
        img.src = record.data
        canvas
      populate: -> # fully built in pass 1 — nothing to populate
    "Color":
      build:    (record, asyncPromises) -> Color.create record.rgba[0], record.rgba[1], record.rgba[2], record.rgba[3]
      populate: -> # fully built in pass 1 — nothing to populate

  # The tag builder a record's class names, or undefined. An OWN-property lookup, because a record
  # class is DATA read out of a file: indexing the table would also answer the names every object
  # inherits (`constructor`, `toString`, `__proto__`) with something that is not a builder.
  @_tagBuilderFor: (tag) ->
    if Object::hasOwnProperty.call Deserializer.TAG_BUILDERS, tag then Deserializer.TAG_BUILDERS[tag] else undefined

  # --- pass-1 factory: shell (or fully-built native value) for one record ---
  @instantiate: (record, asyncPromises) ->
    builder = @_tagBuilderFor record.class
    return builder.build record, asyncPromises if builder?
    # a user class: bare shell, constructor NOT run — the established, SliderWdgt-guarded convention.
    # classNamed, so a record naming a native global or an inherited/accessor property of window
    # fails here as a load error instead of building a non-Fizzygum shell or throwing a TypeError
    klass = classNamed record.class
    # the world loader refuses such a file before its teardown (whyItCanNeverBeRestored mirrors
    # this test); this throw is the net for every other caller
    unless klass?
      throw new SerializationError ("it references the class '" + record.class +
        "', which does not exist in this build"), direction: "load"
    Object.create klass.prototype

  @resolveWellKnown: (key) ->
    resolved = WellKnownObjects.resolve key
    # An unresolved well-known (e.g. an app singleton not present in this world) is left as
    # undefined rather than aborting the whole restore; the widget simply loses that link.
    resolved

  # A same-world re-link token ({"$ext": uniqueID}) — used by the world snapshot's tolerant
  # pass. Resolve against the live world by unique-id string; undefined if absent.
  @resolveExternal: (uniqueID) ->
    return undefined unless world?
    world.topWdgtSuchThat? (w) -> w.uniqueIDString?() is uniqueID

  @compileFunction: (source) ->
    # compile a bare "(args) -> body" CoffeeScript function source to a live function
    # (rare fallback; the common path is injectProperty on the owning widget). Uses the
    # live world's evaluateString (a Widget method) as the CoffeeScript entry point.
    try
      world?.evaluateString? "(" + source + ")"
    catch e
      undefined
