class ClassInspectorWdgt extends InspectorWdgt

  # the SECOND save destination for a mixin-donated member (see overrideInThisClass);
  # laid out left of the save button, shown only while such a member is selected
  overrideInThisClassButton: undefined

  notifyInstancesOfSourceChange: (propertiesArray)->
    @target.constructor.class.notifyInstancesOfSourceChange propertiesArray

  # Override the NON-SETTLING core (not the wrapper): the inherited _buildAndConnectChildren wrapper settles
  # once, and this extension runs inside that single settle -- so the "this class" label is set via the
  # non-settling _setTextNoSettle, keeping a low-level core free of public self-settling setters.
  _buildAndConnectChildrenNoSettle: ->
    super
    @lastLabelInHierarchy._setTextNoSettle "this class"
    @overrideInThisClassButton = new SimpleButtonWdgt true, @, "overrideInThisClass", "override in this class"
    @_addNoSettle @overrideInThisClassButton
    @overrideInThisClassButton.hide()

  # a mixin-donated INSTANCE member gets the second save destination offered; any
  # other selection hides it (a static's override would need a constructor-side
  # assignment -- not offered). (Visibility is not a layout input: the button is
  # laid out unconditionally in _layoutOverrideInThisClassButton.)
  selectionFromList: (selected) ->
    super
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
    if @target[selected + "_source"]?
      return @target[selected + "_source"]
    goingUpTargetProtChain = @target
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

  # layout-apply-sanctioned: apply helper, runs under _reLayout (settle point).
  # The gap between the remove button and the save button, in the bottom row.
  _layoutOverrideInThisClassButton: ->
    buttonLeft = @removePropertyButton.right() + @internalPadding
    buttonBounds = new Rectangle new Point buttonLeft, @bottom() - 15 - @externalPadding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight (Math.max 10, @saveButton.left() - @internalPadding - buttonLeft), 15
    @overrideInThisClassButton._reLayout buttonBounds

  # Destination step past the add... prompt: a class that declares augmentations
  # can receive the new member either on itself or on one of its mixins (a member
  # added to a mixin appears on every non-shadowing consumer class and is logged
  # for snapshot replay). An unaugmented class keeps the base single-step flow.
  addProperty: (ignoringThis, widgetWithProperty) ->
    augmentations = @target.constructor.class?.augmentedWith
    if !augmentations? or augmentations.length is 0
      super
      return
    prop = widgetWithProperty.text.text
    if prop?.getValue?
      prop = prop.getValue()
    return unless prop
    menu = new MenuWdgt @, target: @, title: "add \"" + prop + "\" to:"
    menu.addMenuItem @target.constructor.name, @, "addPropertyToClass", arg1: prop
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
    @_buildAndConnectChildren()

  # a mixin-donated INSTANCE member (not shadowed by this class) is removed from
  # the DONOR: every non-shadowing consumer class loses it (Mixin.removeMember),
  # and the removal is logged so a world snapshot replays it. A plain member (and
  # a mixin static) keeps the base prototype-delete flow.
  removeProperty: ->
    if @currentPropertySourceMixin? and !@currentPropertySourceIsStatic and @list.selected?
      theMixin = @currentPropertySourceMixin
      propertyName = @list.selected.labelString
      updatedCount = theMixin.removeMember propertyName
      world?.sourceEditsRegistry?.recordMixinMemberRemoval? theMixin.name, propertyName
      @currentProperty = undefined
      @currentPropertySourceMixin = undefined
      @_buildAndConnectChildren()
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
    delete @target[propertyName]

  _applyPropertyRename: (oldName, newName) ->
    delete @target[oldName]
    @target[newName] = @currentProperty

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
    @overrideInThisClassButton.hide()
    # the donor label follows the attribution: the member is class-owned now
    @mixinDonorLabel?.setText ""
    @save()
    @inform "overridden in " + @target.constructor.name + "\n(" + theMixinName + "Mixin edits no longer affect it)"

  colloquialName: ->
    "Class Inspector (" + @target.constructor.name.replace("Wdgt", "") + ")"

  layoutOwnPropsOnlyToggle: (height) ->
    # layout-apply-sanctioned: apply helper, runs under _reLayout (settle point)


    toggleBounds = new Rectangle new Point @left() + @externalPadding , height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (@width() - 2*@externalPadding - 2*@internalPadding)/4,15).round()
    @showMethodsToggle._reLayout toggleBounds

    toggleBounds = new Rectangle new Point @showMethodsToggle.right() + @internalPadding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (@width() - 2*@externalPadding - 2*@internalPadding)/4,15).round()
    @showFieldsToggle._reLayout toggleBounds

    toggleBounds = new Rectangle new Point @showFieldsToggle.right() + @internalPadding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point 2*(@width() - 2*@externalPadding - 2*@internalPadding)/4,15).round()
    @showInheritedToggle._reLayout toggleBounds


  _buildAndConnectObjOwnPropsButton: ->

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
    # prototype edit — @target is the class prototype, so this is the registry's
    # essential case.
    @target.constructor.class.applyMemberEdit propertyName, txt
    world?.sourceEditsRegistry?.recordClassEdit? @target, propertyName, txt
    @notifyInstancesOfSourceChange([propertyName])
