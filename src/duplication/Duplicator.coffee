# Duplicator — the DUPLICATION engine: clones a widget subtree (and the data
# structures it reaches) into live sibling objects. ONE instance per copy run:
# the run's identity bookkeeping (original -> clone) lives on the instance, so
# the walk's methods take just the value being copied.
#
# Serialization (src/serialization/Serializer) is the side-effect-free sibling
# of this walk: the two share the native-type taxonomy (NativeValueKinds) and
# per-class KNOWLEDGE (keptByReferenceOnDeepCopy, rebuildDerivedValue,
# getEmptyObjectOfSameTypeAsThisOne, _reactToBeingCopied) but no mutable state,
# so neither can regress the other.
# See docs/architecture/serialization-duplication-reference.md.
#
# Note 1: we deep-copy all kinds of data structures, not just widgets.
# Note 2: the copying mechanism also takes care of inserting the copied widget
# in whatever other data structures the original widget was in (the
# alignCopiedWidgetTo* hooks: broken rectangles, stepping, reference tracker,
# keyboard receivers).
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

  # PUBLIC entry: copy `value` (and everything it reaches) into a live sibling
  # structure.
  duplicate: (value) ->
    @_duplicate value

  # The dispatch core every handler recurses through. nil normalizes to nil;
  # boolean, number, bigint, string, symbol and function values ride along
  # uncopied.
  _duplicate: (value) ->
    return nil if !value?
    return value if typeof value isnt "object"

    return @clonesByOriginal.get value if @clonesByOriginal.has value

    if (value instanceof Widget) and !@widgetsInStructure.has value
      return value

    # native types, recognised through the same taxonomy the Serializer uses
    return @_copyArray value if NativeValueKinds.isArray value
    return @_copyMap value if NativeValueKinds.isMap value
    return @_copySet value if NativeValueKinds.isSet value
    return @_copyDate value if NativeValueKinds.isDate value
    return @_copyImage value if NativeValueKinds.isImage value
    return @_copyCanvas value if NativeValueKinds.isCanvasLike value
    return @_copyVideo value if NativeValueKinds.isVideo value
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
      cloneOfMe[i] = @_duplicate original[i] for i in [0...original.length]
      return

  # Map keys are address-like primitives (e.g. the spreadsheet SheetModel's
  # "A1" strings), copied as-is; values clone through the shared identity
  # bookkeeping like every other reference, so sharing and cycles are preserved.
  _copyMap: (original) ->
    @_copyWithIdentity original, (=> new Map), (cloneOfMe) =>
      original.forEach (value, key) => cloneOfMe.set key, @_duplicate value
      return

  _copySet: (original) ->
    @_copyWithIdentity original, (=> new Set), (cloneOfMe) =>
      original.forEach (value) => cloneOfMe.add @_duplicate value
      return

  _copyDate: (original) ->
    @_copyWithIdentity original, => new Date original.getTime()

  _copyImage: (original) ->
    @_copyWithIdentity original, =>
      cloneOfMe = new Image()
      cloneOfMe.src = original.src
      cloneOfMe

  _copyVideo: (original) ->
    @_copyWithIdentity original, =>
      cloneOfMe = document.createElement 'video'
      cloneOfMe.src = original.src
      cloneOfMe.autoplay = original.autoplay
      cloneOfMe.currentTime = original.currentTime
      cloneOfMe

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
  # simple the clone is NIL and users of gradients re-create them from scratch
  # when nil (search for "gradient" to see the pattern). Only the identity
  # mapping is registered, so the walk can move past them.
  _copyGradient: (original) ->
    @_copyWithIdentity original, => nil

  # ===== the generic walk (Fizzygum class instances and plain objects) =====

  _copyFizzygumObject: (obj) ->
    ctor = obj.constructor
    # closed-set guard (the Serializer carries the same one): only registered
    # Fizzygum classes and plain object literals take the generic walk —
    # anything else is a type the copier doesn't know, e.g. a collaborator
    # missing its keptByReferenceOnDeepCopy marker.
    unless ctor? and (ctor is Object or window[ctor.name] is ctor)
      console.error "Duplicator: cannot duplicate a value of unrecognized type (" + (ctor?.name or "no constructor") + ")"
      debugger
      throw new Error "Duplicator: cannot duplicate a value of unrecognized type"

    cloneOfMe = @_shellFor obj
    @clonesByOriginal.set obj, cloneOfMe
    # cloneOfMe at this point is just an "empty shell" copy
    @_cloneContentInto cloneOfMe, obj
    # cloneOfMe at this point is a full deep copy
    @_rebuildDerivedValues cloneOfMe, obj

    # align the copy into the world-level trackers the original was in (Note 2).
    obj.alignCopiedWidgetToBrokenInfoDataStructures? cloneOfMe
    obj.alignCopiedWidgetToSteppingStructures? cloneOfMe
    obj.alignCopiedWidgetToReferenceTracker? cloneOfMe
    obj.alignCopiedWidgetToKeyboardEventsReceiversSet? cloneOfMe

    # last chance for a widget to do other cleanup, for example a button that is
    # highlighted might want to un-highlight itself
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
    theClone = Object.create obj.constructor::
    # add to the instances tracking (only Widgets have that kind of tracking),
    # and although we don't run the constructor, at least initialise the clone
    # with its own fresh ID.
    theClone.registerThisInstance?()
    theClone.assignUniqueID?()
    theClone

  _cloneContentInto: (cloneOfMe, obj) ->
    # all the properties that are NOT static AND that are "attached" to the
    # object: inherited and non-inherited non-static properties that have been
    # re-assigned (the JS runtime has a copy-on-write mechanism when you change
    # the properties of an object). Also includes the "parent" property.
    for own property of obj
      value = obj[property]
      if !value?
        # undefined, null, nil
        cloneOfMe[property] = nil
      else if typeof value is "object"
        if value.rebuildDerivedValue?
          # a value that can be rebuilt after the cloning (e.g. a canvas
          # context): skip it — the rebuildDerivedValues pass below rebuilds it
          # on the clone.
          cloneOfMe[property] = nil
        else if value.keptByReferenceOnDeepCopy
          # A shared, world-level singleton (e.g. world.wallpaper,
          # world.widgetFactory): it is NOT part of the sub-structure being
          # copied, so a deep copy KEEPS THE REFERENCE rather than cloning it —
          # exactly as the dispatch core returns a Widget outside the structure as-is.
          cloneOfMe[property] = value
        else
          cloneOfMe[property] = @_duplicate value
      else
        # boolean, number, bigint, string, symbol and function — except the
        # clone's own fresh instanceNumericID, which must not be overwritten
        cloneOfMe[property] = value if property isnt "instanceNumericID"
    return

  # some variables such as canvas contexts are not copied, as they are derived
  # values, so we take care of fixing the temporaries here: for each property
  # whose ORIGINAL value knows how to rebuild itself (rebuildDerivedValue), have
  # it rebuild the value onto the clone.
  _rebuildDerivedValues: (cloneOfMe, theOriginal) ->
    for property of cloneOfMe
      if cloneOfMe.hasOwnProperty property
        if theOriginal[property]?.rebuildDerivedValue?
          theOriginal[property].rebuildDerivedValue cloneOfMe, property
    return
