class IconAppearance extends Appearance

  # preferredSize and specificationSize should be
  # in the same ratio
  preferredSize: new Point 200, 200

  # this is the dimension of the "original" canvas
  # that the actual code paints on.
  specificationSize: new Point 200, 200

  # Icon fill color as a string: the explicit ownColorInsteadOfWidgetColor if set,
  # otherwise the host widget's color. Subclass paintFunctions call this instead of
  # repeating the ownColorInsteadOfWidgetColor?-ternary inline (was copied ~64×).
  # _-tier: internal paint helper, only ever @-self-called from paintFunctions.
  _iconColorString: ->
    (@ownColorInsteadOfWidgetColor ? @widget.color).toString()

  # The system-wide icon outline color (from preferences).
  _outlineColorString: ->
    WorldWdgt.preferencesAndSettings.outlineColorString

  # default icon is a ring — one direct mid-radius stroke (see _paintButtonRing):
  # outer r 91.5, inner r 78.1 in specification space
  paintFunction: (context) ->
    context.strokeStyle = @color.toString()
    context.lineWidth = 13.4
    context.strokeCircle 100.5, 98.5, 84.8




  calculateRectangleOfIcon: ->
    height = @widget.height()
    width = @widget.width()

    scaleW = Math.abs(width / @preferredSize.width())
    scaleH = Math.abs(height / @preferredSize.height())


    # default: stretch
    # nothing to do


    # aspect fit
    scaleW = Math.min(scaleW, scaleH)
    scaleH = scaleW

    # aspect fill
    #scaleW = Math.max(scaleW, scaleH)
    #scaleH = scaleW

    # center
    #scaleW = 1
    #scaleH = 1

    result = new Rectangle(Math.min(0, @preferredSize.width()), Math.min(0, @preferredSize.height()), Math.abs(@preferredSize.width()), Math.abs(@preferredSize.height()))
    result2W = result.width() * scaleW
    result2H = result.height() * scaleH
    result2X = @widget.left() + (width - (result2W)) / 2
    result2Y = @widget.top() + (height - (result2H)) / 2

    result = new Rectangle result2X, result2Y, result2X + result2W, result2Y + result2H
    return result.round()

  widthWithoutSpacing: ->
    @calculateRectangleOfIcon().width()

  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return nil unless keyValues?
    [area,sl,st,al,at,w,h] = keyValues

    # the icon art (paintFunction) sets its own colours, so the shadow pass renders it to a
    # scratch and blits the black silhouette (the shadow-pass paint contract).
    if appliedShadow?
      @_paintDamagedAreaAsBlackSilhouette aContext, al, at, w, h, appliedShadow, (sctx) =>
        @_paintColoredIcon sctx, al, at, w, h
      return

    @_paintColoredIcon aContext, al, at, w, h

  _paintColoredIcon: (aContext, al, at, w, h) ->
    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = @widget.alpha

    aContext.useLogicalPixelsUntilRestore()

    result = @calculateRectangleOfIcon()


    aContext.translate(result.left(), result.top())
    aContext.scale(result.width() / @preferredSize.width(), result.height() / @preferredSize.height())
    aContext.scale(@preferredSize.width() / @specificationSize.width(), @preferredSize.height() / @specificationSize.height())

    ## at this point, you draw in a squareSize x squareSize
    ## canvas, and it gets painted in a square that fits
    ## the widget, right in the middle.
    @paintFunction aContext

    aContext.restore()

  oval: (context, x, y, w, h) ->
    context.save()
    context.beginPath()
    context.translate x, y
    context.scale w / 2, h / 2
    context.arc 1, 1, 1, 0, 2 * Math.PI
    context.closePath()
    context.restore()
    return

  # uses moveTos to create unconnected circles
  # (otherwise the arcs create a joint path)
  # basically does the equivalent of what context.rect does
  circle: (context, x, y, r) ->
    context.moveTo x, y
    context.arc x, y, r, 0, 2 * Math.PI

  arc: (context, x, y, w, h, startAngle, endAngle, isClosed) ->
    context.save()
    context.beginPath()
    context.translate x, y
    context.scale w / 2, h / 2
    context.arc 1, 1, 1, Math.PI / 180 * startAngle, Math.PI / 180 * endAngle
    if isClosed
      context.lineTo 1, 1
      context.closePath()
    context.restore()
    return

  # ---- shared icon frame primitives (pure code-motion from subclass paintFunctions) ----
  # These emit exactly the same context ops, in the same order, as the inline copies
  # they replace, so the rendered pixels are byte-identical. Where a subclass draws its
  # own content BETWEEN the two halves of a frame (e.g. SimpleSlide's card, the
  # scrolling/cropping window panels), the halves are split into two helpers so call
  # order is preserved.

  # (The bezier slide-card helpers that lived here served the SimpleSlide /
  # PatchProgramming / GenericPanel / Dashboards icons; that family now
  # draws through SizeAwareIconAppearance._pxSlideCard.)

  # The two window title-bar dots, shared by every window-chrome icon.
  _paintWindowTitleDots: (context, colorString) ->
    @oval context, 11, 11, 6, 6
    context.fillStyle = colorString
    context.fill()
    @oval context, 22, 11, 6, 6
    context.fillStyle = colorString
    context.fill()

  # The window frame: the title-bar underline plus the outer border rectangle.
  _paintWindowFrame: (context, colorString) ->
    context.beginPath()
    context.moveTo 5, 24
    context.lineTo 91, 24
    context.strokeStyle = colorString
    context.lineWidth = 4
    context.stroke()
    context.beginPath()
    context.rect 4, 4, 88, 88
    context.strokeStyle = colorString
    context.lineWidth = 3.5
    context.lineJoin = 'round'
    context.stroke()

  # The rounded-square badge (outer frame filled with the outline colour, plus the
  # inner rounded square with a hole filled with the icon colour). Shared by the
  # ShortcutArrow icon and the FanoutPin appearance; both draw it contiguously.
  _paintRoundedSquareBadge: (context, outlineColorString, iconColorString) ->
    context.beginPath()
    context.moveTo 81.16, 4
    context.lineTo 19.84, 4
    context.lineTo 19.84, 4
    context.bezierCurveTo 11.09, 4, 4, 11.09, 4, 19.84
    context.lineTo 4, 81.16
    context.lineTo 4, 81.16
    context.bezierCurveTo 4, 89.91, 11.09, 97, 19.84, 97
    context.lineTo 81.16, 97
    context.lineTo 81.16, 97
    context.bezierCurveTo 89.91, 97, 97, 89.91, 97, 81.16
    context.lineTo 97, 19.84
    context.lineTo 97, 19.84
    context.bezierCurveTo 97, 11.09, 89.91, 4, 81.16, 4
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    context.beginPath()
    context.moveTo 78.82, 7.72
    context.lineTo 22.83, 7.72
    context.lineTo 22.83, 7.72
    context.bezierCurveTo 14.84, 7.72, 8.37, 14.19, 8.37, 22.18
    context.lineTo 8.37, 78.17
    context.lineTo 8.37, 78.17
    context.bezierCurveTo 8.37, 86.16, 14.84, 92.63, 22.83, 92.63
    context.lineTo 78.82, 92.63
    context.lineTo 78.82, 92.63
    context.bezierCurveTo 86.81, 92.63, 93.28, 86.16, 93.28, 78.17
    context.lineTo 93.28, 22.18
    context.lineTo 93.28, 22.18
    context.bezierCurveTo 93.28, 14.19, 86.81, 7.72, 78.82, 7.72
    context.closePath()
    context.moveTo 85.39, 78.17
    context.lineTo 85.39, 78.17
    context.bezierCurveTo 85.39, 81.8, 82.45, 84.74, 78.82, 84.74
    context.lineTo 22.83, 84.74
    context.lineTo 22.83, 84.74
    context.bezierCurveTo 19.2, 84.74, 16.26, 81.8, 16.26, 78.17
    context.lineTo 16.26, 22.18
    context.lineTo 16.26, 22.18
    context.bezierCurveTo 16.26, 18.55, 19.2, 15.61, 22.83, 15.61
    context.lineTo 78.82, 15.61
    context.lineTo 78.82, 15.61
    context.bezierCurveTo 82.45, 15.61, 85.39, 18.55, 85.39, 22.18
    context.lineTo 85.39, 78.17
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()

  # The L-shaped plot axes glyph, shared by the Function / Scatter / Bar plot icons.
  _paintPlotAxes: (context, iconColorString) ->
    context.beginPath()
    context.moveTo 7, 8
    context.lineTo 11.25, 8
    context.lineTo 11.25, 88.76
    context.lineTo 92, 88.76
    context.lineTo 92, 93
    context.lineTo 7, 93
    context.lineTo 7, 8
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()

  # The palette swatch (gradient-filled background, bordered rectangle, picker line and
  # handle oval), shared by the Color/Grayscale palette icons — the gradient is the only
  # difference between them, so it is built by each subclass and passed in.
  _paintPaletteSwatch: (context, gradient, iconColorString) ->
    context.fillStyle = gradient
    context.fillRect 21, 19, 58, 63
    context.beginPath()
    context.rect 20.5, 17.5, 60, 66
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    context.beginPath()
    context.moveTo 81, 51
    context.lineTo 90, 51
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    @oval context, 88.5, 48, 6, 6
    context.fillStyle = iconColorString
    context.fill()

  # The concentric-circle button "ring" (an annulus), shared by the Close / Collapse /
  # Uncollapse title-bar button icons; each fills it from its own @widget.color.
  _paintButtonRing: (context, fillColor) ->
    # ONE direct mid-radius stroke: the thick-stroke path rasterizes the exact
    # analytic annulus [90.7−6.3, 90.7+6.3] = outer r 97, inner r 84.4 in the
    # 200×200 specification space. Safe under the icon transform because
    # calculateRectangleOfIcon aspect-fits to a square, so the paint scale is
    # always UNIFORM (a non-uniform scale would silently draw a wrong-radius
    # circle where an ellipse belongs).
    context.strokeStyle = fillColor.toString()
    context.lineWidth = 12.6
    context.strokeCircle 100.5, 99.5, 90.7


