class DesktopAppearance extends RectangularAppearance

  # Serialization: skip these on a whole-world snapshot. `pattern` is a live CanvasPattern
  # (the first thing a whole-world serialize used to crash on); both re-derive on demand
  # from world.wallpaper.patternName. See docs/architecture/serialization-duplication-reference.md §5.
  @serializationTransients: ["pattern", "currentPattern"]

  currentPattern: undefined

  # The desktop paints exactly like a plain rectangular widget PLUS a repeating wallpaper tile behind it.
  # Rather than re-copy RectangularAppearance::paintIntoAreaOrBlitFromBackBuffer (which it used to reproduce
  # line-for-line — the single most dangerous clone in the codebase, since a fix to the rectangular paint
  # silently skipped the desktop), it hooks into the two soft `?`-call sites the base paint offers:
  #   _setUpBackgroundPattern     — after the preliminaryCheckNothingToDraw guard, before the size guard
  #   _paintBackgroundPatternFill — after paintStroke, once the logical-pixels scope has closed
  #                                 (device-space — see the override below for why)
  # Op order is therefore identical to the old inlined method.

  # build (once per pattern change) the 5×5 wallpaper tile and turn it into a repeating CanvasPattern
  _setUpBackgroundPattern: (aContext) ->

    if @widget.wallpaper.patternName? && @widget.wallpaper.patternName == @widget.wallpaper.pattern1
      @currentPattern = @widget.wallpaper.patternName
      @pattern = undefined

    if @widget.wallpaper.patternName? && @widget.wallpaper.patternName != @currentPattern
      @currentPattern = @widget.wallpaper.patternName
      # go through the factory so the pattern tile honours the backend switch
      @pattern = HTMLCanvasElement.createOfPhysicalDimensions new Point 5 * ceilPixelRatio, 5 * ceilPixelRatio
      pctx = @pattern.getContext "2d"
      pctx.useLogicalPixelsUntilRestore()

      switch @widget.wallpaper.patternName
        when @widget.wallpaper.pattern2
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.lineWidth = 0.25
          pctx.beginPath()
          pctx.arc 2,2,2,0,2*Math.PI
          pctx.fillStyle = 'rgb(220, 219, 220)'
          pctx.fill()
        when @widget.wallpaper.pattern3
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 1,0
          pctx.lineTo 1,5
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()
        when @widget.wallpaper.pattern4
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 0,5
          pctx.lineTo 5,0
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()
        when @widget.wallpaper.pattern5
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 2,2
          pctx.lineTo 4,4
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()
        when @widget.wallpaper.pattern6
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 0,0
          pctx.lineTo 3,3
          pctx.lineTo 5,0
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()
        when @widget.wallpaper.pattern7
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 0,5
          pctx.lineTo 5,0
          pctx.moveTo 2.5,2.5
          pctx.lineTo 0,0
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()


      @pattern = aContext.createPattern(@pattern, 'repeat')

  # fill the built pattern over the just-painted rectangle. DEVICE-space by declaration (the
  # appearance paint convention's blit/pattern exception): a CanvasPattern anchors to the
  # coordinate space, so under the logical-pixels scope's CTM the 5-device-px tile would scale
  # with the dpr and its phase would follow the translate — the base paint therefore calls this
  # hook AFTER the scope closes, in device pixels (its old epilogue position; the desktop sits
  # at the origin, so the phase is unchanged there anyway).
  _paintBackgroundPatternFill: (aContext, toBePainted, appliedShadow) ->
    if @pattern?
      aContext.save()
      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.alpha
      aContext.fillStyle = @pattern
      aContext.fillRect toBePainted.left(), toBePainted.top(), toBePainted.width(), toBePainted.height()
      aContext.restore()
