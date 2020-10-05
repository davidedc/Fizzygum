# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

Number::toRadians = ->
  @ * Math.PI / 180

Number::toDegrees = ->
  @ * 180 / Math.PI
