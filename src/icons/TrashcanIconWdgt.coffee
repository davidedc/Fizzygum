# this file is excluded from the fizzygum homepage build

class TrashcanIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new TrashcanIconAppearance @


