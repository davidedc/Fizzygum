# InspectorMorph //////////////////////////////////////////////////////

class InspectorMorph extends BoxMorph
  constructor: (target) ->
    # additional properties:
    @target = target
    @currentProperty = null
    @showing = "attributes"
    @markOwnProperties = false
    #
    # initialize inherited properties:
    super()
    #
    # override inherited properties:
    @silentSetExtent new Point(MorphicPreferences.handleSize * 20, MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @drawNew()
    #
    # panes:
    @label = null
    @list = null
    @detail = null
    @work = null
    @buttonInspect = null
    @buttonClose = null
    @buttonSubset = null
    @buttonEdit = null
    @resizer = null
    @buildPanes()  if @target
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []
    property = undefined
    ctrl = undefined
    ev = undefined
    #
    # remove existing panes
    @children.forEach (m) ->
      # keep work pane around
      m.destroy()  if m isnt @work
    #
    @children = []
    #
    # label
    @label = new TextMorph(@target.toString())
    @label.fontSize = MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.drawNew()
    @add @label
    #
    # properties list
    for property of @target
      # dummy condition, to be refined
      attribs.push property  if property
    if @showing is "attributes"
      attribs = attribs.filter((prop) =>
        typeof @target[prop] isnt "function"
      )
    else if @showing is "methods"
      attribs = attribs.filter((prop) =>
        typeof @target[prop] is "function"
      )
    # otherwise show all properties
    # label getter
    # format list
    # format element: [color, predicate(element]
    @list = new ListMorph((if @target instanceof Array then attribs else attribs.sort()), null, (if @markOwnProperties then [[new Color(0, 0, 180), (element) =>
      @target.hasOwnProperty element
    ]] else null))
    @list.action = (selected) =>
      val = undefined
      txt = undefined
      cnts = undefined
      val = @target[selected]
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
    # don't refresh the work pane if it already exists
    if @work is null
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
      menu = undefined
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
      menu.addItem ((if @markOwnProperties then "un-mark own" else "mark own")), (=>
        @markOwnProperties = not @markOwnProperties
        @buildPanes()
      ), "highlight\n'own' properties"
      menu.popUpAtHand @world()
    #
    @add @buttonSubset
    #
    # inspect button
    @buttonInspect = new TriggerMorph()
    @buttonInspect.labelString = "inspect..."
    @buttonInspect.action = =>
      menu = undefined
      world = undefined
      inspector = undefined
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
      menu = undefined
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
    x = undefined
    y = undefined
    r = undefined
    b = undefined
    w = undefined
    h = undefined
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
      @drawNew()
      @changed()
      @resizer.drawNew()
    #
    # list
    y = @label.bottom() + 2
    w = Math.min(Math.floor(@width() / 3), @list.listContents.width())
    w -= @edge
    b = @bottom() - (2 * @edge) - MorphicPreferences.handleSize
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
    h = MorphicPreferences.handleSize
    @buttonSubset.setPosition new Point(x, y)
    @buttonSubset.setExtent new Point(w, h)
    #
    # inspect button
    x = @detail.left()
    w = @detail.width() - @edge - MorphicPreferences.handleSize
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
    r = @detail.right() - @edge - MorphicPreferences.handleSize
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
      if @target.drawNew
        @target.changed()
        @target.drawNew()
        @target.changed()
    catch err
      @inform err
  
  addProperty: ->
    @prompt "new property name:", ((prop) =>
      if prop
        @target[prop] = null
        @buildPanes()
        if @target.drawNew
          @target.changed()
          @target.drawNew()
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
      if @target.drawNew
        @target.changed()
        @target.drawNew()
        @target.changed()
    ), @, propertyName
  
  removeProperty: ->
    prop = @list.selected
    try
      delete (@target[prop])
      #
      @currentProperty = null
      @buildPanes()
      if @target.drawNew
        @target.changed()
        @target.drawNew()
        @target.changed()
    catch err
      @inform err
