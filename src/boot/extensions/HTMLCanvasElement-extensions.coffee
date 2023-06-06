# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

HTMLCanvasElement::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  # TODO id: DUPLICATED_CODE_IN_DEEPCOPY date: 6-Jun-2023

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
  # but in actual physical units i.e. the actual buffer size
  cloneOfMe = HTMLCanvasElement.createOfPhysicalDimensions new Point @width, @height

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

# HTMLCanvasElement.createOfPhysicalDimensions takes physical size, i.e. actual buffer pixels.
# On non-retina displays, that's just the amount of logical pixels,
# which are used for all other measures of morphs.
# On retina displays, that's twice the amount of logical pixels.
# If the dimensions come from a canvas size, then those are
# already physical pixels.
# If the dimensions come form other measurements of the morphs,
# then those are in logical coordinates and need to be
# corrected with ceilPixelRatio before being passed here.
HTMLCanvasElement.createOfPhysicalDimensions = (extentPoint) ->
  extentPoint?.debugIfFloats()
  # answer a new empty instance of Canvas, don't display anywhere
  ext = extentPoint or
    x: 0
    y: 0
  canvas = document.createElement "canvas"
  canvas.width = Math.ceil ext.x
  canvas.height = Math.ceil  ext.y
  canvas


