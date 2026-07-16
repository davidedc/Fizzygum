# VerticalStackLayoutSpec

class VerticalStackLayoutSpec

  @augmentWith DeepCopierMixin

  stack: nil
  element: nil

  # ONE constraint-box sizing model (sizing-model unification U1 — docs/sizing-model-unification-plan.md):
  #
  #   width in stack = round( min( availW, desiredWidth + grow * (availW - desiredWidth) ) )
  #
  # - desiredWidth: the element's width WISH — captured from its natural width at placement
  #   (an initialisation default, user-editable via the "base width..." menu entry), NOT
  #   load-bearing history: nothing samples the container's PAST width. (The old proportional
  #   model — width = wEl + elasticity*(availW*wEl/wStk - wEl) — divided by an add-time
  #   widthOfStackWhenAdded snapshot, which made layout depend on history and whose
  #   uninitialised nil was the NaN that forced WindowWdgt.contentNeverSetInPlaceYet's
  #   measure guard.)
  # - grow: the 0..1 share of the EXTRA space (availW - desiredWidth) the element takes.
  #   0 = keep the desired width (fixed); 1 = fill the row / track the stack width. The
  #   "elasticity..." menu knob edits it on a 0..100 scale. nil = NOT DECIDED YET: the
  #   capture below derives it from the add-time relationship (an element placed at/above
  #   the stack width is fill-class and tracks; a narrower one keeps its size — D2-def),
  #   exactly the distinction the old model encoded in the captured wEl/wStk ratio
  #   (ratio 1 ≡ track, ratio < 1 ≡ scaled-keep). An EXPLICIT grow (the fixed/aspect
  #   classes' 0, a menu edit, a constructor arg) always wins over the derivation.
  desiredWidth: nil
  grow: nil
  alignment: 'left'

  constructor: (@grow = nil) ->
    return nil

  # Capture the spec's initial desiredWidth from the element's natural width at THIS
  # placement — re-run at every (re)placement, exactly the old capture timing (the arrange
  # initialises every spec before asking; pre-U4 name: rememberInitialDimensions). Also
  # binds @element/@stack for the no-arg getWidthInStack. An element WIDER than the
  # available width is clamped and FORCED fill-class (grow 1, trampling an explicit grow —
  # the old model forced elasticity 1 the same way); at or below it, an undecided grow is
  # DERIVED (see the field comment above) and an explicit grow is preserved (the aspect
  # trio's 0 keeps a clock added at exactly the hugged window width fixed).
  captureInitialPlacement: (@element, @stack) ->

    availableWidthInStack = @stack.availableWidthForContents()
    elementWidthWithoutSpacing = @element.widthWithoutSpacing()

    if elementWidthWithoutSpacing > availableWidthInStack
      @desiredWidth = availableWidthInStack
      @grow = 1
    else
      @desiredWidth = elementWidthWithoutSpacing
      @grow ?= if elementWidthWithoutSpacing >= availableWidthInStack then 1 else 0

  # TOTAL, including BEFORE the capture has run (U2): an outer container may measure a
  # subtree whose specs are not yet captured (e.g. a window's content stack measured during
  # the window's own first placement -- the recursion the deleted contentNeverSetInPlaceYet
  # measure guard used to cut off). An uncaptured spec answers with the SAME derivation the
  # capture will apply -- desired from the element's natural width (fill if no element is
  # bound yet), grow keep-vs-track from the same >= relationship -- so a pre-capture measure
  # approximates the post-capture answer instead of NaN-ing (the old model divided by the
  # uncaptured wStk snapshot here).
  getWidthInStack: (availableWidthOverride) ->
    availableWidthInStack = availableWidthOverride ? @stack.availableWidthForContents()

    desired = @desiredWidth ? Math.min availableWidthInStack, (@element?.widthWithoutSpacing?() ? availableWidthInStack)
    grow = @grow ? (if desired >= availableWidthInStack then 1 else 0)

    width = desired + grow * (availableWidthInStack - desired)
    width = Math.round width

    return Math.min width, availableWidthInStack


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    menu.addLine()
    menu.addMenuItem "layout in stack ➜", @, "vertStackMenu", closesUnpinnedPopUps: false, toolTip: ""

  vertStackMenu: (widgetOpeningThePopUp,targetWidget,a,b,c)->
    menu = new MenuWdgt widgetOpeningThePopUp, target: targetWidget
    menu.addMenuItem "base width...", @, "desiredWidthPopout", toolTip: ""
    menu.addMenuItem "elasticity...", @, "growPopout", toolTip: ""
    menu.addMenuItem "align left", @, "setAlignmentToLeft"  if @alignment isnt "left"
    menu.addMenuItem "align right", @, "setAlignmentToRight"  if @alignment isnt "right"
    menu.addMenuItem "align center", @, "setAlignmentToCenter"  if @alignment isnt "center"
    menu.popUpAtHand()

  # The spec's layout setters below (align / elasticity / base-width) are DISCRETE public mutations -- driven
  # from the "layout in stack ➜" menu, the align/elasticity buttons, the base-width prompt, or an app building
  # its starting content. Each must therefore SELF-SETTLE (one layout flush per outermost public mutation),
  # instead of leaving its re-fit to ride the per-frame end-of-cycle flush. The spec is not a Widget, so the
  # settle is taken on @element (the stack element). Canonical public-wrapper / _NoSettle-core split: each
  # public setter is JUST the settle over its _<name>NoSettle core, and ALL the work -- INCLUDING the
  # already-in-this-state guard -- lives in the core, so no wrapper hides a pre-settle early return
  # (check-layering rule [H]). Each core sets its property then calls @element._invalidateLayout() -- the
  # uniform dirty-tree climb (element -> stack -> D1 scroll panel) that replaced the deleted property re-fit
  # seam (a freefloating child's invalidate climbs THROUGH the freefloating boundary to its size-tracking
  # container off-pass). (Off-world content hits _settleLayoutsAfter's orphan early-return, so it still just
  # defers, unchanged.) (end-of-cycle-flush-drawdown -- CONVERT)
  # NB (U4) the setters carry the MODEL's names (setGrow / setDesiredWidth — pre-U4:
  # setElasticity / setWidthOfElementWhenAdded); the USER-FACING wording ("elasticity...",
  # "base width...", the prompt titles) deliberately keeps the old menu vocabulary — labels
  # are product wording and pixel-asserted, methods are code vocabulary.
  # thin-wrap-exempt: the spec is NOT a Widget, so each setter settles on @element (the stack element), not @
  # -- the thin-wrap gate's canonical form anchors _settleLayoutsAfter on @ (a self-settle). This is the same
  # canonical thin wrap, just delegated to @element. (All 5 setters below are exempt for this reason.)
  setAlignmentToLeft: ->
    @element._settleLayoutsAfter => @_setAlignmentNoSettle "left"

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  setAlignmentToRight: ->
    @element._settleLayoutsAfter => @_setAlignmentNoSettle "right"

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  setAlignmentToCenter: ->
    @element._settleLayoutsAfter => @_setAlignmentNoSettle "center"

  # ONE parameterized core for the three alignment wrappers above (they collapse onto it -- identical bar
  # the "left"|"right"|"center" string; the wrappers stay separate because vertStackMenu addresses them BY NAME).
  _setAlignmentNoSettle: (newAlignment) ->
    if @alignment isnt newAlignment
      @alignment = newAlignment
      @element._invalidateLayout()   # (property sub-seam deletion) uniform climb: element -> stack -> (D1) scroll panel

  growPopout: (menuItem,a,b,c,d,e,f)->
    @element.prompt menuItem.parent.title + "\nelasticity:",
      @,
      "setGrowFromPercent",
      ((@grow ? 1) * 100).toString(),
      nil,
      0,
      100,
      true

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  # The prompt's adapter: the user-facing "elasticity" knob speaks 0..100, the model's grow
  # is 0..1 -- this converts and delegates (StringFieldWdgt-value-aware, the prompt's
  # calling convention).
  setGrowFromPercent: (percentOrWidgetGivingPercent, widgetGivingPercent) ->
    @element._settleLayoutsAfter => @_setGrowFromPercentNoSettle percentOrWidgetGivingPercent, widgetGivingPercent
  _setGrowFromPercentNoSettle: (percentOrWidgetGivingPercent, widgetGivingPercent) ->
    if widgetGivingPercent?.getValue?
      percent = widgetGivingPercent.getValue()
    else
      percent = percentOrWidgetGivingPercent
    @_setGrowNoSettle Number(percent) / 100

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  # MODEL scale: grow is the 0..1 share of the extra space (pre-U4 name: setElasticity,
  # which took the prompt's 0..100 scale -- that conversion now lives in the adapter above).
  setGrow: (newGrow) ->
    @element._settleLayoutsAfter => @_setGrowNoSettle newGrow
  _setGrowNoSettle: (newGrow) ->
    unless @grow == newGrow
      @grow = newGrow
      @element._invalidateLayout()   # (property sub-seam deletion) uniform climb: element -> stack -> (D1) scroll panel

  desiredWidthPopout: (menuItem,a,b,c,d,e,f)->
    @element.prompt menuItem.parent.title + "\nbase width:",
      @,
      "setDesiredWidth",
      @desiredWidth.toString(),
      nil,
      10,
      1000,
      true

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  # (pre-U4 name: setWidthOfElementWhenAdded; the user-facing prompt still says "base width".)
  setDesiredWidth: (desiredWidthOrWidgetGivingDesiredWidth, widgetGivingDesiredWidth) ->
    @element._settleLayoutsAfter => @_setDesiredWidthNoSettle desiredWidthOrWidgetGivingDesiredWidth, widgetGivingDesiredWidth
  # An explicit base-width edit PINS the element (grow 0): "I want THIS width" — under the grow
  # model a desired width is moot at grow 1 (the element fills regardless), so without the pin
  # the menu's base-width knob would silently do nothing on a fill-class element (the old
  # proportional model re-anchored the ratio instead, so the knob always bit). The user can
  # raise elasticity again afterwards — the knobs stay independent edits.
  _setDesiredWidthNoSettle: (desiredWidthOrWidgetGivingDesiredWidth, widgetGivingDesiredWidth) ->
    if widgetGivingDesiredWidth?.getValue?
      newDesiredWidth = widgetGivingDesiredWidth.getValue()
    else
      newDesiredWidth = desiredWidthOrWidgetGivingDesiredWidth

    newDesiredWidth = Math.round(newDesiredWidth)

    if newDesiredWidth
      unless @desiredWidth == newDesiredWidth and @grow == 0
        @desiredWidth = newDesiredWidth
        @grow = 0
        @element._invalidateLayout()   # (property sub-seam deletion) uniform climb: element -> stack -> (D1) scroll panel
