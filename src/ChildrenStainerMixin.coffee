# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions


# some widgets are composed by a number of other widgets,
# and you'd want them all to change color at the same time
# an example is the reference widget, which is composed by
# the "reference arrow" and the "document" icons, and you
# want them to change color (e.g. on hover or click) at the
# same time

ChildrenStainerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      setColor: (theColor) ->
        super
        for eachChild in @children
          eachChild.setColor theColor
