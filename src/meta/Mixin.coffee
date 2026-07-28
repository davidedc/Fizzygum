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

    # ORDER MATTERS -- the same four sequential text substitutions as
    # Class._equivalentforSuper, in the same order (see there for the full rationale):
    #  1. `super()`                    -> a no-argument super call.
    #  2. bare `super` ENDING THE LINE -> forward ALL arguments (.apply(this, arguments)),
    #     tolerating trailing whitespace and/or an inline `#` comment (re-appended). MUST
    #     run before rule 4: a trailing space would otherwise be caught there as
    #     `.call this, ` with NO effective argument, SILENTLY dropping the forwarded
    #     arguments (the thin-slice-bug class).
    #  3. `super(args)`                -> a call with those explicit args.
    #  4. `super <args>`               -> a call with those space-separated args.
    mixinSuperBase = "window[@[arguments.callee.name + '_class_injected_in']].__super__[arguments.callee.name]"
    aString = aString.replace(/super\(\)/g, mixinSuperBase + ".call(this)")
    aString = aString.replace /super[ \t]*(#[^\n]*)?$/gm, (match, comment) ->
      mixinSuperBase + ".apply(this, arguments)" + (if comment then "  " + comment else "")
    aString = aString.replace(/super\(/g, mixinSuperBase + ".call(this, ")
    aString = aString.replace(/super /g, mixinSuperBase + ".call this, ")

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
      console.error "code contains a helper var, it shouldn't: " +  aString
      debugger

    return aString

  # ===== live member editing =====
  # The third edit scope, next to instance edits (Widget.injectProperty) and class
  # edits (ClassInspectorWdgt.applyPropertyEdit): rewrite ONE injected member on the
  # DONOR mixin and push the recompiled function to every consumer class, so the
  # edit behaves as if the mixin had always said this. The inspector routes here
  # when the selected member's source comes from a mixin (ClassInspectorWdgt).

  # the classes this mixin is injected into -- recorded on the mixin LITERAL
  # (window.<name>Mixin) by Object::augmentWith at injection time.
  _consumerClassNames: ->
    window[@name + "Mixin"]?.consumerClassNames or []

  # Apply an edit to member `memberName`: update the recorded source (the same
  # store the inspector's view reads), recompile the single member with the mixin
  # super rewrite, and re-inject it into every consumer class whose own class body
  # does not shadow the member (the class body won at boot -- augmentWith runs
  # before the class-body assignments -- and keeps winning). Returns the number of
  # consumer classes updated. Throws on compile errors.
  applyMemberEdit: (memberName, source) ->
    compiled = compileFGCode ("window.__fzEditedMixinMember = " + (@_equivalentforSuper source)), true
    compiled = @_removeHelperFunctions compiled
    eval.call window, compiled
    editedValue = window.__fzEditedMixinMember
    delete window.__fzEditedMixinMember
    if typeof editedValue is "function"
      # the fake-super rewrite resolves its target through
      # `arguments.callee.name + "_class_injected_in"`: the object-literal form gave
      # the original function the member's name, the standalone recompile does not --
      # restore it.
      Object.defineProperty editedValue, "name", { value: memberName, configurable: true }

    @nonStaticPropertiesSources[memberName] = source

    updated = 0
    for className in @_consumerClassNames()
      theClass = window[className]
      continue unless theClass?
      # SHADOW GUARD: skip a consumer whose class body defines this member itself...
      continue if theClass.class?.nonStaticPropertiesSources?[memberName]?
      # ...or whose prototype carries a LIVE class-scope override (`<name>_source`,
      # written by ClassInspectorWdgt's prototype edit / override gesture) -- the
      # same boot-order rule, applied to overrides born at edit time
      continue if Object.prototype.hasOwnProperty.call theClass.prototype, memberName + "_source"
      theClass::[memberName] = editedValue
      if typeof editedValue is "function"
        theClass::[memberName + "_class_injected_in"] = className
      theClass.class?.notifyInstancesOfSourceChange? [memberName]
      updated++
    updated

  # The class-side twin of applyMemberEdit: rewrite ONE static member on the donor
  # and re-copy it onto every consumer CONSTRUCTOR whose own class body does not
  # declare the same static (the boot-order rule, on the class side). No super
  # rewrite: a mixin static belongs to no instance-method chain. Returns the
  # number of consumer classes updated. Throws on compile errors.
  applyStaticEdit: (memberName, source) ->
    compiled = compileFGCode ("window.__fzEditedMixinMember = " + source), true
    compiled = @_removeHelperFunctions compiled
    eval.call window, compiled
    editedValue = window.__fzEditedMixinMember
    delete window.__fzEditedMixinMember

    @staticPropertiesSources[memberName] = source

    updated = 0
    for className in @_consumerClassNames()
      theClass = window[className]
      continue unless theClass?
      # SHADOW GUARD: skip a consumer whose class body declares this static itself
      continue if theClass.class?.staticPropertiesSources?[memberName]?
      theClass[memberName] = editedValue
      theClass.class?.notifyInstancesOfSourceChange? [memberName]
      updated++
    updated

  # Remove member `memberName` from this mixin: drop the recorded source and
  # delete the injected member (+ its fake-super companion) from every consumer
  # class -- except the shadowing ones (both guards, as applyMemberEdit), whose
  # own member never came from the injection. Returns the number of consumer
  # classes updated.
  removeMember: (memberName) ->
    delete @nonStaticPropertiesSources[memberName]
    updated = 0
    for className in @_consumerClassNames()
      theClass = window[className]
      continue unless theClass?
      continue if theClass.class?.nonStaticPropertiesSources?[memberName]?
      continue if Object.prototype.hasOwnProperty.call theClass.prototype, memberName + "_source"
      delete theClass::[memberName]
      delete theClass::[memberName + "_class_injected_in"]
      theClass.class?.notifyInstancesOfSourceChange? [memberName]
      updated++
    updated

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

    # class-side (static) members: the literal's 2-space keys, copied onto each
    # consumer CONSTRUCTOR by augmentWith's for-loop -- minus the mixin DSL's own
    # hooks (MixedClassKeywords). Parsed so the inspector's static leg can show
    # and edit them (applyStaticEdit); the shipped mixins currently declare none.
    staticSourceToBeParsed = source + "\n  $$$STOPTOKEN_LASTFIELD :"
    staticRegex = /^  ([a-zA-Z_$][0-9a-zA-Z_$]*) *: *([^]*?)(?=^  ([a-zA-Z_$][0-9a-zA-Z_$]*) *:)/gm
    while (m = staticRegex.exec(staticSourceToBeParsed))?
        if (m.index == staticRegex.lastIndex)
            staticRegex.lastIndex++
        continue if MixedClassKeywords.indexOf(m[1]) >= 0
        @staticPropertiesSources[m[1]] = m[2]

    if generatePreCompiledJS or createMixin
      JS_string_definitions = compileFGCode (@_equivalentforSuper source), true
      # Accumulate ONLY for a caller that wants the pre-compiled image — see the twin comment in
      # Class.coffee. A normal boot compiles to CREATE and never reads this string.
      if generatePreCompiledJS
        JSSourcesContainer.content += JS_string_definitions + "\n"
      if createMixin
        try
          eval.call window, JS_string_definitions
        catch err
          console.error " error " + err + " evaling : " + JS_string_definitions
          debugger
        # Register this parsed mixin so the inspector can recover a mixin method's real CoffeeScript source
        # from @nonStaticPropertiesSources (InspectorWdgt.selectionFromList) instead of falling back to the
        # compiled JS of val.toString(). Only the real create pass registers -- the build-time syntax gate's
        # parse-only `new Mixin(src, true, false)` (createMixin false) never reaches here, so allMixines stays
        # empty there.
        Mixin.allMixines.push @


    #if @name == "LCLCodePreprocessor" then debugger

