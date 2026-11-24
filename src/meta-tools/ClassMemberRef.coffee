# ONE MEMBER OF ONE CLASS: the member `name` of a Fizzygum class's PROTOTYPE, `holder`, edited
# through the class's meta-object (Class.applyMemberEdit / removeMember) and recorded for a snapshot
# to replay. Every Fizzygum class is edited this way, a value class or an appearance as much as a
# widget class: the meta-object serves them all, and the edit reaches whoever can show it
# (WorldWdgt.noteCodeChanged). A value class's INSTANCES stay immutable -- an object inspector on one
# is read-only -- while its class's members are edited here.
#   My STEPS need that prototype, and the class inspector asks before it takes one
# (ClassInspectorWdgt._subjectIsEditable). What I SHOW (shownText) I can say of any holder a class
# inspector comes to hold -- a built-in class's prototype, an object code handed it: a field reads
# as the source the first class up its chain records, while my holder reads the value that source
# made, and as its value otherwise (_fieldSource).
#
# My edit steps: ONE per operation. Each makes the meta-object's edit AND its registry record
# (SourceEditsRegistry, through _editClassMember / _removeClassMember), so no step of mine can change
# a prototype unrecorded, and a world snapshot replays exactly what was done. Those two notify no
# one: Class leaves that to its caller, and a step can be two of them (a rename is an edit under the
# new name and a removal of the old) -- so each step ends in ONE notification (_notifyOfEdit).
class ClassMemberRef extends MemberRef

  _editClassMember: (memberName, source) ->
    @holder.constructor.class.applyMemberEdit memberName, source
    world?.sourceEditsRegistry?.recordClassEdit? @holder, memberName, source

  _removeClassMember: (memberName) ->
    @holder.constructor.class.removeMember memberName
    world?.sourceEditsRegistry?.recordClassMemberRemoval? @holder, memberName

  # My steps' one notification: code changed under every widget (WorldWdgt.noteCodeChanged), which
  # re-lays and repaints whatever derives from it -- the base's is my holder's alone, and my holder is
  # a class's prototype.
  _notifyOfEdit: ->
    # settling-call-sanctioned: the tail of my edit steps, which only an inspector's edit gestures reach (its
    # Save, Add…, Rename… and Remove), at event time and never inside a settle -- the notification is the edit's
    # own settle
    world.noteCodeChanged()

  # Prototype-level truth for a FIELD: its recorded SOURCE, the first class up the chain that
  # records one -- its current source (its body's, or an edit's since: Class.applyMemberEdit
  # keeps it) -- but only while my holder still reads the VALUE that source made there
  # (Class.fieldRecordHolds): a value has no identity to key a record by, so a run's write (or
  # one shadowing it further down) is told by the value it left, which I then show, as an object
  # inspector does. undefined when no source is recorded, or its value is gone (the base then
  # falls back to showing the VALUE).
  _fieldSource: ->
    value = @holder[@name]
    goingUpTargetProtChain = @holder
    while goingUpTargetProtChain?.constructor?.class?
      theClass = goingUpTargetProtChain.constructor.class
      if theClass.nonStaticPropertiesSources[@name]?
        return undefined unless Class.fieldRecordHolds goingUpTargetProtChain, @name, value
        return theClass.nonStaticPropertiesSources[@name]
      goingUpTargetProtChain = goingUpTargetProtChain.__proto__
    undefined

  # a member added to my class is an edit of it to "undefined"
  add: ->
    @_editClassMember @name, "undefined"
    @_notifyOfEdit()

  # The shared save scaffolding lives in InspectorWdgt::save; a class's member differs only in HOW
  # the edit is applied: through the meta-object that owns the member, which compiles it and keeps
  # its source so CoffeeScript stays editable. Its failure is any save's (InspectorWdgt.save runs me
  # through Widget._savingTypedCode): an edit that does not compile changes nothing and is reported;
  # any other throw reaches the Error log.
  save: (txt) ->
    # my class's own member, method or field: the Class meta-object owns the edit mechanics
    # (Class.applyMemberEdit -- super rewritten exactly as at boot). Unlike an instance edit,
    # nothing but the record remembers a prototype edit -- the registry's essential case (§12).
    @_editClassMember @name, txt
    @_notifyOfEdit()

  # A rename is an edit under the new name of the member's recorded SOURCE, then a removal of
  # the old name: the member is recompiled, so its `super` calls the new name, and the record of
  # it is the two steps. A member my class has no source for (one its source never wrote, nor any
  # edit since) has nothing to recompile, so it is refused, said through the world (I am no widget
  # to open a bubble from). (`constructor` never gets here, either way round:
  # InspectorWdgt.renameProperty refuses it.)
  rename: (newName) ->
    theClass = @holder.constructor.class
    # a member renames the source I show for it (shownText): a function's, the one its FUNCTION keeps
    # (Class.memberRecordOf); a field's, its class's only while my holder holds the value it made
    # (Class.fieldRecordHolds) -- so one a run replaced or rewrote (its source is no longer what it holds)
    # is refused as a member with no source is
    held = @holder[@name]
    source = theClass.nonStaticPropertiesSources[@name]
    sourceIsWhatItHolds = if Utils.isFunction(held) then Class.memberRecordOf(held) is source else Class.fieldRecordHolds @holder, @name, held
    unless theClass.definesMember(@name) and sourceIsWhatItHolds
      world.inform @name + " has no CoffeeScript\nsource in " + theClass.name + "\nto rename"
      return
    @_editClassMember newName, theClass.nonStaticPropertiesSources[@name]
    @_removeClassMember @name
    @_notifyOfEdit()

  # My class's member, through the Class meta-object (never a raw delete, re-key or assignment
  # on the prototype, after which the class's store of member sources would disagree with what
  # its prototype holds, and neither the next edit nor a snapshot load could tell). Removing a
  # member my class defines over its superclass's leaves the superclass's in force
  # (Class.removeMember).
  remove: ->
    @_removeClassMember @name
    @_notifyOfEdit()
