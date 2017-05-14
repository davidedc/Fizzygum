# InspectorMorph2 //////////////////////////////////////////////////////

class InspectorMorph2 extends WindowMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  target: null
  currentProperty: null
  showing: "attributes"
  markOwnershipOfProperties: false
  # panes:
  list: null
  detail: null
  buttonInspect: null
  buttonSubset: null
  buttonEdit: null
  classesButtons: null
  classesNames: null

  constructor: (@target) ->
    debugger
    @classesButtons = []
    @classesNames = []
    super @target.toString()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
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
    attribs = switch @showing
      when "attributes"
        attribs.filter (prop) =>
          not isFunction @target[prop]
      when "methods"
        attribs.filter (prop) =>
          isFunction @target[prop]
      when "all"
        attribs

    # otherwise show all properties
    # label getter
    # format list
    # format element: [color, predicate(element]
    
    staticProperties = Object.getOwnPropertyNames(@target.constructor)
    # get rid of all the standard fuff properties that are in classes
    staticProperties = staticProperties.filter (prop) =>
        prop not in ["name","length","prototype","caller","__super__","arguments"]

    switch @showing
      when "attributes"
        staticFunctions = []
        staticAttributes = staticProperties.filter (prop) =>
          not isFunction @target.constructor[prop]
      when "methods"
        staticFunctions = staticProperties.filter (prop) =>
          isFunction @target.constructor[prop]
        staticAttributes = []
      else
        staticFunctions = staticProperties.filter (prop) =>
          isFunction @target.constructor[prop]
        staticAttributes = staticProperties.filter (prop) =>
          prop not in staticFunctions

    #alert "stat fun " + staticFunctions + " stat attr " + staticAttributes
    attribs = (attribs.concat staticFunctions).concat staticAttributes
    #alert " all attribs " + attribs
    
    # caches the own methods of the object
    if @markOwnershipOfProperties
      targetOwnMethods = Object.getOwnPropertyNames @target.constructor::
      #alert targetOwnMethods

    if @target?
      goingUpTargetProtChain = @target.__proto__
      while goingUpTargetProtChain.constructor.name != "Object"
        @classesNames.push goingUpTargetProtChain.constructor.name
        goingUpTargetProtChain = goingUpTargetProtChain.__proto__

    for eachNamedClass in @classesNames
      classButton = new TriggerMorph true, @
      classButton.action = "openClassInspector"
      classButton.argumentToAction1 = eachNamedClass
      classButton.setLabel eachNamedClass
      classButton.alignCenter()
      #classButton.action = "openShowMenu"
      @classesButtons.push classButton
      @add classButton


    # open a new inspector, just on objects so
    # the idea is that you can view / change
    # its fields
    doubleClickAction = =>
      if !isObject @currentProperty
        return
      inspector = new InspectorMorph2 @currentProperty
      inspector.fullRawMoveTo world.hand.position()
      inspector.fullRawMoveWithin world
      world.add inspector
      inspector.changed()

    @list = new ListMorph(
      @, # target
      "selectionFromList", #action
      (if @target instanceof Array then attribs else attribs.sort()), #elements
      null, #labelGetter
      @filterProperties(staticProperties, targetOwnMethods), #format
      doubleClickAction #doubleClickAction
    )
    @list.disableDrops()

    # we know that the content of this list in this pane is not going to need the
    # step function, so we disable that from here by setting it to null, which
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
    @detail = new ScrollFrameMorph()
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

    # properties button
    @buttonSubset = new TriggerMorph true, @
    @buttonSubset.setLabel "show..."
    @buttonSubset.alignCenter()
    @buttonSubset.action = "openShowMenu"
    @add @buttonSubset

    # inspect button
    @buttonInspect = new TriggerMorph true, @
    @buttonInspect.setLabel "inspect"
    @buttonInspect.alignCenter()
    @buttonInspect.action = "openInspectorMenu"
    @add @buttonInspect

    # edit button
    @buttonEdit = new TriggerMorph true, @
    @buttonEdit.setLabel "edit..."
    @buttonEdit.alignCenter()
    @buttonEdit.action = "openEditMenu"
    @add @buttonEdit


    # resizer
    @resizer = new HandleMorph @

    # update layout
    @layoutSubmorphs()

  openClassInspector: (ignored,ignored2,className) ->
    classInspector = new ClassInspectorMorph window[className].prototype
    classInspector.fullRawMoveTo world.hand.position()
    classInspector.fullRawMoveWithin world
    world.add classInspector
    classInspector.changed()

  showAttributes: ->
    @showing = "attributes"
    @buildAndConnectChildren()

  showMethods: ->
    @showing = "methods"
    @buildAndConnectChildren()

  showAttributesAndMethods: ->
    @showing = "all"
    @buildAndConnectChildren()

  highlightOwnershipOfProperties: ->
    @markOwnershipOfProperties = not @markOwnershipOfProperties
    @buildAndConnectChildren()


  openShowMenu: ->
    menu = new MenuMorph false
    menu.addItem "attributes", true, @, "showAttributes"
    menu.addItem "methods", true, @, "showMethods"
    menu.addItem "all", true, @, "showAttributesAndMethods"
    menu.addLine()
    menu.addItem ((if @markOwnershipOfProperties then "un-mark ownership" else "mark ownership")), true, @, "highlightOwnershipOfProperties", "highlight\nownership of properties"
    menu.popUpAtHand @firstContainerMenu()

  openInspectorMenu: ->
    if isObject @currentProperty
      menu = new MenuMorph false
      menu.addItem "in new inspector...", true, @, =>
        inspector = new @constructor @currentProperty
        inspector.fullRawMoveTo world.hand.position()
        inspector.fullRawMoveWithin world
        world.add inspector
        inspector.changed()

      menu.addItem "here...", true, @, =>
        @setTarget @currentProperty

      menu.popUpAtHand @firstContainerMenu()
    else
      @inform ((if @currentProperty is null then "null" else typeof @currentProperty)) + "\nis not inspectable"

  openEditMenu: ->
    menu = new MenuMorph false
    menu.addItem "save", true, @, "save", "accept changes"
    menu.addLine()
    menu.addItem "add property...", true, @, "addPropertyPopout"
    menu.addItem "rename...", true, @, "renamePropertyPopout"
    menu.addItem "remove", true, @, "removeProperty"
    menu.popUpAtHand @firstContainerMenu()


  filterProperties: (staticProperties, targetOwnMethods)->
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
        [new Color(255, 165, 0),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            element in staticProperties
        ],
        [new Color(0, 180, 0),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            (Object::hasOwnProperty.call(@target, element))
        ],
        [new Color(180, 0, 0),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            (element in targetOwnMethods)
        ]
      ]
    else
      return null

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
          if goingUpTargetProtChain.constructor.klass.propertiesSources[selected]?
            val = goingUpTargetProtChain.constructor.klass.propertiesSources[selected]
            break
          goingUpTargetProtChain = goingUpTargetProtChain.__proto__
      txt = val.toString()
    else
      # this is for finding the static variables
      if val is undefined
        val = @target.constructor[selected]
      
      if val is null
        txt = "null"
      else if isString val
        txt = '"'+val+'"'
      else
        txt = val.toString()

    cnts = new TextMorph txt
    cnts.isEditable = true
    cnts.enableSelecting()
    cnts.setReceiver @target
    @detail.setContents cnts, 2
  
  layoutSubmorphs: (morphStartingTheChange = null) ->
    super morphStartingTheChange
    console.log "fixing the layout of the inspector"

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
    labelBottom = @label.bottom()

    # classes diagram
    justAcounter = 10
    anotherCount = 0
    # reverse works in-place, so we need to remember
    # to put them back right after we are done
    @classesButtons.reverse()
    for eachClassButton in @classesButtons
      if eachClassButton.parent == @
        eachClassButton.fullRawMoveTo new Point(Math.round(labelLeft + justAcounter), Math.round(labelBottom + justAcounter))
        eachClassButton.rawSetExtent new Point 120, 15
        justAcounter += 20
      anotherCount++
    @classesButtons.reverse()


    # list
    listWidth = Math.floor(@width() / 3)
    listWidth -= @padding
    b = @bottom() - (2 * @padding) - WorldMorph.preferencesAndSettings.handleSize
    listHeight = b - labelBottom - classDiagrHeight
    listBottom = labelBottom + listHeight + classDiagrHeight
    if @list.parent == @
      @list.fullRawMoveTo new Point labelLeft, labelBottom + classDiagrHeight
      @list.rawSetExtent new Point listWidth, listHeight

    # detail
    detailLeft = labelLeft + listWidth + @padding
    detailRight = @right() - @padding
    detailWidth = detailRight - detailLeft
    if @detail.parent == @
      @detail.fullRawMoveTo new Point detailLeft, labelBottom + classDiagrHeight
      @detail.rawSetExtent new Point(detailWidth, listHeight).round()

    # properties button
    propertiesLeft = labelLeft
    propertiesTop = listBottom + @padding
    propertiesWidth = listWidth
    propertiesHeight = WorldMorph.preferencesAndSettings.handleSize
    if @buttonSubset.parent == @
      @buttonSubset.fullRawMoveTo new Point propertiesLeft, propertiesTop
      @buttonSubset.rawSetExtent new Point propertiesWidth, propertiesHeight

    # inspect button
    inspectLeft = detailLeft
    inspectWidth = detailWidth - @padding - WorldMorph.preferencesAndSettings.handleSize
    inspectWidth = Math.round inspectWidth / 3 - @padding / 3
    inspectRight = inspectLeft + inspectWidth
    if @buttonInspect.parent == @
      @buttonInspect.fullRawMoveTo new Point inspectLeft, propertiesTop
      @buttonInspect.rawSetExtent new Point inspectWidth, propertiesHeight

    # edit button
    editLeft = inspectRight + @padding
    editRight = editLeft + inspectWidth
    if @buttonEdit.parent == @
      @buttonEdit.fullRawMoveTo new Point editLeft, propertiesTop
      @buttonEdit.rawSetExtent new Point inspectWidth, propertiesHeight


    trackChanges.pop()
    @changed()
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

  notifyInstancesOfSourceChange: (propertiesArray)->
    @target.sourceChanged()
  
  #InspectorMorph2 editing ops:
  save: ->
    txt = @detail.contents.children[0].text.toString()
    propertyName = @list.selected.labelString
    # inject code will also break the layout and the morph
    @target.injectCode propertyName, txt

  # TODO should have a removeProperty method in Morph (and in the classes somehow)
  # rather than here 
  addProperty: (ignoringThis, morphWithProperty) ->
    prop = morphWithProperty.text.text
    if prop?
      if prop.getValue?
        prop = prop.getValue()
      @target[prop] = null
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

      @currentProperty = null
      @buildAndConnectChildren()
      @notifyInstancesOfSourceChange([propertyName])
    catch err
      @inform err
