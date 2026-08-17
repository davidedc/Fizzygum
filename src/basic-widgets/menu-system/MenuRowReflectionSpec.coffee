# What a menu row SHOWS about somebody else's state — the declaration that makes a row a VIEW of a
# value rather than a label painted once at menu-build time.
#
# A row that ticks itself ("✓ circles") or swaps its wording ("touch screen settings" ⇄ "standard
# settings") is showing state it does not own. Written by hand that is a redraw: each menu fixes up
# its OWN rows, at the moment it was clicked, by walking `rowsPanel.children` by INDEX — so a second
# open copy of the same menu disagrees, and so does one open across a change made by a script, the
# loader, or another menu. This record says instead: *my label is a function of that object's value*,
# and one shared reconciliation (MenuRowsPanelWdgt.reconcileReflectedRows) runs whenever the value
# announces itself through the dataflow drain.
#
# SHALLOWLY IMMUTABLE (docs/architecture/immutable-value-classes.md): the fields are never written
# after construction, though `source` references a live object.
#
# ⚠ `readerName` is a METHOD NAME on `source`, not a function — the same late binding a wire's
# `@action` uses, and for the same reasons: it survives serialization and duplication, where a
# closure would not. The source needs no `pins()` and need not even be a Widget (`Wallpaper` and
# `PreferencesAndSettings` are plain collaborators), which is the whole point — this reflects a
# VALUE, and the dataflow node protocol is duck-typed.
#
# CONSTRUCTOR SHAPE (docs/architecture/constructor-and-parameter-conventions.md): `source` and
# `readerName` are the identity — WHOSE state and HOW to read it — so they stay positional; the
# value/label triple rides `opts`. Most callers want the `tickWhen` door below instead.

class MenuRowReflectionSpec

  # the object whose state this row shows
  source: undefined
  # name of the method on `source` that answers the current value
  readerName: undefined
  # the value that selects labelWhenTrue
  whenValue: undefined
  labelWhenTrue: undefined
  labelWhenFalse: undefined

  constructor: (@source, @readerName, opts = {}) ->
    @whenValue = opts.whenValue
    @labelWhenTrue = opts.labelWhenTrue
    @labelWhenFalse = opts.labelWhenFalse

  # THE COMMON CASE: one row per choice, ticked when that choice is the current one. Takes the bare
  # label and builds both spellings, so no caller repeats the tick/untick concatenation by hand.
  @tickWhen: (source, readerName, theValue, theLabel) ->
    new MenuRowReflectionSpec source, readerName,
      whenValue: theValue
      labelWhenTrue: tick + theLabel
      labelWhenFalse: untick + theLabel

  # what this row's label should say RIGHT NOW
  currentLabel: ->
    if @source[@readerName]() is @whenValue then @labelWhenTrue else @labelWhenFalse
