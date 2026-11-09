# SourceEditsRegistry — a per-world log of in-world SOURCE edits, so a whole-world snapshot
# can carry them and replay them on restore. Lives at world.sourceEditsRegistry. See
# docs/architecture/serialization-duplication-reference.md §12.
#
# THREE scopes of edit, captured at the edit choke points:
#   - "instance": a single widget's method rewritten via the property inspector
#     (Widget.injectProperty). These ALSO ride the serializer for free — the widget carries a
#     `<name>_source` string, serialized as {"$src"} and re-injected on restore (§5). The
#     registry's marginal value here is auditability (a durable record of what was edited).
#   - "class": a class PROTOTYPE's member edited (Class.applyMemberEdit) or removed
#     (Class.removeMember, record flagged `deleted: true`) through the class inspector's edit
#     steps (ClassInspectorWdgt). This is the ESSENTIAL case: nothing else records it — a class
#     edit mutates the live prototype but leaves no serializable trace (§2.7). The snapshot
#     embeds it and REPLAYS it against the destination prototypes BEFORE deserialization, so
#     restored shells (Object.create(prototype)) already see the edited methods.
#   - "mixin": a mixin-donated member edited (Mixin.applyMemberEdit) or removed
#     (Mixin.removeMember, record flagged `deleted: true`) through the class inspector's donor
#     routing; replayed against the parsed mixins BEFORE the class-scope edits (boot-order
#     analogy: augmentWith runs before class-body assignments).
# In both of the last two, an ADD is an edit whose source is "undefined", and a RENAME is two
# records: an edit under the new name, then a removal of the old. Each meta-object's member
# sources are its CURRENT ones and its consumers' prototypes follow from them (Class.coffee,
# "live member editing"), so replaying the records in order reproduces the session's live
# members exactly.
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

  # record a class-scope member REMOVAL (from ClassInspectorWdgt's class removal step; the
  # prototype names the class, as above).
  recordClassMemberRemoval: (classPrototype, propertyName) ->
    return unless classPrototype? and propertyName?
    @records.push
      scope: "class"
      className: classPrototype.constructor?.name
      propertyName: propertyName
      deleted: true
    return

  # record a mixin-scope edit (from ClassInspectorWdgt's mixin edit step; `mixinName` is the
  # parsed Mixin's name, without the "Mixin" suffix).
  recordMixinEdit: (mixinName, propertyName, source) ->
    return unless mixinName? and propertyName?
    @records.push
      scope: "mixin"
      mixinName: mixinName
      propertyName: propertyName
      source: source
    return

  # record a mixin-scope member REMOVAL (from ClassInspectorWdgt's mixin removal step).
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
  # from it (they are what compiled everything else), so they arrive only from the class source
  # directory -- with the reflective layer, or alone ahead of a lazy part's load. An artifact built
  # with sources: "none" ships neither, and can therefore never replay these records, no matter how
  # long it waits.
  #
  # ⚠ This asks about the CAPABILITY, not the build flag, deliberately: it is the actual
  # precondition, and it keeps a BUILDFLAG out of class code (no other class reads one). It is asked
  # once a load has brought the reflective layer in wherever it can come (Deserializer.loadWhatItNeeds,
  # before the replay), so by then `Mixin?` is false only where the layer can never arrive. Whether
  # the layer has ARRIVED is a different question, reflectiveLayerIsLoaded's: Class and Mixin alone
  # do not bring the eager classes' member maps.
  @canReplaySourceEdits: -> Mixin?

  # How many records this build will NOT be able to replay -- so a load can say so ONCE, plainly,
  # instead of dropping the user's class edits without a word. (Instance-scope records are absent
  # from the count: they ride the {"$src"} path, which needs only the compiler, and every profile
  # ships that.)
  unreplayableSourceEditsCount: ->
    return 0 if SourceEditsRegistry.canReplaySourceEdits()
    (r for r in @records when r.scope is "class" or r.scope is "mixin").length

  # replay the CLASS-scope records IN ORDER against the live prototypes: an edit re-runs
  # Class.applyMemberEdit, a removal (deleted: true) Class.removeMember — the same choke
  # points the live class inspector's steps use, so the replay compiles exactly what the
  # session compiled (incl. the super rewrite) and gives back a donor's member where the
  # session did. Called by loadWorldSnapshot BEFORE deserialization, so a restored
  # shell already sees the edited methods. Instance-scope edits are NOT replayed
  # here — they ride the normal {"$src"} path on their own widget. A class edit
  # that no longer compiles (the class changed, a typo) is logged, not fatal.
  replayClassEdits: ->
    return unless SourceEditsRegistry.canReplaySourceEdits()
    for r in @records when r.scope is "class"
      theClass = classNamed(r.className)?.class
      continue unless theClass?
      try
        if r.deleted
          theClass.removeMember r.propertyName
        else
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
      theMixin = Mixin.named r.mixinName
      continue unless theMixin?
      try
        if r.deleted
          theMixin.removeMember r.propertyName
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
