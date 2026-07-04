# SourceEditsRegistry — a per-world log of in-world SOURCE edits, so a whole-world snapshot
# can carry them and replay them on restore. Lives at world.sourceEditsRegistry. See
# docs/serialization-duplication-reference.md §12.
#
# TWO scopes of edit, captured at the two edit choke points:
#   - "instance": a single widget's method rewritten via the property inspector
#     (Widget.injectProperty). These ALSO ride the serializer for free — the widget carries a
#     `<name>_source` string, serialized as {"$src"} and re-injected on restore (§5). The
#     registry's marginal value here is auditability (a durable record of what was edited).
#   - "class": a class PROTOTYPE's method rewritten via the class inspector
#     (ClassInspectorWdgt.applyPropertyEdit). This is the ESSENTIAL case: nothing else records
#     it — a class edit mutates the live prototype but leaves no serializable trace (§2.7). The
#     snapshot embeds it and REPLAYS it against the destination prototypes BEFORE deserialization,
#     so restored shells (Object.create(prototype)) already see the edited methods.
#
# A record is plain JSON: {scope, className, uniqueID?, propertyName, source}. Embedded verbatim
# in the world envelope's `world.sourceEdits`.
class SourceEditsRegistry

  constructor: ->
    @records = []

  # record an instance-scope edit (from Widget.injectProperty).
  recordInstanceEdit: (widget, propertyName, source) ->
    return unless widget? and propertyName?
    @records.push
      scope: "instance"
      className: widget.constructor?.name
      uniqueID: widget.uniqueIDString?()
      propertyName: propertyName
      source: source
    return

  # record a class-scope edit (from ClassInspectorWdgt.applyPropertyEdit; `classPrototype` is
  # the prototype the edit was evaluated against — its constructor is the class).
  recordClassEdit: (classPrototype, propertyName, source) ->
    return unless classPrototype? and propertyName?
    @records.push
      scope: "class"
      className: classPrototype.constructor?.name
      propertyName: propertyName
      source: source
    return

  # the plain-JSON records embedded in a world snapshot (shallow copies, so a later live edit
  # can't mutate an already-serialized array; the fields are all primitives).
  serializableRecords: ->
    (Object.assign {}, r) for r in @records

  # replay the CLASS-scope edits against the live prototypes. Called by loadWorldSnapshot
  # BEFORE deserialization, so a restored shell already sees the edited methods. Instance-scope
  # edits are NOT replayed here — they ride the normal {"$src"} path on their own widget. A
  # class edit that no longer compiles (the class changed, a typo) is logged, not fatal.
  replayClassEdits: ->
    for r in @records when r.scope is "class"
      klass = window[r.className]
      proto = klass?.prototype
      continue unless proto?.evaluateString?
      try
        proto.evaluateString "@" + r.propertyName + " = " + r.source
        proto[r.propertyName + "_source"] = r.source if Utils.isFunction proto[r.propertyName]
      catch error
        console?.log "world snapshot: class-scope source edit " + r.className + "." + r.propertyName + " could not be replayed: " + error.message
    return

  # rebuild a registry from the records embedded in a loaded snapshot.
  @fromRecords: (records) ->
    registry = new SourceEditsRegistry
    registry.records = (records or []).slice()
    registry
