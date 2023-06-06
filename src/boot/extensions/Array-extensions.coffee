# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

Array::shallowCopy = ->
  @concat()

Array::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  # TODO id: DUPLICATED_CODE_IN_DEEPCOPY date: 6-Jun-2023

  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf @
  if haveIBeenCopiedAlready >= 0
    if doSerialize
      return "$" + haveIBeenCopiedAlready
    else
      return objectClones[haveIBeenCopiedAlready]

  positionInObjClonesArray = objOriginalsClonedAlready.length
  objOriginalsClonedAlready.push @
  cloneOfMe = []
  objectClones.push  cloneOfMe

  for i in [0... @.length]
    if !@[i]?
        cloneOfMe[i] = nil
    else if typeof @[i] == 'object'
      if !@[i].deepCopy?
        # this should never happen
        debugger
      cloneOfMe[i] = @[i].deepCopy doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure
    else
      cloneOfMe[i] = @[i]

  if doSerialize
    return "$" + positionInObjClonesArray

  return cloneOfMe

Array::chunk = (chunkSize) ->
  array = this
  [].concat.apply [], array.map (elem, i) ->
    if i % chunkSize then [] else [ array.slice(i, i + chunkSize) ]

# removes the elements IN PLACE, i.e. the
# array IS modified
# Also note that the array changes length, so it
# can be messy to use while iterating on it
Array::remove = (theElement) ->
  index = @indexOf theElement
  if index isnt -1
    @splice index, 1
  return @

# de-duplicates array entries
# does NOT modify array in place
Array::unique = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

# de-duplicates array entries
# keeping the current order
# see https://stackoverflow.com/a/14438954
# does NOT modify array in place
uniqueKeepOrder = (value, index, self) ->
  self.indexOf(value) == index

Array::uniqueKeepOrder = ->
  return @filter uniqueKeepOrder
