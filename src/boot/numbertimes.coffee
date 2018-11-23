# this file is excluded from the fizzygum homepage build

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
#
# Why do we need the scope to be passed?
# because as this is a method of numbers, this is
# bound to the number. So if you have functions that
# are only in the "environment" scope, you need
# to pass the scope.
#
# In LCL we didn't need to do this because functions
# such as "box" etc. were all global, but in Fizzygum
# they are not.
#
# Are there other ways to implement "times" differently?
# There would be a way to do it as in times(number of times, function)
# which would also eliminate this scope passing.
# However, the transformation would be more complex.

Number::timesWithVariable = (scope, func) ->
  v = @valueOf()
  i = 0

  while i < v
    func.call scope, i
    i++

Number::times = (scope, func) ->
  v = @valueOf()
  i = 0

  while i < v
    func.call scope, i
    i++

