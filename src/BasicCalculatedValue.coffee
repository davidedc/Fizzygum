# just a draft, it's not meant to compile or work
# just yet, we are just assembling things

class BasicCalculatedVal extends GroundVal
  # sometimes we know that the cached val
  # might be out of date but we don't want to
  # trigger a recalculation to actually check.
  # This is what this flag tracks.
  # Note that this flag has no meaning if this Val
  # is @directlyOrIndirectlyDependsOnAParentVal, as in that case
  # we always have to fetch the val rather than
  # hope to have a good cached version.
  lastCalculatedValContentMaybeOutdated: true
  lastCalculatedValContent: undefined
  # this is needed because during the recalculation step
  # we don't want to process the notifications that
  # we receive about our args changing, that
  # would be messy and wasteful.
  holdOffFromPropagatingChanges: false

  # this val might be referenced by parent Morph or
  # children Morphs dynamically so they way to find this
  # val might be through the name as a string
  constructor: (@valName, @functionToRecalculate, @localInputVals, parentArgsNames, childrenArgsNames, @ownerMorph) ->
    super(@valName, null, @ownerMorph)

    if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
      collectionOfChildrenValuesNames = ""
      for eachName in childrenArgsNames
        collectionOfChildrenValuesNames = collectionOfChildrenValuesNames + ", " + eachName
      console.log "building BasicCalculatedVal named " + @valName + " in morph "+ @ownerMorph.uniqueIDString() + " depending on children variables: " + collectionOfChildrenValuesNames
    
    # we don't mark immediately this value as
    # depending on parent, the reason is that there might be
    # no parent morph to this one, so in some circumstances
    # this value's content can actually just be treated as
    # a normal value that doesn't need to automatically
    # fetch values for some of its arguments, and which
    # notification of changes can actually be believed.
    # As soon as a parent Morph is added, then this doesn't
    # hold true anymore - this Value stops notifying the
    # other dependent values of changes because it doesn't
    # get the changes from the parent values itself...
    #@directlyOrIndirectlyDependsOnAParentVal = true

    @args = new Args(@)
    @args.setup_AddAllLocalArgVals @localInputVals
    @args.setup_AddAllParentArgNames parentArgsNames
    @args.setup_AddAllChildrenArgNames childrenArgsNames


  # Given that this Val if a pure function depending
  # on some args, we want to know at all times
  # whether the args change. If the don't, then we
  # know that there is no need to recalculate the present
  # val. So this method is used by all the args
  # of this val to notify whether they have changed
  # or not.
  # It's important to note that this method can be
  # called for two reasons:
  # 1) an arg has just been recalculated. Hence
  #    we know exactly its val
  # 2) an arg has just maybe changed because
  #    he knows that one of HIS args has changed
  #    but since we want to minimise recalculations we
  #    don't know what the new val is, just that
  #    maybe it has changed. 
  # There is one exception: all args
  # that depend on a parent val (directly or indirectly)
  # never notify anybody. This is because if a parent had
  # to notify all the directlty or indirectly connected
  # vals, in general it could be
  # very expensive, as for example there could be 50
  # children to notify (and they might to notify other
  # connected vals). What happens instead is that when
  # this val is calculated, all args that depend on
  # a parent (directly or indirectly) are
  # always re-fetched, we just
  # can't trust them to have notified us of their change...
  # this method never triggers a recalculation!
  # we could receive this because
  #   - a recalculation has happened down the line
  #     and we know the actual val of the
  #     changed arg
  #   - some invalidation has happened down the line
  #     and hence the arg *might* have changed
  #     but we don't know the actual val.
  # We just need to keep track of which args might
  # need recalculation and which ones are surely the
  # same as the version we used for our last calculation.
  #argMightHaveChanged: (changedArgVal) ->
  #
  #  if WorldMorph.preferencesAndSettings.printoutsReactiveValuesCode
  #    console.log "marking argument " + changedArgVal.valName + " connected to morph " + changedArgVal.ownerMorph.uniqueIDString() + " as \"might have changed\" "
  #
  #  changedArg = @args.argById[changedArgVal.id]
  #  if changedArg.markedForRemoval or @holdOffFromPropagatingChanges then return
  #  changedArg.checkBasedOnSignature()
  #  if !@directlyOrIndirectlyDependsOnAParentVal
  #    @checkAndPropagateChangeBasedOnArgChange()



  propagateChangeOfThisValIfNeeded: (newValContent) ->
    debugger
    if newValContent.signature == @lastCalculatedValContent.signature
      @heal()
    else # newValContent.signature != @lastCalculatedValContent.signature
      if @lastCalculatedValContentMaybeOutdated == false
        notifyDependentParentOrLocalValsOfPotentialChange()
        # note that @lastCalculatedValContentMaybeOutdated
        # remains false because we are sure of this value
        # as we just calculated

  # this method is called either by the user/system
  # because it's time to get the val, or it's
  # called by another val which is being asked to
  # return its val recursively.
  # this method could trigger a recalculation of some
  # args, and of this val itself (obviously
  # this whole apparatus is to minimise recalculations).
  # Even if this
  # particular function *might* be cheap to compute,
  # the "dirty" parameters of its input might not be cheap
  # to calculate.
  # fetchVal is an apt name because it doesn't necessarily
  # recalculate the val (although it might need to) and it
  # doesn't just look it up either. It's some sort of retrieval.
  fetchVal: () ->
    if @lastCalculatedValContentMaybeOutdated is false
      return @lastCalculatedValContent
    
    oneOrMoreArgsHaveActuallyChanged = false
    oneOrMoreArgsHaveActuallyChanged = oneOrMoreArgsHaveActuallyChanged or @args.fetchAllArgsDirectlyOrIndirectlyCalculatedFromParent()
    oneOrMoreArgsHaveActuallyChanged = oneOrMoreArgsHaveActuallyChanged or @args.fetchAllRemainingArgsNeedingRecalculation()

    if oneOrMoreArgsHaveActuallyChanged      
      # functionToRecalculate must always return
      # an object with a calculated default signature
      # in the .signature property
      newValContent =
        @functionToRecalculate \
          @args.argById,
          @args.localArgByName,
          @args.parentArgByName,
          @args.childrenArgByName,
          @args.childrenArgByNameCount

      @signature = newValContent.signature
      @lastCalculatedValContent = newValContent
      if !@directlyOrIndirectlyDependsOnAParentVal
        @propagateChangeOfThisValIfNeeded newValContent
    return @lastCalculatedValContent
      
    

