# Shared base for the small "layout-editing chrome" widgets -- the layout spacer
# (LayoutSpacerWdgt), the element adder/droplet (LayoutElementAdderOrDropletWdgt),
# and the stack-size adjuster (StackElementsSizeAdjustingWdgt; an inspector browser's
# divider is one, InspectorDividerWdgt, between two columns of its set or between its
# set and its body below) -- and of the split button at the left end of an inspector's
# header, joined to the divider standing before that inspector (SplitGripWdgt; both in
# the lazy 'meta-tools' part). My look is my class's (createAppearance). The spacer and the
# adder wear the handles' look (LayoutChromeAppearance): the layoutChromePlate* plate
# over the whole box, in the look of my pointer state (below), and each one's glyph on
# it (_glyphOnMyPlate). The adjuster and the split button wear a split's piece
# (SplitPieceAppearance): one flat plate, and where the button joins the divider before
# its inspector, the two are ONE piece, lit together (THE JOINED PIECE, below). The two
# that drag a split show its resize cursor while the pointer is over them or drags them
# (_resizeCursor, the hover trio below), and KEEP the press that starts the drag
# (pressBegan, below).
#
# Of the first three, only the stack-size adjuster is NOT layout-editing-only:
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

  # THE PART JOINED TO ME, or undefined: a split's divider (StackElementsSizeAdjustingWdgt) and the
  # inspector's split button joined to it as a tab (SplitGripWdgt) each hold the other here, and are
  # painted as one piece (THE JOINED PIECE, below). THE RULE, once:
  #   SET only where the two are INTRODUCED, the reconcile of the inspector whose header the button
  #     leads (InspectorWdgt._reconcileSplitGripNoSettle), through noteJoinedBy, which sets it on
  #     both parts, each letting go of any part it held before;
  #   CLEARED on both parts by either part's going, each by its own event: the BUTTON's teardown
  #     (SplitGripWdgt._destroyNoSettle tells the divider: notePartedFrom), and the DIVIDER's leaving
  #     the stack it divides -- picked out, attached elsewhere or destroyed -- which the set or the
  #     browser it divides hears and tells it (InspectorRowWdgt._reactToChildRemoved,
  #     InspectorBrowserWdgt._reactToChildRemoved: noteLeftMyStack).
  # So no reference of either part outlives the other. (A button a person takes out of its header
  # stays held, though painted alone, until either event, or until the reconcile introduces the
  # divider to the fresh button that replaces it.) Never in a file nor in a copy: a save or a copy of
  # the inspector a button leads joins the two again as it is restored or copied (the same reconcile,
  # from its _afterDeserialization and _reactToBeingCopied), and a part saved or copied without the
  # other has nothing to join.
  joinedPiece: undefined
  @serializationTransients: ["joinedPiece"]
  @copyTransients: ["joinedPiece"]

  #: initialization

  # MY POINTER STATE is the hand's, as a handle's is (HandleWdgt), asked as I am painted and kept
  # nowhere (_plateFillForMyState): pressed while the hand presses me (ActivePointerWdgt.pressesOn)
  # where a press shows on my plate (_showsPressOnMyPlate), hovered while the pointer rests on me
  # (restsOn: never a finger, so a finger carrying a payload over a drop slot does not light it), at
  # rest otherwise. So my look after a gesture is a function of where the gesture left the pointer
  # and me -- and, joined into a piece, of where it left the part joined to me (_pieceShowsPress).

  constructor: ->
    super()
    @appearance = @createAppearance()

  # my look: the handles' plate with my glyph on it. A method, not a class field, so a subclass
  # reskins by overriding it (widget-authoring guidelines §5): a split's adjuster and its button
  # wear a split's piece.
  createAppearance: -> new LayoutChromeAppearance @

  #: event handling

  # Layout-editing CHROME (the spacer, the element adder/droplet, the stack-size adjuster / divider) is
  # never editor content (§5.D D-3/D21). Clicking or dragging one to reshape a layout must NOT make it
  # world.editorFocusWdgt -- otherwise the editor-focus SELECTION overlay frames the chrome (it sits inside
  # the edited container's editing-amenity subtree, so the D21 walk would reach it). Same exemption as the
  # frame-bar chrome / handles / scrollbars; honored by ancestry at ActivePointerWdgt's focus-set sites.
  excludedFromEditorFocusTracking: -> true

  # A PRIMARY PRESS ON ME (Widget.pressBegan says what a receiver answers). A piece that OWNS the
  # drags starting on it (ownsDragsStartingOnMe: a split's adjuster, and the split button joined to
  # one) takes the press as the start of that drag, in place, and KEEPS it, as a slider's thumb does
  # (SliderButtonWdgt.pressBegan): it raises what it stands in, as every press does, and the press
  # goes no further, so a pane around me that scrolls by a plain drag never takes my drag's stroke for
  # a drag-scroll and scrolls under it. Every other piece (a spacer, an adder: neither owns a drag)
  # passes the press on, as any widget does, so a finger's drag on it scrolls such a pane.
  pressBegan: (ignored_pos) ->
    if @ownsDragsStartingOnMe?()
      @bringToForeground()
      return false
    super

  #: menus

  # A divider IS a division cell, and the adder/droplet/spacer carry division boxes too, but each box is
  # machinery working state, not a user knob: I offer no division-cell submenu
  # (Widget._addMyDivisionCellMenuEntries).
  _addMyDivisionCellMenuEntries: (widgetOpeningThePopUp, menu) ->

  #: drawing

  # THE GLYPH ON MY PLATE, which my appearance paints centred over it in the normal pass: [the
  # size-aware icon appearance that draws it, in layoutChromeGlyph, and the side of its square], or []
  # for none. Built for each paint, as the handles' glyphs are, so no ink is saved or copied with me.
  # Default: none -- the adder's plus and the spacer's double arrow answer here.
  _glyphOnMyPlate: -> []

  # Whether a press on me shows on my plate: it does on what a press acts on (an adder adds a slot, an
  # adjuster drags its split); a spacer answers no.
  _showsPressOnMyPlate: -> true

  #: notifications

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): my plate
  # is read from them as I am painted, so I repaint, and so does the part joined to me, whose plate
  # shows them too: I tell it (noteMyPieceChanged), as it repaints only itself.
  notePointerStateChanged: ->
    @_changed()
    @_myJoinedPiece()?.noteMyPieceChanged()

  # MY PIECE CHANGED: the part joined to me tells me the hand's answers about it may have moved. My
  # look reads them as I am painted, so I repaint.
  noteMyPieceChanged: ->
    @_changed()

  #: joined piece

  # `piece` and I are INTRODUCED (joinedPiece's rule says where): I do my half -- I part from any part
  # I held (it repaints as a part alone), hold `piece` and repaint -- and tell `piece`, which does its
  # half the same way and tells me back, a call that ends here at once, since I hold it by then. Each
  # of us touches only its own field and repaints only itself. Nothing to do when I hold `piece`
  # already.
  noteJoinedBy: (piece) ->
    return if @joinedPiece is piece
    @notePartedFrom @joinedPiece
    @joinedPiece = piece
    @_changed()
    piece.noteJoinedBy @

  # `piece` and I PART (joinedPiece's rule says when): I let go of it and tell it, and it lets go of me
  # and tells me back, a call that ends here at once, since by then I hold nothing; so neither names the
  # other, and each repaints itself as a part alone -- a part being destroyed excepted, which repaints
  # no more. Nothing to do when `piece` is not the part I hold.
  notePartedFrom: (piece) ->
    return unless piece? and @joinedPiece is piece
    @joinedPiece = undefined
    piece.notePartedFrom @
    @_changed()  unless @destroyed

  # THE JOINED PIECE. A split's divider and the split button joined to it as a tab are painted as ONE
  # piece (SplitPieceAppearance): a press on either shows on both, and so does a hover. Each part
  # answers the other (_myJoinedPiece) from the one join both hold, so they agree at every moment: the
  # button stands joined while the divider it holds is the splitter its inspector says it moves (one it
  # took out of its header, or put after its title, stands alone until its inspector's reconcile), and
  # the divider while that button says so. The part joined to me, or undefined. Default: none -- the
  # spacer and the adder join nothing.
  _myJoinedPiece: -> undefined

  #: drawing

  # Does my PIECE show a press? My plate does, or the plate of the part joined to me.
  _pieceShowsPress: ->
    @_showsPressedPlate() or (@_myJoinedPiece()?._showsPressedPlate() ? false)

  # Does my PIECE show a hover? The pointer rests on me, or on the part joined to me.
  _pieceShowsHover: ->
    joined = @_myJoinedPiece()
    world.hand.restsOn(@) or (joined? and world.hand.restsOn joined)

  #: event handling

  # THE RESIZE CURSOR my hover shows, a CSS cursor name, or undefined for none: what a drag on me
  # does, said by the page's pointer while the pointer is over me or drags me. Default: none -- a
  # spacer and an adder resize nothing; the split adjuster and the split button answer by their axis.
  _resizeCursor: -> undefined

  # my plate's hover and press are read off the hand as I am painted (above); here, the resize cursor
  hoverEntered: ->
    cursor = @_resizeCursor()
    document.getElementById("world").style.cursor = cursor  if cursor?

  # mid-drag the pointer routinely outruns a strip or a button, so keep the resize
  # cursor while THIS piece of chrome is the one being non-float dragged -- the
  # endOfNonFloatDrag hook below restores it at the true end of the drag
  hoverExited: ->
    return unless @_resizeCursor()?
    return if world.hand.nonFloatDraggedWdgt == @
    document.getElementById("world").style.cursor = "auto"

  # the drag can end with the pointer outside my bounds (that hoverExited was
  # suppressed above), so restore the cursor here unless the pointer is back
  # over me -- then the eventual hoverExited handles it
  endOfNonFloatDrag: ->
    return unless @_resizeCursor()?
    if world.hand.topWdgtUnderPointer() != @
      document.getElementById("world").style.cursor = "auto"

  #: drawing

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
