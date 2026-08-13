## from https://github.com/viruschidai/lru-cache
## used for LRU cache

class DoubleLinkedList
  constructor:  ->
    @headNode = @tailNode = undefined

  # unlinks the given node, wherever it sits -- the caller picks it.
  # The LRU cache evicts by passing the tail node: used nodes move to
  # head, so the tail is the least-recently-used entry.
  remove: (node) ->
    if node.pre
      node.pre.next = node.next
    else
      @headNode = node.next

    if node.next
      node.next.pre = node.pre
    else
      @tailNode = node.pre

  insertBeginning: (node) ->
    if @headNode
      node.next = @headNode
      @headNode.pre = node
      @headNode = node
    else
      @headNode = @tailNode = node

  moveToHead: (node) ->
    @remove node
    @insertBeginning node

  clear: ->
    @headNode = @tailNode = undefined