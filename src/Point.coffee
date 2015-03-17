# Points //////////////////////////////////////////////////////////////

# REQUIRES DeepCopierMixin

class Point
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

  x: null
  y: null
   
  constructor: (@x = 0, @y = 0) ->
  
  # Point string representation: e.g. '12@68'
  toString: ->
    Math.round(@x) + "@" + Math.round(@y)
  
  # Point copying:
  copy: ->
    new @constructor(@x, @y)
  
  # Point comparison:
  eq: (aPoint) ->
    # ==
    @x is aPoint.x and @y is aPoint.y
  
  lt: (aPoint) ->
    # <
    @x < aPoint.x and @y < aPoint.y
  
  gt: (aPoint) ->
    # >
    @x > aPoint.x and @y > aPoint.y
  
  ge: (aPoint) ->
    # >=
    @x >= aPoint.x and @y >= aPoint.y
  
  le: (aPoint) ->
    # <=
    @x <= aPoint.x and @y <= aPoint.y
  
  max: (aPoint) ->
    new @constructor(Math.max(@x, aPoint.x), Math.max(@y, aPoint.y))
  
  min: (aPoint) ->
    new @constructor(Math.min(@x, aPoint.x), Math.min(@y, aPoint.y))
  
  
  # Point conversion:
  round: ->
    new @constructor(Math.round(@x), Math.round(@y))
  
  abs: ->
    new @constructor(Math.abs(@x), Math.abs(@y))
  
  neg: ->
    new @constructor(-@x, -@y)
  
  mirror: ->
    new @constructor(@y, @x)
  
  floor: ->
    new @constructor(Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0))
  
  ceil: ->
    new @constructor(Math.ceil(@x), Math.ceil(@y))
  
  
  # Point arithmetic:
  add: (other) ->
    return new @constructor(@x + other.x, @y + other.y)  if other instanceof Point
    new @constructor(@x + other, @y + other)
  
  subtract: (other) ->
    return new @constructor(@x - other.x, @y - other.y)  if other instanceof Point
    new @constructor(@x - other, @y - other)
  
  multiplyBy: (other) ->
    return new @constructor(@x * other.x, @y * other.y)  if other instanceof Point
    new @constructor(@x * other, @y * other)
  
  divideBy: (other) ->
    return new @constructor(@x / other.x, @y / other.y)  if other instanceof Point
    new @constructor(@x / other, @y / other)
  
  floorDivideBy: (other) ->
    if other instanceof Point
      return new @constructor(Math.floor(@x / other.x), Math.floor(@y / other.y))
    new @constructor(Math.floor(@x / other), Math.floor(@y / other))
  
  
  # Point polar coordinates:
  r: ->
    t = (@multiplyBy(@))
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
  
  
  # Point functions:
  distanceTo: (aPoint) ->
    (aPoint.subtract(@)).r()
  
  rotate: (direction, center) ->
    # direction must be 'right', 'left' or 'pi'
    offset = @subtract(center)
    return new @constructor(-offset.y, offset.y).add(center)  if direction is "right"
    return new @constructor(offset.y, -offset.y).add(center)  if direction is "left"

    # direction === 'pi'
    center.subtract offset
  
  flip: (direction, center) ->
    # direction must be 'vertical' or 'horizontal'
    return new @constructor(@x, center.y * 2 - @y)  if direction is "vertical"

    # direction === 'horizontal'
    new @constructor(center.x * 2 - @x, @y)
  
  distanceAngle: (dist, angle) ->
    deg = angle
    if deg > 270
      deg = deg - 360
    else deg = deg + 360  if deg < -270
    if -90 <= deg and deg <= 90
      x = Math.sin(radians(deg)) * dist
      y = Math.sqrt((dist * dist) - (x * x))
      return new @constructor(x + @x, @y - y)
    x = Math.sin(radians(180 - deg)) * dist
    y = Math.sqrt((dist * dist) - (x * x))
    new @constructor(x + @x, @y + y)
  
  
  # Point transforming:
  scaleBy: (scalePoint) ->
    @multiplyBy scalePoint
  
  translateBy: (deltaPoint) ->
    @add deltaPoint
  
  rotateBy: (angle, centerPoint) ->
    center = centerPoint or new @constructor(0, 0)
    p = @subtract(center)
    r = p.r()
    theta = angle - p.theta()
    new @constructor(center.x + (r * Math.cos(theta)), center.y - (r * Math.sin(theta)))
  
  
  # Point conversion:
  asArray: ->
    [@x, @y]
  
  # creating Rectangle instances from Points:
  corner: (cornerPoint) ->
    # answer a new Rectangle
    new Rectangle(@x, @y, cornerPoint.x, cornerPoint.y)
  
  rectangle: (aPoint) ->
    # answer a new Rectangle
    org = @min(aPoint)
    crn = @max(aPoint)
    new Rectangle(org.x, org.y, crn.x, crn.y)
  
  extent: (aPoint) ->
    #answer a new Rectangle
    crn = @add(aPoint)
    new Rectangle(@x, @y, crn.x, crn.y)
