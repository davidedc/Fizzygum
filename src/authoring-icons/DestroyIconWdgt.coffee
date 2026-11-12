class DestroyIconWdgt extends IconWdgt

  colloquialName: ->
    "\"Destroy\" icon"

  # what I am as a tool in a panel, in a word: the lid over me in a tool cell shows it as its tooltip
  # (ToolPanelWdgt), and a toolbar's overflow row names me by it (OverflowChevronButtonWdgt). I show
  # no tooltip of my own.
  toolName: "explosion"

  createAppearance: -> new DestroyIconAppearance @

  constructor: (@color) ->
    super
