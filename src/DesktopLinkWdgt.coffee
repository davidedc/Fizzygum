# This is an icon, with a caption below, AND it has some logic
# to be shown "in its own layer" together with the
# other desktop system links. I.e. you never see a desktop system link
# on top of a window (unless during a drag), so in that sense
# the desktop system links live in their own "layer"
#
# My TILE answers the pointer the way a button does (visual-design-system §4.3): at rest paper inside
# a line border, hovered desk, pressed chrome inside a frame border -- the desktopIconTile* roles,
# re-derived from my HighlightableMixin state at every paint. My glyph keeps its one ink in every
# state, and my plate and caption theirs.
#   My glyph is a PICTURE, never a pointer target (_showsChildAsAPicture), so a press anywhere on my
# tile is a press on ME: the press, the release and the click all reach me together, and my tile's
# look follows each of them -- pressed while the press lasts, hovered once it ends (pressEnded),
# at rest when the pointer leaves. A press on my plate is a press on my caption (a rename) and leaves
# my tile's look alone (pressBegan).

class DesktopLinkWdgt extends WidgetHolderWithCaptionWdgt

  @augmentWith HighlightableMixin, @name

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

  # HighlightableMixin's colour hook, which every one of its state transitions calls (hoverEntered,
  # hoverExited, pressBegan, pressEnded) after setting @state. My look for a state is my TILE's,
  # which my appearance reads from the two answers below as it paints, so a transition only repaints
  # me: no colour of mine is written here, and none a transition could leave behind. (Which is also
  # why I wear none of the mixin's own colours, color_normal / color_hover / color_pressed.)
  _updateColor: ->
    @_changed()

  # HighlightableMixin's press transition, re-answered by WHERE the press landed: one on my TILE
  # presses me (the pressed look while it lasts); one on my PLATE is a press on my caption, a rename
  # (WidgetHolderWithCaptionWdgt._pressIsOnMyPlate), and leaves my state, and so my tile's look, as
  # it is. Either way the press then goes on as any widget's does (Widget.pressBegan).
  pressBegan: (pos) ->
    unless @_pressIsOnMyPlate pos
      @state = @STATE_PRESSED
      @_updateColor()
    super

  # HighlightableMixin's release transition, re-answered: a release reaches me only when it ends the
  # press that began on me with the pointer still over me (ActivePointerWdgt.processPointerUp), so
  # I am hovered, not at rest -- the pointer leaving me (hoverExited) is what brings the rest look
  # back.
  pressEnded: ->
    @state = @STATE_HIGHLIGHTED
    @_updateColor()

  _fillForMyState: ->
    theme = WorldWdgt.theme
    switch @state
      when @STATE_PRESSED then theme.desktopIconTilePressedFill
      when @STATE_HIGHLIGHTED then theme.desktopIconTileHoverFill
      else theme.desktopIconTileFill

  _strokeForMyState: ->
    theme = WorldWdgt.theme
    if @state is @STATE_PRESSED then theme.desktopIconTilePressedStroke else theme.desktopIconTileStroke

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

