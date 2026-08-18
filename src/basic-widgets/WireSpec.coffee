# ONE WIRE of a controller: "I drive `action` on `target`", plus that wire's own policy.
#
# A controller owns a LIST of these (`@wires`, ControllerMixin), one record per relationship it
# drives. Gathering a wire's four facts into a record is what lets there be a SECOND one: the
# alternative is four loose fields on the controller — target, action, delivery policy, tracking flag
# — describing a single relationship in four places, with no slot for another and nothing to remove
# when un-wiring. That is gap G2 in plans/connector-ubiquity-and-reflection-plan.md (one out-edge
# ever, no un-wire idiom, fan-out only via the unshipped FanoutWdgt), and §P4 closes it here.
#
# WHY A CLASS AND NOT A BARE {target, action} LITERAL. The tree's own precedent is the layout-spec
# family (LayoutSpec and friends): one spec object per ATTACHMENT, living on the widget, serialized
# with it, carrying knobs. This is the same shape for a different kind of attachment. Being a class
# also buys the prototype-level defaults below, which is what keeps an untoggled wire serializing as
# just its target and action.
#
# ⚠ MUTABLE, deliberately — this is a spec with knobs, NOT an immutable value class
# (docs/architecture/immutable-value-classes.md, which governs Point / Color / PinSpec /
# MenuRowReflectionSpec). `firesPerEvent` is flipped in place by its menu row, exactly as a layout
# spec's knobs are. It follows that a wire is never shared between two controllers: a duplicated
# controller deep-copies its records, so toggling one copy's policy cannot reach the other's.
#
# ⚠ `action` holds a METHOD NAME, not a function — the same late binding PinSpec.setterName and
# MenuRowReflectionSpec.readerName use, and for the same reason: a name survives serialization and
# duplication where a closure would not. The engine dispatches it by name
# (DataflowEngine._applyWireValue).
#
# IT IS ALSO A DATAFLOW NODE, in the duck-typed sense the engine means (src/dataflow/CLAUDE.md): its
# "fires per event" menu row is a MenuRowReflectionSpec whose source is the wire itself, so flipping
# the policy anywhere re-ticks every open menu showing it. That needs nothing but a reader method and
# a markNonValueChange — the same zero-engine-change trick §P5 played for Wallpaper.
#
# CONSTRUCTOR SHAPE (docs/architecture/constructor-and-parameter-conventions.md): `target` and
# `action` are the identity — a wire without either is not a wire, and every call site passes both —
# so they stay positional. The two policies are independently optional and ride `opts`.

class WireSpec

  # the widget I drive
  target: undefined
  # name of the method on `target` that I drive — a pin's setterName
  action: undefined
  # per-wire delivery policy (dataflow spec §4/§8): false = pooled once per cycle, true = a
  # synchronous mini-pass per event. The PER-EVENT lane is still deferred; the flag rides the edge
  # record so the policy is stored against the day it lands.
  firesPerEvent: false
  # do I also FOLLOW what I drive? A tracking wire declares the opposite edge as well
  # (ControllerMixin._ensureTrackingEdges) — a scrollbar welded to its content.
  tracks: false

  # The policies are assigned only when asked for, so an ordinary wire carries neither as an own
  # property and serializes as target + action alone — the own-only-when-set idiom @target/@action
  # already followed, now one level down.
  constructor: (@target, @action, opts = {}) ->
    @firesPerEvent = opts.firesPerEvent if opts.firesPerEvent?
    @tracks = opts.tracks if opts.tracks?

  # Am I THIS relationship? The identity of a wire is the pair, which is what makes wiring the same
  # target+action twice a no-op instead of a duplicate edge, and what `unwireFrom` matches on.
  describes: (theTarget, theAction) ->
    @target is theTarget and @action is theAction

  # What the engine's edge record derives from me (DataflowEngine.ensureWireEdges). Stated here, once,
  # so the index and the wire cannot drift into disagreeing about what this wire is.
  edgeOpts: ->
    action: @action
    firesPerEvent: @firesPerEvent

  # what my "fires per event" menu row reads to decide whether it is ticked
  # (MenuRowReflectionSpec.readerName — the row's source is this wire)
  isFiringPerEvent: -> @firesPerEvent

  # the same, for my "follows it too" row: whether I also carry values BACK
  # (ControllerMixin.toggleTrackingOfWire)
  isTracking: -> @tracks

  # How a menu names me: the target as the connect menus name it, then the PIN's label rather than
  # the raw setter — "a Panel . color", not "a Panel . setColor". The user picked the pin by that
  # word, so it is the word that identifies the wire back to them; the setter name is the fallback
  # for a target that declares no matching pin (a hard-wired app circuit naming a plain method).
  describeConnection: ->
    targetName = (@target.toString().replace "Wdgt", "").slice 0, 50
    pinLabel = (@target.pinDrivenBy? @action)?.label ? @action
    targetName + " . " + pinLabel
