# //////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions


DeepCopierMixin =
  # klass properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: ->
    @addInstanceProperties

      # Note 1: we deep-copy all kinds of data structures, not just morphs
      # Note 2: the entire copying mechanism
      # should also take care of inserting the copied
      # morph in whatever other data structures where the
      # original morph was.
      # For example, if the Morph appeared in a data
      # structure related to the broken rectangles mechanism,
      # we should place the copied morph there.
      deepCopy: (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure)->
        haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf @
        if haveIBeenCopiedAlready >= 0
          if doSerialize
            return "$" + haveIBeenCopiedAlready
          else
            return objectClones[haveIBeenCopiedAlready]
        if (@ instanceof Morph) and (@ not in allMorphsInStructure)
          if doSerialize
            return "$EXTERNAL" + @uniqueIDString()
          else
            return @
     
        positionInObjClonesArray = objOriginalsClonedAlready.length
        objOriginalsClonedAlready.push @
        cloneOfMe = @createPristineObjOfSameTypeAsThisOne doSerialize
        objectClones.push  cloneOfMe

        for property of @
          if property ==  "allValsInMorphByName" or property ==  "morphValsDependingOnChildrenVals" or property ==  "morphValsDirectlyDependingOnParentVals"
            continue

          # also includes the "parent" property
          if @hasOwnProperty property

            #if property == "backBufferContext"
            #  debugger
            if !@[property]?
              cloneOfMe[property] = null
            else if typeof @[property] == 'object'
              # if the value can be rebuilt after the cloning
              # then skip it, otherwise clone it. We know when
              # that's the case because the object also has a
              # rebuildDerivedValue method to be used to
              # rebuild it
              if @[property].rebuildDerivedValue?
                cloneOfMe[property] = null
              else
                if !@[property].deepCopy? then debugger
                cloneOfMe[property] = @[property].deepCopy doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure
            else
              if property != "instanceNumericID"
                cloneOfMe[property] = @[property]

        if doSerialize
          return "$" + positionInObjClonesArray

        # see comment in the method
        cloneOfMe.rebuildDerivedValues @

        # if we deep-copied a morph, check whether the original
        # was in data structures related to the broken rects
        # mechanism, and if so, add the copy there too.
        # (since we deep-copy all kinds of data structures,
        # not just morphs, check if we have the relevant alignment
        # method to invoke).
        if @alignCopiedMorphToBrokenInfoDataStructures?
          @alignCopiedMorphToBrokenInfoDataStructures cloneOfMe

        # if we deep-copied a morph, check whether the original
        # was in data structures related to stepping
        # mechanism, and if so, add the copy there too.
        # (since we deep-copy all kinds of data structures,
        # not just morphs, check if we have the relevant alignment
        # method to invoke).
        if @alignCopiedMorphToSteppingStructures?
          @alignCopiedMorphToSteppingStructures cloneOfMe



        return cloneOfMe

      # some variables such as canvas contexts
      # are not copied, as they are derived values
      # so we take care or fixing the temporaries here
      rebuildDerivedValues: (theOriginal)->
        for property of @
          # also includes the "parent" property
          if @hasOwnProperty property
            # OK so we look at the original value
            # and check whether it has a rebuildDerivedValue
            # method. If it does, we invoke that method,
            # which rebuilds the value and adds it
            # *to the clone* (which is the @)
            if theOriginal[property]?.rebuildDerivedValue?
              theOriginal[property].rebuildDerivedValue(@, property)

      # creates a new instance of target's type
      # note that
      #   1) the constructor method is not run!
      #   2) debuggers would show these instances as "Object"
      #      even though their prototype is actually of
      #      the type you wanted, so all is good there
      #   3) this new object is not a copy
      #      of the original object. It just has the
      #      same type.
      createPristineObjOfSameTypeAsThisOne: (addClassNameFieldIfObjectNotArray)->
        #alert "cloning a " + @constructor.name
        if typeof @ is "object"
          # note that this case ALSO handles arrays
          # since they test positive as typeof "object"
          theClone = Object.create(@constructor::)
          # add to the instances tracking
          if @constructor.klass?
            @constructor.klass.instances.push theClone
          if addClassNameFieldIfObjectNotArray
            theClone.className = @constructor.name
          #console.log "theClone class:" + theClone.constructor.name

          # although we don't run the constructor,
          # it's useful to at least initialise the
          # object with a different ID
          if theClone.assignUniqueID?
            theClone.assignUniqueID()
          return theClone
        else
          return @
