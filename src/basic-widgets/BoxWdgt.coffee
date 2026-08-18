# I can have an optionally rounded border

class BoxWdgt extends Widget

  # `cornerRadius` and its setter live on Widget: every rounded appearance reads
  # `@widget.cornerRadius`, so the property belongs to the widget↔appearance contract rather than to
  # me. What is mine is the DEFAULT — a box is round-cornered unless told otherwise, where a plain
  # widget has no opinion and takes the shape's own default.
  constructor: (@cornerRadius = 4) ->
    super()
    @appearance = new BoxyAppearance @
