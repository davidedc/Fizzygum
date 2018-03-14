## from https://github.com/viruschidai/lru-cache
## used for LRU cache

class DoubleLinkedList
  constructor:  ->
    @headNode = @tailNode = nil

  # removes the last element. Since
  # we move used elements to head, the last
  # element is *probably* a relatively
  # unused one.
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
    @headNode = @tailNode = nil