# A MenuWdgt is the FRAMED CITIZEN of the menu kind (the Frame-model §5.B pattern
# DocumentWdgt uses): a menu IS its frame, exactly as a document IS its window. The
# frame does all the chrome work — the title strip, the menu box, the shadow, the
# lifetime state (a menu is born TRANSIENT: it closes on a click outside, and pinning
# it makes it furniture) — and this class declares only the per-kind knowledge: the
# rows payload it wraps, its title, and the row API its openers compose through.
#
# The payload is a CommandPanelWdgt (a vertical stack of menu items, dividers and small
# editors) inside a PopUpRowsViewportWdgt, which is what bounds a menu to the world and
# scrolls whatever does not fit. The panel paints nothing: the FRAME draws the menu box.
#
# The opener composes a menu's ITEMS after construction (addMenuItem / addLine) and
# then pops it up, so the menu is ALWAYS fully built before it is shown. It therefore
# lays its panel out + hugs it exactly ONCE, at popUp (see _reactToBeingAdded) — it is
# deliberately NOT a size-tracking container of its rows. (An earlier size-tracking design
# that re-drove the panel on every settle shifted the menu ±1px and un-hovered the item
# under the pointer — §5.2d.) The row API is DELEGATED to the panel so the ~380
# `menu.addMenuItem` call sites and the MacroToolkit test hooks are untouched.

class MenuWdgt extends FrameWdgt

  target: undefined
  title: undefined
  fontSize: undefined
  # the CommandPanelWdgt that is my rows' whole visible body, and the viewport it lives
  # in — my @contents. Declared here so a duplicate has the handles to remap.
  rowsPanel: undefined
  rowsViewport: undefined

  # Role query (replaces `m instanceof MenuWdgt` in ActivePointerWdgt's
  # click-outside-a-menu dismissal): "am I a menu?" -- distinguishes menus from other frames. True here,
  # inherited by PromptWdgt/SaveShortcutPromptWdgt (mirroring the instanceof); dispatched via ?() (nothing
  # on Widget). Parallels isFrame. (type-test-elimination campaign)
  isMenu: ->
    true

  # Editor CHROME (Frame-model plan §5.D D2a): a menu acting ON the editor focus
  # (the font-selection menu — its items apply a font to the focused text)
  # opts in here so a click on any of its items neither steals the focus
  # pointer nor ends the ongoing edit. Ancestry-honored, so the ROOT menu
  # answering is enough — no per-descendant stamping (the ChangeFontButtonWdgt
  # loop this replaced). Default undefined ⇒ ordinary menus are unaffected.
  actsAsEditorChrome: false
  excludedFromEditorFocusTracking: ->
    @actsAsEditorChrome

  # widgetOpeningThePopUp is the one required argument; everything else rides an opts object
  # (P5 arg-object conversion): target / title / fontSize, each undefined when absent.
  # The rows payload is built BEFORE super: it IS the frame's content operand, and the title
  # my frame reads for its strip is mine to know first.
  constructor: (@widgetOpeningThePopUp, opts = {}) ->
    @target = opts.target
    @title = opts.title
    @fontSize = opts.fontSize
    # a menu is born mid-gesture UI: the lifetime entry enrols me in the open set and arms the
    # click-outside dismissal that ends me.
    @_setLifetimeNoSettle 'transient'
    super @_buildRowsPayload()
    @rowsViewport = @contents
    @rowsPanel = @rowsViewport.contents
    @isLockingToPanels = false
    # freshlyCreatedPopUps is a fact about CONSTRUCTION: the hand skips a pop-up born under the
    # very click that is still being processed, and clears the set at mouse-up.
    world.freshlyCreatedPopUps.add @

  # My payload: the rows panel inside the rows viewport (see the class comment for why the
  # viewport is unconditional). DELIBERATELY no rows here — a menu's ITEMS are composed by its
  # opener after construction (addMenuItem/addLine) and land in the panel.
  _buildRowsPayload: ->
    panel = new CommandPanelWdgt target: @target, fontSize: @fontSize
    # dragging a menu by its title must move the MENU, and a child of a panel detaches instead
    # unless it locks to panels. ListWdgt does exactly this to its own rows panel, for exactly
    # this reason.
    panel.isLockingToPanels = true
    # the panel is TRANSPARENT chrome: my own box is the menu box (FrameWdgt
    # ._deriveAndSetBodyAppearance paints it), and a second box inside it would double the
    # stroke. Its shape still takes its own clicks — alpha is about painting, never hit-testing.
    panel.alpha = 0
    new PopUpRowsViewportWdgt panel

  # I am a menu only while I am mid-gesture UI. Pinned I am furniture, and I am named for what I
  # then am -- a window (program ruling C4: there is no such thing as a pinned-menu kind).
  #   My TITLE crosses that change of kind: titled, I answer "<title>" window, the symmetric twin
  # of my transient "<title>" menu. The title is the name a user gave me, not a record of what I
  # once was, so it is the document-names-its-window move rather than a history leak. BOTH
  # parentages answer "window" -- desktop or nested, the window/card difference is what I LOOK
  # like, never what I am called. Untitled I have no name of my own to offer, so my frame's plain
  # window / internal window stands.
  colloquialName: ->
    unless @isTransientPopUp()
      return super() unless @title
      return "\"" + @title + "\" window"
    if @title
      return "\"" + @title + "\" menu"
    else
      return "menu"

  # the KIND names me: my title is my own, not my payload's colloquial name
  _titleForContents: (unused_aWdgt) ->
    @title

  # As another frame's CONTENT (a pinned menu dropped into a window), I keep the size I have
  # and do not grow in the holder's stack: a menu is its rows, and stretching it would only
  # add empty box.
  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW , FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW, 0
    @_contentStackSpec.canSetHeightFreely = false

  # Lay out at ADD time -- the menu's layout trigger. The opener builds a menu, adds
  # its items (raw __add, no settle -- so the panel never re-lays-out its rows on
  # its own), then popUpAtHand; popUp attaches me to the world, firing this, which
  # drives the rows viewport's absorb: re-lay the rows, re-fit the viewport to their
  # measure, re-take my own extent from it. This one-shot-at-popUp model stands because a
  # menu is always fully composed BEFORE popUp; post-popUp membership changes go through
  # the SAME absorb, from the stack's own membership seam. Also fires on re-parenting (a
  # pinned menu dropped into a panel), re-laying at the new origin.
  _reactToBeingAdded: (whereTo, beingDropped) ->
    super
    @rowsViewport._reLayOutAfterContainedPanelChange()

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
