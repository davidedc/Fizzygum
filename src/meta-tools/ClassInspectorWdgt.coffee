class ClassInspectorWdgt extends InspectorWdgt

  # ===== my edit steps: ONE per operation =====
  # Each makes the meta-object's edit AND its registry record (SourceEditsRegistry), so no gesture
  # of mine can change a prototype unrecorded, and a world snapshot replays exactly what was done.
  # None notifies: Class leaves that to its caller, and a gesture can be two steps (a rename is an
  # edit under the new name and a removal of the old) -- so each gesture below ends in ONE
  # notification (_notifyOfEdit).

  _editClassMember: (memberName, source) ->
    @inspectedObject.constructor.class.applyMemberEdit memberName, source
    world?.sourceEditsRegistry?.recordClassEdit? @inspectedObject, memberName, source

  _removeClassMember: (memberName) ->
    @inspectedObject.constructor.class.removeMember memberName
    world?.sourceEditsRegistry?.recordClassMemberRemoval? @inspectedObject, memberName

  # My gestures' one notification: code changed under every widget (WorldWdgt.noteCodeChanged), which
  # re-lays and repaints whatever derives from it -- the base's is my subject's alone, and my subject
  # is a class.
  _notifyOfEdit: ->
    # nosettle-sanctioned: the tail of my edit gestures (Save, Add…, Rename…, Remove), reached at
    # event time and never inside a settle -- the notification is the edit's own settle
    world.noteCodeChanged()

  # My edit scope: a CLASS, through its meta-object (Class.applyMemberEdit / removeMember),
  # recorded for a snapshot to replay -- so my subject must be a Fizzygum class's PROTOTYPE
  # (isAClassPrototype), and every such class is mine to edit, a value
  # class or an appearance as much as a widget class: the meta-object serves them all, and the edit
  # reaches whoever can show it (WorldWdgt.noteCodeChanged). A value class's INSTANCES stay immutable --
  # an object inspector on one is read-only -- while its class's members are edited here. Any other
  # subject gets a read-only inspector: a built-in class's prototype (an inspector on a number names
  # Number), or a value a code path handed me.
  _subjectIsEditable: ->
    isAClassPrototype @inspectedObject

  # My code pane runs no code (TextWdgt._codeReceiver): I hold a class and no instance of it. Code
  # run against the prototype would stamp a widget's lifecycle fields onto it and change the class
  # unrecorded -- a value class's prototype cannot run it at all -- and code run against the class
  # function would make statics unrecorded. My edits are my Save, Add, Rename and Remove, which a
  # snapshot replays; to run code against an instance, inspect one.
  codeReceiver: ->
    undefined

  # Prototype-level truth for a FIELD: its recorded SOURCE, the first class up the chain that
  # records one -- its current source (its body's, or an edit's since: Class.applyMemberEdit
  # keeps it) -- but only while my subject still reads the VALUE that source made there
  # (Class.fieldRecordHolds): a value has no identity to key a record by, so a run's write (or
  # one shadowing it further down) is told by the value it left, which I then show, as an object
  # inspector does. undefined when no source is recorded, or its value is gone (the base then
  # falls back to showing the VALUE).
  _sourceForFieldMember: (selected) ->
    value = @inspectedObject[selected]
    goingUpTargetProtChain = @inspectedObject
    while goingUpTargetProtChain?.constructor?.class?
      theClass = goingUpTargetProtChain.constructor.class
      if theClass.nonStaticPropertiesSources[selected]?
        return undefined unless Class.fieldRecordHolds goingUpTargetProtChain, selected, value
        return theClass.nonStaticPropertiesSources[selected]
      goingUpTargetProtChain = goingUpTargetProtChain.__proto__
    undefined

  # My class's member, through the Class meta-object (never a raw delete, re-key or assignment
  # on the prototype, after which the class's store of member sources would disagree with what
  # its prototype holds, and neither the next edit nor a snapshot load could tell). Removing a
  # member my class defines over its superclass's leaves the superclass's in force
  # (Class.removeMember).
  _applyPropertyRemoval: (propertyName) ->
    @_removeClassMember propertyName
    @_notifyOfEdit()

  # A rename is an edit under the new name of the member's recorded SOURCE, then a removal of
  # the old name: the member is recompiled, so its `super` calls the new name, and the record of
  # it is the two steps. A member my class has no source for (one its source never wrote, nor any
  # edit since) has nothing to recompile, so it is refused. (`constructor` never gets here, either
  # way round: InspectorWdgt.renameProperty refuses it.)
  _applyPropertyRename: (oldName, newName) ->
    theClass = @inspectedObject.constructor.class
    # a member renames the source my pane shows for it: a function's, the one its FUNCTION keeps
    # (Class.memberRecordOf); a field's, its class's only while my subject holds the value it made
    # (Class.fieldRecordHolds) -- so one a run replaced or rewrote (its source is no longer what it holds)
    # is refused as a member with no source is
    held = @inspectedObject[oldName]
    source = theClass.nonStaticPropertiesSources[oldName]
    sourceIsWhatItHolds = if Utils.isFunction(held) then Class.memberRecordOf(held) is source else Class.fieldRecordHolds @inspectedObject, oldName, held
    unless theClass.definesMember(oldName) and sourceIsWhatItHolds
      @inform oldName + " has no CoffeeScript\nsource in " + theClass.name + "\nto rename"
      return
    @_editClassMember newName, theClass.nonStaticPropertiesSources[oldName]
    @_removeClassMember oldName
    @_notifyOfEdit()

  # a member added to my class is an edit of it to "undefined"
  _applyPropertyAddition: (prop) ->
    @_editClassMember prop, "undefined"
    @_notifyOfEdit()

  # the class name follows the dash as DATA, exactly as the breadcrumb's chip shows it ("Class
  # Inspector — RectangleWdgt"): a class inspector's subject IS the class
  colloquialName: ->
    "Class Inspector — " + @inspectedObject.constructor.name

  # a class inspector builds no own-props toggle, so my toggles band holds three
  # (InspectorWdgt._toggles)
  _buildAndConnectOwnPropsOnlyToggle: ->

  # The shared save scaffolding lives in InspectorWdgt::save; a class inspector
  # differs only in HOW it applies the edit: through the meta-object that owns the
  # member, which compiles it and keeps its source so CoffeeScript stays editable.
  # Its failure is any save's (InspectorWdgt.save runs me through Widget._savingTypedCode): an edit
  # that does not compile changes nothing and is reported; any other throw reaches the Error log.
  applyPropertyEdit: (propertyName, txt) ->
    # my class's own member, method or field: the Class meta-object owns the edit mechanics
    # (Class.applyMemberEdit -- super rewritten exactly as at boot). Unlike an instance edit,
    # nothing but the record remembers a prototype edit -- the registry's essential case (§12).
    @_editClassMember propertyName, txt
    @_notifyOfEdit()
