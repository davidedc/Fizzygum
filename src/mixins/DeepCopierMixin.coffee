# //////////////////////////////////////////////////////////

DeepCopierMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      # Note 1: we deep-copy all kinds of data structures, not just widgets
      # Note 2: the entire copying mechanism
      # should also take care of inserting the copied
      # widget in whatever other data structures where the
      # original widget was.
      # For example, if the widget appeared in a data
      # structure related to the broken rectangles mechanism,
      # we should place the copied widget there.
      deepCopy: (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure)->
        # TODO id: DUPLICATED_CODE_IN_DEEPCOPY date: 6-Jun-2023

        haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf @
        if haveIBeenCopiedAlready >= 0
          if doSerialize
            return "$" + haveIBeenCopiedAlready
          else
            return objectClones[haveIBeenCopiedAlready]
        if (@ instanceof Widget) and (@ not in allMorphsInStructure)
          if doSerialize
            return "$EXTERNAL" + @uniqueIDString()
          else
            return @
     
        positionInObjClonesArray = objOriginalsClonedAlready.length

        # note that for immutable objects, in the non-serialisation case,
        # we actually don't create a copy, we just use the same object
        cloneOfMe = @getEmptyObjectOfSameTypeAsThisOne doSerialize

        # this is the only place where we add to these arrays.
        # Note that we know for sure that @ is NOT already in objOriginalsClonedAlready
        # (because we do the check at the top of this function)
        # and also we know that cloneOfMe is NOT in objectClones either
        # (because we only do these two adds in together)
        objOriginalsClonedAlready.push @
        objectClones.push cloneOfMe

        # cloneOfMe at this point is just an "empty shell" copy

        @recursivelyCloneContent cloneOfMe, doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure

        # cloneOfMe at this point is a full deep copy

        if doSerialize
          return "$" + positionInObjClonesArray

        # see comment in the method
        cloneOfMe.rebuildDerivedValues @

        # TODO these following alignment methods should have a uniform
        # naming convention.

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

        # if we deep-copied a morph, check whether the original
        # was in the data structure that keeps track of the
        # widgets that reference other widgets,
        # and if so, add the copy there too.
        # (since we deep-copy all kinds of data structures,
        # not just morphs, check if we have the relevant alignment
        # method to invoke).
        if @alignCopiedMorphToReferenceTracker?
          @alignCopiedMorphToReferenceTracker cloneOfMe

        # if we deep-copied a morph, check whether the original
        # was in the data structure that keeps track of the
        # widgets that want to receive keyboard events,
        # and if so, add the copy there too.
        # (since we deep-copy all kinds of data structures,
        # not just morphs, check if we have the relevant alignment
        # method to invoke).
        if @alignCopiedMorphToKeyboardEventsReceiversSet?
          @alignCopiedMorphToKeyboardEventsReceiversSet cloneOfMe


        # last chance for a morph to do other
        # cleanup, for example a button that is
        # highlighted might want to un-highlight
        # itself
        cloneOfMe.justBeenCopied?()

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

      recursivelyCloneContent: (cloneOfMe, doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure)->
        # these are all the properties that are NOT static
        # AND that are "attached" to the object.
        # Which means basically inherited and non-inherited, non-static properties that
        # have been re-assigned (Javascript runtime has a copy-on-write mechanism when you
        # change the properties of an object).
        # https://coffeescript.org/#try:class%20ColorExtended%0A%20%20%40extendedStatic%3A%204%0A%20%20extendedNonStatic%3A%205%0A%0A%0Aclass%20Color%20extends%20ColorExtended%0A%20%20%40aStatic%3A%202%0A%20%20nonStatic%3A%202%0A%20%20%0A%0AColor.aStatic%20%3D%2010%0AmyColor%20%3D%20new%20Color%0AmyColor.extendedNonStatic%20%3D%209%0A%0Afor%20property%20of%20myColor%0A%20%20alert%20property%20%2B%20%22%20%22%20%2B%20myColor.hasOwnProperty(property)
        for own property of @
          # also includes the "parent" property

          #if property == "backBufferContext"
          #  debugger

          if !@[property]?
            # undefined, null, nil
            cloneOfMe[property] = nil
          else if typeof @[property] == 'object'
            # if the value can be rebuilt after the cloning
            # then skip it, otherwise clone it. We know when
            # that's the case because the object also has a
            # rebuildDerivedValue method to be used to
            # rebuild it
            if @[property].rebuildDerivedValue?
              cloneOfMe[property] = nil
            else
              if !@[property].deepCopy?
                console.dir @
                console.log property
                debugger
              cloneOfMe[property] = @[property].deepCopy doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure
          else
            # boolean, number, bigint, string, symbol and function
            if property != "instanceNumericID"
              cloneOfMe[property] = @[property]


      # creates a new instance of target's type
      # note that
      #   1) the constructor method is not run!
      #   2) debuggers would show these instances as "Object"
      #      even though their prototype is actually of
      #      the type you wanted, so all is good there
      #   3) this new object is not a copy
      #      of the original object. It just has the
      #      same type. The properties are not copied.
      # This is never run on Arrays because they
      # override deepCopy altogether
      getEmptyObjectOfSameTypeAsThisOne: (doSerialize)->
        #alert "cloning a " + @constructor.name
        if typeof @ is "object"
          theClone = Object.create(@constructor::)
          # add to the instances tracking.
          # note that only Widgets have that kind
          # of tracking
          theClone.registerThisInstance?()
          if doSerialize
            # add a className field if object is not an array
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
