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

  # default icon is a circle
  paintFunction: (context) ->
    fillColor = @color
    context.beginPath()
    context.moveTo 100.5, 7
    context.bezierCurveTo 50.05, 7, 9, 48.04, 9, 98.5
    context.bezierCurveTo 9, 148.95, 50.05, 190, 100.5, 190
    context.bezierCurveTo 150.95, 190, 192, 148.95, 192, 98.5
    context.bezierCurveTo 192, 48.04, 150.95, 7, 100.5, 7
    context.closePath()
    context.moveTo 100.5, 20.39
    context.bezierCurveTo 143.72, 20.39, 178.61, 55.28, 178.61, 98.5
    context.bezierCurveTo 178.61, 141.72, 143.72, 176.61, 100.5, 176.61
    context.bezierCurveTo 57.28, 176.61, 22.39, 141.72, 22.39, 98.5
    context.bezierCurveTo 22.39, 55.28, 57.28, 20.39, 100.5, 20.39
    context.closePath()
    context.fillStyle = fillColor.toString()
    context.fill()




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

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.alpha

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

    # paintHighlight is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    #@paintHighlight aContext, al, at, w, h

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

  # The outer rounded "slide card" rectangle, filled with the outline colour. Shared by
  # the SimpleSlide / PatchProgramming / GenericPanel / Dashboards icons.
  _paintSlideOutline: (context, outlineColorString) ->
    context.beginPath()
    context.moveTo 87.54, 18
    context.lineTo 13.57, 18
    context.bezierCurveTo 10.05, 18, 7.12, 20.67, 7.12, 23.87
    context.lineTo 7, 76.13
    context.bezierCurveTo 7, 79.33, 9.94, 82, 13.46, 82
    context.lineTo 87.43, 82
    context.bezierCurveTo 90.95, 82, 93.88, 79.33, 93.88, 76.13
    context.lineTo 94, 23.87
    context.bezierCurveTo 94, 20.67, 91.06, 18, 87.54, 18
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()

  # The inner rounded card (with the border hole), filled with the icon colour. Shared
  # by the same four slide/panel/dashboard/patch icons.
  _paintSlideCard: (context, iconColorString) ->
    context.beginPath()
    context.moveTo 85.84, 20
    context.lineTo 15.27, 20
    context.bezierCurveTo 11.91, 20, 9.11, 22.5, 9.11, 25.5
    context.lineTo 9, 74.5
    context.bezierCurveTo 9, 77.5, 11.8, 80, 15.16, 80
    context.lineTo 85.73, 80
    context.bezierCurveTo 89.09, 80, 91.89, 77.5, 91.89, 74.5
    context.lineTo 92, 25.5
    context.bezierCurveTo 92, 22.5, 89.2, 20, 85.84, 20
    context.closePath()
    context.moveTo 88.53, 74.5
    context.bezierCurveTo 88.53, 75.9, 87.3, 77, 85.73, 77
    context.lineTo 15.16, 77
    context.bezierCurveTo 13.59, 77, 12.36, 75.9, 12.36, 74.5
    context.lineTo 12.47, 25.5
    context.bezierCurveTo 12.47, 24.1, 13.7, 23, 15.27, 23
    context.lineTo 85.84, 23
    context.bezierCurveTo 87.41, 23, 88.64, 24.1, 88.64, 25.5
    context.lineTo 88.53, 74.5
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()

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
    context.beginPath()
    context.rect 21, 19, 58, 63
    context.fillStyle = gradient
    context.fill()
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
    context.beginPath()
    context.moveTo 100.5, 196.5
    context.bezierCurveTo 153.91, 196.5, 197.5, 152.91, 197.5, 99.5
    context.bezierCurveTo 197.5, 46.09, 153.91, 2.5, 100.5, 2.5
    context.bezierCurveTo 47.09, 2.5, 3.5, 46.09, 3.5, 99.5
    context.bezierCurveTo 3.5, 152.91, 47.09, 196.5, 100.5, 196.5
    context.closePath()
    context.moveTo 100.5, 15.1
    context.bezierCurveTo 147.11, 15.1, 184.9, 52.89, 184.9, 99.5
    context.bezierCurveTo 184.9, 146.11, 147.11, 183.9, 100.5, 183.9
    context.bezierCurveTo 53.89, 183.9, 16.1, 146.11, 16.1, 99.5
    context.bezierCurveTo 16.1, 52.89, 53.89, 15.1, 100.5, 15.1
    context.closePath()
    context.fillStyle = fillColor.toString()
    context.fill()


