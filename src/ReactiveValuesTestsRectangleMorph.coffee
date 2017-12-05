# ReactiveValuesTestsRectangleMorph /////////////////////////////////


class ReactiveValuesTestsRectangleMorph extends Morph

  count: 1
  countVal: nil
  countOfDirectRectangleChildren: nil

  constructor: (extent, color) ->
    super()
    @silentRawSetExtent(extent) if extent?
    @color = color if color?

    countValContent = {"content": @count, "signature": hashCode @count + "" }
    @countVal = new GroundVal("countVal", countValContent, @)

    countOfDirectRectangleChildrenContent = {"content": 0, "signature": hashCode 0 + "" }

    functionToRecalculate = (argById, localArgByName, parentArgByName, childrenArgByName, childrenArgByNameCount) ->
        theCount = 0
        for allCounts of childrenArgByName["countVal"]
            theCount++

        console.log "recalculating the number of rectangles to: " + theCount

        return {
            "content": theCount,
            "signature": hashCode theCount + ""
            }

    #constructor: (@valName, @functionToRecalculate, @localInputVals, parentArgsNames, childrenArgsNames, @ownerMorph)
    #debugger
    @countOfDirectRectangleChildren = new BasicCalculatedVal("countOfDirectRectangleChildren", functionToRecalculate, [], [], ["countVal"], @)

