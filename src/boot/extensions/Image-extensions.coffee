# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

Image::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  deepCopyWithIdentity @, objOriginalsClonedAlready, objectClones, =>
    cloneOfMe = new Image()
    cloneOfMe.src = @src
    cloneOfMe
