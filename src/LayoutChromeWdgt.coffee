# Shared base for the small "layout-editing chrome" widgets -- the layout spacer
# (LayoutSpacerWdgt), the element adder/droplet (LayoutElementAdderOrDropletWdgt),
# and the stack-size adjuster (StackElementsSizeAdjustingWdgt). They all wear the
# handles' look (LayoutChromeAppearance): the layoutChromePlate* plate over the
# whole box, in the look of my pointer state (below), and each subclass's mark on
# it (its glyph, _glyphOnMyPlate, or its drawLayoutChrome tail).
#
# The stack-size adjuster is the one of the three that is NOT layout-editing-only:
# the halo's resize/move affordance inserts it between division siblings on their
# division axis -- either axis; the adjuster reads it off the neighbouring cell's spec
# (Widget._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle) -- which is reachable
# from the base widget context menu in every build, so it and this base ship in core.
# The spacer and the adder/droplet appear only while layouts are being edited: they
# live in the LAZY 'authoring' part, product-reachable via "Edit layout" on a division
# container's context menu (Widget.editLayout awaits the part).
#
# The spacer additionally toggles thisSpacerIsTransparent to skip painting entirely.
class LayoutChromeWdgt extends Widget

  thisSpacerIsTransparent: false

  # MY POINTER STATE is the hand's, as a handle's is (HandleWdgt), asked as I am painted and kept
  # nowhere (_plateFillForMyState): pressed while the hand presses me (ActivePointerWdgt.pressesOn)
  # where a press shows on my plate (_showsPressOnMyPlate), hovered while the pointer rests on me
  # (restsOn: never a finger, so a finger carrying a payload over a drop slot does not light it), at
  # rest otherwise. So my look after a gesture is a function of where the gesture left the pointer
  # and me.

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

  # The drawing tail: runs in logical pixels with the origin already translated to my position,
  # over my plate, in the normal pass only. Default: nothing -- StackElementsSizeAdjustingWdgt draws
  # its grab mark here.
  drawLayoutChrome: (aContext) ->

  # THE GLYPH ON MY PLATE, which my appearance paints centred over it in the normal pass: [the
  # size-aware icon appearance that draws it, in layoutChromeGlyph, and the side of its square], or []
  # for none. Built for each paint, as the handles' glyphs are, so no ink is saved or copied with me.
  # Default: none -- the adder's plus and the spacer's double arrow answer here.
  _glyphOnMyPlate: -> []

  # Whether a press on me shows on my plate: it does on what a press acts on (an adder adds a slot, an
  # adjuster drags its split); a spacer answers no.
  _showsPressOnMyPlate: -> true

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): my plate
  # is read from them as I am painted, so I repaint.
  notePointerStateChanged: ->
    @_changed()

  # Does my plate show a press? While the hand presses me, where a press shows on my plate.
  _showsPressedPlate: ->
    @_showsPressOnMyPlate() and world.hand.pressesOn @

  # my plate's fill and border for the pointer state I show now, which my appearance reads as it
  # paints: the press look while my plate shows a press, else the hover look while the pointer rests
  # on me, else the rest look
  _plateFillForMyState: ->
    theme = WorldWdgt.theme
    if @_showsPressedPlate()
      theme.layoutChromePlatePressFill
    else if world.hand.restsOn @
      theme.layoutChromePlateHoverFill
    else
      theme.layoutChromePlateFill

  _plateStrokeForMyState: ->
    theme = WorldWdgt.theme
    if @_showsPressedPlate() then theme.layoutChromePlatePressStroke else theme.layoutChromePlateStroke
