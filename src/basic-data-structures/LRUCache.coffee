# An LRU cache: it holds at most `capacity` entries, and when a new key arrives at a full cache it evicts the
# LEAST RECENTLY USED one. A Map keeps its keys in insertion order, so that order IS the recency order: a hit takes
# its key out and puts it back (now the most recent), and an eviction drops the first key, the least recent.
#
# The eviction asks the Map for its first key afresh each time. A Map keeps a deleted key's slot until it compacts,
# so on a large cache under pure eviction churn (every operation a new key) that walk passes the holes earlier
# evictions left: there an eviction costs about 270 ns where a linked list cost about 95; with hits in between, and
# on every cache size and hit/eviction mix the suite produces, this class is faster (measured; the trade was the
# owner's, docs/plans/top-10-cleanups-round-3-plan.md §2). Keeping ONE iterator instead would be faster still, but
# a Map iterator pins every table the Map has outgrown until it advances — memory a cache that rarely evicts never
# gives back.
#
# A key is kept as given: the Map tells the number 5 from the text "5" (each cache asks with one kind of key).
# Entries never expire with TIME: an entry goes stale only when what it was computed from changes (a class's code is
# edited, a font atlas arrives), and its owner then resets or removes it (WorldWdgt.noteCodeChanged,
# noteColdGlyphRegionsWarm), never by age.

class LRUCache

  # the number of entries held, kept beside the Map so that WorldInventory reads it (with capacity) as it reads
  # every self-capping store
  size: 0

  constructor: (@capacity = 10) ->
    @reset()

  # every key held, least recently used first
  keys: ->
    Array.from @_entries.keys()

  remove: (key) ->
    @_entries.delete key
    @size = @_entries.size
    return

  reset: ->
    @_entries = new Map
    @size = 0
    return

  set: (key, value) ->
    if @_entries.has key
      @_entries.delete key
    else if @_entries.size >= @capacity
      @_entries.delete @_entries.keys().next().value
    @_entries.set key, value
    @size = @_entries.size
    return

  # a hit makes its key the most recent; a value of `undefined` is told from a miss by asking the Map
  get: (key) ->
    value = @_entries.get key
    return undefined if value is undefined and not @_entries.has key
    @_entries.delete key
    @_entries.set key, value
    value

  has: (key) ->
    @_entries.has key
