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
    # `resolve` is exposed so the world-snapshot loader resolves its `world` section's references
    # (children, bin, app windows, preferences) against the same table with the same reader -- one
    # resolver of the reference forms, never a second.
    whenReady = if asyncPromises.length then Promise.all(asyncPromises) else Promise.resolve()
    { widget: shells[envelope.root], whenReady: whenReady, resolve: resolveRef }

  # WHY THIS BUILD CAN NEVER RESTORE THIS ENVELOPE, as a clause to follow "cannot be loaded here: "
  # (no closing full stop), or undefined when it can. PURE — it only reads the envelope — which is
  # what lets both file doors ask it before anything changes (WorldWdgt.loadWorldSnapshot before its
  # teardown destroys the desktop, FileLoading's widget door before the first shell). It predicts
  # exactly the refusals @deserialize raises up front -- the same two helpers answer both, so the two
  # cannot drift: the envelope's shape (which also refuses what a restore would silently drop or get
  # wrong: each record's shape, each reference's form, memberships, a second record of one widget with
  # one id, a world file's section and its widgets' ids against their classes' counts, a widget file's
  # world section, a widget file's root), and
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
    for key in Deserializer.wellKnownKeysIn envelope
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
    for key in Deserializer.wellKnownKeysIn envelope
      add (WellKnownObjects.appNameInAppKey(key) ? WellKnownObjects.classNameInClassKey(key))
    names

  # WHAT THIS ENVELOPE NEEDS BEFORE IT CAN BE RESTORED, loaded. Answers undefined when it is all
  # resident -- every build the suite runs, so there the restore goes on INLINE, a world cycle no later
  # -- else a promise that resolves once the next thing has arrived, for the caller to RE-ENTER its
  # load on. One thing per trip, in this order, so the second is asked on the re-entry:
  #   1. the LAZY PARTS that own the classes it names (@classNamesIn), which are not defined until their
  #      part loads, and the code its class- and mixin-scope source edits name
  #      (SourceEditsRegistry.namesOfTheCodeEditedIn), which the replay edits only once it is there --
  #      an edit of a lazy part's code rides a file that holds none of that part's widgets. An edit
  #      whose code no part provides is no reason to refuse the file (its restore does not need it):
  #      the load tells the person the edits its replay did not apply (WorldWdgt.loadWorldSnapshot).
  #      A part an edit alone needs that FAILS to load fails the load, as one a widget needs does;
  #   2. the REFLECTIVE LAYER, when the file needs it (_needsTheReflectiveLayer), which reads a
  #      declaration off the classes step 1 brought in.
  # Both file doors ask it before anything changes -- WorldWdgt.loadWorldSnapshot before its teardown,
  # FileLoading's widget door before the first shell -- so a load that fails here leaves everything as
  # it was. A FILE THAT DID NOT ARRIVE is that load failing, and becomes a load SerializationError the
  # doors report: a part's or the layer's file rejects with a bare string (loadJSFilePromise), and only
  # here is it known that a file being restored needed it. Any other rejection is a bug in loading the
  # code, and stays one (the door rethrows it).
  @loadWhatItNeeds: (envelope) ->
    missingParts = world.parts.partsNeededFor @classNamesIn(envelope).concat SourceEditsRegistry.namesOfTheCodeEditedIn envelope?.world?.sourceEdits
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
    replaysClassEdits = (envelope.world?.sourceEdits ? []).some (eachRecord) -> SourceEditsRegistry.isClassLevel eachRecord
    holdsAMemberMapsReader = envelope.objects.some (record) -> record? and classNamed(record.class)?.prototype.readsClassMemberMaps is true
    replaysClassEdits or holdsAMemberMapsReader

  # What makes an envelope unrestorable WHOEVER restores it and whatever this build contains — a
  # clause in whyItCanNeverBeRestored's form, or undefined (its two id rules, which need the widget's class,
  # judge a class this page has; the door asks again once a lazy part's has arrived). Every record the Serializer writes
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
      # here instead. An own-property test, because a marker is DATA read out of a file. A save writes
      # memberships, a list, only for a widget (pass 4(b) re-adds the shell to each set, whose
      # consumers call widget methods on it).
      if record.memberships?
        unless Array.isArray(record.memberships) and !@_tagBuilderFor(record.class)? and @_couldBeAWidgetClass(record.class)
          return "its object table is malformed (entry " + i + " records memberships " + @_shown(record.memberships) +
            ", which a save writes only as a list, for a widget)"
        for marker in record.memberships
          unless Object::hasOwnProperty.call Serializer.WORLD_SET_MEMBERSHIPS, marker
            return "its object table is malformed (entry " + i + " records a membership of " + @_shown(marker) +
              ", a world set this build does not have)"
      # its SHAPE, as its tag states it (TAG_BUILDERS' shapeProblem) or as a class record's is -- a
      # malformed one would throw in its builder after a world load's teardown, or restore wrong
      shapeProblem = if (builder = @_tagBuilderFor record.class)? then builder.shapeProblem record else @_classRecordShapeProblem record
      return "its object table is malformed (entry " + i + ": " + shapeProblem + ")" if shapeProblem?
      # every reference it carries is one a save writes (_refProblem): any other restores as undefined,
      # or as itself, in silence
      refs = @_refsOf record
      for ref in refs when (refProblem = @_refProblem ref, envelope.objects.length)?
        return "its object table is malformed (entry " + i + " holds " + refProblem + ")"
      # a {"$src"} is a widget's injected method, the one function a save writes (Serializer's
      # encodeFunction), so it stands only as a property of a class record: one in a tag record -- an
      # $Array or $Set item, a $Map entry, an $Object property, any field of a Color -- is somewhere no
      # save puts one
      if @_tagBuilderFor(record.class)? and @_holdsFunctionSource refs
        return "its object table is malformed (entry " + i + " holds a method's source outside a widget)"
    # every record's identity is its own: a save writes each widget's iid once for its class, so a second
    # record of one class with one iid is somewhere no save puts one (a world load would restore two widgets
    # sharing a uniqueIDString, and an {"$ext"} would resolve to the last of them). Judged for a widget class
    # this page has: a name it lacks is refused by name after this (whyItCanNeverBeRestored), or judged when
    # its lazy part has arrived and the door re-enters
    seenIdentities = new Set
    for record, i in envelope.objects when record.iid? and classNamed(record.class)? and @_couldBeAWidgetClass(record.class)
      identity = record.class + "#" + record.iid
      return "its object table is malformed (entry " + i + " is a second " + identity + ")" if seenIdentities.has identity
      seenIdentities.add identity
    # a well-known key no Fizzygum build writes would bind to nothing: refused here, before anything is
    # built (an app or class key naming a class this build lacks is not one: it is a known key, and
    # whyItCanNeverBeRestored refuses it as a class this build does not have)
    for key in Deserializer.wellKnownKeysIn envelope
      return "it names the well-known object '" + key + "', which no Fizzygum build has" unless WellKnownObjects.isKnownKey key
    # a world file's section, which the world loader reads beside the table; a widget file carries none (no
    # widget save writes one), so neither the door's part loading nor its reflective-layer test reads source
    # edits that door never replays
    return "it carries a world section, which no widget file has" if envelope.kind isnt "world" and envelope.world?
    if envelope.world? and (sectionProblem = @_worldSectionProblem envelope.world, envelope.objects)?
      return "its world section is malformed (" + sectionProblem + ")"
    # a world file's widget record's iid is at most its class's count in the world's idCounters (absent: 0)
    # -- the save took the iid from that very counter, so one above it is an id a widget of its class built
    # after the load would take again. Every world file, with a section or without; after the section's own
    # shape, so a malformed idCounters is refused as that; and, as the identities are, for a widget class
    # this page has
    if envelope.kind is "world"
      counts = envelope.world?.idCounters ? {}
      for record, i in envelope.objects when record.iid? and classNamed(record.class)? and @_couldBeAWidgetClass(record.class)
        count = if Object::hasOwnProperty.call(counts, record.class) then counts[record.class] else 0
        if record.iid > count
          return "its object table is malformed (entry " + i + " is " + record.class + "#" + record.iid + ", above its class's count in the world's idCounters, " + count + ")"
    # a widget file's root, the widget its door adds to the world
    if envelope.kind isnt "world" and (rootProblem = @_recordReferenceProblem {$r: envelope.root}, envelope.objects, "a widget")?
      return "its root is malformed (" + rootProblem + ")"
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

  # A NUMBER as the format keeps it outside references (a $Date's time, a Color's components): itself,
  # or a {"$num"} naming one JSON cannot write.
  @_isANumber: (value) ->
    typeof value is "number" or (Deserializer._isNumberRef(value) and Deserializer._isNumberText value.$num)

  # A plain JSON object -- a record's `props`, a world section, a source-edit record -- and no list or null.
  @_isAPlainRecord: (value) ->
    value? and typeof value is "object" and !Array.isArray value

  # What is wrong with a value where the format puts a REFERENCE, as a clause, or undefined. A reference
  # is a scalar (a string, a number, a boolean; null stands for undefined), or an object holding exactly
  # one of the forms a save writes: {"$r": an index into the object table}, {"$wk"}, {"$ext"} or {"$src"}
  # a string, {"$num"} a text naming a number JSON cannot write. Any other object is no reference: its
  # restore would hand back undefined, or the object itself, in silence.
  @_refProblem: (value, objectCount) ->
    return undefined unless value? and typeof value is "object"
    keys = Object.keys value
    unless keys.length is 1 and keys[0] in ["$r", "$wk", "$ext", "$src", "$num"]
      return @_shown(value) + ", a reference form no save writes"
    switch keys[0]
      when "$r"
        return @_shown(value) + ", a reference to no entry of the table" unless Number.isInteger(value.$r) and 0 <= value.$r < objectCount
      when "$num"
        return @_shown(value) + ", a number written as no number a save writes" unless @_isNumberText value.$num
      else
        return @_shown(value) + ", a reference form no save writes" unless typeof value[keys[0]] is "string"
    undefined

  # What is wrong with a record's PROPS, as a clause, or undefined: an object, as a save writes one
  # (encodeOwnProps), with no own `__proto__` -- assigned, it would re-prototype the shell.
  @_propsProblem: (props) ->
    return "whose props are " + @_shown(props) + ", not an object" unless @_isAPlainRecord props
    return "whose props name __proto__, which no save writes" if Object::hasOwnProperty.call props, "__proto__"
    undefined

  # What is wrong with a CLASS record's own fields (a tag record states its shape in TAG_BUILDERS), as a
  # clause, or undefined: its props an object (a save always writes one), its iid a whole number.
  @_classRecordShapeProblem: (record) ->
    return "a " + @_shown(record.class) + " record " + problem if record.props? and (problem = @_propsProblem record.props)?
    return "a " + @_shown(record.class) + " record whose iid is " + @_shown(record.iid) + ", not a whole number" if record.iid? and !(Number.isInteger(record.iid) and record.iid >= 0)
    undefined

  # Could the class a record names be a WIDGET's? Yes for a widget class resident now; no for a tag or a
  # resident class that is no widget's; and yes for a name this page cannot judge yet -- a lazy part's,
  # judged when the file door re-enters with the part loaded (loadWhatItNeeds), or one no build has,
  # which whyItCanNeverBeRestored refuses by name.
  @_couldBeAWidgetClass: (className) ->
    return false if @_tagBuilderFor(className)?
    klass = classNamed className
    return true unless klass?
    # a class named by a file's record, judged before any instance exists: no widget answers for a class
    # it has not built, so this is a type test (check-stinks.js sanctions it)
    klass is Widget or klass.prototype instanceof Widget

  # What is wrong with a REFERENCE that must name a record of a given kind (a world section's widgets,
  # its bin, a widget file's root), as a clause, or undefined: a {"$r"} the reference check accepts
  # (_refProblem), to a record that is `wanted` -- "a widget" (_couldBeAWidgetClass), or the one class
  # its place holds.
  @_recordReferenceProblem: (value, objects, wanted) ->
    return problem if (problem = @_refProblem value, objects.length)?
    return @_shown(value) + ", not a reference to " + wanted + "'s record" unless @_isAPlainRecord(value) and value.$r?
    className = objects[value.$r]?.class
    fits = if wanted is "a widget" then @_couldBeAWidgetClass className else className is wanted
    return "a reference to " + @_shown(className) + ", not to " + wanted + "'s record" unless fits
    undefined

  # What is wrong with a world file's SECTION (Serializer.serializeWorld writes every field read here), as
  # a clause, or undefined: each widget it names a reference to a widget's record -- the bin a BinWdgt's,
  # the shelf a ShelfWdgt's, the preferences the PreferencesAndSettings record, the desktop colour a
  # Color's -- each plain field of the type the save writes, the info-doc flags only under their own
  # names (the load sets each one on the world), and the source-edit list record by record.
  @_worldSectionProblem: (section, objects) ->
    return "it is " + @_shown(section) + ", not an object" unless @_isAPlainRecord section
    holds = (where, value, wanted) =>
      problem = @_recordReferenceProblem value, objects, wanted
      if problem? then where + " holds " + problem else undefined
    if section.children?
      return ".children is " + @_shown(section.children) + ", not a list" unless Array.isArray section.children
      for child, i in section.children
        return problem if (problem = holds ".children[" + i + "]", child, "a widget")?
    for [field, wanted] in [["bin", "BinWdgt"], ["shelf", "ShelfWdgt"], ["preferences", "PreferencesAndSettings"], ["desktopColor", "Color"]] when section[field]?
      return problem if (problem = holds "." + field, section[field], wanted)?
    if section.appWindows?
      return ".appWindows is " + @_shown(section.appWindows) + ", not an object" unless @_isAPlainRecord section.appWindows
      for own appName, appWindow of section.appWindows
        return problem if (problem = holds ".appWindows[" + @_shown(appName) + "]", appWindow, "a widget")?
    return ".alpha is " + @_shown(section.alpha) + ", not a number" if section.alpha? and !Number.isFinite section.alpha
    return ".isDevMode is " + @_shown(section.isDevMode) + ", not true or false" if section.isDevMode? and typeof section.isDevMode isnt "boolean"
    return ".wallpaperPatternName is " + @_shown(section.wallpaperPatternName) + ", not a name" if section.wallpaperPatternName? and typeof section.wallpaperPatternName isnt "string"
    if section.infoDocFlags?
      return ".infoDocFlags is " + @_shown(section.infoDocFlags) + ", not an object" unless @_isAPlainRecord section.infoDocFlags
      for own name, flag of section.infoDocFlags when !(WorldWdgt.isInfoDocFlagName(name) and typeof flag is "boolean")
        return ".infoDocFlags[" + @_shown(name) + "] is " + @_shown(flag) + ", not an info-doc flag"
    if section.untitledNamingCounters?
      return ".untitledNamingCounters is " + @_shown(section.untitledNamingCounters) + ", not an object" unless @_isAPlainRecord section.untitledNamingCounters
      for own name, count of section.untitledNamingCounters when !(Number.isInteger(count) and count >= 0)
        return ".untitledNamingCounters[" + @_shown(name) + "] is " + @_shown(count) + ", not a count"
    if section.idCounters?
      return ".idCounters is " + @_shown(section.idCounters) + ", not an object" unless @_isAPlainRecord section.idCounters
      for own className, count of section.idCounters when !(Number.isInteger(count) and count >= 0)
        return ".idCounters[" + @_shown(className) + "] is " + @_shown(count) + ", not a count"
    if section.users?
      return ".users is " + @_shown(section.users) + ", not a list" unless Array.isArray section.users
      for user, i in section.users when !@_isAPlainRecord(user) or (user.armedDrawingTool? and typeof user.armedDrawingTool isnt "string")
        return ".users[" + i + "] is " + @_shown(user) + ", not a user's record"
    if section.sourceEdits?
      return ".sourceEdits is " + @_shown(section.sourceEdits) + ", not a list" unless Array.isArray section.sourceEdits
      for r, i in section.sourceEdits when !SourceEditsRegistry.isARecord r
        return ".sourceEdits[" + i + "] is " + @_shown(r) + ", not a source edit"
    undefined

  # A value read out of a file, shown in a refusal: its JSON, cut short -- the message is a person's
  # to read, and an envelope handed in from code can hold what JSON cannot write (a cycle) or what no
  # String() can show (a null-prototype object).
  @_shown: (value) ->
    try
      shown = JSON.stringify(value) ? String value
    catch
      try
        shown = String value
      catch
        shown = typeof value
    if shown.length > 60 then shown.slice(0, 60) + "…" else shown

  # Is one of `refs` a {"$src"}? Each is one reference form: the objects it names are records of their own.
  @_holdsFunctionSource: (refs) ->
    refs.some (ref) -> ref? and typeof ref is "object" and ref.$src?

  # Every `{"$wk": key}` key an envelope carries, in walk order and with repeats, read by POSITION -- where
  # the format puts a reference that can be one: each record's references (_refsOf: its items, its map
  # entries, the VALUES of its props -- never a props container, whose own keys are property names, "$wk"
  # among them if a run gave an object one). A reference is a single-key {"$wk": string}. (A world section
  # holds its widgets as {"$r"}s, which _worldSectionProblem holds it to, so it carries none.) A pure read of
  # the envelope: classNamesIn takes the app and class keys from it, and _envelopeShapeProblem refuses a
  # file carrying a key no build writes -- both before anything is changed.
  @wellKnownKeysIn: (envelope) ->
    keys = []
    isAReference = (value) -> value? and typeof value is "object" and typeof value.$wk is "string" and Object.keys(value).length is 1
    for record in (if Array.isArray envelope?.objects then envelope.objects else []) when record? and typeof record is "object"
      keys.push ref.$wk for ref in Deserializer._refsOf(record) when isAReference ref
    keys

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
  # Each entry also states the SHAPE its record must have (shapeProblem: a clause, or undefined), which
  # the refusal asks before anything is built (_envelopeShapeProblem), so a malformed record never
  # reaches a builder. Kept a simple literal for the fragment-compile gate: shapeProblem fns take
  # (record), build fns (record, asyncPromises), populate fns (shell, record, resolveRef); none uses `this`.
  # Read ONLY through @_tagBuilderFor below, never indexed directly.
  @TAG_BUILDERS:
    "$Array":
      shapeProblem: (record) -> if Array.isArray record.items then undefined else "an $Array whose items are " + Deserializer._shown(record.items) + ", not a list"
      build:    (record, asyncPromises) -> []
      populate: (shell, record, resolveRef) -> shell[j] = resolveRef(item) for item, j in record.items
    "$Object":
      shapeProblem: (record) -> if (problem = Deserializer._propsProblem record.props)? then "an $Object " + problem else undefined
      build:    (record, asyncPromises) -> {}
    "$Map":
      shapeProblem: (record) ->
        isAPair = (entry) -> Array.isArray(entry) and entry.length is 2
        if Array.isArray(record.entries) and record.entries.every(isAPair) then undefined else "a $Map whose entries are " + Deserializer._shown(record.entries) + ", not a list of pairs"
      build:    (record, asyncPromises) -> new Map
      populate: (shell, record, resolveRef) -> shell.set resolveRef(pair[0]), resolveRef(pair[1]) for pair in record.entries
    "$Set":
      shapeProblem: (record) -> if Array.isArray record.items then undefined else "a $Set whose items are " + Deserializer._shown(record.items) + ", not a list"
      build:    (record, asyncPromises) -> new Set
      populate: (shell, record, resolveRef) -> shell.add resolveRef(item) for item in record.items
    "$Date":
      shapeProblem: (record) -> if Deserializer._isANumber record.ms then undefined else "a $Date whose time is " + Deserializer._shown(record.ms) + ", where the format keeps a number"
      build:    (record, asyncPromises) -> new Date Deserializer.numberFrom record.ms
      populate: -> # fully built in pass 1 — nothing to populate
    "$Canvas":
      # what a save writes: the canvas's own size (non-negative integers), the saving page's ratio, a PNG data URL
      shapeProblem: (record) ->
        isASize = (n) -> Number.isInteger(n) and n >= 0
        return "a $Canvas whose size is " + Deserializer._shown([record.w, record.h]) + ", not two whole numbers" unless isASize(record.w) and isASize(record.h)
        return "a $Canvas whose pixel ratio is " + Deserializer._shown(record.pr) + ", not a positive number" if record.pr? and !(Number.isFinite(record.pr) and record.pr > 0)
        # a canvas with a zero side encodes as "data:," (toDataURL), any other as an image's data URL
        isItsData = typeof record.data is "string" and (/^data:image\//.test(record.data) or (record.data is "data:," and (record.w is 0 or record.h is 0)))
        return "a $Canvas whose data is " + Deserializer._shown(record.data) + ", not its image's data URL" unless isItsData
        undefined
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
      shapeProblem: (record) ->
        if Array.isArray(record.rgba) and record.rgba.length is 4 and record.rgba.every((component) -> Deserializer._isANumber component)
          undefined
        else
          "a Color whose rgba is " + Deserializer._shown(record.rgba) + ", where the format keeps four numbers"
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
