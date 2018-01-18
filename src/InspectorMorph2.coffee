# InspectorMorph2 //////////////////////////////////////////////////////

class InspectorMorph2 extends WindowMorph

  target: nil
  currentProperty: nil
  showing: "attributes"
  markOwnershipOfProperties: true
  # panes:
  list: nil
  detail: nil

  classesButtons: nil
  classesNames: nil
  angledArrows: nil
  hierarchyHeaderString: nil
  propertyHeaderString: nil

  showMethodsOnButton: nil
  showMethodsOffButton: nil
  showMethodsToggle: nil

  showFieldsOnButton: nil
  showFieldsOffButton: nil
  showFieldsToggle: nil

  showInheritedOnButton: nil
  showInheritedOffButton: nil
  showInheritedToggle: nil

  showOwnPropsOnlyOnButton: nil
  showOwnPropsOnlyOffButton: nil
  showOwnPropsOnlyToggle: nil

  lastLabelInHierarchy: nil
  lastArrowInHierarchy: nil

  hierarchyBackgroundPanel: nil

  showingFields: true
  showingMethods: true
  showingInherited: false
  showingOwnPropsOnly: false

  addPropertyButton: nil
  renamePropertyButton: nil
  removePropertyButton: nil
  saveButton: nil

  showFields: ->
    if !@showingFields
      @showingFields = true
      @buildAndConnectChildren()

  showMethods: ->
    if !@showingMethods
      @showingMethods = true
      @buildAndConnectChildren()

  showInherited: ->
    if !@showingInherited
      @showingInherited = true
      @buildAndConnectChildren()

  showOwnPropsOnly: ->
    if !@showingOwnPropsOnly
      @showingOwnPropsOnly = true
      @buildAndConnectChildren()

  hideFields: ->
    if @showingFields
      @showingFields = false
      @buildAndConnectChildren()

  hideMethods: ->
    if @showingMethods
      @showingMethods = false
      @buildAndConnectChildren()

  hideInherited: ->
    if @showingInherited
      @showingInherited = false
      @buildAndConnectChildren()

  hideOwnPropsOnly: ->
    if @showingOwnPropsOnly
      @showingOwnPropsOnly = false
      @buildAndConnectChildren()

  constructor: (@target) ->
    @classesButtons = []
    @classesNames = []
    @angledArrows = []
    super @target.toString()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = nil
    @buildAndConnectChildren()
  
  buildAndConnectChildren: ->
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    super
    attribs = []
    @classesButtons = []
    @classesNames = []
    @angledArrows = []

    # properties list. Note that this picks up ALL properties
    # (enumerable such as strings and un-enumerable such as functions)
    # of the whole prototype chain.
    #
    #   a) some of these are DECLARED as part of the class that defines the object
    #   and are proprietary to the object. These are shown RED
    # 
    #   b) some of these are proprietary to the object but are initialised by
    #   code higher in the prototype chain. These are shown GREEN
    #
    #   c) some of these are not proprietary, i.e. they belong to an object up
    #   the chain of prototypes. These are shown BLUE
    #
    # todo: show the static methods and variables in yet another color.
    
    for property of @target
      # dummy condition, to be refined
      attribs.push property  if property

    if !@showingMethods
      attribs = attribs.filter (prop) => !isFunction @target[prop]

    if !@showingFields
      attribs = attribs.filter (prop) => isFunction @target[prop]

    # if we don't show inherited props, then we let through two types of props (each side of the "or"
    # takes care of one type):
    #   1) the ones that are defined in the immediate class of the object (i.e. are own properties of the prototype)
    #   2) the ones that are just stitched to the object but are in none of the classes upwards i.e.
    #      are not a reachable property from the prototype
    if !@showingInherited
      attribs = attribs.filter (prop) => @target.constructor.prototype.hasOwnProperty(prop) or (prop not of @target.constructor.prototype)

    if @showingOwnPropsOnly
      attribs = attribs.filter (prop) => @target.hasOwnProperty(prop)

    console.log "attribs: " + attribs


    # caches the own methods of the object
    if @markOwnershipOfProperties
      targetOwnMethods = Object.getOwnPropertyNames @target.constructor::
      #alert targetOwnMethods

    if @target?
      goingUpTargetProtChain = @target.__proto__
      while goingUpTargetProtChain.constructor.name != "Object"
        @classesNames.push goingUpTargetProtChain.constructor.name
        goingUpTargetProtChain = goingUpTargetProtChain.__proto__

    @hierarchyBackgroundPanel = new RectangleMorph()
    @hierarchyBackgroundPanel.setColor new Color 255,255,255,.2
    @add @hierarchyBackgroundPanel

    counter = 0
    for eachNamedClass in @classesNames
      classButton = new SimpleButtonMorph true, @, "openClassInspector", (new StringMorph2 eachNamedClass),nil,nil,nil,nil,eachNamedClass
      @classesButtons.push classButton
      @add classButton

      # the top class doesn't get an arrow pointing upwards
      if counter > 0
        angledArrow = new AngledArrowUpLeftIconMorph new Color 0,0,0
        @angledArrows.push angledArrow
        @add angledArrow

      counter++

    @lastLabelInHierarchy = new TextMorph "this object"
    @add @lastLabelInHierarchy
    @lastArrowInHierarchy = new AngledArrowUpLeftIconMorph new Color 0,0,0
    @add @lastArrowInHierarchy

    @showMethodsOnButton = new SimpleButtonMorph true, @, "hideMethods", (new StringMorph2 "methods: on").alignCenter()
    @showMethodsOffButton = new SimpleButtonMorph true, @, "showMethods", (new StringMorph2 "methods: off").alignCenter()
    @showMethodsToggle = new ToggleButtonMorph @showMethodsOnButton, @showMethodsOffButton, if @showingMethods then 0 else 1
    @add @showMethodsToggle

    @showFieldsOnButton = new SimpleButtonMorph true, @, "hideFields", (new StringMorph2 "fields: on").alignCenter()
    @showFieldsOffButton = new SimpleButtonMorph true, @, "showFields", (new StringMorph2 "fields: off").alignCenter()
    @showFieldsToggle = new ToggleButtonMorph @showFieldsOnButton, @showFieldsOffButton, if @showingFields then 0 else 1
    @add @showFieldsToggle

    @showInheritedOnButton = new SimpleButtonMorph true, @, "hideInherited", (new StringMorph2 "inherited: on").alignCenter()
    @showInheritedOffButton = new SimpleButtonMorph true, @, "showInherited", (new StringMorph2 "inherited: off").alignCenter()
    @showInheritedToggle = new ToggleButtonMorph @showInheritedOnButton, @showInheritedOffButton, if @showingInherited then 0 else 1
    @add @showInheritedToggle

    @buildAndConnectObjOwnPropsButton()

    @addPropertyButton = new SimpleButtonMorph true, @, "addPropertyPopout", (new StringMorph2 "add...").alignCenter()
    @add @addPropertyButton
    @renamePropertyButton = new SimpleButtonMorph true, @, "renamePropertyPopout", (new StringMorph2 "rename...").alignCenter()
    @add @renamePropertyButton
    @removePropertyButton = new SimpleButtonMorph true, @, "removeProperty", (new StringMorph2 "remove").alignCenter()
    @add @removePropertyButton
    @saveButton = new SimpleButtonMorph true, @, "save", (new StringMorph2 "save").alignCenter()
    @add @saveButton



    # open a new inspector, just on objects so
    # the idea is that you can view / change
    # its fields
    doubleClickAction = =>
      if !isObject @currentProperty
        return
      inspector = new @constructor @currentProperty
      inspector.fullRawMoveTo world.hand.position()
      inspector.fullRawMoveWithin world
      world.add inspector
      inspector.changed()

    @list = new ListMorph(
      @, # target
      "selectionFromList", #action
      (if @target instanceof Array then attribs else attribs.sort()), #elements
      nil, #labelGetter
      @filterProperties(targetOwnMethods), #format
      doubleClickAction #doubleClickAction
    )
    @list.disableDrops()

    # we know that the content of this list in this pane is not going to need the
    # step function, so we disable that from here by setting it to nil, which
    # prevents the recursion to children. We could have disabled that from the
    # constructor of MenuMorph, but who knows, maybe someone might intend to use a MenuMorph
    # with some animated content? We know that in this specific case it won't need animation so
    # we set that here. Note that the ListMorph itself does require animation because of the
    # scrollbars, but the MenuMorph (which contains the actual list contents)
    # in this context doesn't.
    world.removeSteppingMorph @list.listContents
    @add @list

    # we add a Morph alignment here because adjusting IDs whenever
    # we add or remove methods is a pain...
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


    # details pane
    @detail = new ScrollPanelWdgt()
    @detail.disableDrops()
    @detail.contents.disableDrops()
    @detail.isTextLineWrapping = true
    @detail.color = new Color 255, 255, 255
    ctrl = new TextMorph ""
    ctrl.isEditable = true
    ctrl.enableSelecting()
    ctrl.setReceiver @target
    @detail.setContents ctrl, 2
    @add @detail

    @hierarchyHeaderString = new StringMorph2 "Hierarchy"
    @hierarchyHeaderString.toggleHeaderLine()
    @hierarchyHeaderString.alignCenter()
    @add @hierarchyHeaderString


    @propertyHeaderString = new StringMorph2 "Properties"
    @propertyHeaderString.toggleHeaderLine()
    @propertyHeaderString.alignCenter()
    @add @propertyHeaderString

    # resizer
    @resizer = new HandleMorph @

    # update layout
    @invalidateLayout()

  buildAndConnectObjOwnPropsButton: ->
    @showOwnPropsOnlyOnButton = new SimpleButtonMorph true, @, "hideOwnPropsOnly", (new StringMorph2 "obj own props only: on").alignCenter()
    @showOwnPropsOnlyOffButton = new SimpleButtonMorph true, @, "showOwnPropsOnly", (new StringMorph2 "obj own props only: off").alignCenter()
    @showOwnPropsOnlyToggle = new ToggleButtonMorph @showOwnPropsOnlyOnButton, @showOwnPropsOnlyOffButton, if @showingOwnPropsOnly then 0 else 1
    @add @showOwnPropsOnlyToggle

  openClassInspector: (ignored,ignored2,className) ->
    classInspector = new ClassInspectorMorph window[className].prototype
    classInspector.fullRawMoveTo world.hand.position()
    classInspector.setExtent new Point 560,410
    classInspector.fullRawMoveWithin world
    world.add classInspector
    classInspector.bringToForegroud()
    classInspector.changed()

  showAttributes: ->
    @showing = "attributes"
    @buildAndConnectChildren()

  showAttributesAndMethods: ->
    @showing = "all"
    @buildAndConnectChildren()

  highlightOwnershipOfProperties: ->
    @markOwnershipOfProperties = not @markOwnershipOfProperties
    @buildAndConnectChildren()

  filterProperties: (targetOwnMethods)->
    if @markOwnershipOfProperties
      return [
        # give color criteria from the most general to the most specific
        [new Color(0, 0, 180),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            true
        ],
        [new Color(0, 180, 0),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            @target.constructor.prototype.hasOwnProperty(element)
        ]
      ]
    else
      return nil

  selectionFromList: (selected) ->
    if selected == undefined then return

    val = @target[selected]
    @currentProperty = val

    # functions should have a source somewhere
    # either in the object or in a superclass,
    # try to find it.
    if isFunction(val)
      if @target[selected + "_source"]?
          val = @target[selected + "_source"]
      else
        goingUpTargetProtChain = @target
        while goingUpTargetProtChain != Object
          if goingUpTargetProtChain.constructor.class.nonStaticPropertiesSources[selected]?
            val = goingUpTargetProtChain.constructor.class.nonStaticPropertiesSources[selected]
            break
          goingUpTargetProtChain = goingUpTargetProtChain.__proto__
      txt = val.toString()
    else
      # this is for finding the static variables
      if val is undefined
        val = @target.constructor[selected]
      
      if !val?
        txt = "nil"
      else if isString val
        txt = '"'+val+'"'
      else
        txt = val.toString()

    cnts = new TextMorph txt
    cnts.isEditable = true
    cnts.enableSelecting()
    cnts.setReceiver @target
    @detail.setContents cnts, 2
  
  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    super

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Morph. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false


    classDiagrHeight = Math.floor(@height() / 3)

    labelLeft = @label.left()
    labelBottom = @label.bottom() + 2

    headerBounds = new Rectangle new Point(Math.round(@left() + @padding), Math.round(labelBottom + @padding))
    headerBounds = headerBounds.setBoundsWidthAndHeight @width() - 2 * @padding, 15
    @hierarchyHeaderString.doLayout headerBounds


    # classes diagram
    justAcounter = 0
    anotherCount = 0
    # reverse works in-place, so we need to remember
    # to put them back right after we are done
    @classesButtons.reverse()
    for eachClassButton in @classesButtons
      if eachClassButton.parent == @
        buttonBounds = new Rectangle new Point(Math.round(@left() + 2 * @padding + justAcounter), Math.round(@hierarchyHeaderString.bottom() + 2*@padding + justAcounter))
        buttonBounds = buttonBounds.setBoundsWidthAndHeight 120, 15
        eachClassButton.doLayout buttonBounds

        # the top class doesn't get an arrow pointing upwards
        if anotherCount > 0
          @angledArrows[anotherCount-1].parent == @
          @angledArrows[anotherCount-1].fullRawMoveTo new Point(eachClassButton.left() - 15, Math.round(eachClassButton.top()))
          @angledArrows[anotherCount-1].rawSetExtent new Point 15, 15

        justAcounter += 20

      anotherCount++
    @classesButtons.reverse()
    @layoutLastLabelInHierarchy Math.round(@left() + 2 * @padding + justAcounter), Math.round(@hierarchyHeaderString.bottom() + 2*@padding + justAcounter)

    @hierarchyBackgroundPanel.fullRawMoveTo new Point @left() + @padding, @hierarchyHeaderString.bottom() + @padding
    @hierarchyBackgroundPanel.rawSetExtent new Point @width() - 2 * @padding, justAcounter + 20 + @padding

    headerBounds = new Rectangle new Point @left() + @padding , @hierarchyBackgroundPanel.bottom()+ @padding
    headerBounds = headerBounds.setBoundsWidthAndHeight @width() - 2 * @padding , 15
    @propertyHeaderString.doLayout headerBounds

    listWidth = Math.floor((@width() - 3 * @padding) / 3)
    detailWidth = 2*listWidth

    @layoutOwnPropsOnlyToggle @propertyHeaderString.bottom() + @padding, listWidth, detailWidth

    # list
    listHeight = (@bottom() - 2 * @padding - 15) - (@showMethodsToggle.bottom() + @padding)
    if @list.parent == @
      @list.fullRawMoveTo new Point @left() + @padding, @showMethodsToggle.bottom() + @padding
      @list.rawSetExtent new Point listWidth, listHeight

    # detail
    if @detail.parent == @
      @detail.fullRawMoveTo new Point @list.right() + @padding, @list.top()
      @detail.rawSetExtent new Point(detailWidth, listHeight).round()

    buttonBounds = new Rectangle new Point @left() + @padding, @bottom() - 15 - @padding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight (listWidth - 2 * @padding)/3, 15
    @addPropertyButton.doLayout buttonBounds

    buttonBounds = new Rectangle new Point @addPropertyButton.right() + @padding, @bottom() - 15 - @padding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight (listWidth - 2 * @padding)/3, 15
    @renamePropertyButton.doLayout buttonBounds

    buttonBounds = new Rectangle new Point @renamePropertyButton.right() + @padding, @bottom() - 15 - @padding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight (listWidth - 2 * @padding)/3, 15
    @removePropertyButton.doLayout buttonBounds

    buttonBounds = new Rectangle new Point @right() - @width()/4 - 2*@padding - WorldMorph.preferencesAndSettings.handleSize, @bottom() - 15 - @padding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight @width()/4, 15
    @saveButton.doLayout buttonBounds

    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

  layoutOwnPropsOnlyToggle: (height, listWidth, detailWidth) ->

    toggleBounds = new Rectangle new Point @left()+@padding , height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (listWidth-@padding)/ 2,15).round()
    @showMethodsToggle.doLayout toggleBounds

    toggleBounds = new Rectangle new Point @showMethodsToggle.right() + @padding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (listWidth-@padding)/ 2,15).round()
    @showFieldsToggle.doLayout toggleBounds
 
    toggleBounds = new Rectangle new Point @showFieldsToggle.right() + @padding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (detailWidth-@padding)/ 2,15).round()
    @showInheritedToggle.doLayout toggleBounds

    toggleBounds = new Rectangle new Point @showInheritedToggle.right() + @padding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (detailWidth-@padding)/ 2,15).round()
    @showOwnPropsOnlyToggle.doLayout toggleBounds


  layoutLastLabelInHierarchy: (posx, posy) ->
    if @lastLabelInHierarchy.parent == @
      @lastLabelInHierarchy.fullRawMoveTo new Point posx, posy
      @lastLabelInHierarchy.rawSetExtent new Point 150, 15

    if @lastArrowInHierarchy.parent == @
      @lastArrowInHierarchy.fullRawMoveTo new Point posx - 15, posy
      @lastArrowInHierarchy.rawSetExtent new Point 15, 15


  notifyInstancesOfSourceChange: (propertiesArray)->
    @target.sourceChanged()
  
  #InspectorMorph2 editing ops:
  save: ->
    txt = @detail.contents.children[0].text.toString()
    propertyName = @list.selected.labelString
    # inject code will also break the layout and the morph
    @target.injectProperty propertyName, txt

  # TODO should have a removeProperty method in Morph (and in the classes somehow)
  # rather than here 
  addProperty: (ignoringThis, morphWithProperty) ->
    prop = morphWithProperty.text.text
    if prop?
      if prop.getValue?
        prop = prop.getValue()
      @target[prop] = nil
      @buildAndConnectChildren()
      @notifyInstancesOfSourceChange([prop])
  
  addPropertyPopout: ->
    @prompt "new property name:", @, "addProperty", "property" # Chrome cannot handle empty strings (others do)

  # TODO should have a removeProperty method in Morph (and in the classes somehow)
  # rather than here 
  renameProperty: (ignoringThis, morphWithProperty) ->
    propertyName = @list.selected.labelString
    prop = morphWithProperty.text.text
    if prop.getValue?
      prop = prop.getValue()
    try
      delete @target[propertyName]
      @target[prop] = @currentProperty
    catch err
      @inform err
    @buildAndConnectChildren()
    @notifyInstancesOfSourceChange([prop, propertyName])
  
  renamePropertyPopout: ->
    propertyName = @list.selected.labelString
    @prompt "property name:", @, "renameProperty", propertyName
  
  # TODO should have a removeProperty method in Morph (and in the classes somehow)
  # rather than here 
  removeProperty: ->
    propertyName = @list.selected.labelString
    try
      delete @target[propertyName]

      @currentProperty = nil
      @buildAndConnectChildren()
      @notifyInstancesOfSourceChange([propertyName])
    catch err
      @inform err
