## from https://github.com/viruschidai/lru-cache
## used for LRU cache

class DoubleLinkedList
  constructor:  ->
    @headNode = @tailNode = null

  remove: (node) ->
    if node.pre
      node.pre = node.next
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
    @headNode = @tailNode = null