# this file is excluded from the fizzygum homepage build

class Source extends ExtendableString

  stripComments: ->
    @replace /^ *#.*$/gm, ""

  collapseLinesWithOnlySpaces: ->
    @replace /^ *$/gm, ""

  collapseLastEmptyLines: ->
    @replace /\n+/g, "\n"

