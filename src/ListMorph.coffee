# ListMorph ///////////////////////////////////////////////////////////

class ListMorph extends ScrollFrameMorph
  
  elements: null
  labelGetter: null
  format: null
  listContents: null
  selected: null
  action: null

  constructor: (@elements = [], labelGetter, @format = []) ->
    #
    #    passing a format is optional. If the format parameter is specified
    #    it has to be of the following pattern:
    #
    #        [
    #            [<color>, <single-argument predicate>],
    #            ...
    #        ]
    #
    #    multiple color conditions can be passed in such a format list, the
    #    last predicate to evaluate true when given the list element sets
    #    the given color. If no condition is met, the default color (black)
    #    will be assigned.
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
    @elements = ["(empty)"]  if @elements.length is 0
    @elements.forEach (element) =>
      color = null
      @format.forEach (pair) ->
        color = pair[0]  if pair[1].call(null, element)
      #
      # label string
      # action
      # hint
      @listContents.addItem @labelGetter(element), element, null, color
    #
    @listContents.setPosition @contents.position()
    @listContents.isListContents = true
    @listContents.drawNew()
    @addContents @listContents
  
  select: (item) ->
    @selected = item
    @action.call null, item  if @action
  
  setExtent: (aPoint) ->
    lb = @listContents.bounds
    nb = @bounds.origin.copy().corner(@bounds.origin.add(aPoint))
    if nb.right() > lb.right() and nb.width() <= lb.width()
      @listContents.setRight nb.right()
    if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
      @listContents.setBottom nb.bottom()
    super aPoint
