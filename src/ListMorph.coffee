# ListMorph ///////////////////////////////////////////////////////////

class ListMorph extends ScrollFrameMorph
  
  elements: null
  labelGetter: null
  format: null
  listContents: null
  selected: null # actual element currently selected
  active: null # menu item representing the selected element
  action: null
  doubleClickAction: null

  constructor: (@elements = [], labelGetter, @format = [], @doubleClickAction = null) ->
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
    #    An example of how to use fomats can be found in the InspectorMorph's
    #    "markOwnProperties" mechanism.
    #
    super()
    @contents.acceptsDrops = false
    @color = new Color(255, 255, 255)
    @hBar.alpha = 0.6
    @vBar.alpha = 0.6
    @labelGetter = labelGetter or (element) ->
        return element  if isString(element)
        return element.toSource()  if element.toSource
        element.toString()
    @buildListContents()
    # it's important to leave the step as the default noOperation
    # instead of null because the scrollbars (inherited from scrollframe)
    # need the step function to react to mouse drag.
  
  buildListContents: ->
    @listContents.destroy()  if @listContents
    @listContents = new MenuMorph(@select, null, @)
    @elements = ["(empty)"]  if !@elements.length
    @elements.forEach (element) =>
      color = null
      bold = false
      italic = false
      @format.forEach (pair) ->
        if pair[1].call(null, element)
          if pair[0] == 'bold'
            bold = true
          else if pair[0] == 'italic'
            italic = true
          else # assume it's a color
            color = pair[0]
      #
      # label string
      # action
      # hint
      @listContents.addItem @labelGetter(element), element, null, color, bold, italic, @doubleClickAction
    #
    @listContents.setPosition @contents.position()
    @listContents.isListContents = true
    @listContents.updateRendering()
    @addContents @listContents
  
  select: (item, trigger) ->
    @selected = item
    @active = trigger
    @action.call null, item  if @action
  
  setExtent: (aPoint) ->
    lb = @listContents.bounds
    nb = @bounds.origin.copy().corner(@bounds.origin.add(aPoint))
    if nb.right() > lb.right() and nb.width() <= lb.width()
      @listContents.setRight nb.right()
    if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
      @listContents.setBottom nb.bottom()
    super aPoint
