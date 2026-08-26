# One PIN of a widget: a named property the dataflow can WRITE, READ, or both.
#
# One record per pin, the way CommandSpec describes a command -- rather than a pair of parallel
# arrays of labels and setter names, per kind. Two facts a record can carry and parallel arrays
# structurally cannot:
#
#   • a pin can be READ, so something can answer "what is the target's `color` right now?" in the
#     same vocabulary that wrote it. That answer is what a reverse edge is built out of, and what
#     lets a widget's exported value be a DECLARED pin rather than a duck-typed probe for a few
#     well-known method names. See archive/connector-ubiquity-and-reflection-plan.md G1.
#   • a pin can accept MORE THAN ONE kind, stated on the pin. One table per kind can only say it by
#     repetition -- the same pin appended to two or three tables, in two or three overrides.
#
# SHALLOWLY IMMUTABLE (docs/architecture/immutable-value-classes.md): fields are never written after
# construction, and the strings are inert.
#
# ⚠ `setterName` / `getterName` hold METHOD NAMES, not functions. That is deliberate and it is the
# same late binding the wires already use: a wire stores its `@action` as the setter's name and the
# engine dispatches it by name (DataflowEngine._applyWireValue, which also prefers a
# `_<action>Connector` lane when the target defines one). Names survive serialization and
# duplication; function references would not. Read a pin with `node[pin.getterName]?()`.
# (The plan's sketch called these `set`/`get`; they are spelled out here so that `pin.get()` --
# a call, on a field that is a string -- cannot be written by accident.)
#
# CONSTRUCTOR SHAPE (docs/architecture/constructor-and-parameter-conventions.md): `label` and `kind`
# are the identity -- every pin has both, every call site passes both -- so they stay positional.
# `set` and `get` are INDEPENDENTLY optional (see the two asymmetries below), so they ride `opts`:
# either alone must be expressible without a hole.
#
# THE TWO ASYMMETRIES ARE DECLARED, NOT FAKED:
#   • no `get` => a WRITE-ONLY pin. It can be driven and can never be bound two-way. `bang` is the
#     canonical one (it has no value to read), and it is also what most of Widget's own pins are
#     today -- their fields are readable, but no reader METHOD exists and inventing one here would
#     be fabricating a contract nothing implements.
#   • no `set` => a READ-ONLY pin. It never appears in a "choose target property" menu, because
#     nothing can drive it. StringFieldWdgt's `value` is the canonical one: it holds its string in
#     a child StringWdgt, so `getValue` reaches through the child and there is simply no one-call
#     setter twin to pair it with. The arrays could not express this at all.
#
# A pin with NEITHER is meaningless and is refused at construction rather than silently ignored.
#
# THE THIRD FACT: `announces`. Reading a pin answers "what is it NOW"; announcing is the promise that
# whoever cares will be TOLD when it changes, whatever moved it — a gesture, a script, the loader,
# another widget's method call. The two are independent, and only the pair makes a control that
# FOLLOWS this pin possible: without a reader there is nothing to re-read, and without the
# announcement the re-read never happens and the follower goes quietly stale.
#   It is declared rather than derived because it is a fact about the WIDGET's write paths — every
# one of them — and no analysis of this record can see them. Default false: a pin that says nothing
# promises nothing, so a follower is never offered a relationship whose reverse half is dead. That
# default is the whole reason the flag exists (connector plan §P2: "a pin-to-pin gesture could offer
# binds whose reverse half silently never fires").
#   ⚠ It is NOT what `bind ⇄` consults. A bind at NODE granularity is two ordinary wires and its
# reverse half fires from `updateTarget`; `announces` is the PIN-granularity precondition, read by
# ControllerMixin.canTrackWire. The two granularities keep their own machinery (§P2's table).

class PinSpec

  # what the "choose target property" menu row says
  label: undefined
  # the kinds of value this pin accepts, always an array; see acceptsKind
  kinds: undefined
  # name of the method that WRITES this pin (also a wire's `@action`); undefined => write-only
  setterName: undefined
  # name of the method that READS this pin; undefined => write-only
  getterName: undefined
  # does my widget tell the dataflow whenever this pin changes, by WHATEVER path? see the header
  announces: false

  # `kind` is a kind string, an array of them, or "any". "any" is not shorthand for "all the kinds
  # that exist today" -- it is a statement that the pin ignores the value's kind (a bang), so it
  # keeps matching kinds invented later.
  constructor: (@label, kind, opts = {}) ->
    @kinds = if Array.isArray kind then kind else [kind]
    @setterName = opts.set
    @getterName = opts.get
    # assigned only when asked for, so an ordinary pin carries no own property for it (WireSpec's
    # own-only-when-set idiom)
    @announces = opts.announces if opts.announces?
    if !@setterName? and !@getterName?
      throw new Error "PinSpec \"#{@label}\" declares neither a setter nor a getter"
    # a sound negative: announcing a pin nothing can READ promises to wake a re-reader that has
    # nothing to re-read. Refused at construction, like the neither-half case above, rather than
    # sitting there as a flag with no meaning.
    if @announces and !@getterName?
      throw new Error "PinSpec \"#{@label}\" declares `announces` but has no getter to re-read"

  # can a source of `kind` drive this pin? An undefined kind asks for no filtering at all (the
  # "every pin" query behind the old allSetters).
  acceptsKind: (kind) ->
    return true if !kind? or kind is "any"
    for acceptedKind in @kinds
      return true if acceptedKind is "any" or acceptedKind is kind
    return false

  # (the write-only case is read straight off `getterName` at its one consumer, Widget.exportedValue --
  # a matching isWriteOnly with no caller would be dead code, which the build gates on)
  isReadOnly: -> !@setterName?
