class BubblyAppearance extends BoxyAppearance

  constructor: (morph) ->
    super morph

  outlinePath: (context, radius) ->
    # console.log "bubble outlinePath"

    padding = radius
    w = @morph.width()
    h = @morph.height()

    spikeHeight = h/5
    spikeDistanceFromClosestSide = h/5

    # outline drawn from top left corner, clockwise

    # top left:
    context.arc padding, padding, radius, degreesToRadians(-180), degreesToRadians(-90)

    # top right:
    context.arc w - padding, padding, radius, degreesToRadians(-90), degreesToRadians(-0)

    # bottom right:
    context.arc w - padding, h - spikeHeight - radius, radius, degreesToRadians(0), degreesToRadians(90)

    # line from bottom right corner to the edge of the spike going down
    context.lineTo padding + radius + spikeDistanceFromClosestSide, h - spikeHeight

    # spike line going down
    context.lineTo padding, h

    # bottom left:
    context.arc padding, h - spikeHeight - radius, radius, degreesToRadians(90), degreesToRadians(180)
