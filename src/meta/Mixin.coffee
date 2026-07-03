# BUILD-TIME SYNTAX GATE DEPENDENCY:
# buildSystem/check-coffee-syntax.js loads THIS file in Node and drives every shipped
# mixin source through `new Mixin(src, true, false)` (generate-precompiled mode: it
# compiles the source but eval's nothing) to catch CoffeeScript syntax errors at build
# time, before they would otherwise only surface at in-browser boot. That checker
# shims the globals this class touches at construction time (compileFGCode,
# JSSourcesContainer, srcLoadCompileDebugWrites). If you make the constructor read a
# NEW global, add a matching stand-in to that shim or the gate will break.

class Mixin
  @allMixines: []
  nonStaticPropertiesSources: nil
  staticPropertiesSources: nil
  name: ""

  _equivalentforSuper: (aString) ->
    #console.log "removing super from: " + aString

    # coffeescript won't compile "super" unless it's an instance
    # method (i.e. if it comes inside a class), so we need to
    # translate that manually into valid CS that doesn't use super.

    # rephrasing "super" here...
    # we can't compile "super" in a mixin because we can't tell which
    # class this will be mixed in in advance, i.e. at compile time it doesn't
    # belong to a class, so at compile time it doesn't know which class
    # it will be injected in.
    # So that's why _at time of injection_ we need
    # to store the class it's injected in in a special
    # variable... and then at runtime here we use that variable to
    # implement super

    # ORDER MATTERS -- see Class._equivalentforSuper for the full rationale. A bare `super` ending the
    # line (tolerating trailing whitespace and/or an inline `#` comment, which is re-appended) forwards
    # ALL arguments, and MUST run before the `super <arg>` rule below: otherwise a trailing space --
    # before an inline comment, or as stray end-of-line whitespace -- is caught there as `.call this, `
    # with no effective argument, SILENTLY dropping the forwarded arguments (the thin-slice-bug class).
    mixinSuperBase = "window[@[arguments.callee.name + '_class_injected_in']].__super__[arguments.callee.name]"
    aString = aString.replace /super[ \t]*(#[^\n]*)?$/gm, (match, comment) ->
      mixinSuperBase + ".apply(this, arguments)" + (if comment then "  " + comment else "")
    aString = aString.replace(/super /g, mixinSuperBase + ".call this, ")

    # TODO un-translated cases as of yet
    # /super\(\)/g -> ...???...
    # /super\(/g -> ...???...

  # Coffeescript adds some helper functions at the top of the compiled code:
  #
  #  slice = [].slice
  #  indexOf = [].indexOf
  #  hasProp = {}.hasOwnProperty
  #
  # here we remove them them all, because they mangle the code,
  # also we just have them all in the global scope by now so
  # they are not needed multiple times

  _removeHelperFunctions: (aString) ->
    aString = aString.replace /indexOf = [].indexOf/, "$$$$$$"
    aString = aString.replace /hasProp = {}.hasProp/, "$$$$$$"
    aString = aString.replace /slice = [].slice/, "$$$$$$"

    if (aString.includes "[].indexOf") or
     (aString.includes "{}.hasProp") or
     (aString.includes "[].slice")
      console.log "code contains a helper var, it shouldn't: " +  aString
      debugger

    return aString

  constructor: (source, generatePreCompiledJS, createMixin) ->

    @nonStaticPropertiesSources = {}
    @staticPropertiesSources = {}

    # find the Mixin name
    mixinRegex = /^([a-zA-Z_$][0-9a-zA-Z_$]*)Mixin *=/m
    if (m = mixinRegex.exec(source))?
        m.forEach((match, groupIndex) ->
            if srcLoadCompileDebugWrites then console.log("Found match, group #{groupIndex}: #{match}")
        )
        @name = m[1]
        if srcLoadCompileDebugWrites then console.log "mixin name: " + @name

    if srcLoadCompileDebugWrites then console.log "source ---------\n" + source

    sourceToBeParsed = source + "\n      $$$STOPTOKEN_LASTFIELD :"

    # Now find all the fields definitions
    # note that the constructor, methods, properties and static properties
    # are ALL fields definitions, so we are basically going to cycle through
    # everything

    # to match a valid JS variable name (we just ignore the keywords):
    #    [a-zA-Z_$][0-9a-zA-Z_$]*
    regex = /^      ([a-zA-Z_$][0-9a-zA-Z_$]*) *: *([^]*?)(?=^      ([a-zA-Z_$][0-9a-zA-Z_$]*) *:)/gm

    while (m = regex.exec(sourceToBeParsed))?
        if (m.index == regex.lastIndex)
            regex.lastIndex++
        m.forEach (match, groupIndex) ->
            if srcLoadCompileDebugWrites then console.log "Found match, group #{groupIndex}: #{match}"

        if m[1].valueOf() == "$$$STOPTOKEN_LASTFIELD "
          break
        else
          if srcLoadCompileDebugWrites then console.log "not the stop field: " + m[1].valueOf()

        @nonStaticPropertiesSources[m[1]] = m[2]

    if generatePreCompiledJS or createMixin
      JS_string_definitions = compileFGCode (@_equivalentforSuper source), true
      JSSourcesContainer.content += JS_string_definitions + "\n"
      if createMixin
        try
          eval.call window, JS_string_definitions
        catch err
          console.log " error " + err + " evaling : " + JS_string_definitions
          debugger
        # Register this parsed mixin so the inspector can recover a mixin method's real CoffeeScript source
        # from @nonStaticPropertiesSources (InspectorWdgt.selectionFromList) instead of falling back to the
        # compiled JS of val.toString(). Only the real create pass registers -- the build-time syntax gate's
        # parse-only `new Mixin(src, true, false)` (createMixin false) never reaches here, so allMixines stays
        # empty there.
        Mixin.allMixines.push @


    #if @name == "LCLCodePreprocessor" then debugger

