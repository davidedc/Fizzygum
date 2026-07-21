# this file is excluded from the fizzygum homepage build

# Shared base for the small "layout-editing chrome" widgets -- the layout spacer
# (LayoutSpacerWdgt), the element adder/droplet (LayoutElementAdderOrDropletWdgt),
# and the stack-size adjuster (StackElementsSizeAdjustingWdgt). They only appear
# while layouts are being edited (so all three, and this base, are stripped from
# the homepage build), and they all paint identically: a solid background box in
# ACTUAL pixels, then a small glyph drawn in LOGICAL pixels with the origin
# translated to the widget position.
#
# That shared paint scaffold lives here; each subclass supplies only its
# drawLayoutChrome tail. The spacer additionally toggles thisSpacerIsTransparent
# to skip painting entirely.
class LayoutChromeWdgt extends Widget

  thisSpacerIsTransparent: false

  # Layout-editing CHROME (the spacer, the element adder/droplet, the stack-size adjuster / divider) is
  # never editor content (§5.D D-3/D21). Clicking or dragging one to reshape a layout must NOT make it
  # world.editorFocusWdgt -- otherwise the editor-focus SELECTION overlay frames the chrome (it sits inside
  # the edited container's editing-amenity subtree, so the D21 walk would reach it). Same exemption as the
  # frame-bar chrome / handles / scrollbars; honored by ancestry at ActivePointerWdgt's focus-set sites.
  excludedFromEditorFocusTracking: -> true

  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @thisSpacerIsTransparent
      return

    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

    # paintRectangle here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called before the scaling.
    @paintRectangle aContext, al, at, w, h, @color
    aContext.useLogicalPixelsUntilRestore()

    widgetPosition = @position()
    aContext.translate widgetPosition.x, widgetPosition.y

    @drawLayoutChrome aContext

    aContext.restore()

    # _drawHighlightOverlay is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @_drawHighlightOverlay aContext, al, at, w, h

  # The drawing tail: runs in logical pixels with the origin already translated
  # to the widget position. Default: the affordance drawn (with a darker drop
  # shadow) via spacerWidgetRenderingHelper -- which LayoutSpacerWdgt and
  # LayoutElementAdderOrDropletWdgt each supply. StackElementsSizeAdjustingWdgt
  # overrides this with its own inline glyph.
  drawLayoutChrome: (aContext) ->
    @spacerWidgetRenderingHelper aContext, Color.WHITE, Color.create 200, 200, 255
