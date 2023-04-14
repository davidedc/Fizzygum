class InputEventsQueue extends Array

  isEmpty: ->
    @length == 0

  removeUpToIndex: (i) ->
    @splice 0, i

  removeEventsUpTo: (theEvent) ->
    @removeUpToIndex @indexOf(theEvent)

  clear: ->
    @length = 0
