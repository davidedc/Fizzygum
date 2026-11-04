# The SPREADSHEET's toolbar (docs/archive/spreadsheet-ux-plan.md R9): the text toolbar's tools, which act
# on the editor focus's style subject — a sheet hands over its selected cell's (SheetCellStyle) — plus
# the sheet's own: fill colour, fewer / more decimals, a slider in the cell. A text toolbar in every other
# respect: it docks on top, follows the edited text's style the same way (TextToolbarWdgt), and floats
# from the Super toolbar like any toolbar.
#   ORDER IS WHAT A NARROW WINDOW SHOWS: a strip drops tools into its » from the END, so what a sheet
# needs most comes first.

class SheetToolbarWdgt extends TextToolbarWdgt

  _toolbarItems: -> [
    new BoldButtonWdgt
    new ItalicButtonWdgt
    new FillColorButtonWdgt
    new FewerDecimalsButtonWdgt
    new MoreDecimalsButtonWdgt

    new AlignLeftButtonWdgt
    new AlignCenterButtonWdgt
    new AlignRightButtonWdgt

    new SliderInCellButtonWdgt
    # the toolbar itself is the font-menu stash home (re-clicking re-focuses the open menu)
    new ChangeFontButtonWdgt @
    new IncreaseFontSizeButtonWdgt
    new DecreaseFontSizeButtonWdgt
  ]
