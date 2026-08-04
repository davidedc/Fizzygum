# Just like the Point class, this class has a "new on change"
# policy (also often called "immutable data structures").
# This means that any time you change any part of a
# Rectangle, a *new* Rectangle is created, the old one is
# left unchanged.
# The reason for this is that as manipulation and assignments
# of (parts of) Rectangles is done a lot, it gets
# difficult otherwise to understand how one change to
# (part of) a Rectangle propagates because of the
# assignments that may have happened.
# In this "new on change" policy things are easier - a change
# doesn't affect any other Rectangle ever apart from the
# new one.
# So for example you never change the @bounds property of
# a Widget in-place ever, rather
# you rather replace it with a new Rectangle.
# Also this means that as you create a Rectangle from another,
# you can have the new Rectangle pointing directly at the old
# origin and corner, because we are guaranteed that *those*
# will never change.
# Also another effect is that a Rectangle never needs defensive
# copying: the one you have will never change, and operations on
# it just create new ones — which is why neither Point nor
# Rectangle has a copy() at all.
# A further effect: when an operation's result would be
# value-identical to an existing instance, the operation is free
# to RETURN that instance instead of allocating — either `this`
# (e.g. round() on an already-integral Rectangle) or a shared
# canonical constant (Rectangle.EMPTY, Point.ZERO). The bar for
# such a shortcut is exact `===` equality of every coordinate
# with what the allocation would have produced: a -0-for-+0 swap
# (`===`-equal) is accepted, while NaN/Infinity inputs must take
# the allocating path (hence the Number.isFinite guards).
# Full policy + class inventory: docs/architecture/immutable-value-classes.md.

