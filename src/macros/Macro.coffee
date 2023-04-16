# this file is only needed for Macros
# IMMUTABLE

# In the first macro implementation there were some nice shortcuts/symbols
# to make things more readable. However I'm concerned that this might
# hinder help from LLMs...
#
# However, for reference, the "shortcuts" were:
#    1s -> 1*1000
#    macroString = macroString.replace /([ \d])s([\s,])/mg, "$1*1000$2"
#
#    2ms -> 2
#    macroString = macroString.replace /([ \d])ms([\s,])/mg, "$1$2"
#
#    🌎var1 -> @macroVars.var1
#    macroString = macroString.replace /🌎/g, "@macroVars."    
#
#    🖨️var1 -> console.log var1
#    macroString = macroString.replace /🖨️/g, "console.log"
#
#    ⦿(x,y) -> new Point(x,y)
#    macroString = macroString.replace /⦿/g, "new Point"
#
#    ⌛1s -> yield 1*1000
#    macroString = macroString.replace /⌛/g, "yield"

class Macro
  _body: nil
  _name: nil
  _linkedCode: nil

  constructor: (@_name, @_body) ->

  getBody: ->
    @_body

  getName: ->
    @_name

  @fromString: (macroString) ->
    # get the Macro name from the definition i.e.
    # from the line of the form
    #   macroNameMacro =
    matches = macroString.match /([$a-zA-Z_][0-9a-zA-Z_$\(\).\[\]]*)Macro[ ]*=/, 'm'
    macroName = matches[1] + "Macro"
    macroString = @_replaceMacroInvocationWithYieldingInvocations macroString
    return new @ macroName, macroString

  @_replaceMacroInvocationWithYieldingInvocations: (macroString) ->
    # in macroString, replace all invocations of functions like
    #   macroNameMacro args
    # with
    #   yield from macroNameMacro.call this, args
    #
    # the invocation via "call" is needed because generators otherwise will not pick
    # up the right context when next() is called

    # first, replace all macro definitions like
    #   macroNameMacro =
    # with
    #   macroNameDONTSUBSTITUTE =
    # so they don't get in the way of the next two replacements
    macroString = macroString.replace /Macro[ ]*=/g, "DONTSUBSTITUTE ="

    # case with no arguments i.e.
    #   macroNameMacro()
    # becomes
    #   yield from macroNameMacro.call this 
    macroString = macroString.replace /([^ ]*)Macro\(\)/g, (match, p1) ->
      "yield from #{p1}Macro.call this"

    # case with arguments like example at the top
    macroString = macroString.replace /([^ ]*)Macro([^\(])/g, (match, p1, p2) ->
      "yield from #{p1}Macro.call this, #{p2}"

    # put back the macro definitions as they should be
    macroString = macroString.replace /DONTSUBSTITUTE/g, "Macro"

    return macroString

  _addHeaderCode: (linkedMacro) ->
    return """
      @progressOnMacroSteps = ->
        # we do this only once to initialise things
        if !@macroGenerator?
          @syntheticEventsMousePlace()
          @msSinceLastExecutedMacroStep = 0
          @macroGenerator = theTestMacro.call @
          return

        return unless @noCodeLoading()
        if @returnFromLastMacroStep is "waitNoInputsOngoing"
          return unless @noInputsOngoing()
        else if @returnFromLastMacroStep? # it's the number of milliseconds
          return unless @msSinceLastExecutedMacroStep > @returnFromLastMacroStep

        next = @macroGenerator.next()
        @msSinceLastExecutedMacroStep = 0
        if next.done
          @progressOnMacroSteps = noOperation
          @aMacroIsRunning = false
        else
          @returnFromLastMacroStep = next.value
    """ + "\n\n\n" + linkedMacro


  linkTo: (macroSubroutines) ->

    theWholeCode = @_body    
    # do the same for all the macroSubroutines
    for eachMacro from macroSubroutines
      theWholeCode += "\n\n" + eachMacro._body

    @_linkedCode = @_addHeaderCode theWholeCode
    console.log @_linkedCode

  start: ->
    world.msSinceLastExecutedMacroStep = 0
    world.macroGenerator = nil
    world.returnFromLastMacroStep = nil

    #world.macroVars = {} # a dedicated global space for macros. Unused so far.
    world.aMacroIsRunning = true

    console.log @_linkedCode
    world.evaluateString @_linkedCode
