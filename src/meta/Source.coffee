# this file is excluded from the fizzygum homepage build

class Source

  string: nil

  constructor: (@string) ->

  stripComments: ->
    @string.replace /^ *#.*$/gm, ""

  toString: ->
    @string
