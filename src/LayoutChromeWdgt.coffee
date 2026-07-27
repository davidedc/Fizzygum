# this file is excluded from the fizzygum homepage build

# Shared base for the small "layout-editing chrome" widgets -- the layout spacer
# (LayoutSpacerWdgt), the element adder/droplet (LayoutElementAdderOrDropletWdgt),
# and the stack-size adjuster (StackElementsSizeAdjustingWdgt). They only appear
# while layouts are being edited (so all three, and this base, are stripped from
# the homepage build), and they all paint identically: a solid background box in
# ACTUAL pixels, then a small glyph drawn in LOGICAL pixels with the origin
# translated to the widget position.
#
# That shared paint scaffold lives in LayoutChromeAppearance; each subclass
# supplies only its drawLayoutChrome tail. The spacer additionally toggles
# thisSpacerIsTransparent to skip painting entirely.
class LayoutChromeWdgt extends Widget

  thisSpacerIsTransparent: false

  constructor: ->
    super()
    @appearance = new LayoutChromeAppearance @

  # Layout-editing CHROME (the spacer, the element adder/droplet, the stack-size adjuster / divider) is
  # never editor content (§5.D D-3/D21). Clicking or dragging one to reshape a layout must NOT make it
  # world.editorFocusWdgt -- otherwise the editor-focus SELECTION overlay frames the chrome (it sits inside
  # the edited container's editing-amenity subtree, so the D21 walk would reach it). Same exemption as the
  # frame-bar chrome / handles / scrollbars; honored by ancestry at ActivePointerWdgt's focus-set sites.
  excludedFromEditorFocusTracking: -> true

  # The drawing tail: runs in logical pixels with the origin already translated
  # to the widget position. Default: the affordance drawn (with a darker drop
  # shadow) via spacerWidgetRenderingHelper -- which LayoutSpacerWdgt and
  # LayoutElementAdderOrDropletWdgt each supply. StackElementsSizeAdjustingWdgt
  # overrides this with its own inline glyph.
  drawLayoutChrome: (aContext) ->
    @spacerWidgetRenderingHelper aContext, Color.WHITE, Color.create 200, 200, 255
