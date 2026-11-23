class ArrowSIconWdgt extends IconWdgt

  # the size I have as a tool, which a toolbar builds me at (the rule: SpeechBubbleWdgt's toolExtent)
  toolExtent: new Point 80, 80

  # stated rather than derived: the derivation lowercases the compass point ("arrow s icon")
  colloquialName: -> "arrow S icon"

  createAppearance: -> new ArrowSIconAppearance @


