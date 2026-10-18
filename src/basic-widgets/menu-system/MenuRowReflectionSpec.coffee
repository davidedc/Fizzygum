# What a menu row SHOWS about somebody else's state — the declaration that makes a row a VIEW of a
# value rather than a mark painted once at menu-build time: the row is TICKED exactly while that
# value is the row's choice.
#
# A row that ticks itself (the current wallpaper, the current font) is showing state it does not
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
# plain collaborator, and a wire row's source is its `WireSpec` record), which is the whole point —
# this reflects a VALUE, and the dataflow node protocol is duck-typed.
#
# CONSTRUCTOR SHAPE (docs/architecture/constructor-and-parameter-conventions.md): `source` and
# `readerName` are the identity — WHOSE state and HOW to read it — so they stay positional; the
# value and the label ride `opts`. Callers use the `tickWhen` door below.

class MenuRowReflectionSpec

  # the object whose state this row shows
  source: undefined
  # name of the method on `source` that answers the current value
  readerName: undefined
  # the value that ticks the row
  whenValue: undefined
  # what the row SAYS, ticked or not: its plain wording
  label: undefined

  constructor: (@source, @readerName, opts = {}) ->
    @whenValue = opts.whenValue
    @label = opts.label

  # THE ONE DOOR: one row per choice, ticked while that choice is the current one, saying theLabel.
  @tickWhen: (source, readerName, theValue, theLabel) ->
    new MenuRowReflectionSpec source, readerName,
      whenValue: theValue
      label: theLabel

  # is the row ticked RIGHT NOW
  isTicked: ->
    @source[@readerName]() is @whenValue
