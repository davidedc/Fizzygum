# Map / Set deep-copy, parallel to Array::deepCopy (Array-extensions.coffee) — the graph copier
# (DeepCopierMixin) recurses into a property by calling its .deepCopy, and the JS keyed
# collections had none, so a widget holding a Map/Set could not be duplicated. The serializer
# already treats Map/Set as first-class ($Map/$Set records); this fills the matching gap on the
# duplication side. First real consumer: the spreadsheet's SheetModel (@cells is a Map keyed
# "A1"). Values are cloned via the same objOriginalsClonedAlready / objectClones identity
# bookkeeping as every other deepCopy, so shared references and cycles are preserved; a Map's
# KEYS are address strings (primitives), copied as-is.

Map::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf @
  if haveIBeenCopiedAlready >= 0
    return objectClones[haveIBeenCopiedAlready]

  objOriginalsClonedAlready.push @
  cloneOfMe = new Map
  objectClones.push cloneOfMe

  @forEach (value, key) ->
    if !value?
      cloneOfMe.set key, nil
    else if typeof value == 'object'
      if !value.deepCopy?
        # a value type the copier can't clone (should never happen for a well-formed structure)
        debugger
      cloneOfMe.set key, value.deepCopy objOriginalsClonedAlready, objectClones, allWidgetsInStructure
    else
      cloneOfMe.set key, value
  return cloneOfMe

Set::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf @
  if haveIBeenCopiedAlready >= 0
    return objectClones[haveIBeenCopiedAlready]

  objOriginalsClonedAlready.push @
  cloneOfMe = new Set
  objectClones.push cloneOfMe

  @forEach (value) ->
    if !value?
      cloneOfMe.add nil
    else if typeof value == 'object'
      if !value.deepCopy?
        debugger
      cloneOfMe.add value.deepCopy objOriginalsClonedAlready, objectClones, allWidgetsInStructure
    else
      cloneOfMe.add value
  return cloneOfMe
