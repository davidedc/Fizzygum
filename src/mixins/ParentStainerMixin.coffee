# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions


ParentStainerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      setColor: (theColor, ignored, connectionsCalculationToken, superCall) ->
        if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
        super theColor, ignored, connectionsCalculationToken, true
        @parent?.setColor theColor, ignored, connectionsCalculationToken
