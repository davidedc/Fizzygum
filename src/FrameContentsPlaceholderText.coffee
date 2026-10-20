class FrameContentsPlaceholderText extends TextWdgt

  # stated rather than inherited (a text's "text"): I stand in for the window's missing contents
  colloquialName: -> "placeholder text"

  constructor: ->

    super "Drop a widget in here",
      backgroundColor: WorldWdgt.theme.editableItemFill
      backgroundTransparency: 1

    @alignCenter()
    @alignMiddle()
    @fittingSpecWhenBoundsTooLarge = false
    @_changed()


  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.DONT_MIND , FrameContentLayoutSpec.DONT_MIND, 1

