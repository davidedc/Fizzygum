ParentStainerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      setColor: (theColor, ignored, connectionsCalculationToken, superCall) ->
        return unless @_acceptsConnectionToken connectionsCalculationToken, superCall
        super theColor, ignored, connectionsCalculationToken, true
        @parent?.setColor theColor, ignored, connectionsCalculationToken
