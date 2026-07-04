# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

Image::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  # TODO id: DUPLICATED_CODE_IN_DEEPCOPY date: 6-Jun-2023 description:
  # Only two of the paragraphs below are specific to this class, the rest is
  # generic but, unfortunately, duplicated in other classes (search for the TODO ID).
  # Consider refactoring-out the common parts.

  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf(@)
  if  haveIBeenCopiedAlready >= 0
    return objectClones[haveIBeenCopiedAlready]

  objOriginalsClonedAlready.push @

  cloneOfMe = new Image()
  cloneOfMe.src = @src

  objectClones.push cloneOfMe

  return cloneOfMe
