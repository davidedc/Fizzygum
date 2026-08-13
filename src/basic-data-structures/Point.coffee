# IMMUTABLE — "new on change": see the Rectangle class header for the full policy,
# including the return-`@` / canonical-constant shortcut rules and their exact-`===` bar.

class Point

  x: undefined
  y: undefined

  # a shared, immutable value: deep copies keep the reference (see Duplicator)
  keptByReferenceOnDeepCopy: true

  # THE canonical zero point. A deferred static (see Class.coffee): a class-level value
  # whose source says `new Point` is initialised right after the class itself exists —
  # same mechanism as Rectangle.EMPTY and the Color constants.
  @ZERO: new Point 0, 0

  constructor: (@x = 0, @y = 0) ->

  # Point string representation: e.g. '12@68'
  toString: ->
    Math.round(@x) + "@" + Math.round(@y)

  # Point comparison:
  isZero: ->
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
    return @ if @x >= aPoint.x and @y >= aPoint.y
    return aPoint if aPoint.x >= @x and aPoint.y >= @y
    new @constructor Math.max(@x, aPoint.x), Math.max(@y, aPoint.y)

  min: (aPoint) ->
    return @ if @x <= aPoint.x and @y <= aPoint.y
    return aPoint if aPoint.x <= @x and aPoint.y <= @y
    new @constructor Math.min(@x, aPoint.x), Math.min(@y, aPoint.y)
  
  # Point conversion:
  # (the return-`@` guards: already-integral coordinates are the common case under
  # the integer-placement policy, so these ops mostly need no allocation at all)
  round: ->
    return @ if Number.isInteger(@x) and Number.isInteger(@y)
    new @constructor Math.round(@x), Math.round(@y)

  abs: ->
    return @ if @x >= 0 and @y >= 0
    new @constructor Math.abs(@x), Math.abs(@y)

  neg: ->
    new @constructor -@x, -@y

  # NOTE: floor also clamps to >= 0
  floor: ->
    return @ if Number.isInteger(@x) and @x >= 0 and Number.isInteger(@y) and @y >= 0
    new @constructor Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0)

  ceil: ->
    return @ if Number.isInteger(@x) and Number.isInteger(@y)
    new @constructor Math.ceil(@x), Math.ceil(@y)
  

  # these two in theory don't make sense
  # for a Point BUT it's handy because sometimes
  # we store dimensions in Points
  width: ->
    return @x

  height: ->
    return @y

  
  # Point arithmetic:
  # adding/subtracting zero and multiplying by one return `this` (exact no-ops);
  # multiplying by zero returns THE canonical Point.ZERO — but only for finite
  # coordinates, since NaN/Infinity times zero is not zero.
  add: (other) ->
    if other instanceof Point
      return @ if other.x is 0 and other.y is 0
      return new @constructor @x + other.x, @y + other.y
    return @ if other is 0
    new @constructor @x + other, @y + other

  subtract: (other) ->
    if other instanceof Point
      return @ if other.x is 0 and other.y is 0
      return new @constructor @x - other.x, @y - other.y
    return @ if other is 0
    new @constructor @x - other, @y - other

  multiplyBy: (other) ->
    if other instanceof Point
      return @ if other.x is 1 and other.y is 1
      if other.x is 0 and other.y is 0 and Number.isFinite(@x) and Number.isFinite(@y)
        return @constructor.ZERO
      return new @constructor @x * other.x, @y * other.y
    return @ if other is 1
    if other is 0 and Number.isFinite(@x) and Number.isFinite(@y)
      return @constructor.ZERO
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
  # the Pen family to walk a heading — PenWdgt.forward (negative steps walk backward)
  # and the arrowhead corners in PenAppearance.
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
