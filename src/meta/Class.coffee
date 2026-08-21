# BUILD-TIME SYNTAX GATE DEPENDENCY:
# buildSystem/check-coffee-syntax.js loads THIS file in Node and drives every shipped
# source through `new Class(src, true, false)` (generate-precompiled mode: it compiles
# each fragment but eval's nothing) to catch CoffeeScript syntax errors at build time,
# before they would otherwise only surface at in-browser boot. That checker provides a
# tiny shim for the globals this class touches at construction time (window, undefined,
# compileFGCode, JSSourcesContainer, srcLoadCompileDebugWrites). If you make the
# constructor / its helpers read a NEW global, add a matching stand-in to that shim or
# the gate will break with an operational (exit 2) error.

class Class

  nonStaticPropertiesSources: undefined
  staticPropertiesSources: undefined
  name: ""
  superClassName: undefined
  augmentedWith: undefined
  superClass: undefined
  subClasses: undefined
  classRegex: /^class[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
  propertyRegex: /^  (@?[a-zA-Z_$][0-9a-zA-Z_$]*) *: *(.*)/m
  augmentRegex: /^  @augmentWith[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
  topLevelCommentRegex: /^  #.*/m


  # adds code into the constructor, such that when a
  # Widget is created, it registers itself as in instance
  # on the Class it belongs to AND TO ALL THE SUPERCLASSES
  # The way it's added to all the superclasses is via
  # the constructor always calling "super", so constructors
  # up the chain cause the object to register itself
  # with all the superclasses.
  #
  # TODO this mechanism can be tested like so:
  # open AnalogClockWdgt and then from the console:
  #    window.AnalogClockWdgt.instances
  # ...should give one object
  #    window.AnalogClockWdgt.__super__.constructor.instances.forEach((each) => console.log(each.constructor.name==="AnalogClockWdgt"));
  # should only give one 'true'
  #    window.AnalogClockWdgt.instances.forEach((each) => each.fullDestroy());
  # should destroy all clocks
  #    window.AnalogClockWdgt.instances
  # should show empty set
  #    window.AnalogClockWdgt.__super__.constructor.instances.forEach((each) => console.log(each.constructor.name==="AnalogClockWdgt"));
  # should type all 'false'
  #
  # Note that only Widgets have that kind
  # of tracking and hence the existence check of
  # the registerThisInstance function
  _addInstancesTracker: (aString) ->
    # the regex to get the actual spacing under the constructor
    # is:
    # [ \t]*constructor:[ \t]*->.*$\n([ \t]*)
    # but let's keep it simple: there are going to be four spaces under for the
    # body of the constructor

    # if there is a return, keep it, otherwise add it
    if !aString.includes "\n    return"
      aString += "\n    return\n"
    aString.replace(/^([ \t]*)return/gm, "$1this.registerThisInstance?();\n$1return")
    
  _equivalentforSuper: (fieldName, aString) ->
    if window.srcLoadCompileDebugWrites then console.log "removing super from: " + aString
    # coffeescript won't compile "super" unless it's an instance
    # method (i.e. if it comes inside a class), so we need to
    # translate that manually into valid CS that doesn't use super.
    #
    # ORDER MATTERS -- these are sequential text substitutions on the method source:
    #  1. `super()`                    -> a no-argument super call.
    #  2. bare `super` ENDING THE LINE -> forward ALL arguments (.apply(this, arguments)). We tolerate
    #     trailing whitespace and/or an inline `#` comment before the newline (the comment is
    #     re-appended). This MUST come before rule 4: a trailing space -- e.g. before an inline
    #     comment, or stray end-of-line whitespace -- would otherwise be caught by rule 4 as
    #     `.call this, ` with NO effective argument, SILENTLY dropping the forwarded arguments. That
    #     miscompiled `return super  # Path B` (StretchableEditableWdgt) into a no-arg super call,
    #     which sized the app content to its 5px minimum extent -- the "thin vertical slice" bug.
    #  3. `super(args)`                -> a call with those explicit args.
    #  4. `super <args>`               -> a call with those space-separated args.
    superBase = @name + ".__super__." + fieldName
    aString = aString.replace(/super\(\)/g, superBase + ".call(this)")
    aString = aString.replace /super[ \t]*(#[^\n]*)?$/gm, (match, comment) ->
      superBase + ".apply(this, arguments)" + (if comment then "  " + comment else "")
    aString = aString.replace(/super\(/g, superBase + ".call(this, ")
    aString = aString.replace(/super /g, superBase + ".call this, ")

  # THE CLASS NAME MUST BE IN THE PARSED SOURCE, not patched on afterwards.
  #
  # A heap snapshot names an object's node after its constructor, and DevTools names a
  # RemoteObject's className the same way -- and BOTH read V8's PARSE-TIME function name:
  # the identifier V8 saw in the text it compiled. A later `Object.defineProperty(fn,
  # 'name', ...)` sets the `.name` PROPERTY and reaches neither. Measured: with only that
  # patch, every widget snapshots as a bare `object "Object"` and `world`'s className reads
  # as an unrelated class, while `.name` is right everywhere -- so object-lifetime forensics
  # cannot name a single retained widget.
  #
  # So we turn the ANONYMOUS function expression CoffeeScript emitted into a NAMED one,
  # inside the string that gets eval'd. Both emit shapes arrive here having opened their
  # function with `function (`, and in both the constructor's own `function` is the first
  # in the text:
  #   explicit constructor source   ->  `(function(a, b) { ... });`
  #   synthesized constructor       ->  `window.<Name> = function() { ... };`
  #
  # The name binding a named function expression creates INSIDE its own scope is safe here:
  # it makes the class name resolve, within the constructor body, to the very function that
  # `window.<Name>` holds -- `extend` returns the same object it is handed -- which is what
  # `_equivalentforSuper`'s bare `<Name>.__super__.constructor` already resolved to through
  # the global. No emitted constructor declares a local of its own class's name, so nothing
  # shadows it.
  _nameTheConstructorFunction: (aString) ->
    named = aString.replace /function[ \t]*\(/, => "function " + @name + "("
    if named is aString
      console.error "could not give the constructor of " + @name + " a parse-time name: " + aString
    named

  # A member name that must NOT become a function-expression name, because a named function
  # expression binds its own name INSIDE its own body: these are the three CoffeeScript helper
  # globals, which every compiled member body reaches as FREE identifiers (the contract stated at
  # _removeHelperFunctions). A member named `indexOf` that also wrote `x in aList` -- which
  # compiles to a bare `indexOf.call(...)` -- would resolve the helper to the method itself, and
  # nothing anywhere would say so.
  # Nothing on this tree is one of these (3202 members scanned). The guard is here so that a member
  # added later degrades to "anonymous in a heap snapshot", which costs a name, rather than
  # "silently resolves to itself", which costs a day.
  # ⚠ JS RESERVED WORDS ARE DELIBERATELY NOT LISTED. One would be an illegal function name, so the
  # eval below throws at class-build time -- at boot, for everyone, immediately -- and a failure
  # that loud needs no guard. Only the SILENT hazard is worth spending a list on. (Enumerating them
  # would also mean writing `null` and `instanceof` as literals here, which the stink ratchets
  # count textually and would charge against two baselines that have nothing to do with this.)
  @_memberNamesThatMustStayAnonymous: ["hasProp", "indexOf", "slice"]

  # The member twin of _nameTheConstructorFunction, and the reason is the same one stated there:
  # a heap snapshot names a function node from the function's own `name`, and assignment to a
  # MEMBER expression (`window.X.prototype.foo = function(){}`) is one of the positions JS does
  # NOT infer a name for -- so every member came out `""`. Measured before this: 367 of Widget's
  # 369 prototype methods were anonymous, and a method reached through `.bind(this)` -- the shape
  # that actually retains a widget -- snapshotted as `bound ` with nothing after it.
  #
  # ⚠ Anchored on a declaration that OPENS with `(function`, which is what a compiled member is
  # once _removeHelperFunctions has run. That is what keeps it off the STATIC fields that are not
  # functions at all (`@BLACK: Color.create 0,0,0`): an unanchored replace would happily name a
  # function appearing later inside such a value, labelling the wrong thing.
  # ⚠ Only the FIRST `function(` is renamed -- the member's own, since the member IS the text.
  _nameTheMemberFunction: (fieldName, aString) ->
    return aString unless /^\s*\(function[ \t]*\(/.test aString
    return aString if fieldName in Class._memberNamesThatMustStayAnonymous
    aString.replace /function[ \t]*\(/, -> "function " + fieldName + "("

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
  # A class member compiles to a bare function expression, so the whole `var` head belongs to
  # the helpers and goes in one cut, whatever it happened to declare -- helper-AGNOSTIC, which
  # is what that boot comment relies on. (Mixin's twin cannot do this: a mixin compiles as a
  # whole source, so its own name shares the statement -- see there.)
  _removeHelperFunctions: (aString) ->
    aString = aString.replace /^var(.|\n)*?\(function/, "(function"

    # TRIPWIRE for a helper declaration the cut above did not reach -- a fragment that declares
    # helpers without opening on `(function`. ⚠ It keys off the emitted `var` STATEMENT
    # (anchored at column 0, which only a top-level declaration is, and reaching to the `;`
    # because the helpers may ride on continuation lines), NOT off the bare `[].indexOf`
    # expressions: those occur in the compiled body of this method and of Mixin's twin -- their
    # patterns are literals in it -- so an expression-shaped detector reports the stripper
    # itself, on every build.
    if /^var\b[^;]*\b(hasProp|indexOf|slice)\s*=/m.test aString
      console.error "code contains a helper var, it shouldn't: " +  aString
      debugger

    return aString

  # ===== live member editing =====
  # The CLASS twin of Mixin.applyMemberEdit: rewrite ONE member on this class's
  # prototype from CoffeeScript source, with the SAME compile shape the mixin twin
  # uses -- a bare global-assignment eval, NOT Widget.evaluateString: that method's
  # relayout/repaint tail treats its receiver as a WIDGET, and run on a PROTOTYPE
  # it stamps widget-lifecycle fields (cachedRoot, dstDamageRectIndex, ...) onto the
  # prototype as own properties, polluting every later member listing of the class.
  # (The compiled output may re-declare the CoffeeScript helper vars -- indexOf etc.
  # -- at global scope; harmless, the globals already hold exactly those values.)
  # The super forms are rewritten exactly as the boot emit does
  # (_equivalentforSuper), so an edited member keeps calling super; the source is
  # kept as the `<name>_source` sibling for EVERY member kind -- it is what keeps
  # the member editable as CoffeeScript, what the class inspector's view attributes
  # a field to, and what Mixin.applyMemberEdit's live-override shadow guard keys
  # off. Callers: ClassInspectorWdgt (live save and the override-in-this-class
  # gesture) and SourceEditsRegistry.replayClassEdits (world-snapshot restore).
  # Throws on compile errors. Notifying instances is the CALLER's business -- the
  # restore path replays before any instance exists.
  applyMemberEdit: (memberName, source) ->
    proto = window[@name].prototype
    compiled = compileFGCode ("window.__fzEditedClassMember = " + (@_equivalentforSuper memberName, source)), true
    eval.call window, compiled
    proto[memberName] = window.__fzEditedClassMember
    delete window.__fzEditedClassMember
    proto[memberName + "_source"] = source
    return

  findIfItExtendsAnotherClass: (source) ->
    # find if it extends some other class
    extendsRegex = /^class[ \t]*[a-zA-Z_$][0-9a-zA-Z_$]*[ \t]*extends[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
    if (m = extendsRegex.exec(source))?
        m.forEach (match, groupIndex) ->
            if window.srcLoadCompileDebugWrites then console.log("Found match, group #{groupIndex}: #{match}")
        superClassName = m[1]
        if window.srcLoadCompileDebugWrites then console.log "we should have already loaded " + superClassName
        superClass = window[superClassName].class

        if window.srcLoadCompileDebugWrites then console.log "superClassName: " + superClassName

    return [superClassName, superClass]

  # Collect lines up to a stop. Two operands — the lines and the pattern that ends the stash — because
  # all four callers supply exactly those; the three rarer controls ride opts, since each is wanted by
  # ONE caller and any positional order leaves the others skipping a slot (R3, the hole test:
  # docs/architecture/constructor-and-parameter-conventions.md):
  #   opts.orStopOn         a SECOND stop-positive; either pattern ends the stash
  #   opts.abortOn          a stop-NEGATIVE: matching it abandons the stash and returns false
  #   opts.keepStashWhenEOF at end of input, return what was collected instead of failing
  findUpTo: (sourceLines, regexStopPositive, opts = {}) ->
    # This works by prospectively collecting lines until a
    # stop regex is found.
    # If a stop positive is found, we return the stash and the line with the stop.
    # Otherwise, if a stop negative or end of file, we return false.
    regexStopPositive2 = opts.orStopOn
    regexStopNegative = opts.abortOn
    keepStashWhenEOF = opts.keepStashWhenEOF

    sourceLinesOrig = sourceLines
    linesUpToStop = []

    # collect lines until a stop is found
    for eachLine in sourceLines
      if (regexStopPositive?.test eachLine) or (regexStopPositive2?.test eachLine)
        # we finally found the stop positive: all lines we found so far
        # are a good stash, we'll return the good finds

        # re-assemble the lines we found so far
        everythingUpToStopPositive = linesUpToStop.join "\n"

        # remove what we found so far from what we were passed
        remainingSourceLinesIncludingStopPositive = sourceLines.slice linesUpToStop.length

        # the first line of remainingSourceLinesIncludingStopPositive
        # now is the stop positive
        stopPositiveLine = remainingSourceLinesIncludingStopPositive[0]
        if window.srcLoadCompileDebugWrites
          console.log "stopPositiveLine: " + stopPositiveLine + " ================"
          console.log "everythingUpToStopPositive: " + everythingUpToStopPositive

        remainingSourceLinesExcludingStopPositive = remainingSourceLinesIncludingStopPositive.slice 1
        return [stopPositiveLine, everythingUpToStopPositive, remainingSourceLinesExcludingStopPositive, remainingSourceLinesIncludingStopPositive]

      else if regexStopNegative?.test eachLine
        # found the stop negative: what we collected is no good
        return false

      # no stop found yet, keep collecting
      linesUpToStop.push eachLine

    if keepStashWhenEOF
      return ["", (sourceLinesOrig.join "\n"), [], []]
    else
      # reached the end of the file without finding a stop:
      # what we collected is no good
      return false

  findMixinsInTheClass: (remainingSourceLines) ->
    # This works by prospectively collecting comment lines until an
    # stop positive regex for augmentation is found, then stashing
    # both the comment and the augmentation, then looping over what remains

    augmentationComments = []
    augmentationNames = []

    while returned = @findUpTo remainingSourceLines, @augmentRegex, abortOn: @propertyRegex
      augmentationNames.push (returned[0].match @augmentRegex)[1]
      augmentationComments.push returned[1]
      remainingSourceLines = returned[2]
      if window.srcLoadCompileDebugWrites
        console.log "augmentation: " + (returned[0].match @augmentRegex)[1] + " =========="
        console.log "comments: \n" + returned[1]

    return [augmentationNames, augmentationComments, remainingSourceLines]


  removeAugmentations: (source) ->
    source.replace(/^  @augmentWith[ \t]*([a-zA-Z_$][0-9a-zA-Z_$, @]*)/gm,"")

  getSourceOfAllProperties: (remainingSourceLines) ->
    staticPropertiesSources = {}
    nonStaticPropertiesSources = {}

    while returned = @findUpTo remainingSourceLines, @propertyRegex
      propertyName = (returned[0].match @propertyRegex)[1]
      propertyComment = returned[1]
      propertyFirstLineOfBody = (returned[0].match @propertyRegex)[2]
      remainingSourceLines = returned[2]
      if window.srcLoadCompileDebugWrites
        console.log "propertyName: " + propertyName + " =========="
        console.log "propertyComment: \n" + propertyComment
        console.log "propertyFirstLineOfBody: \n" + propertyFirstLineOfBody

      propertyBodyExceptFirstLine = ""
      if returned = @findUpTo remainingSourceLines, @topLevelCommentRegex, orStopOn: @propertyRegex, keepStashWhenEOF: true
        propertyBodyExceptFirstLine = returned[1]
        remainingSourceLines = returned[3] # leave the next top level comment or property regex IN

      if propertyBodyExceptFirstLine.length == 0
        propertyBody = propertyFirstLineOfBody
      else
        propertyBody = propertyFirstLineOfBody + "\n" + propertyBodyExceptFirstLine

      if window.srcLoadCompileDebugWrites
        console.log "propertyBody: \n" + propertyBody

      if propertyName.substring(0, 1) == "@"
        staticPropertiesSources[propertyName.substring(1, propertyName.length)] = propertyBody
      else
        nonStaticPropertiesSources[propertyName] = propertyBody


    [staticPropertiesSources, nonStaticPropertiesSources]



  findClassDescriptionHeaderCommentAndClassName: (sourceLines) ->
    [classLine, classDescriptionHeaderComment, remainingSourceLines] = @findUpTo sourceLines, @classRegex
    className = (classLine.match @classRegex)[1]
    if window.srcLoadCompileDebugWrites
      console.log "className: " + name + " =========="
      console.log "comments: \n" + classDescriptionHeaderComment
    [className, classDescriptionHeaderComment, remainingSourceLines]

  # You can create a Class in 3 main "modes" of use:
  #  1. you want to load up the CS source, turn it to JS
  #     and eval the JS so to create the class:
  #        generatePreCompiledJS == true
  #        createClass == true
  #  2. you want to load up the CS source, turn it to JS
  #     and just store the JS somewhere to generate the
  #     pre-compiled JS sources:
  #        generatePreCompiledJS == true
  #        createClass == false
  #  3. you want to just load up the CS source so it
  #     appears all neat in the inspectors:
  #        generatePreCompiledJS == false
  #        createClass == false
  constructor: (source, generatePreCompiledJS, createClass) ->

    if !window.classDefinitionAsJS?
      window.classDefinitionAsJS = []

    @subClasses = new Set

    sourceLines = source.split "\n"

    [@name, ignored, sourceLines] = @findClassDescriptionHeaderCommentAndClassName sourceLines
    [@superClassName, @superClass] = @findIfItExtendsAnotherClass source
    # find which mixins need to be mixed-in
    [@augmentedWith, ignored, sourceLines] = @findMixinsInTheClass sourceLines

    # remove the augmentations because we don't want
    # them to mangle up the parsing
    source = @removeAugmentations source

    if window.srcLoadCompileDebugWrites then console.log "source ---------\n" + source

    # Now find all the fields definitions
    # note that the constructor, methods, properties and static properties
    # are ALL fields definitions, so we are basically going to cycle through
    # everything
    [@staticPropertiesSources, @nonStaticPropertiesSources] = @getSourceOfAllProperties sourceLines

    if generatePreCompiledJS or createClass
      # --------------------
      # OK we collected all the fields definitions, now go through them
      # and put them into action
      # --------------------

      # collect all the definitions in JS form here
      JS_string_definitions = "// class " + @name + "\n\n"

      # the class itself is a constructor function, the constructor.
      # we have to find its source (if it exists), and
      # we have to slightly modify it and then we have to
      # actually create this function, hence creating the class.
      if window.srcLoadCompileDebugWrites then console.log "adding the constructor"
      if @nonStaticPropertiesSources.hasOwnProperty('constructor')

        if window.srcLoadCompileDebugWrites then console.log "CS sources of constructor: " + @nonStaticPropertiesSources["constructor"]
        # if there is a source for the constructor
        constructorDeclaration = @_equivalentforSuper "constructor", @nonStaticPropertiesSources["constructor"]
        constructorDeclaration = @_addInstancesTracker constructorDeclaration
        if window.srcLoadCompileDebugWrites then console.log "constructor declaration CS:\n" + constructorDeclaration

        compiled = compileFGCode constructorDeclaration, true

        constructorDeclaration = @_removeHelperFunctions compiled
        constructorDeclaration = "window." + @name + " = " + constructorDeclaration
      else
        # there is no constructor source, so we
        # just have to synthesize one that does:
        #  constructor ->
        #    super
        #    register instance
        constructorDeclaration = """
          window.#{@name} = ->
            # first line here is equivalent to "super" the one
            # passing all the arguments
            window.#{@name}.__super__.constructor.apply this, arguments
            # register instance (only Widgets have this method)
            @registerThisInstance?()
            return
        """
        if window.srcLoadCompileDebugWrites then console.log "constructor declaration CS:\n" + constructorDeclaration
        constructorDeclaration = compileFGCode constructorDeclaration, true

      # give the constructor function the class's name AT PARSE TIME -- see
      # _nameTheConstructorFunction: this is the only spelling heap snapshots and
      # DevTools can read, and it has to be in the text we are about to hand to eval.
      constructorDeclaration = @_nameTheConstructorFunction constructorDeclaration

      if window.srcLoadCompileDebugWrites then console.log "constructor declaration JS: " + constructorDeclaration
      JS_string_definitions += constructorDeclaration + "\n"

      # ...and PIN the `.name` PROPERTY, which is a different fact from the parse-time name
      # above and is separately load-bearing: `obj.constructor.name` is what the Serializer
      # writes as a figure's class, what the hierarchy/menu labels strip "Wdgt" off, and what
      # every NON_INTEGER_GEOMETRY-style diagnostic prints. Pinning it here keeps that fact
      # true no matter what shape a future CoffeeScript release emits for the constructor.
      # (Redefining an existing `name` with only a `value:` leaves it configurable, as it
      # already is on a named function expression.)
      # the name property is tricky, see:
      # see http://stackoverflow.com/questions/5871040/how-to-dynamically-set-a-function-object-name-in-javascript-as-it-is-displayed-i
      # just doing this is not sufficient: window[@name].name = @name

      # analogous to
      # Object.defineProperty(window[@name], 'name', { value: @name })
      JS_string_definitions += "Object.defineProperty(window.#{@name}, 'name', { value: '#{@name}' });" + "\n"

      # if the class extends another one
      if @superClassName?
        if window.srcLoadCompileDebugWrites then console.log "extend: " + @name + " extends " + @superClassName
        # analogous to
        #window[@name].__super__ = window[@superClassName].prototype
        #window[@name] = extend window[@name], window[@superClassName]
        JS_string_definitions += "window.#{@name}.__super__ = window.#{@superClassName}.prototype;" + "\n"
        JS_string_definitions += "window.#{@name} = extend(window.#{@name}, window.#{@superClassName});" + "\n"
      else
        if window.srcLoadCompileDebugWrites then console.log "no extension (extends Object) for " + @name
        # analogous to
        #window[@name].__super__ = Object.prototype
        JS_string_definitions += "window.#{@name}.__super__ = Object.prototype;" + "\n\n"


      # if the class is augmented with one or more Mixins
      for eachAugmentation in @augmentedWith
        if window.srcLoadCompileDebugWrites then console.log "augmentedWith: " + eachAugmentation
        # analogous to
        #window[@name].augmentWith window[eachAugmentation], @name
        JS_string_definitions += "window.#{@name}.augmentWith(window.#{eachAugmentation}, '#{@name}');" + "\n"

      # non-static fields, which are put in the prototype
      for own fieldName, fieldValue of @nonStaticPropertiesSources
        if fieldName != "constructor" and fieldName != "augmentWith" and fieldName != "addInstanceProperties"
          if window.srcLoadCompileDebugWrites then console.log "building field " + fieldName + " ===== "


          fieldDeclaration = @_equivalentforSuper fieldName, fieldValue

          compiled = compileFGCode fieldDeclaration, true

          fieldDeclaration = @_removeHelperFunctions compiled
          fieldDeclaration = @_nameTheMemberFunction fieldName, fieldDeclaration
          fieldDeclaration = "window." + @name + ".prototype." + fieldName + " = " + fieldDeclaration

          if window.srcLoadCompileDebugWrites then console.log "field declaration: " + fieldDeclaration
          JS_string_definitions += fieldDeclaration + "\n"

      JS_staticConstantsBuiltWithClassItself_definitions = ""

      # now the static fields, which are put in the constructor
      # rather than in the prototype
      for own fieldName, fieldValue of @staticPropertiesSources
        if fieldName != "constructor" and fieldName != "augmentWith" and fieldName != "addInstanceProperties"
          if window.srcLoadCompileDebugWrites then console.log "building STATIC field " + fieldName + " ===== "

          fieldDeclaration = @_equivalentforSuper fieldName, fieldValue

          compiled = compileFGCode fieldDeclaration, true

          fieldDeclaration = @_removeHelperFunctions compiled
          fieldDeclaration = @_nameTheMemberFunction fieldName, fieldDeclaration
          fieldDeclaration = "window." + @name + "." + fieldName + " = " + fieldDeclaration

          if window.srcLoadCompileDebugWrites then console.log fieldDeclaration

          if ((new RegExp("\\s*new\\s*" + @name + "(\\s|$)")).test fieldValue) or ((new RegExp("\\s*" + @name + "\\.create\\w*(\\s|\\()")).test fieldValue)
            # for example, in the Color class:
            #    @BLACK: Color.createConstant 0,0,0
            #      or the alternatives
            #    @BLACK: Color.create 0,0,0
            #    @BLACK: new Color 0,0,0
            # we need to put these aside and add them last, so that the
            # rest of the class is defined and we can initialise these
            # properly.
            JS_staticConstantsBuiltWithClassItself_definitions += fieldDeclaration + "\n"
          else
            JS_string_definitions += fieldDeclaration + "\n"


      # analogous to
      # window[@name].instances = new Set
      JS_string_definitions += "window.#{@name}.instances = new Set;" + "\n"

      JS_string_definitions += JS_staticConstantsBuiltWithClassItself_definitions

      # Accumulate ONLY for a caller that wants the pre-compiled image — the ?generatePreCompiled
      # boot and the build-time syntax gate, both of which pass generatePreCompiledJS = true and
      # read the string back. An ordinary boot compiles each class to CREATE it (createClass) and
      # never reads this accumulator, so building it there would cost ~2.5 MB per boot for nothing.
      if generatePreCompiledJS
        JSSourcesContainer.content += JS_string_definitions + "\n"

      if createClass
        try
          if window.srcLoadCompileDebugWrites then console.log "actually evalling " + @name + " to create the class"
          eval.call window, JS_string_definitions
        catch err
          console.error " error " + err + " evaling : " + JS_string_definitions
          alert " error " + err + " evaling : " + JS_string_definitions


      window.classDefinitionAsJS.push JS_string_definitions

    # OK now that we have created the Class
    # (or if already created anyways, in pre-compiled mode)
    # then add the .class field
    window[@name].class = @
    if @superClass?
      @superClass.subClasses.add @



  notifyInstancesOfSourceChange: (propertiesArray)->
    window[@name].instances.forEach (eachInstance) =>
      eachInstance.sourceChanged()
  
    for eachProperty in propertiesArray
      @subClasses.forEach (eachSubClass) =>
        # if a subclass redefined a property, then
        # the change doesn't apply, so there is no
        # notification to propagate
        if !eachSubClass.nonStaticPropertiesSources[eachProperty]?
          eachSubClass.notifyInstancesOfSourceChange([eachProperty])

