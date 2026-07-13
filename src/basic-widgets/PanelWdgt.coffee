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


  mouseClickLeft: (pos, ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey) ->
    @bringToForeground()

    # when you click on an "empty" part of a Panel that contains
    # a piece of text, we pass the click on to the text to it
    # puts the caret at the end of the text.
    # TODO the focusing and placing of the caret at the end of
    # the text should happen via API rather than via spoofing
    # a mouse event?
    if @parent? and @parent instanceof ScrollPanelWdgt
      # the caret is a world singleton; was `!(m instanceof CaretWdgt)` (type-test-elimination campaign)
      childrenNotCarets = @children.filter (m) ->
        m != world.caret
      if childrenNotCarets.length == 1
        item = @firstChildSuchThat (m) ->
          (m instanceof SimplePlainTextWdgt) and m.isEditable
        item?.mouseClickLeft item.bottomRight(), ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey


  # Gesture-driven re-fit of my enclosing container (@parent): DEFER to the cycle. Dispatched from
  # ActivePointerWdgt.drop AFTER a self-settling add (outside any pass) -> the else arm invalidates the
  # container so its _reLayout re-fits on the cycle. Gated on @parent?._reLayoutChildren? to preserve the
  # original "only a tracking container reacts" semantics. (fam 2 -- deferred-layout-residuals-audit.md)
  _reactToChildDropped: ->
    @_reFitContainer @parent

  _reactToChildRemoved: (child) ->
    return unless @parent?
    # Re-fit my enclosing container (@parent) -- but ONLY when this container is part of the LIVE layout.
    # A removal inside a DETACHED subtree (root neither world nor hand) re-fits nothing observable and is
    # deferred like every public mutator's off-world work (_settleLayoutsAfter's orphan early-return); the
    # subtree re-lays-out when re-attached (a self-settling add re-fits top-down -- BasementOpenerWdgt wraps
    # the off-world basement in a WindowWdgt and world.add-s it). Concretely the lost-widget re-home during a
    # pop-up close (Widget._closeNoSettle -> basement.scrollPanel.contents._addInPseudoRandomPositionNoSettle
    # -> _addNoSettle -> _reactToChildRemoved) fires here on the CLOSED basement's contents (root == BasementWdgt);
    # without this its wasted re-fit rode the per-frame end-of-cycle flush (the PanelWdgt._reactToChildRemoved
    # residual). The skip is SAFE specifically at this REMOVAL seam (the only detached case is the
    # never-painted basement): a blanket orphan-skip in the shared _invalidateLayout instead breaks
    # construction/detached-live layout, since orphan invalidates are generally load-bearing (every widget
    # is parent-less, hence an orphan, while being built). Attached removals (closing a window) re-fit as
    # before. (end-of-cycle-flush-drawdown -- ELIMINATE)
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
    # Container re-fit DEFERS to the cycle: aWdgt sits directly in a non-text-wrapping ScrollPanel's contents (me),
    # so when the settle loop lays aWdgt out it then re-fits the enclosing ScrollPanel via the ORDERED settle-time
    # re-fit (_reFitMyTrackingContainerAfterSettle, §4.3 -- successor to the deleted geom seam), whose _reLayout
    # re-fits it on the next doOneCycle. So the old ad-hoc synchronous @parent._reLayoutChildren() here is redundant
    # and removed. (fam 2 verify-and-drop -- deferred-layout-residuals-audit.md)
    aWdgt._applyMoveTo position


  detachesWhenDragged: ->
    if @parent?

      # otherwise you could detach a Frame contained in a
      # ScrollPanelWdgt which is very strange
      if @parent instanceof ScrollPanelWdgt
        return false

      return super

  grabsToParentWhenDragged: ->
    if @parent?

      # otherwise you could detach a Frame contained in a
      # ScrollPanelWdgt which is very strange
      if @parent instanceof ScrollPanelWdgt
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

  editButtonPressedFromWindowBar: ->
    if @dragsDropsAndEditingEnabled
      @disableDragsDropsAndEditing @
    else
      @enableDragsDropsAndEditing @

