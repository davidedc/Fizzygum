class FizzygumLogoWithTextIconWdgt extends IconWdgt

  # the size I have as a tool, which a toolbar builds me at (the rule: SpeechBubbleWdgt's toolExtent)
  toolExtent: new Point 140, 140

  # stated rather than derived: a proper name keeps its capital
  colloquialName: -> "Fizzygum logo with text icon"

  createAppearance: -> new FizzygumLogoWithTextIconAppearance @

