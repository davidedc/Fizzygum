# This is an icon, with a caption below, AND it has some logic
# to be shown "in its own layer" together with the
# other desktop system links. I.e. you never see a desktop system link
# on top of a window (unless during a drag), so in that sense
# the desktop system links live in their own "layer"
#
# My TILE answers the pointer the way a button does (visual-design-system §4.3): at rest paper inside
# a line border, hovered desk, pressed chrome inside a frame border -- the desktopIconTile* roles,
# read from the hand's answers about me at every paint. My glyph keeps its one ink in every state,
# and my plate and caption theirs.
#   My glyph is a PICTURE, never a pointer target (_showsChildAsAPicture), so a press anywhere on my
# tile is a press on ME: the press, the release and the click all reach me together, and my tile's
# look follows each of them -- pressed while the press lasts, then, once it ends, hovered or at rest
# by where the pointer is, at rest when the pointer leaves. A press on my plate is a press on my
# caption (a rename) and shows no press on my tile (_showsPressOnMyTile).

class DesktopLinkWdgt extends WidgetHolderWithCaptionWdgt

  # the link's caption text. Declared HERE rather than on ShortcutWdgt
  # because AppLauncherWdgt is a sibling of that class, not a
  # subclass — this is the tightest base that covers all five writers.
  title: undefined

  # MY GLYPH IS A PICTURE (Widget.isPointerTargetAt, AM-I-A-PICTURE): nothing in my icon's subtree
  # is a pointer target, so a press on the glyph is a press on me, exactly as one on the tile around
  # it. Declared here and not on every holder: a bare holder's default glyph is its drop placeholder
  # (SimpleDropletWdgt), whose whole job is to take a drop, and a bare holder has no press look or
  # tile action that a press on its glyph could miss (its activation escalates either way).
  _showsChildAsAPicture: (child) ->
    child is @icon

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): my look is
  # my TILE's, which my appearance reads from the two answers below as it paints, so I repaint -- no
  # colour of mine is written, and none a gesture could leave behind.
  notePointerStateChanged: ->
    @_changed()

  # Does my TILE show a press? While the hand presses me (ActivePointerWdgt.pressesOn), unless that
  # press LANDED on my PLATE: one there is a press on my caption, a rename
  # (WidgetHolderWithCaptionWdgt._pressIsOnMyPlate), and shows nothing on my tile. Where it landed is
  # the hand's fact (mouseDownPosition, on the screen), asked into my plane as the hand hands a press
  # its point.
  _showsPressOnMyTile: ->
    return false unless world.hand.pressesOn @
    pressPoint = world.hand.mouseDownPosition
    not @_pressIsOnMyPlate (@screenPointToMyPlane pressPoint if pressPoint?)

  # my tile's fill and border for the pointer state I show now, which my appearance reads as it paints
  _fillForMyState: ->
    theme = WorldWdgt.theme
    if @_showsPressOnMyTile()
      theme.desktopIconTilePressedFill
    else if world.hand.restsOn @
      theme.desktopIconTileHoverFill
    else
      theme.desktopIconTileFill

  _strokeForMyState: ->
    theme = WorldWdgt.theme
    if @_showsPressOnMyTile() then theme.desktopIconTilePressedStroke else theme.desktopIconTileStroke

  moveOnTopOfTopReference: ->
    # find the topmost OTHER desktop icon to layer myself just above it
    # (instead of `c instanceof WidgetHolderWithCaptionWdgt`; type-test-elimination campaign)
    topMostReference = @parent.topmostChildSuchThat (c) =>
      c != @ and c.isDesktopIcon?()
    if topMostReference?
      @parent.children.remove @
      index = @parent.children.indexOf topMostReference
      @parent.children.splice (index + 1), 0, @
    else
      @parent.children.remove @
      @parent.children.unshift @

  # When dropped onto a folder's ICON I move directly into its contents (I am a desktop icon),
  # rather than the default "create a reference", and take the folder's NEXT FREE SLOT
  # (IconGridPanelWdgt._placeIconInNextFreeSlotNoSettle): the place I held is the desktop's or
  # another folder's, and a drop onto the icon brings no place inside the folder. (Dropped into
  # the folder's open WINDOW I am the panel's child already, where I was dropped, and stay there:
  # FolderPanelWdgt.)
  # FolderShortcutWdgt keys its drop off this instead of `instanceof DesktopLinkWdgt`
  # (type-test-elimination campaign), and calls it inside the drop's single settle, so add and
  # move through the non-settling cores.
  _reactToBeingDroppedIntoFolder: (folderContents) ->
    folderContents._addNoSettle @
    folderContents._placeIconInNextFreeSlotNoSettle @

