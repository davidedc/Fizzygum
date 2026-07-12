class ClassInspectorWdgt extends InspectorWdgt

  notifyInstancesOfSourceChange: (propertiesArray)->
    @target.constructor.class.notifyInstancesOfSourceChange propertiesArray

  # Override the NON-SETTLING core (not the wrapper): the inherited _buildAndConnectChildren wrapper settles
  # once, and this extension runs inside that single settle -- so the "this class" label is set via the
  # non-settling _setTextNoSettle, keeping a low-level core free of public self-settling setters.
  _buildAndConnectChildrenNoSettle: ->
    super
    @lastLabelInHierarchy._setTextNoSettle "this class"
    #@label.setText "class " + @target.constructor.name

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

  # TODO: when inspecting objects, we added the functionality to
  # inject code in the objects themselves.
  # We'd have to do the same here, add a way to inject code in
  # object classes.
  # The shared save scaffolding lives in InspectorWdgt::save; a class inspector
  # differs only in HOW it applies the edit: it evaluates the assignment against
  # the class prototype (and keeps the source for functions so CoffeeScript
  # stays editable).
  applyPropertyEdit: (propertyName, txt) ->
    # this.target[propertyName] = evaluate txt
    @target.evaluateString "@" + propertyName + " = " + txt
    # if we are saving a function, we'd like to
    # keep the source code so we can edit Coffeescript
    # again.
    if Utils.isFunction @target[propertyName]
      @target[propertyName + "_source"] = txt
      # log the CLASS-scope source edit so a world snapshot can carry AND replay it (§12).
      # Unlike an instance edit, nothing else records a prototype edit — @target is the class
      # prototype, so this is the registry's essential case.
      world?.sourceEditsRegistry?.recordClassEdit? @target, propertyName, txt
    @notifyInstancesOfSourceChange([propertyName])
