# adapted from thomasdarimont/spinning-cube.html
# https://gist.github.com/thomasdarimont/8c694b4522c6cb10d85c

class Point3D

  @augmentWith DeepCopierMixin

  x: nil
  y: nil
  z: nil

  constructor: (@x = 0, @y = 0, @z = 0) ->

  # the order of the rotations does matter
  # and there is no reason to assume
  # a specific order, so we leave the
  # three rotations separate

  rotateX: (angle) ->
    rad = angle * Math.PI / 180
    cosa = Math.cos rad
    sina = Math.sin rad
    y = @y * cosa - @z * sina
    z = @y * sina + @z * cosa
    new @constructor @x, y, z

  rotateY: (angle) ->
    rad = angle * Math.PI / 180
    cosa = Math.cos rad
    sina = Math.sin rad
    z = @z * cosa - @x * sina
    x = @z * sina + @x * cosa
    new @constructor x, @y, z

  rotateZ: (angle) ->
    rad = angle * Math.PI / 180
    cosa = Math.cos rad
    sina = Math.sin rad
    x = @x * cosa - @y * sina
    y = @x * sina + @y * cosa
    new @constructor x, y, @z

  # the order of the translations doesn't matter
  # so one can do them all together

  translateXYZ: (dx,dy,dz) ->
    new @constructor @x+dx, @y+dy, @z+dz

  project: (viewWidth, viewHeight, fieldOfView, viewDistance) ->
    factor = fieldOfView / (viewDistance + @z)
    x = @x * factor + viewWidth / 2
    y = @y * factor + viewHeight / 2
    new Point x, y
