# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

HTMLVideoElement::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  # TODO id: DUPLICATED_CODE_IN_DEEPCOPY date: 6-Jun-2023

  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf(@)
  if  haveIBeenCopiedAlready >= 0
    if doSerialize
      return "$" + haveIBeenCopiedAlready
    else
      return objectClones[haveIBeenCopiedAlready]

  positionInObjClonesArray = objOriginalsClonedAlready.length
  objOriginalsClonedAlready.push @

  cloneOfMe = document.createElement 'video'
  cloneOfMe.src = @src
  cloneOfMe.autoplay = @autoplay
  cloneOfMe.currentTime = @currentTime

  if doSerialize
    cloneOfMe = {}

  objectClones.push cloneOfMe

  if doSerialize
    # TODO id: SERIALISATION_FOR_CLASSES_THAT_TRIGGER_ONLOAD_CALLBACK_NOT_COMPLETE date: 6-Jun-2023 description:
    # if you deserialise this, you'll need to reattach the onload callback and make sure that the recipient of
    # the callback is in the right state to accept such "onload" callback and handle it (which currently it's
    # not the case).
    cloneOfMe.className = "Canvas"
    cloneOfMe.src = @src
    cloneOfMe.video.autoplay = @video.autoplay
    return "$" + positionInObjClonesArray

  return cloneOfMe
