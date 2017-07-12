# ListMorph ///////////////////////////////////////////////////////////

class ListMorph extends ScrollFrameMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype
  
  elements: null
  labelGetter: null
  format: null
  listContents: null # a MenuMorph with the contents of the list
  selected: null # actual element currently selected
  active: null # menu item representing the selected element
  action: null
  target: null
  doubleClickAction: null

  constructor: (
    @target,
    @action,
    @elements = [],
    @labelGetter = (element) ->
        return element  if isString element
        return element.toSource()  if element.toSource
        element.toString()
    ,

    @format = [],
    @doubleClickAction = null
    ) ->
    #
    #    passing a format is optional. If the format parameter is specified
    #    it has to be of the following pattern:
    #
    #        [
    #            [<color>, <single-argument predicate>],
    #            ['bold', <single-argument predicate>],
    #            ['italic', <single-argument predicate>],
    #            ...
    #        ]
    #
    #    multiple conditions can be passed in such a format list, the
    #    last predicate to evaluate true when given the list element sets
    #    the given format category (color, bold, italic).
    #    If no condition is met, the default format (color black, non-bold,
    #    non-italic) will be assigned.
    #    
    #    An example of how to use formats can be found in the InspectorMorph's
    #    "markOwnProperties" mechanism.
    #
    #debugger
    super()
    @contents.disableDrops()
    @color = new Color 255, 255, 255
    @buildAndConnectChildren() # builds the list contents
    # it's important to leave the step as the default noOperation
    # instead of null because the scrollbars (inherited from scrollframe)
    # need the step function to react to mouse floatDrag.
  
  # builds the list contents
  buildAndConnectChildren: ->
    if @listContents
      @listContents = @listContents.destroy()
    @listContents = new MenuMorph @, true, @, false, false, null, null
    @elements = ["(empty)"]  if !@elements.length
    trackChanges.push false
    @elements.forEach (element) =>
      color = null
      bold = false
      italic = false
      @format.forEach (pair) ->
        if pair[1].call null, element
          switch pair[0]
            when 'bold'
              bold = true
            when 'italic'
              italic = true
            else # assume it's a color
              color = pair[0]

      #labelString,
      #action,
      #hint,
      #color,
      #bold = false,
      #italic = false,
      #doubleClickAction # optional, when used as list contents

      console.log "@labelGetter(element): " + @labelGetter(element)
      @listContents.addMenuItem(
        @labelGetter(element), # labelString
        true,
        @, # target
        "select", # action
        null, # hint
        color, # color
        bold, # bold
        italic, # italic
        @doubleClickAction # doubleClickAction
      )

    trackChanges.pop()
    @listContents.silentFullRawMoveTo @contents.position()
    @listContents.reLayout()
    
    @add @listContents
  
  select: (item, trigger) ->
    @selected = item
    @active = trigger
    if @action
      if typeof @action is "function"
        console.log "listmorph selection invoked with function"
        debugger
        @action.call @target, item.labelString
      else # assume it's a String
        @target[@action].call @target, item.labelString
  
  rawSetExtent: (aPoint) ->
    unless aPoint.eq @extent()
      #console.log "move 3"
      @breakNumberOfRawMovesAndResizesCaches()
      lb = @listContents.boundingBox()
      nb = @bounds.origin.corner @bounds.origin.add aPoint
      if nb.right() > lb.right() and nb.width() <= lb.width()
        @listContents.fullRawMoveRightSideTo nb.right()
      if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
        @listContents.fullRawMoveBottomSideTo nb.bottom()
      super aPoint
