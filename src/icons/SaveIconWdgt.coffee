# this file is excluded from the fizzygum homepage build

class SaveIconWdgt extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new SaveIconAppearance @