class Rectangle


  origin: nil # a Point
  corner: nil # a Point

  # a shared, immutable value: deep copies keep the reference (see Duplicator)
  keptByReferenceOnDeepCopy: true

  @EMPTY: new Rectangle
  
  constructor: (left = 0, top = 0, right = 0, bottom = 0) ->
    
    if (typeof(left) is "number") and (typeof(top) is "number") and (typeof(right) is "number") and (typeof(bottom) is "number")
      @origin = new Point left, top
      @corner = new Point right, bottom
    else if (left instanceof Point) and (typeof(top) is "number") and (typeof(right) is "number")
      @origin = left
      @corner = new Point top, right
    else if (typeof(left) is "number") and (typeof(top) is "number") and (right instanceof Point)
      @origin = new Point left, top
      @corner = right
    else if (left instanceof Point) and (top instanceof Point)
      @origin = left
      @corner = top
    else if left instanceof Point
      @origin = left
      @corner = Point.ZERO
    else if left instanceof Rectangle
      @origin = left.origin
      @corner = left.corner
  
  
  # Rectangle string representation: e.g. '[0@0 | 160@80]'
  toString: ->
    "[" + @origin + " | " + @extent() + "]"

  # Rectangle accessing - setting
  # This is used to create a bound with the specified
  # width and height: the corner needs to be displaced
  # of (width, bound) in respect to the origin
  setBoundsWidthAndHeight: (width, height) ->
    result = new @constructor()
    result.origin = @origin
    if (typeof(width) is "number") and (typeof(height) is "number")
      result.corner = new Point(
        width + @origin.x,
        height + @origin.y
      )
    else if (width instanceof Point)
      result.corner = new Point(
        width.x + @origin.x,
        width.y + @origin.y
      )
    else
      result.corner = @corner
    return result
  
  # Rectangle accessing - getting:
  area: ->
    #requires width() and height() to be defined
    w = @width()
    return 0  if w < 0
    Math.max w * @height(), 0
  
  bottom: ->
    @corner.y
  
  bottomCenter: ->
    new Point @center().x, @bottom()
  
  bottomLeft: ->
    new Point @origin.x, @corner.y
  
  bottomRight: ->
    @corner
  
  boundingBox: ->
    @
  
  center: ->
    @origin.add @corner.subtract(@origin).floorDivideBy(2)

  # the largest square centred in me: side = min(width, height), same centre. The
  # origin is fractional when the leftover space is odd — callers round when they
  # commit widget bounds (integer-placement policy).
  largestCenteredSquare: ->
    side = Math.min @width(), @height()
    l = @left() + (@width() - side) / 2
    t = @top() + (@height() - side) / 2
    new Rectangle l, t, l + side, t + side

  extent: ->
    @corner.subtract @origin
  
  isEmpty: ->
    return ((@width() <= 0) or (@height() <= 0))

  isNotEmpty: ->
    !@isEmpty()
  
  height: ->
    @corner.y - @origin.y
  
  left: ->
    @origin.x
  
  leftCenter: ->
    new Point @left(), @center().y
  
  right: ->
    @corner.x
  
  rightCenter: ->
    new Point @right(), @center().y
  
  top: ->
    @origin.y
  
  topCenter: ->
    new Point @center().x, @top()
  
  topLeft: ->
    @origin
  
  topRight: ->
    new Point @corner.x, @origin.y
  
  width: ->
    @corner.x - @origin.x
  
  position: ->
    @origin
  
  # Rectangle comparison:
  equals: (aRect) ->
    if !aRect? then return false
    @origin.equals(aRect.origin) and @corner.equals(aRect.corner)
  
  abs: ->
    newOrigin = @origin.abs()
    newCorner = @corner.max newOrigin
    newOrigin.corner newCorner
  
  # Rectangle functions:
  insetBy: (delta) ->
    # delta can be either a Point or a Number
    return @ if delta is 0 or delta.isZero?()
    result = new @constructor()
    result.origin = @origin.add delta
    result.corner = @corner.subtract delta
    result

  rightHalf: ->
    result = new @constructor()
    result.origin = @origin.add new Point Math.round(@width()/2),0
    result.corner = @corner
    result
  
  expandBy: (delta) ->
    # delta can be either a Point or a Number
    return @ if delta is 0 or delta.isZero?()
    result = new @constructor()
    result.origin = @origin.subtract delta
    result.corner = @corner.add delta
    result
  
  growBy: (delta) ->
    # delta can be either a Point or a Number
    return @ if delta is 0 or delta.isZero?()
    result = new @constructor()
    result.origin = @origin
    result.corner = @corner.add delta
    result
  
  # Note that "negative" rectangles can come
  # out of this operation. E.g.
  # new Rectangle(10,10,20,20).intersect(new Rectangle(15,25,19,25))
  # gives a rectangle with the corner above the origin.
  intersect: (aRect) ->
    a = @zeroIfNegative()
    b = aRect.zeroIfNegative()
    if a.isEmpty() or b.isEmpty()
      return @constructor.EMPTY
    result = new @constructor()
    result.origin = a.origin.max b.origin
    result.corner = a.corner.min b.corner
    result = result.zeroIfNegative()
    result

  zeroIfNegative: () ->
    if @isEmpty()
      return @constructor.EMPTY
    return @
  
  merge: (aRect) ->
    a = @zeroIfNegative()
    b = aRect.zeroIfNegative()
    if a.isEmpty()
      return b
    if b.isEmpty()
      return a
    # when one rectangle already contains the other, the union IS that rectangle
    return a if a.containsRectangle b
    return b if b.containsRectangle a
    result = new @constructor()
    result.origin = a.origin.min b.origin
    result.corner = a.corner.max b.corner
    result
  
  # true when all four coordinates are already integers — the common case under the
  # integer-placement policy, and the guard for the return-`@` shortcuts below
  _isIntegral: ->
    Number.isInteger(@origin.x) and Number.isInteger(@origin.y) and Number.isInteger(@corner.x) and Number.isInteger(@corner.y)

  round: ->
    return @ if @_isIntegral()
    @origin.round().corner @corner.round()

  # NOTE: like Point.floor, this also clamps to >= 0
  floor: ->
    return @ if @_isIntegral() and @origin.x >= 0 and @origin.y >= 0 and @corner.x >= 0 and @corner.y >= 0
    @origin.floor().corner @corner.floor()

  ceil: ->
    return @ if @_isIntegral()
    @origin.ceil().corner @corner.ceil()

  spread: ->
    # round me by applying floor() to my origin and ceil() to my corner
    # (floor clamps, so the origin must also be >= 0 for this to be a no-op)
    return @ if @_isIntegral() and @origin.x >= 0 and @origin.y >= 0
    @origin.floor().corner @corner.ceil()
  
  toLocalCoordinatesOf: (aWdgt) ->
    new @constructor @origin.x - aWdgt.left(),@origin.y - aWdgt.top(),@corner.x - aWdgt.left(),@corner.y - aWdgt.top()
  
  # Rectangle testing:
  containsPoint: (aPoint) ->
    @origin.le(aPoint) and aPoint.lt(@corner)
  
  containsRectangle: (aRect) ->
    aRect.origin.ge(@origin) and aRect.corner.le(@corner)

  isIntersecting: (aRect) ->
    ro = aRect.origin
    rc = aRect.corner
    rc.x >= @origin.x and
      rc.y >= @origin.y and
      ro.x <= @corner.x and
      ro.y <= @corner.y
  
  
  # Rectangle transforming:
  scaleBy: (scale) ->
    # scale can be either a Point or a scalar
    return @ if scale is 1 or (scale.x is 1 and scale.y is 1)
    scalesToZero = scale is 0 or scale.isZero?()
    if scalesToZero and Number.isFinite(@origin.x) and Number.isFinite(@origin.y) and Number.isFinite(@corner.x) and Number.isFinite(@corner.y)
      return @constructor.EMPTY
    o = @origin.multiplyBy scale
    c = @corner.multiplyBy scale
    new @constructor o.x, o.y, c.x, c.y

  translateBy: (factor) ->
    # factor can be either a Point or a scalar
    return @ if factor is 0 or factor.isZero?()
    o = @origin.add factor
    c = @corner.add factor
    new @constructor o.x, o.y, c.x, c.y
  
  translateTo: (aPoint) ->
    c = @corner
    new @constructor aPoint.x, aPoint.y, c.x, c.y
  
  
  # Rectangle converting:
  asArray: ->
    [@left(), @top(), @right(), @bottom()]
