# Paints the PenWdgt TURTLE itself (the arrow/dart pointing along @widget.heading,
# white-then-black stroked and filled with the widget colour) — NOT the graphics the
# pen draws, which land on the canvas the pen is attached to.

class PenAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, undefined, (ctx) =>
      direction = @widget.heading
      len = @widget.width() / 2
      start = @widget.center().subtract(@widget.position())

      if @widget.penPoint is "tip"
        dest = start.distanceAngle(len * 0.75, direction - 180)
        left = start.distanceAngle(len, direction + 195)
        right = start.distanceAngle(len, direction - 195)
      else # 'middle'
        dest = start.distanceAngle(len * 0.75, direction)
        left = start.distanceAngle(len * 0.33, direction + 230)
        right = start.distanceAngle(len * 0.33, direction - 230)

      # Shadow-pass paint contract (Widget.coffee "How the shadow painting works"): the
      # dart's shadow is its black-filled shape; the white/black legibility outline is
      # skipped like every stroke under appliedShadow (the Boxy precedent).
      fillColor = if appliedShadow? then Color.BLACK else @widget.color
      ctx.fillStyle = fillColor.toString()
      ctx.beginPath()

      ctx.moveTo start.x, start.y
      ctx.lineTo left.x, left.y
      ctx.lineTo dest.x, dest.y
      ctx.lineTo right.x, right.y

      ctx.closePath()
      if !appliedShadow?
        ctx.strokeStyle = Color.WHITE.toString()
        ctx.lineWidth = 3
        ctx.stroke()
        ctx.strokeStyle = Color.BLACK.toString()
        ctx.lineWidth = 1
        ctx.stroke()
      ctx.fill()
