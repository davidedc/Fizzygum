# SerializationError — the ONE loud failure the object-graph walkers raise: the serializer when it
# meets a reference it cannot faithfully encode (an out-of-structure pointer that is neither in the
# serialized subtree nor a well-known object) or a value it has no handler for (e.g. an own
# function-valued property whose function keeps no source -- Widget.keptSourceOf -- and no transient
# declaration), the deserializer when a file cannot be restored, and the Duplicator when a copy meets a
# value of a type it does not carry (its closed set). A save's and a copy's refusal name where the value is
# held alike, in the one path vocabulary below. See docs/architecture/serialization-duplication-reference.md.
#
# It is DELIBERATELY a plain class (NOT `extends Error`): the boot-time dependency
# finder (src/boot/dependencies-finding.coffee) treats an `extends X` target as a
# source-file dependency unless X is one of Set/Array/Map, so `extends Error` would
# inject a phantom "Error" into the load order. A plain class carries everything the
# catch sites and headless rigs need — a `.name`, a human `.message`, the structured
# `.path` / `.rootDescription` / `.offender` fields, a good `.toString()`, and a best-
# effort `.stack` captured from an inner Error — and `instanceof SerializationError`
# still works for catch discrimination.
#
# Fields:
#   rootDescription — the serialization root, e.g. "FrameWdgt#1"
#   path            — the property path from the root to the offending reference, e.g.
#                     "FrameWdgt#1 → .contents (SliderWdgt#5) → .target" (the path vocabulary below)
#   offender        — a description of the thing that could not be encoded, e.g.
#                     "StringWdgt#9, which is outside the serialized structure and not a
#                      well-known object"
#   remediation     — one or more hints on how to make the save succeed
#   direction       — "save" (the default: the Serializer's throws), "load" (the Deserializer's: a
#                     file this build cannot restore) or "copy" (the Duplicator's: a value a copy cannot
#                     carry). The class serves every direction, and this is what lets toString open with
#                     words that say which one failed
class SerializationError

  constructor: (@message = "serialization failed", details = {}) ->
    @name = "SerializationError"
    @rootDescription = details.rootDescription ? undefined
    @path = details.path ? undefined
    @offender = details.offender ? undefined
    @remediation = details.remediation ? undefined
    @direction = details.direction ? "save"
    # best-effort stack for debugging, without `extends Error`
    try
      @stack = (new Error @message).stack
    catch e
      @stack = undefined

  # A multi-line, human-readable rendering — this is what menu/file actions feed to
  # world.inform, and what a headless rig can snapshot. Structured callers read the
  # individual fields instead. The opening words follow @direction, so a refused or failed load
  # never reads as a failed save.
  toString: ->
    opening = switch @direction
      when "load" then "Cannot load this file: "
      when "copy" then "Cannot copy: "
      else "Cannot serialize: "
    parts = [opening + @message]
    parts.push "  root: " + @rootDescription if @rootDescription?
    parts.push "  at:   " + @path if @path?
    parts.push "  offending value: " + @offender if @offender?
    parts.push "  " + @remediation if @remediation?
    parts.join "\n"

  # A refusal's PATH, one vocabulary for both walkers, so the two spell the same route alike: the root (a widget by
  # its ID, the one a person finds it by; a world snapshot's is WORLD_ROOT), then each step the walk took -- into a
  # property, an Array's item, a record's key, a Map's key or value (a value named by its key when the key is a
  # string, a number or a boolean -- a sheet's cell by its address), a Set's item -- and a widget named as the walk
  # enters it. The Serializer writes a path as it descends; the Duplicator, only when a copy is refused, as the refusal
  # unwinds. (Which values each refuses differs: a copy walks the fields a save leaves out, @serializationTransients,
  # but for those its class's copy rebuilds, @copyTransients, and shares what a save refuses, a widget outside the
  # structure, a function -- reference doc §8.)
  @WORLD_ROOT: "the world"
  @pathRoot: (root) ->
    if root.uniqueIDString? then root.uniqueIDString() else (root.constructor?.name ? "an object with no prototype")
  @intoProperty: (name) -> " → ." + name
  @intoItem: (index) -> "[" + index + "]"
  @intoKey: (key) -> " → " + key
  @INTO_MAP_KEY: " (Map key)"
  # (a key is spelled as it reads: a string quoted -- cut past MAP_KEY_SHOWN characters --, a number as itself, NaN,
  # Infinity and -0 included, which JSON would write as null and 0)
  @MAP_KEY_SHOWN: 40
  @intoMapValue: (key) ->
    keyText = switch typeof key
      when "string"
        quoted = JSON.stringify key
        if quoted.length > SerializationError.MAP_KEY_SHOWN + 2 then quoted.slice(0, SerializationError.MAP_KEY_SHOWN + 1) + '…"' else quoted
      when "number" then (if key is 0 and 1 / key < 0 then "-0" else String key)
      when "boolean" then String key
    if keyText? then " (Map value at " + keyText + ")" else " (Map value)"
  @INTO_SET_ITEM: " (Set item)"
  @enteringWidget: (widget) -> " (" + widget.uniqueIDString() + ")"

  # The remedy when a walker refuses a value of a type it does not carry (the Serializer's closed set, the
  # Duplicator's): what a PERSON can do first -- an inspector on it, a field a run filled with it -- then what a
  # class author can, in the one form both walkers honour (a value its holder rebuilds, derived where its class
  # declares it: NativeValueKinds.isDerivedAt), so following it clears the save and the copy alike.
  @UNRECOGNIZED_TYPE_REMEDY: "If an inspector is open on it, close the inspector (open a new one for a second view); if a run put it in a field, remove that field with an inspector's Remove. If a class's own code keeps it in a field, make it a value its holder rebuilds: stamp a rebuildDerivedValue on it and declare that field in the class's @serializationTransients, so a save leaves it out and a copy rebuilds it."

  # The load error for a class a file names and this page cannot build: a record's class
  # (Deserializer.instantiate), a class key's or an app key's (WellKnownObjects.resolve). The words of
  # the file doors' refusal (Deserializer.whyItCanNeverBeRestored), and true ones: a class a LAZY part
  # of this build provides is missing only from the page, until its part loads. The file doors load
  # such a part first (Deserializer.loadWhatItNeeds), so that half is met only by a synchronous caller
  # (Widget.deserialize, a direct deserialize).
  @forMissingClass: (className) ->
    lack = if world?.parts?.canEverProvideClass className then "this page has not loaded" else "this build does not have"
    new SerializationError ("it uses " + className + ", which " + lack), direction: "load"
