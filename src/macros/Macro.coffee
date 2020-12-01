# this file is excluded from the fizzygum homepage build
# TODO make this immutable, and use getters

class Macro
  body: nil
  theArguments: []
  name: nil
  translated: nil

  constructor: (@name, @theArguments, @body) ->
    @translated = @translateMacro()

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


  translateMacro: ->
    theMacro = @body
    theMacro = theMacro.replace /^Macro[ ]+([a-zA-Z0-9]*).*$/mg, "  # Macro $1\n  noOperation()"
    theMacro = theMacro.replace /^[ ]*🠶?[ ]*⤷/mg, "  ⤷"

    theMacro = theMacro.replace /^  /mg, "      "

    theMacro = theMacro.replace /([ \d])s([\s,])/mg, "$1*1000$2"
    theMacro = theMacro.replace /([ \d])ms([\s,])/mg, "$1$2"

    theMacro = theMacro.replace /🌎/g, "@macroVars."    
    theMacro = theMacro.replace /🖶/g, "console.log"
    theMacro = theMacro.replace /⦿/g, "new Point"

    theMacroByLine = theMacro.split "\n"
    lineNumber = 0
    for eachLine in theMacroByLine

      comment = ""
      if matches = eachLine.match /#(.*)/
        comment = " #" + matches[1]
        eachLine = eachLine.replace /#(.*)/, ""


      if eachLine.match /^ 🠶/
        theMacroByLine[lineNumber] = """
                @nextBlockToBeRun++; @macroStepsWaitingTimer = 0
            when ?this_number__to_be_inserted_by_linker
        """.replace(/^/mg, "  ")
        theMacroByLine[lineNumber] += "\n    if @noCodeLoading() and @macroStepsWaitingTimer > "

        if matches = eachLine.match /⌛ *(\d+ *\* *1000)/
          theMacroByLine[lineNumber] += matches[1]
        else if matches = eachLine.match /⌛ *(\d+)/
          theMacroByLine[lineNumber] += matches[1]
        else
          theMacroByLine[lineNumber] += "100"

        if matches = eachLine.match /when *(.*)/
          theMacroByLine[lineNumber] += " and " + matches[1]

        theMacroByLine[lineNumber] += comment


      lineNumber++
    theMacro = theMacroByLine.join "\n"
    theMacro = theMacro.replace /no inputs ongoing/g, "@noInputsOngoing()"
