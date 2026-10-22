class FrameContentsPlaceholderText extends TextWdgt

  # stated rather than inherited (a text's "text"): I stand in for the window's missing contents
  colloquialName: -> "placeholder text"

  # My ink is my surface's own role, framePlaceholderText, given as I am built: I am a hint standing
  # in for the window's missing contents, not a text with no ink of its own, so I do not wear a
  # text's default ink.
  constructor: ->

    super "Drop a widget in here",
      backgroundColor: WorldWdgt.theme.editableItemFill
      backgroundTransparency: 1
      color: WorldWdgt.theme.framePlaceholderText

    @alignCenter()
    @alignMiddle()
    @fittingSpecWhenBoundsTooLarge = false
    @_changed()


  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.DONT_MIND , FrameContentLayoutSpec.DONT_MIND, 1

