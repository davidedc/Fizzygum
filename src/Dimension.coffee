# Dimension //////////////////////////////////////////////////////////////

# REQUIRES Point

# See the Rectangle class about the "copy on change" policy
# of this class.

# this class really is nothing more than a Point. But with
# dimensions you can ask .width() and .height()
# which would otherwise be confusing in a Point.

class Dimension extends Point

  width: ->
    return @x

  height: ->
    return @y

