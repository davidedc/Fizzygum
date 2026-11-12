class ToothpasteIconWdgt extends IconWdgt

  # what I am as a tool, in a word: the paint tool whose face I am shows it as its tooltip and is
  # named by it (CodeInjectingSimpleRectangularButtonWdgt). I show no tooltip of my own.
  toolName: "toothpaste"

  createAppearance: -> new ToothpasteIconAppearance @

  constructor: (@color) ->
    super
