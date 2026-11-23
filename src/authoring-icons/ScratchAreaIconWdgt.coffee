# based on https://thenounproject.com/term/organization/153374/
class ScratchAreaIconWdgt extends IconWdgt

  # the size I have as a tool, which a toolbar builds me at (the rule: SpeechBubbleWdgt's toolExtent)
  toolExtent: new Point 80, 80

  createAppearance: -> new ScratchAreaIconAppearance @


