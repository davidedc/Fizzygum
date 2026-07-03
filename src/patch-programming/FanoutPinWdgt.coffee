# this file is excluded from the fizzygum homepage build

class FanoutPinWdgt extends Widget

  @augmentWith ControllerMixin

  inputValue: nil
  target: nil
  action: nil

  constructor: (@color) ->
    super
    @appearance = new FanoutPinAppearance @

  # Role query (replaces `x instanceof FanoutPinWdgt` filters): "am I a patch-graph connection pin?" --
  # a structural sub-part of a Fanout, not a standalone targetable widget. Used to exclude pins from the
  # target-chooser menu (Container/ControllerMixin) and to route fanout input to pin children (FanoutWdgt).
  # True here only; dispatched via ?() so nothing lands on Widget. (type-test-elimination campaign)
  isConnectionPin: ->
    true

  setInput: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    return unless @_acceptsConnectionToken connectionsCalculationToken, superCall
    @inputValue = newvalue
    @updateTarget()

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!"
    functionNamesStrings.push "bang"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!"
    functionNamesStrings.push "bang"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!"
    functionNamesStrings.push "bang"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings


  # the bang makes the node fire the current output value
  bang: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    return unless @_acceptsConnectionToken connectionsCalculationToken, superCall
    @updateTarget()


  updateTarget: ->
    @_fireConnection @inputValue
    return

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    if world.isIndexPage
      menu.addMenuItem "connect to ➜", true, @, "openTargetSelector", "connect to\nanother widget"
    else
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another widget\nwhose color property\n will be" + " controlled by this one"

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.allSetters()

  reactToTargetConnection: ->
    @parent.updateTarget()
