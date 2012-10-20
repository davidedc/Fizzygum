class MorphicNode
  constructor: (parent, childrenArray) ->
    @init parent or null, childrenArray or []

MorphicNode::init = (parent, childrenArray) ->
  @parent = parent or null
  @children = childrenArray or []


# MorphicNode string representation: e.g. 'a MorphicNode[3]'
MorphicNode::toString = ->
  "a MorphicNode" + "[" + @children.length.toString() + "]"


# MorphicNode accessing:
MorphicNode::addChild = (aMorphicNode) ->
  @children.push aMorphicNode
  aMorphicNode.parent = this

MorphicNode::addChildFirst = (aMorphicNode) ->
  @children.splice 0, null, aMorphicNode
  aMorphicNode.parent = this

MorphicNode::removeChild = (aMorphicNode) ->
  idx = @children.indexOf(aMorphicNode)
  @children.splice idx, 1  if idx isnt -1


# MorphicNode functions:
MorphicNode::root = ->
  return this  if @parent is null
  @parent.root()

MorphicNode::depth = ->
  return 0  if @parent is null
  @parent.depth() + 1

MorphicNode::allChildren = ->
  
  # includes myself
  result = [this]
  @children.forEach (child) ->
    result = result.concat(child.allChildren())
  
  result

MorphicNode::forAllChildren = (aFunction) ->
  if @children.length > 0
    @children.forEach (child) ->
      child.forAllChildren aFunction
  
  aFunction.call null, this

MorphicNode::allLeafs = ->
  result = []
  @allChildren().forEach (element) ->
    result.push element  if element.children.length is 0
  
  result

MorphicNode::allParents = ->
  
  # includes myself
  result = [this]
  result = result.concat(@parent.allParents())  if @parent isnt null
  result

MorphicNode::siblings = ->
  return []  if @parent is null
  @parent.children.filter (child) =>
    child isnt @


MorphicNode::parentThatIsA = (constructor) ->
  
  # including myself
  return this  if this instanceof constructor
  return null  unless @parent
  @parent.parentThatIsA constructor

MorphicNode::parentThatIsAnyOf = (constructors) ->
  
  # including myself
  yup = false
  constructors.forEach (each) =>
    if @constructor is each
      yup = true
      return
  
  return this  if yup
  return null  unless @parent
  @parent.parentThatIsAnyOf constructors
