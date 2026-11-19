# What a menu row SHOWS about somebody else's state — the declaration that makes a row a VIEW of a
# value rather than a mark painted once at menu-build time: the row is TICKED exactly while that
# value is the row's choice.
#
# A row that ticks itself (the current wallpaper, the current font, a text's weight, slant, header
# line, mask, alignment and fitting) is showing state it does not
# own. Written by hand that is a redraw: each menu fixes up its OWN rows, at the moment it was
# clicked, by walking `rowsPanel.children` by INDEX — so a second open copy of the same menu
# disagrees, and so does one open across a change made by a script, the loader, or another menu.
# This record says instead: *my tick is a function of that object's value*, and each reflecting row
# re-reads it (MenuItemWdgt._applyRowReflectionConnector) whenever the value announces itself
# through the dataflow drain.
#   The tick is DRAWN (MenuItemWdgt's tick indicator), never typed into the label: the label is the
# row's plain wording, the same whether or not it is ticked.
#
# SHALLOWLY IMMUTABLE (docs/architecture/immutable-value-classes.md): the fields are never written
# after construction, though `source` references a live object.
#
# ⚠ `readerName` is a METHOD NAME on `source`, not a function — the same late binding a wire's
# `@action` uses, and for the same reasons: it survives serialization and duplication, where a
# closure would not. The source needs no `pins()` and need not even be a Widget (`Wallpaper` is a
# plain collaborator), which is the whole point — this reflects a VALUE, and the dataflow node
# protocol is duck-typed. A source holding several things answers for one of them by the
# `readerArguments` that name it (a wire row's source is its CONTROLLER, asked about the wire its
# (target, action) pair names): a row never holds a part of an outside widget, so a copied row still
# asks the real one.
#
# CONSTRUCTOR SHAPE (docs/architecture/constructor-and-parameter-conventions.md): `source` and
# `readerName` are the identity — WHOSE state and HOW to read it — so they stay positional; the
# value, the label, the announcer and the reader's arguments ride `opts`. Callers use the two doors
# below.
#
# TWO SLOTS, ONE RECORD SHAPE: a row's TICK (`tickWhen`, CommandSpec.reflection) and its ENABLEMENT
# (`enabledWhile`, CommandSpec.enablement) are each one of these -- one condition on somebody's
# state, re-read whenever it announces. They are two records, not one with two readers, because
# the two can be read from different sources and announced by different producers: a row can tick
# from one object's state and be enabled by a condition that some other producer announces.
# `announcer` names that producer when it is not the source.

class MenuRowReflectionSpec

  # the object whose state this row shows
  source: undefined
  # name of the method on `source` that answers the current value
  readerName: undefined
  # the value the condition holds at
  whenValue: undefined
  # what the row SAYS, ticked or not: its plain wording (a tick's record only)
  label: undefined
  # who announces a change of the value, when that is not `source` itself: the producer the row
  # subscribes to (MenuItemWdgt._subscribeToWhatIShow); undefined means the source
  announcer: undefined
  # what the reader is asked WITH, when it answers for one of several things the source holds (a
  # controller's wire, named by its (target, action) pair: ControllerWdgt.isWireFiringPerEvent); own
  # only when given. A widget and a string, never a part of the source: a copied row then still asks
  # the source about the same thing, rather than holding a cloned part of it.
  readerArguments: undefined

  constructor: (@source, @readerName, opts = {}) ->
    @whenValue = opts.whenValue
    @label = opts.label
    @announcer = opts.announcedBy  if opts.announcedBy?
    @readerArguments = opts.readerArguments if opts.readerArguments?

  # THE TICK'S DOOR: one row per choice, ticked while that choice is the current one, saying theLabel;
  # opts.readerArguments, when the source's reader answers for one of several things it holds.
  @tickWhen: (source, readerName, theValue, theLabel, opts = {}) ->
    new MenuRowReflectionSpec source, readerName,
      whenValue: theValue
      label: theLabel
      readerArguments: opts.readerArguments

  # THE ENABLEMENT'S DOOR: the row is ENABLED exactly while `source[readerName]()` is theValue, and
  # disabled (greyed, refusing its press) otherwise. `opts.announcedBy` names who announces the value
  # when the source cannot.
  @enabledWhile: (source, readerName, theValue, opts = {}) ->
    new MenuRowReflectionSpec source, readerName,
      whenValue: theValue
      announcedBy: opts.announcedBy

  # does the condition hold RIGHT NOW -- for a tick, the row is ticked; for an enablement, enabled
  holds: ->
    # `? []`: a splat of undefined throws
    @source[@readerName]((@readerArguments ? [])...) is @whenValue
