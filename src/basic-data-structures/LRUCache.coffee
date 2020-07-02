## LRU cache
## from https://github.com/viruschidai/lru-cache

# REQUIRES DoubleLinkedList

class LRUCache

  constructor: (@capacity = 10, @maxAge = 60000) ->
    @_linkList = new DoubleLinkedList
    @reset()

  keys: ->
    return Object.keys @_hash

  # »>> this part is excluded from the fizzygum homepage build
  # unused code
  values: ->
    values = @keys().map (key) =>
      @get key
    return values.filter (v) -> v isnt undefined
  # this part is excluded from the fizzygum homepage build <<«

  remove: (key) ->
    if @_hash[key]?
      node = @_hash[key]
      @_linkList.remove node
      delete @_hash[key]
      if node.data.onDispose then node.data.onDispose.call this, node.data.key, node.data.value
      @size--

  reset: ->
    @_hash = {}
    @size = 0
    @_linkList.clear()

  set: (key, value, onDispose) ->
    node = @_hash[key]
    if node
      node.data.value = value
      node.data.onDispose = onDispose
      @_refreshNode node
    else
      if @size is @capacity then @remove @_linkList.tailNode.data.key

      createNode = (data, pre, next) -> {data, pre, next}

      node = createNode {key, value, onDispose}
      node.data.lastVisitTime = Date.now()
      @_linkList.insertBeginning node
      @_hash[key] = node
      @size++
      return

  get: (key) ->
    node = @_hash[key]
    if !node then return undefined
    if @_isExpiredNode node
      @remove key
      return undefined
    @_refreshNode node
    return node.data.value

  _refreshNode: (node) ->
    node.data.lastVisitTime = Date.now()
    @_linkList.moveToHead node

  _isExpiredNode: (node) ->
    return Date.now() - node.data.lastVisitTime > @maxAge

  has: (key) -> return @_hash[key]?
