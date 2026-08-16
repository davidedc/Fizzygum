class FolderWindowWdgt extends FrameWdgt


  constructor: (@closeButton, @contents, @internal = false) ->
    @contents = new ScrollPanelWdgt new FolderPanelWdgt
    super @contents, closeButton: @closeButton
    # wide enough for a 3-column icon grid at the desktop-icon pitch
    # (3 × 105 + the grid's edge padding + window chrome); overrides the
    # generic 300×300 FrameWdgt default, which clips the third column
    @setExtent new Point 340, 300


  representativeIcon: ->
    new GenericShortcutIconWdgt new FolderIconWdgt

  # A folder always has real content, so no "nothing to save" branch (§5.E E2:
  # the 'saveOrAsk' hook, routed through FrameWdgt.closeFromFrameBar's dispatch).
  _closeFromFrameBarWhenSaveOrAsk: ->
    # public-call-sanctioned + nosettle-sanctioned: this IS the close-from-bar
    # action; @close is the public self-settling close verb it legitimately
    # triggers (as the public closeFromFrameBar it replaced did).
    if !world.anyReferenceToWdgt @
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
  createReference: (placeToDropItIn = world, referenceName) ->
    widgetToAdd = new IconicDesktopSystemFolderShortcutWdgt @, referenceName
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    placeToDropItIn.add widgetToAdd
    widgetToAdd.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
    @bringToForeground()

