# Rectangles //////////////////////////////////////////////////////////

# REQUIRES DeepCopierMixin

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
# a Morph in-place ever, rather
# you rather replace it with a new Rectangle.
# Also this means that as you create a Rectangle from another,
# you can have the new Rectangle pointing directly at the old
# origin and corner, because we are guaranteed that *those*
# will never change.
# Also another effect is that you never need to copy() a
# Rectangle. This is because the one you have will never change
# and the new operations you put it through will just create
# new ones.
# The drawback is that "new on change" policy means that a bunch
# of Rectangles are created for potentially a great
# number of transient transformations which would
# otherwise be cheaper to just do
# in place. The problem with mixing the two approaches
# is that using in-place changes poisons the other approach,
# so the two approaches can only be mixed with great care, so
# it should probably only be done in "optimisation" phase
# if profiling shows it's actually a problem.

class Rectangle
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

  origin: null
  corner: null
  @EMPTY: new Rectangle()
  
  constructor: (left = 0, top = 0, right = 0, bottom = 0) ->
    
    if (typeof(left) is "number") and (typeof(top) is "number") and (typeof(right) is "number") and (typeof(bottom) is "number")
      @origin = new Point(left, top)
      @corner = new Point(right, bottom)
    else if (left instanceof Point) and (typeof(top) is "number") and (typeof(right) is "number")
      @origin = left
      @corner = new Point(top, right)
    else if (typeof(left) is "number") and (typeof(top) is "number") and (right instanceof Point)
      @origin = new Point(left, top)
      @corner = right
    else if (left instanceof Point) and (top instanceof Point)
      @origin = left
      @corner = top
    else if (left instanceof Rectangle)
      @origin = left.origin
      @corner = top.origin
  
  
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
    return ((@width() <= 0) or (@height() <= 0))

  isNotEmpty: ->
    !@isEmpty()
  
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
    if !aRect? then return false
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
  
  # Note that "negative" rectangles can come
  # out of this operation. E.g.
  # new Rectangle(10,10,20,20).intersect(new Rectangle(15,25,19,25))
  # gives a rectangle with the corner above the origin.
  intersect: (aRect) ->
    @debugIfFloats()
    a = @zeroIfNegative()
    b = aRect.zeroIfNegative()
    if a.isEmpty() or b.isEmpty()
      return @constructor.EMPTY
    result = new @constructor()
    result.origin = a.origin.max(b.origin)
    result.corner = a.corner.min(b.corner)
    result = result.zeroIfNegative()
    result.debugIfFloats()
    result

  zeroIfNegative: () ->
    @debugIfFloats()
    if @isEmpty()
      return @constructor.EMPTY
    return @
  
  merge: (aRect) ->
    @debugIfFloats()
    a = @zeroIfNegative()
    b = aRect.zeroIfNegative()
    if a.isEmpty()
      return b
    result = new @constructor()
    result.origin = a.origin.min(b.origin)
    result.corner = a.corner.max(aRect.corner)
    result.debugIfFloats()
    result
  
  round: ->
    @origin.round().corner @corner.round()

  floor: ->
    @origin.floor().corner @corner.floor()

  ceil: ->
    @origin.ceil().corner @corner.ceil()
  
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
  
  toLocalCoordinatesOf: (aMorph) ->
    new @constructor(@origin.x - aMorph.left(),@origin.y - aMorph.top(),@corner.x - aMorph.left(),@corner.y - aMorph.top())
  
  # Rectangle testing:
  containsPoint: (aPoint) ->
    @debugIfFloats()
    @origin.le(aPoint) and aPoint.lt(@corner)
  
  containsRectangle: (aRect) ->
    @debugIfFloats()
    aRect.origin.ge(@origin) and aRect.corner.le(@corner)
  
  isIntersecting: (aRect) ->
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
