class BubblyAppearance extends BoxyAppearance

  # No constructor: the meta-compiler synthesises a forward-everything one for a class
  # without its own — `__super__.constructor.apply this, arguments` plus
  # `registerThisInstance?()` (meta/Class.coffee) — equivalent to the explicit
  # `(widget) -> super widget` this would otherwise need (both call sites pass one
  # argument). Dedup case law: docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md.

  # The bubble outline (rounded box + tail spike) is not a roundRect, so unlike
  # BoxyAppearance both of these paint through the generic path pipeline. Fill
  # and stroke share the one path — this outline never applied the boxy
  # half-pixel stroke displacement.
  fillOutline: (context) ->
    context.beginPath()
    @outlinePath context, @getCornerRadius()
    context.closePath()
    context.fill()

  strokeOutline: (context) ->
    context.beginPath()
    @outlinePath context, @getCornerRadius()
    context.closePath()
    context.stroke()

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
