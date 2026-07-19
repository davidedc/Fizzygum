# I clip my subwidgets at my bounds. Which potentially saves a lot of redrawing
# and event handling.
# It's a good idea to use me whenever it's clear that there is a
# "container"/"contained" scenario going on.

class PanelWdgt extends Widget

  @augmentWith ClippingAtRectangularBoundsMixin, @name

  scrollPanel: nil
  extraPadding: 0
  _acceptsDrops: true
  providesAmenitiesForEditing: true

  # if this Panel belongs to a ScrollPanel, then
  # the @scrollPanel points to it
  constructor: (@scrollPanel = nil) ->
    super()
    @dragsDropsAndEditingEnabled = true
    @appearance = new RectangularAppearance @

    @color = WorldWdgt.preferencesAndSettings.defaultPanelsBackgroundColor
    @strokeColor = WorldWdgt.preferencesAndSettings.defaultPanelsStrokeColor

    if @scrollPanel
      @noticesTransparentClick = false

  colloquialName: ->
    "panel"

  # Where among `children` (a childrenNotHandlesNorCarets list) does a payload dropped at screen point
  # `posOnScreen` land? Returns the sibling insertion index (bumped one past a child whose right half holds
  # the point), or nil when the point is over no child — callers then fall back to appending at the end.
  # Pure computation; shared verbatim by HorizontalMenuPanelWdgt.add and ToolPanelWdgt._addNoSettle.
  _findDropSlot: (posOnScreen, children) ->
    return nil unless posOnScreen? and children.length > 0
    positionNumberAmongSiblings = 0
    for w in children
      if w.bounds.growBy(@internalPadding).containsPoint posOnScreen
        if w.bounds.growBy(@internalPadding).rightHalf().containsPoint posOnScreen
          positionNumberAmongSiblings++
        return positionNumberAmongSiblings
      positionNumberAmongSiblings++
    return nil

  # only the desktop and folder panels have menu entries
  # to invoke this
  makeFolder: (ignored, ignored2, name) ->
    newFolderWindow = new FolderWindowWdgt
    newFolderWindow.close()
    newFolderWindow.createReference (name or world.untitledNamingService.getNextUntitledFolderShortcutName()), @
    world.untitledNamingService.noteShortcutCreated()
    return newFolderWindow

  setColor: (aColorOrAWidgetGivingAColor, widgetGivingColor) ->
    aColor = super aColorOrAWidgetGivingAColor, widgetGivingColor
    # keep in sync the value of the container scrollPanel
    # if there is one. Note that the container scrollPanel
    # is actually not painted.
    if @scrollPanel
      if @scrollPanel.color?.equals aColor
        return
      @scrollPanel.color = aColor
      @scrollPanel.changed()

    return aColor


  setAlphaScaled: (alphaOrWidgetGivingAlpha, widgetGivingAlpha) ->
    alpha = super(alphaOrWidgetGivingAlpha, widgetGivingAlpha)
    if @scrollPanel
      unless @scrollPanel.alpha == alpha
        @scrollPanel.alpha = alpha
    return alpha


  # The panel-side scroll-topology chokepoint (mirror of Widget._amIDirectlyInsideScrollPanelWdgt,
  # which asks the same question from a CONTENT widget's viewpoint): is my parent a scroll frame —
  # i.e. am I the panel it clips and scrolls? ONE place tests the class; the three policy callers
  # (click-to-caret forward, detach refusal, grab-to-parent) read as intent.
  # (type-test-elimination ε: LEAVE-with-cleanup — see the plan's LEAVE section.)
  _amITheContentsPanelOfAScrollPanelWdgt: ->
    @parent? and @parent instanceof ScrollPanelWdgt

  # Do my direct children get the "lock to panel/desktop" menu toggle? Panels are lockable
  # surfaces (the world included); a scroll frame opts OUT — its direct children are chrome,
  # while children INSIDE the scrolled contents get the toggle from their own PanelWdgt parent.
  # Capability, was `(parent instanceof PanelWdgt) and !(parent instanceof ScrollPanelWdgt)`
  # at the lock-menu site (type-test-elimination ε).
  childrenCanLockToMe: ->
    true

  mouseClickLeft: (pos, ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey) ->
    @bringToForeground()

    # when you click on an "empty" part of a Panel that contains
    # a piece of text, we pass the click on to the text to it
    # puts the caret at the end of the text.
    # TODO the focusing and placing of the caret at the end of
    # the text should happen via API rather than via spoofing
    # a mouse event?
    if @_amITheContentsPanelOfAScrollPanelWdgt()
      # the caret is a world singleton; was `!(m instanceof CaretWdgt)` (type-test-elimination campaign)
      childrenNotCarets = @children.filter (m) ->
        m != world.caret
      if childrenNotCarets.length == 1
        item = @firstChildSuchThat (m) ->
          (m instanceof SimpleTextWdgt) and m.isEditable
        item?.mouseClickLeft item.bottomRight(), ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey


  # Gesture-driven re-fit of my enclosing container (@parent): DEFER to the cycle. Dispatched from
  # ActivePointerWdgt.drop AFTER a self-settling add (outside any pass) -> the else arm invalidates the
  # container so its _reLayout re-fits on the cycle. Gated on @parent?._reLayoutChildren? to preserve the
  # original "only a tracking container reacts" semantics. (fam 2 -- deferred-layout-residuals-audit.md)
  _reactToChildDropped: ->
    @_reFitContainer @parent

  _reactToChildRemoved: (child) ->
    return unless @parent?
    # Skip the re-fit when @isOrphan() -- SAFE ONLY at this REMOVAL seam (not a blanket rule: a shared
    # orphan-skip in _invalidateLayout broke 63 tests). Attached removals re-fit as before -- see docs/archive/end-of-cycle-flush-endgame-plan.md.
    return if @isOrphan()
    @_reFitContainer @parent

  _reactToChildAdded: (child) ->
    # the BasementWdgt has a filter that can
    # show/hide the contents of this pane
    # based on whether they are reachable or
    # not. So let's notify it.
    if @parent?
      if @parent.parent?
        if @parent.parent._reactToChildAddedInScrollPanel?
          @parent.parent._reactToChildAddedInScrollPanel child

  # puts the widget in the ScrollPanel
  # in some sparse manner and keeping it
  # "in view"
  # NON-settling: every caller (a drop into the basement via BasementOpenerWdgt._reactToChildDropped, the
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

