# Deserializer — rebuilds a widget graph from a Serializer envelope. See
# docs/architecture/serialization-duplication-reference.md §9. Returns { widget, whenReady }: the widget
# is DETACHED (the caller attaches it — a menu action, drop handler, or snapshot loader);
# whenReady is a promise that resolves once the async work the restore started has landed: every
# canvas's decode (via <img> onload, on both backends), and every load a restored widget's
# _afterDeserialization started for an element it re-makes from its own path.
#
# Five passes over the envelope:
#   1. instantiate  — a shell per record (constructor NOT run), or the native-type factory
#   2. populate     — resolve $r/$wk/$ext/$num refs at any depth and assign props/items/entries
#   3. register     — identity (fresh id for kind:"widget", restored iid for kind:"world")
#                     + registerThisInstance so Class.instances / GC / class-edit see it
#   4. fixups       — compile $src functions, re-register world-set memberships, run the
#                     per-class _afterDeserialization hook (a derived value -- a canvas context --
#                     is in no record: its holder rebuilds it, lazily, as a fresh widget does)
#   5. deliver      — return { widget, whenReady }
class Deserializer

  # Restore from an envelope string (or an already-parsed envelope object).
  @deserialize: (envelopeOrString, opts = {}) ->
    envelope = if typeof envelopeOrString is "string" then JSON.parse(envelopeOrString) else envelopeOrString
    unless envelope? and envelope.format is Serializer.FORMAT
      throw new SerializationError "not a Fizzygum serialization envelope",
        offender: "format=" + envelope?.format
        direction: "load"
    # the same envelope-level verdict both file doors ask for before anything changes (through
    # whyItCanNeverBeRestored), so a file they let through cannot fail one of these after it
    shapeProblem = @_envelopeShapeProblem envelope
    throw new SerializationError shapeProblem, direction: "load" if shapeProblem?
    # and asked before the first shell is built, so a refused file leaves nothing registered
    functionSourceProblem = @_functionSourceOnANonWidget envelope
    throw new SerializationError functionSourceProblem, direction: "load" if functionSourceProblem?

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
      return Deserializer.numberFrom ref if Deserializer._isNumberRef ref
      return shells[ref.$r] if ref.$r?              # $r may legitimately be 0
      # a singleton absent from this world (no wallpaper yet, say) resolves to undefined and the widget
      # loses that link; a key naming a CLASS this page lacks throws instead (WellKnownObjects.resolve),
      # and both file doors refuse such a file before anything is built (whyItCanNeverBeRestored)
      return WellKnownObjects.resolve ref.$wk if ref.$wk?
      if ref.$ext?
        # prefer a shell being restored (world snapshot); fall back to the live world.
        return shellByUniqueId.get(ref.$ext) ? @resolveExternal ref.$ext
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
          shell.assignUniqueID()        # fresh id (like duplication) for kind:"widget"
        shell.registerThisInstance()

    # ---- Pass 4: fixups ----
    # (a) compile each injected method with its widget's own injectProperty: a {"$src"} stands only as a
    #     property of a widget's record (_envelopeShapeProblem and _functionSourceOnANonWidget refused
    #     every other place before pass 1)
    for job in srcJobs
      job.shell.injectProperty job.name, job.source
    # (b) re-register world-set memberships recorded at serialize time: each marker names its set in
    # Serializer.WORLD_SET_MEMBERSHIPS, the table the save wrote it from, which also holds each
    # marker's verdict on what the re-registered machinery reads. Every marker is one of its keys:
    # _envelopeShapeProblem refused the envelope up front otherwise.
    if world?
      for record, i in records when record.memberships?
        world[Serializer.WORLD_SET_MEMBERSHIPS[marker]]?.add shells[i] for marker in record.memberships
    # (c) per-class post-restore hook (absorbs ad-hoc deserialization guards). A hook that re-makes
    # an element the page loads from its holder's path (an image) answers that load's promise, and
    # whenReady waits for it: the restore is ready when what it re-made has arrived, not merely when
    # its own records have decoded. Any other answer is ignored -- so a hook that is NOT reporting a
    # load must not end on an expression that yields a thenable (CoffeeScript returns the last one).
    for shell in shells when shell instanceof Widget
      reloading = shell._afterDeserialization?()
      asyncPromises.push reloading if typeof reloading?.then is "function"

    # ---- Pass 5: deliver ----
    # `shells` is exposed so the world-snapshot loader can resolve its `world` section's
    # {"$r"} references (children, bin, app windows, preferences) against the same table.
    whenReady = if asyncPromises.length then Promise.all(asyncPromises) else Promise.resolve()
    { widget: shells[envelope.root], whenReady: whenReady, shells: shells }

  # WHY THIS BUILD CAN NEVER RESTORE THIS ENVELOPE, as a clause to follow "cannot be loaded here: "
  # (no closing full stop), or undefined when it can. PURE — it only reads the envelope — which is
  # what lets both file doors ask it before anything changes (WorldWdgt.loadWorldSnapshot before its
  # teardown destroys the desktop, FileLoading's widget door before the first shell). It predicts
  # exactly the refusals @deserialize raises up front -- the same two helpers answer both, so the two
  # cannot drift: the envelope's shape (which also refuses what a restore would silently drop or get
  # wrong: a membership, a number written as no number, a $Date or Color field that is no number), and
  # a method's source on a class that cannot take one -- and the throws that resolve a NAME read out of
  # the file -- @instantiate's per-record one, and
  # WellKnownObjects.resolve's for a class key or an app key. The names are @classNamesIn, the one list
  # of the classes a file needs, which the parts pre-load reads too (loadWhatItNeeds), so a file is
  # refused for exactly the names its restore would fail on: each is tested as the restore resolves it,
  # through classNamed, so it either passes, and resolves, or must be one that can still arrive; and an
  # app key's class, once resident, must be an app (WellKnownObjects.isAppClass), as resolveApp asks. WHAT
  # can still arrive is the caller's to say: both file doors pass PartsRegistry.canEverProvideClass, so
  # a class a LAZY part provides is not a reason (that file loads the part first). The format check stays
  # with each caller (the world loader's also wants kind:"world"), so the envelope is taken to be a
  # Fizzygum one.
  @whyItCanNeverBeRestored: (envelope, canStillArrive) ->
    shapeProblem = @_envelopeShapeProblem envelope
    return shapeProblem if shapeProblem?
    functionSourceProblem = @_functionSourceOnANonWidget envelope
    return functionSourceProblem if functionSourceProblem?
    unbuildable = []
    for className in @classNamesIn envelope
      continue if classNamed(className)?
      continue if canStillArrive className
      unbuildable.push className
    return "it uses " + unbuildable.join(", ") + ", which this build does not have" if unbuildable.length
    # an app key must name a class of the app kind (WellKnownObjects.isAppClass); one still to arrive
    # with a lazy part is judged on the door's re-entry, once it has
    notApps = []
    for key in Serializer.wellKnownKeysIn envelope
      appName = WellKnownObjects.appNameInAppKey key
      continue unless appName? and (appClass = classNamed appName)?
      notApps.push appName unless WellKnownObjects.isAppClass(appClass) or appName in notApps
    return WellKnownObjects.notAnAppReason notApps if notApps.length
    undefined

  # Every class name an envelope references, each once: THE list of what restoring it NEEDS, read before
  # anything is changed. Three sources, because a file names classes in three ways, and the restore
  # resolves each through classNamed or throws:
  #   - each object record's `class`, unless it is a native-type TAG (@instantiate builds $Array, $Map,
  #     Color, ... from @TAG_BUILDERS, and a record of any other name through classNamed);
  #   - the `{"$wk": "app:<ClassName>"}` app-singleton keys (WellKnownObjects.resolveApp) -- an eager
  #     desktop launcher's target arrives only through one of these;
  #   - the class keys, `{"$wk": "class:<ClassName>"}` / `"prototype:<ClassName>"`.
  # Nothing else is left out, whatever its spelling: a name no class answers is one the restore would
  # fail on, so it must reach the refusal. Two readers, and the point of one list is that they cannot
  # disagree: the refusal of a file this build can never restore (whyItCanNeverBeRestored) and the
  # pre-load of the lazy parts it needs (loadWhatItNeeds). A pure read of the envelope, which is what
  # lets both run before a world load's teardown.
  @classNamesIn: (envelope) ->
    names = []
    add = (name) -> names.push name if typeof name is "string" and name.length and name not in names
    for record in (envelope?.objects ? []) when record? and !@_tagBuilderFor(record.class)?
      add record.class
    for key in Serializer.wellKnownKeysIn envelope
      add (WellKnownObjects.appNameInAppKey(key) ? WellKnownObjects.classNameInClassKey(key))
    names

  # WHAT THIS ENVELOPE NEEDS BEFORE IT CAN BE RESTORED, loaded. Answers undefined when it is all
  # resident -- every build the suite runs, so there the restore goes on INLINE, a world cycle no later
  # -- else a promise that resolves once the next thing has arrived, for the caller to RE-ENTER its
  # load on. One thing per trip, in this order, so the second is asked on the re-entry:
  #   1. the LAZY PARTS that own the classes it names (@classNamesIn), which are not defined until their
  #      part loads;
  #   2. the REFLECTIVE LAYER, when the file needs it (_needsTheReflectiveLayer), which reads a
  #      declaration off the classes step 1 brought in.
  # Both file doors ask it before anything changes -- WorldWdgt.loadWorldSnapshot before its teardown,
  # FileLoading's widget door before the first shell -- so a load that fails here leaves everything as
  # it was. A FILE THAT DID NOT ARRIVE is that load failing, and becomes a load SerializationError the
  # doors report: a part's or the layer's file rejects with a bare string (loadJSFilePromise), and only
  # here is it known that a file being restored needed it. Any other rejection is a bug in loading the
  # code, and stays one (the door rethrows it).
  @loadWhatItNeeds: (envelope) ->
    missingParts = world.parts.partsNeededFor @classNamesIn envelope
    if missingParts.length
      return world.parts.ensureAllLoaded(missingParts).catch (reason) ->
        throw reason unless typeof reason is "string"
        throw new SerializationError ("a part of Fizzygum it needs did not load (" + missingParts.join(", ") + "): " + reason), direction: "load"
    if @_needsTheReflectiveLayer envelope
      return ensureReflectiveLayerLoaded().catch (reason) ->
        throw reason unless typeof reason is "string"
        throw new SerializationError ("the class sources it needs did not load: " + reason), direction: "load"
    undefined

  # Does restoring this envelope need the reflective layer -- the class source text, and the member
  # maps the meta-system registers from it -- which has NOT loaded but still could? False wherever it
  # has loaded (a compile-at-boot page once booted, any page once something has asked for it) and on a
  # build that can never load it, so in practice a wait is paid only on a `sources: "lazy"` build, and
  # there only for a file that needs the layer:
  #   - one carrying class- or mixin-scope source edits, which are replayed against the meta-system;
  #   - one holding a widget whose class READS the member maps (`readsClassMemberMaps`, an inspector,
  #     which shows and edits a member's source: before the layer it would show compiled JS, and its
  #     edits would have no class record to go to). The declaration is read off the RESIDENT class of a
  #     record, so this is asked once the file's parts have arrived (loadWhatItNeeds' order).
  # The question is whether the layer has LOADED, not whether the meta-system is here: a lazy part's
  # load brings Class and Mixin in on their own (PartsRegistry._loadPartPromise), without the eager
  # classes' sources.
  @_needsTheReflectiveLayer: (envelope) ->
    return false if reflectiveLayerIsLoaded()
    return false unless reflectiveLayerCanLoad()
    replaysClassEdits = (envelope.world?.sourceEdits ? []).some (eachRecord) -> eachRecord.scope is "class" or eachRecord.scope is "mixin"
    holdsAMemberMapsReader = envelope.objects.some (record) -> record? and classNamed(record.class)?.prototype.readsClassMemberMaps is true
    replaysClassEdits or holdsAMemberMapsReader

  # What makes an envelope unrestorable WHOEVER restores it and whatever this build contains — a
  # clause in whyItCanNeverBeRestored's form, or undefined. Every record the Serializer writes
  # carries a non-empty string `class` (a class name or a tag), and @instantiate resolves nothing else,
  # so a record without one is a malformed table, not an unknown class.
  @_envelopeShapeProblem: (envelope) ->
    if envelope.formatVersion > Serializer.FORMAT_VERSION
      return "it is format version " + envelope.formatVersion + ", newer than this build understands (" +
        Serializer.FORMAT_VERSION + "). Update Fizzygum and retry"
    return "its object table is missing" unless Array.isArray envelope.objects
    for record, i in envelope.objects
      unless record? and typeof record.class is "string" and record.class.length
        return "its object table is malformed (entry " + i + " names no class)"
      # a world-set membership this build has no set for would be dropped by the restore: refused
      # here instead. An own-property test, because a marker is DATA read out of a file.
      for marker in (record.memberships or [])
        unless Object::hasOwnProperty.call Serializer.WORLD_SET_MEMBERSHIPS, marker
          return "its object table is malformed (entry " + i + " records a membership of '" + marker +
            "', a world set this build does not have)"
      refs = @_refsOf record
      # a {"$num"} carries a number JSON cannot write, by its text (Serializer.numberRef): one naming
      # any other would restore as no number at all
      for ref in refs when @_isNumberRef(ref) and !@_isNumberText ref.$num
        return "its object table is malformed (entry " + i + " holds " + @_shown(ref) + ", a number written as no number a save writes)"
      # where the format keeps NUMBERS -- a $Date's time, a Color's four components -- anything else
      # would build an invalid date or a black channel, or throw after a world load's teardown
      if (fieldProblem = @_numberFieldProblem record)?
        return "its object table is malformed (entry " + i + ": " + fieldProblem + ")"
      # a {"$src"} is a widget's injected method, the one function a save writes (Serializer's
      # encodeFunction), so it stands only as a property of a class record: one in a tag record -- an
      # $Array or $Set item, a $Map entry, an $Object property, any field of a Color -- is somewhere no
      # save puts one
      if @_tagBuilderFor(record.class)? and @_holdsFunctionSource refs
        return "its object table is malformed (entry " + i + " holds a method's source outside a widget)"
    # a well-known key no Fizzygum build writes would bind to nothing: refused here, before anything is
    # built (an app or class key naming a class this build lacks is not one: it is a known key, and
    # whyItCanNeverBeRestored refuses it as a class this build does not have)
    for key in Serializer.wellKnownKeysIn envelope
      return "it names the well-known object '" + key + "', which no Fizzygum build has" unless WellKnownObjects.isKnownKey key
    undefined

  # The class half of where a {"$src"} may stand, a clause in whyItCanNeverBeRestored's form or
  # undefined: a class record's props, the only field the load reads of one, hold none unless its
  # class takes injected methods (Serializer.classTakesInjectedMethods, the save's own test). It asks
  # the classes resident NOW and leaves a class still to arrive unjudged: both file doors ask again on
  # re-entering with their lazy parts loaded (loadWhatItNeeds), the world loader still before its
  # teardown, and @deserialize asks before pass 1.
  @_functionSourceOnANonWidget: (envelope) ->
    for record, i in envelope.objects when !@_tagBuilderFor(record.class)?
      klass = classNamed record.class
      continue unless klass? and !Serializer.classTakesInjectedMethods klass
      if @_holdsFunctionSource @_propRefsOf record
        return "it gives a method's source to a " + record.class + " (entry " + i + "), and only a widget takes one"
    undefined

  # The number a file's NUMBER stands for: itself, or the one a {"$num"} names by its text
  # (Serializer.numberRef). A text no save writes is refused before anything is built
  # (_envelopeShapeProblem), so this reads only a vetted file.
  @numberFrom: (ref) ->
    return ref if typeof ref is "number"
    for [text, value] in Serializer.NUMBERS_JSON_CANNOT_WRITE when text is ref.$num
      return value
    undefined

  @_isNumberText: (text) ->
    Serializer.NUMBERS_JSON_CANNOT_WRITE.some (pair) -> pair[0] is text

  # Is `value` the {"$num"} reference form? An own-property test, as for any key read out of a file:
  # a {"$num": null} is one too, and the vetting refuses its text.
  @_isNumberRef: (value) ->
    value? and typeof value is "object" and Object::hasOwnProperty.call value, "$num"

  # What is wrong with the NUMBERS a record keeps outside its references -- a $Date's time, a Color's
  # four components, each a number or a {"$num"} naming one -- as a clause, or undefined.
  @_numberFieldProblem: (record) ->
    isANumber = (value) => typeof value is "number" or (@_isNumberRef(value) and @_isNumberText value.$num)
    if record.class is "$Date" and !isANumber record.ms
      return "a $Date whose time is " + @_shown(record.ms) + ", where the format keeps a number"
    if record.class is "Color" and !(Array.isArray(record.rgba) and record.rgba.length is 4 and record.rgba.every isANumber)
      return "a Color whose rgba is " + @_shown(record.rgba) + ", where the format keeps four numbers"
    undefined

  # A value read out of a file, shown in a refusal: its JSON, cut short -- the message is a person's
  # to read, and an envelope handed in from code can hold what JSON cannot write (a cycle).
  @_shown: (value) ->
    try
      shown = JSON.stringify(value) ? String value
    catch
      shown = String value
    if shown.length > 60 then shown.slice(0, 60) + "…" else shown

  # Is one of `refs` a {"$src"}? Each is one reference form: the objects it names are records of their own.
  @_holdsFunctionSource: (refs) ->
    refs.some (ref) -> ref? and typeof ref is "object" and ref.$src?

  # The references a record carries: its items, its entries' keys and values, its props. A field of a
  # shape the format does not have (items that are not a list, an entry that is not a pair) carries none
  # here: this reads a record, it does not vet one, and its reader must answer for any file.
  @_refsOf: (record) ->
    refs = if Array.isArray record.items then record.items.slice() else []
    if Array.isArray record.entries
      refs.push entry... for entry in record.entries when Array.isArray entry
    refs.push @_propRefsOf(record)...
    refs

  @_propRefsOf: (record) ->
    return [] unless record.props? and typeof record.props is "object"
    (ref for own name, ref of record.props)

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
      build:    (record, asyncPromises) -> new Date Deserializer.numberFrom record.ms
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
      build:    (record, asyncPromises) -> Color.create (Deserializer.numberFrom component for component in record.rgba)...
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
    # both file doors refuse such a file before anything is built (whyItCanNeverBeRestored mirrors
    # this test); this throw is the net for every other caller
    throw SerializationError.forMissingClass record.class unless klass?
    Object.create klass.prototype

  # A same-world re-link token ({"$ext": uniqueID}) — used by the world snapshot's tolerant
  # pass. Resolve against the live world by unique-id string; undefined if absent.
  @resolveExternal: (uniqueID) ->
    return undefined unless world?
    world.topWdgtSuchThat? (w) -> w.uniqueIDString?() is uniqueID
