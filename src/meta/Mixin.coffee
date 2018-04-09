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

    aString = aString.replace(/super$/gm, "window[@[arguments.callee.name + '_class_injected_in']].__super__[arguments.callee.name].apply(this, arguments)")
    aString = aString.replace(/super /g, "window[@[arguments.callee.name + '_class_injected_in']].__super__[arguments.callee.name].call this, ")

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

    if (aString.indexOf "[].indexOf") != -1 or
     (aString.indexOf "{}.hasProp") != -1 or
     (aString.indexOf "[].slice") != -1
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


    #if @name == "LCLCodePreprocessor" then debugger

