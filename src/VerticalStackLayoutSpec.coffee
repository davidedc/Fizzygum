# VerticalStackLayoutSpec

class VerticalStackLayoutSpec

  @augmentWith DeepCopierMixin

  stack: nil
  element: nil

  widthOfStackWhenAdded: nil
  widthOfElementWhenAdded: nil
  elasticity: 1
  alignment: 'left'

  constructor: (@elasticity) ->
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
    menu.addMenuItem "layout in stack ➜", false, @, "vertStackMenu", ""

  vertStackMenu: (widgetOpeningThePopUp,targetWidget,a,b,c)->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, targetWidget, true, true, nil
    menu.addMenuItem "base width...", true, @, "baseWidthPopout", ""
    menu.addMenuItem "elasticity...", true, @, "elasticityPopout", ""
    menu.addMenuItem "align left", true, @, "setAlignmentToLeft"  if @alignment isnt "left"
    menu.addMenuItem "align right", true, @, "setAlignmentToRight"  if @alignment isnt "right"
    menu.addMenuItem "align center", true, @, "setAlignmentToCenter"  if @alignment isnt "center"
    menu.popUpAtHand()

  # The spec's layout setters below (align / elasticity / base-width) are DISCRETE public mutations -- driven
  # from the "layout in stack ➜" menu, the align/elasticity buttons, the base-width prompt, or an app building
  # its starting content. Each must therefore SELF-SETTLE (one layout flush per outermost public mutation),
  # instead of leaving its re-fit to ride the per-frame end-of-cycle flush. The spec is not a Widget, so the
  # settle is taken on @element (the stack element). Canonical public-wrapper / _NoSettle-core split: each
  # public setter is JUST the settle over its _<name>NoSettle core, and ALL the work -- INCLUDING the
  # already-in-this-state guard -- lives in the core, so no wrapper hides a pre-settle early return
  # (check-layering rule [H]). _announceLayoutPropertyChangeToContainer stays the NON-settling re-fit
  # core (it is also called by in-cycle paths -- soft-wrap, contained-text edits, WindowWdgt resize -- that
  # ride THEIR own outer settle). (Off-world content hits _settleLayoutsAfter's orphan early-return, so it
  # still just defers, unchanged.) (end-of-cycle-flush-drawdown -- CONVERT)
  # thin-wrap-exempt: the spec is NOT a Widget, so each setter settles on @element (the stack element), not @
  # -- the thin-wrap gate's canonical form anchors _settleLayoutsAfter on @ (a self-settle). This is the same
  # canonical thin wrap, just delegated to @element. (All 5 setters below are exempt for this reason.)
  setAlignmentToLeft: ->
    @element._settleLayoutsAfter => @_setAlignmentToLeftNoSettle()
  _setAlignmentToLeftNoSettle: ->
    if @alignment isnt "left"
      @alignment = "left"
      @element._invalidateLayout()   # (property sub-seam deletion) uniform climb: element -> stack -> (D1) scroll panel

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  setAlignmentToRight: ->
    @element._settleLayoutsAfter => @_setAlignmentToRightNoSettle()
  _setAlignmentToRightNoSettle: ->
    if @alignment isnt "right"
      @alignment = "right"
      @element._invalidateLayout()   # (property sub-seam deletion) uniform climb: element -> stack -> (D1) scroll panel

  # thin-wrap-exempt: settles on @element (not @) -- not a Widget; canonical otherwise (see setAlignmentToLeft).
  setAlignmentToCenter: ->
    @element._settleLayoutsAfter => @_setAlignmentToCenterNoSettle()
  _setAlignmentToCenterNoSettle: ->
    if @alignment isnt "enter"
      @alignment = "center"
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

