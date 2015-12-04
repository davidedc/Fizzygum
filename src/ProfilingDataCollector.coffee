# Data collected at run time ///////////////////////////////////


class ProfilingDataCollector

  # Overall profiling flags #########################

  @overallProfilingEnabled: false

  @enableProfiling: ->
    @overallProfilingEnabled = true
  @disableProfiling: ->
    @overallProfilingEnabled = false

  # Broken rectangles ###############################

  @brokenRectsProfilingEnabled: false
  @shortSessionCumulativeNumberOfBrokenRects: 0
  @overallSessionCumulativeNumberOfBrokenRects: 0
  @shortSessionMaxNumberOfBrokenRects: 0
  @overallSessionMaxNumberOfBrokenRects: 0
  @shortSessionCumulativeTotalAreaOfBrokenRects: 0
  @overallSessionCumulativeTotalAreaOfBrokenRects: 0
  @shortSessionMaxTotalAreaOfBrokenRects: 0
  @overallSessionMaxTotalAreaOfBrokenRects: 0

  @shortSessionCumulativeNumberOfAllocatedCanvases: 0
  @shortSessionMaxNumberOfAllocatedCanvases: 0

  @shortSessionCumulativeSizeOfAllocatedCanvases: 0

  @shortSessionCumulativeNumberOfBlitOperations: 0
  @shortSessionMaxNumberOfBlits: 0

  @shortSessionCumulativeAreaOfBlits: 0
  @shortSessionMaxAreaOfBlits: 0

  @shortSessionBiggestBlitArea: 0

  @shortSessionCumulativeTimeSpentRedrawing: 0
  @shortSessionMaxTimeSpentRedrawing: 0

  

  # Broken rectangles ###############################

  @enableBrokenRectsProfiling: ->
    @overallProfilingEnabled = true
    @brokenRectsProfilingEnabled = true
  @disableBrokenRectsProfiling: ->
    @brokenRectsProfilingEnabled = false

  @profileBrokenRects: (brokenRectsArray) ->
    if !@overallProfilingEnabled or !@brokenRectsProfilingEnabled
      return

    numberOfBrokenRects = brokenRectsArray.length

    @shortSessionCumulativeNumberOfBrokenRects += \
      numberOfBrokenRects
    if numberOfBrokenRects > \
    @shortSessionMaxNumberOfBrokenRects
      @shortSessionMaxNumberOfBrokenRects =
        numberOfBrokenRects

    @overallSessionCumulativeNumberOfBrokenRects += \
      numberOfBrokenRects
    if numberOfBrokenRects > \
    @overallSessionMaxNumberOfBrokenRects
      @overallSessionMaxNumberOfBrokenRects =
        numberOfBrokenRects

    totalAreaOfBrokenRects = 0
    for eachRect in brokenRectsArray
      totalAreaOfBrokenRects += eachRect.area()

    @shortSessionCumulativeTotalAreaOfBrokenRects += \
      totalAreaOfBrokenRects
    @overallSessionCumulativeTotalAreaOfBrokenRects += \
      totalAreaOfBrokenRects
    if totalAreaOfBrokenRects > \
    @shortSessionMaxTotalAreaOfBrokenRects
      @shortSessionMaxTotalAreaOfBrokenRects =
        totalAreaOfBrokenRects
    if totalAreaOfBrokenRects > \
    @overallSessionMaxTotalAreaOfBrokenRects
      @overallSessionMaxTotalAreaOfBrokenRects =
        totalAreaOfBrokenRects


