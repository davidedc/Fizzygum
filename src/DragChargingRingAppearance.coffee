# Paints the drag-embed CHARGING RING (docs/specs/drag-embed-interaction-spec.md §6/§11): a small
# cursor-anchored ring of dwellRingSteps arc segments. The first @widget.chargeStep segments are drawn
# in the accent (filled) colour, the rest faint — a radial progress readout of the dwell-to-arm charge.
# PRESENTATION ONLY: the arm DECISION is the hand's event-time elapsed check; this never feeds it.
# The fill amount is STATE computed in DragChargingRingWdgt.updateChargeDeclaration (paint stays read-only).

class DragChargingRingAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # an ephemeral overlay casts no shadow — nothing to draw on the shadow pass
    return nil if appliedShadow?

    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil

    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()
    aContext.clipToRectangle al, at, w, h
    aContext.globalAlpha = @widget.alpha
    aContext.useLogicalPixelsUntilRestore()
    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y

    cx = @widget.width() / 2
    cy = @widget.height() / 2
    radius = Math.min(cx, cy) - 2
    steps = @widget.ringSteps
    filled = @widget.chargeStep
    seg = 2 * Math.PI / steps
    gap = seg * 0.18                    # a small gap between segments so they read as discrete

    aContext.lineWidth = 3
    aContext.lineCap = "butt"
    for i in [0...steps]
      startAngle = -Math.PI / 2 + i * seg + gap / 2
      endAngle   = -Math.PI / 2 + (i + 1) * seg - gap / 2
      aContext.beginPath()
      aContext.arc cx, cy, radius, startAngle, endAngle
      aContext.strokeStyle = (if i < filled then @widget.filledColor else @widget.emptyColor).toString()
      aContext.stroke()

    aContext.restore()

    @paintHighlight aContext, al, at, w, h
