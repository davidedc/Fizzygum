# SourceEditsRegistry — a per-world log of in-world SOURCE edits, so a whole-world snapshot
# can carry them and replay them on restore. Lives at world.sourceEditsRegistry. See
# docs/architecture/serialization-duplication-reference.md §12.
#
# TWO scopes of edit, each recorded by the person's GESTURE that makes it, never by the verb it
# drives (the product calls those verbs as plumbing too, which no one edited) -- and, once, by a world
# LOAD: a member of the page it could not return to boot, which the loaded world still runs, is recorded
# as that member's edit would have been (recordMembersStillRunning), so a save carries the code it runs:
#   - "instance": a single widget's method rewritten by an inspector's Save
#     (MemberRef.save). These ALSO ride the serializer for free — the injected function
#     keeps its source (Widget.keptSourceOf), serialized as {"$src"} and re-injected on restore (§5). The
#     registry's marginal value here is auditability (a durable record of what was edited).
#   - "class": a class PROTOTYPE's member edited (Class.applyMemberEdit) or removed
#     (Class.removeMember, record flagged `deleted: true`) through an inspector's edit
#     steps (ClassMemberRef). This is the ESSENTIAL case: nothing else records it — a class
#     edit mutates the live prototype but leaves no serializable trace (§2.7). The snapshot
#     embeds it and REPLAYS it against the destination prototypes BEFORE deserialization, so
#     restored shells (Object.create(prototype)) already see the edited methods. A class's own
#     comment and its category list are class records too (Class.setClassComment, setCategories),
#     replayed in the same order; a registry holds one only from a file, as no gesture records either.
# In the class scope, an ADD is an edit whose source is "undefined", and a RENAME is two records: an
# edit under the new name, then a removal of the old. A class's member sources are its CURRENT ones
# and its prototype follows from them (Class.coffee, "live member editing"), so replaying the
# records in order, from boot, reproduces the session's live members exactly -- and a load first
# returns the page to boot (returnThePageToBootSources).
#
# A record is plain JSON, embedded verbatim in the world envelope's `world.sourceEdits`:
#   - an instance edit: {scope: "instance", className, uniqueID?, propertyName, source};
#   - a class member's edit or removal: {scope: "class", className, propertyName, source | deleted: true,
#     comment?, category?} -- the member's comment and category only where the edit SET them ("" for
#     none): an edit that kept them carries neither, and its replay keeps them too;
#   - a class's comment: {scope: "class", className, classComment} ("" for none);
#   - a class's category list: {scope: "class", className, categories: [names]}.
class SourceEditsRegistry

  constructor: ->
    @records = []

  # record an instance-scope edit (from an inspector's Save, MemberRef.save): a holder WITH AN IDENTITY,
  # a widget's (its uniqueIDString), so the record names the one object edited. A holder with none (a
  # paint tool, DrawingToolBase: the person's, whose edit the world snapshot's user record carries
  # whole) is no one this record could name, and is not recorded.
  recordInstanceEdit: (widget, propertyName, source) ->
    return unless widget?.uniqueIDString? and propertyName?
    @records.push
      scope: "instance"
      className: widget.constructor?.name
      uniqueID: widget.uniqueIDString?()
      propertyName: propertyName
      source: source
    return

  # record a class-scope edit (from ClassMemberRef's class edit step, _editClassMember: an
  # inspector's Save, Add…, Duplicate… and Rename…; `classPrototype` is the prototype the edit was
  # evaluated against — its constructor is the class). opts.comment and opts.category are the
  # member's comment and category where the edit SET them ("" for none), each written only then.
  recordClassEdit: (classPrototype, propertyName, source, opts = {}) ->
    return unless classPrototype? and propertyName?
    record =
      scope: "class"
      className: classPrototype.constructor?.name
      propertyName: propertyName
      source: source
    record.comment = opts.comment if opts.comment?
    record.category = opts.category if opts.category?
    @records.push record
    return

  # record a class-scope member REMOVAL (from ClassMemberRef's class removal step, _removeClassMember:
  # an inspector's Remove and Rename…; the prototype names the class, as above).
  recordClassMemberRemoval: (classPrototype, propertyName) ->
    return unless classPrototype? and propertyName?
    @records.push
      scope: "class"
      className: classPrototype.constructor?.name
      propertyName: propertyName
      deleted: true
    return

  # the plain-JSON records embedded in a world snapshot (copies, so a later live edit can't mutate
  # an already-serialized array: a record's fields are primitives but a category list, which is
  # copied with it).
  serializableRecords: ->
    for r in @records
      copy = Object.assign {}, r
      copy.categories = r.categories.slice() if r.categories?
      copy

  # CAN THIS BUILD REPLAY class-scope edits at all? (arc 5)
  #
  # The replay drives the META-SYSTEM -- Class.applyMemberEdit / removeMember -- and the meta-system
  # is not in the pre-compiled image: of the classes the boot defines, Class is the one absent from
  # it (it is what compiled everything else), so it arrives only from the class source directory -- with the reflective
  # layer, or alone ahead of a lazy part's load. An artifact built with sources: "none" ships no
  # Class, and can therefore never replay these records, no matter how long it waits.
  #
  # ⚠ This asks about the CAPABILITY, not the build flag, deliberately: it is the actual
  # precondition, and it keeps a BUILDFLAG out of class code (no other class reads one). It is asked
  # once a load has brought the reflective layer in wherever it can come (Deserializer.loadWhatItNeeds,
  # before the replay), so by then `Class?` is false only where the layer can never arrive. Whether
  # the layer has ARRIVED is a different question, reflectiveLayerIsLoaded's: Class alone does not
  # bring the eager classes' member maps.
  @canReplaySourceEdits: -> Class?

  # Is `r` a record as the header above writes one (and serializableRecords hands a save), by its
  # SHAPE: a plain object with its scope and the code it names -- a class's name, an instance edit's
  # class (with the widget's unique id where it had one) -- and then an instance edit's member and
  # source, or one of a class record's three kinds (_isAClassRecordsBody). Asked of every record a
  # world file carries, before the load changes anything (Deserializer._worldSectionProblem), on every
  # build, the ones with no meta-system included -- so it reads shape alone, and asks nothing of
  # Class. What a record's note SAYS is judged where its rule lives: a category's name as the load
  # vets the file (malformedCategoryIn); a comment's lines, and a list's names being distinct, by
  # the meta-object as the replay applies the record, as a source's code is.
  @isARecord: (r) ->
    return false unless r? and typeof r is "object" and !Array.isArray(r) and SourceEditsRegistry._isAName r.className
    switch r.scope
      when "class" then SourceEditsRegistry._isAClassRecordsBody r
      when "instance" then (!r.uniqueID? or typeof r.uniqueID is "string") and SourceEditsRegistry._isAMembersEdit r
      else false

  # a text that names something -- a class, a member -- as a record writes it: never empty
  @_isAName: (value) ->
    typeof value is "string" and value.length > 0

  # a member's edit or removal: the member's name, and its source unless it is a removal
  @_isAMembersEdit: (r) ->
    SourceEditsRegistry._isAName(r.propertyName) and (r.deleted is true or typeof r.source is "string")

  # A class record is ONE of three kinds, by the field it carries: a member's edit or removal (with
  # its comment and its category, where it carries them, texts: "" is none), the class's comment (a
  # text), or the class's category list (a list of texts).
  @_isAClassRecordsBody: (r) ->
    isATextOrAbsent = (value) -> !value? or typeof value is "string"
    if r.propertyName?
      !r.classComment? and !r.categories? and SourceEditsRegistry._isAMembersEdit(r) and isATextOrAbsent(r.comment) and isATextOrAbsent(r.category)
    else if r.classComment?
      !r.categories? and typeof r.classComment is "string"
    else
      Array.isArray(r.categories) and r.categories.every (name) -> typeof name is "string"

  # The first METHOD CATEGORY a class record names that is no category's name, or undefined: a
  # member's category ("" names none: it clears the member's) or a name in a class's category list,
  # judged by the rule the parse reads a marker by (Class.isACategoryName: lower-case words, one
  # space between two, none of them opening with `extends`), so a file naming one is refused before
  # anything changes (Deserializer._sectionSourceEditsProblem). Asked of a record isARecord passes. The rule
  # is the meta-system's, so it judges where Class is: on a page that compiles at boot, always; on a
  # production tree, the load's re-entry once the reflective layer has come (it vets the file again,
  # still before anything changes), its first look having found no Class; a build with no
  # meta-system never applies a class record at all (canReplaySourceEdits), and its load says how
  # many it did not.
  @malformedCategoryIn: (r) ->
    return undefined unless Class? and SourceEditsRegistry.isClassLevel r
    named = if r.categories? then r.categories else if r.category then [r.category] else []
    (name for name in named when !Class.isACategoryName name)[0]

  # Is `record` CLASS-LEVEL -- a class-scope one, which the replay applies against the meta-system?
  # (An instance-scope one rides the {"$src"} path on its own widget, which needs only the compiler,
  # and every profile ships that.)
  @isClassLevel: (record) ->
    record?.scope is "class"

  # How many class-level records I hold: what a load's replay would apply, so the load can tell the
  # user, once, how many of them it did not (WorldWdgt.loadWorldSnapshot).
  classLevelRecordCount: ->
    (r for r in @records when SourceEditsRegistry.isClassLevel r).length

  # The code the class-level records of a world file name, by the names the build's part manifest
  # holds them by: each class's name (a name no part holds is passed over). What the parts pre-load
  # brings in before the replay (Deserializer.loadWhatItNeeds), so an edit of a lazy part's code finds
  # its class even when the file holds none of that part's widgets.
  @namesOfTheCodeEditedIn: (records) ->
    names = []
    add = (name) -> names.push name if typeof name is "string" and name not in names
    for r in (records ? []) when r?.scope is "class"
      add r.className
    names

  # THE PAGE AS IT BOOTED, which a replay starts from: the records reproduce a session's members from
  # boot (above), so a world-snapshot load first returns every class's meta-object to its boot record.
  # Each member whose source, comment or category differs from the one the class's source text at boot
  # gives (Class.bootRecord, Class.membersAwayFrom) gets all three back through the meta-object's own
  # two edits, which keep every prototype a function of the stores -- so the members come back as
  # boot made them (_returnMember); then the class's own comment and category list, each where it is
  # away (_returnClassNotes). What the page edited is read from the STORES, never from a registry: a
  # world's registry lists the edits made under it, while the prototypes are the page's, and a world
  # built on an edited page (the harness's resetWorld) starts with none. A class the vault holds no
  # source text for (one made at run time) has no boot and is left as it is. An edit that cannot be
  # returned is logged and left, as a record that cannot be replayed is: the load has already torn the
  # desktop down, so nothing here throws past it, and the load tells the user how many members still
  # run as the page edited them once the replay is done (pageMembersStillRunning,
  # WorldWdgt.loadWorldSnapshot). Answers {returned, unreturned}: how many edits it returned (a member,
  # a class's comment, a class's category list: one each), and each member it left, with the source it
  # was left running (undefined for a member the page removed -- read by own-ness, so a removed member
  # that shares a name with one of Object.prototype's is too) and its comment and category ("" for
  # none), so it can be recorded as the record a session's edit of it would be
  # (recordMembersStillRunning); 0 and none where this build has no meta-system (canReplaySourceEdits).
  @returnThePageToBootSources: ->
    returned = 0
    unreturned = []
    for metaObject in SourceEditsRegistry._metaObjectsInBootOrder()
      boot = metaObject.bootRecord()
      continue unless boot?
      for memberName in Class.membersAwayFrom metaObject, boot
        try
          SourceEditsRegistry._returnMember metaObject, memberName, boot
          returned++
        catch error
          unreturned.push
            metaObject: metaObject
            memberName: memberName
            source: metaObject.nonStaticPropertiesSources[memberName]
            comment: metaObject.commentOf memberName
            category: metaObject.categoryOf memberName
          console?.log "world snapshot: " + metaObject.name + "." + memberName + " could not be returned to its source at boot: " + (error?.message ? textOfThrownValue error)
      try
        returned += SourceEditsRegistry._returnClassNotes metaObject, boot
      catch error
        console?.log "world snapshot: " + metaObject.name + "'s comment or category list could not be returned to boot: " + (error?.message ? textOfThrownValue error)
    {returned, unreturned}

  # One member of `metaObject` given back as `boot`, its boot record, holds it: its source, its
  # comment and its category (each "" where boot has none, which clears the page's), or removed where
  # boot has no such member. A member whose notes alone are away is recompiled with them: an edit is
  # the one path that writes a member's notes.
  @_returnMember: (metaObject, memberName, boot) ->
    if memberName of boot.nonStaticPropertiesSources
      metaObject.applyMemberEdit memberName, boot.nonStaticPropertiesSources[memberName],
        comment: boot.nonStaticPropertiesComments[memberName] ? ""
        category: boot.nonStaticPropertiesCategories[memberName] ? ""
    else
      metaObject.removeMember memberName
    return

  # `metaObject`'s class's own comment and category list given back as `boot`, its boot record,
  # holds them, each only where it is away (Class.classNotesAwayFrom): how many of the two it gave
  # back.
  @_returnClassNotes: (metaObject, boot) ->
    away = Class.classNotesAwayFrom metaObject, boot
    metaObject.setClassComment boot.classComment if "classComment" in away
    metaObject.setCategories boot.categoryNames if "categoryNames" in away
    away.length

  # Which members returnThePageToBootSources LEFT (`unreturned`) the loaded world still runs as the PAGE
  # edited them -- read after the replay, which can have given one of them the file's own version: each
  # that still holds the source it was left running, unless this registry's last record of it (the file's)
  # says the same, which makes it the file's code, not the page's. Counted rather than predicted.
  pageMembersStillRunning: (unreturned) ->
    (each for each in unreturned when each.metaObject.nonStaticPropertiesSources[each.memberName] is each.source and !@_lastRecordSays each)

  # Does my last record of `each`'s member leave it as `each` holds it -- its source, or removed?
  _lastRecordSays: (each) ->
    last = undefined
    for record in @records when record.scope is "class" and record.propertyName is each.memberName and
        record.className is each.metaObject.name
      last = record
    return false unless last?
    if each.source? then last.deleted isnt true and last.source is each.source else last.deleted is true

  # RECORD, after a load's replay, each page member the load could not return to boot that the loaded world
  # still runs as the page edited it (pageMembersStillRunning): the loaded world runs it, so its registry --
  # what a save of it writes -- says so, as the session's own edit of it would have (the same record), its
  # comment and category with its source ("" for none, which a replay sets as it sets a text), and a save of
  # the loaded world reloads into the same member. Answers how many it recorded: the load's notice counts
  # them.
  recordMembersStillRunning: (unreturned) ->
    stillRunning = @pageMembersStillRunning unreturned
    for each in stillRunning
      record = {scope: "class", className: each.metaObject.name, propertyName: each.memberName}
      if each.source?
        Object.assign record, source: each.source, comment: each.comment, category: each.category
      else
        record.deleted = true
      @records.push record
    stillRunning.length

  # How many edits returnThePageToBootSources would return, changing nothing -- members, and a class's own
  # comment and category list (Class.editsAwayFromBoot): a load's confirm says so before it replaces
  # anything.
  @editsAwayFromBootCount: ->
    count = 0
    count += metaObject.editsAwayFromBoot().length for metaObject in SourceEditsRegistry._metaObjectsInBootOrder()
    count

  # Every class's meta-object -- none where this build has no meta-system.
  @_metaObjectsInBootOrder: ->
    return [] unless SourceEditsRegistry.canReplaySourceEdits()
    (eachClass.class for eachClass in allClassFunctions() when eachClass.class?)

  # replay the CLASS-scope records IN ORDER against the live prototypes, each by its kind
  # (_applyClassRecord): an edit re-runs Class.applyMemberEdit, a removal (deleted: true)
  # Class.removeMember — the same choke points ClassMemberRef's live steps use, so the replay
  # compiles exactly what the session compiled (incl. the super rewrite) — and a class's comment and
  # category list their two verbs. Called by loadWorldSnapshot BEFORE deserialization, so a restored
  # shell already sees the edited methods. Instance-scope edits are NOT replayed
  # here — they ride the normal {"$src"} path on their own widget. A class edit the meta-object
  # refuses (a source that no longer compiles -- the class changed, a typo -- or a note it does not
  # take) is logged, not fatal, and counted by the load as one it did not apply.
  # Answers how many records it applied: the load tells the world its code changed when any did
  # (WorldWdgt.noteCodeChanged), as an inspector's edit of a class's member does.
  replayClassEdits: ->
    return 0 unless SourceEditsRegistry.canReplaySourceEdits()
    applied = 0
    for r in @records when r.scope is "class"
      metaObject = classNamed(r.className)?.class
      continue unless metaObject?
      try
        SourceEditsRegistry._applyClassRecord metaObject, r
        applied++
      catch error
        console?.log "world snapshot: class-scope source edit " + SourceEditsRegistry._whatItEdits(r) + " could not be replayed: " + (error?.message ? textOfThrownValue error)
    applied

  # One class record applied to `metaObject` by its kind (_isAClassRecordsBody): the class's comment,
  # its category list, a member's removal, or a member's edit with the comment and category it
  # carries (one it does not carry is undefined, which keeps the member's).
  @_applyClassRecord: (metaObject, r) ->
    if r.classComment? then metaObject.setClassComment r.classComment
    else if r.categories? then metaObject.setCategories r.categories
    else if r.deleted then metaObject.removeMember r.propertyName
    else metaObject.applyMemberEdit r.propertyName, r.source, comment: r.comment, category: r.category
    return

  # What a class record edits, as a log line names it: `<class>.<member>`, or the class's comment or
  # its category list.
  @_whatItEdits: (r) ->
    if r.propertyName? then r.className + "." + r.propertyName
    else if r.classComment? then r.className + "'s comment"
    else r.className + "'s category list"

  # rebuild a registry from the records embedded in a loaded snapshot.
  @fromRecords: (records) ->
    registry = new SourceEditsRegistry
    registry.records = (records or []).slice()
    registry
