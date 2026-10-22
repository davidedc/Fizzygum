# A PROMPT's row of buttons -- the actions that end it: [Close] [OK], or a save-shortcut prompt's
# [Don't save] [Cancel] [OK] -- as ONE row of the prompt's rows panel, the last one
# (PromptWdgt._addButtonsInto builds the buttons and hands them to me).
#
# My geometry is the pop-up skin's (visual-design-system §4.3, §5), a pure function of my box and
# my buttons' measures, every number a Theme metric:
#   - I am minimumTargetSize tall -- the 44 rule (§4.2): a smaller visible control sits in a row at
#     least 44 tall -- or as tall as my tallest button when that is taller. The height is mine,
#     committed when I am built, and the rows panel only ever changes my width;
#   - every button at its own preferredExtent (a button sizes itself: I never stretch, shrink or
#     wrap one), centred down my height, floored -- a 36-tall button sits 4 below my top;
#   - the buttons in order, left to right, footerGap apart, the last one's right edge on my right
#     edge. The rows panel hands me its whole content width (CommandPanelWdgt._childWidthInStack),
#     so that edge IS the content box's: the buttons sit right-aligned, flush to it.
# I answer menuEntryPreferredWidth -- my buttons' widths and the gaps between them -- so the prompt
# widens to fit me, as it does for its widest editor or its title
# (CommandPanelWdgt.maxWidthOfMenuEntries).
#   I am a size-tracking container of my buttons, as the panel's other composite rows are (the entry
# field, the slider, the colour picker): the panel sizes me through _setWidthSizeHeightAccordingly,
# which re-lays me at my new width, and _reLayoutChildren places the buttons from my CURRENT frame,
# so arranging again at the same box moves nothing (the arrange-idempotence oracle,
# Fizzygum-tests/scripts/staleness-census.js). Only a button that is still MY CHILD takes part: one
# taken out of a pinned prompt (wantsDetachOfChild) is not mine to place, and the others close up.
#   I paint nothing (no appearance): the pop-up's body shows between my buttons.

class PromptButtonsRowWdgt extends Widget

  # the buttons I hold, in order, left to right -- each my child once I am built. Declared so a
  # duplicate has the handles to remap.
  buttons: undefined

  # The buttons ARE my identity, so they are my one positional parameter.
  constructor: (buttons = []) ->
    super()
    @buttons = buttons
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_addNoSettle eachButton for eachButton in @buttons
    @_applyExtent new Point @menuEntryPreferredWidth(), @_rowHeightFor @_extentsOf @_myButtons()
    @_invalidateLayout()

  # I am a construct's internal structure, like the rows panel I stand in: the ancestor hierarchy
  # menu passes over me (Widget.hierarchyMenuWidgets).
  hiddenFromHierarchyMenu: ->
    true

  # A button of mine may be dragged out of me exactly when a command may be dragged out of the rows
  # panel I stand in -- off a PINNED pop-up (CommandPanelWdgt.wantsDetachOfChild): my buttons are
  # that pop-up's commands, and I am only the row they sit in. So I pass the question up, and both
  # halves of a grab (ButtonWdgt.rejectDrags, Widget.grabsToParentWhenDragged) read the one answer.
  wantsDetachOfChild: (aWdgt) ->
    (@parent?.wantsDetachOfChild? aWdgt) ? false

  # A button that leaves me -- taken out of a pinned prompt, or destroyed -- changes my width and
  # where the others go: re-fit me (my invalidation climbs to the rows panel, which re-hugs my new
  # width). A detached row has no layout to keep, so an orphan's removal re-fits nothing, as
  # PanelWdgt._reactToChildRemoved skips it.
  _reactToChildRemoved: (child) ->
    return if @isOrphan()
    @_reFitContainer()

  # As a menu entry, the width my buttons need: each at its own preferredExtent, and footerGap
  # between two of them. A pure measure of my buttons, so it follows a button taken out of me.
  menuEntryPreferredWidth: ->
    @_widthFor @_extentsOf @_myButtons()

  # My buttons that are still my children, in order.
  _myButtons: ->
    (button for button in @buttons when button?.parent is @)

  _extentsOf: (buttons) ->
    (button.preferredExtent() for button in buttons)

  # The width a row of buttons of these extents (Points) takes, footerGap apart.
  _widthFor: (extents) ->
    width = 0
    width += extent.x for extent in extents
    width += WorldWdgt.theme.footerGap * (extents.length - 1) if extents.length > 0
    width

  # The height a row of buttons of these extents takes: the 44 rule's, or the tallest button's.
  _rowHeightFor: (extents) ->
    height = WorldWdgt.theme.minimumTargetSize
    height = Math.max height, extent.y for extent in extents
    height

  # PURE: the bounds of buttons of these extents (Points, in order, left to right) in `box` (a
  # Rectangle): right-aligned flush to its right edge, footerGap apart, each centred down it,
  # floored. Integers in, integers out.
  _buttonBoundsIn: (box, extents) ->
    x = box.right() - @_widthFor extents
    bounds = []
    for extent in extents
      y = box.top() + Math.floor (box.height() - extent.y) / 2
      bounds.push new Rectangle x, y, x + extent.x, y + extent.y
      x += extent.x + WorldWdgt.theme.footerGap
    bounds

  # My buttons placed in my CURRENT frame (my _reLayout has applied it), as one damage unit.
  _reLayoutChildren: ->
    buttons = @_myButtons()
    bounds = @_buttonBoundsIn @bounds, @_extentsOf buttons
    @_repaintAsOneUnit =>
      for button, i in buttons
        button._reLayout bounds[i]
      return
    return

  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()
