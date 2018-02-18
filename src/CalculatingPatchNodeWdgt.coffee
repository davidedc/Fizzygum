# REQUIRES ControllerMixin

class CalculatingPatchNodeWdgt extends Widget

  @augmentWith ControllerMixin

  tempPromptEntryField: nil
  defaultContents: nil
  textMorph: nil

  output: nil

  input1: nil
  input2: nil
  input3: nil
  input4: nil

  # we need to keep track of which inputs are
  # connected becayse we wait for those to be
  # all updated before the node fires
  setInput1IsConnected: false
  setInput2IsConnected: false
  setInput3IsConnected: false
  setInput4IsConnected: false

  # to keep track of whether each input is
  # up-to-date or not
  input1connectionsCalculationToken: 314
  input2connectionsCalculationToken: 314
  input3connectionsCalculationToken: 314
  input4connectionsCalculationToken: 314

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

  colloquialName: ->
    "Calculating patch node"

  setInput1: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @input1connectionsCalculationToken then return else if !connectionsCalculationToken? then @input1connectionsCalculationToken = getRandomInt -20000, 20000 else @input1connectionsCalculationToken = connectionsCalculationToken
    @input1 = Number(newvalue)
    @updateTarget @input1connectionsCalculationToken

  setInput2: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @input2connectionsCalculationToken then return else if !connectionsCalculationToken? then @input2connectionsCalculationToken = getRandomInt -20000, 20000 else @input2connectionsCalculationToken = connectionsCalculationToken
    @input2 = Number(newvalue)
    @updateTarget @input2connectionsCalculationToken

  setInput3: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @input3connectionsCalculationToken then return else if !connectionsCalculationToken? then @input3connectionsCalculationToken = getRandomInt -20000, 20000 else @input3connectionsCalculationToken = connectionsCalculationToken
    @input3 = Number(newvalue)
    @updateTarget @input3connectionsCalculationToken

  setInput4: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !superCall and connectionsCalculationToken == @input4connectionsCalculationToken then return else if !connectionsCalculationToken? then @input4connectionsCalculationToken = getRandomInt -20000, 20000 else @input4connectionsCalculationToken = connectionsCalculationToken
    @input4 = Number(newvalue)
    @updateTarget @input4connectionsCalculationToken

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

  updateTarget: (tokenToCheckIfEqual, directFireViaBang) ->
    debugger

    if !@setInput1IsConnected and
     !@setInput2IsConnected and
     !@setInput3IsConnected and
     !@setInput4IsConnected
      return

    okToFire = true
    if @setInput1IsConnected
      if @input1connectionsCalculationToken != tokenToCheckIfEqual
        okToFire = false
    if @setInput2IsConnected
      if @input2connectionsCalculationToken != tokenToCheckIfEqual
        okToFire = false
    if @setInput3IsConnected
      if @input3connectionsCalculationToken != tokenToCheckIfEqual
        okToFire = false
    if @setInput4IsConnected
      if @input4connectionsCalculationToken != tokenToCheckIfEqual
        okToFire = false

    # if we are firing via bang then we use
    # the existing output value, we don't
    # recalculate a new one
    if okToFire and !directFireViaBang
      # note that we calculate an output value
      # even if this node has no target. This
      # is because the node might be visualising the
      # output in some other way.
      @doCalculation()

    # if all the connected inputs are fresh OR we
    # are firing via bang, then at this point we
    # are going to update the target with the output
    # value.
    if okToFire or directFireViaBang      
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
    if @textMorph.text != ""
      @evaluateString "@functionFromCompiledCode = " + @textMorph.text
      # now we have the user-defined function in @functionFromCompiledCode
      @output = @functionFromCompiledCode?.call world, @input1, @input2, @input3, @input4


  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "in1", "in2", "in3", "in4"
    functionNamesStrings.push "bang", "setInput1", "setInput2", "setInput3", "setInput4"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "in1", "in2", "in3", "in4"
    functionNamesStrings.push "bang", "setInput1", "setInput2", "setInput3", "setInput4"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "set target", true, @, "openTargetSelector", "select another morph\nwhose numerical property\nwill be " + "controlled by this one"


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

