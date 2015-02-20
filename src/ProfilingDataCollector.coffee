# Data collected at run time ///////////////////////////////////


class ProfilingDataCollector

  @shortSessionCumulativeNumberOfBrokenRects: 0
  @shortSessionMaxNumberOfBrokenRects: 0

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
  

  @profileBrokenRects: (numberOfBrokenRects) ->
    @shortSessionCumulativeNumberOfBrokenRects += \
      numberOfBrokenRects
    if numberOfBrokenRects > \
    @shortSessionMaxNumberOfBrokenRects
      @shortSessionMaxNumberOfBrokenRects =
        numberOfBrokenRects
