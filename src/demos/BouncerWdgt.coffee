# bounces within the parent. Similar to the good old
# AtomMorph from Squeak

class BouncerWdgt extends Widget

  velocity: undefined

  constructor: ->
    super()
    @fps = 60
    world.steppingWdgts.add @
    @_applyExtent new Point 5, 5

    @appearance = new RectangularAppearance @

    while !@velocity? or @velocity.x == 0 or @velocity.y == 0
      @velocity = new Point Math.getRandomInt(-10,10), Math.getRandomInt(-10,10)

  
  # I bounce inside my parent, so without one (a bouncer not attached yet, or taken off its holder,
  # stays in the world's stepping set) there is nothing to bounce inside, and my step does nothing.
  step: ->
    return unless @parent?
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

    @moveTo new Point px, py
    if bounced
        @velocity = new Point vx, vy
