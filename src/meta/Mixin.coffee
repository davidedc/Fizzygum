# BUILD-TIME SYNTAX GATE DEPENDENCY:
# buildSystem/check-coffee-syntax.js loads THIS file in Node and drives every shipped
# mixin source through `new Mixin(src, true, false)` (generate-precompiled mode: it
# compiles the source but eval's nothing) to catch CoffeeScript syntax errors at build
# time, before they would otherwise only surface at in-browser boot. It loads it through
# buildSystem/lib/meta-compiler.js, whose shim supplies the globals this class touches at
# construction time (compileFGCode, JSSourcesContainer, srcLoadCompileDebugWrites; Class,
# whose super rewrite it calls, is loaded beside it). If you make
# the constructor read a NEW global, add a matching stand-in to that shim or the gate will
# break.

class Mixin
  @allMixines: []
  nonStaticPropertiesSources: undefined
  name: ""

  # The mixin's source with each of its `super`s spelled out as a call -- Class.rewriteSuperCalls,
  # the one super rewrite, says how. What a mixin's `super` MEANS cannot be known when it is
  # compiled: the mixin belongs to no class until it is injected, and it is injected into several.
  # So injection records, on each consumer's prototype, the class each injected method was
  # injected in (`<member>_class_injected_in`, Object::addInstanceProperties), and the call reads
  # it at RUN time, through the calling method's own name.
  _rewriteSuperCalls: (source) ->
    Class.rewriteSuperCalls source, "window[@[arguments.callee.name + '_class_injected_in']].__super__[arguments.callee.name]"

  # CoffeeScript declares its helpers at the top of whatever it compiles:
  #
  #  slice = [].slice
  #  indexOf = [].indexOf
  #  hasProp = {}.hasOwnProperty
  #
  # We take the DECLARATIONS out and leave every USE in the body alone, so a compiled member
  # reaches all three as FREE identifiers and resolves them against the three page-lifetime
  # globals boot installs -- the contract stated in full at
  # src/boot/loading-and-compiling-coffeescript-sources.coffee ("THE THREE COFFEESCRIPT HELPER
  # GLOBALS"). One shared definition, rather than one per compiled fragment.
  #
  # ⚠ WHY ONE PATTERN PER HELPER, where Class.coffee cuts the whole `var` head out in one go:
  # a mixin compiles as a WHOLE source, so its own name is the FIRST declarator of that very
  # statement and the helpers ride on its continuation lines --
  #
  #     var SomeMixin,
  #       hasProp = {}.hasOwnProperty,
  #       indexOf = [].indexOf;
  #
  # -- so removing the head wholesale would take `var SomeMixin` with it. Each helper's
  # declarator is overwritten in place with a placeholder ($$$ once replace() has folded the
  # doubled $) rather than deleted, because deleting one would leave a dangling comma.
  _removeHelperFunctions: (aString) ->
    aString = aString.replace /indexOf = \[\]\.indexOf/, "$$$$$$"
    aString = aString.replace /hasProp = \{\}\.hasOwnProperty/, "$$$$$$"
    aString = aString.replace /slice = \[\]\.slice/, "$$$$$$"

    # TRIPWIRE for a helper declaration the three patterns above did not match -- a shape only
    # a compiler change can produce. ⚠ It keys off the emitted `var` STATEMENT (anchored at
    # column 0, which only a top-level declaration is, and reaching to the `;` because the
    # helpers ride on continuation lines), NOT off the bare `[].indexOf` expressions: those
    # occur in THIS method's own compiled body -- the patterns just above are literals in it --
    # so an expression-shaped detector reports the stripper itself, on every build.
    if /^var\b[^;]*\b(hasProp|indexOf|slice)\s*=/m.test aString
      console.error "HELPER_VAR_NOT_STRIPPED: code contains a helper var, it shouldn't: " +  aString
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
    # the typed source sits behind the assignment, so a compile error is placed in it (typedFrom);
    # a `super` the rewrite expands shifts the columns after it on its line
    assignment = "window.__fzEditedMixinMember = "
    compiled = compileFGCode assignment + (@_rewriteSuperCalls source), true, typedFrom: assignment.length
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
      theClass.class?.notifyInstancesOfSourceChange?()
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
      theClass.class?.notifyInstancesOfSourceChange?()
      updated++
    updated

  constructor: (source, generatePreCompiledJS, createMixin) ->

    @nonStaticPropertiesSources = {}

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

    # Now find the instance members: the 6-space keys onceAddedClassProperties hands to
    # addInstanceProperties, methods and fields alike, each a `name: value` definition. (The
    # literal's 2-space class-side keys are not parsed: augmentWith copies them onto each
    # consumer constructor, and nothing reads their source.)

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
      JS_string_definitions = compileFGCode (@_rewriteSuperCalls source), true
      # Accumulate ONLY for a caller that wants the pre-compiled image — see the twin comment in
      # Class.coffee. A normal boot compiles to CREATE and never reads this string.
      if generatePreCompiledJS
        JSSourcesContainer.content += JS_string_definitions + "\n"
      if createMixin
        try
          eval.call window, JS_string_definitions
        catch err
          console.error "SOURCE_EVAL_FAILED: " + err + " evaling : " + JS_string_definitions
          debugger
        # Register this parsed mixin so the inspector can recover a mixin method's real CoffeeScript source
        # from @nonStaticPropertiesSources (InspectorWdgt.selectionFromList) instead of falling back to the
        # compiled JS of val.toString(). Only the real create pass registers -- the build-time syntax gate's
        # parse-only `new Mixin(src, true, false)` (createMixin false) never reaches here, so allMixines stays
        # empty there.
        Mixin.allMixines.push @


    #if @name == "LCLCodePreprocessor" then debugger

