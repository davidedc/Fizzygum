# Rectangles //////////////////////////////////////////////////////////

class Rectangle
  constructor: (left, top, right, bottom) ->
    @init new Point((left or 0), (top or 0)), new Point((right or 0), (bottom or 0))

Rectangle::init = (originPoint, cornerPoint) ->
  @origin = originPoint
  @corner = cornerPoint


# Rectangle string representation: e.g. '[0@0 | 160@80]'
Rectangle::toString = ->
  "[" + @origin.toString() + " | " + @extent().toString() + "]"

# Rectangle copying:
Rectangle::copy = ->
  new Rectangle(@left(), @top(), @right(), @bottom())

# Rectangle accessing - setting:
Rectangle::setTo = (left, top, right, bottom) ->
  # note: all inputs are optional and can be omitted
  @origin = new Point(left or ((if (left is 0) then 0 else @left())), top or ((if (top is 0) then 0 else @top())))
  @corner = new Point(right or ((if (right is 0) then 0 else @right())), bottom or ((if (bottom is 0) then 0 else @bottom())))

# Rectangle accessing - getting:
Rectangle::area = ->
  #requires width() and height() to be defined
  w = @width()
  return 0  if w < 0
  Math.max w * @height(), 0

Rectangle::bottom = ->
  @corner.y

Rectangle::bottomCenter = ->
  new Point(@center().x, @bottom())

Rectangle::bottomLeft = ->
  new Point(@origin.x, @corner.y)

Rectangle::bottomRight = ->
  @corner.copy()

Rectangle::boundingBox = ->
  @

Rectangle::center = ->
  @origin.add @corner.subtract(@origin).floorDivideBy(2)

Rectangle::corners = ->
  [@origin, @bottomLeft(), @corner, @topRight()]

Rectangle::extent = ->
  @corner.subtract @origin

Rectangle::height = ->
  @corner.y - @origin.y

Rectangle::left = ->
  @origin.x

Rectangle::leftCenter = ->
  new Point(@left(), @center().y)

Rectangle::right = ->
  @corner.x

Rectangle::rightCenter = ->
  new Point(@right(), @center().y)

Rectangle::top = ->
  @origin.y

Rectangle::topCenter = ->
  new Point(@center().x, @top())

Rectangle::topLeft = ->
  @origin

Rectangle::topRight = ->
  new Point(@corner.x, @origin.y)

Rectangle::width = ->
  @corner.x - @origin.x

Rectangle::position = ->
  @origin

# Rectangle comparison:
Rectangle::eq = (aRect) ->
  @origin.eq(aRect.origin) and @corner.eq(aRect.corner)

Rectangle::abs = ->
  newOrigin = undefined
  newCorner = undefined
  newOrigin = @origin.abs()
  newCorner = @corner.max(newOrigin)
  newOrigin.corner newCorner

# Rectangle functions:
Rectangle::insetBy = (delta) ->
  # delta can be either a Point or a Number
  result = new Rectangle()
  result.origin = @origin.add(delta)
  result.corner = @corner.subtract(delta)
  result

Rectangle::expandBy = (delta) ->
  # delta can be either a Point or a Number
  result = new Rectangle()
  result.origin = @origin.subtract(delta)
  result.corner = @corner.add(delta)
  result

Rectangle::growBy = (delta) ->
  # delta can be either a Point or a Number
  result = new Rectangle()
  result.origin = @origin.copy()
  result.corner = @corner.add(delta)
  result

Rectangle::intersect = (aRect) ->
  result = new Rectangle()
  result.origin = @origin.max(aRect.origin)
  result.corner = @corner.min(aRect.corner)
  result

Rectangle::merge = (aRect) ->
  result = new Rectangle()
  result.origin = @origin.min(aRect.origin)
  result.corner = @corner.max(aRect.corner)
  result

Rectangle::round = ->
  @origin.round().corner @corner.round()

Rectangle::spread = ->
  # round me by applying floor() to my origin and ceil() to my corner
  @origin.floor().corner @corner.ceil()

Rectangle::amountToTranslateWithin = (aRect) ->
  #
  #    Answer a Point, delta, such that self + delta is forced within
  #    aRectangle. when all of me cannot be made to fit, prefer to keep
  #    my topLeft inside. Taken from Squeak.
  #
  dx = undefined
  dy = undefined
  dx = aRect.right() - @right()  if @right() > aRect.right()
  dy = aRect.bottom() - @bottom()  if @bottom() > aRect.bottom()
  dx = aRect.left() - @right()  if (@left() + dx) < aRect.left()
  dy = aRect.top() - @top()  if (@top() + dy) < aRect.top()
  new Point(dx, dy)


# Rectangle testing:
Rectangle::containsPoint = (aPoint) ->
  @origin.le(aPoint) and aPoint.lt(@corner)

Rectangle::containsRectangle = (aRect) ->
  aRect.origin.gt(@origin) and aRect.corner.lt(@corner)

Rectangle::intersects = (aRect) ->
  ro = aRect.origin
  rc = aRect.corner
  (rc.x >= @origin.x) and (rc.y >= @origin.y) and (ro.x <= @corner.x) and (ro.y <= @corner.y)


# Rectangle transforming:
Rectangle::scaleBy = (scale) ->
  # scale can be either a Point or a scalar
  o = @origin.multiplyBy(scale)
  c = @corner.multiplyBy(scale)
  new Rectangle(o.x, o.y, c.x, c.y)

Rectangle::translateBy = (factor) ->
  # factor can be either a Point or a scalar
  o = @origin.add(factor)
  c = @corner.add(factor)
  new Rectangle(o.x, o.y, c.x, c.y)


# Rectangle converting:
Rectangle::asArray = ->
  [@left(), @top(), @right(), @bottom()]

Rectangle::asArray_xywh = ->
  [@left(), @top(), @width(), @height()]
