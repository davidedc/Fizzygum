# this file is excluded from the fizzygum homepage build

class InspectorMorph extends BoxMorph

  target: nil
  currentProperty: nil
  showing: "attributes"
  markOwnershipOfProperties: false
  # panes:
  label: nil
  list: nil
  detail: nil
  work: nil
  buttonInspect: nil
  buttonClose: nil
  buttonSubset: nil
  buttonEdit: nil
  resizer: nil
  padding: nil

  constructor: (@target) ->
    super()
    # override inherited properties:
    @silentRawSetExtent new Point(WorldMorph.preferencesAndSettings.handleSize * 20,
      WorldMorph.preferencesAndSettings.handleSize * 20 * 2 / 3).round()
    @padding = if WorldMorph.preferencesAndSettings.isFlat then 1 else 5
    @color = Color.create 60, 60, 60
    @buildAndConnectChildren()  if @target
  
  inspectObject: (objectToBeInspected) ->
    @target = objectToBeInspected
    @currentProperty = nil
    @buildAndConnectChildren()
  
  buildAndConnectChildren: ->
    if Automator? and
     Automator.state != Automator.IDLE and
     Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    attribs = []

    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    # label
    @label = new TextMorph @target.toString().replace "Wdgt", ""
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.isBold = true
    @label.color = Color.WHITE
    @add @label
    
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

    # filter out some fields we don't want to see...
    attribs = attribs.filter((prop) => !prop.includes "_class_injected_in" )
    attribs = attribs.filter((prop) => prop != "instances")
    #attribs = attribs.filter((prop) => !prop.includes "function " )
    #attribs = attribs.unique()

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
    
    # caches the own methods of the object
    if @markOwnershipOfProperties
      targetOwnMethods = Object.getOwnPropertyNames @target.constructor::
      #alert targetOwnMethods

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
      @filterProperties(staticProperties, targetOwnMethods), #format
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
    world.steppingWdgts.delete @list.listContents
    @add @list

    # we add a Widget alignment here because adjusting IDs whenever
    # we add or remove methods is a pain...
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()


    # details pane
    @detail = new ScrollPanelWdgt
    @detail.disableDrops()
    @detail.contents.disableDrops()
    @detail.isTextLineWrapping = true
    @detail.color = Color.WHITE
    ctrl = new TextMorph ""
    ctrl.isEditable = true
    ctrl.enableSelecting()
    ctrl.setReceiver @target
    @detail.setContents ctrl, 2
    @add @detail

    # work ('evaluation') pane
    @work = new ScrollPanelWdgt
    @work.disableDrops()
    @work.contents.disableDrops()
    @work.isTextLineWrapping = true
    @work.color = Color.WHITE
    ev = new TextMorph ""
    ev.isEditable = true
    ev.enableSelecting()
    ev.setReceiver @target
    @work.setContents ev, 2
    @add @work

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

    # close button
    @buttonClose = new TriggerMorph true, @
    @buttonClose.setLabel "close"
    @buttonClose.alignCenter()
    @buttonClose.action = "close"
    @add @buttonClose

    # resizer
    @resizer = new HandleMorph @

    # update layout
    @invalidateLayout()

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
    menu = new MenuMorph @, false
    menu.addMenuItem "attributes", true, @, "showAttributes"
    menu.addMenuItem "methods", true, @, "showMethods"
    menu.addMenuItem "all", true, @, "showAttributesAndMethods"
    menu.addLine()
    menu.addMenuItem ((if @markOwnershipOfProperties then "un-mark ownership" else "mark ownership")), true, @, "highlightOwnershipOfProperties", "highlight\nownership of properties"
    menu.popUpAtHand()

  openInspectorMenu: ->
    if isObject @currentProperty
      menu = new MenuMorph @, false
      menu.addMenuItem "in new inspector...", true, @, =>
        inspector = new @constructor @currentProperty
        inspector.fullRawMoveTo world.hand.position()
        inspector.fullRawMoveWithin world
        world.add inspector
        inspector.changed()

      menu.addMenuItem "here...", true, @, =>
        @inspectObject @currentProperty

      menu.popUpAtHand()
    else
      @inform ((if !@currentProperty? then "nil" else typeof @currentProperty)) + "\nis not inspectable"

  openEditMenu: ->
    menu = new MenuMorph @, false
    menu.addMenuItem "save", true, @, "save", "accept changes"
    menu.addLine()
    menu.addMenuItem "add property...", true, @, "addPropertyPopout"
    menu.addMenuItem "rename...", true, @, "renamePropertyPopout"
    menu.addMenuItem "remove", true, @, "removeProperty"
    menu.popUpAtHand()


  filterProperties: (staticProperties, targetOwnMethods)->
    if @markOwnershipOfProperties
      return [
        # give color criteria from the most general to the most specific
        [Color.create(0, 0, 180),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            true
        ],
        [Color.create(255, 165, 0),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            element in staticProperties
        ],
        [Color.create(0, 180, 0),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            (Object::hasOwnProperty.call(@target, element))
        ],
        [Color.create(180, 0, 0),
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
      return nil

  selectionFromList: (selected) ->
    if selected == undefined then return
    val = @target[selected]
    # this is for finding the static variables
    if val is undefined
      val = @target.constructor[selected]
    @currentProperty = val
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
    #if !window.recalculatingLayouts
    #  debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      @notifyAllChildrenRecursivelyThatParentHasReLayouted()
      return

    @rawSetBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    # label
    labelLeft = @left() + @padding
    labelTop = @top() + @padding
    labelRight = @right() - @padding
    labelWidth = labelRight - labelLeft
    if @label.parent == @
      @label.fullRawMoveTo new Point labelLeft, labelTop
      @label.rawSetWidth labelWidth
      if @label.height() > @height() - 50
        @silentRawSetHeight @label.height() + 50
        # TODO run the tests when commenting this out
        # because this one point to the Widget implementation
        # which is empty.
        @reLayout()
        
        @changed()
        @resizer.silentUpdateResizerHandlePosition()

    # list
    labelBottom = labelTop + @label.height() + 2
    listWidth = Math.floor(@width() / 3)
    listWidth -= @padding
    b = @bottom() - (2 * @padding) - WorldMorph.preferencesAndSettings.handleSize
    listHeight = b - labelBottom
    listBottom = labelBottom + listHeight
    if @list.parent == @
      @list.fullRawMoveTo new Point labelLeft, labelBottom
      @list.rawSetExtent new Point listWidth, listHeight

    # detail
    detailLeft = labelLeft + listWidth + @padding
    detailRight = @right() - @padding
    detailWidth = detailRight - detailLeft
    if @detail.parent == @
      @detail.fullRawMoveTo new Point detailLeft, labelBottom
      @detail.rawSetExtent new Point(detailWidth, (listHeight * 2 / 3) - @padding).round()

    # work
    workTop = Math.round labelBottom + (listHeight * 2 / 3)
    if @work.parent == @
      @work.fullRawMoveTo new Point detailLeft, workTop
      @work.rawSetExtent new Point(detailWidth, listHeight / 3).round()

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

    # close button
    closeLeft = editRight + @padding
    closeRight = detailRight - @padding - WorldMorph.preferencesAndSettings.handleSize
    closeWidth = closeRight - closeLeft
    if @buttonClose.parent == @
      @buttonClose.fullRawMoveTo new Point closeLeft, propertiesTop
      @buttonClose.rawSetExtent new Point closeWidth, propertiesHeight

    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyAllChildrenRecursivelyThatParentHasReLayouted()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

  
  
  #InspectorMorph editing ops:
  save: ->
    txt = @detail.contents.children[0].text.toString()
    propertyName = @list.selected.labelString

    try
      # this.target[propertyName] = evaluate txt
      @target.evaluateString "this." + propertyName + " = " + txt
      @target.reLayout?()      
      @target.changed?()
    catch err
      @inform err

  addProperty: (ignoringThis, morphWithProperty) ->
    prop = morphWithProperty.text.text
    if prop?
      if prop.getValue?
        prop = prop.getValue()
      @target[prop] = nil
      @buildAndConnectChildren()
      @target.reLayout?()      
      @target.changed?()
  
  addPropertyPopout: ->
    @prompt "new property name:", @, "addProperty", "property" # Chrome cannot handle empty strings (others do)

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
    @target.reLayout?()    
    @target.changed?()
  
  renamePropertyPopout: ->
    propertyName = @list.selected.labelString
    @prompt "property name:", @, "renameProperty", propertyName
  
  removeProperty: ->
    propertyName = @list.selected.labelString
    try
      delete @target[propertyName]

      @currentProperty = nil
      @buildAndConnectChildren()
      @target.reLayout?()      
      @target.changed?()
    catch err
      @inform err
