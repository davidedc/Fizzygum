# BUILD-TIME SYNTAX GATE DEPENDENCY:
# buildSystem/check-coffee-syntax.js loads THIS file in Node and drives every shipped
# source through `new Class(src, true, false)` (generate-precompiled mode: it compiles
# each fragment but eval's nothing) to catch CoffeeScript syntax errors at build time,
# before they would otherwise only surface at in-browser boot. It loads it through
# buildSystem/lib/meta-compiler.js (as every build tool that reads the meta-system does),
# whose shim supplies the globals this class touches at construction time (window, with
# srcLoadCompileDebugWrites on it, compileFGCode, JSSourcesContainer, and CoffeeScript -- the
# bundled compiler, whose lexer the super rewrite and every constructor's ending read).
# If you make the constructor / its helpers read a NEW global, add a matching stand-in to
# that shim or the gate will break with an operational (exit 2) error.

class Class

  nonStaticPropertiesSources: undefined
  staticPropertiesSources: undefined
  # What my text says beside my members' code, read by the same parse (getSourceOfAllProperties): each member's
  # comment and category, by name, statics and instance members apart, a store holding a member only where my text
  # gives it one; my class's own comment, "" where my text writes none; and my categories' names, each once, in the
  # order my markers first name them. Each kept current by my edits since, as my sources are (live member editing,
  # below).
  nonStaticPropertiesComments: undefined
  staticPropertiesComments: undefined
  nonStaticPropertiesCategories: undefined
  staticPropertiesCategories: undefined
  classComment: ""
  categoryNames: undefined
  name: ""
  superClassName: undefined
  classRegex: /^class[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
  propertyRegex: /^  (@?[a-zA-Z_$][0-9a-zA-Z_$]*) *: *(.*)/m
  topLevelCommentRegex: /^  #.*/m
  # A METHOD CATEGORY's marker: a line that is exactly two spaces, `#:`, one space and the category's name
  # (Class.isACategoryName). A comment at the member column ends the body above it (topLevelCommentRegex), so a
  # marker stands between two members, in the next one's stash, as every such comment does; it gives its category
  # to every member after it, up to the next marker.
  categoryMarkerRegex: /^  #: (.*)$/


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

  # THE SUPER REWRITE: the caller passes the member its `super` means as `superBase`
  # (`<Name>.__super__.<member>`, _superOf). CoffeeScript compiles `super` only inside a class
  # body, and the meta-system compiles every member ALONE, so each `super` is spelled out as a
  # call through `superBase` before the member is compiled.
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
    lines[line] = lines[line].slice(0, column + 1) + "\n  " + lines[line].slice(column + 1).trimStart()
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
  # is what that boot comment relies on.
  # Because the cut takes EVERY declaration, a name in that head other than the three globals
  # (`modulo` from `%%`, a `ref` temporary hoisted out of a parameter default) is lost here;
  # the build's syntax gate (check-coffee-syntax.js) taps this method and fails such a member.
  _removeHelperFunctions: (aString) ->
    aString = aString.replace /^var(.|\n)*?\(function/, "(function"

    # TRIPWIRE for a helper declaration the cut above did not reach -- a fragment that declares
    # helpers without opening on `(function`. ⚠ It keys off the emitted `var` STATEMENT
    # (anchored at column 0, which only a top-level declaration is, and reaching to the `;`
    # because the helpers may ride on continuation lines), NOT off the bare `[].indexOf`
    # expressions: those occur in the compiled body of this method -- its patterns are literals
    # in it -- so an expression-shaped detector reports the stripper itself, on every build.
    if /^var\b[^;]*\b(hasProp|indexOf|slice)\s*=/m.test aString
      console.error "HELPER_VAR_NOT_STRIPPED: code contains a helper var, it shouldn't: " +  aString

    return aString

  # ===== live member editing =====
  # My nonStaticPropertiesSources is the CURRENT source of every instance member I define: read
  # from my source text at boot, then kept by my two edits below -- an edit writes a member's
  # entry, a removal deletes it. My prototype holds my member where I define one, else nothing (my
  # instances then inherit the member from my superclass). The live members are thereby a function
  # of the stores, which is what lets a world snapshot reproduce them by replaying the edits in
  # order (SourceEditsRegistry). It is also what keeps a member editable as CoffeeScript.
  # My member's comment and category are kept by the same two edits (an edit keeps them, sets them
  # where it is handed them, or carries another member's for a copy; a removal drops them), and my
  # class's own comment and category list by two whole-value verbs (setClassComment, setCategories).
  # A rename is no edit of mine: it is an edit under the new name plus a removal of the old
  # (ClassMemberRef.rename), so the member is RECOMPILED and its `super` follows
  # the new name (_superOf).
  # Callers: ClassMemberRef's edit steps (an inspector's gestures), and a world-snapshot load's
  # return to boot and replay (SourceEditsRegistry.returnThePageToBootSources, replayClassEdits).
  # I edit and tell no one: telling the widgets is my CALLER's business, and each caller ends in one
  # WorldWdgt.noteCodeChanged -- a gesture once it has made all its edits, a load once it has
  # returned and replayed them all -- since an edit's readers are the whole world, not my instances (a
  # menu row re-fits its label, a stack reads its children's layout specs).

  # Rewrite ONE member on my prototype from CoffeeScript source: a bare global-assignment eval,
  # then a plain write of the result onto the prototype, so nothing runs WITH the prototype as
  # `this`: code run against a prototype stamps whatever fields it sets onto it as own properties,
  # polluting every later member listing of the class. (The compiled output may
  # re-declare the CoffeeScript helper vars -- indexOf etc. -- at global scope; harmless, the
  # globals already hold exactly those values.) The super forms are rewritten exactly as the boot
  # emit does (_rewriteSuperCalls), so an edited member keeps calling super.
  # The member's comment and category ride in opts: opts.comment (lines of comment, Class.isAComment)
  # and opts.category (a category's name, Class.isACategoryName), each KEPT as the member has it
  # where its key is absent (or undefined), set where it is handed, "" clearing it. A handed note is
  # a person's or a file's, and one that is none of these is refused before the compile
  # (_refuseNotes). A copy hands none: opts.notesOf names my member whose comment and category the
  # edit CARRIES, as my stores hold them, unjudged (a duplicate's or a rename's copy,
  # ClassMemberRef._editCopyUnder); a note handed beside it is set instead. Throws on a refusal or a
  # compile error, having changed nothing.
  applyMemberEdit: (memberName, source, opts = {}) ->
    Class.refuseTheConstructor memberName, @name
    Widget.refuseCodeAfterAFunction source
    Class._refuseNotes opts.comment, opts.category
    notesOf = opts.notesOf ? memberName
    comment = opts.comment ? @commentOf notesOf
    category = opts.category ? @categoryOf notesOf
    proto = window[@name].prototype
    # the typed source sits behind the assignment, so a compile error is placed in it (typedFrom);
    # a `super` the rewrite expands shifts the columns after it on its line
    assignment = "window.__fzEditedClassMember = "
    compiled = compileFGCode assignment + (@_rewriteSuperCalls memberName, source), true, typedFrom: assignment.length
    eval.call window, compiled
    proto[memberName] = window.__fzEditedClassMember
    delete window.__fzEditedClassMember
    @nonStaticPropertiesSources[memberName] = source
    Class._keepIn @nonStaticPropertiesComments, memberName, comment
    Class._keepIn @nonStaticPropertiesCategories, memberName, category
    Class.keepMemberRecord proto[memberName], source
    Class.refreshFieldRecord proto, memberName
    return

  # The notes an edit hands in (applyMemberEdit's opts), refused where they are none: a comment is
  # lines of comment (Class.isAComment, which "" is: no comment), a category a category's name
  # (Class.isACategoryName) or "" (none). A note not handed (undefined) refuses nothing: the edit
  # keeps the member's, or carries the ones of the member opts.notesOf names, as they stand. So a
  # note is judged only as it comes in from outside my stores, never one my text gave a member: a
  # class made at run time, whose text may hold a `###` block or code between two members (the
  # parse keeps those lines as the next member's comment), keeps what its parse read there, and
  # each of its members is still edited, duplicated and renamed.
  @_refuseNotes: (comment, category) ->
    if comment? and !Class.isAComment comment
      throw new Error "a member's comment is lines of comment: each one blank or opening with #"
    if category? and category isnt "" and !Class.isACategoryName category
      throw new Error JSON.stringify(category) + " is no method category's name: lower-case words, one space between two, none of them opening with \"extends\""
    return

  # Remove ONE member from my prototype, with its source, its comment and category, and its field
  # record. Then my instances read the member my superclass holds, if any, as if I had never defined
  # it.
  removeMember: (memberName) ->
    Class.refuseTheConstructor memberName, @name
    proto = window[@name].prototype
    delete proto[memberName]
    delete @nonStaticPropertiesSources[memberName]
    delete @nonStaticPropertiesComments[memberName]
    delete @nonStaticPropertiesCategories[memberName]
    Class.refreshFieldRecord proto, memberName
    return

  # My class's own comment, replaced whole: lines of comment (Class.isAComment), "" for none;
  # anything else is refused, having changed nothing. It compiles nothing and tells no one, as my
  # member edits do.
  setClassComment: (text) ->
    unless Class.isAComment text
      throw new Error "a class's comment is lines of comment: each one blank or opening with #"
    @classComment = text
    return

  # My category list, replaced whole: distinct category names (Class.isACategoryName) in the order a
  # reader meets them, a category no member stands in yet included; anything else is refused, having
  # changed nothing. A member's category is the member's own (applyMemberEdit), so a member in a
  # category the list leaves out still shows it, after the list's (categories). It compiles nothing
  # and tells no one, as my member edits do.
  setCategories: (names) ->
    unless Array.isArray(names) and names.every((name) -> Class.isACategoryName name) and new Set(names).size is names.length
      throw new Error "a class's categories are distinct category names, each lower-case words, one space between two, none of them opening with \"extends\": " + JSON.stringify names
    @categoryNames = names.slice()
    return

  # Do I define member `memberName` -- did my source text, or a later edit, give it to me? (My store has no
  # prototype: an inherited `constructor` is no entry of it.)
  definesMember: (memberName) ->
    memberName of @nonStaticPropertiesSources

  # My instance member `memberName`'s comment: the one my text writes above it, as the parse keeps it
  # (_commentAndMarkersOf), or the one an edit gave it since (applyMemberEdit); "" where it has none, or where I define
  # no such member. (A static's is in my staticPropertiesComments.)
  commentOf: (memberName) ->
    @nonStaticPropertiesComments[memberName] ? ""

  # The category my instance member `memberName` stands in: the name of the last marker above it in my text, or the
  # one an edit put it in since; "" for none (a member above my first marker), or a name I define no member under.
  categoryOf: (memberName) ->
    @nonStaticPropertiesCategories[memberName] ? ""

  # My categories, in the order a reader meets them: my category list (categoryNames: my markers' names, each once, as
  # first met, or the list setCategories gave me since), then any other category one of my members stands in, each
  # once, in my category store's order.
  categories: ->
    names = @categoryNames.slice()
    for own memberName, category of @nonStaticPropertiesCategories when category not in names
      names.push category
    names

  # `constructor` is no member to edit or remove: a prototype's `constructor` IS its class -- what
  # every `.constructor.name` and `.constructor.class` read answers (the Serializer writes it as a
  # saved widget's class) -- and an edit of it would never change what `new` runs. So both edits
  # refuse it, whoever calls them (applyMemberEdit / removeMember).
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
  # all three callers supply exactly those; the two rarer controls ride opts, since only ONE caller
  # wants them (docs/architecture/constructor-and-parameter-conventions.md):
  #   opts.orStopOn         a SECOND stop-positive; either pattern ends the stash
  #   opts.keepStashWhenEOF at end of input, return what was collected instead of failing
  findUpTo: (sourceLines, regexStopPositive, opts = {}) ->
    # This works by prospectively collecting lines until a
    # stop regex is found.
    # If a stop positive is found, we return the stash and the line with the stop.
    # Otherwise, at end of file, we return false (or, with keepStashWhenEOF, the stash).
    regexStopPositive2 = opts.orStopOn
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

      # no stop found yet, keep collecting
      linesUpToStop.push eachLine

    if keepStashWhenEOF
      return ["", (sourceLinesOrig.join "\n"), [], []]
    else
      # reached the end of the file without finding a stop:
      # what we collected is no good
      return false

  # A RECORD STORE, keyed by member names, with NO prototype: a name nobody recorded is no record at any reader --
  # `constructor`, `toString` and every other Object.prototype member included. Every store of mine is made here.
  @_newRecordStore: -> Object.create null

  # My members' SOURCES, name -> source, statics and instance members in two stores, each in my text's order; then,
  # after them, what my text says beside the code (_notesOf). The first two positions are every reader's (a rig reads
  # them by position). Each member's STASH -- the lines between the body above it and its own line -- is kept as
  # written, beside the name, for that second pass: this loop splits, it reads no comment.
  getSourceOfAllProperties: (remainingSourceLines) ->
    staticPropertiesSources = Class._newRecordStore()
    nonStaticPropertiesSources = Class._newRecordStore()
    stashes = []

    while returned = @findUpTo remainingSourceLines, @propertyRegex
      propertyName = (returned[0].match @propertyRegex)[1]
      propertyComment = returned[1]
      stashes.push [propertyName, propertyComment]
      propertyFirstLineOfBody = (returned[0].match @propertyRegex)[2]
      remainingSourceLines = returned[2]
      if window.srcLoadCompileDebugWrites
        console.log "propertyName: " + propertyName + " =========="
        console.log "propertyComment: \n" + propertyComment
        console.log "propertyFirstLineOfBody: \n" + propertyFirstLineOfBody

      propertyBodyExceptFirstLine = ""
      if returned = @findUpTo(remainingSourceLines, @topLevelCommentRegex, orStopOn: @propertyRegex, keepStashWhenEOF: true)
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


    [staticPropertiesSources, nonStaticPropertiesSources, @_notesOf stashes]

  # What my members' stashes say beside the code ([name as written, stash], in my text's order, from
  # getSourceOfAllProperties), statics and instance members alike: each member's comment (_commentAndMarkersOf), and
  # its category -- the last marker at or above it, none above my first marker; and my categories' names, each once,
  # in the order their markers are first met. A member written twice keeps what its last writing says, as its source
  # does.
  _notesOf: (stashes) ->
    notes =
      staticPropertiesComments: Class._newRecordStore()
      nonStaticPropertiesComments: Class._newRecordStore()
      staticPropertiesCategories: Class._newRecordStore()
      nonStaticPropertiesCategories: Class._newRecordStore()
      categoryNames: []
    category = ""
    for [writtenName, stash] in stashes
      [comment, markers] = @_commentAndMarkersOf stash
      for marker in markers
        category = marker
        notes.categoryNames.push marker unless marker in notes.categoryNames
      if writtenName[0] is "@"
        Class._keepIn notes.staticPropertiesComments, writtenName[1..], comment
        Class._keepIn notes.staticPropertiesCategories, writtenName[1..], category
      else
        Class._keepIn notes.nonStaticPropertiesComments, writtenName, comment
        Class._keepIn notes.nonStaticPropertiesCategories, writtenName, category
    notes

  # A member's stash read as what it says: the names of its markers, in order, and its comment -- every other line,
  # less the two spaces of the member column, blank lines trimmed at its ends (Class._commentOfLines). A `#:` line
  # whose name is no category's (Class.isACategoryName) is no marker: it stays a line of the comment. Nothing here
  # throws: the build's syntax gate drives this parse over every file, where a throw fails the build.
  _commentAndMarkersOf: (stash) ->
    markers = []
    lines = []
    for line in stash.split "\n"
      if (marker = line.match(@categoryMarkerRegex)?[1])? and Class.isACategoryName marker
        markers.push marker
      else
        lines.push (if line.startsWith "  " then line.slice 2 else line)
    [Class._commentOfLines(lines), markers]

  # Lines read as a comment: joined, the blank lines at both ends trimmed; "" where no other line is left.
  @_commentOfLines: (lines) ->
    isBlank = (line) -> /^\s*$/.test line
    from = 0
    from++ while from < lines.length and isBlank lines[from]
    to = lines.length
    to-- while to > from and isBlank lines[to - 1]
    lines[from...to].join "\n"

  # A text kept in a record store under `memberName`, or, for "", no entry there at all: a store holds a member only
  # where there is something to say of it.
  @_keepIn: (store, memberName, text) ->
    if text then store[memberName] = text else delete store[memberName]
    return

  # Is `name` a METHOD CATEGORY's name: lower-case words, one space between two, none of them opening with `extends`.
  # The boot dependency scan (src/boot/dependencies-finding.coffee, EXTENDS) reads a blank, then `extends`, then the
  # word glued to it or after it on the line, as an edge, on any line of a class's text, a comment's included: a marker
  # naming `extendsfoo` or `extends things` would make its class load after a class `foo` or `things`. (The scan reads
  # one line at a time, so a name's last word `extends` reads no edge; it is refused all the same, by the one rule.)
  @isACategoryName: (name) ->
    typeof name is "string" and /^[a-z]+(?: [a-z]+)*$/.test(name) and !/(?:^| )extends/.test(name)

  # Is `text` lines of comment: every line of it blank, or opening (past its indent) with `#`. A `###` block's inner
  # lines do not, so a block comment is none by this rule.
  @isAComment: (text) ->
    typeof text is "string" and text.split("\n").every (line) -> /^\s*(#|$)/.test line

  # A member's text as an editor shows it (withLeadingComment), split back into the member's comment and its source.
  # The comment is the text's leading run of blank and `#` lines up to its LAST `#` line, "" where the text opens on
  # no `#` line; the source is everything after the line break that ends it. Up to the last `#` line, never to the
  # run's end: a source may open on a blank line (its value on the lines below), and that line stays the source's.
  # The one place this rule lives.
  @splitLeadingComment: (text) ->
    lines = text.split "\n"
    last = -1
    for line, i in lines
      if /^\s*#/.test line then last = i
      else break unless /^\s*$/.test line
    return {comment: "", source: text} if last < 0
    {comment: lines[..last].join("\n"), source: lines[last + 1..].join "\n"}

  # A member's comment and source joined as an editor shows them: the comment, a line break, the source; the source
  # alone where the comment is "". splitLeadingComment's inverse.
  @withLeadingComment: (comment, source) ->
    if comment then comment + "\n" + source else source

  # A class's source text parsed into what it is made of: its name; its static and instance member sources -- every
  # field definition, the constructor, the methods and the static members alike; and what the text says beside them
  # (_notesOf), with the class's own comment -- the lines above its `class` line, as written, blank lines trimmed at
  # its ends. Pure: read by my constructor, and by bootRecord to read my source text again.
  _parsedSource: (source) ->
    sourceLines = source.split "\n"
    [name, header, sourceLines] = @findClassDescriptionHeaderCommentAndClassName sourceLines
    [staticPropertiesSources, nonStaticPropertiesSources, notes] = @getSourceOfAllProperties sourceLines
    parsed =
      name: name
      classComment: Class._commentOfLines header.split "\n"
      staticPropertiesSources: staticPropertiesSources
      nonStaticPropertiesSources: nonStaticPropertiesSources
    Object.assign parsed, notes

  # My record as my source text at boot gives it -- the SourceVault's text, the one my constructor
  # parsed, read again by the same parse (_parsedSource): my members' sources, comments and
  # categories, my class's comment and category list, each under the name I hold it by, so one
  # comparison reads me and my boot alike (Class.membersAwayFrom, classNotesAwayFrom). What a
  # world-snapshot load returns me to before it replays a file's edits
  # (SourceEditsRegistry.returnThePageToBootSources). Undefined for a class the vault holds no text
  # for: one made at run time has no boot.
  bootRecord: ->
    source = SourceVault.get @name
    return undefined unless source?
    @_parsedSource source

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

    parsed = @_parsedSource source
    @name = parsed.name
    @superClassName = @findIfItExtendsAnotherClass source
    @staticPropertiesSources = parsed.staticPropertiesSources
    @nonStaticPropertiesSources = parsed.nonStaticPropertiesSources
    @staticPropertiesComments = parsed.staticPropertiesComments
    @nonStaticPropertiesComments = parsed.nonStaticPropertiesComments
    @staticPropertiesCategories = parsed.staticPropertiesCategories
    @nonStaticPropertiesCategories = parsed.nonStaticPropertiesCategories
    @classComment = parsed.classComment
    @categoryNames = parsed.categoryNames

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
      if "constructor" of @nonStaticPropertiesSources
        constructorSource = @_rewriteSuperCalls "constructor", @nonStaticPropertiesSources.constructor
      else
        constructorSource = Class.rewriteSuperCalls "->\n    super\n", @_superOf "constructor"
      constructorSource = Class.endingInReturn constructorSource, @name
      if window.srcLoadCompileDebugWrites then console.log "constructor declaration CS:\n" + constructorSource
      compiled = compileFGCode constructorSource, true, fromTheBuild: true
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


      # non-static fields, which are put in the prototype
      for own fieldName, fieldValue of @nonStaticPropertiesSources
        if fieldName != "constructor"
          if window.srcLoadCompileDebugWrites then console.log "building field " + fieldName + " ===== "


          fieldDeclaration = @_rewriteSuperCalls fieldName, fieldValue

          compiled = compileFGCode fieldDeclaration, true, fromTheBuild: true

          fieldDeclaration = @_removeHelperFunctions compiled
          fieldDeclaration = @_nameTheMemberFunction fieldName, fieldDeclaration
          fieldDeclaration = "window." + @name + ".prototype." + fieldName + " = " + fieldDeclaration

          if window.srcLoadCompileDebugWrites then console.log "field declaration: " + fieldDeclaration
          JS_string_definitions += fieldDeclaration + "\n"

      JS_staticConstantsBuiltWithClassItself_definitions = ""

      # now the static fields, which are put in the constructor
      # rather than in the prototype
      for own fieldName, fieldValue of @staticPropertiesSources
        if fieldName != "constructor"
          if window.srcLoadCompileDebugWrites then console.log "building STATIC field " + fieldName + " ===== "

          fieldDeclaration = @_rewriteSuperCalls fieldName, fieldValue

          compiled = compileFGCode fieldDeclaration, true, fromTheBuild: true

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

    @_keepMyMembersRecords()

  # THE SOURCE A MEMBER'S FUNCTION WAS MADE FROM, kept BY THE FUNCTION -- the rule Widget.keptSourceOf keeps for an
  # injected method, for the same reason: whatever replaces a member takes its function, and its source with it, so
  # no reader is handed one function's source for another. Kept where a member's function is made: a class made or
  # ingested (_keepMyMembersRecords) and a class edit (applyMemberEdit). A function's FIRST record is its record: a
  # member whose source names a function made elsewhere (`step: noOperation`, an edit to `Widget::bar`) leaves that
  # function's own record alone. A function no meta-object made (a run's) has none. Read by the inspectors, which ask
  # the function their subject holds, never a name; never by the save, which writes a widget's injected methods only
  # (a class member written as a widget's {"$src"} would compile on its own, `super` and all). Weak: it keeps no
  # function alive.
  @_memberRecords: new WeakMap
  @memberRecordOf: (aFunction) ->
    Class._memberRecords.get aFunction if typeof aFunction is "function"
  @keepMemberRecord: (aFunction, source) ->
    return unless typeof aFunction is "function" and source? and !Class._memberRecords.has aFunction
    Class._memberRecords.set aFunction, source
    return

  # A FIELD's twin of the record kept with a function: a value has no identity to key a record by, so the VALUE each
  # recorded field source made is kept with the PROTOTYPE it made it on (a prototype -> a Map of name -> value). An
  # inspector on a class's prototype shows a field's recorded source only while its subject still reads that very
  # value (fieldRecordHolds), never a source a run's write replaced (ClassMemberRef._fieldSource), and a rename
  # carries a field's source only then too. Two ways a record is made:
  #   - keepFieldRecord: a class BODY's field (_keepMyMembersRecords), kept ONCE, as a function's record is -- the
  #     reflective layer's ingest of a class already made keeps the record it has, never a run's write since;
  #   - refreshFieldRecord: an EDIT of a member (an edit, a removal): a field's record becomes the value the edit made,
  #     and a member gone, or now a function (which keeps its own record), leaves no field record behind.
  @_fieldRecords: new WeakMap
  @_fieldRecordsOf: (proto) ->
    Class._fieldRecords.set proto, new Map unless Class._fieldRecords.has proto
    Class._fieldRecords.get proto
  @keepFieldRecord: (proto, memberName) ->
    records = Class._fieldRecordsOf proto
    records.set memberName, proto[memberName] unless records.has memberName
    return
  @refreshFieldRecord: (proto, memberName) ->
    records = Class._fieldRecordsOf proto
    if Object::hasOwnProperty.call(proto, memberName) and typeof proto[memberName] isnt "function"
      records.set memberName, proto[memberName]
    else
      records.delete memberName
    return
  @fieldRecordHolds: (proto, memberName, value) ->
    values = Class._fieldRecords.get proto
    !!values?.has(memberName) and Object.is values.get(memberName), value

  # Keep, with each function my class holds, the source it was made from (Class.keepMemberRecord): my instance
  # members and statics as I record them, and my constructor's on my class function (where I write one); and, with my
  # prototype, the VALUE each of my fields' sources made (Class.keepFieldRecord). Each record is kept once. Run as I
  # am made, and as the reflective layer INGESTS me beside the code a pre-compiled image already runs. ⚠ At an ingest
  # a person's run may already have replaced a member, and neither its function nor its value can be told from the
  # image's: the minified image keeps no function names, so both are anonymous, and a value has no identity -- such a
  # member reads as my source (filed). My own keys only (Object.keys), never my whole chain's.
  _keepMyMembersRecords: ->
    klass = window[@name]
    return unless klass?
    proto = klass.prototype
    keep = (aFunction, source) -> Class.keepMemberRecord aFunction, source
    for memberName in Object.keys(proto) when memberName isnt "constructor" and memberName of @nonStaticPropertiesSources
      keep proto[memberName], @nonStaticPropertiesSources[memberName]
      Class.keepFieldRecord proto, memberName unless typeof proto[memberName] is "function"
    keep klass, @nonStaticPropertiesSources.constructor
    for staticName in Object.keys(klass) when staticName of @staticPropertiesSources
      keep klass[staticName], @staticPropertiesSources[staticName]
    return

  # The members of `current` (a meta-object) away from `boot` (its boot record, bootRecord): each
  # whose source, comment or category is not the one boot holds -- an edit, an addition or a removal
  # -- never the constructor, which no edit reaches (refuseTheConstructor). A note reads "" where a
  # store holds none (a store keeps no entry for ""). The one comparison of a member with its boot:
  # editsAwayFromBoot below, and a world-snapshot load's return to boot
  # (SourceEditsRegistry.returnThePageToBootSources).
  @membersAwayFrom: (current, boot) ->
    noteOf = (store, memberName) -> store[memberName] ? ""
    differs = (memberName) ->
      current.nonStaticPropertiesSources[memberName] isnt boot.nonStaticPropertiesSources[memberName] or
        noteOf(current.nonStaticPropertiesComments, memberName) isnt noteOf(boot.nonStaticPropertiesComments, memberName) or
        noteOf(current.nonStaticPropertiesCategories, memberName) isnt noteOf(boot.nonStaticPropertiesCategories, memberName)
    memberNames = new Set Object.keys(current.nonStaticPropertiesSources).concat Object.keys boot.nonStaticPropertiesSources
    (memberName for memberName from memberNames when memberName isnt "constructor" and differs memberName)

  # Which of the class's own two notes `current` (a meta-object) holds away from `boot` (its boot
  # record): "classComment", "categoryNames", each where it differs -- the list compared name by
  # name, in order.
  @classNotesAwayFrom: (current, boot) ->
    away = []
    away.push "classComment" if current.classComment isnt boot.classComment
    sameList = current.categoryNames.length is boot.categoryNames.length and
      current.categoryNames.every (name, i) -> name is boot.categoryNames[i]
    away.push "categoryNames" unless sameList
    away

  # My edits away from my boot (bootRecord): each member away (membersAwayFrom), then each of my
  # class's notes away (classNotesAwayFrom) -- none for a class with no boot. What a load's confirm
  # counts (SourceEditsRegistry.editsAwayFromBootCount).
  editsAwayFromBoot: ->
    boot = @bootRecord()
    return [] unless boot?
    Class.membersAwayFrom(@, boot).concat Class.classNotesAwayFrom @, boot

