# this file is excluded from the fizzygum homepage build

class DiffingPatchNodeWdgt extends PatchNodeWdgt

  # shared dataflow-node behaviour (dataflow protocol, connect-to-target menu, setter menus, _reLayout
  # scaffold, padding, and the input1/input2/output/textWidget preamble) lives on PatchNodeWdgt.

  tempPromptEntryField: nil
  defaultContents: nil

  # we need to keep track of which inputs are
  # connected because we wait for those to be
  # all updated before the node fires
  setInput1IsConnected: false
  setInput2IsConnected: false
  setInput1HotIsConnected: false
  setInput2HotConnected: false

  constructor: (@defaultContents = "") ->
    super new Point 200,400
    @_buildAndConnectChildren()
    @input1 = ""
    @input2 = ""

  colloquialName: ->
    "Diffing patch node"

  setInput1: (newvalue, ignored) ->
    @input1 = newvalue
    @updateTarget()

  setInput2: (newvalue, ignored) ->
    @input1 = newvalue
    @updateTarget()

  setInput1Hot: (newvalue, ignored) ->
    @input1 = newvalue
    @updateTarget()

  setInput2Hot: (newvalue, ignored) ->
    @input2 = newvalue
    @updateTarget()

  recalculateOutput: ->
    @output = @formattedDiff @input1, @input2
    @textWidget._setTextConnector @output

  # Diffing's inputs differ from the default in1..in4 (it has in1/in2 + hot inputs), so it overrides ONLY this
  # data hook; PatchNodeWdgt::stringSetters / numericalSetters (and their `super`-into-Widget chaining) stay
  # shared and unchanged.
  _inputSetterMenuEntries: ->
    [["bang!", "in1", "in2", "in1 hot", "in2 hot"], ["bang", "setInput1", "setInput2", "setInput1Hot", "setInput2Hot"]]

  _buildAndConnectChildrenNoSettle: ->

    @tempPromptEntryField = new SimpleTextScrollPanelWdgt @defaultContents, false, 5
    @tempPromptEntryField.configureAsMonoTextPanel true
    @textWidget = @tempPromptEntryField.textWdgt
    @_addNoSettle @tempPromptEntryField


    @_invalidateLayout()

  # subclass hook for PatchNodeWdgt::_reLayout — position my own children within the (already-applied) frame.
  _layOutNodeContents: ->

    textHeight = @height() - 2 * @externalPadding

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField._applyExtent new Point @width() - 2 * @externalPadding, textHeight

  # Simple Diff function
  # (C) Paul Butler 2008 <http://www.paulbutler.org/>
  # https://github.com/paulgb/simplediff/blob/master/coffeescript/simplediff.coffee
  diff: (before, after) ->
      # Find the differences between two lists. Returns a list of pairs, where the first value
      # is in ['+','-','='] and represents an insertion, deletion, or no change for that list.
      # The second value of the pair is the element.

      # Build a hash map with elements from before as keys, and
      # a list of indexes as values
      ohash = {}
      for val, i in before
          if val not of ohash
              ohash[val] = []
          ohash[val].push i

      # Find the largest substring common to before and after
      lastRow = (0 for i in [0 ... before.length])
      subStartBefore = subStartAfter = subLength = 0
      for val, j in after
          thisRow = (0 for i in [0 ... before.length])
          for k in ohash[val] ? []
              thisRow[k] = (if k and lastRow[k - 1] then 1 else 0) + 1
              if thisRow[k] > subLength
                  subLength = thisRow[k]
                  subStartBefore = k - subLength + 1
                  subStartAfter = j - subLength + 1
          lastRow = thisRow

      # If no common substring is found, assume that an insert and
      # delete has taken place
      if subLength == 0
          [].concat(
              (if before.length then [['-', before]] else []),
              (if after.length then [['+', after]] else []),
          )

      # Otherwise, the common substring is considered to have no change, and we recurse
      # on the text before and after the substring
      else
          [].concat(
              @diff(before[...subStartBefore], after[...subStartAfter]),
              [['=', after[subStartAfter...subStartAfter + subLength]]],
              @diff(before[subStartBefore + subLength...], after[subStartAfter + subLength...])
          )

  # The below functions are intended for simple tests and experimentation; you will want to write more sophisticated wrapper functions for real use

  stringDiff: (before, after) ->
      # Returns the difference between the before and after strings when split on whitespace. Considers punctuation a part of the word
      @diff(before.split(/[ ]+/), after.split(/[ ]+/))

  formattedDiff: (before, after) ->
      con =
          '=': ((x) -> x),
          '+': ((x) -> '+(' + x + ')'),
          '-': ((x) -> '-(' + x + ')')
      ((con[a])(b.join ' ') for [a, b] in @stringDiff(before, after)).join ' '
