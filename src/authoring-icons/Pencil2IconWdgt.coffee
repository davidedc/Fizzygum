class Pencil2IconWdgt extends IconWdgt

  # stated rather than derived: the camelCase split leaves the digit glued to the word
  colloquialName: -> "pencil 2 icon"

  # what I am as a tool, in a word: the paint tool whose face I am shows it as its tooltip and is
  # named by it (CodeInjectingSimpleRectangularButtonWdgt). I show no tooltip of my own.
  toolName: "pencil"

  createAppearance: -> new Pencil2IconAppearance @

  constructor: (@color) ->
    super

