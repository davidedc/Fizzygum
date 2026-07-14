# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

HTMLVideoElement::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  deepCopyWithIdentity @, objOriginalsClonedAlready, objectClones, =>
    cloneOfMe = document.createElement 'video'
    cloneOfMe.src = @src
    cloneOfMe.autoplay = @autoplay
    cloneOfMe.currentTime = @currentTime
    cloneOfMe
