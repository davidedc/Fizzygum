# this file is excluded from the fizzygum homepage build

class DiffingPatchNodeWdgt extends Widget

  @augmentWith ControllerMixin

  tempPromptEntryField: nil
  defaultContents: nil
  textWidget: nil

  output: nil

  input1: nil
  input2: nil

  # we need to keep track of which inputs are
  # connected because we wait for those to be
  # all updated before the node fires
  setInput1IsConnected: false
  setInput2IsConnected: false
  setInput1HotIsConnected: false
  setInput2HotConnected: false

  # the external padding is the space between the edges
  # of the container and all of its internals. The reason
  # you often set this to zero is because windows already put
  # contents inside themselves with a little padding, so this
  # external padding is not needed. Useful to keep it
  # separate and know that it's working though.
  externalPadding: 0
  # the internal padding is the space between the internal
  # components. It doesn't necessarily need to be equal to the
  # external padding
  internalPadding: 5

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

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    @updateTarget true

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.numericalSetters()

  # any input change (or a bang) marks me STALE — the drain recomputes me via dataflowRecompute (pulling both
  # stored inputs) then delivers @output along my out-edge. This replaces the legacy freshness gate (the
  # allConnectedInputsAreFresh deadlock, spec §8); the "hot input" one-input-fires mode collapses into this
  # engine default (any input fires, all inputs pulled). A bang marks me forced.
  updateTarget: (fireBecauseBang) ->
    world.dataflow.markStale @, (fireBecauseBang is true)
    return

  fireOutputToTarget: ->
    @_fireConnection @output

  reactToTargetConnection: ->
    @fireOutputToTarget()

  recalculateOutput: ->
    @output = @formattedDiff @input1, @input2
    @textWidget._setTextConnector @output

  # ── dataflow node protocol (spec §8) ─────────────────────────────────────────────────────
  # A COMPUTING node: recompute = re-diff the stored inputs (recalculateOutput refreshes the on-node display too),
  # handing the engine the fresh @output; dataflowValue lets a consumer PULL @output and the cutoff compare it.
  dataflowRecompute: ->
    @recalculateOutput()
    @output

  dataflowValue: -> @output


  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "in1", "in2", "in1 hot", "in2 hot"
    functionNamesStrings.push "bang", "setInput1", "setInput2", "setInput1Hot", "setInput2Hot"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "in1", "in2", "in1 hot", "in2 hot"
    functionNamesStrings.push "bang", "setInput1", "setInput2", "setInput1Hot", "setInput2Hot"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    if world.isIndexPage
      menu.addMenuItem "connect to ➜", true, @, "openTargetSelector", "connect to\nanother widget"
    else
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another widget\nwhose numerical property\n will be" + " controlled by this one"
    @addFiresPerEventMenuEntry menu


  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = Color.WHITE

    @textWidget = @tempPromptEntryField.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget._setFontNameNoSettle nil, nil, @textWidget.monoFontStack
    @textWidget.isEditable = true
    @textWidget.enableSelecting()

    @_addNoSettle @tempPromptEntryField


    @_invalidateLayout()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    textHeight = @height() - 2 * @externalPadding

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField._applyExtent new Point @width() - 2 * @externalPadding, textHeight



    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

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

