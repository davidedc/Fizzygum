# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

HTMLCanvasElement::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf(@)
  if  haveIBeenCopiedAlready >= 0
    if doSerialize
      return "$" + haveIBeenCopiedAlready
    else
      return objectClones[haveIBeenCopiedAlready]

  positionInObjClonesArray = objOriginalsClonedAlready.length
  objOriginalsClonedAlready.push @
  # with and height here are not the morph's,
  # which would be in logical units and hence would need ceilPixelRatio
  # correction,
  # but in actual physical units i.e. the actual bugffer size
  cloneOfMe = newCanvas new Point @width, @height

  ctx = cloneOfMe.getContext "2d"
  ctx.drawImage @, 0, 0

  if doSerialize
    cloneOfMe = {}

  objectClones.push cloneOfMe

  if doSerialize
    cloneOfMe.className = "Canvas"
    cloneOfMe.width = @width
    cloneOfMe.height = @height
    cloneOfMe.data = @toDataURL()
    return "$" + positionInObjClonesArray


  return cloneOfMe
