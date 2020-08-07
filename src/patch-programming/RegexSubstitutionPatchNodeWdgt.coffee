# this file is excluded from the fizzygum homepage build

class RegexSubstitutionPatchNodeWdgt extends Widget

  @augmentWith ControllerMixin

  regexEntryField: nil
  defaultContents: nil
  textMorph: nil

  substitutionTextArea: nil
  substitutionTextAreaText: nil

  outputTextArea: nil
  outputTextAreaText: nil

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
  input1connectionsCalculationToken: 0
  input2connectionsCalculationToken: 0
  input3connectionsCalculationToken: 0
  input4connectionsCalculationToken: 0

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
    "Regex subst. patch node"

  setInput1: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @input1connectionsCalculationToken then return else if !connectionsCalculationToken? then @input1connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @input1connectionsCalculationToken = connectionsCalculationToken
    @input1 = newvalue
    @updateTarget @input1connectionsCalculationToken

  setInput2: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @input2connectionsCalculationToken then return else if !connectionsCalculationToken? then @input2connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @input2connectionsCalculationToken = connectionsCalculationToken
    @input2 = newvalue
    @updateTarget @input2connectionsCalculationToken

  setInput3: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @input3connectionsCalculationToken then return else if !connectionsCalculationToken? then @input3connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @input3connectionsCalculationToken = connectionsCalculationToken
    @input3 = newvalue
    @updateTarget @input3connectionsCalculationToken

  setInput4: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @input4connectionsCalculationToken then return else if !connectionsCalculationToken? then @input4connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @input4connectionsCalculationToken = connectionsCalculationToken
    @input4 = newvalue
    @updateTarget @input4connectionsCalculationToken

  # the bang makes the node fire the current output value
  bang: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken
    @updateTarget @connectionsCalculationToken, true

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    [menuEntriesStrings, functionNamesStrings] = theTarget.numericalSetters()
    menu = new MenuMorph @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuMorph @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()

  updateTarget: (connectionsCalculationToken, fireBecauseBang) ->
    if !@setInput1IsConnected and
     !@setInput2IsConnected and
     !@setInput3IsConnected and
     !@setInput4IsConnected
      return

    allConnectedInputsAreFresh = true
    if @setInput1IsConnected
      if @input1connectionsCalculationToken != connectionsCalculationToken
        allConnectedInputsAreFresh = false
    if @setInput2IsConnected
      if @input2connectionsCalculationToken != connectionsCalculationToken
        allConnectedInputsAreFresh = false
    if @setInput3IsConnected
      if @input3connectionsCalculationToken != connectionsCalculationToken
        allConnectedInputsAreFresh = false
    if @setInput4IsConnected
      if @input4connectionsCalculationToken != connectionsCalculationToken
        allConnectedInputsAreFresh = false

    # if we are firing via bang then we use
    # the existing output value, we don't
    # recalculate a new one
    if allConnectedInputsAreFresh and !fireBecauseBang
      # note that we calculate an output value
      # even if this node has no target. This
      # is because the node might be visualising the
      # output in some other way.
      @recalculateOutput()

    # if all the connected inputs are fresh OR we
    # are firing via bang, then at this point we
    # are going to update the target with the output
    # value.
    if allConnectedInputsAreFresh or fireBecauseBang      
      @fireOutputToTarget connectionsCalculationToken

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
    @fireOutputToTarget world.makeNewConnectionsCalculationToken()

  recalculateOutput: ->
    if @textMorph.text != ""

      # from: https://stackoverflow.com/a/22763959
      regParts = @textMorph.text.match(/^\/(.*?)\/([gim]*)$/)
      if regParts
        # the parsed pattern had delimiters and modifiers. handle them. 
        regexp = new RegExp(regParts[1], regParts[2])
      else
        # we got pattern string without delimiters
        regexp = new RegExp(@textMorph.text)

      @output = @input1.replace regexp, @substitutionTextAreaText.text
      @outputTextAreaText.setText @output


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
    if world.isIndexPage
      menu.addMenuItem "connect to ➜", true, @, "openTargetSelector", "connect to\nanother widget"
    else
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another morph\nwhose numerical property\n will be" + " controlled by this one"


  buildAndConnectChildren: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @regexEntryField = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @regexEntryField.disableDrops()
    @regexEntryField.contents.disableDrops()
    @regexEntryField.color = Color.WHITE
    @textMorph = @regexEntryField.textWdgt
    @textMorph.backgroundColor = Color.TRANSPARENT
    @textMorph.setFontName nil, nil, @textMorph.monoFontStack
    @textMorph.isEditable = true
    @textMorph.enableSelecting()
    @add @regexEntryField

    @substitutionTextArea = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @substitutionTextArea.disableDrops()
    @substitutionTextArea.contents.disableDrops()
    @substitutionTextArea.color = Color.WHITE
    @substitutionTextAreaText = @substitutionTextArea.textWdgt
    @substitutionTextAreaText.backgroundColor = Color.TRANSPARENT
    @substitutionTextAreaText.setFontName nil, nil, @substitutionTextAreaText.monoFontStack
    @substitutionTextAreaText.isEditable = true
    @substitutionTextAreaText.enableSelecting()
    @add @substitutionTextArea

    @outputTextArea = new SimplePlainTextScrollPanelWdgt @defaultContents, false, 5
    @outputTextArea.disableDrops()
    @outputTextArea.contents.disableDrops()
    @outputTextArea.color = Color.WHITE
    @outputTextAreaText = @outputTextArea.textWdgt
    @outputTextAreaText.backgroundColor = Color.TRANSPARENT
    @outputTextAreaText.setFontName nil, nil, @outputTextAreaText.monoFontStack
    @outputTextAreaText.isEditable = false
    @add @outputTextArea


    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts
    #  debugger

    if @isCollapsed()
      @layoutIsValid = true
      @notifyAllChildrenRecursivelyThatParentHasReLayouted()
      return

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

    availableHeight = @height() - 2 * @externalPadding - 2 * @internalPadding
    text1Height = Math.round(availableHeight * 1/4)
    text2Height = Math.round(availableHeight * 1/4)
    text3Height = Math.round(availableHeight * 2/4)

    if @regexEntryField.parent == @
      @regexEntryField.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding
      @regexEntryField.rawSetExtent new Point @width() - 2 * @externalPadding, text1Height

    if @substitutionTextArea.parent == @
      @substitutionTextArea.fullRawMoveTo new Point @left() + @externalPadding, @regexEntryField.bottom() + @internalPadding
      @substitutionTextArea.rawSetExtent new Point @width() - 2 * @externalPadding, text2Height

    if @outputTextArea.parent == @
      @outputTextArea.fullRawMoveTo new Point @left() + @externalPadding, @substitutionTextArea.bottom() + @internalPadding
      @outputTextArea.rawSetExtent new Point @width() - 2 * @externalPadding, text3Height


    trackChanges.pop()
    @fullChanged()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    super
    @layoutIsValid = true
    @notifyAllChildrenRecursivelyThatParentHasReLayouted()

