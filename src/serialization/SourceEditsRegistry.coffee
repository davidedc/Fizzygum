# SourceEditsRegistry — a per-world log of in-world SOURCE edits, so a whole-world snapshot
# can carry them and replay them on restore. Lives at world.sourceEditsRegistry. See
# docs/architecture/serialization-duplication-reference.md §12.
#
# THREE scopes of edit, each recorded by the person's GESTURE that makes it, never by the verb it
# drives (the product calls those verbs as plumbing too, which no one edited):
#   - "instance": a single widget's method rewritten by the object inspector's Save
#     (InspectorWdgt.applyPropertyEdit). These ALSO ride the serializer for free — the injected function
#     keeps its source (Widget.keptSourceOf), serialized as {"$src"} and re-injected on restore (§5). The
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
# "live member editing"), so replaying the records in order, from boot, reproduces the session's
# live members exactly -- and a load first returns the page to boot (returnThePageToBootSources).
#
# A record is plain JSON: {scope, className|mixinName, uniqueID?, propertyName, source?,
# deleted?}. Embedded verbatim in the world envelope's `world.sourceEdits`.
class SourceEditsRegistry

  constructor: ->
    @records = []

  # record an instance-scope edit (from the object inspector's Save, InspectorWdgt.applyPropertyEdit).
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

  # Is `r` a record as my writers above write one (and serializableRecords hands a save): a plain object
  # with its scope, the code it names -- a class's name, a mixin's parsed name, an instance edit's class
  # (with the widget's unique id where it had one) -- the member, and the source unless it is a
  # removal. Asked of every record a world file carries, before the load changes anything
  # (Deserializer._worldSectionProblem).
  @isARecord: (r) ->
    return false unless r? and typeof r is "object" and !Array.isArray r
    isAName = (value) -> typeof value is "string" and value.length > 0
    namesItsCode = switch r.scope
      when "class" then isAName r.className
      when "mixin" then isAName r.mixinName
      when "instance" then isAName(r.className) and (!r.uniqueID? or typeof r.uniqueID is "string")
      else false
    namesItsCode and isAName(r.propertyName) and (r.deleted is true or typeof r.source is "string")

  # Is `record` CLASS-LEVEL -- a class- or mixin-scope one, which the replays apply against the
  # meta-system? (An instance-scope one rides the {"$src"} path on its own widget, which needs only the
  # compiler, and every profile ships that.)
  @isClassLevel: (record) ->
    record?.scope is "class" or record?.scope is "mixin"

  # How many class-level records I hold: what a load's replays would apply, so the load can tell the
  # user, once, how many of them it did not (WorldWdgt.loadWorldSnapshot).
  classLevelRecordCount: ->
    (r for r in @records when SourceEditsRegistry.isClassLevel r).length

  # The code the class-level records of a world file name, by the names the build's part manifest
  # holds them by -- a class's name, and a mixin's source name: a record holds the parsed one
  # ("Highlightable", whose source and global are "HighlightableMixin"), and either spelling is taken,
  # as Mixin.named takes either (a name no part holds is passed over). What the parts pre-load brings in
  # before the replay (Deserializer.loadWhatItNeeds), so an edit of a lazy part's code finds its class
  # or mixin even when the file holds none of that part's widgets.
  @namesOfTheCodeEditedIn: (records) ->
    names = []
    add = (name) -> names.push name if typeof name is "string" and name not in names
    for r in (records ? [])
      if r?.scope is "class"
        add r.className
      else if r?.scope is "mixin" and typeof r.mixinName is "string"
        add r.mixinName
        add r.mixinName + "Mixin"
    names

  # THE PAGE AS IT BOOTED, which a replay starts from: the records reproduce a session's members from
  # boot (above), so a world-snapshot load first returns every meta-object to its boot sources. Each
  # member whose source differs from the one the meta-object's source text at boot gives (Class /
  # Mixin bootMemberSources, Class.membersAwayFrom) gets that one back through the meta-object's own
  # two edits, which keep every prototype a function of the stores -- so the members come back as
  # boot made them, a class member's removal giving back its donor's (mixins go first, in boot's own
  # order). What the page edited is read from the STORES, never from a registry: a world's registry
  # lists the edits made under it, while the prototypes are the page's, and a world built on an edited
  # page (the harness's resetWorld) starts with none. A class or mixin the vault holds no source text
  # for (one made at run time) has no boot and is left as it is. A member that cannot be returned is
  # logged and left, as a record that cannot be replayed is: the load has already torn the desktop
  # down, and tells the user how many of them still run once the replay is done (@stillRunning,
  # WorldWdgt.loadWorldSnapshot). Answers {returned, unreturned}: how many members it returned, and
  # each one it left, with the source it was left running (undefined for a member the page removed);
  # 0 and none where this build has no meta-system (canReplaySourceEdits).
  @returnThePageToBootSources: ->
    returned = 0
    unreturned = []
    for metaObject in SourceEditsRegistry._metaObjectsInBootOrder()
      bootSources = metaObject.bootMemberSources()
      continue unless bootSources?
      for memberName in Class.membersAwayFrom metaObject.nonStaticPropertiesSources, bootSources
        try
          if Object::hasOwnProperty.call bootSources, memberName
            metaObject.applyMemberEdit memberName, bootSources[memberName]
          else
            metaObject.removeMember memberName
          returned++
        catch error
          unreturned.push {metaObject, memberName, source: metaObject.nonStaticPropertiesSources[memberName]}
          console?.log "world snapshot: " + metaObject.name + "." + memberName + " could not be returned to its source at boot: " + error.message
    {returned, unreturned}

  # How many of the members returnThePageToBootSources LEFT still hold the source it left them
  # running -- read after the replay, which can have given one of them the file's own version: those
  # the page's edits still decide, counted rather than predicted.
  @stillRunning: (unreturned) ->
    (each for each in unreturned when each.metaObject.nonStaticPropertiesSources[each.memberName] is each.source).length

  # How many members returnThePageToBootSources would return, changing nothing: a load's confirm says
  # so before it replaces anything.
  @membersAwayFromBootCount: ->
    count = 0
    count += metaObject.membersAwayFromBoot().length for metaObject in SourceEditsRegistry._metaObjectsInBootOrder()
    count

  # Every parsed mixin, then every class's meta-object -- none where this build has no meta-system.
  @_metaObjectsInBootOrder: ->
    return [] unless SourceEditsRegistry.canReplaySourceEdits()
    Mixin.allMixines.concat (eachClass.class for eachClass in allClassFunctions() when eachClass.class?)

  # replay the CLASS-scope records IN ORDER against the live prototypes: an edit re-runs
  # Class.applyMemberEdit, a removal (deleted: true) Class.removeMember — the same choke
  # points the live class inspector's steps use, so the replay compiles exactly what the
  # session compiled (incl. the super rewrite) and gives back a donor's member where the
  # session did. Called by loadWorldSnapshot BEFORE deserialization, so a restored
  # shell already sees the edited methods. Instance-scope edits are NOT replayed
  # here — they ride the normal {"$src"} path on their own widget. A class edit
  # that no longer compiles (the class changed, a typo) is logged, not fatal.
  # Answers how many records it applied: the load tells the world its code changed when any did
  # (WorldWdgt.noteCodeChanged), as a class inspector's gesture does.
  replayClassEdits: ->
    return 0 unless SourceEditsRegistry.canReplaySourceEdits()
    applied = 0
    for r in @records when r.scope is "class"
      theClass = classNamed(r.className)?.class
      continue unless theClass?
      try
        if r.deleted
          theClass.removeMember r.propertyName
        else
          theClass.applyMemberEdit r.propertyName, r.source
        applied++
      catch error
        console?.log "world snapshot: class-scope source edit " + r.className + "." + r.propertyName + " could not be replayed: " + error.message
    applied

  # replay the MIXIN-scope records IN ORDER: an edit re-runs Mixin.applyMemberEdit
  # (recompile + re-inject into every non-shadowing consumer class), a removal
  # (deleted: true) re-runs Mixin.removeMember -- record order matters so a
  # remove-then-re-add sequence lands in its final state. Called by the snapshot
  # restore BEFORE replayClassEdits -- the boot-order analogy: augmentWith runs
  # before class-body assignments, so a class-scope edit of the same member keeps
  # winning. A record whose mixin/member no longer compiles is logged, not fatal
  # (same policy as replayClassEdits). Answers how many records it applied, as replayClassEdits does.
  replayMixinEdits: ->
    # ⚠ Without this the very first line of the loop body would throw a bare `Mixin is not defined`
    # mid-restore -- it reads Mixin.allMixines OUTSIDE the per-record try/catch below.
    return 0 unless SourceEditsRegistry.canReplaySourceEdits()
    applied = 0
    for r in @records when r.scope is "mixin"
      theMixin = Mixin.named r.mixinName
      continue unless theMixin?
      try
        if r.deleted
          theMixin.removeMember r.propertyName
        else
          theMixin.applyMemberEdit r.propertyName, r.source
        applied++
      catch error
        console?.log "world snapshot: mixin-scope source edit " + r.mixinName + "." + r.propertyName + " could not be replayed: " + error.message
    applied

  # rebuild a registry from the records embedded in a loaded snapshot.
  @fromRecords: (records) ->
    registry = new SourceEditsRegistry
    registry.records = (records or []).slice()
    registry
