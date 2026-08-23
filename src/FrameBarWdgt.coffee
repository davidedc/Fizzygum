# The title bar of a FrameWdgt -- ONE child that owns the title-strip pieces
# (titlebarBackground, label, close button, collapse/uncollapse switch,
# pencil-eye edit button), their strip arrange, and the title half of the
# window/card skin (the body half stays on the frame). WHICH pieces the strip
# carries, at what metrics, and along which axis is NOT mine to decide: the
# frame derives all of it in one place (FrameWdgt._barSpec) and I build and lay
# out whatever that spec names -- so a manifestation is a ROSTER, never a bar
# subclass. The frame keeps ALIAS
# fields pointing at the same piece instances -- `win.label` / `win.closeButton`
# / `win.editButton` / `win.collapseUncollapseSwitchButton` /
# `win.titlebarBackground` are load-bearing contracts (MacroToolkit, the macro
# tests, FolderWindowWdgt's supplied close button, showEditModeInBar) -- so
# everything outside reaches the pieces through the frame exactly as before.
#
# The pieces' press protocol is answered HERE: the icon-button family
# deliberately targets ITSELF and asks its PARENT what a press means (see
# IconButtonWdgt's ctor note), and that parent is this bar -- which forwards to
# the frame (closeButtonInBarPressed & co. -- the frame owns what its bar
# buttons DO).
#
# ⚠ This must stay a plain (non-PanelWdgt) Widget with the inherited
# grabsToParentWhenDragged() == true: the grab climb
# (Widget.findFirstLooseWidget) stops at a child whose parent is a PanelWdgt,
# so a PanelWdgt bar would make a title-bar drag grab the LABEL instead of the
# window. Appearance-less: the background piece draws the strip, the bar itself
# paints nothing -- but it IS an opaque hit-target (the explicit appearance-less
# default), so strip clicks escalate through it to the frame.

