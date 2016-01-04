# A small harness to run tests around reactive values.
# To run these, just open console and type
#   ReactiveValuesTests.runTests()

# REQUIRES ReactiveValuesTestsRectangleMorph

class ReactiveValuesTests
  @runTests: ->

    # create first rectangle
    firstReactValRect = new ReactiveValuesTestsRectangleMorph()
    if ProfilerData.reactiveValues_createdGroundVals != 1
      console.log "ERROR createdGroundVals should be 1 it's " +
        ProfilerData.reactiveValues_createdGroundVals
    if ProfilerData.reactiveValues_createdBasicCalculatedValues != 1
      console.log "ERROR createdBasicCalculatedValues should be 1 it's " +
        ProfilerData.reactiveValues_createdBasicCalculatedValues
    firstReactValRect.fullRawMoveTo new Point 10, 10
    world.add firstReactValRect

    # create second rectangle, slightly displaced to verlap
    secondReactValRect = new ReactiveValuesTestsRectangleMorph()
    if ProfilerData.reactiveValues_createdGroundVals != 2
      console.log "ERROR createdGroundVals should be 2 it's " +
        ProfilerData.reactiveValues_createdGroundVals
    if ProfilerData.reactiveValues_createdBasicCalculatedValues != 2
      console.log "ERROR createdBasicCalculatedValues should be 2 it's " +
        ProfilerData.reactiveValues_createdBasicCalculatedValues
    secondReactValRect.fullRawMoveTo new Point 40, 40
    world.add secondReactValRect

    if firstReactValRect.countOfDirectRectangleChildren.lastCalculatedValContentMaybeOutdated != true
      console.log "ERROR firstReactValRect.countOfDirectRectangleChildren should be dirty and it isn't"

    # now attach the second rectangle to the first
    firstReactValRect.add secondReactValRect

    if firstReactValRect.countOfDirectRectangleChildren.lastCalculatedValContentMaybeOutdated != true
      console.log "ERROR firstReactValRect.countOfDirectRectangleChildren should be dirty and it isn't"

    # now fetch the value of countOfDirectRectangleChildren in the
    # first rectangle
    firstReactValRect.countOfDirectRectangleChildren.fetchVal()

    if firstReactValRect.countOfDirectRectangleChildren.lastCalculatedValContentMaybeOutdated != false
      console.log "ERROR firstReactValRect.countOfDirectRectangleChildren should be clean and it isn't"

    if firstReactValRect.countOfDirectRectangleChildren.lastCalculatedValContent.content != 1
      console.log "ERROR firstReactValRect.countOfDirectRectangleChildren should contain 1 and it doesn't"

    
