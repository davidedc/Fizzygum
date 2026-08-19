# I clip my subwidgets at my bounds. Which potentially saves a lot of redrawing
# and event handling.
# It's a good idea to use me whenever it's clear that there is a
# "container"/"contained" scenario going on.

class PanelWdgt extends Widget

  @augmentWith ClippingAtRectangularBoundsMixin, @name

  extraPadding: 0
  _acceptsDrops: true
  providesAmenitiesForEditing: true

  constructor: ->
    super()
    @dragsDropsAndEditingEnabled = true
    @appearance = new RectangularAppearance @

    @color = WorldWdgt.preferencesAndSettings.defaultPanelsBackgroundColor
    @strokeColor = WorldWdgt.preferencesAndSettings.defaultPanelsStrokeColor

  # Where among `children` (a childrenNotHandlesNorCarets list) does a payload dropped at screen point
  # `posOnScreen` land? Returns the sibling insertion index (bumped one past a child whose right half holds
  # the point), or undefined when the point is over no child — callers then fall back to appending at the end.
  # Pure computation; used verbatim by ToolPanelWdgt._addNoSettle.
  _findDropSlot: (posOnScreen, children) ->
    return undefined unless posOnScreen? and children.length > 0
    positionNumberAmongSiblings = 0
    for w in children
      if w.bounds.growBy(@internalPadding).containsPoint posOnScreen
        if w.bounds.growBy(@internalPadding).rightHalf().containsPoint posOnScreen
          positionNumberAmongSiblings++
        return positionNumberAmongSiblings
      positionNumberAmongSiblings++
    return undefined

  # only the desktop and folder panels have menu entries
  # to invoke this
  # `folderWindow` lets a caller supply a FolderWindowWdgt SUBCLASS while reusing the installation
  # ritual below (close to the shelf, make a shortcut, count the name). WorldWdgt.createDesktop is
  # the one such caller: the Examples folder is an ExamplesFolderWindowWdgt, which fills itself on
  # first open. Menu callers pass three arguments and get the plain folder, as before.
  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu for the shape): the menu items
  # carry no arguments at all, so both slots arrive empty and everything defaults.
  makeFolderFromMenu: (ignored, ignored2, name, folderWindow) ->
    @makeFolder name, folderWindow

  makeFolder: (name, folderWindow) ->
    newFolderWindow = folderWindow ? new FolderWindowWdgt
    newFolderWindow.close()
    # close + reference = the FILING ritual, so the icon left behind is the folder's PRIMARY
    # representation: content-presenting under the arrow contract (reference-widgets plan §4.4)
    # — bare folder art, and a copy of it deep-copies the folder.
    newFolderWindow.createReference @, (name or world.untitledNamingService.getNextUntitledFolderShortcutName()), representsContents: true
    world.untitledNamingService.noteShortcutCreated()
    return newFolderWindow

  # The panel half of the scrolled-content contract (scroll-frame role plan P5): the PURE
  # measure of my children for a content-sizing scroll frame, at the width the viewport gives
  # me (its viewport minus scroll padding — the same width the text re-wrap uses). A stack
  # overrides to measure at its OWN width; a folder/toolbar plane is never content-sizing, so
  # the viewport reads its applied bounds back instead of asking this.
  scrolledContentMeasure: (widthHint) ->
    @subWidgetsMergedPreferredBounds widthHint

  # The panel-side scroll-topology chokepoint (mirror of Widget._amIDirectlyInsideScrollPanelWdgt,
  # which asks the same question from a CONTENT widget's viewpoint): am I the panel a scroll
  # frame clips and scrolls? Asked of the PARENT as a role query (ScrollPanelWdgt.isMyContentsPanel
  # — scroll-frame role plan P3), so it is true for ANY panel-family class serving as a plane
  # (the default ScrolledPaneWdgt, a FolderPanelWdgt, a ToolPanelWdgt), and the two policy
  # callers below (detach refusal, grab-to-parent) read as intent.
  _amITheContentsPanelOfAScrollPanelWdgt: ->
    (@parent?.isMyContentsPanel? @) ? false

  # Do my direct children get the "lock to panel/desktop" menu toggle? Panels are lockable
  # surfaces (the world included); a scroll frame doesn't define this capability at all — its
  # direct children are chrome — while children INSIDE the scrolled contents get the toggle
  # from their own PanelWdgt parent. Capability via ?() at the lock-menu site
  # (type-test-elimination ε).
  childrenCanLockToMe: ->
    true

  # (the click-to-caret forward for a scrolled pane holding one text lives on
  # ScrolledPaneWdgt.mouseClickLeft, which supers into this)
  mouseClickLeft: (pos, ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey) ->
    @bringToForeground()


  # Gesture-driven re-fit of my enclosing container (@parent): DEFER to the cycle. Dispatched from
  # ActivePointerWdgt.drop AFTER a self-settling add (outside any pass) -> the else arm invalidates the
  # container so its _reLayout re-fits on the cycle. Gated on @parent?._reLayoutChildren? to preserve the
  # original "only a tracking container reacts" semantics. (fam 2 -- deferred-layout-residuals-audit.md)
  # (the scroll-holder relays — _reactToChild*InScrollPanel — live on ScrolledPaneWdgt, which
  # supers into these; scroll-frame role plan P3)
  _reactToChildDropped: (droppedWidget) ->
    @_reFitContainer @parent

  _reactToChildRemoved: (child) ->
    return unless @parent?
    # Skip the re-fit when @isOrphan() -- SAFE ONLY at this REMOVAL seam (not a blanket rule: a shared
    # orphan-skip in _invalidateLayout broke 63 tests). Attached removals re-fit as before -- see docs/archive/end-of-cycle-flush-endgame-plan.md.
    return if @isOrphan()
    @_reFitContainer @parent

  # puts the widget in the ScrollPanel
  # in some sparse manner and keeping it
  # "in view"
  # NON-settling: every caller (a drop into the bin via BinOpenerWdgt._reactToChildDropped, the
  # close/lost re-home chain) runs inside an enclosing settle, so this must not re-enter the settle tier
  # through a public add. (The public self-settling wrapper was removed when its last caller -- the drop --
  # went cores-only; nothing needs a standalone settling entry here.)
  _addInPseudoRandomPositionNoSettle: (aWdgt) ->
    width = @width()
    height = @height()

    posx = Math.abs(aWdgt.hashCode()) % width
    posy = Math.abs((aWdgt.toString() + "x").hashCode()) % height
    position = @position().add new Point posx, posy

    @_addNoSettle aWdgt
    aWdgt._applyMoveTo position
    # The settle-time up-edge alone does NOT cover this: it's gated on FRAME-CHANGE, and a scattered widget
    # already settles AT the frame the move above applied -- the re-fit below must be scheduled explicitly. See docs/archive/ordered-downwalk-stage-b-plan.md (§9-N2).
    @_reFitContainer @parent


  detachesWhenDragged: ->
    if @parent?

      # otherwise you could detach a Frame contained in a
      # ScrollPanelWdgt which is very strange
      if @_amITheContentsPanelOfAScrollPanelWdgt()
        return false

      return super

  grabsToParentWhenDragged: ->
    if @parent?

      # otherwise you could detach a Frame contained in a
      # ScrollPanelWdgt which is very strange
      if @_amITheContentsPanelOfAScrollPanelWdgt()
        if @parent.canScrollByDraggingBackground and @parent.anyScrollBarShowing()
          return false
        else
          return true

      return super

    # doesn't have a parent
    return false
  
  _reactToChildGrabbed: (child) ->
    @_reFitContainer @parent

  # PanelWdgt menus:
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    if @children.length
      menu.addLine()
      menu.addMenuItem "move all inside", @, "keepAllSubwidgetsWithin", toolTip: "keep all subwidgets\nwithin and visible"
  
  keepAllSubwidgetsWithin: ->
    @children.forEach (m) =>
      m._moveWithin @

