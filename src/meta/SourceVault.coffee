# this file is excluded from the fizzygum homepage build

class SourceVault

  # Simply run from console:
  #   SourceVault.runAllAnalyses()
  @runAllAnalyses: ->
    console.log "allSourcesContainingReLayoutCall -----------------"
    console.log @allSourcesContainingReLayoutCall()

    console.log "allSourcesContainingQuestionMark -----------------"
    console.log @allSourcesContainingQuestionMark()

    console.log "allSourcesWithDoLayout -----------------"
    console.log @allSourcesWithDoLayout()

    console.log "allSourcesContainingStringifiedCodeForScript -----------------"
    console.log @allSourcesContainingStringifiedCodeForScript()

    console.log "allSourcesWithDoLayoutCallingRaw -----------------"
    console.log @allSourcesWithDoLayoutCallingRaw()

    console.log "allSourcesWithReLayoutMethod -----------------"
    console.log @allSourcesWithReLayoutMethod()

    # private fields should not be accessed via dot notation
    # they should rather be accessed only by "this" object
    # i.e. like @_privateField
    console.log "referencesToNonLocalPrivateFields -----------------"
    console.log @referencesToNonLocalPrivateFields()

    console.log "allTrailingWhiteSpaces -----------------"
    @allTrailingWhiteSpaces()

    console.log "allTODOs -----------------"
    @allTODOs()

    console.log "allScheduledChecks -----------------"
    @allScheduledChecks()

    console.log "allSourcesWithDoLayoutWithoutStandardStructure -----------------"
    @allSourcesWithDoLayoutWithoutStandardStructure()

    console.log "allUnused -----------------"
    @allUnused()

    return

  @getSourceContent: (sourceFileName) ->
    if !window[sourceFileName]?
      return nil
    stringToBeReturned = new Source window[sourceFileName]
    return stringToBeReturned

  @allSourceFilesNames: ->
    Object.keys(window).filter (eachSourceFileName) =>
      eachSourceFileName.endsWith "_coffeSource"
  
  @allSourcesContainingReLayoutCall: ->
    @allSourceFilesNames().filter (eachSourceFileName) =>
      @getSourceContent(eachSourceFileName).stripComments().match /[@\.]_reLayoutSelf/
  
  @allSourcesContainingQuestionMark: ->
    @allSourceFilesNames().filter (eachSourceFileName) =>
      @getSourceContent(eachSourceFileName).stripComments().match /\?/

  # there should rarely be stringified code - scripts should
  # be rare beasts in core codebase. They should only be privilege
  # of user code, and ideally even there they should be temporary
  # and eventually migrated to code in a class somewhere.
  @allSourcesContainingStringifiedCodeForScript: ->
    theRegexp = /scriptWdgt \= new ScriptWdgt """/g
    @allSourceFilesNames().filter (eachSourceFileName) =>
      eachSource = @getSourceContent(eachSourceFileName).stripComments()
      # nifty way to count regex matches https://stackoverflow.com/a/1072782
      matchCount = ((eachSource || '').match(theRegexp) || []).length
      if matchCount
        console.log eachSourceFileName + " : " + matchCount + " matches of stringified code (scripts)"
  
  @allSourcesJustClassName: ->
    @allSourceFilesNames().map (eachSourceFileName) =>
      eachSourceFileName.replace "_coffeSource", ""
  
  @allSourcesWithDoLayout: ->
    @allSourcesJustClassName().filter (eachSource) =>
      window[eachSource]?.class?.nonStaticPropertiesSources._reLayout?
  
  # unused, this is now included in a bigger check we do on the _reLayout source
  @allSourcesWithDoLayoutWithoutSuper: ->
    @allSourcesWithDoLayout().filter (eachSource) =>
      if eachSource == "Widget" then return false
      doLayoutMethod = NonStaticPropertyOfClassSource.fromFileAndMethodName eachSource, "_reLayout"
      doLayoutMethod = doLayoutMethod.stripComments().collapseLinesWithOnlySpaces().collapseLastEmptyLines()
      doLayoutLineByLine = doLayoutMethod.split "\n"
      doLayoutLastLines = doLayoutLineByLine.slice Math.max doLayoutLineByLine.length - 5, 1
      doLayoutLastLinesJoined = doLayoutLastLines.join "\n"
      if doLayoutLastLinesJoined.includes "super"
        return false
      console.log eachSource + "-------------------------"
      console.log doLayoutLastLinesJoined
      return true

  @allSourcesWithDoLayoutCallingRaw: ->
    @allSourcesWithDoLayout().filter (eachSource) =>
      doLayoutMethod = NonStaticPropertyOfClassSource.fromFileAndMethodName eachSource, "_reLayout"
      doLayoutMethod = doLayoutMethod.stripComments()
      if doLayoutMethod.match /raw/i
        console.log "x " + eachSource
        return true
      else
        console.log "✓ " + eachSource
        return false

  @allSourcesWithReLayoutMethod: ->
    @allSourcesJustClassName().filter (eachSource) =>
      window[eachSource]?.class?.nonStaticPropertiesSources._reLayoutSelf?

  @allTrailingWhiteSpaces: ->
    @highlightRegex [/[^\s#][ ]+$/gm],[/[^\s#]([ ]+)$/gm],["🡆$1🡄"]

  @referencesToNonLocalPrivateFields: ->
    @highlightRegex [/[^\.][\.]_/gm],[/([^\.][\.]_)/gm],["🡆$1🡄"], nil, ((matches) -> !(matches.includes("_proto") or matches.includes("_super")))

  @highlightRegex: (regexesArray, replaceWhatRegexesArray, replaceWithWhatStringsArray, matchTestFunction, lineTestFunction) ->
    howManyLinesBeforeAndAfter = 5
    for eachSourceFileName in @allSourceFilesNames()
      theSource = @getSourceContent(eachSourceFileName)
      theSourceByLine = theSource.split "\n"
      lineNumber = 0
      for eachLine in theSourceByLine
        lineNumber++
        regexNumber = -1
        for eachRegex in regexesArray
          regexNumber++
          if matches = eachLine.match regexesArray[regexNumber]
            if !lineTestFunction? or (lineTestFunction? and lineTestFunction eachLine)
              if !matchTestFunction? or (matchTestFunction? and matchTestFunction matches)
                theSourceByLine[lineNumber-1] = theSourceByLine[lineNumber-1].replace replaceWhatRegexesArray[regexNumber], replaceWithWhatStringsArray[regexNumber]
                for aBitBeforeABitAfter in [-(howManyLinesBeforeAndAfter+1)...howManyLinesBeforeAndAfter]
                  if lineNumber + aBitBeforeABitAfter >= 0 and lineNumber + aBitBeforeABitAfter < theSourceByLine.length
                    console.log eachSourceFileName + " line " + (lineNumber+aBitBeforeABitAfter) + " >" + theSourceByLine[lineNumber+aBitBeforeABitAfter]
                console.log "-----------------------------------------------"
    return # avoid returning a ton of junk

  @allTODOs: ->
    @highlightRegex [/^ *# *.*TODO/gi],[/(todo)/gi],["🡆$1🡄"]

  # Here follows just a test of this very function
  # CHECK AFTER 1 Jan 0 00:00:00 GMT
  @allScheduledChecks: ->
    @highlightRegex [/CHECK AFTER (.*)/gi],[/(CHECK AFTER .*)/gi],["🡆$1🡄"], ((matches) -> Date.parse(matches[0]) < new Date)

  @allUnused: ->
    @highlightRegex [/^ *# *.*unused/gi, /^ *# *.*not *used/gi],[/(unused)/gi, /(not *used)/gi],["🡆$1🡄", "🡆$1🡄"]

  @allSourcesWithDoLayoutWithoutStandardStructure: ->
    @allSourcesWithDoLayout().filter (eachSource) =>
      if eachSource == "Widget" then return false
      doLayoutMethod = NonStaticPropertyOfClassSource.fromFileAndMethodName eachSource, "_reLayout"
      doLayoutMethod = doLayoutMethod.stripComments().collapseLinesWithOnlySpaces().collapseLastEmptyLines()
      if doLayoutMethod.match /newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout\s*if @_handleCollapsedStateShouldWeReturn\(\) then return\s*@rawSetBounds newBoundsForThisLayout\s*world.disableTrackChanges\(\)/m
        if doLayoutMethod.match /world.maybeEnableTrackChanges\(\)\s*super\s*@markLayoutAsFixed\(\)/
          return false
      console.log eachSource + "-------------------------"
      console.log doLayoutMethod.toString()
      return true

