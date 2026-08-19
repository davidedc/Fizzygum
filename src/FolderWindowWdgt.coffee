class FolderWindowWdgt extends FrameWdgt

  # true for a folder window opened INSIDE another container rather than on the
  # desktop; the constructor takes it and defaults it to false
  internal: undefined

  constructor: (@closeButton, @contents, @internal = false) ->
    @contents = new ScrollPanelWdgt new FolderPanelWdgt
    super @contents, closeButton: @closeButton
    # wide enough for a 3-column icon grid at the desktop-icon pitch
    # (3 × 105 + the grid's edge padding + window chrome); overrides the
    # generic 300×300 FrameWdgt default, which clips the third column
    @setExtent new Point 340, 300


  # my ART, not a badge decision: the arrow contract (reference-widgets plan §4.4) reserves the
  # arrow composite for genuine reference icons; representativeIcon is "the content's icon" and
  # feeds the INNER art of whatever icon wraps it.
  representativeIcon: ->
    new FolderIconWdgt

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
  # representation (bare art, deep copy) — while the menu's "create shortcut" defaults to a
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

