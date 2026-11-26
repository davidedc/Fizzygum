# A PAINT TOOL AS AN OBJECT A PERSON EDITS: the person's tool for one key (a DrawingTool, made and
# kept by DrawingTool.of), whose OWN members are the tool -- applyToolAt, the one body a paint surface
# runs at every pointer move, and the helpers it calls (the toothpaste's paintBrush,
# initialiseQueueIfNeeded and pressEnded) -- each a function kept with its CoffeeScript source. A
# surface that takes the tool up puts each member on itself as an instance member, compiled there from
# its source (CanvasGlassTopWdgt._takeUpToolInReach), so a member's `@` is that surface, never me.
#   I hold EVERY prototype member a tool has: its fields, its name, the instance edit protocol it
# services (MemberRef's header states the protocol; I am its worked case of a holder that is no
# widget) and its write-through to the person. DrawingTool, what `new` makes, declares none of its
# own, so a member list on a tool -- whose default filter lists what the subject's own class declares
# and what no class declares -- lists the tool's own members alone, read dimmed as a widget's injected
# members are, with my plumbing one class up, where the Inherited filter lists it.
#   The protocol, verb by verb: my injection is the one body every holder shares
# (Widget.injectPropertyInto), evaluated by my own private eval (_evaluateAgainstMe); I keep only a
# member I can write back as TEXT, since the person's record keeps text (_sourceOfMember), and refuse
# any other as code that does not compile is refused; my add, duplicate and rename twins refuse a new
# member under a name the paint surface already answers (nameTheSurfaceAnswers), and each twin answers
# whether it made its edit; my notification (sourceChanged) writes me to the person, whose one table every
# palette and every surface reads (User.overrideDrawingTool).
#   I am EDITED AS AN OBJECT, but I am NO RECEIVER TYPED CODE RUNS AGAINST: I answer no evaluateString,
# the run verb, so a member editor on me offers no run rows (MemberRef.codeReceiverOf). My members run
# with `@` the paint surface that took me up, never me, so code run against me would mean nothing --
# and a run could leave me a member with no source, which no record of the person's could keep.
#   NO WIDGET: I hold functions, strings and a key, never a widget, so I stand in no tree and no
# teardown owes me anything; I live as long as the person who holds me (User.drawingTools).
class DrawingToolBase

  # the key I am the person's tool for ('pencil' | 'brush' | 'toothpaste' | 'eraser'): my name, and the
  # entry of the person's table my edits write (sourceChanged)
  toolKey: undefined
  # the person's record my members were last made from or written to (DrawingTool.of compares it, by
  # identity, with what my key means now) and its text (memberCode): derived, never saved
  _madeFrom: undefined
  _memberCode: undefined
  @serializationTransients: ["_madeFrom", "_memberCode"]
  # a copy of whatever holds me (an inspector window's Duplicate) holds ME: the person has one tool per key
  keptByReferenceOnDeepCopy: true

  # My key is my identity: a tool always has one.
  constructor: (@toolKey) ->

  # THE NAME OF THE TOOL A KEY NAMES, as a person reads it ("pencil tool"): its one definition, which a
  # tool answers as its own name (colloquialName) and so does the palette's tool button for that key
  # (CodeInjectingSimpleRectangularButtonWdgt.colloquialName), so a window, a menu's title and a row
  # naming either say the same words.
  @colloquialNameForKey: (toolKey) ->
    toolKey + " tool"

  # what an inspector titles me (Utils.colloquialNameOf asks): my key's tool's name
  colloquialName: ->
    DrawingToolBase.colloquialNameForKey @toolKey

  # ---- the instance edit protocol (MemberRef's header) ----------------------------------------

  # MY EVALUATION of an injection's assignment against myself: codeSource compiled (compileFGCode) and
  # run with me as `this`, the evaluation I hand the one body every holder shares
  # (Widget.injectPropertyInto), which may not call it itself (it is mine and private) and so is handed
  # it. The same one line as Widget.evaluateString, written here and not shared: a widget's injection
  # keeps evaluating in that method, as it is, and mine is PRIVATE, so I answer no run verb (my header:
  # no code is run against me). opts.typedFrom places a compile error in the text a person typed, as
  # Widget's does.
  _evaluateAgainstMe: (codeSource, opts = {}) ->
    eval compileFGCode codeSource, true, typedFrom: opts.typedFrom

  # The edit alone: the member `propertyName` becomes the value txt evaluates to, through the one body
  # every holder shares (Widget.injectPropertyInto: compiled before anything changes, a function made
  # from txt kept with its source). KEPT ONLY IF I CAN WRITE IT BACK AS TEXT, the way the person's
  # record keeps it (_sourceOfMember): a function with its kept source, or a value with a code form.
  # What a txt NAMING a function (`Math.max`) or holding a widget makes is neither, so I put back what
  # I held under that name -- my own member, or none -- and refuse it as code that does not compile is
  # refused (`isCompileError`), which the saving gesture tells beside the hand and leaves the editor
  # modified (Widget._savingTypedCode). Every plumbing caller (a load's {"$src"}, my duplicate twin)
  # hands me a kept source or a code form, and is never refused (a stand-in's text, duplicated, throws
  # again as it threw when I was made: _standInFor).
  injectProperty: (propertyName, txt) ->
    had = Object::hasOwnProperty.call @, propertyName
    before = @[propertyName]
    Widget.injectPropertyInto @, propertyName, txt, (assignment, opts) => @_evaluateAgainstMe assignment, opts
    return if DrawingToolBase._sourceOfMember(@[propertyName])?
    if had then @[propertyName] = before else delete @[propertyName]
    refusal = new Error "the code makes no member a tool can keep",
      cause: new Error "a tool's member is a function, or a value written as code"
    refusal.isCompileError = true
    throw refusal

  # the add twin: a new own member, undefined until a save gives it a value -- refused under a name the
  # paint surface answers (_refusesAsAToolMemberName). Answers whether it added.
  addOwnProperty: (propertyName) ->
    return false if @_refusesAsAToolMemberName propertyName
    @[propertyName] = undefined
    true

  # the duplicate twin: my member oldName, kept, and a copy of it under newName -- refused under a name
  # the paint surface answers. A function with its kept source is injected again under the new name, from
  # that source and through my own injectProperty, so the copy keeps a source of its own; anything else
  # is the slot copied. Answers whether it duplicated.
  duplicateOwnProperty: (oldName, newName) ->
    return false if @_refusesAsAToolMemberName newName
    keptSource = Widget.keptSourceOf @[oldName]
    if keptSource?
      @injectProperty newName, keptSource
    else
      @[newName] = @[oldName]
    true

  # the rename twin: my member re-keyed, its function carrying its kept source to the new name --
  # refused under a name the paint surface answers. Answers whether it renamed.
  renameOwnProperty: (oldName, newName) ->
    return false if @_refusesAsAToolMemberName newName
    @[newName] = @[oldName]
    delete @[oldName]
    true

  # the remove twin: my member goes, and with its function the source the function keeps. Answers that
  # it removed.
  removeOwnProperty: (propertyName) ->
    delete @[propertyName]
    true

  # A NAME NO TOOL MEMBER TAKES: one the paint surface already answers, owned or inherited -- a member
  # its class chain gives it or a field of its own, each declared at class level, so its class's
  # prototype answers them all. Every member of a tool is put on each surface that takes the tool up as
  # an OWN member, and deleted from it at the next change of tool (CanvasGlassTopWdgt._takeUpToolInReach):
  # under a name the surface answers, it would stand over the surface's own -- a member `width` over its
  # width(), so the stock code throws at every move; one named hoverMoved or pressMoved over the class
  # entries that take the tool up, so the drawing never paints again -- or overwrite a field of the
  # surface's and then delete it (`bounds`, `parent`), a drawing no one could mend. The rule a member
  # list holds a subject's own new names to (MemberListWdgt._refusesAsAnAnsweredName), one level over:
  # here the surface is what answers. Its ONE statement, asked at TWO doors and no third: the gestures
  # that make a member under a new name, which SAY it to the person (_refusesAsAToolMemberName: Add…,
  # Duplicate…, Rename…), and the surface's take-up, the point of damage, which keeps such a member off
  # every surface whatever brought it into the tool (CanvasGlassTopWdgt._takeUpToolInReach).
  @nameTheSurfaceAnswers: (name) ->
    name of CanvasGlassTopWdgt.prototype

  # A new member's name refused, saying why, when the paint surface answers it (nameTheSurfaceAnswers).
  # Said through the world (I am no widget to open a bubble from), the name quoted as a message that starts
  # with a member's name quotes it (MemberListWdgt._refusesAsAnAnsweredName). Answers whether it refused.
  _refusesAsAToolMemberName: (name) ->
    return false unless DrawingToolBase.nameTheSurfaceAnswers name
    world.inform '"' + name + '" is the paint\nsurface\'s own: no tool\nmember takes its name'
    true

  # THE ONE NOTIFICATION, a person's gesture's (an inspector's Save, Add…, Duplicate…, Rename… and
  # Remove): I write myself to the person as my key's tool (User.overrideDrawingTool, which
  # announces), the record I write being the one I remember making myself from, so I am not made again
  # from it. Every palette's cell and every paint surface reading my key takes the edit up at its next use
  # (DrawingTool.of, CanvasGlassTopWdgt._takeUpToolInReach). Nothing of mine paints, lays out or was
  # banned, so that is all an edit of mine changes.
  #   THE PERSON'S RECORD KEEPS EXACTLY MY MEMBERS THAT CAN BE READ BACK AS TEXT (memberSources). A
  # member with no source to state (_sourceOfMember answers none: a function with no kept source, a
  # value with no code form) is left out of it, never written as undefined -- no gesture of mine makes
  # one (my Save refuses it), but code run elsewhere can write one straight into me. Such a member stays
  # on me for the session, shown as any member with no source is, reaches no drawing (a surface takes up
  # only what my record holds as text), and is gone with my next make (_takeMembersFrom).
  sourceChanged: ->
    record = @memberSources()
    @_madeFrom = record
    @_memberCode = JSON.stringify record
    world.user.overrideDrawingTool @toolKey, record

  # ---- my members, read and made -------------------------------------------------------------

  # MY MEMBERS: my own properties no class of mine declares -- exactly what a member list stitches beside
  # my class's members (MemberListWdgt._filteredMemberNames); my fields are declared, so never members.
  _memberNames: ->
    (name for own name of @ when name not of Object.getPrototypeOf @)

  # MY MEMBERS AS THE PERSON'S RECORD KEEPS THEM: member name -> source text (_sourceOfMember), in my
  # members' order, a fresh record each time it is asked -- the members that can be read back as text
  # and no other (sourceChanged states the rule). What I write back, and so what my member code says.
  memberSources: ->
    stated = ([name, DrawingToolBase._sourceOfMember @[name]] for name in @_memberNames())
    Object.fromEntries (entry for entry in stated when entry[1]?)

  # MY MEMBER CODE: my record as one text, the JSON of member name -> source, which a paint surface
  # compares with the one it took up at every pointer move and, on a change, takes up and records as
  # one reading (CanvasGlassTopWdgt._takeUpToolInReach) -- the same string while nothing changed, so the
  # compare is by reference. Kept from my last make or write, worked out again only when neither kept it
  # (a tool restored from a file).
  memberCode: ->
    @_memberCode ?= JSON.stringify @memberSources()

  # The text a member of mine is kept as: a function's kept source (Widget.keptSourceOf), else a value's
  # code form (Utils.codeFormOf), else undefined -- a member that cannot be kept as text. The ONE answer
  # to "can this member be kept as text", which my Save's refusal asks (injectProperty) and my write-back
  # asks (memberSources), so the two cannot disagree.
  @_sourceOfMember: (value) ->
    Widget.keptSourceOf(value) ? Utils.codeFormOf(value)

  # MY MEMBERS MADE FROM `record` (member name -> source: the person's edit of my key, or its stock
  # members, PaintToolbarWdgt.stockToolMembers): every member of mine removed, the record remembered
  # FIRST, by identity (DrawingTool.of compares it) and as text (memberCode), so I am never made again
  # from the same record; then EVERY member of it tried, in its order, through the one body every holder
  # shares (Widget.injectPropertyInto) -- plumbing, refused nothing: a record holds kept sources and
  # code forms. A member whose text cannot be made (it does not compile, or it compiles and throws as it
  # is evaluated) stands in me as its stand-in (_standInFor), and after all of them the FIRST failure is
  # rethrown, ONCE: the house's road for code a person typed that compiles and then throws -- the asking
  # gesture's catch, which says it in the Error log -- while every later ask finds me made, of every
  # member I could make.
  _takeMembersFrom: (record) ->
    delete @[name] for name in @_memberNames()
    @_madeFrom = record
    @_memberCode = JSON.stringify record
    evaluate = (assignment, opts) => @_evaluateAgainstMe assignment, opts
    firstFailure = undefined
    for own name, source of record
      try
        Widget.injectPropertyInto @, name, source, evaluate
      catch error
        firstFailure ?= error
        @_standInFor name, source
    throw firstFailure if firstFailure?
    return

  # THE STAND-IN for my member `name`, whose text `source` in the person's record could not be made into
  # it: a FUNCTION THAT DOES NOTHING, keeping `source` as its source (Widget.keepSourceWith). A function,
  # because a function is the one kind of member that carries its own text: so the inspector lists the
  # member and its editor shows the person's text (MemberRef.shownText reads the kept source, and my
  # members are edited, MemberRef.canEdit), a Save of mended text makes the real member in its place
  # (injectProperty), and my write-back hands the text on unchanged (memberSources, through
  # _sourceOfMember), so the person's record loses nothing. It is a made member nowhere that would
  # mislead: no surface gets it -- a surface takes me up from the TEXT, which fails there the same way
  # and leaves the member off it (CanvasGlassTopWdgt._takeUpToolInReach) -- and a world snapshot or a
  # file holding me writes no {"$src"} for it (its text spells no function literal): that save is
  # refused by the member's name until it is mended or removed (Serializer), while the person's own
  # record carries the text. Its row in my member list reads as a method's ("fn").
  _standInFor: (name, source) ->
    standIn = ->
    Widget.keepSourceWith standIn, source
    @[name] = standIn
    return
