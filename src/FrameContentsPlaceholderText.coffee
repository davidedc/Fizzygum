class FrameContentsPlaceholderText extends TextWdgt

  constructor: ->

    super "Drop a widget in here",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1

    @alignCenter()
    @alignMiddle()
    @fittingSpecWhenBoundsTooLarge = false
    @changed()


  initialiseDefaultFrameContentLayoutSpec: ->
    @layoutSpecDetails = new FrameContentLayoutSpec FrameContentLayoutSpec.DONT_MIND , FrameContentLayoutSpec.DONT_MIND, 1

