class WindowContentsPlaceholderText extends TextWdgt

  constructor: ->

    super "Drop a widget in here",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1

    @alignCenter()
    @alignMiddle()
    @fittingSpecWhenBoundsTooLarge = false
    @changed()


  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec WindowContentLayoutSpec.DONT_MIND , WindowContentLayoutSpec.DONT_MIND, 1

