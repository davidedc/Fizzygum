# SerializationError — the ONE loud, path-carrying failure the serializer raises when
# it meets a reference it cannot faithfully encode (an out-of-structure pointer that is
# neither in the serialized subtree nor a well-known object), or a value it has no
# handler for (e.g. an own function-valued property with no `_source` sibling and no
# transient declaration). See docs/architecture/serialization-duplication-reference.md.
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
#                     "FrameWdgt#1 → .contents (SliderWdgt#5) → .target"
#   offender        — a description of the thing that could not be encoded, e.g.
#                     "StringWdgt#9, which is outside the serialized structure and not a
#                      well-known object"
#   remediation     — one or more hints on how to make the save succeed
class SerializationError

  constructor: (@message = "serialization failed", details = {}) ->
    @name = "SerializationError"
    @rootDescription = details.rootDescription ? nil
    @path = details.path ? nil
    @offender = details.offender ? nil
    @remediation = details.remediation ? nil
    # best-effort stack for debugging, without `extends Error`
    try
      @stack = (new Error @message).stack
    catch e
      @stack = nil

  # A multi-line, human-readable rendering — this is what menu/file actions feed to
  # world.inform, and what a headless rig can snapshot. Structured callers read the
  # individual fields instead.
  toString: ->
    parts = ["Cannot serialize: " + @message]
    parts.push "  root: " + @rootDescription if @rootDescription?
    parts.push "  at:   " + @path if @path?
    parts.push "  offending value: " + @offender if @offender?
    parts.push "  " + @remediation if @remediation?
    parts.join "\n"
