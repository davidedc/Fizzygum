# Duplicator — the DUPLICATION engine: clones a widget subtree (and the data
# structures it reaches) into live sibling objects. ONE instance per copy run:
# the run's identity bookkeeping (original -> clone) lives on the instance, so
# the walk's methods take just the value being copied.
#
# Serialization (src/serialization/Serializer) is the side-effect-free sibling
# of this walk: the two share the native-type taxonomy (NativeValueKinds) and
# per-class KNOWLEDGE (keptByReferenceOnDeepCopy, rebuildDerivedValue -- and through
# NativeValueKinds.isDerivedAt the @serializationTransients that say where a stamped value is
# derived -- getEmptyObjectOfSameTypeAsThisOne, _reactToBeingCopied) but no mutable state,
# so neither can regress the other.
# See docs/architecture/serialization-duplication-reference.md.
#
# Note 1: we deep-copy all kinds of data structures, not just widgets.
# Note 2: the copying mechanism also takes care of inserting the copied widget
# in whatever other data structures the original widget was in (the
# alignCopiedWidgetTo* hooks: damage rectangles, stepping, reference tracker,
# keyboard receivers).
# Note 3: a copy is BUILT WHOLE before anything outside it learns of it. Each widget shell's
# registration in its classes' instance sets (in the order the walk built the shells) and each
# object's alignment and last-chance hook (Note 2, _reactToBeingCopied; in the order the walk
# finished the objects, a child before its parent) wait, and run only once the walk has copied
# everything (duplicate). So a copy refused part-way -- a value of a type the copier does not
# know (_copyFizzygumObject's closed set) -- leaves no half-built widget in an instance set, the
# stepping set, a damage list or the keyboard receivers. (Its shells did take fresh IDs.)
# Note 4: a refusal names where the refused value is held, as a save's does, in SerializationError's one path
# vocabulary: each step the walk took to reach it -- a property, an Array's item, a Map's value, a Set's item, a widget
# of the copy entered -- is told to the refusal as it unwinds through that step (_refusalThrough), and duplicate names
# the root. A copy that is not refused builds no path.
# Note 5: a field a class names in its @copyTransients (merged up the chain, as @serializationTransients is) is LEFT
# OUT of the copy -- the clone holds none of its own -- because the copy rebuilds it: a sheet's cell records' derived
# fields, which the copied sheet recommits (SimpleSpreadsheetWdgt._reactToBeingCopied marks every cell stale, and the
# next drain computes each value). The walk never meets their values, so a value of a type it does not carry, there,
# refuses nothing. It is the class's statement, field by field, never a blanket "a copy leaves out what a save leaves
# out": a save's transients are rebuilt by a LOAD's paths (_afterDeserialization, the stepping loop's re-seed), and a
# copy runs other hooks, so a field joins only where its class's copy rebuilds it. (A record copied WITHOUT its sheet --
# an inspector on a sheet's model, duplicated -- has nothing to rebuild them, and holds none.)
class Duplicator

  constructor: (allWidgetsInStructure) ->
    # the widgets that count as "in-structure": a Widget OUTSIDE this set is an
    # external collaborator, and the duplicate KEEPS the live reference (so a
    # copied widget can stay wired to a widget outside the copy). Serialization,
    # which cannot keep a live pointer, handles that case separately.
    @widgetsInStructure = new Set allWidgetsInStructure
    # original -> clone, identity-keyed: the one place cycle/sharing bookkeeping
    # lives, shared by every handler below.
    @clonesByOriginal = new Map
    # what waits for the walk to finish (Note 3): the widget shells to register, in the order they
    # were built, and each object's alignment and last-chance hook, in the order it was finished
    @_shellsToRegister = []
    @_finishings = []
    # class -> the fields its copy rebuilds (Note 5), read once per class
    @_copyTransientsByClass = new Map

  # PUBLIC entry: copy `value` (and everything it reaches) into a live sibling
  # structure. A refusal names `value` as its root, the path from it in front (Note 4).
  duplicate: (value) ->
    try
      copy = @_duplicate value
    catch err
      if err?.direction is "copy"
        err.rootDescription = SerializationError.pathRoot value
        err.path = err.rootDescription + (err.path ? "")
      throw err
    # the whole copy is built: now the world learns of it (Note 3)
    shell.registerThisInstance() for shell in @_shellsToRegister
    finish() for finish in @_finishings
    copy

  # PUBLIC lookup after a run: the clone made for `original` (undefined if the walk never
  # reached it). Widget.fullCopy uses this to find the fresh copies of the referent figures
  # its arrow-contract closure contributed, to file them to the shelf.
  cloneOf: (original) ->
    @clonesByOriginal.get original

  # The dispatch core every handler recurses through. undefined normalizes to undefined;
  # boolean, number, bigint, string, symbol and function values ride along
  # uncopied (a widget's INJECTED method is then compiled afresh on its copy: _compileInjectedMethods).
  _duplicate: (value) ->
    return undefined if !value?
    return value if typeof value isnt "object"

    return @clonesByOriginal.get value if @clonesByOriginal.has value

    # a class's own prototype belongs to the page, not to the copy: shared, the Serializer's same fact
    # (it names one by its class, WellKnownObjects.classKeyFor). Asked before the widget rule below,
    # because a Widget-branch prototype is `instanceof Widget`, and a non-widget one would otherwise be
    # copied into an object posing as its class's prototype. (A class FUNCTION rides along uncopied,
    # as every function does, above.)
    return value if isAClassPrototype value

    if (value instanceof Widget) and !@widgetsInStructure.has value
      return value

    # a value its holder rebuilds (it answers rebuildDerivedValue: a canvas context, a 3D pane's
    # runtime) reached anywhere but where that holder rebuilds it -- an inspector's subject, a cache's
    # slot -- is a page object outside the copied structure, kept by reference as an outside widget is.
    # One where its holder rebuilds it is DERIVED there and never reaches this walk (_cloneContentInto
    # asks NativeValueKinds.isDerivedAt first).
    return value if NativeValueKinds.rebuildsItself value

    # native types, recognised through the same taxonomy the Serializer uses (two of its predicates, the
    # buffer's and the gradient's, only the copier asks)
    return @_copyArray value if NativeValueKinds.isArray value
    return @_copyBuffer value if NativeValueKinds.isBuffer value
    return @_copyMap value if NativeValueKinds.isMap value
    return @_copySet value if NativeValueKinds.isSet value
    return @_copyDate value if NativeValueKinds.isDate value
    # an element the page loads (an image, a video) is a PAGE FACT derived from its holder's own path,
    # and the holder re-makes it, with its load handlers, in _reactToBeingCopied: nothing is copied and
    # the clone's field is left undefined -- the treatment a derived value gets. A copied element
    # would carry none of the original's handlers, so a copy could claim a load it never made.
    return undefined if NativeValueKinds.isImage(value) or NativeValueKinds.isVideo(value)
    return @_copyCanvas value if NativeValueKinds.isCanvasLike value
    return @_copyGradient value if NativeValueKinds.isGradientLike value

    @_copyFizzygumObject value

  # ===== identity registration =====

  # Clone with identity registration. buildEmpty creates the clone; populate
  # (optional) fills a CONTAINER only after the clone is registered, so a cyclic
  # reference back to the original resolves to the (partially-built) clone. Leaf
  # types (whose whole clone is built by buildEmpty) pass no populate.
  _copyWithIdentity: (original, buildEmpty, populate) ->
    cloneOfMe = buildEmpty()
    @clonesByOriginal.set original, cloneOfMe
    populate? cloneOfMe
    cloneOfMe

  # ===== native-type handlers =====

  _copyArray: (original) ->
    @_copyWithIdentity original, (=> []), (cloneOfMe) =>
      for i in [0...original.length]
        try
          cloneOfMe[i] = @_duplicate original[i]
        catch err
          throw @_refusalThrough err, (SerializationError.intoItem i), original[i]
      return

  # A buffer is DATA, copied as an Array is: an ArrayBuffer byte for byte, and a view onto one (a typed
  # array, a DataView) rebuilt over the COPY of its buffer, at the same offset and length, by its own
  # kind's constructor. The buffer goes through the identity bookkeeping, so views that share one buffer
  # in the original share one buffer in the copy, as they did -- and so a view copies its WHOLE buffer,
  # however small the view.
  _copyBuffer: (original) ->
    return @_copyWithIdentity original, (=> original.slice 0) unless NativeValueKinds.isBufferView original
    bufferOfTheCopy = @_duplicate original.buffer
    Kind = original.constructor
    @_copyWithIdentity original, =>
      if Kind.BYTES_PER_ELEMENT?
        new Kind bufferOfTheCopy, original.byteOffset, original.length
      else
        new Kind bufferOfTheCopy, original.byteOffset, original.byteLength

  # Map keys are address-like primitives (e.g. the spreadsheet SheetModel's
  # "A1" strings), copied as-is; values clone through the shared identity
  # bookkeeping like every other reference, so sharing and cycles are preserved.
  _copyMap: (original) ->
    @_copyWithIdentity original, (=> new Map), (cloneOfMe) =>
      original.forEach (value, key) =>
        try
          cloneOfMe.set key, @_duplicate value
        catch err
          throw @_refusalThrough err, (SerializationError.intoMapValue key), value
      return

  _copySet: (original) ->
    @_copyWithIdentity original, (=> new Set), (cloneOfMe) =>
      original.forEach (value) =>
        try
          cloneOfMe.add @_duplicate value
        catch err
          throw @_refusalThrough err, SerializationError.INTO_SET_ITEM, value
      return

  _copyDate: (original) ->
    @_copyWithIdentity original, => new Date original.getTime()

  _copyCanvas: (original) ->
    @_copyWithIdentity original, =>
      # width and height here are not the widget's, which would be in logical
      # units and hence would need ceilPixelRatio correction, but in actual
      # physical units i.e. the actual buffer size. Under the SWCanvas backend
      # the factory yields an SWCanvasElement, so an SWCanvas original clones
      # into an SWCanvas clone (getContext/drawImage supported on both).
      cloneOfMe = HTMLCanvasElement.createOfPhysicalDimensions new Point original.width, original.height
      ctx = cloneOfMe.getContext "2d"
      ctx.drawImage original, 0, 0
      cloneOfMe

  # Canvas gradients might be tied to a specific context, so to keep things
  # simple the clone is UNDEFINED and users of gradients re-create them from scratch
  # when undefined (search for "gradient" to see the pattern). Only the identity
  # mapping is registered, so the walk can move past them.
  _copyGradient: (original) ->
    @_copyWithIdentity original, => undefined

  # ===== the generic walk (Fizzygum class instances and plain objects) =====

  _copyFizzygumObject: (obj) ->
    ctor = obj.constructor
    # THE CLOSED SET, the same rule as the Serializer's generic branch: a plain object (an object
    # literal, or one with no prototype -- a class's member stores are made so), or an instance of the
    # class classNamed answers for its constructor's name. Anything else is a type the copier does not
    # know -- an instance of a browser-native class the dispatch above has no handler for (a DOMRect),
    # or of a vendored engine's (an SWCanvas surface an inspector was opened on) -- and is REFUSED
    # here, never cloned into a shell of its prototype that carries none of its internal state: the
    # walkers' one refusal, as the save's closed set refuses it, which the copy's gesture tells the
    # person (Widget.fullCopy). Nothing the walk built so far reaches the world (Note 3).
    unless !ctor? or ctor is Object or classNamed(ctor.name) is ctor
      throw new SerializationError ("a value of an unrecognized type (" + ctor.name + ") cannot be copied"),
        direction: "copy", offender: "an instance of " + ctor.name, remediation: SerializationError.UNRECOGNIZED_TYPE_REMEDY

    cloneOfMe = @_shellFor obj
    @clonesByOriginal.set obj, cloneOfMe
    # cloneOfMe at this point is just an "empty shell" copy
    @_cloneContentInto cloneOfMe, obj
    # cloneOfMe at this point is a full deep copy
    @_rebuildDerivedValues cloneOfMe, obj
    @_compileInjectedMethods cloneOfMe

    # once the whole copy is built (Note 3): align the copy into the world-level trackers the original
    # was in (Note 2), then give it a last chance to do other cleanup, for example a viewport ends a
    # scroll step that is still bound to the original (ViewportWdgt._reactToBeingCopied)
    @_finishings.push =>
      obj.alignCopiedWidgetToDamageInfoDataStructures? cloneOfMe
      obj.alignCopiedWidgetToSteppingStructures? cloneOfMe
      obj.alignCopiedWidgetToReferenceTracker? cloneOfMe
      obj.alignCopiedWidgetToKeyboardEventsReceiversSet? cloneOfMe
      cloneOfMe._reactToBeingCopied?()

    cloneOfMe

  # Creates a new instance of obj's type. A class that clones as ITSELF
  # (immutables — Color) declares that with a getEmptyObjectOfSameTypeAsThisOne
  # override; the engine consults it here. Note that for the generic shell
  #   1) the constructor is not run
  #   2) debuggers show these instances as "Object" even though their prototype
  #      is of the right type, so all is good there
  #   3) the shell has the same type but none of the properties yet.
  _shellFor: (obj) ->
    return obj.getEmptyObjectOfSameTypeAsThisOne() if obj.getEmptyObjectOfSameTypeAsThisOne?
    # a prototype-less object (a plain object made with Object.create null) copies as one
    theClone = Object.create (if obj.constructor? then obj.constructor.prototype else null)
    # add to the instances tracking (only Widgets have that kind of tracking) once the
    # whole copy is built (Note 3), and although we don't run the constructor, at least
    # initialise the clone with its own fresh ID.
    @_shellsToRegister.push theClone if theClone.registerThisInstance?
    theClone.assignUniqueID?()
    theClone

  _cloneContentInto: (cloneOfMe, obj) ->
    # all the properties that are NOT static AND that are "attached" to the
    # object: inherited and non-inherited non-static properties that have been
    # re-assigned (the JS runtime has a copy-on-write mechanism when you change
    # the properties of an object). Also includes the "parent" property.
    for own property of obj
      # DERIVED STATE is NEVER copied (Widget.isDerivedStateField, the one rule the Serializer and
      # WorldInventory read too): the version-keyed cache pairs, left unset, re-derive on first
      # read -- a field-copied one arrives stamped at the CURRENT version yet holds the ORIGINAL's
      # value (the settle leg's CACHED_DERIVATION_DIVERGED rider measures it); and the island
      # source-lane stash persists until a damage flush consumes it, so a copy CAN observe a live
      # one, and with the island OUTSIDE the copied structure the clone's first damage flush would
      # deposit a false "vacated" rect onto a buffer it never painted into and pin the island.
      continue if Widget.isDerivedStateField property
      value = obj[property]
      try
        @_clonePropertyInto cloneOfMe, obj, property, value
      catch err
        throw @_refusalThrough err, (SerializationError.intoProperty property), value
    return

  # One own property of the original onto its clone: _cloneContentInto's step, apart so a refusal met under it is
  # told the property (Note 4).
  _clonePropertyInto: (cloneOfMe, obj, property, value) ->
    # a field the class's copy rebuilds is left out (Note 5)
    return if @_copyRebuilds obj, property
    # A widget's PARENT is a structural link, written here directly rather than through
    # TreeNode._addChild, so it is ANNOUNCED as _addChild announces it (noteStructureChange): a tree
    # derivation cached while the walk links its widgets (root, the first clipping parent) must not
    # be read again once the copy is whole.
    #   A ROOT of the copy -- a widget whose parent is outside the copied structure -- comes back
    # DETACHED, never pointing at a parent that does not hold it: the serializer's detach-root rule
    # (serialization-duplication-reference.md §4), one fact for both walkers. Its caller places it
    # (adds it, carries it, files it to the shelf); until then it is an orphan, so nothing done to
    # it reaches the tree its original stands in, and nothing reads that tree as where it came from.
    if property is "parent" and (value instanceof Widget)
      cloneOfMe.parent = if @widgetsInStructure.has value then @_duplicate value else undefined
      WorldWdgt.noteStructureChange()
      return
    if !value?
      # undefined, null, undefined
      cloneOfMe[property] = undefined
    else if typeof value is "object"
      if NativeValueKinds.isDerivedAt obj, property
        # a value DERIVED here (a canvas context beside its canvas, a stamped runtime value in a transient field): skip it -- the
        # _rebuildDerivedValues pass below rebuilds it on the clone.
        cloneOfMe[property] = undefined
      else if value.keptByReferenceOnDeepCopy
        # Kept by reference, two kinds: a shared world-level singleton (e.g.
        # world.wallpaper, world.widgetFactory) is NOT part of the sub-structure
        # being copied — exactly as the dispatch core returns a Widget outside the
        # structure as-is; and an immutable value (Point, Rectangle, ShadowInfo,
        # TransformSpec, SheetError) never changes, so sharing it is invisible.
        # See docs/architecture/immutable-value-classes.md.
        cloneOfMe[property] = value
      else
        cloneOfMe[property] = @_duplicate value
    else
      # boolean, number, bigint, string, symbol and function — except the
      # clone's own fresh instanceNumericID, which must not be overwritten
      cloneOfMe[property] = value if property isnt "instanceNumericID"
    return

  # Does `obj`'s class name `property` among the fields its copy rebuilds (@copyTransients, Note 5)?
  _copyRebuilds: (obj, property) ->
    klass = obj.constructor
    return false unless klass?
    unless @_copyTransientsByClass.has klass
      @_copyTransientsByClass.set klass, new Set classStaticListMergedUpTheChain klass, "copyTransients"
    @_copyTransientsByClass.get(klass).has property

  # A copy refusal unwinding through a step the walk took is told that step, in front of the path it carries so far --
  # and the value the step reached named, as a save names it, when it is a widget of the copy (Note 4). Anything else
  # thrown passes as it is.
  _refusalThrough: (err, step, value) ->
    if err?.direction is "copy"
      entered = if @widgetsInStructure.has value then SerializationError.enteringWidget value else ""
      err.path = step + entered + (err.path ? "")
    err

  # A DERIVED value (NativeValueKinds.isDerivedAt: a canvas context beside its canvas, a stamped runtime value in a transient field) is not copied:
  # for each property derived on the ORIGINAL, its value rebuilds itself onto the clone
  # (rebuildDerivedValue).
  _rebuildDerivedValues: (cloneOfMe, theOriginal) ->
    # `for own` (a hasOwnProperty borrowed from Object, never asked of the clone): a prototype-less
    # clone has none of its own
    for own property of cloneOfMe
      if NativeValueKinds.isDerivedAt theOriginal, property
        theOriginal[property].rebuildDerivedValue cloneOfMe, property
    return

  # A widget's INJECTED method (Widget.injectProperty, kept with its source: Widget.keptSourceOf) is compiled
  # afresh on the copy, from that source and with the copy's own injectProperty -- as a load compiles each
  # {"$src"} (Deserializer, pass 4): every own field of a widget (Serializer.classTakesInjectedMethods) that
  # holds a function with a kept source, the fields a save writes a {"$src"} for and, since a copy keeps
  # a @serializationTransients field a save drops (unless the class names it in @copyTransients), such a
  # one too. Shared, a fat-arrow method
  # (`=> @x`) is one function BOUND to the widget that compiled it, so the copy's would run on the original;
  # compiled here, it binds the copy, and a thin-arrow one is simply a function of its own.
  _compileInjectedMethods: (cloneOfMe) ->
    return unless Serializer.classTakesInjectedMethods cloneOfMe.constructor
    for own property, value of cloneOfMe
      keptSource = Widget.keptSourceOf value
      cloneOfMe.injectProperty property, keptSource if typeof keptSource is "string"
    return
