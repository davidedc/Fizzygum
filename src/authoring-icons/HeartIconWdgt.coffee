class HeartIconWdgt extends IconWdgt

  # the size I have as a tool, which a toolbar builds me at (the rule: SpeechBubbleWdgt's toolExtent)
  toolExtent: new Point 80, 80

  createAppearance: -> new HeartIconAppearance @
