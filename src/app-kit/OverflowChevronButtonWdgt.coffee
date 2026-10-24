# The trailing piece of a toolbar strip that has more tools than it can show: it pops the
# REMAINDER as a menu (the macOS / tablet toolbar convention). One leaf of the shared icon-button
# family -- a toolThumbnailSize target drawing a chevron inset in it (ruling G3) -- built and
# retired by ToolPanelWdgt's own arrange, so it exists exactly while some tool is hidden and a
# strip that shows everything carries no chevron at all.
#
# I LOOK LIKE A TOOL in its cell (OverflowChevronAppearance): a plate in the tool cell's fill for my
# state -- none at rest, hovered, pressed -- under the drawn » at the glyph size my strip names
# (ToolPanelWdgt writes my glyphSize as it places me), in the toolbarGlyph ink in every state. The
# icon button's state inks (IconButtonWdgt._updateColor) never reach my glyph: my look reads my
# state as it paints, so a transition writes no colour (_updateColor), and I hold none.
#
# The remainder menu is DERIVED at pop time from the tools currently hidden -- each row's name,
# picture and tick (ticked while its tool is the active one) -- and it is a
# transient pop-up: there is no wiring keeping it in step with the strip, because a strip that
# re-arranges under an open menu dismisses that menu as it dismisses any other transient. One
# widget, one staleness signal.

class OverflowChevronButtonWdgt extends IconButtonWdgt

  toolTipMessage: "more tools"

  createAppearance: -> new OverflowChevronAppearance @, WorldWdgt.theme.toolbarGlyph

  # MY FACE IS A PICTURE (Widget.isPointerTargetAt, AM-I-A-PICTURE): the empty face every icon
  # button carries covers my whole box, so it would catch a press in my plate's corner notches.
  # Nothing in it is a pointer target: the press, the release and the click are mine, and where I
  # catch the pointer is my plate's shape.
  _showsChildAsAPicture: (child) ->
    child is @faceWidget

  # HighlightableMixin's colour hook, which every one of its state transitions calls after setting
  # @state. My look for a state is read from it as my appearance paints, so a transition only
  # repaints me: no colour of mine is written here, and none a transition could leave behind.
  _updateColor: ->
    @_changed()

  actOnClick: ->
    # the strip owns the answer to "what is behind me" -- capability via ?(), so a chevron that
    # somehow sits outside a tool panel simply has nothing to offer.
    hiddenCells = @parent?.cellsBehindTheOverflowChevron?() ? []
    return if hiddenCells.length is 0
    menu = new MenuWdgt @, target: @, title: "more tools"
    # EDITOR CHROME, declared (Frame-model §5.D D2a, the ChangeFontButtonWdgt spelling): my rows
    # ARE the strip's tools, and a strip's tools act ON the widget being edited -- which is why
    # ToolbarWdgt declares the whole strip exempt, and why the overflow that stands in for part of
    # that strip must say the same. The pointer honours the declaration by ANCESTRY, so the root
    # menu answering covers every row, its labels and its icons; without it, opening the overflow
    # would end the very edit its rows are about to act on. My own press is already covered: every
    # icon button in the IconButtonWdgt family is chrome.
    menu.actsAsEditorChrome = true
    for cell in hiddenCells
      tool = cell.glassBoxItem?() ? cell
      # a hidden tool that is the ACTIVE one (isActiveTool: the armed paint tool, a text tool
      # mirroring the edited text) says so with its row's tick, as its cell would with its plate --
      # read now, at pop time, like everything else in this menu. The row names its tool by the
      # tool's tooltip (or, lacking one, its colloquial name), capitalised as a row is ("Change
      # font"); the tooltip itself reads as it does.
      menu.addMenuItem (CommandPanelWdgt.rowLabelOfValue (tool.toolTipMessage ? tool.colloquialName())), @, "triggerToolFromMenu",
        arg1: cell
        icon: @_miniatureOf tool
        ticked: (if tool.isActiveTool?() then true else undefined)
    menu.popUpAtHand()

  # A ROW SHOWS WHAT ITS TOOL LOOKS LIKE: a picture of the tool at glyph size, beside the name.
  # The picture is taken HERE, at pop time, from the tool as it stands -- the same derive-at-pop
  # rule the rest of this menu follows, so a strip that re-arranges never leaves a stale portrait
  # behind; the menu is transient and goes with the strip.
  #   A COPY is photographed rather than the tool itself, because fitting it to the glyph box
  # means resizing it, and the tool on the strip must not move. The copy exists for one shot and
  # is destroyed straight after: what the row keeps is a picture (InertIconHolderWdgt: pixels, or
  # for a typed face a live copy of the face's appearance, never the tool), which is also what keeps
  # the row's tap the ROW's -- a live tool held on a row would take the tap itself.
  #   An undefined icon is simply a label-only row (MenuItemWdgt), so a tool that cannot be copied
  # costs its row nothing.
  _miniatureOf: (tool) ->
    # nosettle-sanctioned: fullCopy has no NoSettle core -- it self-settles only to file copied
    # referent figures to the shelf, which a toolbar tool contributes none of. I am reached ONLY
    # from actOnClick, an event-stream handler, so a settle here is legal and never mid-pass.
    picture = tool.fullCopy?()
    return undefined unless picture?
    glyphBox = WorldWdgt.theme.menuRowGlyphSize
    icon = new InertIconHolderWdgt picture, fitInto: new Point glyphBox, glyphBox
    picture._fullDestroyNoSettle()
    icon

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu for the shape): dispatch fills the
  # leading slots with the menu item + the menu's subject, so the cell this row stands for rides
  # slot 3.
  #   ONE DISPATCH CONTRACT, no per-family case: a row does what a TAP on its grid cell does, and
  # a tap is an activated on whatever the cell puts under the pointer -- the LID over a
  # drag-out thumbnail, or the tool itself where it handles its own clicks. The cell answers
  # which; clicking the wrapped tool instead leaves every lid-covered tool inert, because such a
  # tool is there to be COPIED and carries no click at all. Capability via ?() throughout, so a
  # cell with nothing clickable in it is simply inert.
  triggerToolFromMenu: (ignored, ignored2, cell) ->
    (cell.thumbnailClickReceiver?() ? cell).activated?()
