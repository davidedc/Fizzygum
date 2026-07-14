# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

# cloning a date object, see: https://stackoverflow.com/a/1090817
Date::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  deepCopyWithIdentity @, objOriginalsClonedAlready, objectClones, => new Date @getTime()
