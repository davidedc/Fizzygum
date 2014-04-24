# Global Functions ////////////////////////////////////////////////////

# This is used for testing purposes, we hash the
# data URL of a canvas object so to get a fingerprint
# of the image data, and compare it with "OK" pre-recorded
# values.
# adapted from http://werxltd.com/wp/2010/05/13/javascript-implementation-of-javas-string-hashcode-method/

hashCode = (stringToBeHashed) ->
  hash = 0
  return hash  if stringToBeHashed.length is 0
  for i in [0...stringToBeHashed.length]
    char = stringToBeHashed.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash # Convert to 32bit integer
  hash

# returns the function that does nothing
nop = ->
  # this is the function that does nothing:
  ->
    null

noOperation = ->
    null

isFunction = (functionToCheck) ->
  typeof(functionToCheck) is "function"

localize = (string) ->
  # override this function with custom localizations
  string

isNil = (thing) ->
  thing is `undefined` or thing is null

contains = (list, element) ->
  # answer true if element is a member of list
  list.some (any) ->
    any is element

detect = (list, predicate) ->
  # answer the first element of list for which predicate evaluates
  # true, otherwise answer null
  for element in list
    return element  if predicate.call(null, element)
  null

sizeOf = (object) ->
  # answer the number of own properties
  size = 0
  key = undefined
  for key of object
    size += 1  if Object.prototype.hasOwnProperty.call(object, key)
  size

isString = (target) ->
  typeof target is "string" or target instanceof String

isObject = (target) ->
  target? and (typeof target is "object" or target instanceof Object)

radians = (degrees) ->
  degrees * Math.PI / 180

degrees = (radians) ->
  radians * 180 / Math.PI

fontHeight = (height) ->
  minHeight = Math.max(height, WorldMorph.preferencesAndSettings.minimumFontHeight)
  minHeight * 1.2 # assuming 1/5 font size for ascenders

newCanvas = (extentPoint) ->
  # answer a new empty instance of Canvas, don't display anywhere
  ext = extentPoint or
    x: 0
    y: 0
  canvas = document.createElement("canvas")
  canvas.width = ext.x
  canvas.height = ext.y
  canvas

getMinimumFontHeight = ->
  # answer the height of the smallest font renderable in pixels
  str = "I"
  size = 50
  canvas = document.createElement("canvas")
  canvas.width = size
  canvas.height = size
  ctx = canvas.getContext("2d")
  ctx.font = "1px serif"
  maxX = ctx.measureText(str).width
  ctx.fillStyle = "black"
  ctx.textBaseline = "bottom"
  ctx.fillText str, 0, size
  for y in [0...size]
    for x in [0...maxX]
      data = ctx.getImageData(x, y, 1, 1)
      return size - y + 1  if data.data[3] isnt 0
  0


getBlurredShadowSupport = ->
  # check for Chrome issue 90001
  # http://code.google.com/p/chromium/issues/detail?id=90001
  source = document.createElement("canvas")
  source.width = 10
  source.height = 10
  ctx = source.getContext("2d")
  ctx.fillStyle = "rgb(255, 0, 0)"
  ctx.beginPath()
  ctx.arc 5, 5, 5, 0, Math.PI * 2, true
  ctx.closePath()
  ctx.fill()
  target = document.createElement("canvas")
  target.width = 10
  target.height = 10
  ctx = target.getContext("2d")
  ctx.shadowBlur = 10
  ctx.shadowColor = "rgba(0, 0, 255, 1)"
  ctx.drawImage source, 0, 0
  (if ctx.getImageData(0, 0, 1, 1).data[3] then true else false)

getDocumentPositionOf = (aDOMelement) ->
  # answer the absolute coordinates of a DOM element in the document
  if aDOMelement is null
    return (
      x: 0
      y: 0
    )
  pos =
    x: aDOMelement.offsetLeft
    y: aDOMelement.offsetTop

  offsetParent = aDOMelement.offsetParent
  while offsetParent isnt null
    pos.x += offsetParent.offsetLeft
    pos.y += offsetParent.offsetTop
    if offsetParent isnt document.body and offsetParent isnt document.documentElement
      pos.x -= offsetParent.scrollLeft
      pos.y -= offsetParent.scrollTop
    offsetParent = offsetParent.offsetParent
  pos


