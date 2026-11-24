class ClassInspectorWdgt extends InspectorWdgt

  # my member reference: a CLASS's member, edited through its meta-object and recorded (ClassMemberRef)
  _memberRefOf: (memberName) ->
    new ClassMemberRef @inspectedObject, memberName

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

  # the class name follows the dash as DATA, exactly as the breadcrumb's chip shows it ("Class
  # Inspector — RectangleWdgt"): a class inspector's subject IS the class
  colloquialName: ->
    "Class Inspector — " + @inspectedObject.constructor.name

  # a class inspector builds no own-props toggle, so my toggles band holds three
  # (InspectorWdgt._toggles)
  _buildAndConnectOwnPropsOnlyToggle: ->
