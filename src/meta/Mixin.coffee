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
  # Every mixin the page has parsed from its source: what the inspectors attribute a donated member to
  # (InspectorWdgt.selectionFromList, through donorOf), what a class removal gives a
  # donor's member back from (donorOf), what a snapshot's mixin records replay onto. Filled through
  # register by the one step that ingests a page's sources (boot's
  # storeSourceAndPotentiallyCompileItAndExecuteIt), on BOTH its paths -- compiling a mixin to create
  # it, and parsing one whose code a pre-compiled image already runs. A Mixin made anywhere else
  # only parses (bootMemberSources, the build's syntax gate) and stays out of it.
  @allMixines: []
  nonStaticPropertiesSources: undefined
  # bootMemberSources, parsed once
  _bootMemberSources: undefined
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
  # edits (Class.applyMemberEdit): rewrite ONE injected member on the DONOR mixin and
  # push the recompiled member to every consumer class, so the edit behaves as if the
  # mixin had always said this. The class inspector routes here when the selected
  # member's source comes from a mixin (ClassInspectorWdgt).
  # My nonStaticPropertiesSources is the CURRENT source of every member I inject (an edit
  # writes it, a removal deletes it), as a Class's is of its own. A consumer's prototype holds
  # the member its class defines, else the member of its LAST augmentation that defines it
  # (Mixin.donorOf), else none: boot order put it so -- augmentWith runs before the class-body
  # assignments, and each augmentWith injects over the one before it -- and every edit, mine and
  # a class's, keeps it so (_isTheDonorTo). The live members are thereby a function of the stores.
  # I edit and tell no one: telling the widgets is the CALLER's business, as it is for a Class's
  # edits (WorldWdgt.noteCodeChanged, once per gesture or load). My edits answer the consumer
  # classes they updated, which the class inspector names in what it tells the person.

  # the classes this mixin is injected into -- recorded on the mixin LITERAL
  # (window.<name>Mixin) by Object::augmentWith at injection time.
  _consumerClassNames: ->
    window[@name + "Mixin"]?.consumerClassNames or []

  # The parsed Mixin named `name` -- the mixin global's name ("HighlightableMixin", what a
  # class's augmentedWith holds) or the parsed one's own ("Highlightable"), among those registered
  # (allMixines, register).
  @named: (name) ->
    Mixin.allMixines.find (m) -> m.name is name or m.name + "Mixin" is name

  # Register `aMixin` as the page's parse of its mixin, once per name: the reflective layer's ingest
  # walks every source the vault holds, a lazy part's already-ingested ones included, so a second
  # parse of a registered mixin is not the page's -- the first, which edits may since have changed,
  # stays.
  @register: (aMixin) ->
    Mixin.allMixines.push aMixin unless Mixin.named(aMixin.name)?
    return

  # The parsed Mixins among the augmentations of the class `theClass` (a Class meta-object) that
  # define member `memberName`, in augmentation order.
  @donorsOf: (theClass, memberName) ->
    (theMixin for mixinName in (theClass.augmentedWith ? []) when (theMixin = Mixin.named mixinName)?.definesMember memberName)

  # The parsed Mixin that DONATES member `memberName` to the class `theClass`: of its
  # augmentations that define it, the LAST, whose member boot order left on the prototype; or
  # undefined. The inspectors read it to attribute a donated member to its donor, which routes a class
  # inspector's edits of it there; Class.removeMember, to give the member back.
  @donorOf: (theClass, memberName) ->
    Mixin.donorsOf(theClass, memberName).pop()

  # My members as my source text at boot gives them -- the SourceVault's text, parsed the way my
  # constructor parsed it (a Mixin made without its create flags parses and does nothing else): what a
  # world-snapshot load returns me to before it replays a file's edits
  # (SourceEditsRegistry.returnThePageToBootSources), and what a consumer class made after my edits
  # is measured against (Class._takeMixinMembersFromTheStores, once per class made). Parsed once: the
  # text is the page's for good, and every caller only reads the answer -- never mutate it. Undefined
  # for a mixin the vault holds no text for.
  bootMemberSources: ->
    return @_bootMemberSources if @_bootMemberSources?
    source = SourceVault.get @name + "Mixin"
    return undefined unless source?
    @_bootMemberSources = new Mixin(source, false, false).nonStaticPropertiesSources

  # My members away from my boot sources (Class.membersAwayFrom): none for a mixin with no boot.
  membersAwayFromBoot: ->
    bootSources = @bootMemberSources()
    return [] unless bootSources?
    Class.membersAwayFrom @nonStaticPropertiesSources, bootSources

  # Do I define member `memberName`? (My store has no prototype: no inherited name is an entry of it.)
  definesMember: (memberName) ->
    memberName of @nonStaticPropertiesSources

  # Does consumer class `theClass` (a class function) hold member `memberName` from ME? Not if
  # its class defines the member itself -- the class won at boot, and a class edit or removal
  # keeps its store current (Class.applyMemberEdit / removeMember), so that covers the class body
  # and every override born since -- nor if another of its augmentations is the donor. This one
  # question is how every edit of mine keeps a consumer's prototype what boot order says.
  _isTheDonorTo: (theClass, memberName) ->
    !theClass.class?.definesMember(memberName) and Mixin.donorOf(theClass.class, memberName) is @

  # Member `memberName` compiled from `source` with the mixin super rewrite, evaluated on its
  # own. Throws on compile errors, having changed nothing.
  _compiledMember: (memberName, source) ->
    # the typed source sits behind the assignment, so a compile error is placed in it (typedFrom);
    # a `super` the rewrite expands shifts the columns after it on its line
    assignment = "window.__fzEditedMixinMember = "
    compiled = compileFGCode assignment + (@_rewriteSuperCalls source), true, typedFrom: assignment.length
    compiled = @_removeHelperFunctions compiled
    eval.call window, compiled
    value = window.__fzEditedMixinMember
    delete window.__fzEditedMixinMember
    # only a function the source MAKES is named: a source naming one made elsewhere (`noOperation`) hands
    # over that function, whose name is its own
    if typeof value is "function" and Widget.spellsAFunctionLiteral source
      # the fake-super rewrite resolves its target through
      # `arguments.callee.name + "_class_injected_in"`: the object-literal form gave
      # the original function the member's name, the standalone recompile does not --
      # restore it.
      Object.defineProperty value, "name", { value: memberName, configurable: true }
    # kept with its function, whichever consumer it goes to (Class.memberRecordOf)
    Class.keepMemberRecord value, source
    value

  # My CURRENT member `memberName`, compiled from my store -- what a consumer falls back to when
  # the member it held over mine goes (Class.removeMember, and removeMember below). Throws on
  # compile errors, so a caller compiles it before changing anything.
  compiledCurrentMember: (memberName) ->
    @_compiledMember memberName, @nonStaticPropertiesSources[memberName]

  # The ONE injection of a member into a consumer class after boot: the member, and for a
  # function the class it is injected in, which its `super` reads -- what
  # Object::addInstanceProperties writes at boot.
  @injectInto: (className, memberName, value) ->
    theClass = window[className]
    theClass::[memberName] = value
    if typeof value is "function"
      theClass::[memberName + "_class_injected_in"] = className
    else
      delete theClass::[memberName + "_class_injected_in"]
    return

  # The injection undone: the member and its fake-super companion leave consumer class `className`'s
  # prototype, which then holds what its chain gives it.
  @withdrawFrom: (className, memberName) ->
    delete window[className]::[memberName]
    delete window[className]::[memberName + "_class_injected_in"]
    return

  # Apply an edit to member `memberName`: recompile the single member, update my recorded
  # source (the store a class inspector's field rows and renames read), and inject the member into every consumer
  # class that holds it from me (_isTheDonorTo). Answers the names of the consumer classes
  # updated. Throws on compile errors, having changed nothing.
  applyMemberEdit: (memberName, source) ->
    Class.refuseTheConstructor memberName, @name + "Mixin"
    Widget.refuseCodeAfterAFunction source
    editedValue = @_compiledMember memberName, source
    @nonStaticPropertiesSources[memberName] = source
    for className in @_consumerClassNames() when window[className]? and @_isTheDonorTo window[className], memberName
      Mixin.injectInto className, memberName, editedValue
      className

  # Remove member `memberName` from this mixin: drop the recorded source, and give each consumer
  # class that held the member from me what boot order gives it without mine -- the member of its
  # augmentation before me that defines it, else none (the injected member and its fake-super
  # companion deleted). Each fallback is compiled before anything changes, so one that does not
  # compile throws having changed nothing. Answers the names of the consumer classes updated.
  removeMember: (memberName) ->
    Class.refuseTheConstructor memberName, @name + "Mixin"
    fallbacks = for className in @_consumerClassNames() when window[className]? and @_isTheDonorTo window[className], memberName
      previousDonor = Mixin.donorsOf(window[className].class, memberName).slice(-2)[0]
      previousDonor = undefined if previousDonor is @
      className: className, donor: previousDonor, value: previousDonor?.compiledCurrentMember memberName
    delete @nonStaticPropertiesSources[memberName]
    for each in fallbacks
      if each.donor?
        Mixin.injectInto each.className, memberName, each.value
      else
        Mixin.withdrawFrom each.className, memberName
      each.className

  # TRIPWIRE for an injected member I hold no source for. My parse (the constructor) reads the
  # members as the 6-space keys of the literal onceAddedClassProperties hands to
  # addInstanceProperties; a member written at any other indentation is injected all the same and
  # recorded nowhere -- the inspector then shows its compiled JS, its edits cannot reach me, and a
  # class that removes its own same-named member has nothing to fall back to. So the literal's
  # hook is run once against a stand-in that only collects the member names it is handed (every
  # mixin's onceAddedClassProperties does nothing else), and each one I do not define is reported.
  _reportMembersWithoutSource: ->
    injected = []
    collector = addInstanceProperties: (fromClass, members) ->
      injected.push key for own key of members when key not in MixedClassKeywords
    window[@name + "Mixin"]?.onceAddedClassProperties?.call collector, @name
    for key in injected when !@definesMember key
      console.error "MIXIN_MEMBER_UNRECORDED: " + @name + "Mixin." + key + " is injected but has no recorded source -- write it as a 6-space key, as Mixin's parse reads them"
    return

  constructor: (source, generatePreCompiledJS, createMixin) ->

    # name -> source, with no prototype (as Class's stores): a name nobody recorded is no record
    @nonStaticPropertiesSources = Object.create null

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
        @_reportMembersWithoutSource()


    #if @name == "LCLCodePreprocessor" then debugger

