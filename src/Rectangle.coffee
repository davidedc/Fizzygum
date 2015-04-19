# Rectangles //////////////////////////////////////////////////////////

# REQUIRES DeepCopierMixin

class Rectangle
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

  origin: null
  corner: null
  
  constructor: (left, top, right, bottom) ->
    
    @origin = new Point((left or 0), (top or 0))
    @corner = new Point((right or 0), (bottom or 0))
  
  
  # Rectangle string representation: e.g. '[0@0 | 160@80]'
  toString: ->
    "[" + @origin + " | " + @extent() + "]"

  onlyContainingIntegers: ->
    if Math.floor(@origin.x) == @origin.x and
      Math.floor(@origin.y) == @origin.y and
      Math.floor(@corner.x) == @corner.x and
      Math.floor(@corner.y) == @corner.y
        return true
    else
      return false

  debugIfFloats: ->
    if !@onlyContainingIntegers()
      debugger

  prepareBeforeSerialization: ->
    @debugIfFloats()
    @className = @constructor.name
    @classVersion = "0.0.1"
    @serializerVersion = "0.0.1"
    for property of @
      if @[property]?
        if typeof @[property] == 'object'
          if !@[property].className?
            if @[property].prepareBeforeSerialization?
              @[property].prepareBeforeSerialization()
  
  # Rectangle copying:
  copy: ->
    @debugIfFloats()
    new @constructor(@left(), @top(), @right(), @bottom())
  
  # Rectangle accessing - setting:
  setTo: (left, top, right, bottom) ->
    @debugIfFloats()
    # note: all inputs are optional and can be omitted
    @origin = new Point(
      left or ((if (left is 0) then 0 else @left())),
      top or ((if (top is 0) then 0 else @top())))
    @corner = new Point(
      right or ((if (right is 0) then 0 else @right())),
      bottom or ((if (bottom is 0) then 0 else @bottom())))
  
  # Rectangle accessing - getting:
  area: ->
    @debugIfFloats()
    #requires width() and height() to be defined
    w = @width()
    return 0  if w < 0
    Math.max w * @height(), 0
  
  bottom: ->
    @debugIfFloats()
    @corner.y
  
  bottomCenter: ->
    @debugIfFloats()
    new Point(@center().x, @bottom())
  
  bottomLeft: ->
    @debugIfFloats()
    new Point(@origin.x, @corner.y)
  
  bottomRight: ->
    @debugIfFloats()
    @corner.copy()
  
  boundingBox: ->
    @debugIfFloats()
    @
  
  center: ->
    @debugIfFloats()
    @origin.add @corner.subtract(@origin).floorDivideBy(2)
  
  corners: ->
    @debugIfFloats()
    [@origin, @bottomLeft(), @corner, @topRight()]
  
  extent: ->
    @debugIfFloats()
    @corner.subtract @origin
  
  isEmpty: ->
    @debugIfFloats()
    # The subtract method creates a new Point
    theExtent = @corner.subtract @origin
    theExtent.x = 0 or theExtent.y = 0

  isNotEmpty: ->
    @debugIfFloats()
    # The subtract method creates a new Point
    theExtent = @corner.subtract @origin
    theExtent.x > 0 and theExtent.y > 0
  
  height: ->
    @debugIfFloats()
    @corner.y - @origin.y
  
  left: ->
    @debugIfFloats()
    @origin.x
  
  leftCenter: ->
    @debugIfFloats()
    new Point(@left(), @center().y)
  
  right: ->
    @debugIfFloats()
    @corner.x
  
  rightCenter: ->
    @debugIfFloats()
    new Point(@right(), @center().y)
  
  top: ->
    @debugIfFloats()
    @origin.y
  
  topCenter: ->
    @debugIfFloats()
    new Point(@center().x, @top())
  
  topLeft: ->
    @debugIfFloats()
    @origin
  
  topRight: ->
    @debugIfFloats()
    new Point(@corner.x, @origin.y)
  
  width: ->
    @debugIfFloats()
    @corner.x - @origin.x
  
  position: ->
    @debugIfFloats()
    @origin
  
  # Rectangle comparison:
  eq: (aRect) ->
    @debugIfFloats()
    @origin.eq(aRect.origin) and @corner.eq(aRect.corner)
  
  abs: ->
    @debugIfFloats()
    newOrigin = @origin.abs()
    newCorner = @corner.max(newOrigin)
    newOrigin.corner newCorner
  
  # Rectangle functions:
  insetBy: (delta) ->
    @debugIfFloats()
    # delta can be either a Point or a Number
    result = new @constructor()
    result.origin = @origin.add(delta)
    result.corner = @corner.subtract(delta)
    result.debugIfFloats()
    result
  
  expandBy: (delta) ->
    @debugIfFloats()
    # delta can be either a Point or a Number
    result = new @constructor()
    result.origin = @origin.subtract(delta)
    result.corner = @corner.add(delta)
    result.debugIfFloats()
    result
  
  growBy: (delta) ->
    @debugIfFloats()
    # delta can be either a Point or a Number
    result = new @constructor()
    result.origin = @origin.copy()
    result.corner = @corner.add(delta)
    result.debugIfFloats()
    result
  
  intersect: (aRect) ->
    @debugIfFloats()
    result = new @constructor()
    result.origin = @origin.max(aRect.origin)
    result.corner = @corner.min(aRect.corner)
    result.debugIfFloats()
    result
  
  merge: (aRect) ->
    @debugIfFloats()
    result = new @constructor()
    result.origin = @origin.min(aRect.origin)
    result.corner = @corner.max(aRect.corner)
    result.debugIfFloats()
    result
  
  round: ->
    @debugIfFloats()
    @origin.round().corner @corner.round()
  
  spread: ->
    @debugIfFloats()
    # round me by applying floor() to my origin and ceil() to my corner
    @origin.floor().corner @corner.ceil()
  
  amountToTranslateWithin: (aRect) ->
    @debugIfFloats()
    #
    #    Answer a Point, delta, such that self + delta is forced within
    #    aRectangle. when all of me cannot be made to fit, prefer to keep
    #    my topLeft inside. Taken from Squeak.
    #
    dx = aRect.right() - @right()  if @right() > aRect.right()
    dy = aRect.bottom() - @bottom()  if @bottom() > aRect.bottom()
    dx = aRect.left() - @left()  if (@left() + dx) < aRect.left()
    dy = aRect.top() - @top()  if (@top() + dy) < aRect.top()
    new Point(dx, dy)
  
  
  # Rectangle testing:
  containsPoint: (aPoint) ->
    @debugIfFloats()
    @origin.le(aPoint) and aPoint.lt(@corner)
  
  containsRectangle: (aRect) ->
    @debugIfFloats()
    aRect.origin.gt(@origin) and aRect.corner.lt(@corner)
  
  intersects: (aRect) ->
    @debugIfFloats()
    ro = aRect.origin
    rc = aRect.corner
    (rc.x >= @origin.x) and
      (rc.y >= @origin.y) and
      (ro.x <= @corner.x) and
      (ro.y <= @corner.y)
  
  
  # Rectangle transforming:
  scaleBy: (scale) ->
    @debugIfFloats()
    # scale can be either a Point or a scalar
    o = @origin.multiplyBy(scale)
    c = @corner.multiplyBy(scale)
    new @constructor(o.x, o.y, c.x, c.y)
  
  translateBy: (factor) ->
    @debugIfFloats()
    # factor can be either a Point or a scalar
    o = @origin.add(factor)
    c = @corner.add(factor)
    new @constructor(o.x, o.y, c.x, c.y)
  
  
  # Rectangle converting:
  asArray: ->
    @debugIfFloats()
    [@left(), @top(), @right(), @bottom()]
  
  asArray_xywh: ->
    @debugIfFloats()
    [@left(), @top(), @width(), @height()]
