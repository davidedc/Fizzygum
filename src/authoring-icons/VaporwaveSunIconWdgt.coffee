class VaporwaveSunIconWdgt extends IconWdgt

  # the size I have as a tool, which a toolbar builds me at (the rule: SpeechBubbleWdgt's toolExtent)
  toolExtent: new Point 140, 140

  createAppearance: -> new VaporwaveSunIconAppearance @

