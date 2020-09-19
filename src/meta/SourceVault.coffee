# this file is excluded from the fizzygum homepage build

class SourceVault

  @allSourceFilesNames: ->
    Object.keys(window).filter (eachSourceFile) ->
      eachSourceFile.endsWith "_coffeSource"
  
  @allSourcesIncludingReLayoutCall: ->
    @allSourceFilesNames().filter (eachSourceFile) ->
      window[eachSourceFile].replace(/^ *#.*$/gm, "").match /[@\.]reLayout/
  
  @allSourcesIncludingQuestionMark: ->
    @allSourceFilesNames().filter (eachSourceFile) ->
      window[eachSourceFile].replace(/^ *#.*$/gm, "").match /\?/
  
  @allSourcesJustClassName: ->
    @allSourceFilesNames().map (eachSourceFile) ->
      eachSourceFile.replace "_coffeSource", ""
  
  @allSourcesWithDoLayout: ->
    @allSourcesJustClassName().filter (eachSource) ->
      window[eachSource]?.class?.nonStaticPropertiesSources.doLayout?
  
  @allSourcesWithDoLayoutWithoutSuper: ->
    @allSourcesWithDoLayout().filter (eachSource) ->
      if eachSource == "Widget" then return false
      doLayoutMethod = window[eachSource].class.nonStaticPropertiesSources.doLayout.replace(/^ *#.*$/gm, "")
      doLayoutNoEmptyLines = doLayoutMethod.replace /^ *$/gm, ""
      doLayoutNoEmptyLines = doLayoutNoEmptyLines.replace /\n+/g, "\n"
      doLayoutLineByLine = doLayoutNoEmptyLines.split "\n"
      doLayoutLastLines = doLayoutLineByLine.slice Math.max doLayoutLineByLine.length - 5, 1
      doLayoutLastLinesJoined = doLayoutLastLines.join "\n"
      if doLayoutLastLinesJoined.includes "super"
        return false
      console.log eachSource + "-------------------------"
      console.log doLayoutLastLinesJoined
      return true

  @allSourcesWithDoLayoutCallingRaw: ->
    @allSourcesWithDoLayout().filter (eachSource) ->
      doLayoutMethod = window[eachSource].class.nonStaticPropertiesSources.doLayout.replace(/^ *#.*$/gm, "")
      if doLayoutMethod.match /raw/i
        console.log "x " + eachSource
        return true
      else
        console.log "✓ " + eachSource
        return false

  @allSourcesWithReLayoutMethod: ->
    @allSourcesJustClassName().filter (eachSource) ->
      window[eachSource]?.class?.nonStaticPropertiesSources.reLayout?
