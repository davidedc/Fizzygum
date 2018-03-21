class WindowContentsPlaceholderText extends TextMorph2

  constructor: ->

    super "Drop a widget in here",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1

    @alignCenter()
    @alignMiddle()
    @fittingSpecWhenBoundsTooLarge = false
    @changed()


  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.DONT_MIND , PreferredSize.DONT_MIND, 1

