# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

Image::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  # TODO id: DUPLICATED_CODE_IN_DEEPCOPY date: 6-Jun-2023 description:
  # Only two of the paragraphs below are specific to this class, the rest is
  # generic but, unfortunately, duplicated in other classes (search for the TODO ID).
  # Consider refactoring-out the common parts.

  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf(@)
  if  haveIBeenCopiedAlready >= 0
    if doSerialize
      return "$" + haveIBeenCopiedAlready
    else
      return objectClones[haveIBeenCopiedAlready]

  positionInObjClonesArray = objOriginalsClonedAlready.length
  objOriginalsClonedAlready.push @

  cloneOfMe = new Image()
  cloneOfMe.src = @src

  if doSerialize
    cloneOfMe = {}

  objectClones.push cloneOfMe

  if doSerialize
    # TODO id: SERIALISATION_FOR_CLASSES_THAT_TRIGGER_ONLOAD_CALLBACK_NOT_COMPLETE date: 6-Jun-2023
    cloneOfMe.className = "Image"
    cloneOfMe.src = @src
    return "$" + positionInObjClonesArray

  return cloneOfMe
