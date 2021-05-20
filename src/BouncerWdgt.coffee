# bounces within the parent. Similar to the good old
# AtomMorph from Squeak

# this file is excluded from the fizzygum homepage build

class BouncerWdgt extends Widget

  velocity: nil

  constructor: ->
    super()
    @fps = 60
    world.steppingWdgts.add @
    @rawSetExtent new Point 5, 5

    @appearance = new RectangularAppearance @

    while !@velocity? or @velocity.x == 0 or @velocity.y == 0
      @velocity = new Point Math.getRandomInt(-10,10), Math.getRandomInt(-10,10)

  
  step: ->
    p = @position()
    vx = @velocity.x
    vy = @velocity.y
    px = p.x + vx
    py = p.y + vy

    bounced = false

    if px > @parent.right()
      px = @parent.right() - (px - @parent.right())
      vx = - vx
      bounced = true

    if py > @parent.bottom()
      py = @parent.bottom() - (py - @parent.bottom())
      vy = - vy
      bounced = true

    if px < @parent.left()
      px = @parent.left() - (px - @parent.left())
      vx = - vx
      bounced = true

    if py < @parent.top()
      py = @parent.top() - (py - @parent.top())
      vy = - vy
      bounced = true

    @fullMoveTo new Point px, py
    if bounced
        @velocity = new Point vx, vy
