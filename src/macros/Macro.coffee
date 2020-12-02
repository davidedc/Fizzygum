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

  linkToSubroutines: (macroSubroutines) ->

    MAX_MACRO_EXPANSIONS = 10000
    callSiteRegexString = "^[ ]*⤷"


    anyMacroFound = true
    macroCallsExpansionLoopsCount = 0

    theMacro = @translated.replace /💼/g, "@macroVars.expansion#{macroCallsExpansionLoopsCount}." 

    while anyMacroFound
      if macroCallsExpansionLoopsCount > MAX_MACRO_EXPANSIONS
        console.log "too many macro expansions (infinite loop?)"
        debugger
        throw "too many macro expansions (infinite loop?)"
      anyMacroFound = false
      if theMacro.match new RegExp callSiteRegexString,'m'
        for eachMacro from macroSubroutines
          matches = nil
          if matches = theMacro.match(new RegExp callSiteRegexString + eachMacro.name + "([ ]+.*$|[ ]*#.*$|$)",'m')
            line = matches[0]
            
            # extract the inline comment at call site, we want
            # to preserve it in the final translation
            comment = ""
            # this is a sloppy regex that could match "macroNamePlusSometingElse #...",
            # however the regex we just did is tight, so there is no risk with this one
            if matchesComment = line.match(new RegExp callSiteRegexString + eachMacro.name + ".*(#.*)$",'m')
              comment = matchesComment[1]

            line = line.replace /#.*/,""

            anyMacroFound = true
            macroCallsExpansionLoopsCount++

            macroBody = eachMacro.translated

            # note that this parses up to 10 parameters,
            # including any space before the pipe (we're gonna trim it later)
            # also note that the first parameter is mandatory in this match,
            # and everything beyond it (including the pipe) is optional
            matches = line.match new RegExp callSiteRegexString + eachMacro.name +
             "[ ]+([^|\\n]+)[ ]*" + # first parameter
             "\\|?[ ]*([^|\\n]+)?[ ]*".repeat(9) + # up to 9 other optional parameters
             "$" , 'm'

            for paramNumber in [0...10]
              if eachMacro.theArguments[paramNumber]?
                if matches?[paramNumber+1]?
                  replaceWithThis = matches[paramNumber+1].trim()
                else
                  replaceWithThis = "nil"
                macroBody = macroBody.replace (new RegExp(eachMacro.theArguments[paramNumber],'gm')), replaceWithThis

            if comment != ""
              macroBody = macroBody.replace /(# Macro \w+)$/m, "$1 " + comment

            # substitute the call line (including params) with the body
            theMacro = theMacro.replace (new RegExp(callSiteRegexString + eachMacro.name + "([ ]+.*$|[ ]*#.*$|$)",'m')), macroBody
            theMacro = theMacro.replace /💼/g, "@macroVars.expansion#{macroCallsExpansionLoopsCount}."
    

    for i in [0..macroCallsExpansionLoopsCount]
      theMacro = "      @macroVars.expansion#{i} ?= {}\n" + theMacro


    thenNumber = 0
    thenNumbersRegex = new RegExp "\\?this_number__to_be_inserted_by_linker"
    while theMacro.match thenNumbersRegex
      theMacro = theMacro.replace thenNumbersRegex, "#{thenNumber}"
      thenNumber++

    return theMacro
