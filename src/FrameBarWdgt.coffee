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

  # WHICH of the collapse switch's two glyphs is showing while the frame is EXPANDED: the switch
  # is built as [collapse, uncollapse] (see _reDeriveRosterNoSettle) and its value is an index into
  # that pair, so the offer-to-collapse glyph is the first.
  @COLLAPSE_GLYPH: 0

  # THE ORDER THE STRIP GIVES ITS PIECES UP as it narrows (owner ruling, the graded roster): the
  # title goes first (the grade in _layOutTitleInStrip), then the pencil, then the collapse
  # switch, then the close button, and then the strip carries nothing at all. Least consequential
  # first -- editing is an amenity, collapsing is a convenience, and closing is the last thing a
  # window gives up. A roster name absent from this list is dropped after all of them (from the
  # roster's own tail), so a piece added tomorrow degrades rather than overflowing.
  @PIECE_DROP_ORDER: ["edit", "collapse", "close"]

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

  # THE EVENT ONE OF MY PIECES ACTED ON — the stamp my own strip gesture reads to know whose click
  # it is looking at (see mouseClickLeft). Purely about a gesture in flight, so it never belongs in
  # a snapshot; merged up the chain by Serializer.transientsForClass, which ADDS to Widget's list.
  @serializationTransients: ["_eventOfAPiecePress"]
  _eventOfAPiecePress: undefined

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

  # MY PIECES DO NOT OWN DRAGS -- I DO. A chrome piece acts on a TAP (close, collapse, toggle the
  # pencil); a press on one that travels past the grab threshold is the user taking hold of the
  # STRIP, and it must do what a drag on my bare strip does: move a window, pull a docked band out
  # of its slot. Without this a piece cancels the drag outright (the button family rejects drags
  # by default) and a strip whose pieces cover it -- a 50 px band grip with a centred 44 px switch
  # -- becomes undraggable at exactly the place a user grabs it.
  #   Declared HERE, on the strip, in the parent-side shape wantsDetachOfChild already uses
  # (ButtonWdgt.rejectDrags consults both): a piece never has to know which strip it sits on, and
  # nothing in the hand learns a special case. The CLICK path is untouched -- a tap still fires
  # the button's own action, and the provenance stamp that tells my strip gesture "that was a
  # piece press" is written by the action, which a drag never reaches.
  ownsDragsOfMyChildren: -> true

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
  #   Every piece press comes through here, which is what makes this the one place that can STAMP
  # it: the strip's own gesture must know a click was a piece's, and by the time that click has
  # escalated to me the press has already moved the very pieces a positional test would ask about
  # (see mouseClickLeft).

  closeButtonInBarPressed: ->
    @_notePiecePress()
    @frame.closeButtonInBarPressed()

  editButtonInBarPressed: ->
    @_notePiecePress()
    @frame.editButtonInBarPressed()

  collapseButtonInBarPressed: ->
    @_notePiecePress()
    @frame.collapseButtonInBarPressed()

  uncollapseButtonInBarPressed: ->
    @_notePiecePress()
    @frame.uncollapseButtonInBarPressed()

  # A piece of mine is acting on THIS event. The EVENT CLOCK, never the wall clock and never a
  # bare flag: one click is drained under one WorldWdgt.timeOfEventBeingProcessed, so a press and
  # the escalation it causes share a stamp and no later gesture can. A flag would have to be
  # cleared by someone, and a press driven straight from code (a macro, a menu sweep) escalates to
  # nobody — it would leave the flag armed and swallow the next real strip tap forever.
  _notePiecePress: ->
    @_eventOfAPiecePress = WorldWdgt.timeOfEventBeingProcessed

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

    # the weight the preference block names, on EVERY engine: a bar title is chrome like any
    # other, and chrome keyed on the user agent renders one world two ways -- which is precisely
    # what the cross-engine suite leg reads, and reports, as a defect.
    title.isBold = preferences.titleBarBoldText

    title.color = Color.WHITE
    # a window title reads CENTRED in its strip (ruling C13): the arrange grants me a box centred
    # on the strip and clear of the pieces at both ends, and the text centres itself within it.
    title.alignCenter()
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
    # whatever the frame last titled itself survives every piece swap below (an empty window keeps
    # saying "empty window", a grip that widens back into a bar gets its title back)
    titleTextCarriedOver = @label?.text

    # the title pair (strip background + text piece) first: a roster that drops the title retires
    # both, and a roster that keeps it in a DIFFERENT style rebuilds both, since the two styles are
    # two different pieces.
    titleWanted = "title" in pieces
    if @titlebarBackground? and (!titleWanted or @titleStyle isnt spec.titleStyle)
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

    # the pencil, RETIRE side only: its build belongs to the frame, which pairs it with the mode
    # glyph to show (FrameWdgt._createAndAddEditButton, re-driven right after this).
    if ("edit" not in pieces) and @editButton?
      @_destroyEditButtonNoSettle()
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
    vertical = spec.axis is "vertical"
    pitch = spec.slotSize + spec.padding

    titleAt = spec.pieces.indexOf "title"
    leadingPieces = spec.pieces.slice 0, titleAt
    trailingPieces = spec.pieces.slice titleAt + 1

    # ALONG the strip is my width when I run across a frame's top and my height when I run down a
    # band's leading end -- one arrange, two directions (program ruling C13).
    stripLength = if vertical then @height() else @width()
    stripStart = if vertical then @top() else @left()
    stripEnd = if vertical then @bottom() else @right()

    # THE ROSTER, GRADED BY FIT -- ONE derivation, right here, with the strip's length as one of
    # its inputs (ruling C5). Every piece the strip has no whole slot for gives its slot up, in
    # the order below, so a narrowing strip thins out to nothing instead of overlapping its own
    # buttons.
    #   NON-settling cores (not the public collapse/unCollapse): this is a layout pass, so reaching
    # the self-settling wrapper would re-enter the flush. The cores are idempotent, so an
    # already-correct button is a no-op exactly as the public guards made it. (check-layering [G])
    allPieces = leadingPieces.concat trailingPieces
    keptPieces = @_pieceNamesThatFit allPieces, stripLength, spec
    for pieceName in allPieces
      piece = @_pieceNamed pieceName
      continue unless piece?
      if pieceName in keptPieces
        piece._unCollapseNoSettle()
      else
        piece._collapseNoSettle()
    leadingPieces = (pieceName for pieceName in leadingPieces when pieceName in keptPieces)
    trailingPieces = (pieceName for pieceName in trailingPieces when pieceName in keptPieces)

    if vertical
      @titlebarBackground._applyBounds (@position().add new Point 1,1), (new Point spec.thickness, @height()).subtract new Point 2,2
    else
      @titlebarBackground._applyBounds (@position().add new Point 1,1), (new Point @width(), spec.thickness).subtract new Point 2,2
    # TODO this looks better:
    #@titlebarBackground._applyExtent (new Point @width(), spec.thickness).subtract new Point 4,4
    #@titlebarBackground._applyMoveTo @position().add new Point 2,2

    # THE TITLE, after the pieces because it takes the span they leave, and it is the FIRST thing
    # the graded roster gives up: a strip too narrow to READ drops its text the same way the roster
    # above drops a button, and for the same reason -- the piece stays, so its text survives to be
    # shown again the moment the strip runs across a frame's top instead of down a band's side. A
    # title cropped past legibility gives itself up too (see _layOutTitleInStrip).
    titleShows = @_layOutTitleInStrip spec, leadingPieces, trailingPieces, pitch

    if titleShows
      # the roster reads left to right: the leading pieces from the strip's start, the trailing
      # ones from its end, and the title in the span between
      for pieceName, slotIndex in leadingPieces
        piece = @_pieceNamed pieceName
        continue unless piece? and piece.parent == @
        @_layOutPieceInSlot piece, (stripStart + spec.padding + slotIndex * pitch), spec

      for pieceName, slotIndex in trailingPieces
        piece = @_pieceNamed pieceName
        continue unless piece? and piece.parent == @ and !piece.isInCollapsedSubtree()
        @_layOutPieceInSlot piece, (stripEnd - (trailingPieces.length - slotIndex) * pitch), spec
    else
      # A TEXTLESS strip centres its piece GROUP along its own axis (ruling C13): with no title
      # between them the pieces are the whole of what the strip carries, and a lone collapse glyph
      # pinned to one end of a long empty band reads as an accident rather than as the band's
      # control. Contiguous, in roster order, in the middle -- a side dock's horizontal bar centres
      # it horizontally, a top dock's vertical bar vertically, and it is ONE arithmetic either way.
      showing = @_showingPieces leadingPieces.concat trailingPieces
      if showing.length > 0
        groupLength = showing.length * spec.slotSize + (showing.length - 1) * spec.padding
        groupStart = stripStart + Math.round (stripLength - groupLength) / 2
        for piece, slotIndex in showing
          @_layOutPieceInSlot piece, (groupStart + slotIndex * pitch), spec

  # WHICH of `pieceNames` the strip has room for, in roster order. A piece occupies a whole slot
  # (the target box) and the strip keeps a padding at each end and between neighbours, so the
  # count that fits is the inverse of the group arithmetic the placement below uses --
  # n * pitch + padding pixels for n pieces. What falls out goes by PIECE_DROP_ORDER, so the
  # progression is the ruled one (pencil, collapse, close) rather than "whatever was last".
  _pieceNamesThatFit: (pieceNames, stripLength, spec) ->
    pitch = spec.slotSize + spec.padding
    slotsAvailable = Math.max 0, Math.floor (stripLength - spec.padding) / pitch
    kept = pieceNames.slice()
    for pieceName in FrameBarWdgt.PIECE_DROP_ORDER
      break if kept.length <= slotsAvailable
      droppedAt = kept.indexOf pieceName
      kept.splice droppedAt, 1 if droppedAt >= 0
    # a roster name the drop order does not know still has to fit: the tail goes
    kept = kept.slice 0, slotsAvailable if kept.length > slotsAvailable
    kept

  # The pieces of `pieceNames` that are actually on the strip right now -- mine, and not collapsed
  # away by the roster's fit grade above.
  _showingPieces: (pieceNames) ->
    pieces = []
    for pieceName in pieceNames
      piece = @_pieceNamed pieceName
      pieces.push piece if piece? and piece.parent == @ and !piece.isInCollapsedSubtree()
    pieces

  # PLACE THE TITLE, and answer whether it ends up showing at all.
  #   Its box is the widest one CENTRED on the strip that stays clear of the pieces at both ends,
  # so the text reads centred in the strip's FULL width (ruling C13) and can never run under a
  # button; the box is symmetric because the extra room beside the shorter end is room a centred
  # title cannot use anyway. Vertically it sits centred in the strip's thickness.
  #   THE GRADE (ruling C13): a title that fits shows whole; a cropped one shows only while the
  # visible prefix keeps barTitleEllipsisMinFraction of the characters AND at least
  # barTitleEllipsisMinChars of them. Below either bar there is no title piece at all -- "World…"
  # and "t…" name nothing, and an empty strip says more than a garbled one.
  _layOutTitleInStrip: (spec, leadingPieces, trailingPieces, pitch) ->
    return false unless @label? and @label.parent == @
    # a strip running down a band's side is too narrow to read: the piece stays (its text survives
    # for the moment the strip runs across a top again) but it is collapsed out of the picture
    unless spec.showsText
      @label._collapseNoSettle()
      return false
    vertical = spec.axis is "vertical"
    stripLength = if vertical then @height() else @width()
    stripStart = if vertical then @top() else @left()
    trailingShowing = (@_showingPieces trailingPieces).length

    centre = stripStart + Math.round stripLength / 2
    leadEnd = stripStart + spec.padding + leadingPieces.length * pitch
    trailEnd = stripStart + stripLength - spec.padding - trailingShowing * pitch
    halfSpan = Math.min (centre - leadEnd), (trailEnd - centre)

    if halfSpan <= 0
      @label._collapseNoSettle()
      return false

    # uncollapsed BEFORE the grant: the grade below reads what the label would draw in the box it
    # is holding, so it must be holding one
    @label._unCollapseNoSettle()
    labelTop = @top() + Math.round (spec.thickness - spec.textHeight) / 2
    labelBounds = new Rectangle new Point (centre - halfSpan), labelTop
    @label._applyGrantedBounds labelBounds.setBoundsWidthAndHeight (2 * halfSpan), spec.textHeight

    return true if @_titleReadsWellEnough()
    @label._collapseNoSettle()
    false

  # Does the title in the box it now holds still SAY the frame's name? Whole, always; cropped, only
  # while enough of it survives (the two barTitleEllipsis* dials).
  _titleReadsWellEnough: ->
    preferences = WorldWdgt.preferencesAndSettings
    wholeLength = @label.text.length
    return true if wholeLength is 0
    keptLength = @label.numberOfCharactersThatFit()
    return true if keptLength >= wholeLength
    keptLength >= preferences.barTitleEllipsisMinChars and
      keptLength >= preferences.barTitleEllipsisMinFraction * wholeLength

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

  # MY STRIP'S OWN GESTURES. The pieces escalate their clicks to me (they are shaped where they
  # are drawn; I am not a hit target), so this one handler covers the whole strip — and so it must
  # ask, for anything a piece could also mean, whether the click was a PIECE's. A piece has
  # already acted by the time it escalates: a press on the collapse button that this handler read
  # as a strip press would undo itself on the spot.
  #   It asks by PROVENANCE (the press protocol's stamp), never by position, because the press has
  # already RE-LAID my pieces: collapsing a docked band turns a 50-wide vertical strip into a
  # band-wide horizontal one, so the collapse glyph is no longer under the point that was clicked
  # and a positional test answers "not a piece" — which is exactly the tap-anywhere-to-expand case
  # below, and the collapse undid itself in the same click.
  #   A COLLAPSED frame expands on a tap ANYWHERE on its strip (program ruling C17): collapsed, a
  # frame IS its bar — a window's strip, a band's sliver — and at touch scale a sliver with one
  # small button at its end wastes its own target area.
  #   A tap on an EXPANDED strip keeps its own meaning: it PINS a transient frame — the pop-up
  # manifestation's one bar gesture, and the counterpart of the drag that moves it, since the
  # title is what you take hold of.
  mouseClickLeft: (ignored_pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    super
    return unless @frame?
    return if @_clickIsAPiecePress()
    if @frame.contents?.collapsed
      # a tap on the strip IS a press of the collapse switch, so it must do BOTH halves of one:
      # the switch flips its own glyph on its own click (the frame never drives it), and the
      # frame's verb does the expanding. Without the first half the strip would expand a frame and
      # leave the switch offering to expand it again.
      @collapseUncollapseSwitchButton?.setToggleState FrameBarWdgt.COLLAPSE_GLYPH
      @frame.uncollapseButtonInBarPressed()
      return
    @frame.pinPopUp @ if @frame.isTransientPopUp()

  # Was this escalated click a BUTTON piece's, rather than the strip's own? (the title text and
  # the strip background ARE the strip, and answer no.) A piece press stamps the event it acted on
  # and the click it escalates is that same event, so the two meet here without either the click
  # or the piece having to say where anything is.
  _clickIsAPiecePress: ->
    @_eventOfAPiecePress? and @_eventOfAPiecePress is WorldWdgt.timeOfEventBeingProcessed

  # A piece IS its SLOT -- the whole target box the strip advances by -- and DRAWS the glyph dial
  # centred inside it. Two dials, never one (program ruling G3: the bar arrange must never equate
  # a glyph with a box), and the piece takes the bigger of them: what a finger can hit is the slot,
  # while the ink stays the size the eye wants. The inset lives on the appearance, which is where
  # a shape already decides where it paints inside the box it is given.
  _layOutPieceInSlot: (piece, slotStart, spec) ->
    if spec.axis is "vertical"
      pieceBounds = new Rectangle new Point @left() + spec.padding, slotStart
    else
      pieceBounds = new Rectangle new Point slotStart, @top() + spec.padding
    piece.glyphSize = spec.glyphSize
    piece._reLayout pieceBounds.setBoundsWidthAndHeight spec.slotSize, spec.slotSize
