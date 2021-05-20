# this file is only needed for Macros
# IMMUTABLE

class Macro
  _body: nil
  _arguments: []
  _name: nil
  _preliminarySubstitutionsBody: nil

  constructor: (@_name, @_arguments, @_body) ->

  getBody: ->
    @_body

  getArguments: ->
    @_arguments

  getName: ->
    @_name

  getPreliminarySubstitutionsBody: ->
    @_preliminarySubstitutionsBody ?= @_doPreliminarySubstitutions()

  @fromString: (macroString) ->

    iDRegexp = "[a-zA-Z0-9]+"
    macroPreambleRegexp = "^Macro[ ]+"

    macroAndParamsRegexp = new RegExp macroPreambleRegexp + iDRegexp +
     "[ ]+(" + iDRegexp + ")" + # first param
     ("[ ]*\\|?[ ]*(" + iDRegexp + ")?").repeat(9) + # up to 9 more optional params
     "[ ]*$", 'm'

    macroStringFirstLine = (macroString.split "\n")[0]

    # get the macro name
    matches = macroStringFirstLine.match new RegExp macroPreambleRegexp + "(" + iDRegexp + ").*$", 'm'
    name = matches[1]

    # if there is one to 10 params, then parse them
    theArguments = []
    if matches = macroStringFirstLine.match macroAndParamsRegexp
      for paramNumber in [0...10]
        if matches[paramNumber+1]? then theArguments.push matches[paramNumber+1]

    return new @ name, theArguments, macroString


  _doPreliminarySubstitutions: ->
    macroString = @getBody()
    macroString = macroString.replace /^Macro[ ]+([a-zA-Z0-9]+).*$/mg, "  # Macro $1"
    macroString = macroString.replace /^[ ]*🠶?[ ]*⤷/mg, "  ⤷"

    macroString = macroString.replace /^  /mg, "      "

    macroString = macroString.replace /([ \d])s([\s,])/mg, "$1*1000$2"
    macroString = macroString.replace /([ \d])ms([\s,])/mg, "$1$2"

    macroString = macroString.replace /🌎/g, "@macroVars."    
    macroString = macroString.replace /🖶/g, "console.log"
    macroString = macroString.replace /⦿/g, "new Point"

    macroStringByLine = macroString.split "\n"
    lineNumber = 0
    for eachLine in macroStringByLine

      comment = ""
      if matches = eachLine.match /#(.*)/
        comment = " #" + matches[1]
        eachLine = eachLine.replace /#(.*)/, ""


      if eachLine.match /^ 🠶/
        macroStringByLine[lineNumber] = """
                @nextBlockToBeRun++; @macroStepsWaitingTimer = 0
            when ?this_number__to_be_inserted_by_linker
        """.replace(/^/mg, "  ")
        macroStringByLine[lineNumber] += "\n    if @noCodeLoading() and @macroStepsWaitingTimer > "

        if matches = eachLine.match /⌛ *(\d+ *\* *1000)/
          macroStringByLine[lineNumber] += matches[1]
        else if matches = eachLine.match /⌛ *(\d+)/
          macroStringByLine[lineNumber] += matches[1]
        else
          macroStringByLine[lineNumber] += "100"

        if matches = eachLine.match /when *(.*)/
          macroStringByLine[lineNumber] += " and " + matches[1]

        macroStringByLine[lineNumber] += comment


      lineNumber++
    macroString = macroStringByLine.join "\n"
    macroString = macroString.replace /no inputs ongoing/g, "@noInputsOngoing()"

  linkToSubroutines: (macroSubroutines) ->

    MAX_MACRO_EXPANSIONS = 10000
    callSiteRegexString = "^[ ]*⤷"


    anyMacroFound = true
    macroCallsExpansionLoopsCount = 0

    linkedMacroString = @getPreliminarySubstitutionsBody().replace /💼/g, "@macroVars.expansion#{macroCallsExpansionLoopsCount}." 

    while anyMacroFound
      if macroCallsExpansionLoopsCount > MAX_MACRO_EXPANSIONS
        console.log "too many macro expansions (infinite loop?)"
        debugger
        throw "too many macro expansions (infinite loop?)"
      anyMacroFound = false
      if linkedMacroString.match new RegExp callSiteRegexString,'m'
        for eachMacro from macroSubroutines
          matches = nil
          if matches = linkedMacroString.match(new RegExp callSiteRegexString + eachMacro.getName() + "([ ]+.*$|[ ]*#.*$|$)",'m')
            line = matches[0]
            
            # extract the inline comment at call site, we want
            # to preserve it in the final translation
            comment = ""
            # this is a sloppy regex that could match "macroNamePlusSomethingElse #...",
            # however the regex we just did is tight, so there is no risk with this one
            if matchesComment = line.match(new RegExp callSiteRegexString + eachMacro.getName() + ".*(#.*)$",'m')
              comment = matchesComment[1]

            line = line.replace /#.*/,""

            anyMacroFound = true
            macroCallsExpansionLoopsCount++

            macroBody = eachMacro.getPreliminarySubstitutionsBody()

            # note that this parses up to 10 parameters,
            # including any space before the pipe (we're gonna trim it later)
            # also note that the first parameter is mandatory in this match,
            # and everything beyond it (including the pipe) is optional
            matches = line.match new RegExp callSiteRegexString + eachMacro.getName() +
             "[ ]+([^|\\n]+)[ ]*" + # first parameter
             "\\|?[ ]*([^|\\n]+)?[ ]*".repeat(9) + # up to 9 other optional parameters
             "$" , 'm'

            for paramNumber in [0...10]
              if eachMacro.getArguments()[paramNumber]?
                if matches?[paramNumber+1]?
                  replaceWithThis = matches[paramNumber+1].trim()
                else
                  replaceWithThis = "nil"
                macroBody = macroBody.replace (new RegExp(eachMacro.getArguments()[paramNumber],'gm')), replaceWithThis

            if comment != ""
              macroBody = macroBody.replace /(# Macro \w+)$/m, "$1 " + comment

            # substitute the call line (including params) with the body
            linkedMacroString = linkedMacroString.replace (new RegExp(callSiteRegexString + eachMacro.getName() + "([ ]+.*$|[ ]*#.*$|$)",'m')), macroBody
            linkedMacroString = linkedMacroString.replace /💼/g, "@macroVars.expansion#{macroCallsExpansionLoopsCount}."
    

    for i in [0..macroCallsExpansionLoopsCount]
      linkedMacroString = "      @macroVars.expansion#{i} ?= {}\n" + linkedMacroString


    # we start with 2 because 0 and 1 are already taken by
    # two previous sections
    thenNumber = 2
    thenNumbersRegex = new RegExp "\\?this_number__to_be_inserted_by_linker"
    while linkedMacroString.match thenNumbersRegex
      linkedMacroString = linkedMacroString.replace thenNumbersRegex, "#{thenNumber}"
      thenNumber++

    return linkedMacroString

  getRunnableMacroStepsCode: (macroSubroutines) ->

    # .replace /^/mg, "  " is to add a couple of spaces to
    # the start of the line so indentation is correct
    linkedMacro = (@linkToSubroutines macroSubroutines).replace /^/mg, "  "

    headerCode = """
      currentTime = WorldMorph.dateOfCurrentCycleStart.getTime()
      switch (@nextBlockToBeRun)
        when 0
          @syntheticEventsMousePlace()
          @nextBlockToBeRun = 1; @macroStepsWaitingTimer = 0
        when 1
          if @noCodeLoading() and @macroStepsWaitingTimer > 100 and @noInputsOngoing()
    """.replace /^/mg, "  "

    code = "@progressOnMacroSteps = ->\n" + headerCode + "\n" + linkedMacro + "\n        @nextBlockToBeRun = -1; @progressOnMacroSteps = noOperation; @macroIsRunning = false"
