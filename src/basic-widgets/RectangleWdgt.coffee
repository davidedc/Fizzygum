# a plain rectangular Widget. Because it's so basic, it's the building
# block of many more complex constructions, for example containers
# , clipping windows, and clipping windows which allow content to be
# scrolled (clipping is particularly easy to do along a rectangular
# path and it allows many optimisations and it's a very common case)
# It's important that the basic unadulterated version of
# rectangle doesn't draw a border, to keep this basic
# and versatile, so for example there is no case where the children
# are painted over the border, which would look bad.


class RectangleWdgt extends Widget

  # what I am as a tool in a panel, in a word: the lid over me in a tool cell shows it as its tooltip
  # (ToolPanelWdgt), and a toolbar's overflow row names me by it (OverflowChevronButtonWdgt). I show
  # no tooltip of my own.
  toolName: "rectangle"

  constructor: (extent, color) ->
    super()
    @appearance = new RectangularAppearance @
    @__commitExtent(extent) if extent?
    @color = color if color?

