# See the Rectangle class about the "copy on change" policy
# of this class.

class Point

  x: nil
  y: nil
   
  constructor: (@x = 0, @y = 0) ->

  # Point string representation: e.g. '12@68'
  toString: ->
    Math.round(@x) + "@" + Math.round(@y)

  # Point copying:
  copy: ->
    new @constructor @x, @y

  # Point comparison:
  isZero: (aPoint) ->
    # ==
    @x is 0 and @y is 0
  
  # Point comparison:
  equals: (aPoint) ->
    # ==
    @x is aPoint.x and @y is aPoint.y
  
  lt: (aPoint) ->
    # <
    @x < aPoint.x and @y < aPoint.y
  
  ge: (aPoint) ->
    # >=
    @x >= aPoint.x and @y >= aPoint.y
  
  le: (aPoint) ->
    # <=
    @x <= aPoint.x and @y <= aPoint.y
  
  max: (aPoint) ->
    new @constructor Math.max(@x, aPoint.x), Math.max(@y, aPoint.y)
  
  min: (aPoint) ->
    new @constructor Math.min(@x, aPoint.x), Math.min(@y, aPoint.y)
  
  # Point conversion:
  round: ->
    new @constructor Math.round(@x), Math.round(@y)
  
  abs: ->
    new @constructor Math.abs(@x), Math.abs(@y)
  
  neg: ->
    new @constructor -@x, -@y

  floor: ->
    new @constructor Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0)
  
  ceil: ->
    new @constructor Math.ceil(@x), Math.ceil(@y)
  

  # these two in theory don't make sense
  # for a Point BUT it's handy because sometimes
  # we store dimensions in Points
  width: ->
    return @x

  height: ->
    return @y

  
  # Point arithmetic:
  add: (other) ->
    return new @constructor @x + other.x, @y + other.y  if other instanceof Point
    new @constructor @x + other, @y + other
  
  subtract: (other) ->
    return new @constructor @x - other.x, @y - other.y  if other instanceof Point
    new @constructor @x - other, @y - other
  
  multiplyBy: (other) ->
    return new @constructor @x * other.x, @y * other.y  if other instanceof Point
    new @constructor @x * other, @y * other
  
  floorDivideBy: (other) ->
    if other instanceof Point
      return new @constructor Math.floor(@x / other.x), Math.floor(@y / other.y)
    new @constructor Math.floor(@x / other), Math.floor(@y / other)
  
  toLocalCoordinatesOf: (aWdgt) ->
    new @constructor @x - aWdgt.left(), @y - aWdgt.top()
  
  # Point polar coordinates:
  r: ->
    t = @multiplyBy @
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
    theta = Math.atan tan
    if @x >= 0
      return theta.toDegrees()  if @y >= 0
      return 360 + theta.toDegrees()
    180 + theta.toDegrees()
  
  theta: ->
    #
    #    answer the angle I make with origin in radians.
    #    Right is 0, down is 90
    #
    if @x is 0
      return (90).toRadians()  if @y >= 0
      return (270).toRadians()
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return theta  if @y >= 0
      return (360).toRadians() + theta
    (180).toRadians() + theta
  
  
  # Point functions:
  distanceTo: (aPoint) ->
    aPoint.subtract(@).r()
  
  # The point `dist` away at compass `angle` (degrees, clockwise from north). Used by
  # the Pen family to walk a heading — PenWdgt.forward/back and the arrowhead corners
  # in PenAppearance.
  distanceAngle: (dist, angle) ->
    deg = angle
    if deg > 270
      deg = deg - 360
    else deg = deg + 360  if deg < -270
    if -90 <= deg and deg <= 90
      x = Math.sin(deg.toRadians()) * dist
      y = Math.sqrt((dist * dist) - (x * x))
      return new @constructor x + @x, @y - y
    x = Math.sin((180 - deg).toRadians()) * dist
    y = Math.sqrt((dist * dist) - (x * x))
    new @constructor x + @x, @y + y
  
  
  # Point transforming:
  scaleBy: (scalePoint) ->
    @multiplyBy scalePoint
  
  translateBy: (deltaPoint) ->
    @add deltaPoint
  
  
  # Point conversion:
  asArray: ->
    [@x, @y]
  
  # creating Rectangle instances from Points:
  corner: (cornerPoint) ->
    # answer a new Rectangle
    new Rectangle @x, @y, cornerPoint.x, cornerPoint.y
  
  rectangle: (aPoint) ->
    # answer a new Rectangle
    org = @min aPoint
    crn = @max aPoint
    new Rectangle org.x, org.y, crn.x, crn.y
  
  extent: (aPoint) ->
    #answer a new Rectangle
    crn = @add aPoint
    new Rectangle @x, @y, crn.x, crn.y
