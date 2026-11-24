# ONE MEMBER OF ONE OBJECT: the member `name` of `holder`. I say what an inspector shows of that
# member (shownText), and I am the one place that knows HOW it is edited. An OBJECT's member is
# edited through the instance edit protocol -- Widget.injectProperty, addOwnProperty,
# renameOwnProperty, removeOwnProperty, verbs that edit alone and tell no one -- and each of my steps
# (add, save, rename, remove) is a person's gesture: it makes the edit, records it where a world
# snapshot needs it (a Save of a function: SourceEditsRegistry), and tells ONCE (_notifyOfEdit). A
# class's member is ClassMemberRef's, whose steps go through the class's meta-object instead.
#   Which subjects an inspector edits at all is the inspector's question
# (InspectorWdgt._subjectIsEditable, and the guards of its gestures): a step of mine assumes it was
# asked.
#
# SHALLOWLY IMMUTABLE (docs/architecture/immutable-value-classes.md): my two fields are never written
# after construction, though `holder` is a live object. An inspector makes me for the one gesture
# that asks (InspectorWdgt._memberRefOf) and drops me: no widget holds me, so nothing serializes or
# duplicates me.
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

  constructor: (@holder, @name) ->

  # What an inspector shows of my member, which its selectionFromList loads into its code pane: a
  # function's source, read where my holder holds it, or a field's recorded source, else its value.
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

  # Can a rename or a removal act on my member? Only on a member my holder OWNS. One up its
  # prototype chain belongs to a class, and is edited in that class's inspector: removed here it
  # would delete nothing, and renamed here it would become a copy of the class's member on my holder
  # with no source of its own, which no world snapshot can save. Nor `constructor`, which is my
  # holder's class itself (Class.refuseTheConstructor).
  canBeRenamedOrRemoved: ->
    @name isnt "constructor" and Object::hasOwnProperty.call @holder, @name

  # the one differing step between an object's and a class's add (mirroring save below): an object's
  # member goes through the Widget-level addOwnProperty twin. ClassMemberRef overrides this with its
  # class edit step.
  add: ->
    @holder.addOwnProperty @name
    @_notifyOfEdit()

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

  # the one differing step between an object's and a class's rename (mirroring save above): an
  # object's member goes through the Widget-level renameOwnProperty twin (an injected method's
  # function carries its kept source to the new name). ClassMemberRef overrides this with an edit
  # under the new name and a removal of the old. The gesture has refused the name my member already
  # has and `constructor` (InspectorWdgt.renameProperty): a move onto itself would drop the member.
  rename: (newName) ->
    @holder.renameOwnProperty @name, newName
    @_notifyOfEdit()

  # removal's differing step, same seam as rename: an object's member goes through the Widget-level
  # removeOwnProperty twin (the member's function goes, and its kept source with it).
  # (ClassMemberRef overrides this with its class removal step.)
  remove: ->
    @holder.removeOwnProperty @name
    @_notifyOfEdit()

  # The one notification each of my edit steps ends in, once its edit is made: my holder's
  # (Widget.sourceChanged), since the edit was made under it. ClassMemberRef's is the world's.
  _notifyOfEdit: ->
    # settling-call-sanctioned: the tail of my edit steps, which only an inspector's edit gestures reach (its
    # Save, Add…, Rename… and Remove), at event time and never inside a settle -- the notification is the edit's
    # own settle
    @holder.sourceChanged()
