class ClassInspectorMorph extends InspectorMorph2

  notifyInstancesOfSourceChange: (propertiesArray)->
    @target.constructor.class.notifyInstancesOfSourceChange propertiesArray

  buildAndConnectChildren: ->
    super
    @lastLabelInHierarchy.setText "this class"
    #@label.setText "class " + @target.constructor.name   

  colloquialName: ->
    "Class Inspector (" + @target.constructor.name.replace("Morph", "").replace("Wdgt", "") + ")"

  layoutOwnPropsOnlyToggle: (height) ->


    toggleBounds = new Rectangle new Point @left() + @externalPadding , height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (@width() - 2*@externalPadding - 2*@internalPadding)/4,15).round()
    @showMethodsToggle.doLayout toggleBounds

    toggleBounds = new Rectangle new Point @showMethodsToggle.right() + @internalPadding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (@width() - 2*@externalPadding - 2*@internalPadding)/4,15).round()
    @showFieldsToggle.doLayout toggleBounds

    toggleBounds = new Rectangle new Point @showFieldsToggle.right() + @internalPadding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point 2*(@width() - 2*@externalPadding - 2*@internalPadding)/4,15).round()
    @showInheritedToggle.doLayout toggleBounds


  buildAndConnectObjOwnPropsButton: ->

  # TODO: when inspecting objects, we added the functionality to
  # inject code in the objects themselves.
  # We'd have to do the same here, add a way to inject code in
  # object classes.
  save: ->
    txt = @detail.contents.children[0].text.toString()
    propertyName = @list.selected.labelString

    # this.target[propertyName] = evaluate txt
    @target.evaluateString "@" + propertyName + " = " + txt
    # if we are saving a function, we'd like to
    # keep the source code so we can edit Coffeescript
    # again.
    if isFunction @target[propertyName]
      @target[propertyName + "_source"] = txt
    @notifyInstancesOfSourceChange([propertyName])

    @detail.textWdgt.considerCurrentTextAsReferenceText()
    @detail.checkIfTextContentWasModifiedFromTextAtStart()

    # it's possible that the user might have fixed
    # a "painting" error, so give another chance to all
    # "banned" widgets (banned from repainting)
    for eachWidget in world.widgetsGivingErrorWhileRepainting
      eachWidget.show()
    world.widgetsGivingErrorWhileRepainting = []
