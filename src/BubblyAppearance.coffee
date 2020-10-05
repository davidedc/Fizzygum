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
    context.arc padding, padding, radius, (-180).toRadians(), (-90).toRadians()

    # top right:
    context.arc w - padding, padding, radius, (-90).toRadians(), (-0).toRadians()

    # bottom right:
    context.arc w - padding, h - spikeHeight - radius, radius, (0).toRadians(), (90).toRadians()

    # line from bottom right corner to the edge of the spike going down
    context.lineTo padding + radius + spikeDistanceFromClosestSide, h - spikeHeight

    # spike line going down
    context.lineTo padding, h

    # bottom left:
    context.arc padding, h - spikeHeight - radius, radius, (90).toRadians(), (180).toRadians()
