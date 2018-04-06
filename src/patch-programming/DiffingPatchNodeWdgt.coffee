# REQUIRES ControllerMixin

class DiffingPatchNodeWdgt extends Widget

  @augmentWith ControllerMixin

  tempPromptEntryField: nil
  defaultContents: nil
  textMorph: nil

  output: nil

  input1: nil
  input2: nil

  # we need to keep track of which inputs are
  # connected becayse we wait for those to be
  # all updated before the node fires
  setInput1IsConnected: false
  setInput2IsConnected: false
  setInput1HotIsConnected: false
  setInput2HotConnected: false

  # to keep track of whether each input is
  # up-to-date or not
  input1connectionsCalculationToken: 314
  input2connectionsCalculationToken: 314

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
    @buildAndConnectChildren()
    @input1 = ""
    @input2 = ""

  colloquialName: ->
    "Diffing patch node"

  setInput1: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @input1connectionsCalculationToken then return else if !connectionsCalculationToken? then @input1connectionsCalculationToken = getRandomInt -20000, 20000 else @input1connectionsCalculationToken = connectionsCalculationToken
    @input1 = newvalue
    @updateTarget @input1connectionsCalculationToken

  setInput2: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @input2connectionsCalculationToken then return else if !connectionsCalculationToken? then @input2connectionsCalculationToken = getRandomInt -20000, 20000 else @input2connectionsCalculationToken = connectionsCalculationToken
    @input1 = newvalue
    @updateTarget @input2connectionsCalculationToken

  setInput1Hot: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
    @input1 = newvalue
    @updateTarget @connectionsCalculationToken, false, true

  setInput2Hot: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
    @input2 = newvalue
    @updateTarget @connectionsCalculationToken, false, true

  # the bang makes the node fire the current output value
  bang: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
    @updateTarget @connectionsCalculationToken, true

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    [menuEntriesStrings, functionNamesStrings] = theTarget.numericalSetters()
    menu = new MenuMorph @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuMorph @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()

  updateTarget: (tokenToCheckIfEqual, directFireViaBang, fireViaHotInput) ->
    debugger

    if !@setInput1IsConnected and
     !@setInput2IsConnected and
     !@setInput1HotIsConnected and
     !@setInput2HotIsConnected
      return

    okToFire = true
    if @setInput1IsConnected
      if @input1connectionsCalculationToken != tokenToCheckIfEqual
        okToFire = false
    if @setInput2IsConnected
      if @input2connectionsCalculationToken != tokenToCheckIfEqual
        okToFire = false

    # if we are firing via bang then we use
    # the existing output value, we don't
    # recalculate a new one
    if (okToFire or fireViaHotInput) and !directFireViaBang
      # note that we calculate an output value
      # even if this node has no target. This
      # is because the node might be visualising the
      # output in some other way.
      @doCalculation()

    # if all the connected inputs are fresh OR we
    # are firing via bang, then at this point we
    # are going to update the target with the output
    # value.
    if okToFire or fireViaHotInput or directFireViaBang      
      @fireOutputToTarget tokenToCheckIfEqual

    return    

  fireOutputToTarget: (calculationToken) ->
    # mark this node as fired.
    # if the update DOES come from the "bang!", then
    # @connectionsCalculationToken has already been updated
    # but we keep it simple and re-assign it here, not
    # worth complicating things with an additional check
    @connectionsCalculationToken = calculationToken

    if @action and @action != ""
      @target[@action].call @target, @output, nil, @connectionsCalculationToken

  reactToTargetConnection: ->
    # we generate a new calculation token, that's OK because
    # we are definitely not in the middle of the calculation here
    # but we might be starting a new chain of calculations
    @fireOutputToTarget getRandomInt -20000, 20000

  doCalculation: ->
    debugger
    @output = @formattedDiff @input1, @input2
    @textMorph.setText @output


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

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    if world.isIndexPage
      menu.addMenuItem "connect to ➜", true, @, "openTargetSelector", "connect to\nanother widget"
    else
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another morph\nwhose numerical property\n will be" + " controlled by this one"


  buildAndConnectChildren: ->
    debugger
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @tempPromptEntryField = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = new Color 255, 255, 255

    @textMorph = @tempPromptEntryField.textWdgt
    @textMorph.backgroundColor = new Color 0,0,0,0
    @textMorph.setFontName nil, nil, @textMorph.monoFontStack
    @textMorph.isEditable = true
    @textMorph.enableSelecting()

    @add @tempPromptEntryField


    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    super
    debugger

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    textHeight = @height() - 2 * @externalPadding
    textBottom = @top() + @externalPadding + textHeight

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @tempPromptEntryField.rawSetExtent new Point @width() - 2 * @externalPadding, textHeight



    trackChanges.pop()
    @fullChanged()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

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

