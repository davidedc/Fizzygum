# The DEFAULT content pane a ViewportWdgt scrolls — the plane its content actually lives
# on. The plane is PINNED: scrolling never moves it or its children; the viewport's stored
# offset translates the whole subtree at paint time (ViewportWdgt._scrollTranslation), and
# the screen↔plane walks carry the same translation for input/hit-testing. Built by
# ViewportWdgt._buildViewportChromeNoSettle whenever a caller supplies no contents of its own;
# the plane ROLE itself is broader than this class — a FolderPanelWdgt, ToolPanelWdgt or
# vertical stack passed as contents plays it too, which is why every topology question is a
# parent-based query (ViewportWdgt.isMyContentsPanel), never a class test.
#
# What lives HERE is only what is true of the default plane BY CONSTRUCTION — so PanelWdgt
# stays purely the SURFACE class, with no plane-conditional second personality (scroll-frame
# role plan P3):
#   - it never notices transparent clicks (its viewport handles those);
#   - its membership changes are relayed to the viewport's HOLDER (the bin listens);
#   - a click on its empty part forwards the caret to a lone editable text child.
# (The color/alpha up-relays that keep the viewport's mimic paint values true are NOT here —
# they live on PanelWdgt, because every panel-family plane deserves them, not just the
# default one; the stack declares its own pair.)

class ScrolledPaneWdgt extends PanelWdgt

  # my viewport catches what needs catching; a plane spanning the viewport must not
  # intercept clicks that mean "the content behind the pixels"
  noticesTransparentClick: false

  # (the color/alpha up-relays that keep my viewport's mimic values true live on PanelWdgt now —
  # every panel-family plane relays, not just me)

  # ── the membership relays to the viewport's HOLDER ────────────────────────────────────────
  # (@parent = the viewport, @parent.parent = whoever holds it — e.g. the bin, which
  # re-files storage on what enters/leaves its open window. BinWdgt is the one implementor.)

  _reactToChildDropped: (droppedWidget) ->
    # a USER DROP arrived — the third member of the _reactToChild*InViewport relay family
    # (Added/Removed below). Drop-specific on purpose: the close-filing and storage-drain
    # arrivals come through _addNoSettle and never reach this hook, so a holder that means to
    # react to deliberate gestures only (the bin's drop-as-trash-intent, reference-widgets
    # plan R5) can, without hearing machinery moves.
    @parent?.parent?._reactToChildDroppedInViewport? droppedWidget
    super

  _reactToChildRemoved: (child) ->
    # notify the holder FIRST — super returns early for orphan-rooted panels, and e.g. the bin
    # listens (a pickup out of its open window changes storage membership) whether windowed or
    # not. Symmetric to the _reactToChildAddedInViewport relay below.
    @parent?.parent?._reactToChildRemovedInViewport? child
    super

  _reactToChildAdded: (child) ->
    # e.g. the bin listens: an add here can flip a widget's storage membership (reachable vs
    # lost) whether windowed or not. Mark-only; the eager StorageSorter drains once per world
    # cycle. (see docs/archive/bin-shelf-eager-sorting-plan.md)
    @parent?.parent?._reactToChildAddedInViewport? child

  # Re-wrap my FIT_BOX_TO_TEXT text children to the given width — the text-wrapping half of
  # the scrolled-content contract (scroll-frame role plan P5). The viewport calls this when it
  # isTextLineWrapping, with its viewport-minus-padding width; only a default plane defines it
  # (?.-dispatched), which is exactly the population the wrap feature serves.
  _reWrapTextChildrenTo: (textWidth) ->
    @children.forEach (widget) =>
      if widget.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
        # contained text that OPTED INTO FIT_BOX_TO_TEXT (a SimpleTextWdgt or
        # a bare TextWdgt put into that mode) fits its BOX to the TEXT: reassert
        # soft-wrap, then feed it the width — _applyWidth re-lays-out the text to
        # that width (height = wrapped line count), and that new height drives the
        # vertical slider. We RESPECT the mode (a non-text child or a
        # FIT_TEXT_TO_BOX widget is skipped).
        widget.softWrap = true
        widget._applyWidth textWidth
        # (Phase C, proper-layouts) We only RE-WRAP the text child here (_applyWidth -> height = wrapped
        # line count); paint + the caret's synchronous @wrappedLines read need that committed, and the new
        # height then flows into the viewport's subBounds measure. We do NOT prime the contents FRAME
        # height here: the merged-bounds commit in the viewport's arrange is the SINGLE owner of my
        # extent -- an earlier priming here disagreed with that commit by ~totalPadding and flip-flopped
        # the frame height every pass (see docs/archive/proper-layouts-eliminate-suppression-booleans-plan.md).
        # The genuine content-height read-back is the measure itself, retired only when a later phase gives
        # the arrange a pure measure of its children.

  mouseClickLeft: (pos, ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey) ->
    super

    # when you click on an "empty" part of the pane and it holds one piece of text, pass the
    # click on to the text so the caret lands at its end.
    # TODO the focusing and placing of the caret at the end of
    # the text should happen via API rather than via spoofing
    # a mouse event?
    if @_amITheContentsPanelOfAViewport()
      # the caret is a world singleton, compared by identity instead of
      # `!(m instanceof CaretWdgt)` (type-test-elimination campaign)
      childrenNotCarets = @children.filter (m) ->
        m != world.caret
      if childrenNotCarets.length == 1
        item = @firstChildSuchThat (m) ->
          (m instanceof SimpleTextWdgt) and m.isEditable
        item?.mouseClickLeft item.bottomRight(), ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey
