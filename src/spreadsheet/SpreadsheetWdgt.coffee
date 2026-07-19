# The framed SPREADSHEET citizen (Frame-model plan §5.B, owner decision D2):
# a spreadsheet IS its window. A truly THIN FrameWdgt subclass over the naked
# grid (SimpleSpreadsheetWdgt -- the model owner / formula scope / keyboard
# receiver): the grid manages its own editing (no providesAmenitiesForEditing,
# so the frame shows no pencil -- parity with the plain-wrapped era), the
# window title comes from the kind name, close is the plain base flow, and
# the frame's representativeIcon dispatch reaches the grid unchanged.

class SpreadsheetWdgt extends FrameWdgt

  constructor: ->
    super new SimpleSpreadsheetWdgt

  colloquialName: ->
    "spreadsheet"

  # the kind names the window (identical text to the grid's own colloquialName,
  # so the title is byte-what the plain-wrapped era derived from the content)
  _titleForContents: (aWdgt) ->
    @colloquialName()

  # A citizen never falls back to the empty-window placeholder: losing the
  # payload rebuilds a FRESH grid. NOT during my own teardown (§5.B B3 case
  # law: constructing a fresh child inside the destroy-until-empty iteration
  # never terminates).
  _resetToDefaultContents: ->
    return if @_beingFullDestroyed
    @_destroyToolbarNoSettle()
    @contents = new SimpleSpreadsheetWdgt
    @_buildAndConnectChildrenNoSettle()