class FrameBarWdgt extends Widget

  frame: undefined
  titlebarBackground: undefined
  label: undefined
  closeButton: undefined
  collapseUncollapseSwitchButton: undefined
  editButton: undefined
  # WHICH style the title pieces I am holding right now were built for. The two styles are two
  # different pieces -- a rounded header box around a self-hugging TextWdgt, or an inset strip
  # behind a fitted StringWdgt -- so a frame that changes manifestation needs them REBUILT, not
  # recoloured, and this is what tells the roster derive that they disagree with the spec.
  titleStyle: undefined

  constructor: (@frame) ->
    super()

  colloquialName: ->
    "title bar"

  # The title bar and all its pieces (titlebarBackground / label / the chrome buttons) are frame CHROME,
  # never editor content (§5.D D-3/D21). Clicking the title must NOT make the hit piece world.editorFocusWdgt
  # -- otherwise the editor-focus SELECTION overlay frames the title (it sits inside the frame's
  # editing-amenity subtree, so the D21 walk would reach it). Declared on the bar so it covers every piece
  # BY ANCESTRY at ActivePointerWdgt's focus-set sites (the pieces are my children; the buttons also exclude
  # themselves via IconButtonWdgt).
  excludedFromEditorFocusTracking: -> true

  # I present NO SURFACE OF MY OWN -- my titlebarBackground piece draws the strip -- so the
  # pointer falls THROUGH me: to my pieces (shaped where the strip is drawn), to the frame body
  # at the 1px border the background doesn't cover, and -- at the frame's rounded-corner notches
  # -- on through to whatever is BEHIND the frame. Without this the base claims my whole box (the
  # appearance-less default) and I would intercept hits at exactly those corner pixels the
  # frame's own shape excludes -- observed as the desktop folder shortcut losing its
  # pointer-under state when its window spawns at the click point (same corner story as
  # MenuWdgt / PromptWdgt, container arc §5.6).
  catchesPointerAt: (aPoint) ->
    false

  # The internal structure of a window's chrome, not a user-meaningful target:
  # excluded from the right-click hierarchy/disambiguation menu exactly like
  # MenuRowsPanelWdgt (see Widget.getHierarchyMenuWidgets) -- every action a
  # user takes on the title strip belongs to the WINDOW ("a Frame" stays the
  # entry they navigate).
  hiddenFromHierarchyMenu: ->
    true

  # ===== the press protocol =====
  # The bar answers its buttons' `@parent.<x>ButtonInBarPressed?()` asks and
  # forwards to the frame, which owns the meaning (close/collapse the CONTENT,
  # toggle its edit mode).

  closeButtonInBarPressed: ->
    @frame.closeButtonInBarPressed()

  editButtonInBarPressed: ->
    @frame.editButtonInBarPressed()

  collapseButtonInBarPressed: ->
    @frame.collapseButtonInBarPressed()

  uncollapseButtonInBarPressed: ->
    @frame.uncollapseButtonInBarPressed()

  # Piece adds mirror the frame's add core (strip-spacing hook first) so a
  # piece type that overrides _resizeToWithoutSpacing behaves identically to
  # when the frame added it directly.
  _addNoSettle: (aWdgt, opts = {}) ->
    aWdgt._resizeToWithoutSpacing()
    super

  # ===== build =====
  # The background is keep-if-exist and the label is destroyed + rebuilt every
  # time, born blank -- every build path immediately re-derives its text from the
  # content. The button pieces are whatever the frame's CURRENT bar spec names
  # (below). The caller (the frame) passes -- on the first build -- any
  # ctor-supplied close button (FolderWindowWdgt injects its own).
  _buildAndConnectPiecesNoSettle: (suppliedCloseButton) ->
    spec = @frame._barSpec()

    if "title" in spec.pieces
      if !@titlebarBackground?
        @_buildTitlebarBackground()
      # label -- tear down through the non-settling core (inside the rebuild's settle)
      @label?._fullDestroyNoSettle()
      @label = @_buildTitleNoSettle spec
      @titleStyle = spec.titleStyle

    # the upper-left button, often a close button but it can be anything: the
    # frame's ctor-supplied piece is adopted here, and the roster below decides
    # whether the strip carries one at all
    @closeButton ?= suppliedCloseButton
    @_reDeriveRosterNoSettle()

  # The title piece, in the shape its style asks for: a WINDOW's is a plain fitted string the
  # arrange grants the span between the buttons; a POP-UP HEADER's hugs its own text (the strip
  # sizes itself to it) and is centred in the header box, white and bold on the header colour.
  _buildTitleNoSettle: (spec) ->
    preferences = WorldWdgt.preferencesAndSettings
    if spec.titleStyle is "menuHeader"
      # BORN with its text: a multi-line text hugs its box only when told to (its box-hug core
      # is a one-shot, not a mode the way a plain string's is), so it must have something to
      # hug at build time. The frame re-asserts the same title right after.
      title = new TextWdgt (@frame._titleForContents(@frame.contents) ? ""),
        fontSize: spec.fontSize
        fontName: preferences.menuFontName
        bold: preferences.menuHeaderBold
      title.color = Color.WHITE
      title.backgroundColor = preferences.menuHeaderColor
      title.alignCenter()
      @_addNoSettle title
      # the modern family does not self-size; make the title hug its text (and KEEP hugging it
      # through every later setText) so the strip's own thickness and the payload's row-width
      # floor can be read off it. Use the NoSettle core: the build settles ONCE, at its top.
      title._sizeToTextAndDisableFittingNoSettle()
      return title

    title = new StringWdgt "", fontSize: spec.fontSize

    # as of March 2018, Safari 10.1.1 on OSX 10.12.5 :
    # safari's rendering of bright text on dark background is atrocious
    # so we have to force bold style in the window bars
    if /^((?!chrome|android).)*safari/i.test navigator.userAgent
      title.isBold = true
    else
      title.isBold = preferences.titleBarBoldText

    title.color = Color.WHITE
    @_addNoSettle title
    title

  # Build the button pieces the frame's CURRENT bar spec names, and retire the
  # ones it drops -- the edit button's build/retire idiom, generalized to the
  # whole roster. The roster follows the frame's ATTACHMENT: a host that owns a
  # frame's placement owns its membership, so a host-owned frame carries no
  # close piece (program ruling C6, the same isFreeFloating() predicate the
  # resize handle answers) -- hence the frame re-runs this at every (re)parenting
  # and every layout-spec change. Answers whether the roster actually CHANGED, so
  # the frame invalidates its layout only when it did (a spec-less chrome child
  # rides the freefloating skip in Widget._addNoSettle's container invalidate, and
  # an unconditional invalidate mid-arrange would cost a settle re-visit).
  _reDeriveRosterNoSettle: ->
    spec = @frame._barSpec()
    pieces = spec.pieces
    rosterChanged = false

    # the title pair (strip background + text piece) first: a roster that drops the title retires
    # both, and a roster that keeps it in a DIFFERENT style rebuilds both, since the two styles are
    # two different pieces. The text carries over so whatever the frame last titled itself survives
    # the swap (an empty window keeps saying "empty window").
    titleWanted = "title" in pieces
    if @titlebarBackground? and (!titleWanted or @titleStyle isnt spec.titleStyle)
      titleTextCarriedOver = @label?.text
      # the SUBTREE, through the non-settling core: the pieces own children of their own, and
      # destroying a piece alone would leave those alive and off-tree -- escaped widgets the
      # instances registry pins forever.
      @titlebarBackground._fullDestroyNoSettle()
      @titlebarBackground = undefined
      @label?._fullDestroyNoSettle()
      @label = undefined
      @titleStyle = undefined
      rosterChanged = true
    if titleWanted and !@titlebarBackground?
      @_buildTitlebarBackground()
      @label = @_buildTitleNoSettle spec
      @label._setTextNoSettle titleTextCarriedOver if titleTextCarriedOver?
      @titleStyle = spec.titleStyle
      rosterChanged = true

    if "close" in pieces
      if !@closeButton? or @closeButton.parent isnt @
        @closeButton ?= new CloseIconButtonWdgt
        @_addNoSettle @closeButton
        rosterChanged = true
    else if @closeButton?
      # the SUBTREE, through the non-settling core (the label/background idiom above): an
      # icon button owns a face widget, and destroying the button alone would leave that face
      # alive and off-tree -- an escaped widget the instances registry pins forever.
      @closeButton._fullDestroyNoSettle()
      @closeButton = undefined
      rosterChanged = true

    if "collapse" in pieces
      if !@collapseUncollapseSwitchButton? or @collapseUncollapseSwitchButton.parent isnt @
        if !@collapseUncollapseSwitchButton?
          collapseButton = new CollapseIconButtonWdgt
          uncollapseButton = new UncollapseIconButtonWdgt
          @collapseUncollapseSwitchButton = new SwitchButtonWdgt [collapseButton, uncollapseButton]
        @_addNoSettle @collapseUncollapseSwitchButton
        rosterChanged = true
    else if @collapseUncollapseSwitchButton?
      # the SUBTREE, as above: the switch owns the two glyph buttons it toggles between.
      @collapseUncollapseSwitchButton._fullDestroyNoSettle()
      @collapseUncollapseSwitchButton = undefined
      rosterChanged = true

    rosterChanged

  # Does my built strip disagree with the roster my frame's spec names? The pure question, asked
  # by a frame whose layout spec just changed: the answer decides whether that change is worth a
  # re-lay at all, and the re-lay is where the mutating half above runs (a gained piece is
  # CONSTRUCTED, which is a settling operation outside a flush). Same two names, same
  # membership test, so the two halves cannot drift apart.
  _rosterDisagreesWithSpec: ->
    spec = @frame._barSpec()
    pieces = spec.pieces
    titleWanted = "title" in pieces
    closeWanted = "close" in pieces
    collapseWanted = "collapse" in pieces
    return true if titleWanted isnt (@titlebarBackground? and @titlebarBackground.parent is @)
    return true if titleWanted and @titleStyle isnt spec.titleStyle
    return true if closeWanted isnt (@closeButton? and @closeButton.parent is @)
    return true if collapseWanted isnt (@collapseUncollapseSwitchButton? and @collapseUncollapseSwitchButton.parent is @)
    false

  # The roster names pieces; this is the one place a name meets its instance.
  _pieceNamed: (pieceName) ->
    switch pieceName
      when "close" then @closeButton
      when "collapse" then @collapseUncollapseSwitchButton
      when "title" then @label
      when "edit" then @editButton

  _buildTitlebarBackground: ->
    if @titlebarBackground?
      # tear down through the non-settling core: this runs inside the frame
      # rebuild's settle, so the public self-settling fullDestroy() would throw
      # under the single-mutation tier. The enclosing settle covers the re-layout.
      @titlebarBackground._fullDestroyNoSettle()

    # TODO we should really just instantiate a Widget,
    # and give it the shape, there is no reason to create
    # the dedicated shape widget and then change the appearance
    # as the window changes from internal to external and vice versa
    # HOWEVER a bunch of tests would fail if I do the proper
    # thing so we are doing this for the time being.
    if @frame._barSpec().titleStyle is "menuHeader"
      @titlebarBackground = new BoxWdgt WorldWdgt.preferencesAndSettings.menuHeaderCornerRadius
    else if @frame.isInternal()
      @titlebarBackground = new RectangleWdgt
    else
      @titlebarBackground = new BoxWdgt

    @_setAppearanceAndColorOfTitleBackground()
    @_addNoSettle @titlebarBackground

  # The title-bar half of my skin (the body half is
  # FrameWdgt._deriveAndSetBodyAppearance): the pop-up manifestation's header box carries the
  # menu-header colour and no stroke; a window's is re-derived from the frame's parentage on
  # every (re)parenting.
  _setAppearanceAndColorOfTitleBackground: ->
    # an untitled pop-up has no strip at all, so there is no background to skin
    return unless @titlebarBackground?
    if @frame._barSpec().titleStyle is "menuHeader"
      @titlebarBackground.appearance = new BoxyAppearance @titlebarBackground
      @titlebarBackground.setColor WorldWdgt.preferencesAndSettings.menuHeaderColor
      return

    if @frame.isInternal()
      @titlebarBackground.appearance = new RectangularAppearance @titlebarBackground
    else
      @titlebarBackground.appearance = new BoxyAppearance @titlebarBackground

    if @frame.isInternal()
      @titlebarBackground.setColor WorldWdgt.preferencesAndSettings.internalWindowBarBackgroundColor
      @titlebarBackground.strokeColor = WorldWdgt.preferencesAndSettings.internalWindowBarStrokeColor
    else
      @titlebarBackground.setColor WorldWdgt.preferencesAndSettings.externalWindowBarBackgroundColor
      @titlebarBackground.strokeColor = WorldWdgt.preferencesAndSettings.externalWindowBarStrokeColor

  # The edit button's lifecycle is driven by the FRAME (it depends on the
  # content's providesAmenitiesForEditing and dies/respawns on collapse /
  # uncollapse); the bar just houses the piece. The button targets the FRAME
  # (bound ref) and asks its parent -- this bar -- what a press means.
  _createAndAddEditButtonNoSettle: ->
    @editButton = new EditIconButtonWdgt @frame
    @_addNoSettle @editButton
    @editButton

  # the SUBTREE, like every other piece I retire: an icon button owns a face widget, and destroying
  # the button alone leaves that face alive and off-tree -- an escaped widget the instances registry
  # pins forever. ONE retirement path for the whole roster.
  _destroyEditButtonNoSettle: ->
    @editButton?._fullDestroyNoSettle()
    @editButton = undefined

  # ===== the strip arrange =====
  # The bar's bounds ARE the frame's top strip (the frame hands them over in
  # its own arrange via `@bar._reLayout barBounds`), so all the piece math
  # reads off MY origin/extent -- the same absolute pixels the frame's flat
  # arrange produced.
  #
  # The roster is a LIST, not a set of fixed slots: the pieces named BEFORE
  # "title" lead from my left edge in order, the ones named AFTER it trail from
  # my right edge, and the title takes the span left between them -- so dropping
  # a piece closes its gap instead of leaving a hole. Every number comes from the
  # spec (which reads preferences), never from a literal here.

  _reLayoutChildren: ->
    @_positionAndResizeChildren()

  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  # Pinned false, NOT derived: defining _reLayout above would flip the derived
  # answer and mis-route its read sites -- the same pin the frame and the stack
  # carry.
  implementsDeferredLayout: ->
    false

  _positionAndResizeChildren: ->
    spec = @frame._barSpec()
    if spec.titleStyle is "menuHeader"
      @_layOutTitleBox spec
      return
    pitch = spec.slotSize + spec.padding

    titleAt = spec.pieces.indexOf "title"
    leadingPieces = spec.pieces.slice 0, titleAt
    trailingPieces = spec.pieces.slice titleAt + 1

    # NON-settling cores (not the public collapse/unCollapse): this is a layout pass, so reaching the
    # self-settling wrapper would re-enter the flush. The cores are idempotent, so an already-correct
    # button is a no-op exactly as the public guards made it. (check-layering [G])
    # A trailing button is what a narrow strip gives up first, so the title keeps its room.
    stripFitsWholeRoster = @width() >= (leadingPieces.length + trailingPieces.length) * pitch + spec.padding
    for pieceName in trailingPieces
      piece = @_pieceNamed pieceName
      continue unless piece?
      if stripFitsWholeRoster
        piece._unCollapseNoSettle()
      else
        piece._collapseNoSettle()

    for pieceName, slotIndex in leadingPieces
      piece = @_pieceNamed pieceName
      continue unless piece? and piece.parent == @
      @_layOutPieceInSlot piece, (@left() + spec.padding + slotIndex * pitch), spec

    for pieceName, slotIndex in trailingPieces
      piece = @_pieceNamed pieceName
      continue unless piece? and piece.parent == @ and !piece.isInCollapsedSubtree()
      @_layOutPieceInSlot piece, (@right() - (trailingPieces.length - slotIndex) * pitch), spec

    @titlebarBackground._applyBounds (@position().add new Point 1,1), (new Point @width(), spec.thickness).subtract new Point 2,2
    # TODO this looks better:
    #@titlebarBackground._applyExtent (new Point @width(), spec.thickness).subtract new Point 4,4
    #@titlebarBackground._applyMoveTo @position().add new Point 2,2

    # the title takes the span between the leading pieces and the trailing ones
    # that are actually showing
    if spec.showsText and @label? and @label.parent == @
      labelLeft = @left() + spec.padding + leadingPieces.length * pitch
      labelRight = @right() - spec.padding
      for pieceName in trailingPieces
        piece = @_pieceNamed pieceName
        labelRight -= pitch if piece? and !piece.isInCollapsedSubtree()

      labelBounds = new Rectangle new Point labelLeft, @top() + spec.padding
      labelBounds = labelBounds.setBoundsWidthAndHeight (labelRight - labelLeft), spec.textHeight
      @label._applyGrantedBounds labelBounds

  # The POP-UP strip: ONE header box, inset from my edges by the padding and as tall as the
  # strip, with the title text hugging itself and centred in it. An untitled pop-up carries no
  # pieces at all, so there is nothing to place.
  _layOutTitleBox: (spec) ->
    return unless @titlebarBackground? and @label?
    @titlebarBackground._applyBounds (@position().add new Point spec.padding, spec.padding),
      (new Point (@width() - 2 * spec.padding), spec.thickness)
    # Integer placement (Layer A): the box centre is fractional when its extent is odd, so round
    # the centred title's position to commit an integer @bounds.
    @label._applyMoveTo (@titlebarBackground.center().subtract @label.extent().floorDivideBy 2).round()

  # A tap on my strip PINS a transient frame — the pop-up manifestation's one bar gesture, and
  # the counterpart of the drag that moves it: the title is what you take hold of. The pieces
  # escalate their own clicks to me (they are shaped where they are drawn; I am not a hit
  # target), so this one handler covers the whole strip.
  mouseClickLeft: ->
    super
    @frame.pinPopUp @ if @frame?.isTransientPopUp()

  # A piece occupies its SLOT -- the target box the strip advances by -- and is
  # drawn at the GLYPH dial centred inside it. Two dials, never one (program
  # ruling G3): a target and the mark inside it scale differently. They are equal
  # on the desk profile, so a piece fills its slot exactly.
  _layOutPieceInSlot: (piece, slotLeft, spec) ->
    glyphInset = Math.round (spec.slotSize - spec.glyphSize) / 2
    glyphSide = spec.slotSize - 2 * glyphInset
    pieceBounds = new Rectangle new Point slotLeft + glyphInset, @top() + spec.padding + glyphInset
    piece._reLayout pieceBounds.setBoundsWidthAndHeight glyphSide, glyphSide
