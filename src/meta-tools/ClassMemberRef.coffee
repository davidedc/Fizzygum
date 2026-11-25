# ONE MEMBER OF ONE CLASS: the member `name` of a Fizzygum class's PROTOTYPE, `holder`, edited
# through the class's meta-object (Class.applyMemberEdit / removeMember) and recorded for a snapshot
# to replay. Every Fizzygum class is edited this way, a value class or an appearance as much as a
# widget class: the meta-object serves them all, and the edit reaches whoever can show it
# (WorldWdgt.noteCodeChanged). A value class's INSTANCES stay immutable -- an inspector on one is
# read-only -- while its class's members are edited here.
#   I am made for a Fizzygum class's PROTOTYPE and nothing else (MemberRef.of), and my steps need
# that prototype. What I SHOW (shownText): a field reads as the source the first class up its chain
# records, while my holder reads the value that source made, and as its value otherwise
# (_fieldSource).
#
# My edit steps: ONE per operation. Each makes the meta-object's edit AND its registry record
# (SourceEditsRegistry, through _editClassMember / _removeClassMember), so no step of mine can change
# a prototype unrecorded, and a world snapshot replays exactly what was done. Those two notify no
# one: Class leaves that to its caller, and a step can be two of them (a rename is an edit under the
# new name and a removal of the old; a duplicate and a rename share the copy that tells no one,
# _editCopyUnder) -- so each step ends in ONE notification (_notifyOfEdit), and answers whether it
# made its edit.
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
    # settling-call-sanctioned: the tail of my edit steps, which only an inspector's edit gestures reach (a member
    # list's Add…, Duplicate…, Rename… and Remove, a member editor's Save), at event time and never inside a
    # settle -- the notification is the edit's own settle
    world.noteCodeChanged()

  # Prototype-level truth for a FIELD: its recorded SOURCE, the first class up the chain that
  # records one -- its current source (its body's, or an edit's since: Class.applyMemberEdit
  # keeps it) -- but only while my holder still reads the VALUE that source made there
  # (Class.fieldRecordHolds): a value has no identity to key a record by, so a run's write (or
  # one shadowing it further down) is told by the value it left, which I then show, as an object's
  # member is shown. undefined when no source is recorded, or its value is gone (the base then
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
    true

  # The shared save scaffolding lives in MemberEditorWdgt.save; a class's member differs only in HOW
  # the edit is applied: through the meta-object that owns the member, which compiles it and keeps
  # its source so CoffeeScript stays editable. Its failure is any save's (MemberEditorWdgt.save runs me
  # through Widget._savingTypedCode): an edit that does not compile changes nothing and is reported;
  # any other throw reaches the Error log.
  save: (txt) ->
    # my class's own member, method or field: the Class meta-object owns the edit mechanics
    # (Class.applyMemberEdit -- super rewritten exactly as at boot). Unlike an instance edit,
    # nothing but the record remembers a prototype edit -- the registry's essential case (§12).
    @_editClassMember @name, txt
    @_notifyOfEdit()
    true

  # THE COPY a duplicate and a rename share, which tells no one: an edit under newName of my member's
  # recorded SOURCE, so the copy is recompiled and its `super` calls the new name. The source is the
  # one I show for my member (shownText): a function's, the one its FUNCTION keeps
  # (Class.memberRecordOf); a field's, its class's only while my holder holds the value it made
  # (Class.fieldRecordHolds). A member my class has no source for (one its source never wrote, nor any
  # edit since), or one a run replaced or rewrote (its source is no longer what it holds), has nothing
  # to recompile, so it is refused, said through the world (I am no widget to open a bubble from) with
  # the gesture's verb in the words, and my member's name quoted, as a message that starts with a
  # member's name quotes it (MemberListWdgt._refusesAsAnAnsweredName says why). Answers whether it made
  # the copy.
  _editCopyUnder: (newName, verb) ->
    theClass = @holder.constructor.class
    held = @holder[@name]
    source = theClass.nonStaticPropertiesSources[@name]
    sourceIsWhatItHolds = if Utils.isFunction(held) then Class.memberRecordOf(held) is source else Class.fieldRecordHolds @holder, @name, held
    unless theClass.definesMember(@name) and sourceIsWhatItHolds
      world.inform '"' + @name + '" has no CoffeeScript\nsource in ' + theClass.name + "\nto " + verb
      return false
    @_editClassMember newName, source
    true

  # A duplicate is the copy alone (_editCopyUnder), recorded as the one edit under the new name, then
  # the one notification. A refused copy changes nothing and tells no one, and answers false. My one
  # guard is the copy's, on my member (a member with no source to recompile); on newName I have none:
  # the edit under it replaces a member my class defines under that name, or defines one over a
  # superclass's. The guard on newName is my caller's: `constructor` and a name my holder already
  # answers, my class's own or inherited, never get here (MemberListWdgt.duplicateProperty,
  # _refusesAsAnAnsweredName).
  duplicate: (newName) ->
    return false unless @_editCopyUnder newName, "duplicate"
    @_notifyOfEdit()
    true

  # A rename is the copy (_editCopyUnder), then a removal of the old name: the record of it is the two
  # steps, and it tells once. A refused copy removes nothing and tells no one, and answers false. My one
  # guard is the copy's, on my member (a member with no source to recompile); on newName I have none:
  # the edit under it replaces a member my class defines under that name, or defines one over a
  # superclass's, and a move onto my member's own name would remove the member it just wrote. The guard
  # on newName is my caller's: the member list's Rename… (MemberListWdgt.renameProperty) asks me with
  # none of three names -- my member's own name, which is nothing to do, so it does nothing and says
  # nothing; `constructor`, refused; and a name my holder already answers, my class's own or inherited,
  # refused (_refusesAsAnAnsweredName). (`constructor` is never my member either: a member list offers
  # no rename of it, MemberRef.canBeRenamedOrRemoved.)
  rename: (newName) ->
    return false unless @_editCopyUnder newName, "rename"
    @_removeClassMember @name
    @_notifyOfEdit()
    true

  # My class's member, through the Class meta-object (never a raw delete, re-key or assignment
  # on the prototype, after which the class's store of member sources would disagree with what
  # its prototype holds, and neither the next edit nor a snapshot load could tell). Removing a
  # member my class defines over its superclass's leaves the superclass's in force
  # (Class.removeMember).
  remove: ->
    @_removeClassMember @name
    @_notifyOfEdit()
    true
