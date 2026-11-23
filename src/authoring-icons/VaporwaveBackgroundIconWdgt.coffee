class VaporwaveBackgroundIconWdgt extends IconWdgt

  # the size I have as a tool, which a toolbar builds me at (the rule: SpeechBubbleWdgt's toolExtent)
  toolExtent: new Point 320, 320

  createAppearance: -> new VaporwaveBackgroundIconAppearance @

