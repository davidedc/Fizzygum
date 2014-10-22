# Args are the input based on which a val is calculated
# There are several pieces of "aggregate" information that
# we keep about args considered together e.g. whether
# any of them has changed since the last calculation of the
# Val, or which ones directly or indirectly depend on a Parent
# Val.
class Args
  # some accessors gere to get to the
  # actual arguments. You can get to all
  # of them by Id of the Value
  # or, in the care of an argument connected
  # to a parent morph, by the value name
  # (since there is only one Arg connected
  # to the parent for each value name, which is
  # not the case for children Args as
  # onviously you may have many children and hence
  # many arguments)
  argById: null
  parentArgByName: null
  childrenArgByName: null
  # we want to group together all children
  # values under the same name
  # so we keep this count separate
  # rather than counting navigating the keys
  childrenArgByNameCount: null
  localArgByName: null
  calculatedDirectlyOfIndirectlyFromParentById: null
  calculatedDirectlyOfIndirectlyFromParentByIdCount: 0

  countOfDamaged: 0
  morphContainingTheseArgs: null

  # just some flags to keep track of which
  # args might have changed. Again, we might
  # not know for sure because we don't necessarily
  # recalculate them
  argsMaybeChangedSinceLastCalculationById: null

  constructor: (@valContainingTheseArgs) ->
    @argById = {}
    @parentArgByName = {}
    @childrenArgByName = {}
    @childrenArgByNameCount = {}
    @localArgByName = {}
    @calculatedDirectlyOfIndirectlyFromParentById = {}
    @argsMaybeChangedSinceLastCalculationById = {}

    @morphContainingTheseArgs = @valContainingTheseArgs.ownerMorph


  ################################################
  #  breaking / healing
  ################################################

  healAll: () ->
    for eachArg of argsMaybeChangedSinceLastCalculationById
      eachArg.heal()


  ################################################
  #  accessors
  ################################################

  getByVal: (theVal) ->
    return @getById theVal.id

  ################################################
  #  setup methods - these are called in the
  #  constructors of each value to prepare
  #  for the arguments.
  ################################################

  # for local arguments, you can
  # actually create the arguments as they are static
  setup_AddAllLocalArgVals: (localInputVals) ->
    for each in localInputVals
      # connecting arguments that come from local values is
      # easier because those links are static, they are done
      # at construction time once and for all
      each.localValsAffectedByChangeOfThisVal.push @valContainingTheseArgs
      newArg = new Arg localInputVals, @valContainingTheseArgs
      newArg.fromLocal = true
      @localArgByName[localInputVals.valueName] = newArg

  # you can't create the actual arguments yet as these
  # arguments will be connected dynamically. we just prepare
  # some a structure in the morph so we'll be able
  # to connect the actual values in the morph's
  # childAdded and childRemoved methods
  setup_AddAllParentArgNames: (parentArgsNames) ->
    # ORIGINAL CODE:
    #for each var in parentArgsNames
    #  if !@ownerMorph.morphValsDirectlyDependingOnParentVals[each]?
    #    @ownerMorph.morphValsDirectlyDependingOnParentVals[each] = {}
    #  @ownerMorph.morphValsDirectlyDependingOnParentVals[each][@valName] = @

    for eachVar in parentArgsNames
      @morphContainingTheseArgs.morphValsDirectlyDependingOnParentVals[eachVar]?= {}
      @morphContainingTheseArgs.morphValsDirectlyDependingOnParentVals[eachVar][@valContainingTheseArgs.valName] = @valContainingTheseArgs

  # you can't create the actual arguments yet as these
  # arguments will be connected dynamically. we just prepare
  # some a structure in the morph so we'll be able
  # to connect the actual values in the morph's
  # childAdded and childRemoved methods
  setup_AddAllChildrenArgNames: (childrenArgsNames) ->
    #debugger
    for eachVar in childrenArgsNames
      @morphContainingTheseArgs.morphValsDependingOnChildrenVals[eachVar] ?= {}
      @morphContainingTheseArgs.morphValsDependingOnChildrenVals[eachVar][@valContainingTheseArgs.valName] = @valContainingTheseArgs

  ################################################
  #  argument connenction methods
  #  these are called when Morphs are moved
  #  around so we need to connect/disconnect
  #  the arguments of each value to/from the
  #  (new) parent/children
  ################################################

  # check whether you are reconnecting
  # an arg that was temporarily
  # disconnected
  tryToReconnectDisconnectedArgFirst: (parentOrChildVal) ->
    existingArg = @argById[parentOrChildVal.id]
    if existingArg?
      existingArg.markedForRemoval = false
      existingArg.valContainingThisArg.argMightHaveChanged(parentOrChildVal)
      return existingArg
    return null


  # connects a val depending on a children val to a child val.
  # This is called by childAdded on the new parent of the childMorph
  # that has just been added
  connectToChildVal: (valDependingOnChildrenVal, childVal) ->

    if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
      console.log "connecting " + valDependingOnChildrenVal.valName + " in morph "+ valDependingOnChildrenVal.ownerMorph.uniqueIDString() + " to receive input from " + childVal.valName + " in morph "+ childVal.ownerMorph.uniqueIDString()

    # check whether you are reconnecting
    # an arg that was temporarily
    # disconnected
    #if @morphContainingTheseArgs.constructor.name == "RectangleMorph"
    #  debugger
    argumentToBeConnected = @tryToReconnectDisconnectedArgFirst childVal
    argumentToBeConnected ?= new Arg childVal, valDependingOnChildrenVal
    argumentToBeConnected.fromChild = true
    @childrenArgByName[childVal.valName] ?= {}
    @childrenArgByName[childVal.valName][childVal.id] = argumentToBeConnected
    @childrenArgByNameCount[childVal.valName]?= 0
    @childrenArgByNameCount[childVal.valName]++
    if childVal.directlyOrIndirectlyDependsOnAParentVal
      @valContainingTheseArgs.stainValCalculatedFromParent(childVal)
    argumentToBeConnected.args.argFromChildMightHaveChanged childVal

  # connects a val depending on a parent val to a parent val.
  # This is called by childAdded on the childMorph that has just
  # been added
  connectToParentVal: (valDependingOnParentVal, parentVal) ->
    # check whether you are reconnecting
    # an arg that was temporarily
    # disconnected
    argumentToBeConnected = @tryToReconnectDisconnectedArgFirst childVal
    argumentToBeConnected ?= new Arg childVal, valDependingOnParentVal
    argumentToBeConnected.directlyCalculatedFromParent = true
    argumentToBeConnected.turnIntoArgDirectlyOrIndirectlyDependingOnParent()

  ################################################
  #  handling update of argument coming from
  #  other values
  ################################################

  argFromChildMightHaveChanged: (childValThatMightHaveChanged) ->

    if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
      console.log "marking child value " + childValThatMightHaveChanged.valName + " in morph "+ childValThatMightHaveChanged.ownerMorph.uniqueIDString() + " as \"might have changed\" "


    arg = @argById[childValThatMightHaveChanged.id]
    if  !arg?  or  @holdOffFromPropagatingChanges then return
    if arg.markedForRemoval then return
    # the unique identifier of a val is given by
    # its name as a string and the id of the Morph it belongs to
    if arg.maybeChangedSinceLastCalculation and childValThatMightHaveChanged.ownerMorph.parent == @morphContainingTheseArgs
      arg.checkBasedOnSignature()
    else if arg.maybeChangedSinceLastCalculation and childValThatMightHaveChanged.ownerMorph.parent != @morphContainingTheseArgs
      # argsMaybeChangedSinceLastCalculation contains kid and kid not child anymore
      arg.break()
    else if !arg.maybeChangedSinceLastCalculation and childValThatMightHaveChanged.ownerMorph.parent == @morphContainingTheseArgs
      # argsMaybeChangedSinceLastCalculation not contains kid and kid is now child
      # ???
      add the data structures and mark it as dirty and signature undefined
    else if !arg.maybeChangedSinceLastCalculation and childValThatMightHaveChanged.ownerMorph.parent != @morphContainingTheseArgs
      # argsMaybeChangedSinceLastCalculation not contains kid and not child
      # ???
      this should never happen
    if !@valContainingTheseArgs.directlyOrIndirectlyDependsOnAParentVal
      @valContainingTheseArgs.checkAndPropagateChangeBasedOnArgChange()

  ################################################
  #  fetching correct arguments values
  ################################################

  # all @calculatedDirectlyOfIndirectlyFromParentById
  # always need
  # to be fetched (maybe recalculated)
  # regardless of their dirty val
  # we then update the signature and heal them.
  # Note that some children args can be in this set
  # as children args can maybe depend directly
  # or indirectly from parent vals.
  fetchAllArgsDirectlyOrIndirectlyCalculatedFromParent: ->
    oneOrMoreArgsHaveActuallyChanged = false
    for idNotUsed, argCalculatedFromParent of @calculatedDirectlyOfIndirectlyFromParentById
      # check that the child/parent arg we are going to fetch
      # is still a in a child/parent relationship with
      # this morph. If not, this check will remove the
      # arg and just move on
      if argCalculatedFromParent.removeArgIfMarkedForRemoval()
        continue
      # note here that since in @argValsById we keep the
      # reference to the Val object, which is the one
      # we pass to the "functionToRecalculate", we
      # don't need to put the fetched val anywhere.
      argCalculatedFromParent.fetchVal()
      # updateSignatureAndHeal returns true if
      # the argument has actually changed since last
      # recalculation
      oneOrMoreArgsHaveActuallyChanged = oneOrMoreArgsHaveActuallyChanged or argCalculatedFromParent.updateSignatureAndHeal()
    return oneOrMoreArgsHaveActuallyChanged

  fetchAllRemainingArgsNeedingRecalculation: ->
    @holdOffFromPropagatingChanges = true

    oneOrMoreArgsHaveActuallyChanged = false
    for maybeModifiedArgId of @argsMaybeChangedSinceLastCalculationById
      maybeModifiedArg = @argById[maybeModifiedArgId]
      # check that the child arg we are going to fetch
      # is still a in a child relationship with
      # this morph. If not, this check will remove the
      # arg and just move on.
      if maybeModifiedArg.removeArgIfMarkedForRemoval()
        continue
      # note here that since in @argValsById we keep the
      # reference to the Val object, which is the one
      # we pass to the "functionToRecalculate", we
      # don't need to put the fetched val anywhere.

      if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
        console.log "fetching potentially changed input: " + maybeModifiedArg.id

      debugger
      maybeModifiedArg.fetchVal()
      # the argument has actually changed since last
      # recalculation
      oneOrMoreArgsHaveActuallyChanged = oneOrMoreArgsHaveActuallyChanged or maybeModifiedArg.updateSignature()
    return oneOrMoreArgsHaveActuallyChanged

    # since we calculated all the damaged args,
    # heal them all
    @args.healAll()
    @holdOffFromPropagatingChanges = false