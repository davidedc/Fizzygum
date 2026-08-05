# Shared base for the small "layout-editing chrome" widgets -- the layout spacer
# (LayoutSpacerWdgt), the element adder/droplet (LayoutElementAdderOrDropletWdgt),
# and the stack-size adjuster (StackElementsSizeAdjustingWdgt). They all paint
# identically: a solid background box in ACTUAL pixels, then a small glyph drawn
# in LOGICAL pixels with the origin translated to the widget position.
#
# The stack-size adjuster is the one of the three that is NOT layout-editing-only:
# the halo's resize/move affordance inserts it between division siblings on their
# division axis -- either axis; the adjuster reads it off the neighbouring cell's spec
# (Widget._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle) -- which is reachable
# from the base widget context menu in every build, so it and this base ship in core.
# The spacer and the adder/droplet appear only while layouts are being edited: they
# live in the LAZY 'authoring' part, product-reachable via "edit layout" on a division
# container's context menu (Widget.editLayout awaits the part).
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

  # Capability query (duck-typed at the call sites): am I layout-editing chrome? A divider
  # IS a division cell, and the adder/droplet/spacer carry division boxes too — but their
  # boxes are machinery working state, not user knobs, so the widget menu gate uses this to
  # withhold the division-cell spec submenu from all three.
  isLayoutChrome: -> true

  # The drawing tail: runs in logical pixels with the origin already translated
  # to the widget position. Default: the affordance drawn (with a darker drop
  # shadow) via spacerWidgetRenderingHelper -- which LayoutSpacerWdgt and
  # LayoutElementAdderOrDropletWdgt each supply. StackElementsSizeAdjustingWdgt
  # overrides this with its own inline glyph.
  drawLayoutChrome: (aContext) ->
    @spacerWidgetRenderingHelper aContext, Color.WHITE, Color.create 200, 200, 255
