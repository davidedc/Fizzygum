class MorphicNode

  parent: null
  # "children" is an ordered list of the immediate
  # children of this node. First child is at the
  # back relative to other children, last child is at the
  # top. The shadow is added as the first child, and it's
  # actually a special child that gets drawn before the
  # others.
  children: null

  constructor: (@parent = null, @children = []) ->
  
  
  # MorphicNode string representation: e.g. 'a MorphicNode[3]'
  toString: ->
    "a MorphicNode" + "[" + @children.length + "]"
  
  
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
    return 0  unless @parent
    @parent.depth() + 1
  
  # Returns all the internal AND terminal nodes in the subtree starting
  # at this node - including this node
  allChildrenTopToBottom: ->
    result = [@] # includes myself
    @children.forEach (child) ->
      result = result.concat(child.allChildrenTopToBottom())
    result

  allChildrenBottomToTop: ->
    arrayShallowCopyAndReverse(@allChildrenTopToBottom())

  # A shorthand to run a function on all the internal/terminal nodes in the subtree
  # starting at this node - including this node.
  # Note that the function is run starting form the "bottom" leaf and the all the
  # way "up" to the current node.
  forAllChildrenTopToBottom: (aFunction) ->
    if @children.length
      @children.forEach (child) ->
        child.forAllChildrenTopToBottom aFunction
    aFunction.call null, @
  
  allLeafs: ->
    result = []
    @allChildrenTopToBottom().forEach (element) ->
      result.push element  if !element.children.length
    #
    result
  
  # Return all "parent" nodes from this node up to the root (including both)
  allParents: ->
    # includes myself
    result = [@]
    result = result.concat(@parent.allParents())  if @parent?
    result
  
  # The direct children of the parent of this node. (current node not included)
  siblings: ->
    return []  unless @parent
    @parent.children.filter (child) =>
      child isnt @
  
  # returns the first parent (going up from this node) that is of a particular class
  # (includes this particular node)
  # This is a subcase of "parentThatIsAnyOf".
  parentThatIsA: (constructor) ->
    # including myself
    return @ if @ instanceof constructor
    return null  unless @parent
    @parent.parentThatIsA constructor
  
  # returns the first parent (going up from this node) that belongs to a set
  # of classes. (includes this particular node).
  parentThatIsAnyOf: (constructors) ->
    # including myself
    constructors.forEach (each) =>
      if @constructor is each
        return @
    #
    return null  unless @parent
    @parent.parentThatIsAnyOf constructors
