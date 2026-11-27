# ONE MEMBER OF ONE OBJECT: the member `name` of `holder`. I say what an inspector shows of that
# member (shownText), and I am the one place that knows HOW it is edited. An OBJECT's member is
# edited through THE INSTANCE EDIT PROTOCOL, which its holder services -- a widget (Widget), and a
# paint tool (DrawingToolBase, the worked case of a holder that is no widget). Its verbs make a holder
# EDITED AS AN OBJECT (canEdit asks for them):
#   - injectProperty (name, txt): the member becomes the value txt evaluates to, compiled before
#     anything changes (a compile error is thrown, changing nothing), a function made from txt kept
#     with its source -- through the one body every holder shares, Widget.injectPropertyInto, which
#     each holder hands its own evaluation of an assignment against itself (that body may not call a
#     holder's private one: a paint tool's is private, since it answers no run verb). A holder that
#     keeps only some members refuses the others there, thrown like a compile error.
#   - addOwnProperty (name), duplicateOwnProperty (oldName, newName), renameOwnProperty (oldName,
#     newName), removeOwnProperty (name): each ANSWERS WHETHER IT MADE ITS EDIT. A widget's always do; a
#     holder that refuses one changes nothing and says why itself.
#   - sourceChanged (): the ONE notification, made by a person's GESTURE once its edit is made -- my
#     steps' (_notifyOfEdit) and a run's (Widget._runningAPersonsCode) -- and by nothing else.
# A second capability, apart from the first: a RECEIVER TYPED CODE RUNS AGAINST answers
# evaluateString (code, opts), the RUN verb, code run with the holder as `this` -- what a member
# editor's run rows run (codeReceiverOf). A widget is both; a paint tool is edited as an object and is
# no receiver (its members run with `@` the paint surface, never the tool), so its editor has no run
# rows; the macro toolkit answers an evaluateString of its own and is not edited, so it has none either.
# Every edit verb but the notification edits alone and tells no one: the product drives them too, as
# plumbing (a paint surface taking its tool up, a load's {"$src"}). Each of my steps (add, save,
# duplicate, rename, remove) is a person's gesture: it makes the edit, records it where a world
# snapshot needs it (a Save of a function: SourceEditsRegistry), tells ONCE (_notifyOfEdit), and
# answers whether it made the edit -- a step its holder refused tells no one. A class's member is
# ClassMemberRef's, whose steps go through the class's meta-object instead.
#   Three questions about a holder are mine to answer too, so no inspector asks them another way:
# which reference a member of it takes (of), whether its members are edited at all (canEdit), and
# what code typed in a member's editor runs against (codeReceiverOf). A gesture asks before it takes
# a step, and a step of mine assumes it was asked.
#
# SHALLOWLY IMMUTABLE (docs/architecture/immutable-value-classes.md): my two fields are never written
# after construction, though `holder` is a live object. I am a VALUE an inspector's widgets hold: a
# member editor holds me (MemberEditorWdgt.memberRef), and I am an inspector's subject when it shows
# one member (InspectorWdgt.inspectedObject). So a copy and a save of either carry me, an ordinary
# object of my class, and I declare no keptByReferenceOnDeepCopy: a copy of an inspector together
# with its subject must point at the COPIED holder, which only an ordinary walk of me gives (the
# copy's identity map hands my copy the copied holder), never at the original's.
class MemberRef

  # the object whose member I am: a live object, read and edited where it is
  holder: undefined
  # my member's name in my holder
  name: undefined

  # The CoffeeScript kept with the function a Fizzygum class FUNCTION holds as its STATIC `name`
  # (Class.memberRecordOf): its own class's record, or -- a static `extend` copied down, still that very
  # function -- the declaring ancestor's. A function no class made under a record (a run's static, an
  # override no record names) has none and reads as its compiled text, which is true, where a source
  # recorded under the NAME would be code this class does not run. undefined for a holder that is no
  # class function, or a function with no record.
  @_recordedStaticSourceOf: (holder, name) ->
    return undefined unless typeof holder is "function" and classNamed(holder.name) is holder
    Class.memberRecordOf holder[name]

  # THE REFERENCE for the member `name` of `holder`: a CLASS's member when holder is a Fizzygum
  # class's prototype (isAClassPrototype), whose members are its class's, edited through the class's
  # meta-object and recorded, never as an object's; an object's otherwise. The one place that decision
  # is made, so no door that shows a class's prototype has to send it anywhere else.
  @of: (holder, name) ->
    if isAClassPrototype holder then new ClassMemberRef holder, name else new MemberRef holder, name

  # Can `holder`'s members be edited at all? A Fizzygum class's prototype, through its class; an
  # object that services the instance edit protocol (my header: its verbs arrive together, on a
  # widget and on a paint tool alike, so one probe answers for them all) -- a CAPABILITY query, never
  # `instanceof Widget`, so a non-widget that services the protocol is edited too (DrawingToolBase). A
  # number, a string, a Point, a plain object, a built-in class's prototype, a class function: no --
  # you cannot inject a property into 42. Asked by every edit gesture, not only by the builds that
  # offer them: a restored list or editor keeps the buttons its file holds.
  @canEdit: (holder) ->
    (isAClassPrototype holder) or holder?.injectProperty?

  # What code typed in a member's editor runs against (TextWdgt._codeReceiver, through
  # MemberEditorWdgt.codeReceiver): its holder, exactly when typed code can be RUN against it -- it is
  # EDITED AS AN OBJECT (injectProperty, the protocol canEdit asks for, whose notification, sourceChanged,
  # a run ends in) AND it is a RECEIVER TYPED CODE RUNS AGAINST (evaluateString, the run verb), and it is
  # no class's prototype, whose class code run against it would change unrecorded. Two capabilities,
  # both asked (my header names them apart). A widget answers both. A paint tool is edited but no
  # receiver: its members run with `@` the paint surface, never the tool, so it gets no run rows, and no
  # run can stitch a member onto it that its person's record could not keep. The macro toolkit answers
  # a run verb of its own but is not edited, so it has no notification for a run to end in: no run rows
  # either. A holder no edit reaches -- a number, an immutable Point, a plain object, a function -- gets
  # none at all, rather than rows that throw or write to a value meant to stay as it is.
  @codeReceiverOf: (holder) ->
    holder if holder?.injectProperty? and holder.evaluateString? and !isAClassPrototype holder

  constructor: (@holder, @name) ->

  # I am shown as ONE TEXT, a BODY: an inspector whose subject I am shows my editor, and no member list
  # and no class button (InspectorWdgt.showsOneText), whoever holds me, and an inspector browser stands
  # that inspector where its body goes (InspectorBrowserWdgt._placeNoSettle).
  editsAsText: -> true

  # what an inspector titles me (Utils.colloquialNameOf asks): my member's name
  colloquialName: -> @name

  # Do I name the same member as `other` -- the same holder's, under the same name? Two references
  # made for one member at two clicks are two objects, and an inspector showing one shows the other
  # (InspectorWdgt.showsSubject), so a member chosen again reloads the editor already showing it. Only a
  # member reference answers the question this compares by, so nothing else that holds a `holder` and a
  # `name` (another subject shown as one text) is ever the same member as I am.
  sameMemberAs: (other) ->
    other?.sameMemberAs? and other.holder is @holder and other.name is @name

  # What an inspector shows of my member, which its member editor shows (MemberEditorWdgt: its build,
  # its reload when the member is chosen again, and after a Save of a value): a function's source,
  # read where my holder holds it, or a field's recorded source, else its value as code.
  shownText: ->
    val = @holder[@name]

    # A function shows the source of the member my holder HAS, read where it is held: the first link
    # of my holder's prototype chain that holds the member decides.
    #   Held by anything but a Fizzygum class's prototype -- my holder itself, or an object it was
    # made from -- it is a function of that holder's own: the source it keeps (Widget.keptSourceOf, an
    # injected one's), or, held by a class FUNCTION, the source recorded for that very static
    # (_recordedStaticSourceOf); never the source of a class member it shadows.
    #   Held by a class's prototype, it is a class member: the source kept WITH that very function
    # (Class.memberRecordOf), never a source recorded under its NAME, which a run's replacement need not
    # be. A `constructor` row is the class function: its constructor's source where the class writes one.
    #   A function with no source kept or recorded shows as the one printer prints it
    # (Utils.printedFormOf): a Fizzygum CLASS by its name, its code form -- a field holding one, and
    # the `constructor` row of a class that writes no constructor -- and any other function as its
    # compiled text.
    if Utils.isFunction(val)
      holder = @holder
      holder = Object.getPrototypeOf holder until !holder? or Object::hasOwnProperty.call holder, @name
      source =
        if holder? and !isAClassPrototype holder
          Widget.keptSourceOf(val) ? MemberRef._recordedStaticSourceOf holder, @name
        else
          Class.memberRecordOf val
      txt = source ? Utils.printedFormOf val
    else
      # a field shows its recorded source where there is one, else its own VALUE as the one printer
      # prints values (Utils.printedFormOf): CoffeeScript that evaluates to it where it has a code
      # form, so a Save of the text as shown stores what is held -- `Color.create 80, 80, 80`, `[5]`, a
      # string escaped -- and its printed form where it has none (a widget's debug name). An
      # undefined field reads "undefined", whatever my holder's constructor holds under the same name.
      txt = @_fieldSource() ? Utils.printedFormOf val
    txt

  # the recorded SOURCE of my member when it is no function, or undefined to show its VALUE.
  # ClassMemberRef overrides this with the prototype-level truth (the source its class chain
  # records); an OBJECT's member keeps showing the instance's VALUE -- per-instance state is its own
  # truth.
  _fieldSource: ->
    undefined

  # Can a rename, a removal or a duplicate act on my member? Only on a member my holder OWNS. One up
  # its prototype chain belongs to a class, and is edited as that class's member: removed here it
  # would delete nothing, and renamed or duplicated here it would become a copy of the class's member
  # on my holder with no source of its own, which no world snapshot can save. Nor `constructor`, which
  # is my holder's class itself (Class.refuseTheConstructor).
  canBeRenamedOrRemoved: ->
    @name isnt "constructor" and Object::hasOwnProperty.call @holder, @name

  # the one differing step between an object's and a class's add (mirroring save below): an object's
  # member goes through its holder's addOwnProperty twin, and a twin that refused (my header) makes
  # this step change nothing and tell no one. ClassMemberRef overrides this with its class edit step.
  add: ->
    return false unless @holder.addOwnProperty @name
    @_notifyOfEdit()
    true

  # the one differing step between an object's and a class's save: an object's member is injected
  # onto my holder (ClassMemberRef overrides this to edit the class's member through its
  # meta-object); an injection that refuses throws, as one that does not compile does, so nothing
  # follows it. A function saved is logged as an instance-scope source edit, which a world snapshot
  # carries (SourceEditsRegistry, §12): this Save is the one writer of that record, so the product's
  # own injections (a paint surface taking its tool up, a load's re-injections) log nothing; and the
  # registry records only a holder with an identity (a widget's), so a paint tool's Save, which the
  # person's own record already carries, logs nothing either.
  save: (txt) ->
    @holder.injectProperty @name, txt
    if Utils.isFunction @holder[@name]
      world?.sourceEditsRegistry?.recordInstanceEdit? @holder, @name, txt
    @_notifyOfEdit()
    true

  # the one differing step between an object's and a class's duplicate: my member, kept, and a copy
  # of it under newName on my holder, through its duplicateOwnProperty twin (a field's copy holds the
  # same value; an injected method's is injected again from its kept source, so it keeps a source of
  # its own). Recorded nowhere, as a rename is not: a copied method rides a save as its own {"$src"}.
  # ClassMemberRef overrides this with an edit under the new name. I have no guard on newName: the
  # twin overwrites a member my holder has under it, and stands an own one over one my holder
  # inherits. The guard is my caller's: the member list's Duplicate… refuses `constructor` and a name
  # my holder already answers, owned or inherited, before it asks me (MemberListWdgt.duplicateProperty,
  # _refusesAsAnAnsweredName) -- and a holder refusing a name of its own refuses in its twin, which
  # makes this step change nothing and tell no one (my header).
  duplicate: (newName) ->
    return false unless @holder.duplicateOwnProperty @name, newName
    @_notifyOfEdit()
    true

  # the one differing step between an object's and a class's rename (mirroring save above): an
  # object's member goes through its holder's renameOwnProperty twin (an injected method's function
  # carries its kept source to the new name). ClassMemberRef overrides this with an edit under the new
  # name and a removal of the old. I have no guard on newName: the twin overwrites a member my holder
  # has under it, stands an own one over one my holder inherits, and a move onto my member's own name
  # would drop it. The guard is my caller's: the member list's Rename… (MemberListWdgt.renameProperty)
  # asks me with none of three names -- my member's own name, which is nothing to do, so it does
  # nothing and says nothing; `constructor`, refused; and a name my holder already answers, owned or
  # inherited, refused (_refusesAsAnAnsweredName) -- and a twin that refused makes this step change
  # nothing and tell no one.
  rename: (newName) ->
    return false unless @holder.renameOwnProperty @name, newName
    @_notifyOfEdit()
    true

  # removal's differing step, same seam as rename: an object's member goes through its holder's
  # removeOwnProperty twin (the member's function goes, and its kept source with it), a twin that
  # refused making this step change nothing and tell no one.
  # (ClassMemberRef overrides this with its class removal step.)
  remove: ->
    return false unless @holder.removeOwnProperty @name
    @_notifyOfEdit()
    true

  # The one notification each of my edit steps ends in, once its edit is made: my holder's
  # sourceChanged (a widget's, Widget.sourceChanged; a paint tool's, which writes it to the person),
  # since the edit was made under it. ClassMemberRef's is the world's.
  _notifyOfEdit: ->
    # settling-call-sanctioned: the tail of my edit steps, which only an inspector's edit gestures reach (a member
    # list's Add…, Duplicate…, Rename… and Remove, a member editor's Save), at event time and never inside a
    # settle -- the notification is the edit's own settle
    @holder.sourceChanged()
