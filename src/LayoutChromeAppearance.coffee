# Paints the layout-editing chrome family (LayoutSpacerWdgt,
# LayoutElementAdderOrDropletWdgt, StackElementsSizeAdjustingWdgt): a solid
# background box over the damage area, then the widget's own drawLayoutChrome
# glyph tail — all in widget-local LOGICAL pixels through the ctx matrix.
# The glyph tails stay subclass-polymorphic on the widgets; a transparent spacer
# (thisSpacerIsTransparent) paints nothing at all.

class LayoutChromeAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @widget.thisSpacerIsTransparent
      return

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localArea) =>
      # Shadow-pass paint contract (Widget.coffee "How the shadow painting works"): the box
      # is opaque, so its BLACK version is the complete silhouette — the chrome art drawn
      # inside it adds no coverage and is skipped, like the hover highlight (not ink).
      boxColor = if appliedShadow? then Color.BLACK else @widget.color
      if boxColor?
        ctx.fillStyle = boxColor.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, localArea

      if !appliedShadow?
        @widget.drawLayoutChrome ctx
