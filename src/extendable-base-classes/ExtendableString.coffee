# this file is excluded from the fizzygum homepage build

# This extension is a little wonky, as you see we have to keep a
# String inside, because extending native classes
# is tricky.
#
# The reason why we are not *just* extending String is that
# we get the errors:
#    "String.prototype.toString requires that 'this' be a String"
#   or
#    "String.prototype.valueOf requires that 'this' be a String"
# because of these:
#    https://stackoverflow.com/questions/46992393/how-to-correctly-inherit-from-string-built-in-class
#    https://github.com/Microsoft/TypeScript-wiki/blob/master/Breaking-Changes.md#extending-built-ins-like-error-array-and-map-may-no-longer-work
#
# So basically we need to fudge it a little by keeping a redundant String
# around like so, otherwise toString can't be implemented

class ExtendableString extends String

  _string: nil

  constructor: (@_string) ->

  # adapted from String
  replace: ->
    new @constructor @_string.replace arguments...

  # adapted from String
  toString: ->
    @_string

  # adapted from String
  valueOf: ->
    @_string
