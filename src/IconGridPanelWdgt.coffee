# Shared base of the two panels that host the simulated "file system"
# (the iconic desktop system): the desktop (WorldWdgt) and folder panels
# (FolderPanelWdgt). Hosts the two behaviours the pair shares: the ICON GRID
# every icon made or moved in later is placed on -- its next free slot
# (_placeIconInNextFreeSlotNoSettle, which add calls, and so does every other
# path that brings an icon in: a "Create shortcut", a filing, a desktop link
# moved into a folder) -- and keeping desktop links layered behind the other
# content (_reactToChildAdded / _reactToChildMovedToFront). Never instantiated
# directly.
class IconGridPanelWdgt extends PanelWdgt

  laysIconsHorizontallyInGrid: true
  iconsLayingInGridWrapCount: 3

  # the options ride through to Widget.add untouched (bare super forwards all
  # arguments), so a plain payload lands free-floating via Widget.add's own defaulting.
  add: (aWdgt, opts = {}) ->
    super
    # If the user drops an icon, it's more natural to just position it
    # where it is. Conversely, if an icon is just "created" somewhere,
    # then automatic grid positioning is better: my next free slot (an add
    # of anything that takes no part in my grid leaves it where it is).
    @_placeIconInNextFreeSlotNoSettle aWdgt unless opts.beingDropped

  # THE ONE PLACEMENT RULE of my icon grid: `aWdgt`, an icon of mine just made or just moved in,
  # goes to my NEXT FREE SLOT -- the first slot, in my grid's own order (_iconSlotTopLeft), whose
  # cell (the standard desktop-icon extent at the slot) no OTHER icon of my grid overlaps by a pixel.
  # The grid reads where my icons ARE, never a count of the icons placed so far: while nothing else
  # stands in my slots they fill in the order the icons arrive (a desktop's boot icons, a folder's
  # openers), and a slot an icon has left -- dragged away, deleted, filed elsewhere -- is the next
  # one taken. An icon of my grid is a child that participatesInIconGrid; anything else (the bin's
  # opener, the clock, every window and plain widget) neither takes a slot nor blocks one. The
  # search ends: each other icon overlaps finitely many slots. Integer by construction: my
  # position, the theme's grid origin and the pitch are whole pixels.
  # NON-settling -- an immediate move of aWdgt and nothing else -- so add calls it after its own
  # settle, and the creation cores (Widget._createReferenceNoSettle, which asks it with a `?` of
  # whatever place it was given; a desktop link moving into a folder,
  # DesktopLinkWdgt._reactToBeingDroppedIntoFolder) inside the settle they run in.
  _placeIconInNextFreeSlotNoSettle: (aWdgt) ->
    # an icon of my grid: instead of `(aWdgt instanceof WidgetHolderWithCaptionWdgt) and
    # !(aWdgt instanceof BinOpenerWdgt)` (type-test-elimination campaign)
    return unless aWdgt.parent is @ and aWdgt.participatesInIconGrid?()
    cellExtent = WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
    occupied = (each.boundingBox() for each in @children when each isnt aWdgt and each.participatesInIconGrid?())
    slot = 0
    loop
      topLeft = @_iconSlotTopLeft slot
      cell = topLeft.extent cellExtent
      break unless occupied.some (box) -> box.intersect(cell).isNotEmpty()
      slot++
    aWdgt._applyMoveTo topLeft

  # The top-left, in my plane, of my grid's slot number `slot` (counting from 0). My grid's ORDER:
  # row by row, iconsLayingInGridWrapCount slots to a row, when I lay icons horizontally (a folder
  # panel), else column by column, that many to a column (the desktop). The place: the theme's grid
  # origin, then one PITCH per column across and per row down -- the standard desktop-icon extent
  # (the theme's cell by its two-line height) plus the gap between two columns, or two rows. The
  # pitch reads the theme, never an icon's extent.
  _iconSlotTopLeft: (slot) ->
    if @laysIconsHorizontallyInGrid
      column = slot % @iconsLayingInGridWrapCount
      row = Math.floor slot / @iconsLayingInGridWrapCount
    else
      column = Math.floor slot / @iconsLayingInGridWrapCount
      row = slot % @iconsLayingInGridWrapCount
    theme = WorldWdgt.theme
    pitch = new Point theme.desktopIconCellWidth + theme.desktopIconColumnGap, theme.desktopIconHeight + theme.desktopIconRowGap
    @position().add(theme.desktopIconGridOrigin).add new Point column * pitch.x, row * pitch.y

  # The extent that shows `columns` x `rows` of my grid's slots whole, with no scroll bar: the
  # grid origin's margin before the first slot and again past the last one on each axis, the icons
  # (the standard desktop-icon extent) and the gaps between them. A folder window opens at it.
  extentShowingIconGrid: (columns, rows) ->
    theme = WorldWdgt.theme
    origin = theme.desktopIconGridOrigin
    new Point 2 * origin.x + columns * theme.desktopIconCellWidth + (columns - 1) * theme.desktopIconColumnGap,
      2 * origin.y + rows * theme.desktopIconHeight + (rows - 1) * theme.desktopIconRowGap

  # keeps folders and shortcuts and scripts in the background in respect
  # to other windows and widgets.
  # These deliberately REPLACE (no super) PanelWdgt's scroll-panel-holder
  # relay: the world has no holder and a folder window doesn't listen, so
  # what these panels need on an add / move-to-front is only the link
  # re-layering.
  # only a desktop link knows how to layer itself above the other references; non-links
  # have no moveOnTopOfTopReference, so `?()` fires for exactly the old
  # `instanceof DesktopLinkWdgt`. (type-test-elimination campaign)
  _reactToChildAdded: (theWidget) ->
    theWidget.moveOnTopOfTopReference?()

  _reactToChildMovedToFront: (theWidget) ->
    theWidget.moveOnTopOfTopReference?()
