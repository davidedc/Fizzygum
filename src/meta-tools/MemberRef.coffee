# ONE MEMBER OF ONE OBJECT: the member `name` of `holder`. I say what an inspector shows of that
# member (shownText), and I am the one place that knows HOW it is edited. An OBJECT's member is
# edited through the instance edit protocol -- Widget.injectProperty, addOwnProperty,
# duplicateOwnProperty, renameOwnProperty, removeOwnProperty, verbs that edit alone and tell no one
# -- and each of my steps (add, save, duplicate, rename, remove) is a person's gesture: it makes the
# edit, records it where a world snapshot needs it (a Save of a function: SourceEditsRegistry), tells
# ONCE (_notifyOfEdit), and answers whether it made the edit. A class's member is ClassMemberRef's,
# whose steps go through the class's meta-object instead.
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
  # object that services the instance edit protocol (injectProperty and its twins, which arrive
  # together on Widget, so one probe answers for them all) -- a CAPABILITY query, never
  # `instanceof Widget`, so a future non-widget that services the protocol is edited too. A number, a
  # string, a Point, a plain object, a built-in class's prototype, a class function: no -- you cannot
  # inject a property into 42. Asked by every edit gesture, not only by the builds that offer them:
  # a restored list or editor keeps the buttons its file holds.
  @canEdit: (holder) ->
    (isAClassPrototype holder) or holder?.injectProperty?

  # What code typed in a member's editor runs against (TextWdgt._codeReceiver, through
  # MemberEditorWdgt.codeReceiver): its holder, exactly while the holder is an object whose members
  # are edited as an object's. Code run against a widget is an edit made under it
  # (Widget.evaluateString), so the run scope is the edit scope; a holder no edit reaches -- a number,
  # an immutable Point, a plain object, a function -- gets no run rows at all, rather than rows that
  # throw or write to a value meant to stay as it is, and neither does a class's prototype, whose
  # class code run against it would change unrecorded.
  @codeReceiverOf: (holder) ->
    holder if holder?.injectProperty? and !isAClassPrototype holder

  constructor: (@holder, @name) ->

  # A member is what I am: an inspector whose subject I am shows my editor, and no member list and no
  # class chip (InspectorWdgt), whoever holds me.
  editsAsAMember: -> true

  # what an inspector titles me (Utils.colloquialNameOf asks): my member's name
  colloquialName: -> @name

  # Do I name the same member as `other` -- the same holder's, under the same name? Two references
  # made for one member at two clicks are two objects, and an inspector showing one shows the other
  # (InspectorWdgt.showsSubject), so a member chosen again reloads the editor already showing it.
  sameMemberAs: (other) ->
    (other?.editsAsAMember?() is true) and other.holder is @holder and other.name is @name

  # What an inspector shows of my member, which its member editor shows (MemberEditorWdgt: its build,
  # and its reload when the member is chosen again): a function's source, read where my holder holds
  # it, or a field's recorded source, else its value.
  shownText: ->
    val = @holder[@name]

    # A function shows the source of the member my holder HAS, read where it is held: the first link
    # of my holder's prototype chain that holds the member decides.
    #   Held by anything but a Fizzygum class's prototype -- my holder itself, or an object it was
    # made from -- it is a function of that holder's own: the source it keeps (Widget.keptSourceOf, an
    # injected one's), or, held by a class FUNCTION, the source recorded for that very static
    # (_recordedStaticSourceOf), else its compiled text; never the source of a class member it shadows.
    #   Held by a class's prototype, it is a class member: the source kept WITH that very function
    # (Class.memberRecordOf), never a source recorded under its NAME, which a run's replacement need not
    # be. A function with none reads as its compiled text. A `constructor` row is the class function:
    # its constructor's source where the class writes one, else its compiled text.
    if Utils.isFunction(val)
      holder = @holder
      holder = Object.getPrototypeOf holder until !holder? or Object::hasOwnProperty.call holder, @name
      if holder? and !isAClassPrototype holder
        ownSource = Widget.keptSourceOf(val) ? MemberRef._recordedStaticSourceOf holder, @name
        val = ownSource if ownSource?
      else if (source = Class.memberRecordOf val)?
        val = source
      txt = val.toString()
    else
      # a field shows its recorded source where there is one, else its own VALUE -- an undefined
      # field reads "undefined", whatever my holder's constructor holds under the same name
      if (fieldSource = @_fieldSource())?
        txt = fieldSource
      else if !val?
        txt = "undefined"
      else if Utils.isString val
        txt = '"'+val+'"'
      else
        # a value with no prototype has no toString of its own: it reads as Object's does
        txt = if Utils.isFunction val.toString then val.toString() else Object::toString.call val
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
  # member goes through the Widget-level addOwnProperty twin. ClassMemberRef overrides this with its
  # class edit step.
  add: ->
    @holder.addOwnProperty @name
    @_notifyOfEdit()
    true

  # the one differing step between an object's and a class's save: an object's member is injected
  # onto my holder (ClassMemberRef overrides this to edit the class's member through its
  # meta-object). A function saved is logged as an instance-scope source edit, which a world snapshot
  # carries (SourceEditsRegistry, §12): this Save is the one writer of that record, so the product's
  # own injections (a paint tool's handlers, a load's re-injections) log nothing.
  save: (txt) ->
    @holder.injectProperty @name, txt
    if Utils.isFunction @holder[@name]
      world?.sourceEditsRegistry?.recordInstanceEdit? @holder, @name, txt
    @_notifyOfEdit()
    true

  # the one differing step between an object's and a class's duplicate: my member, kept, and a copy
  # of it under newName on my holder, through the Widget-level duplicateOwnProperty twin (a field's
  # copy holds the same value; an injected method's is injected again from its kept source, so it
  # keeps a source of its own). Recorded nowhere, as a rename is not: a copied method rides a save
  # as its own {"$src"}. ClassMemberRef overrides this with an edit under the new name. The gesture
  # has refused `constructor` and a name my holder already owns (MemberListWdgt.duplicateProperty): a
  # copy never overwrites a member.
  duplicate: (newName) ->
    @holder.duplicateOwnProperty @name, newName
    @_notifyOfEdit()
    true

  # the one differing step between an object's and a class's rename (mirroring save above): an
  # object's member goes through the Widget-level renameOwnProperty twin (an injected method's
  # function carries its kept source to the new name). ClassMemberRef overrides this with an edit
  # under the new name and a removal of the old. The gesture has refused the name my member already
  # has and `constructor` (MemberListWdgt.renameProperty): a move onto itself would drop the member.
  rename: (newName) ->
    @holder.renameOwnProperty @name, newName
    @_notifyOfEdit()
    true

  # removal's differing step, same seam as rename: an object's member goes through the Widget-level
  # removeOwnProperty twin (the member's function goes, and its kept source with it).
  # (ClassMemberRef overrides this with its class removal step.)
  remove: ->
    @holder.removeOwnProperty @name
    @_notifyOfEdit()
    true

  # The one notification each of my edit steps ends in, once its edit is made: my holder's
  # (Widget.sourceChanged), since the edit was made under it. ClassMemberRef's is the world's.
  _notifyOfEdit: ->
    # settling-call-sanctioned: the tail of my edit steps, which only an inspector's edit gestures reach (a member
    # list's Add…, Duplicate…, Rename… and Remove, a member editor's Save), at event time and never inside a
    # settle -- the notification is the edit's own settle
    @holder.sourceChanged()
