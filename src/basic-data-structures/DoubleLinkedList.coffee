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

  # ⚠ must clear the node's OWN links first: moveToHead re-inserts a node that still
  # carries its old pre/next, and a stale `pre` makes the NEXT remove of that node
  # rewire the wrong neighbor -- the tail then names an already-evicted entry, the
  # LRU's eviction no-ops, and (its size check being exact equality) the cache grows
  # UNBOUNDED. Measured: capacity 20, size 4999 under set/get churn.
  insertBeginning: (node) ->
    node.pre = undefined
    if @headNode
      node.next = @headNode
      @headNode.pre = node
      @headNode = node
    else
      node.next = undefined
      @headNode = @tailNode = node

  moveToHead: (node) ->
    @remove node
    @insertBeginning node

  clear: ->
    @headNode = @tailNode = undefined