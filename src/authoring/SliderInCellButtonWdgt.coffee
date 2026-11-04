# Puts a slider in the selected spreadsheet cell: it enters the formula below in the cell, as if typed
# (SheetCellStyle.enterSource), so the formula bar shows where the slider came from and its range can be
# edited there. A slider-valued cell exports the slider's number to the formulas that read it. See
# EditorContentPropertyChangerButtonWdgt for the shared family contract.

class SliderInCellButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "slider in cell"

  # the formula a cell gets: from 1 to 100, at 50, in steps of 1
  sliderSource: "new SliderWdgt 1, 100, 50, 1"

  createAppearance: -> new SliderNodeIconAppearance @, WorldWdgt.theme.toolbarGlyph

  activated: ->
    @_styleSubject()?.enterSource? @sliderSource
    return
