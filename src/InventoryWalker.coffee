# InventoryWalker -- the PROPERTY walk of WorldInventory (docs/architecture/world-lifetime-and-inventory.md
# §2): it counts everything reachable from the roots it is given, by kind and by constructor, into the
# report it is handed, and meets the destroyed widgets still held on the way, each named by the
# property path that first reached it.
#
# ONE instance per inventory: the walk's bookkeeping -- what it has visited, the path that first
# reached each object, what it has yet to expand, the serializer transients it read per class, the
# zombies it met -- lives on the instance, so its methods take just the value they are given (the
# Duplicator's shape for a copy run). The instance is held by WorldInventory.takeInventory's frame
# and by nothing the walk can reach: a walker the walk reached would walk its own bookkeeping, which
# is why that bookkeeping is not kept on the WorldInventory (the harness holds that one on a class
# static, WorldWdgt._worldInventoryForAudit, where the walk reaches it).
#
# Read-only and side-effect-free: WorldInventory's header says what that means for the whole inventory.
class InventoryWalker

  constructor: (report) ->
    @_report = report
    # destroyed widgets the walk met, each with the path that names its retainer: [{id, path}, ...]
    @retainedZombies = []
    @_visited = new Set
    @_provenance = new Map   # object -> {parent, key}, only to name a zombie's retainer
    @_stack = []
    @_transientsByClass = new Map

  # "Class#id", read passively: instanceNumericID is assigned at construction
  @passiveIdOf: (aWidget) ->
    (aWidget.constructor?.name ? "?") + "#" + (aWidget.instanceNumericID ? "?")

  # the value of `object`'s own DATA property `name` -- undefined for an accessor (a getter may
  # compute: the walk never runs one) and for a property whose descriptor cannot be read. The one
  # reading of an own property wherever the inventory enumerates them: the properties of each object
  # the walk expands, each class's statics, the world's fields.
  @ownDataValueOf: (object, name) ->
    descriptor = undefined
    try
      descriptor = Object.getOwnPropertyDescriptor object, name
    return undefined unless descriptor? and !descriptor.get? and !descriptor.set?
    descriptor.value

  # a root of the walk, named by its key ("world", or "Class.static" for a class's own static); a
  # static's class is passed as its holder, and since a class is never itself reached, a path
  # prints it as <?>
  enqueueRoot: (value, key, parent) ->
    @_enqueue value, key, parent
    return

  # expands everything the roots reach
  walk: ->
    @_processValue @_stack.pop() while @_stack.length > 0
    return

  # the property path that first reached `value`, which names its retainer; undefined when the
  # walk never reached it
  pathOf: (value) ->
    return undefined unless @_provenance.has value
    parts = []
    cursor = value
    guard = 0
    while cursor? and guard++ < 300
      entry = @_provenance.get cursor
      if !entry?
        parts.unshift "<?>"
        break
      parts.unshift entry.key
      break unless entry.parent?
      cursor = entry.parent
    parts.join "."

  _count: (key, n) ->
    @_report[key] = (@_report[key] ? 0) + n
    return

  _enqueue: (value, key, parent) ->
    return unless value?
    type = typeof value
    if type is "string"
      @_count "strings.count", 1
      @_count "strings.chars", value.length
      return
    return if type is "number" or type is "boolean" or type is "symbol" or type is "bigint"
    if type is "function"
      @_count "objects.Function", 1
      return
    return if @_visited.has value
    @_visited.add value
    if NativeValueKinds.isBuffer value
      @_count "typedArrays.count", 1
      @_count "typedArrays.bytes", value.byteLength
      return
    @_provenance.set value, {parent: parent, key: key}
    @_stack.push value
    return

  # one reached object, by its kind: the window, the document, a canvas and a DOM node are
  # counted as leaves; a Map, a Set and an Array are expanded by their entries; anything else is
  # an object (_processObject). A value that throws as it is read counts in walker.errors.
  _processValue: (value) ->
    try
      if value is window
        @_count "objects.Window", 1
        return
      if value is document
        @_count "objects.Document", 1
        return
      isCanvasLike = false
      try
        isCanvasLike = typeof value.getContext is "function" and typeof value.toDataURL is "function"
      if isCanvasLike
        @_count "canvases.count", 1
        @_count "canvases.pixels", (value.width ? 0) * (value.height ? 0)
        return
      if window.Node? and value instanceof Node
        @_count "dom.nodes", 1
        return
      if NativeValueKinds.isMap value
        @_count "objects.Map", 1
        @_count "containers.mapEntries", value.size
        value.forEach (eachValue, eachKey) =>
          @_enqueue eachKey, "<mapKey>", value
          @_enqueue eachValue, "<mapValue>", value
        return
      if NativeValueKinds.isSet value
        @_count "objects.Set", 1
        @_count "containers.setEntries", value.size
        value.forEach (eachValue) => @_enqueue eachValue, "<setEntry>", value
        return
      if Array.isArray value
        @_count "objects.Array", 1
        @_count "containers.arrayElements", value.length
        for eachElement, i in value
          @_enqueue eachElement, "[" + i + "]", value
        return
      @_processObject value
    catch error
      @_count "walker.errors", 1
    return

  # an object: counted by its constructor's name, met as a zombie when it is a destroyed widget,
  # and expanded by its own DATA properties -- never a derived-state field, never a field its
  # class's serializer recomputes on restore, never an accessor
  _processObject: (value) ->
    ctor = undefined
    ctorName = "NoConstructor"
    try
      ctor = value.constructor
      ctorName = ctor.name if ctor?.name
    @_count "objects." + ctorName, 1
    if Widget? and value instanceof Widget and value.destroyed
      @retainedZombies.push {id: InventoryWalker.passiveIdOf(value), path: @pathOf(value)}
    transients = @_transientsOf ctor, ctorName
    for own name of value
      continue if Widget.isDerivedStateField name
      continue if transients?.has name
      @_enqueue InventoryWalker.ownDataValueOf(value, name), name, value
    return

  # the serializer's per-class transient declarations, merged up the chain -- those
  # fields are recomputed on restore, so retention through them is by design. Only a
  # Fizzygum class declares any: classNamed is the one test of that
  _transientsOf: (ctor, ctorName) ->
    return undefined unless ctor?
    return @_transientsByClass.get ctor if @_transientsByClass.has ctor
    found = undefined
    if Serializer? and classNamed(ctorName) is ctor
      try
        found = Serializer.transientsForClass ctor
    @_transientsByClass.set ctor, found
    found
