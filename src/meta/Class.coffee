# BUILD-TIME SYNTAX GATE DEPENDENCY:
# buildSystem/check-coffee-syntax.js loads THIS file in Node and drives every shipped
# source through `new Class(src, true, false)` (generate-precompiled mode: it compiles
# each fragment but eval's nothing) to catch CoffeeScript syntax errors at build time,
# before they would otherwise only surface at in-browser boot. It loads it through
# buildSystem/lib/meta-compiler.js (as every build tool that reads the meta-system does),
# whose shim supplies the globals this class touches at construction time (window,
# compileFGCode, JSSourcesContainer, srcLoadCompileDebugWrites, and CoffeeScript -- the
# bundled compiler, whose lexer the super rewrite and every constructor's ending read).
# If you make the constructor / its helpers read a NEW global, add a matching stand-in to
# that shim or the gate will break with an operational (exit 2) error.

class Class

  nonStaticPropertiesSources: undefined
  staticPropertiesSources: undefined
  name: ""
  superClassName: undefined
  augmentedWith: undefined
  classRegex: /^class[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
  propertyRegex: /^  (@?[a-zA-Z_$][0-9a-zA-Z_$]*) *: *(.*)/m
  augmentRegex: /^  @augmentWith[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
  topLevelCommentRegex: /^  #.*/m


  # What a `super` in this class's `memberName` calls: the member of that name on the superclass's
  # prototype.
  _superOf: (memberName) ->
    @name + ".__super__." + memberName

  # A member's source with each of its `super`s spelled out as a call to the same-named member of
  # the superclass's prototype -- Class.rewriteSuperCalls, which says why and how.
  _rewriteSuperCalls: (memberName, source) ->
    if window.srcLoadCompileDebugWrites then console.log "removing super from: " + source
    Class.rewriteSuperCalls source, @_superOf memberName

  # The text the lexer reads of `source`: it drops a byte-order mark and every \r before reading,
  # and so does the compiler, so each token's line and column sit exactly on what this returns.
  @_textTheLexerReads: (source) ->
    source.replace(/^\uFEFF/, "").replace(/\r/g, "")

  # The lexer's tokens of `source`, or undefined where the lexer refuses it. Its errors carry their
  # `location`, as compileFGCode reads them: the caller then hands the source on as written, so
  # compileFGCode reports the error, placed where it is. Any other failure is a fault, and
  # propagates. (`CoffeeScript.tokens` is one of the calls this tree makes of the bundled
  # compiler; the README beside it lists them.)
  @_tokensOf: (source) ->
    try
      CoffeeScript.tokens source
    catch error
      throw error unless error.location?
      undefined

  # THE SUPER REWRITE, for Class and Mixin alike: each passes the member its `super` means as
  # `superBase` (Class: `<Name>.__super__.<member>`; Mixin: the class it was injected in, found at
  # call time). CoffeeScript compiles `super` only inside a class body, and the meta-system
  # compiles every member ALONE, so each `super` is spelled out as a call through `superBase`
  # before the member is compiled.
  #
  # WHICH `super`s, and as WHAT call, are read from the lexer's tokens -- the reading the compiler
  # is about to make of this very text -- never from the text. A `super` in a string, a comment or
  # a regex is no SUPER token, and neither is the end of a name (`@_super`, `x.super`); the form is
  # the call the parser sees, whatever whitespace, comment, operator or postfix `if` follows:
  #   `super()`      an explicit call with no arguments  ->  superBase.call(this)
  #   `super(a, b)`  an explicit call                    ->  superBase.call(this, a, b)
  #   `super a, b`   an implicit call                    ->  superBase.call this, a, b
  #   `super`        no call: it forwards every argument ->  superBase.apply(this, arguments)
  # (Read from the text instead, `return super  # Path B` -- a trailing space before a comment --
  # looks like an implicit call with no argument, and drops the arguments it forwards.)
  # Left as written, for the compiler to refuse: a `super` an accessor or a soak continues
  # (`super.x`, `super?.x`, `super::x`, `super[x]`, `super?()`, `super?`), and `do super`, which the
  # lexer places at the `do`. A `super` in the body of a class nested in the member is that class's
  # own, and the compiler spells it natively.
  #
  # Only the keyword, and an explicit call's opening parenthesis, is replaced, so every line of the
  # source stays on its line: lib/call-sites.js maps a member's lines back onto its file by that.
  # The text rewritten is the text the lexer reads (_textTheLexerReads), so each token's line and
  # column sit exactly on it; a source the lexer refuses is handed on as written (_tokensOf).
  @rewriteSuperCalls: (source, superBase) ->
    return source unless source.includes "super"
    source = @_textTheLexerReads source
    return source unless (tokens = @_tokensOf source)?
    lineStarts = [0]
    for i in [0...source.length] when source[i] is "\n"
      lineStarts.push i + 1
    offsetOf = (token) -> lineStarts[token[2].first_line] + token[2].first_column
    edits = []
    # one entry per open INDENT: true where it opens the body of a class nested in the member -- the
    # INDENT that ends a class's header; a header that ends at a TERMINATOR or an OUTDENT has no body
    classBodies = []
    classOpened = false
    for token, i in tokens
      switch token[0]
        when "CLASS" then classOpened = true
        when "INDENT" then classBodies.push classOpened
        when "OUTDENT"
          classBodies.pop()
          classOpened = false
        when "TERMINATOR" then classOpened = false
        when "SUPER"
          continue if true in classBodies
          at = offsetOf token
          continue unless source.startsWith "super", at
          next = tokens[i + 1]
          if next[0] is "CALL_START" and not next.generated
            opening = if tokens[i + 2][0] is "CALL_END" then ".call(this" else ".call(this, "
            edits.push [at, offsetOf(next) + 1, superBase + opening]
          else if next[0] is "CALL_START"
            edits.push [at, at + 5, superBase + ".call this,"]
          else unless next[0] in [".", "?.", "::", "?::", "INDEX_START", "INDEX_SOAK", "FUNC_EXIST", "?"]
            edits.push [at, at + 5, superBase + ".apply(this, arguments)"]
    # the last edit first, so each one leaves the offsets of those before it standing
    for edit in edits by -1
      [from, to, replacement] = edit
      source = source.slice(0, from) + replacement + source.slice(to)
    source

  # EVERY CONSTRUCTOR ENDS IN `return`. CoffeeScript gives a class's constructor no implicit
  # return, but the meta-system compiles each member ALONE, as a plain function, which hands back
  # its last expression -- and `new` returns that instead of the instance whenever it is an object
  # (a body ending `@appearance = new XAppearance @` would make `new` hand back the appearance).
  # So the constructor's source ends in a `return` of its own function, placed by the lexer:
  #   a body on lines of its own  ->  `return` as its last line, indented as its first line is
  #     (spaces or tabs, as written)
  #   a body on the arrow's line, or none  ->  the text after the arrow first moves to a line of
  #     its own, at two spaces (every line that continues a member sits further right, past the
  #     class's member column): a `return` after it on the arrow's line would belong to its last
  #     branch -- `-> if a then b() else c(); return` returns `b()`. That body then sits one line
  #     lower than written, so a compile error in it is reported one line low.
  # The function's own arrow follows the comment lines the source may open on: it is the first
  # token after them, or the one right after the parameter list that opens there (a default value
  # can hold arrows of its own). A constructor that is no `->` function -- a bound `=>` one, which
  # CoffeeScript refuses too, or any other value -- is refused, naming the class. A source the
  # lexer refuses is handed on as written (_tokensOf), for compileFGCode to report. A `return` the
  # source already ends in compiles to one `return;`.
  @endingInReturn: (source, className) ->
    source = @_textTheLexerReads source
    return source unless (tokens = @_tokensOf source)?
    start = 0
    start++ while tokens[start]?[0] is "TERMINATOR" or (tokens[start]?[0] is "JS" and tokens[start].generated)
    arrowAt = start
    if tokens[start]?[0] is "PARAM_START"
      depth = 0
      for i in [start...tokens.length]
        depth++ if tokens[i][0] is "PARAM_START"
        if tokens[i][0] is "PARAM_END" and --depth is 0
          arrowAt = i + 1
          break
    arrow = tokens[arrowAt]
    unless arrow?[0] is "->"
      throw new Error "the constructor of " + className + " is no `->` function: " + JSON.stringify source.slice 0, 60
    # after an arrow the lexer always has an INDENT: a real one opens a body on lines of its own
    next = tokens[arrowAt + 1]
    lines = source.split "\n"
    unless next.generated
      bodyLine = lines[tokens[arrowAt + 2][2].first_line]
      return source + "\n" + bodyLine.match(/^[ \t]*/)[0] + "return\n"
    {last_line: line, last_column: column} = arrow[2]
    lines[line] = lines[line].slice(0, column + 1) + "\n  " + lines[line].slice(column + 1).replace(/^\s+/, "")
    lines.join("\n") + "\n  return\n"

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
  # inside the string that gets eval'd. Every constructor arrives here in one shape --
  # `window.<Name> = (function(a, b) { ... });` -- the class's own and the one the meta-system
  # gives a class that writes none alike, so the constructor's own `function` is the first in
  # the text.
  #
  # The name binding a named function expression creates INSIDE its own scope is safe here:
  # it makes the class name resolve, within the constructor body, to the very function that
  # `window.<Name>` holds -- `extend` returns the same object it is handed -- which is what
  # the super rewrite's bare `<Name>.__super__.constructor` (_superOf) already resolved to
  # through the global. No emitted constructor declares a local of its own class's name, so
  # nothing shadows it.
  _nameTheConstructorFunction: (aString) ->
    named = aString.replace /function[ \t]*\(/, => "function " + @name + "("
    if named is aString
      console.error "CONSTRUCTOR_NOT_NAMED: could not give the constructor of " + @name + " a parse-time name: " + aString
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
  # This list is ALSO the build's statement of which helpers boot provides: check-coffee-syntax.js
  # reads it, holds it against boot's `window.<helper> =` assignments (the two must agree), and
  # fails any member whose stripped `var` head declares a name outside it.
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
  # Because the cut takes EVERY declaration, a name in that head other than the three globals
  # (`modulo` from `%%`, a `ref` temporary hoisted out of a parameter default) is lost here;
  # the build's syntax gate (check-coffee-syntax.js) taps this method and fails such a member.
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
      console.error "HELPER_VAR_NOT_STRIPPED: code contains a helper var, it shouldn't: " +  aString
      debugger

    return aString

  # ===== live member editing =====
  # My nonStaticPropertiesSources is the CURRENT source of every instance member I define: read
  # from my source text at boot, then kept by my two edits below -- an edit writes a member's
  # entry, a removal deletes it -- exactly as a Mixin keeps its own (Mixin.applyMemberEdit /
  # removeMember). My prototype holds my member where I define one, else the member my donor
  # mixin defines, else nothing. The live members are thereby a function of the stores, which is
  # what lets a world snapshot reproduce them by replaying the edits in order
  # (SourceEditsRegistry). It is also what keeps a member editable as CoffeeScript, what the class
  # inspector attributes a member to, and what Mixin's shadow guard keys off.
  # A rename is no edit of mine: it is an edit under the new name plus a removal of the old
  # (ClassInspectorWdgt._applyPropertyRename), so the member is RECOMPILED and its `super` follows
  # the new name (_superOf).
  # Callers: ClassInspectorWdgt's edit steps and SourceEditsRegistry.replayClassEdits (world-snapshot
  # restore). Telling the widgets is the CALLER's business (Class.notifyWidgetsOfAnEditTo) -- the
  # restore path replays before any instance exists.

  # Rewrite ONE member on my prototype from CoffeeScript source -- the CLASS twin of
  # Mixin.applyMemberEdit, with the SAME compile shape: a bare global-assignment eval, NOT
  # Widget.evaluateString, whose relayout/repaint tail treats its receiver as a WIDGET, and run on
  # a PROTOTYPE stamps widget-lifecycle fields (cachedRoot, dstDamageRectIndex, ...) onto it as own
  # properties, polluting every later member listing of the class. (The compiled output may
  # re-declare the CoffeeScript helper vars -- indexOf etc. -- at global scope; harmless, the
  # globals already hold exactly those values.) The super forms are rewritten exactly as the boot
  # emit does (_rewriteSuperCalls), so an edited member keeps calling super. Throws on compile
  # errors, having changed nothing.
  applyMemberEdit: (memberName, source) ->
    Class.refuseTheConstructor memberName, @name
    proto = window[@name].prototype
    # the typed source sits behind the assignment, so a compile error is placed in it (typedFrom);
    # a `super` the rewrite expands shifts the columns after it on its line
    assignment = "window.__fzEditedClassMember = "
    compiled = compileFGCode assignment + (@_rewriteSuperCalls memberName, source), true, typedFrom: assignment.length
    eval.call window, compiled
    proto[memberName] = window.__fzEditedClassMember
    delete window.__fzEditedClassMember
    @nonStaticPropertiesSources[memberName] = source
    return

  # Remove ONE member from my prototype, with its source and its injection companion
  # (`<name>_class_injected_in`, Object::addInstanceProperties). Then boot order holds, as if I had
  # never defined it: the mixin of mine that donates the member (Mixin.donorOf) gives it back --
  # its CURRENT member -- since my body's member won over the injection only by coming after it.
  # The donor's member is compiled before anything changes, so one that does not compile throws
  # having changed nothing.
  removeMember: (memberName) ->
    Class.refuseTheConstructor memberName, @name
    donor = Mixin.donorOf @, memberName
    donorsMember = donor?.compiledCurrentMember memberName
    proto = window[@name].prototype
    delete proto[memberName]
    delete proto[memberName + "_class_injected_in"]
    delete @nonStaticPropertiesSources[memberName]
    Mixin.injectInto @name, memberName, donorsMember if donor?
    return

  # Do I define member `memberName` -- did my source text, or a later edit, give it to me? (An OWN
  # entry: my store is a plain object, whose inherited `constructor` is no member of mine.)
  definesMember: (memberName) ->
    Object::hasOwnProperty.call @nonStaticPropertiesSources, memberName

  # `constructor` is no member to edit or remove, on a class or through a mixin: a prototype's
  # `constructor` IS its class -- what every `.constructor.name` and `.constructor.class` read
  # answers (the Serializer writes it as a saved widget's class) -- and an edit of it would never
  # change what `new` runs. So the edits of both meta-objects refuse it, whoever calls them
  # (Class.applyMemberEdit / removeMember, Mixin.applyMemberEdit / removeMember).
  @refuseTheConstructor: (memberName, ownerName) ->
    if memberName is "constructor"
      throw new Error ownerName + "'s constructor is the class itself: it cannot be edited, renamed or removed as a member"
    return

  # The name of the class my source extends, or undefined. That class is read before me (the load
  # order follows `extends`); one that is not loaded is refused here, before anything of mine is
  # defined -- later, my emitted `__super__` line would fail at eval instead, leaving a half-built
  # global behind.
  findIfItExtendsAnotherClass: (source) ->
    extendsRegex = /^class[ \t]*[a-zA-Z_$][0-9a-zA-Z_$]*[ \t]*extends[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
    if (m = extendsRegex.exec(source))?
        superClassName = m[1]
        if window.srcLoadCompileDebugWrites then console.log "superClassName: " + superClassName
        unless window[superClassName]?
          throw new Error "class " + @name + " extends " + superClassName + ", which is not loaded"

    return superClassName

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

    sourceLines = source.split "\n"

    [@name, ignored, sourceLines] = @findClassDescriptionHeaderCommentAndClassName sourceLines
    @superClassName = @findIfItExtendsAnotherClass source
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

      # the class itself is its constructor function. A class that writes none gets the one
      # CoffeeScript gives it, which forwards every argument: as if it were written
      # `constructor: -> super`. That source is not the class's, so it skips the member step build
      # tools read the source's members at (_rewriteSuperCalls) and goes to the same super rewrite
      # directly. From there every constructor takes one path: it ends in `return`
      # (Class.endingInReturn), is compiled, and is stripped of the helper head.
      if @nonStaticPropertiesSources.hasOwnProperty "constructor"
        constructorSource = @_rewriteSuperCalls "constructor", @nonStaticPropertiesSources.constructor
      else
        constructorSource = Class.rewriteSuperCalls "->\n    super\n", @_superOf "constructor"
      constructorSource = Class.endingInReturn constructorSource, @name
      if window.srcLoadCompileDebugWrites then console.log "constructor declaration CS:\n" + constructorSource
      compiled = compileFGCode constructorSource, true
      constructorDeclaration = "window." + @name + " = " + @_removeHelperFunctions compiled

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


          fieldDeclaration = @_rewriteSuperCalls fieldName, fieldValue

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

          fieldDeclaration = @_rewriteSuperCalls fieldName, fieldValue

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
          console.error "SOURCE_EVAL_FAILED: " + err + " evaling : " + JS_string_definitions
          alert " error " + err + " evaling : " + JS_string_definitions


      window.classDefinitionAsJS.push JS_string_definitions

    # OK now that we have created the Class
    # (or if already created anyways, in pre-compiled mode)
    # then add the .class field
    window[@name].class = @

  # The WIDGETS an edit to one of my members can have changed, as a Set. While my instances are
  # widgets -- I am Widget, or on its branch -- they are my `instances` set: a widget is in the set
  # of its class and of every superclass (Widget.registerThisInstance), so it holds my subclasses'
  # too, and none is left out, not even a subclass's whose own definition of the member overrides
  # mine -- an override can call super, and many do -- since a widget told once too often costs one
  # repaint, where one left out keeps a stale look. Any other class (a value class, an appearance, a
  # layout spec) has no instance that registers, and any widget may paint with it, so its answer is
  # every widget (Widget's set) -- the very set TreeNode's holds, above Widget, which every widget
  # registers in too. Asked by class RELATION, never by a member my prototype holds: a member is
  # exactly what an edit of mine can add or take away.
  widgetsAnEditCanChange: ->
    klass = window[@name]
    if klass is Widget or Widget::isPrototypeOf klass.prototype then klass.instances else Widget.instances

  # After an edit -- one gesture, which can change several classes (a mixin edit changes each consumer
  # class it updates) -- every widget it can have changed hears of it ONCE (Widget.sourceChanged: its
  # re-layout hook and a repaint): the union of the classes' answers, each widget told once however
  # many of them name it. Callers: the class inspector's gestures. A snapshot's replay tells no one:
  # it runs before any instance exists.
  @notifyWidgetsOfAnEditTo: (classes) ->
    widgets = new Set
    for eachClass in classes
      eachClass.widgetsAnEditCanChange().forEach (eachWidget) -> widgets.add eachWidget
    widgets.forEach (eachWidget) -> eachWidget.sourceChanged()
    return

