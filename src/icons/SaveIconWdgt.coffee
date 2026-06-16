# this file is excluded from the fizzygum homepage build

class SaveIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new SaveIconAppearance @

