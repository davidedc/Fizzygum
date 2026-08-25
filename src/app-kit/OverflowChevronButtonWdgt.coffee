# The trailing piece of a toolbar strip that has more tools than it can show: it pops the
# REMAINDER as a menu (the macOS / tablet toolbar convention). One leaf of the shared icon-button
# family -- a toolThumbnailSize target drawing a chevron inset in it (ruling G3) -- built and
# retired by ToolPanelWdgt's own arrange, so it exists exactly while some tool is hidden and a
# strip that shows everything carries no chevron at all.
#
# The remainder menu is DERIVED at pop time from the tools currently hidden, and it is a
# transient pop-up: there is no wiring keeping it in step with the strip, because a strip that
# re-arranges under an open menu dismisses that menu as it dismisses any other transient. One
# widget, one staleness signal.

class OverflowChevronButtonWdgt extends IconButtonWdgt

  toolTipMessage: "more tools"

  constructor: ->
    super()
    # A strip is a light surface, so the mark takes the dark icon line colour rather than the
    # button family's near-white default.
    #   It is `color_normal` -- the RESTING colour of the highlight state machine -- and not a
    # bare `@color`: HighlightableMixin repaints me at color_normal on every mouseLeave and
    # mouseUpLeft, so a colour set beside it survives only until the first pointer visit and I
    # then go near-white on a near-white strip. @color follows it so my very first paint, before
    # any pointer has reached me, is already the resting one.
    @color_normal = WorldWdgt.preferencesAndSettings.iconDarkLineColor
    @color = @color_normal

  createAppearance: -> new OverflowChevronIconAppearance @

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
      menu.addMenuItem (tool.toolTipMessage ? tool.colloquialName()), @, "triggerToolFromMenu",
        arg1: cell
    menu.popUpAtHand()

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu for the shape): dispatch fills the
  # leading slots with the menu item + the menu's subject, so the cell this row stands for rides
  # slot 3.
  #   ONE DISPATCH CONTRACT, no per-family case: a row does what a TAP on its grid cell does, and
  # a tap is a mouseClickLeft on whatever the cell puts under the pointer -- the LID over a
  # drag-out thumbnail, or the tool itself where it handles its own clicks. The cell answers
  # which; clicking the wrapped tool instead leaves every lid-covered tool inert, because such a
  # tool is there to be COPIED and carries no click at all. Capability via ?() throughout, so a
  # cell with nothing clickable in it is simply inert.
  triggerToolFromMenu: (ignored, ignored2, cell) ->
    (cell.thumbnailClickReceiver?() ? cell).mouseClickLeft?()
