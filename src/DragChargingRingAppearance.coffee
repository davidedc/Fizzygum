# Paints the drag-embed CHARGING RING (docs/specs/drag-embed-interaction-spec.md §6/§11): a small
# cursor-anchored ring of dwellRingSteps arc segments. The first @widget.chargeStep segments are drawn
# in the accent (filled) colour, the rest faint — a radial progress readout of the dwell-to-arm charge.
# PRESENTATION ONLY: the arm DECISION is the hand's event-time elapsed check; this never feeds it.
# The fill amount is STATE computed in DragChargingRingWdgt.updateChargeDeclaration (paint stays read-only).

class DragChargingRingAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # an ephemeral overlay casts no shadow — nothing to draw on the shadow pass
    return undefined if appliedShadow?

    # (the scope's default alpha reduces to plain @widget.alpha here — no shadow pass reaches this)
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      cx = @widget.width() / 2
      cy = @widget.height() / 2
      radius = Math.min(cx, cy) - 2
      steps = @widget.ringSteps
      filled = @widget.chargeStep
      seg = 2 * Math.PI / steps
      gap = seg * 0.18                    # a small gap between segments so they read as discrete

      ctx.lineWidth = 3
      ctx.lineCap = "butt"
      for i in [0...steps]
        startAngle = -Math.PI / 2 + i * seg + gap / 2
        endAngle   = -Math.PI / 2 + (i + 1) * seg - gap / 2
        ctx.beginPath()
        ctx.arc cx, cy, radius, startAngle, endAngle
        ctx.strokeStyle = (if i < filled then @widget.filledColor else @widget.emptyColor).toString()
        ctx.stroke()
      return
