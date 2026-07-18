# A MenuWdgt is a pop-up that shows a vertical stack of rows (menu items,
# dividers, and small editors). It gets its menu BEHAVIOUR (transient, closes on
# click-outside, pinnable, shadowed) from PopUpWdgt, and its menu LOOK/LAYOUT by
# composing a titled MenuRowsPanelWdgt — the same split PromptWdgt uses. The panel
# draws the single titled box and lays out the rows; this pop-up draws nothing but
# its shadow and hugs the panel's size.
#
# The opener composes a menu's ITEMS after construction (addMenuItem / addLine) and
# then pops it up, so the menu is ALWAYS fully built before it is shown. It therefore
# lays its panel out + hugs it exactly ONCE, at popUp (see _reactToBeingAdded ->
# _layOutAndHugRowsPanel) — it is deliberately NOT a size-tracking container: it does
# NOT define _reLayoutChildren, so its re-layouts are stable base no-ops. (An earlier
# size-tracking design that re-drove the panel on every settle shifted the menu ±1px
# and un-hovered the item under the pointer — §5.2d.) The row API is DELEGATED to the
# panel so the ~380 `menu.addMenuItem` call sites and the MacroToolkit test hooks are
# untouched.

class MenuWdgt extends PopUpWdgt

  target: nil
  title: nil
  environment: nil
  fontSize: nil
  # the titled MenuRowsPanelWdgt that is this menu's whole visible body (box,
  # title header, and the rows). Free-floating, so it co-moves with me.
  rowsPanel: nil
  # my title bar: the MenuHeader the rows-panel builds from @title, surfaced here
  # so `menu.label` reaches it (the drag/pin-by-header idiom the menu tests share).
  # Same instance as @rowsPanel.label, so `.center()` tracks it live.
  label: nil

  # Role query (replaces `m instanceof MenuWdgt` in ActivePointerWdgt's menuAtPointer filter + the
  # click-outside-a-menu dismissal): "am I a menu?" -- distinguishes menus from other pop-ups. True here,
  # inherited by PromptWdgt/SaveShortcutPromptWdgt (mirroring the instanceof); dispatched via ?() (nothing
  # on Widget). Parallels isWindow. (type-test-elimination campaign)
  isMenu: ->
    true

  # I draw NOTHING myself -- my rowsPanel draws the box (and my shadow is my only
  # paint). So I am transparent EVERYWHERE: hit-testing must fall THROUGH me to my
  # panel (which is opaque where the box is, so topWdgtSuchThat finds it first) and,
  # where the panel does not cover (its rounded corners / the padding), on through to
  # whatever is behind me. Without this, Widget.isTransparentAt returns `undefined`
  # for an appearance-less widget, which `not undefined` treats as OPAQUE -- so my
  # transparent corners would intercept a click meant for a menu BEHIND me (a submenu
  # popped over a parent menu stopped the parent's item from staying hover-highlighted).
  # The MenuAppearance the old self-laying menu carried reported this correctly; the
  # panel now carries it, and I must report transparent to match.
  isTransparentAt: (aPoint) ->
    true

  # widgetOpeningThePopUp is the one required argument; everything else rides an opts object
  # (P5 arg-object conversion). Defaults match the old positional signature: killOutside /
  # killOnTriggers true; target / title / environment / fontSize nil.
  constructor: (@widgetOpeningThePopUp, opts = {}) ->
    @target = opts.target
    @killThisPopUpIfClickOutsideDescendants = opts.killOutside ? true
    @killThisPopUpIfClickOnDescendantsTriggers = opts.killOnTriggers ? true
    @title = opts.title
    @environment = opts.environment
    @fontSize = opts.fontSize
    if @killThisPopUpIfClickOutsideDescendants
      @onClickOutsideMeOrAnyOfMyChildren "close"
    super @widgetOpeningThePopUp, @killThisPopUpIfClickOutsideDescendants, @killThisPopUpIfClickOnDescendantsTriggers
    @isLockingToPanels = false

    @_buildAndConnectChildren()

  # Build the composed body via the NoSettle core, settling ONCE at the end
  # (orphan-settledness: `new MenuWdgt` returns settled). Only the PANEL is
  # ctor-built (empty but for its title header): a menu's ITEMS are composed by
  # the opener after construction (addMenuItem/addLine) and land in the panel; the
  # menu lays the panel out + hugs it at popUp (see _reactToBeingAdded).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @rowsPanel = new MenuRowsPanelWdgt target: @target, title: @title, environment: @environment, fontSize: @fontSize
    @_addNoSettle @rowsPanel
    # DELIBERATELY do NOT lay out / hug here: like the old self-laying menu, I stay
    # at my default (zero) extent until popUp lays me out (via _reactToBeingAdded).
    # This matters for popUpCenteredAtHand (inform), which offsets by @extent()/2 --
    # a zero pre-layout extent centres my TOP-LEFT at the hand, byte-identical to the
    # old menu; a build-time hug would offset by half the real size and mis-place it.
    # surface the panel's title header as my own .label (the drag/pin-by-header handle).
    @label = @rowsPanel.label

  colloquialName: ->
    if @title
      return "\"" + @title + "\" menu"
    else
      return "menu"

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW , WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW, 0
    @layoutSpecDetails.canSetHeightFreely = false

  # Lay my rows-panel out at my origin and hug its extent. A menu's ITEMS are added
  # by the opener via the RAW __add (addMenuItem -> panel.__add), which does NOT
  # invalidate or trigger layout -- so the panel never re-lays-out its rows on its
  # own. I drive its _reLayoutSelf() here (it lays its rows out + self-sizes via
  # immediate mutators, FLOWRULE-safe) and hug its final extent via the non-notifying
  # _applyExtentBase twin. Like the old self-laying menu, this runs ONCE at popUp
  # (via _reactToBeingAdded), NOT on every settle: a menu is always fully composed
  # BEFORE popUp (every addMenuItem / removeConsecutiveLines caller builds the whole
  # menu, then pops it up), so a stable one-shot layout reproduces the old menu's
  # behaviour EXACTLY and avoids the re-fit churn a size-tracking container adds
  # (an on-every-settle re-drive shifted the menu ±1px, un-hovering the item under
  # the pointer). The panel is free-floating, so it co-moves with me if I am later
  # dragged or clamped on-screen.
  _layOutAndHugRowsPanel: ->
    return unless @rowsPanel?
    @rowsPanel.__commitMoveTo @position()
    @rowsPanel._reLayoutSelf()
    @_applyExtentBase @rowsPanel.extent()

  # Lay out at ADD time -- the menu's layout trigger. The opener builds a menu, adds
  # its items (raw __add, no settle), then popUpAtHand; popUp attaches me to the
  # world, firing this -- exactly as the base Widget._reactToBeingAdded -> @_reLayoutSelf
  # laid the old self-laying menu's rows out at popUp. Also fires on re-parenting (a
  # pinned menu dropped into a panel), re-laying at the new origin.
  _reactToBeingAdded: (whereTo, beingDropped) ->
    @_layOutAndHugRowsPanel()

  # ===== row API -- delegated to the rows-panel =====
  # The opener composes a menu by calling these on the MENU (dozens of MenusHelper
  # / addWidgetSpecificMenuEntries sites); the rows themselves live in the panel.

  addLine: (height) ->
    @rowsPanel.addLine height

  prependLine: (height) ->
    @rowsPanel.prependLine height

  addMenuItem: (label, target, action, opts = {}) ->
    @rowsPanel.addMenuItem label, target, action, opts

  prependMenuItem: (label, target, action, opts = {}) ->
    @rowsPanel.prependMenuItem label, target, action, opts

  removeMenuItem: (label) ->
    @rowsPanel.removeMenuItem label

  removeConsecutiveLines: ->
    @rowsPanel.removeConsecutiveLines()

  # »>> this part is excluded from the fizzygum homepage build

  # test-system hooks: the menu's row count / rows live in the panel now, so
  # forward (MacroToolkit reaches these on the menu -- checkNumberOfItemsInMenu).
  testNumberOfItems: ->
    @rowsPanel.testNumberOfItems()

  testItems: ->
    @rowsPanel.testItems()

  # this part is excluded from the fizzygum homepage build <<«
