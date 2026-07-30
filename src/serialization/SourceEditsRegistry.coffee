# SourceEditsRegistry — a per-world log of in-world SOURCE edits, so a whole-world snapshot
# can carry them and replay them on restore. Lives at world.sourceEditsRegistry. See
# docs/architecture/serialization-duplication-reference.md §12.
#
# THREE scopes of edit, captured at the edit choke points:
#   - "instance": a single widget's method rewritten via the property inspector
#     (Widget.injectProperty). These ALSO ride the serializer for free — the widget carries a
#     `<name>_source` string, serialized as {"$src"} and re-injected on restore (§5). The
#     registry's marginal value here is auditability (a durable record of what was edited).
#   - "class": a class PROTOTYPE's method rewritten via the class inspector
#     (ClassInspectorWdgt.applyPropertyEdit → Class.applyMemberEdit). This is the ESSENTIAL
#     case: nothing else records it — a class edit mutates the live prototype but leaves no
#     serializable trace (§2.7). The snapshot embeds it and REPLAYS it against the destination
#     prototypes BEFORE deserialization, so restored shells (Object.create(prototype)) already
#     see the edited methods.
#   - "mixin": a mixin-donated member edited (Mixin.applyMemberEdit) or removed
#     (Mixin.removeMember, record flagged `deleted: true`) through the class inspector's donor
#     routing; replayed against the parsed mixins BEFORE the class-scope edits (boot-order
#     analogy: augmentWith runs before class-body assignments).
#
# A record is plain JSON: {scope, className|mixinName, uniqueID?, propertyName, source?,
# deleted?}. Embedded verbatim in the world envelope's `world.sourceEdits`.
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

  # record a mixin-scope edit (from ClassInspectorWdgt.applyPropertyEdit's mixin
  # routing; `mixinName` is the parsed Mixin's name, without the "Mixin" suffix;
  # `isStatic` true marks a class-side member -- replayed via applyStaticEdit).
  recordMixinEdit: (mixinName, propertyName, source, isStatic = false) ->
    return unless mixinName? and propertyName?
    record =
      scope: "mixin"
      mixinName: mixinName
      propertyName: propertyName
      source: source
    record.static = true if isStatic
    @records.push record
    return

  # record a mixin-scope member REMOVAL (from ClassInspectorWdgt's remove routing).
  recordMixinMemberRemoval: (mixinName, propertyName) ->
    return unless mixinName? and propertyName?
    @records.push
      scope: "mixin"
      mixinName: mixinName
      propertyName: propertyName
      deleted: true
    return

  # the plain-JSON records embedded in a world snapshot (shallow copies, so a later live edit
  # can't mutate an already-serialized array; the fields are all primitives).
  serializableRecords: ->
    (Object.assign {}, r) for r in @records

  # CAN THIS BUILD REPLAY class/mixin-scope edits at all? (arc 5)
  #
  # Both replays drive the META-SYSTEM -- Class.applyMemberEdit, Mixin.allMixines -- and the
  # meta-system is not in the pre-compiled image: Class and Mixin are the only two classes absent
  # from it (they are what compiled everything else), so they arrive only with the class SOURCE TEXT.
  # An artifact built with sources: "none" ships neither, and can therefore never replay these
  # records, no matter how long it waits.
  #
  # ⚠ This asks about the CAPABILITY, not the build flag, deliberately: it is the actual
  # precondition, it keeps a BUILDFLAG out of class code (no other class reads one), and it stays
  # correct for a future sources: "lazy" build, where the honest answer before the layer loads is
  # "not yet" rather than "never".
  @canReplaySourceEdits: -> Mixin?

  # How many records this build will NOT be able to replay -- so a load can say so ONCE, plainly,
  # instead of dropping the user's class edits without a word. (Instance-scope records are absent
  # from the count: they ride the {"$src"} path, which needs only the compiler, and every profile
  # ships that.)
  unreplayableSourceEditsCount: ->
    return 0 if SourceEditsRegistry.canReplaySourceEdits()
    (r for r in @records when r.scope is "class" or r.scope is "mixin").length

  # replay the CLASS-scope edits against the live prototypes: each re-runs
  # Class.applyMemberEdit — the same choke point the live class-inspector save uses,
  # so the replay compiles exactly what the session compiled (incl. the super
  # rewrite). Called by loadWorldSnapshot BEFORE deserialization, so a restored
  # shell already sees the edited methods. Instance-scope edits are NOT replayed
  # here — they ride the normal {"$src"} path on their own widget. A class edit
  # that no longer compiles (the class changed, a typo) is logged, not fatal.
  replayClassEdits: ->
    return unless SourceEditsRegistry.canReplaySourceEdits()
    for r in @records when r.scope is "class"
      theClass = window[r.className]?.class
      continue unless theClass?
      try
        theClass.applyMemberEdit r.propertyName, r.source
      catch error
        console?.log "world snapshot: class-scope source edit " + r.className + "." + r.propertyName + " could not be replayed: " + error.message
    return

  # replay the MIXIN-scope records IN ORDER: an edit re-runs Mixin.applyMemberEdit
  # (recompile + re-inject into every non-shadowing consumer class), a removal
  # (deleted: true) re-runs Mixin.removeMember -- record order matters so a
  # remove-then-re-add sequence lands in its final state. Called by the snapshot
  # restore BEFORE replayClassEdits -- the boot-order analogy: augmentWith runs
  # before class-body assignments, so a class-scope edit of the same member keeps
  # winning. A record whose mixin/member no longer compiles is logged, not fatal
  # (same policy as replayClassEdits).
  replayMixinEdits: ->
    # ⚠ Without this the very first line of the loop body would throw a bare `Mixin is not defined`
    # mid-restore -- it reads Mixin.allMixines OUTSIDE the per-record try/catch below.
    return unless SourceEditsRegistry.canReplaySourceEdits()
    for r in @records when r.scope is "mixin"
      theMixin = Mixin.allMixines.find (m) -> m.name is r.mixinName
      continue unless theMixin?
      try
        if r.deleted
          theMixin.removeMember r.propertyName
        else if r.static
          theMixin.applyStaticEdit r.propertyName, r.source
        else
          theMixin.applyMemberEdit r.propertyName, r.source
      catch error
        console?.log "world snapshot: mixin-scope source edit " + r.mixinName + "." + r.propertyName + " could not be replayed: " + error.message
    return

  # rebuild a registry from the records embedded in a loaded snapshot.
  @fromRecords: (records) ->
    registry = new SourceEditsRegistry
    registry.records = (records or []).slice()
    registry
