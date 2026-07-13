# VerticalStackLayoutSpec

class VerticalStackLayoutSpec

  @augmentWith DeepCopierMixin

  stack: nil
  element: nil

  widthOfStackWhenAdded: nil
  widthOfElementWhenAdded: nil
  elasticity: 1
  alignment: 'left'

  constructor: (@elasticity = 1) ->
    return nil

  rememberInitialDimensions: (@element, @stack) ->
    
    availableWidthInStack = @stack.availableWidthForContents()
    elementWidthWithoutSpacing = @element.widthWithoutSpacing()
    
    if elementWidthWithoutSpacing > availableWidthInStack
      @widthOfElementWhenAdded = availableWidthInStack
      @elasticity = 1
    else
      @widthOfElementWhenAdded = elementWidthWithoutSpacing

    @widthOfStackWhenAdded = availableWidthInStack

  getWidthInStack: (availableWidthOverride) ->
    availableWidthInStack = availableWidthOverride ? @stack.availableWidthForContents()
    proportionalWidth = availableWidthInStack * @widthOfElementWhenAdded / @widthOfStackWhenAdded
    differenceWithFixedWidth = proportionalWidth - @widthOfElementWhenAdded
    
    width = @widthOfElementWhenAdded + @elasticity * differenceWithFixedWidth
    width = Math.round width

    return Math.min width, availableWidthInStack


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    menu.addLine()
    menu.addMenuItem "layout in stack ➜", @, "vertStackMenu", closesUnpinnedPopUps: false, toolTip: ""

  vertStackMenu: (widgetOpeningThePopUp,targetWidget,a,b,c)->
    menu = new MenuWdgt widgetOpeningThePopUp, target: targetWidget
    menu.addMenuItem "base width...", @, "baseWidthPopout", toolTip: ""
    menu.addMenuItem "elasticity...", @, "elasticityPopout", toolTip: ""
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

  elasticityPopout: (menuItem,a,b,c,d,e,f)->
    @element.prompt menuItem.parent.title + "\nelasticity:",
      @,
      "setElasticity",
      (@elasticity * 100).toString(),
      nil,
      0,
      100,
      true

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  setElasticity: (elasticityOrWidgetGivingElasticity, widgetGivingElasticity) ->
    @element._settleLayoutsAfter => @_setElasticityNoSettle elasticityOrWidgetGivingElasticity, widgetGivingElasticity
  _setElasticityNoSettle: (elasticityOrWidgetGivingElasticity, widgetGivingElasticity) ->
    if widgetGivingElasticity?.getValue?
      elasticity = widgetGivingElasticity.getValue()
    else
      elasticity = elasticityOrWidgetGivingElasticity

    elasticity = Number(elasticity)

    elasticity = elasticity/100
    unless @elasticity == elasticity
      @elasticity = elasticity
      @element._invalidateLayout()   # (property sub-seam deletion) uniform climb: element -> stack -> (D1) scroll panel

  baseWidthPopout: (menuItem,a,b,c,d,e,f)->
    @element.prompt menuItem.parent.title + "\nbase width:",
      @,
      "setWidthOfElementWhenAdded",
      @widthOfElementWhenAdded.toString(),
      nil,
      10,
      1000,
      true

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  setWidthOfElementWhenAdded: (widthOfElementWhenAddedOrWidgetGivingWidthOfElementWhenAdded, widgetGivingWidthOfElementWhenAdded) ->
    @element._settleLayoutsAfter => @_setWidthOfElementWhenAddedNoSettle widthOfElementWhenAddedOrWidgetGivingWidthOfElementWhenAdded, widgetGivingWidthOfElementWhenAdded
  _setWidthOfElementWhenAddedNoSettle: (widthOfElementWhenAddedOrWidgetGivingWidthOfElementWhenAdded, widgetGivingWidthOfElementWhenAdded) ->
    if widgetGivingWidthOfElementWhenAdded?.getValue?
      widthOfElementWhenAdded = widgetGivingWidthOfElementWhenAdded.getValue()
    else
      widthOfElementWhenAdded = widthOfElementWhenAddedOrWidgetGivingWidthOfElementWhenAdded

    widthOfElementWhenAdded = Math.round(widthOfElementWhenAdded)

    if widthOfElementWhenAdded
      unless @widthOfElementWhenAdded == widthOfElementWhenAdded
        @widthOfElementWhenAdded = widthOfElementWhenAdded
        @element._invalidateLayout()   # (property sub-seam deletion) uniform climb: element -> stack -> (D1) scroll panel

