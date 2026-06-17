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

  getWidthInStack: ->
    availableWidthInStack = @stack.availableWidthForContents()
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

  setAlignmentToLeft: ->
    if @alignment isnt "left"
      @alignment = "left"
      @element.refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  setAlignmentToRight: ->
    if @alignment isnt "right"
      @alignment = "right"
      @element.refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  setAlignmentToCenter: ->
    if @alignment isnt "enter"
      @alignment = "center"
      @element.refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  elasticityPopout: (menuItem,a,b,c,d,e,f)->
    @element.prompt menuItem.parent.title + "\nelasticity:",
      @,
      "setElasticity",
      (@elasticity * 100).toString(),
      nil,
      0,
      100,
      true

  setElasticity: (elasticityOrWidgetGivingElasticity, widgetGivingElasticity) ->
    if widgetGivingElasticity?.getValue?
      elasticity = widgetGivingElasticity.getValue()
    else
      elasticity = elasticityOrWidgetGivingElasticity

    elasticity = Number(elasticity)

    elasticity = elasticity/100
    unless @elasticity == elasticity
      @elasticity = elasticity
      @element.refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  baseWidthPopout: (menuItem,a,b,c,d,e,f)->
    @element.prompt menuItem.parent.title + "\nbase width:",
      @,
      "setWidthOfElementWhenAdded",
      @widthOfElementWhenAdded.toString(),
      nil,
      10,
      1000,
      true

  setWidthOfElementWhenAdded: (widthOfElementWhenAddedOrWidgetGivingWidthOfElementWhenAdded, widgetGivingWidthOfElementWhenAdded) ->
    if widgetGivingWidthOfElementWhenAdded?.getValue?
      widthOfElementWhenAdded = widgetGivingWidthOfElementWhenAdded.getValue()
    else
      widthOfElementWhenAdded = widthOfElementWhenAddedOrWidgetGivingWidthOfElementWhenAdded

    widthOfElementWhenAdded = Math.round(widthOfElementWhenAdded)

    if widthOfElementWhenAdded
      unless @widthOfElementWhenAdded == widthOfElementWhenAdded
        @widthOfElementWhenAdded = widthOfElementWhenAdded
        @element.refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

