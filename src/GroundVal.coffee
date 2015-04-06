# just a draft, it's not meant to compile or work
# just yet, we are just assembling things

# a GroundVal holds a val that is not
# calculated from anything: it's actually
# changeable as is. It doesn't react to the
# change of any other Val.

# REQUIRES ProfilerData

class GroundVal
  
  directlyOrIndirectlyDependsOnAParentVal: false

  # we use "lastCalculatedValContent" here just as a matter of
  # uniformity. The cached val of a GroundVal
  # is always up to date, it's always good for use.
  lastCalculatedValContent: null

  # always false for GroundVals, because there is never
  # a recalculation to be done here, the val is always
  # exactly known
  lastCalculatedValContentMaybeOutdated: false
  # these vals are affected by change of this
  # val
  localValsAffectedByChangeOfThisVal: null

  args: null

  constructor: (@valName, @lastCalculatedValContent, @ownerMorph) ->

    # stuff to do only if we are building GroundVal and not
    # any of its subclasses
    if @constructor.name == "GroundVal" and
        WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode

      ProfilerData.reactiveValues_createdGroundVals++

      if !@lastCalculatedValContent?
        contentOfLastCalculatedVal = null
      else
        contentOfLastCalculatedVal = @lastCalculatedValContent

      console.log "building GroundVal named " + @valName + " in morph "+ @ownerMorph.uniqueIDString() + " with content: " + contentOfLastCalculatedVal

    @addMyselfToMorphsValsList valName
    @id = @valName + @ownerMorph.uniqueIDString()
    @localValsAffectedByChangeOfThisVal = []


  checkAndPropagateChangeBasedOnArgChange: () ->
    if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
      console.log "checking if " + @valName + " in morph "+ @ownerMorph.uniqueIDString() + " has any damaged inputs..."

    # we can check these with a counter, DON'T do
    # something like Object.keys(obj).length because it's
    # unnecessary overhead.
    # Note here that there is no propagation in case:
    #  a) there is a change but we already notified our
    #     change to the connected vals
    #  b) there is no change and we never notified
    #     any change to the connected vals
    if @args.countOfDamaged > 0
      if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
        console.log "... " + @valName  + " in morph "+ @ownerMorph.uniqueIDString() + " has some damaged inputs but it's already broken so nothing to do"
      if @lastCalculatedValContentMaybeOutdated == false
        if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
          console.log "... " + @valName  + " in morph "+ @ownerMorph.uniqueIDString() + " has some damaged inputs and wasn't damaged so need to propagate damage"
        @lastCalculatedValContentMaybeOutdated = true
        @notifyDependentParentOrLocalValsOfPotentialChange()
    else # there are NO damaged args
      if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
        console.log "... " + @valName  + " in morph "+ @ownerMorph.uniqueIDString() + " has NO damaged inputs"
      @heal()


  heal: ->
    if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
      console.log "... now healing " + @id

    if @lastCalculatedValContentMaybeOutdated
      if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
        console.log "... " + @id + "'s last calculated value was marked as broken, notifying dep values of this being healed"
      @lastCalculatedValContentMaybeOutdated = false
      @notifyDependentParentOrLocalValsOfPotentialChange()


  addMyselfToMorphsValsList: (valName) ->
    @ownerMorph.allValsInMorphByName[valName] = @

  stainValCalculatedFromParent: (stainingArgVal) ->
    # note that staining argument here could
    # be a child argument, as it might directly or
    # indirectly depend on
    # a value which is in a parent
    stainingArg = @args.getByVal stainingArgVal
    # this might recursively stain other values
    # depending on this value
    stainingArg.turnIntoArgDirectlyOrIndirectlyDependingOnParent()

  unstainValCalculatedFromParent: (unstainedArgVal) ->
    # note that argument here could
    # be a child argument, as it might directly or
    # indirectly depend on
    # a value which is in a parent
    unstainedArg = @args.getByVal unstainedArgVal
    # this might recursively un-stain other values
    # depending on this value
    unstainedArg.turnIntoArgNotDirectlyNorIndirectlyDependingOnParent()


  # this is the only type of val that we
  # can actually change directly.
  # All other typed of vals are calculated
  # from other vals.
  setVal: (newVal) ->
    @signature = newVal.signature

    # comparison needs to be smarter?
    # does this need to have multiple version for basic vals
    # like integers and strings?
    if @lastCalculatedValContent == newVal
      return
    else
      @lastCalculatedValContent = newVal
      @notifyDependentParentOrLocalValsOfPotentialChange()
  
  # note that parents never notify children
  # of any change, because we don't want this
  # operation to take long as there might be hundreds
  # of children directly/indirectly under this morph.
  notifyDependentParentOrLocalValsOfPotentialChange: ->
    for cv in @localValsAffectedByChangeOfThisVal
      cv.argMightHaveChanged @
    if @ownerMorph.parent?
      v = @ownerMorph.parent.morphValsDependingOnChildrenVals[@valName]
      for k of v
        #k.argFromChildMightHaveChanged @
        k.argMightHaveChanged @

  # no logic for recalculation needed
  # fetchVal is an apt name because it doesn't necessarily
  # recalculate the val (although it might need to) and it
  # doesn't just look it up either. It's some sort of retrieval.
  fetchVal: ->
    return @lastCalculatedValContent


