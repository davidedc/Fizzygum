# Global Functions ////////////////////////////////////////////////////

nop = ->
  # do explicitly nothing
  null

noOpFunction = ->
  # returns the function that does nothing
  ->    
    # this is the function that does nothing
    null

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
  i = undefined
  size = list.length
  i = 0
  while i < size
    return list[i]  if predicate.call(null, list[i])
    i += 1
  null
isString = (target) ->
  typeof target is "string" or target instanceof String
isObject = (target) ->
  target isnt null and (typeof target is "object" or target instanceof Object)
radians = (degrees) ->
  degrees * Math.PI / 180
degrees = (radians) ->
  radians * 180 / Math.PI
fontHeight = (height) ->
  Math.max height, MorphicPreferences.minimumFontHeight
newCanvas = (extentPoint) ->
  
  # answer a new empty instance of Canvas, don't display anywhere
  canvas = undefined
  ext = undefined
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
  ctx = undefined
  maxX = undefined
  data = undefined
  x = undefined
  y = undefined
  canvas.width = size
  canvas.height = size
  ctx = canvas.getContext("2d")
  ctx.font = "1px serif"
  maxX = ctx.measureText(str).width
  ctx.fillStyle = "black"
  ctx.textBaseline = "bottom"
  ctx.fillText str, 0, size
  y = 0
  while y < size
    x = 0
    while x < maxX
      data = ctx.getImageData(x, y, 1, 1)
      return size - y + 1  if data.data[3] isnt 0
      x += 1
    y += 1
  0
getBlurredShadowSupport = ->
  
  # check for Chrome issue 90001
  # http://code.google.com/p/chromium/issues/detail?id=90001
  source = undefined
  target = undefined
  ctx = undefined
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
  pos = undefined
  offsetParent = undefined
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
clone = (target) ->
  
  # answer a new instance of target's type
  if typeof target is "object"
    Clone = ->

    Clone:: = target
    return new Clone()
  target
copy = (target) ->
  
  # answer a shallow copy of target
  value = undefined
  c = undefined
  property = undefined
  return target  if typeof target isnt "object"
  value = target.valueOf()
  return new target.constructor(value)  if target isnt value
  if target instanceof target.constructor and target.constructor isnt Object
    c = clone(target.constructor::)
    for property of target
      c[property] = target[property]  if target.hasOwnProperty(property)
  else
    c = {}
    for property of target
      c[property] = target[property]  unless c[property]
  c

getMinimumFontHeight = ->
  
  # answer the height of the smallest font renderable in pixels
  str = "I"
  size = 50
  canvas = document.createElement("canvas")
  ctx = undefined
  maxX = undefined
  data = undefined
  x = undefined
  y = undefined
  canvas.width = size
  canvas.height = size
  ctx = canvas.getContext("2d")
  ctx.font = "1px serif"
  maxX = ctx.measureText(str).width
  ctx.fillStyle = "black"
  ctx.textBaseline = "bottom"
  ctx.fillText str, 0, size
  y = 0
  while y < size
    x = 0
    while x < maxX
      data = ctx.getImageData(x, y, 1, 1)
      return size - y + 1  if data.data[3] isnt 0
      x += 1
    y += 1
  0


getBlurredShadowSupport = ->
  
  # check for Chrome issue 90001
  # http://code.google.com/p/chromium/issues/detail?id=90001
  source = undefined
  target = undefined
  ctx = undefined
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
  pos = undefined
  offsetParent = undefined
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
clone = (target) ->
  
  # answer a new instance of target's type
  if typeof target is "object"
    Clone = ->

    Clone:: = target
    return new Clone()
  target
copy = (target) ->
  
  # answer a shallow copy of target
  value = undefined
  c = undefined
  property = undefined
  return target  if typeof target isnt "object"
  value = target.valueOf()
  return new target.constructor(value)  if target isnt value
  if target instanceof target.constructor and target.constructor isnt Object
    c = clone(target.constructor::)
    for property of target
      c[property] = target[property]  if target.hasOwnProperty(property)
  else
    c = {}
    for property of target
      c[property] = target[property]  unless c[property]
  c
