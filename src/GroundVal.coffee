# just a draft, it's not meant to compile or work
# just yet, we are just assembling things

# a GroundVal holds a val that is not
# calculated from anything: it's actually
# changeable as is. It doesn't react to the
# change of any other Val.
class GroundVal
  
  directlyOrIndirectlyDependsOnAParentVal = false

  # we use "lastCalculatedValContent" here just as a matter of
  # uniformity. The cached val of a GroundVal
  # is always up to date, it's always good for use.
  lastCalculatedValContent = null

  # always false for GroundVals, because there is never
  # a recalculation to be done here, the val is always
  # exactly known
  lastCalculatedValContentMaybeOutdated = false
  # these vals are affected by change of this
  # val
  localValsAffectedByChangeOfThisVal = []

  constructor: (@valName, @lastCalculatedValContent, @ownerMorph) ->
    @addMyselfToMorphsValsList valName
    @id = @valName + @ownerMorph.id

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
    stainingArg.turnIntoArgNotDirectlyNorIndirectlyDependingOnParent()


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
      v = @ownerMorph.parent.valsDependingOnChildrenVal[@valName]
      for k in v
        k.argFromChildMightHaveChanged @

  # no logic for recalculation needed
  # fetchVal is an apt name because it doesn't necessarily
  # recalculate the val (although it might need to) and it
  # doesn't just look it up either. It's some sort of retrieval.
  fetchVal: ->
    return @lastCalculatedValContent


