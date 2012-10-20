# ListMorph ///////////////////////////////////////////////////////////

class ListMorph extends ScrollFrameMorph
  constructor: (elements, labelGetter, format) ->
  
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
    @init elements or [], labelGetter or (element) ->
      return element  if isString(element)
      return element.toSource()  if element.toSource
      element.toString()
    , format or []

ListMorph::init = (elements, labelGetter, format) ->
  super()
  @contents.acceptsDrops = false
  @color = new Color(255, 255, 255)
  @hBar.alpha = 0.6
  @vBar.alpha = 0.6
  @elements = elements or []
  @labelGetter = labelGetter
  @format = format
  @listContents = null
  @selected = null
  @action = null
  @acceptsDrops = false
  @buildListContents()

ListMorph::buildListContents = ->
  @listContents.destroy()  if @listContents
  @listContents = new MenuMorph(@select, null, this)
  @elements = ["(empty)"]  if @elements.length is 0
  @elements.forEach (element) =>
    color = null
    @format.forEach (pair) ->
      color = pair[0]  if pair[1].call(null, element)
    
    # label string
    # action
    # hint
    @listContents.addItem @labelGetter(element), element, null, color

  @listContents.setPosition @contents.position()
  @listContents.isListContents = true
  @listContents.drawNew()
  @addContents @listContents

ListMorph::select = (item) ->
  @selected = item
  @action.call null, item  if @action

ListMorph::setExtent = (aPoint) ->
  lb = @listContents.bounds
  nb = @bounds.origin.copy().corner(@bounds.origin.add(aPoint))
  @listContents.setRight nb.right()  if nb.right() > lb.right() and nb.width() <= lb.width()
  @listContents.setBottom nb.bottom()  if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
  super aPoint