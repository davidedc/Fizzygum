# this file is excluded from the fizzygum homepage build

# This extention is fake. It helps us understand what we
# are doing but it's a not a real extension, for example concatenation
# with "+" won't work.
#
# The reason why we are not *really* just extending String is that
# we get the error:
#    "String.prototype.toString requires that 'this' be a String"
# because of these:
#    https://stackoverflow.com/questions/46992393/how-to-correctly-inherit-from-string-built-in-class
#    https://github.com/Microsoft/TypeScript-wiki/blob/master/Breaking-Changes.md#extending-built-ins-like-error-array-and-map-may-no-longer-work
#
# So basically we'd need to copy-over all the methods from String:
#    https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String
# however we are going to copy just the ones we use

class Source extends String

  string: nil

  constructor: (@string) ->

  stripComments: ->
    new @constructor @string.replace /^ *#.*$/gm, ""

  removeLineEndSpaces: ->
    new @constructor @string.replace /^ *$/gm, ""

  collapseLastEmptyLines: ->
    new @constructor @string.replace /\n+/g, "\n"

  # this method is just copied from String
  match: ->
    @string.match arguments...

  # this method is just copied from String
  split: ->
    @string.split arguments...

  # this method is just copied from String
  includes: ->
    @string.split arguments...

  # this method is adapted from String
  replace: ->
    new @constructor @string.replace arguments...

  # this method is adapted from String
  toString: ->
    @string
