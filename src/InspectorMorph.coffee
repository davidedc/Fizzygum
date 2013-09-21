# InspectorMorph //////////////////////////////////////////////////////

class InspectorMorph extends BoxMorph

  target: null
  currentProperty: null
  showing: "attributes"
  markOwnershipOfProperties: false
  # panes:
  label: null
  list: null
  detail: null
  work: null
  buttonInspect: null
  buttonClose: null
  buttonSubset: null
  buttonEdit: null
  resizer: null

  constructor: (@target) ->
    super()
    # override inherited properties:
    @silentSetExtent new Point(WorldMorph.MorphicPreferences.handleSize * 20,
      WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = if WorldMorph.MorphicPreferences.isFlat then 1 else 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @updateRendering()
    @buildPanes()  if @target
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []
    #
    # remove existing panes
    @destroyAll()

    #
    @children = []
    #
    # label
    @label = new TextMorph(@target.toString())
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.updateRendering()
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
    if @showing is "attributes"
      attribs = attribs.filter((prop) =>
        not isFunction @target[prop]
      )
    else if @showing is "methods"
      attribs = attribs.filter((prop) =>
        isFunction @target[prop]
      )
    # otherwise show all properties
    # label getter
    # format list
    # format element: [color, predicate(element]
    
    staticProperties = Object.getOwnPropertyNames(@target.constructor)
    # get rid of all the standar fuff properties that are in classes
    staticProperties = staticProperties.filter((prop) =>
        prop not in ["name","length","prototype","caller","__super__","arguments"]
    )
    if @showing is "attributes"
      staticFunctions = []
      staticAttributes = staticProperties.filter((prop) =>
        not isFunction(@target.constructor[prop])
      )
    else if @showing is "methods"
      staticFunctions = staticProperties.filter((prop) =>
        isFunction(@target.constructor[prop])
      )
      staticAttributes = []
    else
      staticFunctions = staticProperties.filter((prop) =>
        isFunction(@target.constructor[prop])
      )
      staticAttributes = staticProperties.filter((prop) =>
        prop not in staticFunctions
      )
    #alert "stat fun " + staticFunctions + " stat attr " + staticAttributes
    attribs = (attribs.concat staticFunctions).concat staticAttributes
    #alert " all attribs " + attribs
    
    # caches the own methods of the object
    if @markOwnershipOfProperties
      targetOwnMethods = Object.getOwnPropertyNames(@target.constructor.prototype)
      #alert targetOwnMethods

    doubleClickAction = =>
      if (!isObject(@currentProperty))
        return
      world = @world()
      inspector = new InspectorMorph @currentProperty
      inspector.setPosition world.hand.position()
      inspector.keepWithin world
      world.add inspector
      inspector.changed()

    @list = new ListMorph((if @target instanceof Array then attribs else attribs.sort()), null,(
      if @markOwnershipOfProperties
        [
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
              (Object.prototype.hasOwnProperty.call(@target, element))
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
      else null
    ),doubleClickAction)

    @list.action = (selected) =>
      if (selected == undefined) then return
      val = @target[selected]
      # this is for finding the static variables
      if val is undefined
        val = @target.constructor[selected]
      @currentProperty = val
      if val is null
        txt = "NULL"
      else if isString(val)
        txt = val
      else
        txt = val.toString()
      cnts = new TextMorph(txt)
      cnts.isEditable = true
      cnts.enableSelecting()
      cnts.setReceiver @target
      @detail.setContents cnts
    #
    @list.hBar.alpha = 0.6
    @list.vBar.alpha = 0.6
    # we know that the content of this list in this pane is not going to need the
    # step function, so we disable that from here by setting it to null, which
    # prevents the recursion to children. We could have disabled that from the
    # constructor of MenuMorph, but who knows, maybe someone might intend to use a MenuMorph
    # with some animated content? We know that in this specific case it won't need animation so
    # we set that here. Note that the ListMorph itself does require animation because of the
    # scrollbars, but the MenuMorph (which contains the actual list contents)
    # in this context doesn't.
    @list.listContents.step = null
    @add @list
    #
    # details pane
    @detail = new ScrollFrameMorph()
    @detail.acceptsDrops = false
    @detail.contents.acceptsDrops = false
    @detail.isTextLineWrapping = true
    @detail.color = new Color(255, 255, 255)
    @detail.hBar.alpha = 0.6
    @detail.vBar.alpha = 0.6
    ctrl = new TextMorph("")
    ctrl.isEditable = true
    ctrl.enableSelecting()
    ctrl.setReceiver @target
    @detail.setContents ctrl
    @add @detail
    #
    # work ('evaluation') pane
    @work = new ScrollFrameMorph()
    @work.acceptsDrops = false
    @work.contents.acceptsDrops = false
    @work.isTextLineWrapping = true
    @work.color = new Color(255, 255, 255)
    @work.hBar.alpha = 0.6
    @work.vBar.alpha = 0.6
    ev = new TextMorph("")
    ev.isEditable = true
    ev.enableSelecting()
    ev.setReceiver @target
    @work.setContents ev
    @add @work
    #
    # properties button
    @buttonSubset = new TriggerMorph()
    @buttonSubset.labelString = "show..."
    @buttonSubset.action = =>
      menu = new MenuMorph()
      menu.addItem "attributes", =>
        @showing = "attributes"
        @buildPanes()
      #
      menu.addItem "methods", =>
        @showing = "methods"
        @buildPanes()
      #
      menu.addItem "all", =>
        @showing = "all"
        @buildPanes()
      #
      menu.addLine()
      menu.addItem ((if @markOwnershipOfProperties then "un-mark ownership" else "mark ownership")), (=>
        @markOwnershipOfProperties = not @markOwnershipOfProperties
        @buildPanes()
      ), "highlight\nownership of properties"
      menu.popUpAtHand @world()
    #
    @add @buttonSubset
    #
    # inspect button
    @buttonInspect = new TriggerMorph()
    @buttonInspect.labelString = "inspect..."
    @buttonInspect.action = =>
      if isObject(@currentProperty)
        menu = new MenuMorph()
        menu.addItem "in new inspector...", =>
          world = @world()
          inspector = new InspectorMorph(@currentProperty)
          inspector.setPosition world.hand.position()
          inspector.keepWithin world
          world.add inspector
          inspector.changed()
        #
        menu.addItem "here...", =>
          @setTarget @currentProperty
        #
        menu.popUpAtHand @world()
      else
        @inform ((if @currentProperty is null then "null" else typeof @currentProperty)) + "\nis not inspectable"
    #
    @add @buttonInspect
    #
    # edit button
    @buttonEdit = new TriggerMorph()
    @buttonEdit.labelString = "edit..."
    @buttonEdit.action = =>
      menu = new MenuMorph(@)
      menu.addItem "save", "save", "accept changes"
      menu.addLine()
      menu.addItem "add property...", "addProperty"
      menu.addItem "rename...", "renameProperty"
      menu.addItem "remove...", "removeProperty"
      menu.popUpAtHand @world()
    #
    @add @buttonEdit
    #
    # close button
    @buttonClose = new TriggerMorph()
    @buttonClose.labelString = "close"
    @buttonClose.action = =>
      @destroy()
    #
    @add @buttonClose
    #
    # resizer
    @resizer = new HandleMorph(@, 150, 100, @edge, @edge)
    #
    # update layout
    @fixLayout()
  
  fixLayout: ->
    Morph::trackChanges = false
    #
    # label
    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x
    @label.setPosition new Point(x, y)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @silentSetHeight @label.height() + 50
      @updateRendering()
      @changed()
      @resizer.updateRendering()
    #
    # list
    y = @label.bottom() + 2
    w = Math.min(Math.floor(@width() / 3), @list.listContents.width())
    w -= @edge
    b = @bottom() - (2 * @edge) - WorldMorph.MorphicPreferences.handleSize
    h = b - y
    @list.setPosition new Point(x, y)
    @list.setExtent new Point(w, h)
    #
    # detail
    x = @list.right() + @edge
    r = @right() - @edge
    w = r - x
    @detail.setPosition new Point(x, y)
    @detail.setExtent new Point(w, (h * 2 / 3) - @edge)
    #
    # work
    y = @detail.bottom() + @edge
    @work.setPosition new Point(x, y)
    @work.setExtent new Point(w, h / 3)
    #
    # properties button
    x = @list.left()
    y = @list.bottom() + @edge
    w = @list.width()
    h = WorldMorph.MorphicPreferences.handleSize
    @buttonSubset.setPosition new Point(x, y)
    @buttonSubset.setExtent new Point(w, h)
    #
    # inspect button
    x = @detail.left()
    w = @detail.width() - @edge - WorldMorph.MorphicPreferences.handleSize
    w = w / 3 - @edge / 3
    @buttonInspect.setPosition new Point(x, y)
    @buttonInspect.setExtent new Point(w, h)
    #
    # edit button
    x = @buttonInspect.right() + @edge
    @buttonEdit.setPosition new Point(x, y)
    @buttonEdit.setExtent new Point(w, h)
    #
    # close button
    x = @buttonEdit.right() + @edge
    r = @detail.right() - @edge - WorldMorph.MorphicPreferences.handleSize
    w = r - x
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
    @fixLayout()
  
  
  #InspectorMorph editing ops:
  save: ->
    txt = @detail.contents.children[0].text.toString()
    prop = @list.selected
    try
      #
      # this.target[prop] = evaluate(txt);
      @target.evaluateString "this." + prop + " = " + txt
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    catch err
      @inform err
  
  addProperty: ->
    @prompt "new property name:", ((prop) =>
      if prop
        @target[prop] = null
        @buildPanes()
        if @target.updateRendering
          @target.changed()
          @target.updateRendering()
          @target.changed()
    ), @, "property" # Chrome cannot handle empty strings (others do)
  
  renameProperty: ->
    propertyName = @list.selected
    @prompt "property name:", ((prop) =>
      try
        delete (@target[propertyName])
        @target[prop] = @currentProperty
      catch err
        @inform err
      @buildPanes()
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    ), @, propertyName
  
  removeProperty: ->
    prop = @list.selected
    try
      delete (@target[prop])
      #
      @currentProperty = null
      @buildPanes()
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    catch err
      @inform err
