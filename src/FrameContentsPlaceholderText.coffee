class FrameContentsPlaceholderText extends TextWdgt

  constructor: ->

    super "Drop a widget in here",
      backgroundColor: WorldWdgt.preferencesAndSettings.editableItemBackgroundColor
      backgroundTransparency: 1

    @alignCenter()
    @alignMiddle()
    @fittingSpecWhenBoundsTooLarge = false
    @_changed()


  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.DONT_MIND , FrameContentLayoutSpec.DONT_MIND, 1

