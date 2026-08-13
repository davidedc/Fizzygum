# DivisionStackLayoutSpec

# The per-child spec for a DIVISION stack element: siblings that jointly divide their
# container's main axis, each bringing a three-point constraint box (min / desired / max)
# to base Widget._reLayout's three-regime distribution (under-min shrink / desired-margin
# grow / max-margin fill).
#
# LIFECYCLE — a per-widget KNOB, not per-placement state (contrast VerticalStackLayoutSpec,
# which captures at each placement): built on demand — by a box setter
# (setMinAndMaxBoundsAndSpreadability / setMaxDim) — and kept for the widget's whole life,
# so a divider-tuned cell dragged out of its stack and dropped back in keeps its box. The
# widget retains it as @_divisionBox (Widget._ensureDivisionBox() materializes it).
#
# A widget with no private box reads through the shared @defaults() instance, so a plain
# widget costs no allocation. The defaults are the box every widget is born with: desired
# (30,30), min (30,30), max (330,330) = desired + SPREADABILITY_MEDIUM of the desired.
class DivisionStackLayoutSpec extends LayoutSpec

  minWidth: 30
  minHeight: 30
  desiredWidth: 30
  desiredHeight: 30
  maxWidth: 330
  maxHeight: 330

  # WHICH of the container's axes my row divides: 'x' = a horizontal row dividing width
  # (the cross axis stretches to the container's height), 'y' = a vertical division stack
  # dividing height (cross stretches to width). Set at attach (`divisionBox('y')`); the
  # engine reads it off the children (mixed axes under one parent: first child wins,
  # loudly — see Widget._divisionChildrenAxis).
  axis: 'x'

  # CROSS-AXIS placement of my cell: 'stretch' (the default — fill the container's whole
  # cross extent, the classic row/toolbar look) or 'start' | 'center' | 'end', where the
  # cell takes its own cross-axis DESIRED extent (recursively derived for a nested
  # container) and sits at the chosen edge/middle of the band.
  crossAlign: 'stretch'

  # The widget whose knob I am — the back-ref for the settle-on-element setter idiom below
  # (the spec is not a Widget, so a public setter settles on @element, mirroring
  # VerticalStackLayoutSpec). Bound at the ONE place a private box is materialized
  # (Widget._ensureDivisionBox) and never re-bound: the box is a per-widget knob and never
  # changes owner. The shared @defaults() instance deliberately keeps NO element — it backs
  # plain widgets read-only, and no menu is ever built on it.
  element: undefined

  constructor: ->
    super()
    return undefined

  # The shared read-only instance backing every widget without a private box (see the class
  # comment). Built lazily at first use rather than as a class-level instance, so boot pays
  # nothing. Readers must not write it — writers go through Widget._ensureDivisionBox(),
  # which materializes a private box.
  @defaults: ->
    @_defaults ?= new DivisionStackLayoutSpec

  # Capability query (duck-typed at the call sites): am I a division-stack attachment?
  isDivisionElement: ->
    true

  # Spreadability sugar: a preset distance between desired and max —
  # setMinAndMaxBoundsAndSpreadability computes max = desired + spreadability·desired/100.
  @SPREADABILITY_HANDLES: 1
  @SPREADABILITY_NONE: 10
  @SPREADABILITY_MEDIUM: 1000
  @SPREADABILITY_SPACERS: 100000000

  # The division cell's DIRECT-MANIPULATION surface, dispatched from the widget's menu gate
  # (Widget.addWidgetSpecificMenuEntries — an active division element that is not layout
  # chrome). Mirrors VerticalStackLayoutSpec's "layout in stack ➜" submenu.
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    menu.addLine()
    menuLabel = if @axis == 'y' then "layout in column ➜" else "layout in row ➜"
    menu.addMenuItem menuLabel, @, "divisionCellMenu", closesUnpinnedPopUps: false, toolTip: ""

  divisionCellMenu: (widgetOpeningThePopUp,targetWidget,a,b,c)->
    menu = new MenuWdgt widgetOpeningThePopUp, target: targetWidget
    menu.addMenuItem "desired size...", @, "desiredMainDimPopout", toolTip: ""
    menu.addMenuItem "max size...", @, "maxMainDimPopout", toolTip: ""
    menu.addMenuItem "cross: stretch", @, "setCrossAlignToStretch"  if @crossAlign isnt "stretch"
    menu.addMenuItem "cross: start", @, "setCrossAlignToStart"  if @crossAlign isnt "start"
    menu.addMenuItem "cross: center", @, "setCrossAlignToCenter"  if @crossAlign isnt "center"
    menu.addMenuItem "cross: end", @, "setCrossAlignToEnd"  if @crossAlign isnt "end"
    menu.popUpAtHand()

  # The setters below are DISCRETE public mutations (menu entries / prompts / an app
  # building its content), so each SELF-SETTLES — taken on @element since the spec is not a
  # Widget, the canonical wrapper/_NoSettle-core split with ALL logic (incl. the
  # already-in-state guard) in the core, each core ending in @element._invalidateLayout().
  # VerticalStackLayoutSpec's setter block is the family's canonical comment — same idiom,
  # division knobs instead of stack knobs. The size setters address the box pair of the
  # spec's CURRENT axis (main dim: width under 'x', height under 'y'); the cross pair of a
  # box stays construction/API-set — the read side tolerates any inconsistency (the
  # recursive dim walkers clamp desired/min to max, and getMaxDim clamps max to desired).
  # thin-wrap-exempt: settles on @element (not @) — not a Widget; canonical otherwise
  # (see VerticalStackLayoutSpec.setAlignmentToLeft).
  setCrossAlignToStretch: ->
    @element._settleLayoutsAfter => @_setCrossAlignNoSettle "stretch"

  # thin-wrap-exempt: settles on @element (not @) — not a Widget; canonical otherwise (see above).
  setCrossAlignToStart: ->
    @element._settleLayoutsAfter => @_setCrossAlignNoSettle "start"

  # thin-wrap-exempt: settles on @element (not @) — not a Widget; canonical otherwise (see above).
  setCrossAlignToCenter: ->
    @element._settleLayoutsAfter => @_setCrossAlignNoSettle "center"

  # thin-wrap-exempt: settles on @element (not @) — not a Widget; canonical otherwise (see above).
  setCrossAlignToEnd: ->
    @element._settleLayoutsAfter => @_setCrossAlignNoSettle "end"

  # ONE parameterized core for the four wrappers above (the wrappers stay separate because
  # divisionCellMenu addresses them BY NAME).
  _setCrossAlignNoSettle: (newCrossAlign) ->
    if @crossAlign isnt newCrossAlign
      @crossAlign = newCrossAlign
      @element._invalidateLayout()

  desiredMainDimPopout: (menuItem,a,b,c,d,e,f)->
    currentDesired = if @axis == 'y' then @desiredHeight else @desiredWidth
    @element.prompt menuItem.parent.title + "\ndesired size:",
      @,
      "setDesiredMainDim",
      currentDesired.toString(),
      undefined,
      10,
      1000,
      true

  # thin-wrap-exempt: settles on @element (not @) — not a Widget; canonical otherwise (see above).
  # Prompt-adapter signature (value-or-widget-giving-value), like VerticalStackLayoutSpec.setDesiredWidth.
  setDesiredMainDim: (dimOrWidgetGivingDim, widgetGivingDim) ->
    @element._settleLayoutsAfter => @_setDesiredMainDimNoSettle dimOrWidgetGivingDim, widgetGivingDim
  _setDesiredMainDimNoSettle: (dimOrWidgetGivingDim, widgetGivingDim) ->
    if widgetGivingDim?.getValue?
      newDim = widgetGivingDim.getValue()
    else
      newDim = dimOrWidgetGivingDim
    newDim = Math.round newDim
    return unless newDim
    if @axis == 'y'
      unless @desiredHeight == newDim
        @desiredHeight = newDim
        @element._invalidateLayout()
    else
      unless @desiredWidth == newDim
        @desiredWidth = newDim
        @element._invalidateLayout()

  maxMainDimPopout: (menuItem,a,b,c,d,e,f)->
    currentMax = if @axis == 'y' then @maxHeight else @maxWidth
    @element.prompt menuItem.parent.title + "\nmax size:",
      @,
      "setMaxMainDim",
      currentMax.toString(),
      undefined,
      10,
      1000,
      true

  # thin-wrap-exempt: settles on @element (not @) — not a Widget; canonical otherwise (see above).
  # Prompt-adapter signature (value-or-widget-giving-value), like VerticalStackLayoutSpec.setDesiredWidth.
  setMaxMainDim: (dimOrWidgetGivingDim, widgetGivingDim) ->
    @element._settleLayoutsAfter => @_setMaxMainDimNoSettle dimOrWidgetGivingDim, widgetGivingDim
  _setMaxMainDimNoSettle: (dimOrWidgetGivingDim, widgetGivingDim) ->
    if widgetGivingDim?.getValue?
      newDim = widgetGivingDim.getValue()
    else
      newDim = dimOrWidgetGivingDim
    newDim = Math.round newDim
    return unless newDim
    if @axis == 'y'
      unless @maxHeight == newDim
        @maxHeight = newDim
        @element._invalidateLayout()
    else
      unless @maxWidth == newDim
        @maxWidth = newDim
        @element._invalidateLayout()
