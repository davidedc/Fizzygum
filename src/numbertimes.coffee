# used for Fizzytiles

# Note that this also handles the
# cases where user wants to
# bind a variable e.g.
#   3 times with i box
# which is transformed into
#
#   3.times @, (i) -> box
#
# which coffeescript then transforms in the
#
# valid program:
#  3..times(this, function(i) {
#    return box;
#  });

Number::timesWithVariable = (scope, func) ->
  v = @valueOf()
  i = 0

  while i < v
    func.call scope or window, i
    i++

Number::times = (scope, func) ->
  v = @valueOf()
  i = 0

  while i < v
    func.call scope or window, i
    i++

