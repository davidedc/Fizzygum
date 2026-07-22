# The title bar of a FrameWdgt -- ONE child that owns the five title-strip
# pieces (titlebarBackground, label, close button, collapse/uncollapse switch,
# pencil-eye edit button), their strip arrange, and the title half of the
# window/card skin (the body half stays on the frame). The frame keeps ALIAS
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

  frame: nil
  titlebarBackground: nil
  label: nil
  closeButton: nil
  collapseUncollapseSwitchButton: nil
  editButton: nil

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

  # I draw NOTHING myself -- my titlebarBackground piece draws the strip -- so I am
  # transparent EVERYWHERE and hit-testing must fall THROUGH me: to my pieces (opaque
  # where the strip is drawn), to the frame body at the 1px border the background
  # doesn't cover, and -- at the frame's transparent rounded-corner notches -- on
  # through to whatever is BEHIND the frame. Without this the base answers OPAQUE
  # (the explicit appearance-less default) and I would intercept hits at those corner
  # pixels the frame's own appearance reports transparent -- observed as the desktop
  # folder shortcut losing its pointer-under state when its window spawns at the
  # click point (same corner story as MenuWdgt / PromptWdgt, container arc §5.6).
  isTransparentAt: (aPoint) ->
    true

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
  # Mirrors the frame's historical chrome build exactly: background and the two
  # buttons are keep-if-exist (rebuilds re-add the same instances), the label is
  # destroyed + rebuilt every time (its text follows the content). The caller
  # (the frame) passes its labelContent and -- on the first build -- any
  # ctor-supplied close button (FolderWindowWdgt injects its own).
  _buildAndConnectPiecesNoSettle: (labelContent, suppliedCloseButton) ->
    if !@titlebarBackground?
      @_buildTitlebarBackground()

    # label -- tear down through the non-settling core (inside the rebuild's settle)
    @label?._fullDestroyNoSettle()
    @label = new StringWdgt labelContent, WorldWdgt.preferencesAndSettings.titleBarTextFontSize

    # as of March 2018, Safari 10.1.1 on OSX 10.12.5 :
    # safari's rendering of bright text on dark background is atrocious
    # so we have to force bold style in the window bars
    if /^((?!chrome|android).)*safari/i.test navigator.userAgent
      @label.isBold = true
    else
      @label.isBold = WorldWdgt.preferencesAndSettings.titleBarBoldText

    @label.color = Color.WHITE
    @_addNoSettle @label

    # upper-left button, often a close button
    # but it can be anything
    if !@closeButton?
      @closeButton = suppliedCloseButton ? new CloseIconButtonWdgt
    @_addNoSettle @closeButton

    if !@collapseUncollapseSwitchButton?
      collapseButton = new CollapseIconButtonWdgt
      uncollapseButton = new UncollapseIconButtonWdgt
      @collapseUncollapseSwitchButton = new SwitchButtonWdgt [collapseButton, uncollapseButton]
    @_addNoSettle @collapseUncollapseSwitchButton

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
    if @frame.isInternal()
      @titlebarBackground = new RectangleWdgt
    else
      @titlebarBackground = new BoxWdgt

    @_setAppearanceAndColorOfTitleBackground()
    @_addNoSettle @titlebarBackground

  # The title-bar half of the internal/external skin (the body half is
  # FrameWdgt._deriveAndSetBodyAppearance), re-derived from the frame's
  # parentage on every (re)parenting.
  _setAppearanceAndColorOfTitleBackground: ->
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

  _destroyEditButtonNoSettle: ->
    @editButton?._destroyNoSettle()
    @editButton = nil

  # ===== the strip arrange =====
  # The bar's bounds ARE the frame's top strip (the frame hands them over in
  # its own arrange via `@bar._reLayout barBounds`), so all the piece math
  # reads off MY origin/extent -- the same absolute pixels the frame's flat
  # arrange produced.

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
    closeIconSize = FrameWdgt.CLOSE_ICON_SIZE
    padding = @frame.padding

    # close button
    if @closeButton? and @closeButton.parent == @
      buttonBounds = new Rectangle new Point @left() + padding, @top() + padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @closeButton._reLayout buttonBounds

    # collapse/uncollapse button
    if @collapseUncollapseSwitchButton? and @collapseUncollapseSwitchButton.parent == @
      buttonBounds = new Rectangle new Point @left() + closeIconSize + 2 * padding, @top() + padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @collapseUncollapseSwitchButton._reLayout buttonBounds

    @titlebarBackground._applyBounds (@position().add new Point 1,1), (new Point @width(), closeIconSize + 2 * padding).subtract new Point 2,2
    # TODO this looks better:
    #@titlebarBackground._applyExtent (new Point @width(), closeIconSize + 2 * padding).subtract new Point 4,4
    #@titlebarBackground._applyMoveTo @position().add new Point 2,2

    # NON-settling cores (not the public collapse/unCollapse): this is a layout pass, so reaching the
    # self-settling wrapper would re-enter the flush. The cores are idempotent, so an already-correct
    # button is a no-op exactly as the public guards made it. (check-layering [G])
    # The edit button is the rightmost title-bar button, so it collapses at
    # narrow widths to leave the label room.
    if @width() < 3 * (closeIconSize + padding) + padding
      @editButton?._collapseNoSettle()
    else
      @editButton?._unCollapseNoSettle()

    # label
    if @label? and @label.parent == @
      labelLeft = @left() + padding + 2 * (closeIconSize + padding)
      labelTop = @top() + padding
      labelRight = @right() - padding
      if @editButton? and !@editButton.isInCollapsedSubtree()
        labelRight -= 1 * (closeIconSize + padding)
      labelWidth = labelRight - labelLeft

      labelBounds = new Rectangle new Point labelLeft, labelTop
      labelBounds = labelBounds.setBoundsWidthAndHeight labelWidth, WorldWdgt.preferencesAndSettings.titleBarTextHeight
      @label._applyGrantedBounds labelBounds

    # edit button -- the sole right-hand title-bar button, in the rightmost slot.
    if @editButton? and !@editButton.isInCollapsedSubtree() and @editButton.parent == @
      buttonBounds = new Rectangle new Point @right() - 1 * (closeIconSize + padding), @top() + padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @editButton._reLayout buttonBounds
