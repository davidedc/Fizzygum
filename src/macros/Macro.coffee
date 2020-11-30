# this file is excluded from the fizzygum homepage build
# TODO make this immutable, and use getters

class Macro
  body: nil
  theArguments: []
  name: nil

  constructor: (@name, @theArguments, @body) ->

  @fromString: (macroString) ->

    iDRegexp = "[a-zA-Z0-9]+"
    macroAndParamsRegexp = new RegExp "^Macro[ ]+" + iDRegexp +
     "[ ]+(" + iDRegexp + ")" + # first param
     ("[ ]*\\|?[ ]*(" + iDRegexp + ")?").repeat(9) + # up to 9 more optional params
     "[ ]*$", 'm'

    macroStringFirstLine = (macroString.split "\n")[0]

    # get the macro name
    matches = macroStringFirstLine.match /^Macro[ ]+([a-zA-Z0-9]*).*$/m
    name = matches[1]

    # if there is one to 10 params, then parse them
    theArguments = []
    if matches = macroStringFirstLine.match macroAndParamsRegexp
      for paramNumber in [0...10]
        if matches[paramNumber+1]? then theArguments.push matches[paramNumber+1]

    return new @ name, theArguments, macroString
