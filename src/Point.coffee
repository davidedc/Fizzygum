# Points //////////////////////////////////////////////////////////////

# Point instance creation:
Point = (x, y) ->
  @x = x or 0
  @y = y or 0

# Point string representation: e.g. '12@68'
Point::toString = ->
  Math.round(@x.toString()) + "@" + Math.round(@y.toString())


# Point copying:
Point::copy = ->
  new Point(@x, @y)


# Point comparison:
Point::eq = (aPoint) ->
  
  # ==
  @x is aPoint.x and @y is aPoint.y

Point::lt = (aPoint) ->
  
  # <
  @x < aPoint.x and @y < aPoint.y

Point::gt = (aPoint) ->
  
  # >
  @x > aPoint.x and @y > aPoint.y

Point::ge = (aPoint) ->
  
  # >=
  @x >= aPoint.x and @y >= aPoint.y

Point::le = (aPoint) ->
  
  # <=
  @x <= aPoint.x and @y <= aPoint.y

Point::max = (aPoint) ->
  new Point(Math.max(@x, aPoint.x), Math.max(@y, aPoint.y))

Point::min = (aPoint) ->
  new Point(Math.min(@x, aPoint.x), Math.min(@y, aPoint.y))


# Point conversion:
Point::round = ->
  new Point(Math.round(@x), Math.round(@y))

Point::abs = ->
  new Point(Math.abs(@x), Math.abs(@y))

Point::neg = ->
  new Point(-@x, -@y)

Point::mirror = ->
  new Point(@y, @x)

Point::floor = ->
  new Point(Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0))

Point::ceil = ->
  new Point(Math.ceil(@x), Math.ceil(@y))


# Point arithmetic:
Point::add = (other) ->
  return new Point(@x + other.x, @y + other.y)  if other instanceof Point
  new Point(@x + other, @y + other)

Point::subtract = (other) ->
  return new Point(@x - other.x, @y - other.y)  if other instanceof Point
  new Point(@x - other, @y - other)

Point::multiplyBy = (other) ->
  return new Point(@x * other.x, @y * other.y)  if other instanceof Point
  new Point(@x * other, @y * other)

Point::divideBy = (other) ->
  return new Point(@x / other.x, @y / other.y)  if other instanceof Point
  new Point(@x / other, @y / other)

Point::floorDivideBy = (other) ->
  return new Point(Math.floor(@x / other.x), Math.floor(@y / other.y))  if other instanceof Point
  new Point(Math.floor(@x / other), Math.floor(@y / other))


# Point polar coordinates:
Point::r = ->
  t = (@multiplyBy(this))
  Math.sqrt t.x + t.y

Point::degrees = ->
  
  #
  #    answer the angle I make with origin in degrees.
  #    Right is 0, down is 90
  #
  tan = undefined
  theta = undefined
  if @x is 0
    return 90  if @y >= 0
    return 270
  tan = @y / @x
  theta = Math.atan(tan)
  if @x >= 0
    return degrees(theta)  if @y >= 0
    return 360 + (degrees(theta))
  180 + degrees(theta)

Point::theta = ->
  
  #
  #    answer the angle I make with origin in radians.
  #    Right is 0, down is 90
  #
  tan = undefined
  theta = undefined
  if @x is 0
    return radians(90)  if @y >= 0
    return radians(270)
  tan = @y / @x
  theta = Math.atan(tan)
  if @x >= 0
    return theta  if @y >= 0
    return radians(360) + theta
  radians(180) + theta


# Point functions:
Point::crossProduct = (aPoint) ->
  @multiplyBy aPoint.mirror()

Point::distanceTo = (aPoint) ->
  (aPoint.subtract(this)).r()

Point::rotate = (direction, center) ->
  
  # direction must be 'right', 'left' or 'pi'
  offset = @subtract(center)
  return new Point(-offset.y, offset.y).add(center)  if direction is "right"
  return new Point(offset.y, -offset.y).add(center)  if direction is "left"
  
  # direction === 'pi'
  center.subtract offset

Point::flip = (direction, center) ->
  
  # direction must be 'vertical' or 'horizontal'
  return new Point(@x, center.y * 2 - @y)  if direction is "vertical"
  
  # direction === 'horizontal'
  new Point(center.x * 2 - @x, @y)

Point::distanceAngle = (dist, angle) ->
  deg = angle
  x = undefined
  y = undefined
  if deg > 270
    deg = deg - 360
  else deg = deg + 360  if deg < -270
  if -90 <= deg and deg <= 90
    x = Math.sin(radians(deg)) * dist
    y = Math.sqrt((dist * dist) - (x * x))
    return new Point(x + @x, @y - y)
  x = Math.sin(radians(180 - deg)) * dist
  y = Math.sqrt((dist * dist) - (x * x))
  new Point(x + @x, @y + y)


# Point transforming:
Point::scaleBy = (scalePoint) ->
  @multiplyBy scalePoint

Point::translateBy = (deltaPoint) ->
  @add deltaPoint

Point::rotateBy = (angle, centerPoint) ->
  center = centerPoint or new Point(0, 0)
  p = @subtract(center)
  r = p.r()
  theta = angle - p.theta()
  new Point(center.x + (r * Math.cos(theta)), center.y - (r * Math.sin(theta)))


# Point conversion:
Point::asArray = ->
  [@x, @y]

# creating Rectangle instances from Points:
Point::corner = (cornerPoint) ->
  
  # answer a new Rectangle
  new Rectangle(@x, @y, cornerPoint.x, cornerPoint.y)

Point::rectangle = (aPoint) ->
  
  # answer a new Rectangle
  org = undefined
  crn = undefined
  org = @min(aPoint)
  crn = @max(aPoint)
  new Rectangle(org.x, org.y, crn.x, crn.y)

Point::extent = (aPoint) ->
  
  #answer a new Rectangle
  crn = @add(aPoint)
  new Rectangle(@x, @y, crn.x, crn.y)
