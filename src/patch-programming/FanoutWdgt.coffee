# this file is excluded from the fizzygum homepage build

class FanoutWdgt extends Widget

  @augmentWith ControllerMixin

  pinUp: nil
  pinDown: nil
  pinLeft: nil
  pinRight: nil
  inputValue: nil

  constructor: (@color) ->
    super
    @appearance = new FanoutAppearance @

    @pinUp = new FanoutPinWdgt
    @pinDown = new FanoutPinWdgt
    @pinLeft = new FanoutPinWdgt
    @pinRight = new FanoutPinWdgt

    @add @pinUp
    @add @pinDown
    @add @pinLeft
    @add @pinRight

    @invalidateLayout()

  setInput: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken
    @inputValue = newvalue
    @updateTarget()

  updateTarget: ->
    for target in @children
      if target instanceof FanoutPinWdgt
        target.setInput @inputValue, nil, @connectionsCalculationToken
    return

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "input"
    functionNamesStrings.push "setInput"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "input"
    functionNamesStrings.push "setInput"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "input"
    functionNamesStrings.push "setInput"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  rawSetExtent: (aPoint) ->
    super
    @invalidateLayout()

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # TODO shouldn't be calling this rawSetBounds from here,
    # rather use super
    @rawSetBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    height = @height()
    width = @width()

    squareDim = Math.min width, height

     # p0 is the origin, the origin being in the bottom-left corner
    p0 = @topLeft()

    # now the origin is in the middle of the widget
    p0 = p0.add new Point width/2, height/2
    
    # now the origin is in the top left corner of the
    # square centered in the morph
    p0 = p0.subtract new Point squareDim/2, squareDim/2

    pinSize = (new Point 22 * squareDim/100, 22*squareDim/100).round()

    @pinUp.setExtent pinSize
    @pinDown.setExtent pinSize
    @pinLeft.setExtent pinSize
    @pinRight.setExtent pinSize

    @pinUp.fullRawMoveTo (p0.add new Point 39 * squareDim/100, 1 * squareDim/100).round()
    @pinDown.fullRawMoveTo (p0.add new Point 39 * squareDim/100, 77 * squareDim/100).round()
    @pinLeft.fullRawMoveTo (p0.add new Point 1 * squareDim/100, 39 * squareDim/100).round()
    @pinRight.fullRawMoveTo (p0.add new Point 77 * squareDim/100, 39 * squareDim/100).round()


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()