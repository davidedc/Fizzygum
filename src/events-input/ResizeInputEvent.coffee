# see https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent
class ResizeInputEvent extends InputEvent

  @fromBrowserEvent: (event, isSynthetic, time) ->
    new @()

  processEvent: ->
    #console.log "processing resize"
    if world.automaticallyAdjustToFillEntireBrowserAlsoOnResize
      world.stretchWorldToFillEntirePage()
