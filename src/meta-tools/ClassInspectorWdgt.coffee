class ClassInspectorWdgt extends InspectorWdgt

  # the SECOND save destination for a mixin-donated member (see overrideInThisClass);
  # laid out last in my footer band's left group, after remove (_footerLeftButtons), shown only
  # while such a member is selected
  overrideInThisClassButton: undefined

  notifyInstancesOfSourceChange: (propertiesArray)->
    @inspectedObject.constructor.class.notifyInstancesOfSourceChange propertiesArray

  # Override the NON-SETTLING core (not the wrapper): the inherited _buildAndConnectChildren wrapper settles
  # once, and this extension -- my second save destination -- is built inside that single settle. My
  # breadcrumb is the base's: my subject is a class's prototype, so its current chip is that class
  # (InspectorWdgt._classChainNames).
  _buildAndConnectChildrenNoSettle: ->
    super
    # part of the base's EDIT ROW, my footer band, so it exists on the same condition the rest of
    # that row does: a class whose prototype cannot service an edit (a Point, a Color — anything off
    # the Widget branch, reachable now that an inspector opens on any value) gets a read-only
    # inspector with no footer band at all, and this button is one of its members.
    if @_subjectIsEditable()
      @overrideInThisClassButton = new SimpleButtonWdgt @, "overrideInThisClass", face: "Override in this class"
      @_addNoSettle @overrideInThisClassButton
      @overrideInThisClassButton.hide()

  # The base's rename and remove follow my selection, and so does my second save destination: a
  # mixin-donated INSTANCE member gets it offered; any other selection hides it (a static's override
  # would need a constructor-side assignment -- not offered), and so does NO selection, since a
  # re-filter clears the attribution with the list. Reached at the end of every selection
  # (selectionFromList) and of every re-filter. (Visibility is not a layout input: whenever the
  # button EXISTS it is laid out in my footer band, shown or not, so showing or hiding it moves no
  # other button. Existence is the separate question the edit row answers -- a read-only subject
  # has no footer band, and the build reaches here before my extension builds the button, hence the
  # `?.` here.)
  _reflectMemberSelection: ->
    super()
    if @currentPropertySourceMixin? and !@currentPropertySourceIsStatic
      @overrideInThisClassButton?.show()
    else
      @overrideInThisClassButton?.hide()

  # Prototype-level truth for a FIELD: its recorded SOURCE, in boot order of
  # authority -- a live class-scope override (`<name>_source`, kept by
  # Class.applyMemberEdit for fields too), the class body's recorded source
  # (chain walk, mirroring the function branch), then the mixin donor's (setting
  # the donor attribution, so the save routes to the mixin and the override
  # gesture is offered -- field parity with methods). undefined when no source is
  # recorded (the base then falls back to showing the VALUE).
  _sourceForFieldMember: (selected) ->
    if @inspectedObject[selected + "_source"]?
      return @inspectedObject[selected + "_source"]
    goingUpTargetProtChain = @inspectedObject
    while goingUpTargetProtChain?.constructor?.class?
      theClass = goingUpTargetProtChain.constructor.class
      if theClass.nonStaticPropertiesSources[selected]?
        return theClass.nonStaticPropertiesSources[selected]
      theMixinProvidingIt = @_mixinProvidingMember theClass, selected
      if theMixinProvidingIt?
        @currentPropertySourceMixin = theMixinProvidingIt
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

  addPropertyToMixin: (ignored, ignored2, prop, mixinGlobalName) ->
    theMixin = Mixin.allMixines.find (m) -> m.name + "Mixin" is mixinGlobalName or m.name is mixinGlobalName
    return unless theMixin?
    theMixin.applyMemberEdit prop, "undefined"
    world?.sourceEditsRegistry?.recordMixinEdit? theMixin.name, prop, "undefined"
    @_refilterMembers()

  # a mixin-donated INSTANCE member (not shadowed by this class) is removed from
  # the DONOR: every non-shadowing consumer class loses it (Mixin.removeMember),
  # and the removal is logged so a world snapshot replays it. A plain member (and
  # a mixin static) keeps the base prototype-delete flow. Either way my member set is all that
  # changed, so I re-filter (_refilterMembers), which also drops the removed member's attribution.
  removeProperty: ->
    if @currentPropertySourceMixin? and !@currentPropertySourceIsStatic and @list.selected?
      theMixin = @currentPropertySourceMixin
      propertyName = @list.selected.labelString
      updatedCount = theMixin.removeMember propertyName
      world?.sourceEditsRegistry?.recordMixinMemberRemoval? theMixin.name, propertyName
      @_refilterMembers()
      @inform "removed from " + theMixin.name + "Mixin\n(" + updatedCount + " consumer class" + (if updatedCount is 1 then "" else "es") + " updated)"
      return
    super

  # plain prototype members keep the RAW delete/re-key (the Widget-level twins
  # would drive instance machinery -- sourceChanged -- against a prototype).
  # Known gap, mirroring the base seam comments: a plain class-member removal
  # or rename leaves any <name>_source live override behind and is not
  # registry-recorded, so it does not replay on snapshot restore (the mixin
  # path above closes this with recordMixinMemberRemoval).
  _applyPropertyRemoval: (propertyName) ->
    delete @inspectedObject[propertyName]

  _applyPropertyRename: (oldName, newName) ->
    delete @inspectedObject[oldName]
    @inspectedObject[newName] = @currentProperty

  # The second save destination for a mixin-donated member: instead of editing the
  # DONOR (what plain save does while @currentPropertySourceMixin is set), keep the
  # edited source as a live override on THIS class's prototype only. Dropping the
  # mixin attribution first makes the plain save routing do exactly that -- and undefined
  # IS the true post-state: the prototype then carries `<name>_source`, which is
  # what a re-selection would attribute the member to (and what applyMemberEdit's
  # live-override shadow guard keys off), so future donor edits skip this class.
  overrideInThisClass: ->
    if !@list.selected? then return
    return unless @currentPropertySourceMixin?
    return if @currentPropertySourceIsStatic
    theMixinName = @currentPropertySourceMixin.name
    @currentPropertySourceMixin = undefined
    @overrideInThisClassButton?.hide()
    # the donor label follows the attribution: the member is class-owned now, and my breadcrumb band
    # re-flows without the label
    @mixinDonorLabel?.setText ""
    @save()
    @inform "overridden in " + @inspectedObject.constructor.name + "\n(" + theMixinName + "Mixin edits no longer affect it)"

  # the class name follows the dash as DATA, exactly as the breadcrumb's chip shows it ("Class
  # Inspector — RectangleWdgt"): a class inspector's subject IS the class
  colloquialName: ->
    "Class Inspector — " + @inspectedObject.constructor.name

  # a class inspector builds no own-props toggle, so my toggles band holds three
  # (InspectorWdgt._toggles)
  _buildAndConnectOwnPropsOnlyToggle: ->

  # The shared save scaffolding lives in InspectorWdgt::save; a class inspector
  # differs only in HOW it applies the edit: it evaluates the assignment against
  # the class prototype (and keeps the source for functions so CoffeeScript
  # stays editable).
  applyPropertyEdit: (propertyName, txt) ->
    # a mixin-donated member (not shadowed by this class's own body) edits the
    # DONOR: the mixin recompiles it and re-injects it into every consumer class
    # (Mixin.applyMemberEdit) -- the class inspector is prototype-level truth, and
    # a mixin member's prototype-level truth is the mixin. Logged with scope
    # "mixin" so a world snapshot carries and replays it (SourceEditsRegistry).
    if @currentPropertySourceMixin?
      theMixin = @currentPropertySourceMixin
      try
        if @currentPropertySourceIsStatic
          updatedCount = theMixin.applyStaticEdit propertyName, txt
        else
          updatedCount = theMixin.applyMemberEdit propertyName, txt
      catch error
        @inform "mixin edit failed:\n" + error.message
        return
      world?.sourceEditsRegistry?.recordMixinEdit? theMixin.name, propertyName, txt, @currentPropertySourceIsStatic
      # (the apply*Edit already ran notifyInstancesOfSourceChange per consumer class)
      @inform "saved to " + theMixin.name + "Mixin\n(" + updatedCount + " consumer class" + (if updatedCount is 1 then "" else "es") + " updated)"
      return

    # a plain class-prototype member: the Class meta-object owns the edit mechanics
    # (Class.applyMemberEdit, the class twin of the mixin routing above -- super
    # rewritten exactly as at boot, `<name>_source` kept for CoffeeScript editability).
    # Log the CLASS-scope source edit -- method or field -- so a world snapshot can
    # carry AND replay it (§12). Unlike an instance edit, nothing else records a
    # prototype edit — @inspectedObject is the class prototype, so this is the registry's
    # essential case.
    @inspectedObject.constructor.class.applyMemberEdit propertyName, txt
    world?.sourceEditsRegistry?.recordClassEdit? @inspectedObject, propertyName, txt
    @notifyInstancesOfSourceChange([propertyName])
