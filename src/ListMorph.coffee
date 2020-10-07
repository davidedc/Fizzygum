class ListMorph extends ScrollPanelWdgt
  
  elements: nil
  labelGetter: nil
  format: nil
  listContents: nil # a MenuMorph with the contents of the list
  selected: nil # actual element currently selected
  active: nil # menu item representing the selected element
  action: nil
  target: nil
  doubleClickAction: nil

  constructor: (
    @target,
    @action,
    @elements = [],
    @labelGetter = (element) ->
        return element  if Utils.isString element
        return element.toSource()  if element.toSource
        element.toString()
    ,

    @format = [],
    @doubleClickAction = nil
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
    @color = Color.WHITE
    @buildAndConnectChildren() # builds the list contents
    # it's important to leave the step as the default noOperation
    # instead of nil because the scrollbars (inherited from ScrollPanel)
    # need the step function to react to mouse floatDrag.
  
  # builds the list contents
  buildAndConnectChildren: ->
    @listContents = new MenuMorph @, true, @, false, false, nil, nil
    @listContents.isLockingToPanels = true
    @elements = ["(empty)"]  if !@elements.length
    trackChanges.push false
    @elements.forEach (element) =>
      color = nil
      bold = false
      italic = false
      @format.forEach (pair) ->
        if pair[1].call nil, element
          switch pair[0]
            when 'bold'
              bold = true
            when 'italic'
              italic = true
            else # assume it's a color
              color = pair[0]

      #labelString,
      #action,
      #toolTipMessage,
      #color,
      #bold = false,
      #italic = false,
      #doubleClickAction # optional, when used as list contents

      #console.log "@labelGetter(element): " + @labelGetter(element)
      @listContents.addMenuItem(
        @labelGetter(element), # labelString
        true,
        @, # target
        "select", # action
        nil, # toolTipMessage
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
    if @action? and @action != ""
      @target[@action].call @target, item.labelString
    return

  
  rawSetExtent: (aPoint) ->
    unless aPoint.equals @extent()
      #console.log "move 3"
      @breakNumberOfRawMovesAndResizesCaches()
      lb = @listContents.boundingBox()
      nb = @bounds.origin.corner @bounds.origin.add aPoint
      if nb.right() > lb.right() and nb.width() <= lb.width()
        @listContents.fullRawMoveRightSideTo nb.right()
      if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
        @listContents.fullRawMoveBottomSideTo nb.bottom()
      super aPoint
