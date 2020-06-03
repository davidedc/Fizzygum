# some widgets are composed by a number of other widgets,
# and you'd want them all to change color at the same time
# an example is the reference widget, which is composed by
# the "reference arrow" and the "document" icons, and you
# want them to change color (e.g. on hover or click) at the
# same time

ChildrenStainerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      setColor: (theColor, ignored, connectionsCalculationToken, superCall) ->
        if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
        super theColor, ignored, connectionsCalculationToken, true
        for w in @children
          w.setColor theColor, ignored, connectionsCalculationToken
