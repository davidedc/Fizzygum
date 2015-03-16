# Rectangles //////////////////////////////////////////////////////////

# REQUIRES DeepCopierMixin

class Rectangle

  @augmentWith DeepCopierMixin

  origin: null
  corner: null
  
  constructor: (left, top, right, bottom) ->
    
    @origin = new Point((left or 0), (top or 0))
    @corner = new Point((right or 0), (bottom or 0))
  
  
  # Rectangle string representation: e.g. '[0@0 | 160@80]'
  toString: ->
    "[" + @origin + " | " + @extent() + "]"
  
  # Rectangle copying:
  copy: ->
    new @constructor(@left(), @top(), @right(), @bottom())
  
  # Rectangle accessing - setting:
  setTo: (left, top, right, bottom) ->
    # note: all inputs are optional and can be omitted
    @origin = new Point(
      left or ((if (left is 0) then 0 else @left())),
      top or ((if (top is 0) then 0 else @top())))
    @corner = new Point(
      right or ((if (right is 0) then 0 else @right())),
      bottom or ((if (bottom is 0) then 0 else @bottom())))
  
  # Rectangle accessing - getting:
  area: ->
    #requires width() and height() to be defined
    w = @width()
    return 0  if w < 0
    Math.max w * @height(), 0
  
  bottom: ->
    @corner.y
  
  bottomCenter: ->
    new Point(@center().x, @bottom())
  
  bottomLeft: ->
    new Point(@origin.x, @corner.y)
  
  bottomRight: ->
    @corner.copy()
  
  boundingBox: ->
    @
  
  center: ->
    @origin.add @corner.subtract(@origin).floorDivideBy(2)
  
  corners: ->
    [@origin, @bottomLeft(), @corner, @topRight()]
  
  extent: ->
    @corner.subtract @origin
  
  isEmpty: ->
    # The subtract method creates a new Point
    theExtent = @corner.subtract @origin
    theExtent.x = 0 or theExtent.y = 0

  isNotEmpty: ->
    # The subtract method creates a new Point
    theExtent = @corner.subtract @origin
    theExtent.x > 0 and theExtent.y > 0
  
  height: ->
    @corner.y - @origin.y
  
  left: ->
    @origin.x
  
  leftCenter: ->
    new Point(@left(), @center().y)
  
  right: ->
    @corner.x
  
  rightCenter: ->
    new Point(@right(), @center().y)
  
  top: ->
    @origin.y
  
  topCenter: ->
    new Point(@center().x, @top())
  
  topLeft: ->
    @origin
  
  topRight: ->
    new Point(@corner.x, @origin.y)
  
  width: ->
    @corner.x - @origin.x
  
  position: ->
    @origin
  
  # Rectangle comparison:
  eq: (aRect) ->
    @origin.eq(aRect.origin) and @corner.eq(aRect.corner)
  
  abs: ->
    newOrigin = @origin.abs()
    newCorner = @corner.max(newOrigin)
    newOrigin.corner newCorner
  
  # Rectangle functions:
  insetBy: (delta) ->
    # delta can be either a Point or a Number
    result = new @constructor()
    result.origin = @origin.add(delta)
    result.corner = @corner.subtract(delta)
    result
  
  expandBy: (delta) ->
    # delta can be either a Point or a Number
    result = new @constructor()
    result.origin = @origin.subtract(delta)
    result.corner = @corner.add(delta)
    result
  
  growBy: (delta) ->
    # delta can be either a Point or a Number
    result = new @constructor()
    result.origin = @origin.copy()
    result.corner = @corner.add(delta)
    result
  
  intersect: (aRect) ->
    result = new @constructor()
    result.origin = @origin.max(aRect.origin)
    result.corner = @corner.min(aRect.corner)
    result
  
  merge: (aRect) ->
    result = new @constructor()
    result.origin = @origin.min(aRect.origin)
    result.corner = @corner.max(aRect.corner)
    result
  
  round: ->
    @origin.round().corner @corner.round()
  
  spread: ->
    # round me by applying floor() to my origin and ceil() to my corner
    @origin.floor().corner @corner.ceil()
  
  amountToTranslateWithin: (aRect) ->
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
    @origin.le(aPoint) and aPoint.lt(@corner)
  
  containsRectangle: (aRect) ->
    aRect.origin.gt(@origin) and aRect.corner.lt(@corner)
  
  intersects: (aRect) ->
    ro = aRect.origin
    rc = aRect.corner
    (rc.x >= @origin.x) and
      (rc.y >= @origin.y) and
      (ro.x <= @corner.x) and
      (ro.y <= @corner.y)
  
  
  # Rectangle transforming:
  scaleBy: (scale) ->
    # scale can be either a Point or a scalar
    o = @origin.multiplyBy(scale)
    c = @corner.multiplyBy(scale)
    new @constructor(o.x, o.y, c.x, c.y)
  
  translateBy: (factor) ->
    # factor can be either a Point or a scalar
    o = @origin.add(factor)
    c = @corner.add(factor)
    new @constructor(o.x, o.y, c.x, c.y)
  
  
  # Rectangle converting:
  asArray: ->
    [@left(), @top(), @right(), @bottom()]
  
  asArray_xywh: ->
    [@left(), @top(), @width(), @height()]
