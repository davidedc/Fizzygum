# Puts a slider in the selected spreadsheet cell: it enters the formula below in the cell, as if typed
# (SheetCellStyle.enterSource), so the formula bar shows where the slider came from and its range can be
# edited there. A slider-valued cell exports the slider's number to the formulas that read it. See
# EditorContentPropertyChangerButtonWdgt for the shared family contract.

class SliderInCellButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "slider in cell"

  # my face, the slider node, is a PICTURE that fills its box, unlike my family's glyphs: the tool cell
  # I stand in names it the mark box's side, the side the Patch programming toolbar's slider node is
  # drawn at too
  drawsFaceInToolMarkBox: true

  # the formula a cell gets: from 1 to 100, at 50, in steps of 1
  sliderSource: "new SliderWdgt 1, 100, 50, 1"

  # a source entered in the cell, as if typed: my slider's formula
  verb: "enterSource"

  createAppearance: -> new SliderNodeIconAppearance @

  _actOn: (subject) ->
    # settling-call-sanctioned: a press at event time, outside any pass (activated, my one caller), and the
    #   receiver is a SheetCellStyle (only a sheet hands over a subject offering my verb), whose plain
    #   enterSource hands the source to its sheet, which settles it
    subject.enterSource @sliderSource
    return
