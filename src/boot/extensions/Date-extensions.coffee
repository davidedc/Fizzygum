# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

# cloning a date object, see: https://stackoverflow.com/a/1090817
Date::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf @
  if haveIBeenCopiedAlready >= 0
    if doSerialize
      return "$" + haveIBeenCopiedAlready
    else
      return objectClones[haveIBeenCopiedAlready]

  positionInObjClonesArray = objOriginalsClonedAlready.length
  objOriginalsClonedAlready.push @
  cloneOfMe = new Date @getTime()
  objectClones.push  cloneOfMe

  if doSerialize
    return "$" + positionInObjClonesArray

  return cloneOfMe
