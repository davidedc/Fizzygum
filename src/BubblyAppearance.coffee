class BubblyAppearance extends BoxyAppearance

  # No constructor: the meta-compiler synthesises a forward-everything one for a class
  # without its own — `__super__.constructor.apply this, arguments` plus
  # `registerThisInstance?()` (meta/Class.coffee) — equivalent to the explicit
  # `(widget) -> super widget` this would otherwise need (both call sites pass one
  # argument). Dedup case law: docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md.

  # ===== the two shape answers, because my OUTLINE is not my superclass's =====
  # My rounded body occupies only the top (h - h/5) of the box; the bottom fifth is the tail
  # strip, empty except for the spike itself.
  #
  # ⛔ opaqueCoveredRect MUST be undefined, not inherited. BoxyAppearance claims
  # `boundingBox().insetBy cornerRadius + 1`, whose bottom edge sits BELOW my body for any
  # bubble taller than about 5×(cornerRadius+1) — the occlusion culler would then skip
  # everything behind that strip and drop real pixels there. A ToolTipWdgt is a direct child
  # of the world, so it is asked.
  opaqueCoveredRect: ->
    undefined

  # shapeContainsPoint is deliberately NOT overridden: I inherit BoxyAppearance's rounded-box
  # test, which OVER-claims the tail strip (a click in the empty corner beside the spike stops
  # on the bubble instead of falling through). Harmless today — bubbles and tooltips are not
  # things you click past — and correcting it means an analytic body+spike test, which is a
  # behaviour change, not a rename. Named here so it is a known approximation, not a silence.

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
