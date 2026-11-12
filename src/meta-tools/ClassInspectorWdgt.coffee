class ClassInspectorWdgt extends InspectorWdgt

  # the SECOND save destination for a mixin-donated member (see overrideInThisClass);
  # laid out last in my footer band's left group, after remove (_footerLeftButtons), shown only
  # while such a member is selected
  overrideInThisClassButton: undefined

  # ===== my edit steps: ONE per (scope × operation) =====
  # Each makes the meta-object's edit AND its registry record (SourceEditsRegistry), so no gesture
  # of mine can change a prototype or a mixin unrecorded, and a world snapshot replays exactly what
  # was done. None notifies: Class and Mixin leave that to their caller, and a gesture can be two
  # steps (a rename is an edit under the new name and a removal of the old) -- so each gesture below
  # ends in ONE notification (_notifyOfEdit).

  _editClassMember: (memberName, source) ->
    @inspectedObject.constructor.class.applyMemberEdit memberName, source
    world?.sourceEditsRegistry?.recordClassEdit? @inspectedObject, memberName, source

  _removeClassMember: (memberName) ->
    @inspectedObject.constructor.class.removeMember memberName
    world?.sourceEditsRegistry?.recordClassMemberRemoval? @inspectedObject, memberName

  # (both mixin steps answer the names of the consumer classes they updated)
  _editMixinMember: (theMixin, memberName, source) ->
    updated = theMixin.applyMemberEdit memberName, source
    world?.sourceEditsRegistry?.recordMixinEdit? theMixin.name, memberName, source
    updated

  _removeMixinMember: (theMixin, memberName) ->
    updated = theMixin.removeMember memberName
    world?.sourceEditsRegistry?.recordMixinMemberRemoval? theMixin.name, memberName
    updated

  # My gestures' one notification: code changed under every widget (WorldWdgt.noteCodeChanged), which
  # re-lays and repaints whatever derives from it -- the base's is my subject's alone, and my subject
  # is a class.
  _notifyOfEdit: ->
    # nosettle-sanctioned: the tail of my edit gestures (Save, Add…, Rename…, Remove, a mixin
    # destination's row), reached at event time and never inside a settle -- the notification is the
    # edit's own settle
    world.noteCodeChanged()

  _informConsumerClassesUpdated: (whatHappened, theMixin, classNames) ->
    count = classNames.length
    @inform whatHappened + " " + theMixin.name + "Mixin\n(" + count + " consumer class" + (if count is 1 then "" else "es") + " updated)"

  # Override the NON-SETTLING core (not the wrapper): the inherited _buildAndConnectChildren wrapper settles
  # once, and this extension -- my second save destination -- is built inside that single settle. My
  # breadcrumb is the base's: my subject is a class's prototype, so its current chip is that class
  # (InspectorWdgt._classChainLinks).
  _buildAndConnectChildrenNoSettle: ->
    super
    # part of the base's EDIT ROW, my footer band, so it exists on the same condition the rest of
    # that row does (_subjectIsEditable): a subject that is no Fizzygum class's prototype gets a
    # read-only inspector with no footer band at all, and this button is one of its members.
    if @_subjectIsEditable()
      @overrideInThisClassButton = new SimpleButtonWdgt target: @, action: "overrideInThisClass", face: "Override in this class"
      @_addNoSettle @overrideInThisClassButton
      @overrideInThisClassButton.hide()

  # My edit scope: a CLASS, through its meta-object (Class.applyMemberEdit / removeMember, and
  # Mixin's for a donated member), recorded for a snapshot to replay -- so my subject must be a
  # Fizzygum class's PROTOTYPE (isAClassPrototype), and every such class is mine to edit, a value
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

  # The base's rename and remove follow my selection, and so does my second save destination: a
  # mixin-donated member gets it offered; any other selection hides it, and so does NO selection,
  # since a re-filter clears the attribution with the list. Reached at the end of every selection
  # (selectionFromList) and of every re-filter. (Visibility is not a layout input: whenever the
  # button EXISTS it is laid out in my footer band, shown or not, so showing or hiding it moves no
  # other button. Existence is the separate question the edit row answers -- a read-only subject
  # has no footer band, and the build reaches here before my extension builds the button, hence the
  # `?.` here.)
  _reflectMemberSelection: ->
    super()
    if @currentPropertySourceMixinName?
      @overrideInThisClassButton?.show()
    else
      @overrideInThisClassButton?.hide()

  # Prototype-level truth for a FIELD: its recorded SOURCE, in boot order of
  # authority up the class chain -- the class's own current source (its body's, or an
  # edit's since: Class.applyMemberEdit keeps it), then the mixin donor's (setting
  # the donor attribution, so the save routes to the mixin and the override
  # gesture is offered -- field parity with methods) -- but only while my subject still
  # reads the VALUE that source made there (Class.fieldRecordHolds): a value has no identity
  # to key a record by, so a run's write (or one shadowing it further down) is told by the
  # value it left, which I then show, as an object inspector does. undefined when no source
  # is recorded, or its value is gone (the base then falls back to showing the VALUE).
  _sourceForFieldMember: (selected) ->
    value = @inspectedObject[selected]
    goingUpTargetProtChain = @inspectedObject
    while goingUpTargetProtChain?.constructor?.class?
      theClass = goingUpTargetProtChain.constructor.class
      if theClass.nonStaticPropertiesSources[selected]?
        return undefined unless Class.fieldRecordHolds goingUpTargetProtChain, selected, value
        return theClass.nonStaticPropertiesSources[selected]
      theMixinProvidingIt = Mixin.donorOf theClass, selected
      if theMixinProvidingIt?
        return undefined unless Class.fieldRecordHolds goingUpTargetProtChain, selected, value
        @currentPropertySourceMixinName = theMixinProvidingIt.name
        return theMixinProvidingIt.nonStaticPropertiesSources[selected]
      goingUpTargetProtChain = goingUpTargetProtChain.__proto__
    undefined

  # My footer band's left group: the base's add, rename and remove, then my second save destination
  # for a mixin-donated member, at its own size like every footer button.
  _footerLeftButtons: ->
    super().concat [@overrideInThisClassButton]

  # Destination step past the Add… prompt: a class that declares augmentations
  # can receive the new member either on itself or on one of its mixins (a member
  # added to a mixin appears on every non-shadowing consumer class and is logged
  # for snapshot replay). An unaugmented class keeps the base single-step flow.
  addProperty: (prop) ->
    return unless @_subjectIsEditable()
    return if @_refusesAsANewMemberName prop
    augmentations = @inspectedObject.constructor.class?.augmentedWith
    if !augmentations? or augmentations.length is 0
      super
      return
    return unless prop
    # the title carries the member's name as typed, so it reads as a message: capitals would re-case it
    menu = new MenuWdgt @, target: @, title: "add \"" + prop + "\" to:", titleIsAMessage: true
    menu.addMenuItem @inspectedObject.constructor.name, @, "addPropertyToClass", arg1: prop
    for eachMixinGlobalName in augmentations
      menu.addMenuItem eachMixinGlobalName, @, "addPropertyToMixin", arg1: prop, arg2: eachMixinGlobalName
    menu.popUpAtHand()

  addPropertyToClass: (ignored, ignored2, prop) ->
    @_addNamedProperty prop

  # a member added to a mixin is an edit of it to "undefined", as a member added to my class is
  # (_applyPropertyAddition): every consumer class that does not define it gets it
  addPropertyToMixin: (ignored, ignored2, prop, mixinGlobalName) ->
    theMixin = Mixin.named mixinGlobalName
    return unless theMixin?
    @_editMixinMember theMixin, prop, "undefined"
    @_notifyOfEdit()
    @_refilterMembers()

  # a mixin-donated member (not shadowed by this class) is removed from
  # the DONOR: every consumer class that does not define it loses it (Mixin.removeMember).
  # A member of my class keeps the base flow (_applyPropertyRemoval). Either way my member set
  # is all that changed, so I re-filter (_refilterMembers), which also drops the removed member's
  # attribution.
  removeProperty: ->
    if (theMixin = @_currentPropertySourceMixin())? and @_selectedMemberCanBeRenamedOrRemoved()
      propertyName = @list.selected.labelString
      updated = @_removeMixinMember theMixin, propertyName
      @_notifyOfEdit()
      @_refilterMembers()
      @_informConsumerClassesUpdated "removed from", theMixin, updated
      return
    super

  # My class's member, through the Class meta-object (never a raw delete, re-key or assignment
  # on the prototype, after which the class's store of member sources would disagree with what
  # its prototype holds, and neither the next edit nor a snapshot load could tell). Removing a
  # member my class defines over a mixin's gives the mixin's back (Class.removeMember).
  _applyPropertyRemoval: (propertyName) ->
    @_removeClassMember propertyName
    @_notifyOfEdit()

  # A rename is an edit under the new name of the member's recorded SOURCE, then a removal of
  # the old name: the member is recompiled, so its `super` calls the new name, and the record of
  # it is the two steps. A donated member is renamed on its DONOR, for every consumer class, as
  # its other edits are. A member my class has no source for (one its source never wrote, nor any
  # edit since) has nothing to recompile, so it is refused. (`constructor` never gets here, either
  # way round: InspectorWdgt.renameProperty refuses it.)
  _applyPropertyRename: (oldName, newName) ->
    if (theMixin = @_currentPropertySourceMixin())?
      @_editMixinMember theMixin, newName, theMixin.nonStaticPropertiesSources[oldName]
      @_removeMixinMember theMixin, oldName
      @_notifyOfEdit()
      return
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

  # a member added to my class is an edit of it to "undefined", the twin of addPropertyToMixin
  _applyPropertyAddition: (prop) ->
    @_editClassMember prop, "undefined"
    @_notifyOfEdit()

  # The second save destination for a mixin-donated member: instead of editing the
  # DONOR (what plain save does while @currentPropertySourceMixinName is set), keep the
  # edited source as an override on THIS class only. Dropping the mixin attribution
  # first makes the plain save routing do exactly that -- and undefined IS the true
  # post-state: my class's store of member sources then holds the member
  # (Class.applyMemberEdit), which is what a re-selection attributes it to and what
  # Mixin's one shadow guard keys off, so future donor edits skip this class.
  # A save that does not complete overrides nothing -- refused (an edit that does not compile,
  # InspectorWdgt.save) or thrown (code that compiled and then threw, on to the Error log): the
  # member stays the mixin's, attribution, button and label all.
  overrideInThisClass: ->
    if !@list.selected? then return
    return unless @currentPropertySourceMixinName?
    theMixinName = @currentPropertySourceMixinName
    @currentPropertySourceMixinName = undefined
    saved = false
    try
      saved = @save()
    finally
      @currentPropertySourceMixinName = theMixinName  unless saved
    return unless saved
    @overrideInThisClassButton?.hide()
    # the donor label follows the attribution: the member is class-owned now, and my breadcrumb band
    # re-flows without the label
    @mixinDonorLabel?.setText ""
    @inform "overridden in " + @inspectedObject.constructor.name + "\n(" + theMixinName + "Mixin edits no longer affect it)"

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
    # a mixin-donated member (not shadowed by this class) edits the DONOR: the mixin
    # recompiles it and injects it into every consumer class that does not define it
    # (Mixin.applyMemberEdit) -- the class inspector is prototype-level truth, and
    # a mixin member's prototype-level truth is the mixin
    if (theMixin = @_currentPropertySourceMixin())?
      updated = @_editMixinMember theMixin, propertyName, txt
      @_notifyOfEdit()
      @_informConsumerClassesUpdated "saved to", theMixin, updated
      return

    # my class's own member, method or field: the Class meta-object owns the edit mechanics
    # (Class.applyMemberEdit, the class twin of the mixin routing above -- super
    # rewritten exactly as at boot). Unlike an instance edit, nothing but the record
    # remembers a prototype edit -- the registry's essential case (§12).
    @_editClassMember propertyName, txt
    @_notifyOfEdit()
