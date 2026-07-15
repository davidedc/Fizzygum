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

  @augmentWith DeepCopierMixin

  origin: nil # a Point
  corner: nil # a Point
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
      @corner = new Point 0, 0
    else if left instanceof Rectangle
      @origin = left.origin
      @corner = top.origin
  
  
  # Rectangle string representation: e.g. '[0@0 | 160@80]'
  toString: ->
    "[" + @origin + " | " + @extent() + "]"

  # Rectangle copying:
  copy: ->
    new @constructor @left(), @top(), @right(), @bottom()
  
  # Rectangle accessing - setting
  # This is used to create a bound with the specified
  # width and height: the corner needs to be displaced
  # of (width, bound) in respect to the origin
  setBoundsWidthAndHeight: (width, height) ->
    copy = @copy()
    if (typeof(width) is "number") and (typeof(height) is "number")
      copy.corner = new Point(
        width + copy.origin.x,
        height + copy.origin.y
      )
    else if (width instanceof Point)
      copy.corner = new Point(
        width.x + copy.origin.x,
        width.y + copy.origin.y
      )
    return copy
  
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
    @corner.copy()
  
  boundingBox: ->
    @
  
  center: ->
    @origin.add @corner.subtract(@origin).floorDivideBy(2)
  
  # »>> this part is excluded from the fizzygum homepage build
  # unused code
  corners: ->
    [@origin, @bottomLeft(), @corner, @topRight()]
  # this part is excluded from the fizzygum homepage build <<«
  
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
    result = new @constructor()
    result.origin = @origin.add delta
    result.corner = @corner.subtract delta
    result

  rightHalf: ->
    result = new @constructor()
    result.origin = @origin.add new Point Math.round(@width()/2),0
    result.corner = @corner.copy()
    result
  
  expandBy: (delta) ->
    # delta can be either a Point or a Number
    result = new @constructor()
    result.origin = @origin.subtract delta
    result.corner = @corner.add delta
    result
  
  growBy: (delta) ->
    # delta can be either a Point or a Number
    result = new @constructor()
    result.origin = @origin.copy()
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
    result = new @constructor()
    result.origin = a.origin.min b.origin
    result.corner = a.corner.max aRect.corner
    result
  
  round: ->
    @origin.round().corner @corner.round()

  floor: ->
    @origin.floor().corner @corner.floor()

  ceil: ->
    @origin.ceil().corner @corner.ceil()
  
  spread: ->
    # round me by applying floor() to my origin and ceil() to my corner
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
    o = @origin.multiplyBy scale
    c = @corner.multiplyBy scale
    new @constructor o.x, o.y, c.x, c.y
  
  translateBy: (factor) ->
    # factor can be either a Point or a scalar
    o = @origin.add factor
    c = @corner.add factor
    new @constructor o.x, o.y, c.x, c.y
  
  translateTo: (aPoint) ->
    c = @corner
    new @constructor aPoint.x, aPoint.y, c.x, c.y
  
  
  # Rectangle converting:
  asArray: ->
    [@left(), @top(), @right(), @bottom()]
