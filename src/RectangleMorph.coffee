# RectangleMorph /////////////////////////////////////////////////////////
# a plain rectangular Morph. Because it's so basic, it's the building
# block of many more complex constructions, for example containers
# , clipping windows, and clipping windows which allow content to be
# scrolled (clipping is particularly easy to do along a rectangular
# path and it allows many optimisations and it's a very common case)
# It's important that the basic unadulterated version of
# rectangle doesn't draw a border, to keep this basic
# and versatile, so for example there is no case where the children
# are painted over the border, which would look bad.


class RectangleMorph extends Morph

  count: 1
  countVal: null
  countOfRectangleKids: null

  constructor: (extent, color) ->
    super()
    @silentSetExtent(extent) if extent?
    @color = color if color?

    countValContent = {"content": @count, "signature": hashCode(@count + "")}
    @countVal = new GroundVal("countVal", countValContent, @)

    countOfRectangleKidsContent = {"content": 0, "signature": hashCode(0 + "")}

    functionToRecalculate = (argById, localArgByName, parentArgByName, childrenArgByName, childrenArgByNameCount) ->
        theCount = 0
        for allCounts of childrenArgByName["countVal"]
            theCount++

        console.log "recalculating the number of rectangles to: " + theCount

        return {
            "content": theCount,
            "signature": hashCode(theCount + "")
            }

    #constructor: (@valName, @functionToRecalculate, @localInputVals, parentArgsNames, childrenArgsNames, @ownerMorph)
    #debugger
    @countOfRectangleKids = new BasicCalculatedVal("countOfRectangleKids", functionToRecalculate, [], [], ["countVal"], @)

