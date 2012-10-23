# PenMorph ////////////////////////////////////////////////////////////

# I am a simple LOGO-wise turtle.

class PenMorph extends Morph
  
  heading: 0
  penSize: null
  isWarped: false # internal optimization
  wantsRedraw: false # internal optimization
  isDown: true
  
  constructor: () ->
    @penSize = WorldMorph.MorphicPreferences.handleSize * 4
    super()
    @setExtent new Point(@penSize, @penSize)
    # todo we need to change the size two times, for getting the right size
    # of the arrow and of the line. Probably should make the two distinct
    @penSize = 1
    #alert @morphMethod() # works
    # doesn't work cause coffeescript doesn't support static inheritance
    #alert @morphStaticMethod()

  @staticVariable: 1
  @staticFunction: -> 3.14
    
  # PenMorph updating - optimized for warping, i.e atomic recursion
  changed: ->
    if @isWarped is false
      w = @root()
      w.broken.push @visibleBounds().spread()  if w instanceof WorldMorph
      @parent.childChanged @  if @parent
  
  
  # PenMorph display:
  drawNew: (facing) ->
    #
    #    my orientation can be overridden with the "facing" parameter to
    #    implement Scratch-style rotation styles
    #    
    #
    context = undefined
    start = undefined
    dest = undefined
    left = undefined
    right = undefined
    len = undefined
    direction = facing or @heading
    if @isWarped
      @wantsRedraw = true
      return null
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    len = @width() / 2
    start = @center().subtract(@bounds.origin)
    dest = start.distanceAngle(len * 0.75, direction - 180)
    left = start.distanceAngle(len, direction + 195)
    right = start.distanceAngle(len, direction - 195)
    context.fillStyle = @color.toString()
    context.beginPath()
    context.moveTo start.x, start.y
    context.lineTo left.x, left.y
    context.lineTo dest.x, dest.y
    context.lineTo right.x, right.y
    context.closePath()
    context.strokeStyle = "white"
    context.lineWidth = 3
    context.stroke()
    context.strokeStyle = "black"
    context.lineWidth = 1
    context.stroke()
    context.fill()
    @wantsRedraw = false
  
  
  # PenMorph access:
  setHeading: (degrees) ->
    @heading = parseFloat(degrees) % 360
    if @isWarped is false
      @drawNew()
      @changed()
  
  
  # PenMorph drawing:
  drawLine: (start, dest) ->
    context = @parent.penTrails().getContext("2d")
    from = start.subtract(@parent.bounds.origin)
    to = dest.subtract(@parent.bounds.origin)
    if @isDown
      context.lineWidth = @penSize
      context.strokeStyle = @color.toString()
      context.lineCap = "round"
      context.lineJoin = "round"
      context.beginPath()
      context.moveTo from.x, from.y
      context.lineTo to.x, to.y
      context.stroke()
      @world().broken.push start.rectangle(dest).expandBy(Math.max(@penSize / 2, 1)).intersect(@parent.visibleBounds()).spread()  if @isWarped is false
  
  
  # PenMorph turtle ops:
  turn: (degrees) ->
    @setHeading @heading + parseFloat(degrees)
  
  forward: (steps) ->
    start = @center()
    dest = undefined
    dist = parseFloat(steps)
    if dist >= 0
      dest = @position().distanceAngle(dist, @heading)
    else
      dest = @position().distanceAngle(Math.abs(dist), (@heading - 180))
    @setPosition dest
    @drawLine start, @center()
  
  down: ->
    @isDown = true
  
  up: ->
    @isDown = false
  
  clear: ->
    @parent.drawNew()
    @parent.changed()
  
  
  # PenMorph optimization for atomic recursion:
  startWarp: ->
    @isWarped = true
  
  endWarp: ->
    @drawNew()  if @wantsRedraw
    @changed()
    @parent.changed()
    @isWarped = false
  
  warp: (fun) ->
    @startWarp()
    fun.call @
    @endWarp()
  
  warpOp: (selector, argsArray) ->
    @startWarp()
    @[selector].apply @, argsArray
    @endWarp()
  
  
  # PenMorph demo ops:
  # try these with WARP eg.: this.warp(function () {tree(12, 120, 20)})
  warpSierpinski: (length, min) ->
    @warpOp "sierpinski", [length, min]
  
  sierpinski: (length, min) ->
    i = undefined
    if length > min
      i = 0
      while i < 3
        @sierpinski length * 0.5, min
        @turn 120
        @forward length
        i += 1
  
  warpTree: (level, length, angle) ->
    @warpOp "tree", [level, length, angle]
  
  tree: (level, length, angle) ->
    if level > 0
      @penSize = level
      @forward length
      @turn angle
      @tree level - 1, length * 0.75, angle
      @turn angle * -2
      @tree level - 1, length * 0.75, angle
      @turn angle
      @forward -length
