# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

# splits the array into consecutive sub-arrays of chunkSize.
# NOTE: consumed by the test harness (Fizzygum-tests Automator-and-test-harness-src/
# AutomatorLoader.coffee) to partition tests into parallel shards/groups -- keep it.
Array::chunk = (chunkSize) ->
  array = this
  [].concat.apply [], array.map (elem, i) ->
    if i % chunkSize then [] else [ array.slice(i, i + chunkSize) ]

# removes the elements IN PLACE, i.e. the
# array IS modified
# Also note that the array changes length, so it
# can be messy to use while iterating on it
Array::remove = (theElement) ->
  index = @indexOf theElement
  if index isnt -1
    @splice index, 1
  return @
