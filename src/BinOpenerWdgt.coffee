class BinOpenerWdgt extends DesktopLinkWdgt

  # the bin I open. NOT a tracked reference edge (I am not in
  # world.widgetsReferencingOtherWidgets) -- I am a fixed opener for the one bin singleton.
  target: undefined

  _acceptsDrops: true
  # my carrier-owned corner knob — the layoutSpec MenusHelper hands my parent at
  # add() time (the pattern LayoutSpec.coffee names, alongside HandleWdgt.cornerSpec)
  cornerSpec: undefined

  constructor: ->
    super "Bin", new GenericShortcutIconWdgt new BinIconWdgt
    @target = world.binWdgt
    # my corner KNOB (carrier-owned, like HandleWdgt.cornerSpec): bottom-right of the
    # desktop, desktopSidesPadding inside, ZERO size declared -- the corner pass places
    # me by my own extent, it never sizes me. The CREATOR arms it at add
    # (menusHelper.binIconAndText) -- deliberately NOT via defaultLayoutSpecWhenAddedTo,
    # which would re-anchor me on every user re-drop; a grab disarms the slot and I stay
    # free-floating, which IS the "until the user intervenes" lifecycle.
    @cornerSpec = new CornerInternalLayoutSpec 'bottomRight', 0, 0, new Point world.desktopSidesPadding, world.desktopSidesPadding

  # I am a desktop icon but the desktop positions me itself (bottom-right corner), so I do
  # NOT take part in the auto icon grid -- override of WidgetHolderWithCaptionWdgt (was the
  # `!(aWdgt instanceof BinOpenerWdgt)` exclusion). (type-test-elimination campaign)
  participatesInIconGrid: ->
    false

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    if @target.isOrphan()
      @target.unCollapse()
      windowedBinWdgt = new FrameWdgt @target
      world.add windowedBinWdgt
      windowedBinWdgt._applyBounds (new Point 140, 90), new Point 460, 400
    else
      # if the bin is not an orphan, then it's
      # visible somewhere and it's in a window
      @target.parent.spawnNextTo @
      # RE-RECORD (the F6 family, auto-bookkeeping arc): the bin window already carries
      # fractional bookkeeping from its previous desktop life, so the fill-only seed will
      # not touch it -- after spawnNextTo re-places it, its proportional situation must be
      # re-derived explicitly. (The fresh-window branch above needs nothing: the seed's
      # drain fills a fresh widget at its post-placement geometry.)
      @target.parent._rememberFractionalSituationInHoldingPanel()


  # Runs inside the drop's single settle, so add through the non-settling core.
  _reactToChildDropped: (droppedWidget) ->
    @target.scrollPanel.contents._addInPseudoRandomPositionNoSettle droppedWidget

  wantsToBeDropped: ->
    false