class BubblyAppearance extends BoxyAppearance

  # No constructor: it was `(widget) -> super widget`, byte-identical to BoxyAppearance's, and the
  # meta-compiler synthesises exactly that for a class without one — `__super__.constructor.apply this,
  # arguments` plus `registerThisInstance?()` (meta/Class.coffee, the `else` branch of the
  # `hasOwnProperty('constructor')` test, which is also what _addInstancesTracker injects into an
  # explicit one). 286 of 455 classes already rely on that path, including 4 of the 8 Appearance-family
  # classes. Both call sites pass one argument (`new BubblyAppearance @`), so the synthesised
  # forward-everything is equivalent to the explicit forward-one anyway.

  outlinePath: (context, radius) ->

    padding = radius
    w = @widget.width()
    h = @widget.height()

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
