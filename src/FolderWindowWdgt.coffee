class FolderWindowWdgt extends FrameWdgt

  # true for a folder window opened INSIDE another container rather than on the
  # desktop; the constructor takes it and defaults it to false
  internal: undefined

  constructor: (@closeButton, @contents, @internal = false) ->
    @contents = new ViewportWdgt new FolderPanelWdgt
    super @contents, closeButton: @closeButton
    # my viewport has no border of its own: my frame and my strip's rule are its lines, and a border
    # just inside them would double each (visual-design-system §4.1; my panel has none either,
    # FolderPanelWdgt). MY viewport is dressed in the folder viewport's border (ViewportWdgt
    # .wearPaneRoles: folderViewportStroke, none) as it is built -- a viewport anywhere else keeps
    # its border -- the way a code area is (CodeAreaWdgt._newCodeArea); its fill is my panel's,
    # which it mimics.
    @contents.wearPaneRoles stroke: "folderViewportStroke"
    # I open showing a whole grid of icons with no scroll bar: as many columns as my panel's grid
    # lays in a row, and the theme's folderWindowIconRows rows (the grid's own extent for them,
    # IconGridPanelWdgt.extentShowingIconGrid), inside my chrome -- my border, my strip and its
    # rule, measured by the same _chromeWidth / _chromeHeight my arrange takes out of my extent, so
    # my viewport is exactly that grid. (The generic 300×300 FrameWdgt default clips the third
    # column.) Imposed after the construction above rather than answered as my _initialExtent: my
    # content's first placement sizes me from the content's own extent (the hug in
    # FrameWdgt._positionAndResizeChildren), while this is an extent my content is to take.
    panel = @contents.contents
    grid = panel.extentShowingIconGrid panel.iconsLayingInGridWrapCount, WorldWdgt.theme.folderWindowIconRows
    @setExtent new Point (grid.x + @_chromeWidth()), (grid.y + @_chromeHeight(@contents.contentStackSpec()))


  # my ART, not a badge decision: the arrow contract (reference-widgets plan §4.4) reserves the
  # arrow composite for genuine reference icons; representativeIcon is "the content's icon" and
  # feeds the INNER art of whatever icon wraps it.
  representativeIcon: ->
    new FolderIconWdgt

  # my viewport is internal structure — hide it from the ancestor hierarchy
  # (disambiguation) menu, exactly as a viewport hides its own contents panel
  # (see ViewportWdgt.hidesContainedWidgetFromHierarchyMenu; asked by
  # Widget.hierarchyMenuWidgets via ?()).
  hidesContainedWidgetFromHierarchyMenu: (aWdgt) ->
    aWdgt is @contents

  # A folder always has real content, so no "nothing to save" branch (§5.E E2:
  # the 'saveOrAsk' hook, routed through FrameWdgt.closeFromFrameBar's dispatch).
  _closeFromFrameBarWhenSaveOrAsk: ->
    # public-call-sanctioned + nosettle-sanctioned: this IS the close-from-bar
    # action; @close is the public self-settling close verb it legitimately
    # triggers (as the public closeFromFrameBar it replaced did).
    if !world.anyReferenceOrWireIntoWdgt @
      prompt = new SaveShortcutPromptWdgt @, @
      prompt.popUpAtHand()
    else
      @close()

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @contents.contents.addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu

  # A folder's own reference is a folder shortcut. Same parameter order and same `world` default as
  # the rest of the family (Widget.createReference), so the menu adapter's no-argument call lands
  # the shortcut on the desktop here exactly as it does everywhere else.
  # opts.representsContents threads the arrow contract exactly as in the base (plan §4.4):
  # PanelWdgt.makeFolder passes true — the icon it leaves behind is the folder's PRIMARY
  # representation (bare art, deep copy) — while the menu's "Create shortcut" defaults to a
  # deliberate arrow'd alias.
  createReference: (placeToDropItIn = world, referenceName, opts = {}) ->
    widgetToAdd = @_buildShortcutWidget referenceName, opts
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    placeToDropItIn.add widgetToAdd
    widgetToAdd.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
    @bringToForeground()

  # the core's shortcut-class seam (Widget._buildShortcutWidget): a folder's shortcut is a
  # folder shortcut on EVERY creation path — the menu override above, makeFolder's filing, and
  # a folder WINDOW filed into another folder (which otherwise falls to the base document
  # shortcut, losing the drop-into-me affordance).
  _buildShortcutWidget: (referenceName, opts) ->
    new FolderShortcutWdgt @, referenceName, representsContents: opts.representsContents

