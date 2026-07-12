# this file is only needed for Macros
# IMMUTABLE

# We deliberately avoid cute symbol/shortcut sugar to make macros more readable,
# out of a concern that it might hinder help from LLMs.

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
    #
    # This is what lets one macro INVOKE another macro (a reusable "verb"): the rewrite turns a bare call into
    # a `yield from`, which (a) runs the callee inline so ITS yields — waits, screenshots — propagate to the
    # driver, and (b) makes the call evaluate to the callee's RETURN value, so a verb can hand data back:
    #   [extWin, intWin] = buildExternalAndFreeInternalWindow_Macro()
    # That, in turn, is what makes a SHARED fixture verb possible (build once, return the widgets, reuse from
    # several tests). Both the with-args form (`m a, b`) and the no-arg form (`m()`) are handled below.

    # first, replace all macro definitions like
    #   macroNameMacro =
    # with
    #   macroNameDONTSUBSTITUTE =
    # so they don't get in the way of the next two replacements
    macroString = macroString.replace /Macro[ ]*=/g, "DONTSUBSTITUTE ="

    # IMPORTANT: do the WITH-arguments case FIRST. Its pattern requires a non-"(" char right after
    # "Macro" (the [^\(]), so it naturally skips the no-argument "Macro()" form. Doing it first means the
    # no-argument rewrite below — which introduces a "Macro.call this" — is NOT re-scanned by this pass
    # (which would otherwise match the new "Macro." and double-rewrite a no-arg call into
    # "yield from yield from …Macro.call this, .call this").
    #
    # case with arguments like example at the top
    macroString = macroString.replace /([^ ]*)Macro([^\(])/g, (match, p1, p2) ->
      "yield from #{p1}Macro.call this, #{p2}"

    # case with no arguments i.e.
    #   macroNameMacro()
    # becomes
    #   yield from macroNameMacro.call this
    macroString = macroString.replace /([^ ]*)Macro\(\)/g, (match, p1) ->
      "yield from #{p1}Macro.call this"

    # put back the macro definitions as they should be
    macroString = macroString.replace /DONTSUBSTITUTE/g, "Macro"

    return macroString

  _addHeaderCode: (linkedMacro) ->
    return """
      @progressOnMacroSteps = ->
        # we do this only once to initialise things
        if !@macroGenerator?
          @_syntheticEventsMousePlace_InputEvents()
          @msSinceLastExecutedMacroStep = 0
          @macroGenerator = #{@getName()}.call @
          return

        return unless @noCodeLoading()
        if @returnFromLastMacroStep is "waitNoInputsOngoing"
          return unless @noInputsOngoing()
        else if @returnFromLastMacroStep is "waitForScreenshotReady"
          # a macro's screenshot step: hold until the (SWCanvas) software surface
          # is settled + warm so the captured pixels are deterministic.
          return unless @readyForMacroScreenshot()
        else if @returnFromLastMacroStep is "waitForScreenshotHash"
          # the SWCanvas screenshot hash (crypto.subtle) is ASYNC (perf item H1): hold the
          # macro — and thus the end of the test — until the pending digest has resolved and
          # its verdict + live fingerprint are recorded, so a later assertScreenshotsIdentical
          # sees the fingerprint and the test cannot finish mid-hash. Native/HTML5 hashing is
          # synchronous, so nothing is pending and this settles instantly.
          return unless world.automator.player.screenshotHashSettled()
        else if @returnFromLastMacroStep? # it's the number of milliseconds
          # numeric `yield N` = wait N ms of REAL wall-clock (msSinceLastExecutedMacroStep
          # accrues real per-cycle deltas). This is the NON-scaled real-time SETTLE channel,
          # deliberately independent of the global speed level: the macro EVENT GENERATORS
          # compress gesture time-spans (MacroToolkit.spanFactor), but a `yield N` settle —
          # e.g. holding a drag in an auto-scroll edge band until the framework's Date.now
          # timer clamps, or waiting for a hover bubble — must keep its real duration at every
          # speed. (readyForMacroScreenshot is the other non-scaled gate.) So a yield's N is
          # NOT a gesture span and is never scaled; see src/macros/CLAUDE.md.
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

  start: ->
    world.macroToolkit.msSinceLastExecutedMacroStep = 0
    world.macroToolkit.macroGenerator = nil
    world.macroToolkit.returnFromLastMacroStep = nil

    #world.macroVars = {} # a dedicated global space for macros. Unused so far.
    world.macroToolkit.aMacroIsRunning = true

    world.macroToolkit.evaluateString @_linkedCode
