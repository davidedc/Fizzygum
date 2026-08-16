# Shared base of the two panels that host the simulated "file system"
# (the iconic desktop system): the desktop (WorldWdgt) and folder panels
# (FolderPanelWdgt). Hosts the two behaviours the pair shares: grid
# auto-placement of freshly-created icons (add) and keeping desktop links
# layered behind the other content (_reactToChildAdded /
# _reactToChildMovedToFront). Never instantiated directly.
class IconicDesktopSystemPanelWdgt extends PanelWdgt

  numberOfIconsOnDesktop: 0
  laysIconsHorizontallyInGrid: true
  iconsLayingInGridWrapCount: 3
  iconsPaddingFromContainerEdges: 5

  # the options ride through to Widget.add untouched (bare super forwards all
  # arguments), so a plain payload lands free-floating via Widget.add's own defaulting.
  add: (aWdgt, opts = {}) ->
    super
    # If the user drops an icon, it's more natural to just position it
    # where it is. Conversely, if an icon is just "created" somewhere,
    # then automatic grid positioning is better.
    # a freshly-created (not dropped) desktop icon that takes part in the grid is auto-placed;
    # instead of `(aWdgt instanceof WidgetHolderWithCaptionWdgt) and !(aWdgt instanceof BinOpenerWdgt)`
    # (type-test-elimination campaign)
    if !opts.beingDropped and aWdgt.participatesInIconGrid?()
      if @laysIconsHorizontallyInGrid
        xPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
        yPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
      else
        xPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
        yPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
      # pitch = the standard desktop-icon extent (95×92) + a 10px gutter
      aWdgt._applyMoveTo (@position().add new Point xPos * 105, yPos * 102).add @iconsPaddingFromContainerEdges
      @numberOfIconsOnDesktop++

  # keeps folders and shortcuts and scripts in the background in respect
  # to other windows and widgets.
  # These deliberately REPLACE (no super) PanelWdgt's scroll-panel-holder
  # relay: the world has no holder and a folder window doesn't listen, so
  # what these panels need on an add / move-to-front is only the link
  # re-layering.
  # only a desktop link knows how to layer itself above the other references; non-links
  # have no moveOnTopOfTopReference, so `?()` fires for exactly the old
  # `instanceof IconicDesktopSystemLinkWdgt`. (type-test-elimination campaign)
  _reactToChildAdded: (theWidget) ->
    theWidget.moveOnTopOfTopReference?()

  _reactToChildMovedToFront: (theWidget) ->
    theWidget.moveOnTopOfTopReference?()
