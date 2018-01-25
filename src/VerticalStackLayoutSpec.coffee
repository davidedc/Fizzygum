# VerticalStackLayoutSpec


class VerticalStackLayoutSpec

  @augmentWith DeepCopierMixin

  stack: nil
  element: nil

  widthOfStackWhenAdded: nil
  widthOfElementWhenAdded: nil
  elasticity: 1
  proportionalHeight: false
  alignment: 'left'

  # TODO there should be a method on the morph that
  # initialises its layoutSpecDetails with the proper
  # settings, like we do for WindowContentLayoutSpec.
  # Doing it all from this constructor common for all
  # widgets, and then doing a case analysis based on
  # the element class... this is not OK...
  constructor: (@element, @stack) ->
    
    availableWidthInStack = @availableWidthInStack()
    elementWidthWithoutSpacing = @element.widthWithoutSpacing()
    
    if (@element instanceof SimplePlainTextWdgt) or elementWidthWithoutSpacing > availableWidthInStack
      @widthOfElementWhenAdded = availableWidthInStack
      @widthOfStackWhenAdded = availableWidthInStack
      @elasticity = 1
    else
      @widthOfElementWhenAdded = elementWidthWithoutSpacing
      @widthOfStackWhenAdded = availableWidthInStack
      @elasticity = 1

  availableWidthInStack: ->
    @stack.width() - 2 * @stack.padding

  getWidthInStack: ->
    debugger
    availableWidthInStack = @availableWidthInStack()
    proportionalWidth = availableWidthInStack * @widthOfElementWhenAdded / @widthOfStackWhenAdded
    differenceWithFixedWidth = proportionalWidth - @widthOfElementWhenAdded
    
    width = @widthOfElementWhenAdded + @elasticity * differenceWithFixedWidth
    width = Math.round width

    return Math.min width, availableWidthInStack


  addMorphSpecificMenuEntries: (morphOpeningTheMenu, menu) ->
    menu.addLine()
    menu.addMenuItem "layout in stack ➜", false, @, "vertStackMenu", ""

  vertStackMenu: (morphOpeningTheMenu,targetMorph,a,b,c)->
    debugger
    menu = new MenuMorph morphOpeningTheMenu,  false, targetMorph, true, true, nil
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

  setElasticity: (elasticityOrMorphGivingElasticity, morphGivingElasticity) ->
    debugger
    if morphGivingElasticity?.getValue?
      elasticity = morphGivingElasticity.getValue()
    else
      elasticity = elasticityOrMorphGivingElasticity

    elasticity = Number(elasticity)

    if elasticity
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

  setWidthOfElementWhenAdded: (widthOfElementWhenAddedOrMorphGivingWidthOfElementWhenAdded, morphGivingWidthOfElementWhenAdded) ->
    debugger
    if morphGivingWidthOfElementWhenAdded?.getValue?
      widthOfElementWhenAdded = morphGivingWidthOfElementWhenAdded.getValue()
    else
      widthOfElementWhenAdded = widthOfElementWhenAddedOrMorphGivingWidthOfElementWhenAdded

    widthOfElementWhenAdded = Math.round(widthOfElementWhenAdded)

    if widthOfElementWhenAdded
      unless @widthOfElementWhenAdded == widthOfElementWhenAdded
        @widthOfElementWhenAdded = widthOfElementWhenAdded
        @element.refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

