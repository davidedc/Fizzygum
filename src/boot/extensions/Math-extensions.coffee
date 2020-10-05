# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

# min and max "extremes" are included
Math.getRandomInt = (min, max) ->
  min = Math.ceil min
  max = Math.floor max
  Math.floor Math.random() * (max - min + 1) + min
