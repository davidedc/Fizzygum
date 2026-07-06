ParentStainerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      setColor: (theColor, ignored) ->
        super theColor, ignored
        @parent?.setColor theColor, ignored
