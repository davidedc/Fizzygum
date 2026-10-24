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

  # MY POINTER STATE, the handles' two facts (HandleWdgt), kept apart because they end apart:
  # whether the pointer is over me (hoverEntered / hoverExited), and whether a press that began on
  # me still stands (pressBegan, until its release or its cancel, the end of its drag, the pointer
  # leaving me while nothing is dragged, or my moving to another parent). My plate shows the press
  # while it stands and the hover otherwise (_plateFillForMyState), so its look after a gesture is a
  # function of where the gesture left the pointer and me.
  _isHovered: false
  _isPressed: false

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

  hoverEntered: ->
    @_setPointerState true, @_isPressed

  # The pointer leaving me ends my press unless it drags something: an adjuster's drag carries on
  # while the pointer outruns my strip, but a press that left without dragging is abandoned (the
  # button's rule). A finger's stroke ends with this too, once its press and drag are cleared
  # (ActivePointerWdgt._dissolveHoverStateOfTouchStroke).
  hoverExited: ->
    @_setPointerState false, @_isPressed and world.hand.isThisPointerDraggingSomething()

  # a press shows on my plate while it stands (where a press acts on me, _showsPressOnMyPlate), and
  # then goes on as any widget's does (Widget.pressBegan)
  pressBegan: (pos) ->
    @_setPointerState @_isHovered, true  if @_showsPressOnMyPlate()
    super

  # the release ends my press, and so does the stroke turning into something else (ActivePointerWdgt,
  # the press's AUDIENCE); whether my plate then shows the hover is the pointer's business
  pressEnded: ->
    @_setPointerState @_isHovered, false

  pressCancelled: ->
    @_setPointerState @_isHovered, false

  # the drag that began on me is over, wherever the pointer is: so is my press
  endOfNonFloatDrag: ->
    @_setPointerState @_isHovered, false

  # a press does not survive a change of parent, whatever makes it: a lift also cancels my press, but
  # a drop or a builder moving me tells me nothing else
  _reactToBeingAdded: (whereTo, beingDropped) ->
    super
    @_setPointerState @_isHovered, false

  # my pointer state, and a repaint of me when it changes
  _setPointerState: (hovered, pressed) ->
    return if hovered is @_isHovered and pressed is @_isPressed
    @_isHovered = hovered
    @_isPressed = pressed
    @_changed()

  # my plate's fill and border for the pointer state I am in now, which my appearance reads as it
  # paints: the press look while a press stands, else the hover look while the pointer is over me,
  # else the rest look
  _plateFillForMyState: ->
    theme = WorldWdgt.theme
    if @_isPressed
      theme.layoutChromePlatePressFill
    else if @_isHovered
      theme.layoutChromePlateHoverFill
    else
      theme.layoutChromePlateFill

  _plateStrokeForMyState: ->
    theme = WorldWdgt.theme
    if @_isPressed then theme.layoutChromePlatePressStroke else theme.layoutChromePlateStroke
