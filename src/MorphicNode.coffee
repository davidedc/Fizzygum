class MorphicNode

  parent: null
  children: null

  constructor: (@parent = null, @children = []) ->
  
  
  # MorphicNode string representation: e.g. 'a MorphicNode[3]'
  toString: ->
    "a MorphicNode" + "[" + @children.length.toString() + "]"
  
  
  # MorphicNode accessing:
  addChild: (aMorphicNode) ->
    @children.push aMorphicNode
    aMorphicNode.parent = @
  
  addChildFirst: (aMorphicNode) ->
    @children.splice 0, null, aMorphicNode
    aMorphicNode.parent = @
  
  removeChild: (aMorphicNode) ->
    idx = @children.indexOf(aMorphicNode)
    @children.splice idx, 1  if idx isnt -1
  
  
  # MorphicNode functions:
  root: ->
    return @parent.root() if @parent?
    @
  
  # currently unused
  depth: ->
    return 0  if !@parent?
    @parent.depth() + 1
  
  allChildren: ->
    # includes myself
    result = [@]
    @children.forEach (child) ->
      result = result.concat(child.allChildren())
    #
    result
  
  forAllChildren: (aFunction) ->
    if @children.length
      @children.forEach (child) ->
        child.forAllChildren aFunction
    #
    aFunction.call null, @
  
  allLeafs: ->
    result = []
    @allChildren().forEach (element) ->
      result.push element  if !element.children.length
    #
    result
  
  allParents: ->
    # includes myself
    result = [@]
    result = result.concat(@parent.allParents())  if @parent isnt null
    result
  
  siblings: ->
    return []  if @parent is null
    @parent.children.filter (child) =>
      child isnt @
  
  parentThatIsA: (constructor) ->
    # including myself
    return @  if @ instanceof constructor
    return null  unless @parent
    @parent.parentThatIsA constructor
  
  parentThatIsAnyOf: (constructors) ->
    # including myself
    yup = false
    constructors.forEach (each) =>
      if @constructor is each
        yup = true
        return
    #
    return @  if yup
    return null  unless @parent
    @parent.parentThatIsAnyOf constructors
