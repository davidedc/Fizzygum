# this file is excluded from the fizzygum homepage build

class SourceVault

  @runAllAnalyses: ->
    console.log "allSourcesContainingReLayoutCall -----------------"
    console.log @allSourcesContainingReLayoutCall()

    console.log "allSourcesContainingQuestionMark -----------------"
    console.log @allSourcesContainingQuestionMark()

    console.log "allSourcesWithDoLayout -----------------"
    console.log @allSourcesWithDoLayout()

    console.log "allSourcesContainingStringifiedCodeForScript -----------------"
    console.log @allSourcesContainingStringifiedCodeForScript()

    console.log "allSourcesWithDoLayoutWithoutSuper -----------------"
    console.log @allSourcesWithDoLayoutWithoutSuper()

    console.log "allSourcesWithDoLayoutCallingRaw -----------------"
    console.log @allSourcesWithDoLayoutCallingRaw()

    console.log "allSourcesWithReLayoutMethod -----------------"
    console.log @allSourcesWithReLayoutMethod()

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
      @getSourceContent(eachSourceFileName).stripComments().match /[@\.]reLayout/
  
  @allSourcesContainingQuestionMark: ->
    @allSourceFilesNames().filter (eachSourceFileName) =>
      @getSourceContent(eachSourceFileName).stripComments().match /\?/

  # there should rarely be stringified code - scripts should
  # be rare beasts in core codebase. They should only be priviledge
  # of user code, and ideally even there they should be temporary
  # and eventually migrated to code in a class somewhere.
  @allSourcesContainingStringifiedCodeForScript: ->
    theRegexp = /scriptWdgt \= new ScriptWdgt """/g
    @allSourceFilesNames().filter (eachSourceFileName) =>
      eachSource = @getSourceContent(eachSourceFileName).stripComments()
      # nifty way to count regex matches https://stackoverflow.com/a/1072782
      matchCount = ((eachSource || '').match(theRegexp) || []).length
      if matchCount
        console.log eachSourceFileName + " : " + matchCount + " matches of stringified code (for script)"
  
  @allSourcesJustClassName: ->
    @allSourceFilesNames().map (eachSourceFileName) =>
      eachSourceFileName.replace "_coffeSource", ""
  
  @allSourcesWithDoLayout: ->
    @allSourcesJustClassName().filter (eachSource) =>
      window[eachSource]?.class?.nonStaticPropertiesSources.doLayout?
  
  @allSourcesWithDoLayoutWithoutSuper: ->
    @allSourcesWithDoLayout().filter (eachSource) =>
      if eachSource == "Widget" then return false
      doLayoutMethod = NonStaticPropertyOfClassSource.fromFileAndMethodName eachSource, "doLayout"
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
      doLayoutMethod = NonStaticPropertyOfClassSource.fromFileAndMethodName eachSource, "doLayout"
      doLayoutMethod = doLayoutMethod.stripComments()
      if doLayoutMethod.match /raw/i
        console.log "x " + eachSource
        return true
      else
        console.log "✓ " + eachSource
        return false

  @allSourcesWithReLayoutMethod: ->
    @allSourcesJustClassName().filter (eachSource) =>
      window[eachSource]?.class?.nonStaticPropertiesSources.reLayout?
