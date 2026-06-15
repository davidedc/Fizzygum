# this file is excluded from the fizzygum homepage build

# A draggable "fridge magnet" tile. It used to extend the deprecated
# TriggerMorph; that class is gone, so it now extends MenuItemMorph (which
# carries the same flat-paint + trigger machinery). A magnet is not a menu
# item, so its menu-specific inheritance is inert (it is never a list item and
# never representsAMorph), and it keeps its own label sizing (see createLabel).

class MagnetMorph extends MenuItemMorph

  putIntoWords: false
  isTemplate: true

  constructor: (
      @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked,
      @target
     ) ->
    super
    @defaultRejectDrags = false

  # MenuItemMorph.createLabel sizes the item's box to its label (good for a
  # menu row, wrong for a magnet, which keeps the default box and centres its
  # label). Reproduce the old TriggerMorph label behaviour: a self-sized
  # StringWdgt label, no box resize.
  createLabel: ->
    @label = new StringWdgt(
      @labelString or "",
      @fontSize,
      @fontStyle,
      @labelBold,
      @labelItalic,
      false, # isHeaderLine
      false, # isNumeric
      @labelColor
    )
    @add @label
    @label.sizeToTextAndDisableFitting()

  rightCenter: ->
    new Point(@right(),@height()/2)

  leftCenter: ->
    new Point(@left(),@height()/2)
