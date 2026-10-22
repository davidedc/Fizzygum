# Fizzytiles' TILES BIN: the pane holding the magnets a program is built from (FridgeMagnetsWdgt
# lays the four sample magnets in me). Those magnets are templates (MagnetWdgt.isTemplate), so
# dragging one out carries a copy and leaves the tile here.
#
# I wear the tiles bin's look, read as I am painted: my fill is the fizzytilesTilesBinFill role and
# my border the fizzytilesTilesBinStroke role (_surfaceFill / _surfaceStroke, which my
# RectangularAppearance asks while I hold no colour of my own). Like every panel I hold no colour of
# my own, so a bin saved, loaded or duplicated wears the look of the world it is shown in, and a
# colour set on me later is mine.

class MagnetsBoxWdgt extends PanelWdgt

  _surfaceFill: ->
    WorldWdgt.theme.fizzytilesTilesBinFill

  _surfaceStroke: ->
    WorldWdgt.theme.fizzytilesTilesBinStroke
