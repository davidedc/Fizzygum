# Data collected at run time ///////////////////////////////////


class ProfilingDataCollector

  # Overall profiling flags -----------------------------

  @overallProfilingEnabled: false

  @enableProfiling: ->
    @overallProfilingEnabled = true
  @disableProfiling: ->
    @overallProfilingEnabled = false

  # Broken rectangles -----------------------------

  @brokenRectsProfilingEnabled: false
  @shortSessionCumulativeNumberOfBrokenRects: 0
  @overallSessionCumulativeNumberOfBrokenRects: 0
  @shortSessionMaxNumberOfBrokenRects: 0
  @overallSessionMaxNumberOfBrokenRects: 0
  @shortSessionCumulativeTotalAreaOfBrokenRects: 0
  @overallSessionCumulativeTotalAreaOfBrokenRects: 0
  @shortSessionMaxTotalAreaOfBrokenRects: 0
  @overallSessionMaxTotalAreaOfBrokenRects: 0
  @shortSessionCumulativeDuplicatedBrokenRects: 0
  @overallSessionCumulativeDuplicatedBrokenRects: 0
  @shortSessionMaxDuplicatedBrokenRects: 0
  @overallSessionMaxDuplicatedBrokenRects: 0
  @shortSessionCumulativeMergedSourceAndDestination: 0
  @overallSessionCumulativeMergedSourceAndDestination: 0
  @shortSessionMaxMergedSourceAndDestination: 0
  @overallSessionMaxMergedSourceAndDestination: 0

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

  

  # Broken rectangles -----------------------------

  @enableBrokenRectsProfiling: ->
    @overallProfilingEnabled = true
    @brokenRectsProfilingEnabled = true
  @disableBrokenRectsProfiling: ->
    @brokenRectsProfilingEnabled = false

  @profileBrokenRects: (brokenRectsArray, numberOfDuplicatedBrokenRects, numberOfMergedSourceAndDestination) ->
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
      if eachRect?
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

    @shortSessionCumulativeDuplicatedBrokenRects += \
      numberOfDuplicatedBrokenRects
    @overallSessionCumulativeDuplicatedBrokenRects += \
      numberOfDuplicatedBrokenRects
    if numberOfDuplicatedBrokenRects > \
    @shortSessionMaxDuplicatedBrokenRects
      @shortSessionMaxDuplicatedBrokenRects =
        numberOfDuplicatedBrokenRects
    if numberOfDuplicatedBrokenRects > \
    @overallSessionMaxDuplicatedBrokenRects
      @overallSessionMaxDuplicatedBrokenRects =
        numberOfDuplicatedBrokenRects

    @shortSessionCumulativeMergedSourceAndDestination += \
      numberOfMergedSourceAndDestination
    @overallSessionCumulativeMergedSourceAndDestination += \
      numberOfMergedSourceAndDestination
    if numberOfMergedSourceAndDestination > \
    @shortSessionMaxMergedSourceAndDestination
      @shortSessionMaxMergedSourceAndDestination =
        numberOfMergedSourceAndDestination
    if numberOfMergedSourceAndDestination > \
    @overallSessionMaxMergedSourceAndDestination
      @overallSessionMaxMergedSourceAndDestination =
        numberOfMergedSourceAndDestination


