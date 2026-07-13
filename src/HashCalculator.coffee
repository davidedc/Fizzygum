# this file is excluded from the fizzygum homepage build

# adapted from http://stackoverflow.com/a/7616484

# Currently used to differentiate the filenames
# for test reference images taken in
# different os/browser config: a hash of the
# configuration is added to the filename.

# This delegates to Object::hashCode (boot/extensions/Object-extensions.coffee)
# so there is ONE implementation of the string hash. That one is memoized by
# string value (an O2 hot-path optimization), so calculateHash gets the cached
# path for free. The two used to be separate copies of the same loop; they
# compute identical 32-bit values (verified empirically AND structurally -- the
# old copy's in-loop `i++` was a no-op clobbered by CoffeeScript's range-loop
# counter, and its `& 0xFFFF` was inert since charCodeAt is already 16-bit), so
# the delegation is behavior-preserving -- including the test-reference filenames.
#
# The hash is a 32-bit integer computed with Horner's method, the same algorithm
# Java's String.hashCode() uses (see
# https://mathcenter.oxford.emory.edu/site/cs171/generatingHashCodes/ ).
#
# NOTE: to hash other kinds of data you apply the same step to each element. For
# a boolean array, Java uses 1231 for true and 1237 for false:
#
#   calculateBooleanArrayHash = (booleanArray) ->
#     hash = 0|0
#     for b in booleanArray
#       hash = ((hash << 5) - hash) + (if b then 1231 else 1237)
#       hash |= 0
#     return hash|0

class HashCalculator

  @calculateHash: (theString) ->
    theString.hashCode()
