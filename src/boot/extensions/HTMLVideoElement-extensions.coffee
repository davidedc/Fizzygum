# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

HTMLVideoElement::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  # TODO id: DUPLICATED_CODE_IN_DEEPCOPY date: 6-Jun-2023

  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf(@)
  if  haveIBeenCopiedAlready >= 0
    return objectClones[haveIBeenCopiedAlready]

  objOriginalsClonedAlready.push @

  cloneOfMe = document.createElement 'video'
  cloneOfMe.src = @src
  cloneOfMe.autoplay = @autoplay
  cloneOfMe.currentTime = @currentTime

  objectClones.push cloneOfMe

  return cloneOfMe
