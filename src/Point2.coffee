# Point2 //////////////////////////////////////////////////////////////
# like Point, but it tries not to create new objects like there is
# no tomorrow. Any operation that returned a new point now directly
# modifies the current point.
# Note that the arguments passed to any of these functions are never
# modified.

class Point2

  x: null
  y: null
   
  constructor: (@x = 0, @y = 0) ->
  
  # Point2 string representation: e.g. '12@68'
  toString: ->
    Math.round(@x.toString()) + "@" + Math.round(@y.toString())
  
  # Point2 copying:
  copy: ->
    new Point2(@x, @y)
  
  # Point2 comparison:
  eq: (aPoint2) ->
    # ==
    @x is aPoint2.x and @y is aPoint2.y
  
  lt: (aPoint2) ->
    # <
    @x < aPoint2.x and @y < aPoint2.y
  
  gt: (aPoint2) ->
    # >
    @x > aPoint2.x and @y > aPoint2.y
  
  ge: (aPoint2) ->
    # >=
    @x >= aPoint2.x and @y >= aPoint2.y
  
  le: (aPoint2) ->
    # <=
    @x <= aPoint2.x and @y <= aPoint2.y
  
  max: (aPoint2) ->
    #new Point2(Math.max(@x, aPoint2.x), Math.max(@y, aPoint2.y))
    @x = Math.max(@x, aPoint2.x)
    @y = Math.max(@y, aPoint2.y)
  
  min: (aPoint2) ->
    #new Point2(Math.min(@x, aPoint2.x), Math.min(@y, aPoint2.y))
    @x = Math.min(@x, aPoint2.x)
    @y = Math.min(@y, aPoint2.y)
  
  
  # Point2 conversion:
  round: ->
    #new Point2(Math.round(@x), Math.round(@y))
    @x = Math.round(@x)
    @y = Math.round(@y)
  
  abs: ->
    #new Point2(Math.abs(@x), Math.abs(@y))
    @x = Math.abs(@x)
    @y = Math.abs(@y)
  
  neg: ->
    #new Point2(-@x, -@y)
    @x = -@x
    @y = -@y
  
  mirror: ->
    #new Point2(@y, @x)
    # note that coffeescript would allow [@x,@y] = [@y,@x]
    # but we want to be faster here
    tmpValueForSwappingXAndY = @x
    @x = @y
    @y = tmpValueForSwappingXAndY 
  
  floor: ->
    #new Point2(Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0))
    @x = Math.max(Math.floor(@x), 0)
    @y = Math.max(Math.floor(@y), 0)
  
  ceil: ->
    #new Point2(Math.ceil(@x), Math.ceil(@y))
    @x = Math.ceil(@x)
    @y = Math.ceil(@y)
  
  
  # Point2 arithmetic:
  add: (other) ->
    if other instanceof Point2
      @x = @x + other.x
      @y = @y + other.y
      return
    @x = @x + other
    @y = @y + other
  
  subtract: (other) ->
    if other instanceof Point2
      @x = @x - other.x
      @y = @y - other.y
      return
    @x = @x - other
    @y = @y - other
  
  multiplyBy: (other) ->
    if other instanceof Point2
      @x = @x * other.x
      @y = @y * other.y
      return
    @x = @x * other
    @y = @y * other
  
  divideBy: (other) ->
    if other instanceof Point2
      @x = @x / other.x
      @y = @y / other.y
      return
    @x = @x / other
    @y = @y / other
  
  floorDivideBy: (other) ->
    if other instanceof Point2
      @x = Math.floor(@x / other.x)
      @y = Math.floor(@y / other.y)
      return
    @x = Math.floor(@x / other)
    @y = Math.floor(@y / other)
  
  
  # Point2 polar coordinates:
  # distance from the origin
  r: ->
    t = @copy()
    t.multiplyBy(t)
    Math.sqrt t.x + t.y
  
  degrees: ->
    #
    #    answer the angle I make with origin in degrees.
    #    Right is 0, down is 90
    #
    if @x is 0
      return 90  if @y >= 0
      return 270
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return degrees(theta)  if @y >= 0
      return 360 + (degrees(theta))
    180 + degrees(theta)
  
  theta: ->
    #
    #    answer the angle I make with origin in radians.
    #    Right is 0, down is 90
    #
    if @x is 0
      return radians(90)  if @y >= 0
      return radians(270)
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return theta  if @y >= 0
      return radians(360) + theta
    radians(180) + theta
  
  
  # Point2 functions:
  
  # this function is a bit fishy.
  # a cross product in 2d is probably not a vector
  # see https://github.com/jmoenig/morphic.js/issues/6
  # this function is not used
  crossProduct: (aPoint2) ->
    @multiplyBy aPoint2.copy().mirror()
  
  distanceTo: (aPoint2) ->
    (aPoint2.copy().subtract(@)).r()
  
  rotate: (direction, center) ->
    # direction must be 'right', 'left' or 'pi'
    offset = @copy().subtract(center)
    if direction is "right"
      @x = -offset.y + center.x
      @y = offset.y + center.y
      return
    if direction is "left"
      @x = offset.y + center.x
      @y = -offset.y + center.y
      return
    #
    # direction === 'pi'
    tmpPointForRotate = center.copy().subtract offset
    @x = tmpPointForRotate.x
    @y = tmpPointForRotate.y
  
  flip: (direction, center) ->
    # direction must be 'vertical' or 'horizontal'
    if direction is "vertical"
      @y = center.y * 2 - @y
      return
    #
    # direction === 'horizontal'
    @x = center.x * 2 - @x
  
  distanceAngle: (dist, angle) ->
    deg = angle
    if deg > 270
      deg = deg - 360
    else deg = deg + 360  if deg < -270
    if -90 <= deg and deg <= 90
      x = Math.sin(radians(deg)) * dist
      y = Math.sqrt((dist * dist) - (x * x))
      @x = x + @x
      @y = @y - y
      return
    x = Math.sin(radians(180 - deg)) * dist
    y = Math.sqrt((dist * dist) - (x * x))
    @x = x + @x
    @y = @y + y
  
  
  # Point2 transforming:
  scaleBy: (scalePoint2) ->
    @multiplyBy scalePoint2
  
  translateBy: (deltaPoint2) ->
    @add deltaPoint2
  
  rotateBy: (angle, centerPoint2) ->
    center = centerPoint2 or new Point2(0, 0)
    p = @copy().subtract(center)
    r = p.r()
    theta = angle - p.theta()
    @x = center.x + (r * Math.cos(theta))
    @y = center.y - (r * Math.sin(theta))
  
  
  # Point2 conversion:
  asArray: ->
    [@x, @y]
  
  # creating Rectangle instances from Point2:
  corner: (cornerPoint2) ->
    # answer a new Rectangle
    new Rectangle(@x, @y, cornerPoint2.x, cornerPoint2.y)
  
  rectangle: (aPoint2) ->
    # answer a new Rectangle
    org = @copy().min(aPoint2)
    crn = @copy().max(aPoint2)
    new Rectangle(org.x, org.y, crn.x, crn.y)
  
  extent: (aPoint2) ->
    #answer a new Rectangle
    crn = @copy().add(aPoint2)
    new Rectangle(@x, @y, crn.x, crn.y)
